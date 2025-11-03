"""Genealogy relationship management."""
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


from .utils import relationship_doc_to_response
from .permissions import ensure_tree_access

@router.post("/relationships", status_code=status.HTTP_201_CREATED)
async def create_genealogy_relationship(
    relationship: GenealogyRelationshipCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create relationship between two persons"""
    person1_oid = genealogy_person_repo.validate_object_id(relationship.person1_id, "person1_id")
    person2_oid = genealogy_person_repo.validate_object_id(relationship.person2_id, "person2_id")
    
    person1 = await genealogy_person_repo.find_one(
        {"_id": person1_oid},
        raise_404=True,
        error_message="Person 1 not found"
    )
    if person1 is None:
        raise HTTPException(status_code=404, detail="Person 1 not found")
    
    person2 = await genealogy_person_repo.find_one(
        {"_id": person2_oid},
        raise_404=True,
        error_message="Person 2 not found"
    )
    if person2 is None:
        raise HTTPException(status_code=404, detail="Person 2 not found")
    
    if str(person1["family_id"]) != str(person2["family_id"]):
        raise HTTPException(status_code=400, detail="Cannot create relationship between persons from different trees")
    
    tree_id = person1["family_id"]
    
    await ensure_tree_access(tree_id, ObjectId(current_user.id), required_roles=["owner", "member"])
    
    relationship_data = {
        "family_id": tree_id,
        "person1_id": person1_oid,
        "person2_id": person2_oid,
        "relationship_type": relationship.relationship_type,
        "notes": relationship.notes,
        "created_by": ObjectId(current_user.id)
    }
    
    relationship_doc = await genealogy_relationship_repo.create(relationship_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_GENEALOGY_RELATIONSHIP",
        event_details={
            "resource_type": "genealogy_relationship",
            "resource_id": str(relationship_doc["_id"]),
            "relationship_type": relationship.relationship_type,
            "person1_id": relationship.person1_id,
            "person2_id": relationship.person2_id
        }
    )
    
    return create_success_response(
        message="Relationship created successfully",
        data=relationship_doc_to_response(relationship_doc)
    )


@router.get("/relationships")
async def list_genealogy_relationships(
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all relationships in a family tree with pagination"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id))
    
    skip = (page - 1) * page_size
    relationships = await genealogy_relationship_repo.find_by_tree(
        tree_id=str(tree_oid),
        skip=skip,
        limit=page_size
    )
    
    total = await genealogy_relationship_repo.count({"family_id": tree_oid})
    
    relationship_responses = [relationship_doc_to_response(doc) for doc in relationships]
    
    return create_paginated_response(
        items=relationship_responses,
        total=total,
        page=page,
        page_size=page_size,
        message="Relationships retrieved successfully"
    )


@router.delete("/relationships/{relationship_id}", status_code=status.HTTP_200_OK)
async def delete_genealogy_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a relationship"""
    relationship_doc = await genealogy_relationship_repo.find_by_id(
        relationship_id,
        raise_404=True,
        error_message="Relationship not found"
    )
    if relationship_doc is None:
        raise HTTPException(status_code=404, detail="Relationship not found")
    
    tree_id = relationship_doc["family_id"]
    
    await ensure_tree_access(tree_id, ObjectId(current_user.id), required_roles=["owner", "member"])
    
    await genealogy_relationship_repo.delete_by_id(relationship_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="DELETE_GENEALOGY_RELATIONSHIP",
        event_details={
            "resource_type": "genealogy_relationship",
            "resource_id": relationship_id,
            "relationship_type": relationship_doc.get("relationship_type")
        }
    )
    
    return create_success_response(message="Relationship deleted successfully")


