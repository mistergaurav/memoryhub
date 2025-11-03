"""Family member and tree management endpoints."""
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


@router.get("/tree")
async def get_family_tree(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(100, ge=1, le=500, description="Number of nodes per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get the family tree for the current user with pagination"""
    try:
        skip = (page - 1) * page_size
        relationships_docs = await relationship_repo.find_by_user(str(current_user.id), skip=skip, limit=page_size)
        total = await relationship_repo.count_by_user(str(current_user.id))
        tree_nodes = []
        
        for rel in relationships_docs:
            user_data = await get_user_data(rel["related_user_id"])
            if user_data.get("name"):
                tree_nodes.append(FamilyTreeNode(
                    user_id=user_data["id"],
                    name=user_data.get("name", "Unknown"),
                    avatar_url=user_data.get("avatar"),
                    relation_type=rel["relation_type"],
                    relation_label=rel.get("relation_label"),
                    children=[]
                ))
        
        return create_paginated_response(
            items=[node.model_dump() for node in tree_nodes],
            total=total,
            page=page,
            page_size=page_size,
            message="Family tree retrieved successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get family tree: {str(e)}")


@router.post("/add-member", response_model=dict)
async def add_family_member(
    request: AddFamilyMemberRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Smart endpoint to add a family member - creates relationship and optionally sends invitation"""
    try:
        user = await user_repo.find_by_email(request.email)
        
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


