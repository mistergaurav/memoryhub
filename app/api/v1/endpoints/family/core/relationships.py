"""Family relationship management endpoints."""
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
from app.repositories.family_repository import (
    FamilyRepository,
    FamilyRelationshipRepository,
    FamilyInvitationRepository,
    UserRepository
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
from app.models.responses import create_message_response, create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event
from .utils import get_user_data

router = APIRouter()

family_repo = FamilyRepository()
relationship_repo = FamilyRelationshipRepository()
invitation_repo = FamilyInvitationRepository()
user_repo = UserRepository()


@router.post("/relationships", status_code=status.HTTP_201_CREATED)
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
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_relationship_created",
            event_details={
                "relationship_id": str(relationship_doc["_id"]),
                "related_user_id": relationship.related_user_id,
                "relation_type": relationship.relation_type
            }
        )
        
        relationship_response = FamilyRelationshipResponse(
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
        
        return create_success_response(
            message="Relationship created successfully",
            data=relationship_response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create relationship: {str(e)}")


@router.get("/relationships")
async def list_family_relationships(
    relation_type: Optional[FamilyRelationType] = None,
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=100, description="Number of records per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all family relationships for the current user with pagination"""
    try:
        skip = (page - 1) * page_size
        
        relationships_docs = await relationship_repo.find_by_user(
            str(current_user.id),
            relation_type=relation_type.value if relation_type else None,
            skip=skip,
            limit=page_size
        )
        
        total = await relationship_repo.count_by_user(
            str(current_user.id),
            relation_type=relation_type.value if relation_type else None
        )
        
        relationships = []
        for rel_doc in relationships_docs:
            user_data = await get_user_data(rel_doc["related_user_id"])
            relationships.append(FamilyRelationshipResponse(
                id=str(rel_doc["_id"]),
                user_id=str(rel_doc["user_id"]),
                related_user_id=str(rel_doc["related_user_id"]),
                related_user_name=user_data.get("name"),
                related_user_avatar=user_data.get("avatar"),
                related_user_email=user_data.get("email"),
                relation_type=rel_doc["relation_type"],
                relation_label=rel_doc.get("relation_label"),
                notes=rel_doc.get("notes"),
                created_at=rel_doc["created_at"],
                updated_at=rel_doc["updated_at"]
            ))
        
        return create_paginated_response(
            items=[r.model_dump() for r in relationships],
            total=total,
            page=page,
            page_size=page_size,
            message="Relationships retrieved successfully"
        )
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
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_relationship_deleted",
            event_details={"relationship_id": relationship_id}
        )
        
        return create_message_response("Relationship deleted successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete relationship: {str(e)}")


