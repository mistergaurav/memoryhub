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


from .utils import person_doc_to_response, validate_user_exists
from .permissions import ensure_tree_access

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


