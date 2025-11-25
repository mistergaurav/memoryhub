"""Genealogy person CRUD operations."""
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


@router.post("/persons/self", status_code=status.HTTP_201_CREATED)
async def create_self_person(
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a genealogy person record for the current user.
    This is typically the first person added to a user's family tree.
    """
    user_oid = ObjectId(current_user.id)
    
    # Check if user already has a self-person
    existing_self = await genealogy_person_repo.find_one(
        {
            "family_id": user_oid,
            "linked_user_id": user_oid
        },
        raise_404=False
    )
    
    if existing_self:
        raise HTTPException(
            status_code=400,
            detail="You already have a person record in your family tree"
        )
    
    # Extract name from user's full_name or email
    full_name = current_user.full_name or current_user.email.split('@')[0]
    name_parts = full_name.split(' ', 1)
    first_name = name_parts[0]
    last_name = name_parts[1] if len(name_parts) > 1 else ""
    
    # Create person data
    person_data = {
        "family_id": user_oid,
        "first_name": first_name,
        "last_name": last_name,
        "gender": "unknown",  # User can update later
        "is_alive": True,
        "linked_user_id": user_oid,
        "source": "platform_user",
        "approval_status": "approved",  # Self-person is auto-approved
        "created_by": user_oid,
        "biography": f"This is my profile in the family tree.",
        "photo_url": getattr(current_user, 'avatar_url', None)
    }
    
    person_doc = await genealogy_person_repo.create(person_data)
    person_id = person_doc["_id"]
    
    # Create owner membership
    owner_membership = await tree_membership_repo.find_by_tree_and_user(
        tree_id=str(user_oid),
        user_id=str(current_user.id)
    )
    
    if not owner_membership:
        await tree_membership_repo.create_membership(
            tree_id=str(user_oid),
            user_id=str(current_user.id),
            role="owner",
            granted_by=str(current_user.id)
        )
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_SELF_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": str(person_id),
            "tree_id": str(user_oid)
        }
    )
    
    return create_success_response(
        message="Your profile has been created in the family tree",
        data=person_doc_to_response(person_doc)
    )


@router.post("/persons", status_code=status.HTTP_201_CREATED)
async def create_genealogy_person(
    person: GenealogyPersonCreate,
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new genealogy person with optional relationships"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id), required_roles=["owner", "member"])
    
    linked_user_oid = None
    
    if person.linked_user_id:
        linked_user_oid = genealogy_person_repo.validate_object_id(person.linked_user_id, "linked_user_id")
        
        await validate_user_exists(person.linked_user_id)
        
        existing_link = await genealogy_person_repo.find_one(
            {"linked_user_id": linked_user_oid},
            raise_404=False
        )
        if existing_link:
            raise HTTPException(
                status_code=400, 
                detail="This user is already linked to another genealogy person"
            )
        
        if person.source != PersonSource.PLATFORM_USER:
            person.source = PersonSource.PLATFORM_USER
    
    is_alive = compute_is_alive(person.death_date, person.is_alive)
    
    person_data = {
        "family_id": tree_oid,
        "first_name": person.first_name,
        "last_name": person.last_name,
        "maiden_name": person.maiden_name,
        "gender": person.gender,
        "birth_date": person.birth_date,
        "birth_place": person.birth_place,
        "death_date": person.death_date,
        "death_place": person.death_place,
        "is_alive": is_alive,
        "biography": person.biography,
        "photo_url": person.photo_url,
        "occupation": person.occupation,
        "notes": person.notes,
        "source": person.source,
        "created_by": ObjectId(current_user.id)
    }
    
    if linked_user_oid:
        person_data["linked_user_id"] = linked_user_oid
        # If linking to another user, set status to pending
        if str(linked_user_oid) != str(current_user.id):
            person_data["approval_status"] = "pending"
        else:
            person_data["approval_status"] = "approved"
    else:
        person_data["approval_status"] = "approved"
    
    person_doc = await genealogy_person_repo.create(person_data)
    person_id = person_doc["_id"]
    
    if tree_oid == ObjectId(current_user.id):
        owner_membership = await tree_membership_repo.find_by_tree_and_user(
            tree_id=str(tree_oid),
            user_id=str(current_user.id)
        )
        
        if not owner_membership:
            await tree_membership_repo.create_membership(
                tree_id=str(tree_oid),
                user_id=str(current_user.id),
                role="owner",
                granted_by=str(current_user.id)
            )
    
    if person.relationships:
        for rel_spec in person.relationships:
            related_person_oid = genealogy_person_repo.validate_object_id(rel_spec.person_id, "related_person_id")
            
            related_person = await genealogy_person_repo.find_one(
                {"_id": related_person_oid},
                raise_404=True,
                error_message=f"Related person not found: {rel_spec.person_id}"
            )
            if related_person is None:
                raise HTTPException(status_code=404, detail=f"Related person not found: {rel_spec.person_id}")
            
            if str(related_person["family_id"]) != str(tree_oid):
                raise HTTPException(
                    status_code=403, 
                    detail="Cannot create relationship with person from a different family tree"
                )
            
            relationship_data = {
                "family_id": tree_oid,
                "person1_id": person_id,
                "person2_id": related_person_oid,
                "relationship_type": rel_spec.relationship_type,
                "notes": rel_spec.notes,
                "created_by": ObjectId(current_user.id)
            }
            await genealogy_relationship_repo.create(relationship_data)
    
    # Send notification if a user was linked and it's not self-link
    if linked_user_oid and str(linked_user_oid) != str(current_user.id):
        await notification_repo.create_notification(
            user_id=str(linked_user_oid),
            notification_type="genealogyApprovalRequest",  # Matches frontend enum
            title="Family Tree Request",
            message=f"{current_user.full_name or current_user.email} wants to add you to their family tree as {person.first_name} {person.last_name}.",
            target_id=str(person_id),
            actor_id=str(current_user.id),
            target_type="genealogy_person"
        )
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_GENEALOGY_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": str(person_id),
            "tree_id": str(tree_oid),
            "first_name": person.first_name,
            "last_name": person.last_name
        }
    )
    
    return create_success_response(
        message="Person created successfully",
        data=person_doc_to_response(person_doc)
    )


@router.post("/persons/{person_id}/approve")
async def approve_genealogy_person(
    person_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Approve a genealogy person request"""
    person_doc = await genealogy_person_repo.find_by_id(person_id)
    if not person_doc:
        raise HTTPException(status_code=404, detail="Person not found")
    
    # Check if current user is the linked user
    if str(person_doc.get("linked_user_id")) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Only the linked user can approve this request")
    
    updated_person = await genealogy_person_repo.update_by_id(
        person_id, 
        {"approval_status": "approved", "rejection_reason": None}
    )
    
    # Notify the creator
    await notification_repo.create_notification(
        user_id=str(person_doc["created_by"]),
        notification_type="genealogy_approved",
        title="Request Approved",
        message=f"{current_user.full_name} approved being added to your family tree.",
        target_id=person_id,
        actor_id=str(current_user.id),
        target_type="genealogy_person"
    )
    
    return create_success_response(
        message="Request approved",
        data=person_doc_to_response(updated_person)
    )


@router.post("/persons/{person_id}/reject")
async def reject_genealogy_person(
    person_id: str,
    reason: str = Query(..., min_length=1),
    current_user: UserInDB = Depends(get_current_user)
):
    """Reject a genealogy person request"""
    person_doc = await genealogy_person_repo.find_by_id(person_id)
    if not person_doc:
        raise HTTPException(status_code=404, detail="Person not found")
    
    if str(person_doc.get("linked_user_id")) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Only the linked user can reject this request")
    
    updated_person = await genealogy_person_repo.update_by_id(
        person_id, 
        {"approval_status": "rejected", "rejection_reason": reason}
    )
    
    # Notify the creator
    await notification_repo.create_notification(
        user_id=str(person_doc["created_by"]),
        notification_type="genealogy_rejected",
        title="Request Rejected",
        message=f"{current_user.full_name} rejected being added to your family tree: {reason}",
        target_id=person_id,
        actor_id=str(current_user.id),
        target_type="genealogy_person"
    )
    
    return create_success_response(
        message="Request rejected",
        data=person_doc_to_response(updated_person)
    )


@router.get("/persons/search")
async def search_genealogy_persons(
    q: str = Query(..., min_length=2, description="Search query for first/last name"),
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Search persons by name in genealogy tree"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id))
    
    # Use regex for case-insensitive fuzzy search
    search_filter = {
        "family_id": tree_oid,
        "$or": [
            {"first_name": {"$regex": q, "$options": "i"}},
            {"last_name": {"$regex": q, "$options": "i"}},
            {"maiden_name": {"$regex": q, "$options": "i"}}
        ]
    }
    
    skip = (page - 1) * page_size
    persons = await genealogy_person_repo.find_many(
        filter_dict=search_filter,
        skip=skip,
        limit=page_size,
        sort_by="last_name",
        sort_order=1
    )
    
    total = await genealogy_person_repo.count(search_filter)
    
    person_responses = [person_doc_to_response(doc) for doc in persons]
    
    return create_paginated_response(
        items=person_responses,
        total=total,
        page=page,
        page_size=page_size,
        message=f"Found {total} matching persons"
    )


@router.get("/persons")
async def list_genealogy_persons(
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all persons in family tree with pagination"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id))
    
    skip = (page - 1) * page_size
    persons = await genealogy_person_repo.find_by_tree(
        tree_id=str(tree_oid),
        skip=skip,
        limit=page_size
    )
    
    total = await genealogy_person_repo.count({"family_id": tree_oid})
    
    person_responses = [person_doc_to_response(doc) for doc in persons]
    
    return create_paginated_response(
        items=person_responses,
        total=total,
        page=page,
        page_size=page_size,
        message="Persons retrieved successfully"
    )


@router.get("/persons/{person_id}")
async def get_genealogy_person(
    person_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific person"""
    person_doc = await genealogy_person_repo.find_by_id(
        person_id,
        raise_404=True,
        error_message="Person not found"
    )
    if person_doc is None:
        raise HTTPException(status_code=404, detail="Person not found")
    
    await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id))
    
    return create_success_response(
        message="Person retrieved successfully",
        data=person_doc_to_response(person_doc)
    )


@router.put("/persons/{person_id}")
async def update_genealogy_person(
    person_id: str,
    person_update: GenealogyPersonUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a person"""
    person_doc = await genealogy_person_repo.find_by_id(
        person_id,
        raise_404=True,
        error_message="Person not found"
    )
    if person_doc is None:
        raise HTTPException(status_code=404, detail="Person not found")
    
    await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id), required_roles=["owner", "member"])
    
    person_update_dict = person_update.dict(exclude_unset=True)
    update_data = {k: v for k, v in person_update_dict.items() if v is not None}
    unset_data = {}
    
    if "linked_user_id" in person_update_dict:
        if person_update.linked_user_id is None or person_update.linked_user_id == "":
            unset_data["linked_user_id"] = ""
            update_data.pop("linked_user_id", None)
        else:
            linked_user_oid = genealogy_person_repo.validate_object_id(person_update.linked_user_id, "linked_user_id")
            
            await validate_user_exists(person_update.linked_user_id)
            
            existing_link = await genealogy_person_repo.find_one({
                "linked_user_id": linked_user_oid,
                "_id": {"$ne": ObjectId(person_id)}
            }, raise_404=False)
            
            if existing_link:
                raise HTTPException(
                    status_code=400, 
                    detail="This user is already linked to another genealogy person"
                )
            update_data["linked_user_id"] = linked_user_oid
    
    if "death_date" in update_data or "is_alive" in update_data:
        death_date = update_data.get("death_date", person_doc.get("death_date"))
        is_alive_override = update_data.get("is_alive")
        update_data["is_alive"] = compute_is_alive(death_date, is_alive_override)
    
    updated_person = await genealogy_person_repo.update_by_id(person_id, update_data)
    if updated_person is None:
        raise HTTPException(status_code=404, detail="Person not found")
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="UPDATE_GENEALOGY_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": person_id,
            "updates": list(update_data.keys())
        }
    )
    
    return create_success_response(
        message="Person updated successfully",
        data=person_doc_to_response(updated_person)
    )


@router.delete("/persons/{person_id}", status_code=status.HTTP_200_OK)
async def delete_genealogy_person(
    person_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a person"""
    person_doc = await genealogy_person_repo.find_by_id(
        person_id,
        raise_404=True,
        error_message="Person not found"
    )
    if person_doc is None:
        raise HTTPException(status_code=404, detail="Person not found")
    
    await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id), required_roles=["owner"])
    
    await genealogy_person_repo.delete_by_id(person_id)
    
    await genealogy_relationship_repo.collection.delete_many({
        "$or": [
            {"person1_id": ObjectId(person_id)},
            {"person2_id": ObjectId(person_id)}
        ]
    })
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="DELETE_GENEALOGY_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": person_id,
            "first_name": person_doc.get("first_name"),
            "last_name": person_doc.get("last_name")
        }
    )
    
    return create_success_response(message="Person deleted successfully")


