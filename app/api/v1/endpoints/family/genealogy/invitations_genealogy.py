"""Genealogy tree invitation handling."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime, timedelta
import secrets

from .schemas import (
    GenealogyPersonCreate, GenealogyPersonUpdate, GenealogyPersonResponse,
    GenealogyRelationshipCreate, GenealogyRelationshipResponse,
    FamilyTreeNode, PersonSource, UserSearchResult,
    FamilyHubInvitationCreate, FamilyHubInvitationResponse, InvitationAction, InvitationStatus
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database
from app.utils.genealogy_helpers import safe_object_id, compute_is_alive
from .repository import (
    GenealogyPersonRepository,
    GenealogyRelationshipRepository,
    GenealogyTreeRepository,
    GenealogTreeMembershipRepository
)
from app.repositories.family_repository import (
    UserRepository,
    NotificationRepository,
    GenealogyInviteLinksRepository,
    MemoryRepository,
    FamilyRepository
)
from app.models.responses import create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event

router = APIRouter()

genealogy_person_repo = GenealogyPersonRepository()
genealogy_relationship_repo = GenealogyRelationshipRepository()
genealogy_tree_repo = GenealogyTreeRepository()
tree_membership_repo = GenealogTreeMembershipRepository()
user_repo = UserRepository()
notification_repo = NotificationRepository()
invite_links_repo = GenealogyInviteLinksRepository()
memory_repo = MemoryRepository()
family_repo = FamilyRepository()


from .utils import validate_user_exists, person_doc_to_response, get_user_display_name
from .permissions import get_tree_membership, ensure_tree_access

@router.post("/invite-links", status_code=status.HTTP_201_CREATED)
async def create_invite_link(
    person_id: str = Query(..., description="Genealogy person ID to link invitation to"),
    email: Optional[str] = Query(None, description="Email to send invitation to"),
    message: Optional[str] = Query(None, description="Personal message"),
    expires_in_days: int = Query(30, ge=1, le=365, description="Expiry in days"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create an invitation link for a living family member to join the platform"""
    person_oid = safe_object_id(person_id)
    if not person_oid:
        raise HTTPException(status_code=400, detail="Invalid person_id")
    
    person_doc = await genealogy_person_repo.find_one(
        {"_id": person_oid},
        raise_404=True,
        error_message="Person not found"
    )
    if person_doc is None:
        raise HTTPException(status_code=404, detail="Person not found")
    
    if str(person_doc["family_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to invite for this person")
    
    if not person_doc.get("is_alive", True):
        raise HTTPException(status_code=400, detail="Cannot send invitation for deceased person")
    
    if person_doc.get("linked_user_id"):
        raise HTTPException(status_code=400, detail="Person is already linked to a platform user")
    
    existing_invite = await invite_links_repo.find_active_by_person(person_id)
    
    if existing_invite:
        raise HTTPException(status_code=400, detail="An active invitation already exists for this person")
    
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(days=expires_in_days)
    
    invite_data = {
        "family_id": ObjectId(current_user.id),
        "person_id": person_oid,
        "token": token,
        "email": email,
        "message": message,
        "status": "pending",
        "created_by": ObjectId(current_user.id),
        "created_at": datetime.utcnow(),
        "expires_at": expires_at,
        "accepted_at": None,
        "accepted_by": None
    }
    
    invite_doc = await invite_links_repo.create(invite_data)
    
    await genealogy_person_repo.collection.update_one(
        {"_id": person_oid},
        {
            "$set": {
                "pending_invite_email": email,
                "invite_token": token,
                "invitation_sent_at": datetime.utcnow(),
                "invitation_expires_at": expires_at,
                "updated_at": datetime.utcnow()
            }
        }
    )
    
    person_name = f"{person_doc['first_name']} {person_doc['last_name']}"
    invite_url = f"/genealogy/join/{token}"
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_INVITE_LINK",
        event_details={
            "resource_type": "genealogy_invite",
            "resource_id": str(invite_doc["_id"]),
            "person_id": person_id,
            "email": email
        }
    )
    
    return create_success_response(
        message="Invitation link created successfully",
        data={
            "id": str(invite_doc["_id"]),
            "family_id": str(current_user.id),
            "person_id": str(person_oid),
            "person_name": person_name,
            "token": token,
            "email": email,
            "message": message,
            "status": "pending",
            "invite_url": invite_url,
            "created_by": str(current_user.id),
            "created_at": invite_data["created_at"],
            "expires_at": expires_at
        }
    )


@router.post("/join/{token}", status_code=status.HTTP_200_OK)
async def redeem_invite_link(
    token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Redeem an invitation link and link user to genealogy person"""
    invite_doc = await invite_links_repo.find_by_token(token, raise_404=True)
    if invite_doc is None:
        raise HTTPException(status_code=404, detail="Invitation not found")
    
    if invite_doc["expires_at"] < datetime.utcnow():
        await invite_links_repo.update_by_id(
            str(invite_doc["_id"]),
            {"status": "expired"}
        )
        raise HTTPException(status_code=400, detail="Invitation has expired")
    
    if invite_doc["status"] != "pending":
        raise HTTPException(status_code=400, detail=f"Invitation has already been {invite_doc['status']}")
    
    person_doc = await genealogy_person_repo.find_one(
        {"_id": invite_doc["person_id"]},
        raise_404=True,
        error_message="Person not found"
    )
    if person_doc is None:
        raise HTTPException(status_code=404, detail="Person not found")
    
    if person_doc.get("linked_user_id"):
        raise HTTPException(status_code=400, detail="This person is already linked to another user")
    
    db = get_database()
    async with await db.client.start_session() as session:
        async with session.start_transaction():
            await genealogy_person_repo.collection.update_one(
                {"_id": invite_doc["person_id"]},
                {
                    "$set": {
                        "linked_user_id": ObjectId(current_user.id),
                        "source": "platform_user",
                        "is_alive": True,
                        "updated_at": datetime.utcnow()
                    },
                    "$unset": {
                        "pending_invite_email": "",
                        "invite_token": ""
                    }
                },
                session=session
            )
            
            await invite_links_repo.collection.update_one(
                {"_id": invite_doc["_id"]},
                {
                    "$set": {
                        "status": "accepted",
                        "accepted_at": datetime.utcnow(),
                        "accepted_by": ObjectId(current_user.id)
                    }
                },
                session=session
            )
            
            membership_exists = await tree_membership_repo.find_by_tree_and_user(
                tree_id=str(invite_doc["family_id"]),
                user_id=str(current_user.id)
            )
            
            if not membership_exists:
                membership_data = {
                    "tree_id": invite_doc["family_id"],
                    "user_id": ObjectId(current_user.id),
                    "role": "member",
                    "joined_at": datetime.utcnow(),
                    "granted_by": invite_doc["created_by"]
                }
                await tree_membership_repo.collection.insert_one(membership_data, session=session)
    
    joiner_name = await get_user_display_name(
        {"username": getattr(current_user, 'username', None),
         "full_name": current_user.full_name,
         "email": current_user.email}
    )
    
    await notification_repo.create_notification(
        user_id=str(invite_doc["family_id"]),
        notification_type="invitation_accepted",
        title="Family Tree Invitation Accepted",
        message=f"{joiner_name} joined your family tree",
        related_id=str(invite_doc["person_id"])
    )
    
    tree_circle = await family_repo.find_one({
        "owner_id": invite_doc["family_id"],
        "name": "Family Tree Members"
    }, raise_404=False)
    
    if tree_circle is not None:
        if ObjectId(current_user.id) not in tree_circle.get("member_ids", []):
            await family_repo.collection.update_one(
                {"_id": tree_circle["_id"]},
                {
                    "$addToSet": {"member_ids": ObjectId(current_user.id)},
                    "$set": {"updated_at": datetime.utcnow()}
                }
            )
    else:
        circle_data = {
            "name": "Family Tree Members",
            "description": "Members who have access to the family genealogy tree",
            "circle_type": "extended_family",
            "owner_id": invite_doc["family_id"],
            "member_ids": [invite_doc["family_id"], ObjectId(current_user.id)],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        await family_repo.create(circle_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="REDEEM_INVITE_LINK",
        event_details={
            "resource_type": "genealogy_invite",
            "resource_id": str(invite_doc["_id"]),
            "person_id": str(invite_doc["person_id"]),
            "tree_id": str(invite_doc["family_id"])
        }
    )
    
    return create_success_response(
        message="Successfully joined family tree",
        data={
            "person_id": str(invite_doc["person_id"]),
            "tree_id": str(invite_doc["family_id"])
        }
    )


@router.get("/invite-links")
async def list_invite_links(
    status_filter: Optional[str] = Query(None, description="Filter by status"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all invitation links created by current user"""
    invites = await invite_links_repo.find_by_family(
        family_id=str(current_user.id),
        status_filter=status_filter,
        limit=100
    )
    
    invite_responses = []
    for invite_doc in invites:
        person_doc = await genealogy_person_repo.find_one({"_id": invite_doc["person_id"]}, raise_404=False)
        person_name = f"{person_doc['first_name']} {person_doc['last_name']}" if person_doc is not None else "Unknown"
        
        invite_data = {
            "id": str(invite_doc["_id"]),
            "family_id": str(invite_doc["family_id"]),
            "person_id": str(invite_doc["person_id"]),
            "person_name": person_name,
            "token": invite_doc["token"],
            "email": invite_doc.get("email"),
            "message": invite_doc.get("message"),
            "status": invite_doc["status"],
            "invite_url": f"/genealogy/join/{invite_doc['token']}",
            "created_by": str(invite_doc["created_by"]),
            "created_at": invite_doc["created_at"],
            "expires_at": invite_doc["expires_at"],
            "accepted_at": invite_doc.get("accepted_at"),
            "accepted_by": str(invite_doc["accepted_by"]) if invite_doc.get("accepted_by") else None
        }
        invite_responses.append(invite_data)
    
    return create_success_response(
        message="Invite links retrieved successfully",
        data=invite_responses
    )


@router.get("/persons/{person_id}/timeline")
async def get_person_timeline(
    person_id: str,
    skip: int = Query(0, ge=0, description="Skip N memories"),
    limit: int = Query(20, ge=1, le=100, description="Limit results"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get timeline of all memories associated with this genealogy person"""
    person_oid = safe_object_id(person_id)
    if not person_oid:
        raise HTTPException(status_code=400, detail="Invalid person_id")
    
    person_doc = await genealogy_person_repo.find_one(
        {"_id": person_oid},
        raise_404=True,
        error_message="Person not found"
    )
    if person_doc is None:
        raise HTTPException(status_code=404, detail="Person not found")
    
    tree_id = person_doc["family_id"]
    membership = await tree_membership_repo.find_by_tree_and_user(
        tree_id=str(tree_id),
        user_id=str(current_user.id)
    )
    
    if not membership and str(tree_id) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this person's timeline")
    
    memories = await memory_repo.find_by_genealogy_person(
        person_id=str(person_oid),
        skip=skip,
        limit=limit
    )
    
    owner_ids = list({str(m["owner_id"]) for m in memories})
    owner_names = await user_repo.get_user_names(owner_ids) if owner_ids else {}
    
    memory_responses = []
    for memory_doc in memories:
        owner_id = str(memory_doc["owner_id"])
        owner_doc = await user_repo.find_one({"_id": memory_doc["owner_id"]}, raise_404=False)
        
        memory_data = {
            "id": str(memory_doc["_id"]),
            "title": memory_doc.get("title", ""),
            "content": memory_doc.get("content", ""),
            "media_urls": memory_doc.get("media_urls", []),
            "tags": memory_doc.get("tags", []),
            "created_at": memory_doc["created_at"],
            "owner_id": owner_id,
            "owner_username": owner_doc.get("username", "") if owner_doc else "",
            "owner_full_name": owner_doc.get("full_name") if owner_doc else None,
            "like_count": memory_doc.get("like_count", 0),
            "comment_count": memory_doc.get("comment_count", 0)
        }
        memory_responses.append(memory_data)
    
    return create_success_response(
        message="Person timeline retrieved successfully",
        data=memory_responses
    )

@router.post("/generate-invite-link", status_code=status.HTTP_200_OK)
async def generate_invite_link(
    current_user: UserInDB = Depends(get_current_user)
):
    """Generate a unique invite link"""
    token = secrets.token_urlsafe(32)
    # You would typically store this token in the database with an expiry date
    # and associate it with the user who generated it.
    # For this example, we'll just return the link.
    invite_link = f"/genealogy/join/{token}"
    return create_success_response(
        message="Invite link generated successfully",
        data={"invite_link": invite_link}
    )
