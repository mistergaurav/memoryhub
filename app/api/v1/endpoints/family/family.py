from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime, timedelta
from bson import ObjectId
import secrets

from app.models.family.family import (
    FamilyRelationshipCreate, FamilyRelationshipResponse,
    FamilyCircleCreate, FamilyCircleUpdate, FamilyCircleResponse,
    FamilyInvitationCreate, FamilyInvitationResponse,
    FamilyRelationType, FamilyTreeNode,
    AddFamilyMemberRequest
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.repositories.family_repository import (
    FamilyRepository,
    FamilyRelationshipRepository,
    FamilyInvitationRepository
)
from app.utils.family_validators import (
    validate_family_ownership,
    validate_family_member_access,
    validate_object_id_list,
    validate_user_exists,
    validate_relationship_ownership,
    validate_invitation_token,
    validate_invitation_for_user,
    validate_circle_ownership_for_invitations,
    validate_no_duplicate_relationship,
    validate_user_not_owner,
    validate_user_not_in_circle
)
from app.models.responses import create_message_response

router = APIRouter()

family_repo = FamilyRepository()
relationship_repo = FamilyRelationshipRepository()
invitation_repo = FamilyInvitationRepository()


@router.post("/relationships", response_model=FamilyRelationshipResponse, status_code=status.HTTP_201_CREATED)
async def create_family_relationship(
    relationship: FamilyRelationshipCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family relationship"""
    try:
        related_user = await validate_user_exists(relationship.related_user_id, "related user")
        
        await validate_no_duplicate_relationship(
            str(current_user.id),
            relationship.related_user_id
        )
        
        relationship_data = {
            "user_id": ObjectId(current_user.id),
            "related_user_id": ObjectId(relationship.related_user_id),
            "relation_type": relationship.relation_type,
            "relation_label": relationship.relation_label,
            "notes": relationship.notes,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        relationship_doc = await relationship_repo.create(relationship_data)
        
        return FamilyRelationshipResponse(
            id=str(relationship_doc["_id"]),
            user_id=str(relationship_doc["user_id"]),
            related_user_id=str(relationship_doc["related_user_id"]),
            related_user_name=related_user.get("full_name"),
            related_user_avatar=related_user.get("avatar_url"),
            related_user_email=related_user.get("email"),
            relation_type=relationship_doc["relation_type"],
            relation_label=relationship_doc.get("relation_label"),
            notes=relationship_doc.get("notes"),
            created_at=relationship_doc["created_at"],
            updated_at=relationship_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create relationship: {str(e)}")


@router.get("/relationships", response_model=List[FamilyRelationshipResponse])
async def list_family_relationships(
    relation_type: Optional[FamilyRelationType] = None,
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(50, ge=1, le=100, description="Number of records to return"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all family relationships for the current user with pagination"""
    try:
        relationships_docs = await relationship_repo.find_by_user(
            str(current_user.id),
            relation_type=relation_type.value if relation_type else None,
            skip=skip,
            limit=limit
        )
        
        relationships = []
        for rel_doc in relationships_docs:
            related_user = await get_collection("users").find_one({"_id": rel_doc["related_user_id"]})
            relationships.append(FamilyRelationshipResponse(
                id=str(rel_doc["_id"]),
                user_id=str(rel_doc["user_id"]),
                related_user_id=str(rel_doc["related_user_id"]),
                related_user_name=related_user.get("full_name") if related_user else None,
                related_user_avatar=related_user.get("avatar_url") if related_user else None,
                related_user_email=related_user.get("email") if related_user else None,
                relation_type=rel_doc["relation_type"],
                relation_label=rel_doc.get("relation_label"),
                notes=rel_doc.get("notes"),
                created_at=rel_doc["created_at"],
                updated_at=rel_doc["updated_at"]
            ))
        
        return relationships
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list relationships: {str(e)}")


@router.delete("/relationships/{relationship_id}")
async def delete_family_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a family relationship"""
    try:
        await validate_relationship_ownership(str(current_user.id), relationship_id)
        
        await relationship_repo.delete_by_id(relationship_id)
        
        return create_message_response("Relationship deleted successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete relationship: {str(e)}")


@router.post("/circles", response_model=FamilyCircleResponse, status_code=status.HTTP_201_CREATED)
async def create_family_circle(
    circle: FamilyCircleCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family circle"""
    try:
        member_oids = validate_object_id_list(circle.member_ids, "member_ids") if circle.member_ids else []
        
        member_oids.append(ObjectId(current_user.id))
        member_oids = list(set(member_oids))
        
        circle_data = {
            "name": circle.name,
            "description": circle.description,
            "circle_type": circle.circle_type,
            "avatar_url": circle.avatar_url,
            "color": circle.color,
            "owner_id": ObjectId(current_user.id),
            "member_ids": member_oids,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        circle_doc = await family_repo.create(circle_data)
        
        members = []
        for member_id in circle_doc["member_ids"]:
            user = await get_collection("users").find_one({"_id": member_id})
            if user:
                members.append({
                    "id": str(user["_id"]),
                    "name": user.get("full_name"),
                    "avatar": user.get("avatar_url")
                })
        
        return FamilyCircleResponse(
            id=str(circle_doc["_id"]),
            name=circle_doc["name"],
            description=circle_doc.get("description"),
            circle_type=circle_doc["circle_type"],
            avatar_url=circle_doc.get("avatar_url"),
            color=circle_doc.get("color"),
            owner_id=str(circle_doc["owner_id"]),
            member_count=len(circle_doc["member_ids"]),
            members=members,
            created_at=circle_doc["created_at"],
            updated_at=circle_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create circle: {str(e)}")


@router.get("/circles", response_model=List[FamilyCircleResponse])
async def list_family_circles(
    current_user: UserInDB = Depends(get_current_user)
):
    """List all family circles for the current user"""
    try:
        circles_docs = await family_repo.find_by_member(str(current_user.id))
        circles = []
        
        for circle_doc in circles_docs:
            members = []
            for member_id in circle_doc.get("member_ids", []):
                user = await get_collection("users").find_one({"_id": member_id})
                if user:
                    members.append({
                        "id": str(user["_id"]),
                        "name": user.get("full_name"),
                        "avatar": user.get("avatar_url")
                    })
            
            circles.append(FamilyCircleResponse(
                id=str(circle_doc["_id"]),
                name=circle_doc["name"],
                description=circle_doc.get("description"),
                circle_type=circle_doc["circle_type"],
                avatar_url=circle_doc.get("avatar_url"),
                color=circle_doc.get("color"),
                owner_id=str(circle_doc["owner_id"]),
                member_count=len(circle_doc.get("member_ids", [])),
                members=members,
                created_at=circle_doc["created_at"],
                updated_at=circle_doc["updated_at"]
            ))
        
        return circles
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list circles: {str(e)}")


@router.post("/circles/{circle_id}/members/{user_id}")
async def add_member_to_circle(
    circle_id: str,
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a member to a family circle"""
    try:
        circle = await validate_family_ownership(
            str(current_user.id),
            circle_id,
            "family_circles"
        )
        
        await validate_user_exists(user_id, "user")
        
        await validate_user_not_in_circle(circle, user_id)
        
        await family_repo.add_member(circle_id, user_id, str(current_user.id))
        
        return create_message_response("Member added successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add member: {str(e)}")


@router.delete("/circles/{circle_id}/members/{user_id}")
async def remove_member_from_circle(
    circle_id: str,
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove a member from a family circle"""
    try:
        circle = await validate_family_ownership(
            str(current_user.id),
            circle_id,
            "family_circles"
        )
        
        await validate_user_not_owner(circle, user_id)
        
        await family_repo.remove_member(circle_id, user_id, str(current_user.id))
        
        return create_message_response("Member removed successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to remove member: {str(e)}")


@router.post("/invitations", response_model=FamilyInvitationResponse, status_code=status.HTTP_201_CREATED)
async def create_family_invitation(
    invitation: FamilyInvitationCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family invitation"""
    try:
        circles = await validate_circle_ownership_for_invitations(
            str(current_user.id),
            invitation.circle_ids
        )
        
        circle_names = [circle.get("name", "") for circle in circles]
        circle_oids = [circle["_id"] for circle in circles]
        
        token = secrets.token_urlsafe(32)
        
        invitation_data = {
            "inviter_id": ObjectId(current_user.id),
            "invitee_email": invitation.invitee_email.lower(),
            "relation_type": invitation.relation_type,
            "relation_label": invitation.relation_label,
            "message": invitation.message,
            "circle_ids": circle_oids,
            "token": token,
            "status": "pending",
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(days=7)
        }
        
        invitation_doc = await invitation_repo.create(invitation_data)
        
        from os import getenv
        base_url = getenv("REPLIT_DOMAINS", "localhost:5000").split(",")[0]
        if not base_url.startswith("http"):
            base_url = f"https://{base_url}"
        invite_url = f"{base_url}/accept-family-invite?token={token}"
        
        return FamilyInvitationResponse(
            id=str(invitation_doc["_id"]),
            inviter_id=str(invitation_doc["inviter_id"]),
            inviter_name=current_user.full_name,
            invitee_email=invitation_doc["invitee_email"],
            relation_type=invitation_doc["relation_type"],
            relation_label=invitation_doc.get("relation_label"),
            message=invitation_doc.get("message"),
            circle_ids=[str(cid) for cid in invitation_doc.get("circle_ids", [])],
            circle_names=circle_names,
            token=invitation_doc["token"],
            status=invitation_doc["status"],
            invite_url=invite_url,
            created_at=invitation_doc["created_at"],
            expires_at=invitation_doc["expires_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create invitation: {str(e)}")


@router.post("/invitations/{token}/accept")
async def accept_family_invitation(
    token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Accept a family invitation"""
    try:
        invitation = await validate_invitation_token(token)
        
        await validate_invitation_for_user(invitation, current_user.email)
        
        relationship_data = {
            "user_id": invitation["inviter_id"],
            "related_user_id": ObjectId(current_user.id),
            "relation_type": invitation["relation_type"],
            "relation_label": invitation.get("relation_label"),
            "notes": f"Added via invitation",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        await relationship_repo.create(relationship_data)
        
        for circle_id in invitation.get("circle_ids", []):
            await get_collection("family_circles").update_one(
                {"_id": circle_id},
                {
                    "$addToSet": {"member_ids": ObjectId(current_user.id)},
                    "$set": {"updated_at": datetime.utcnow()}
                }
            )
        
        await invitation_repo.update(
            {"_id": invitation["_id"]},
            {
                "status": "accepted",
                "accepted_at": datetime.utcnow()
            }
        )
        
        return create_message_response("Invitation accepted successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to accept invitation: {str(e)}")


@router.get("/tree", response_model=List[FamilyTreeNode])
async def get_family_tree(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get the family tree for the current user"""
    try:
        relationships_docs = await relationship_repo.find_by_user(str(current_user.id))
        tree_nodes = []
        
        for rel in relationships_docs:
            user = await get_collection("users").find_one({"_id": rel["related_user_id"]})
            if user:
                tree_nodes.append(FamilyTreeNode(
                    user_id=str(user["_id"]),
                    name=user.get("full_name", "Unknown"),
                    avatar_url=user.get("avatar_url"),
                    relation_type=rel["relation_type"],
                    relation_label=rel.get("relation_label"),
                    children=[]
                ))
        
        return tree_nodes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get family tree: {str(e)}")


@router.post("/add-member", response_model=dict)
async def add_family_member(
    request: AddFamilyMemberRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Smart endpoint to add a family member - creates relationship and optionally sends invitation"""
    try:
        user = await get_collection("users").find_one({"email": request.email.lower()})
        
        if user:
            relationship_exists = await relationship_repo.check_relationship_exists(
                str(current_user.id),
                str(user["_id"])
            )
            
            if relationship_exists:
                return {
                    "status": "already_exists",
                    "message": "Family relationship already exists",
                    "user_id": str(user["_id"])
                }
            
            relationship_data = {
                "user_id": ObjectId(current_user.id),
                "related_user_id": user["_id"],
                "relation_type": request.relation_type,
                "relation_label": request.relation_label,
                "notes": request.notes,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            await relationship_repo.create(relationship_data)
            
            return {
                "status": "added",
                "message": "Family member added successfully",
                "user_id": str(user["_id"]),
                "user_name": user.get("full_name")
            }
        else:
            if not request.send_invitation:
                return {
                    "status": "not_found",
                    "message": "User not found. Set send_invitation=true to invite them.",
                    "email": request.email
                }
            
            token = secrets.token_urlsafe(32)
            invitation_data = {
                "inviter_id": ObjectId(current_user.id),
                "invitee_email": request.email.lower(),
                "relation_type": request.relation_type,
                "relation_label": request.relation_label,
                "message": request.invitation_message or f"{current_user.full_name} would like to add you as their {request.relation_type} on Memory Hub",
                "circle_ids": [],
                "token": token,
                "status": "pending",
                "created_at": datetime.utcnow(),
                "expires_at": datetime.utcnow() + timedelta(days=7)
            }
            invitation_doc = await invitation_repo.create(invitation_data)
            
            from os import getenv
            base_url = getenv("REPLIT_DOMAINS", "localhost:5000").split(",")[0]
            if not base_url.startswith("http"):
                base_url = f"https://{base_url}"
            invite_url = f"{base_url}/accept-family-invite?token={token}"
            
            return {
                "status": "invited",
                "message": "Invitation sent successfully",
                "invitation_id": str(invitation_doc["_id"]),
                "invite_url": invite_url,
                "email": request.email
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add family member: {str(e)}")
