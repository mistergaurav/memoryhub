"""Family invitation handling endpoints."""
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


@router.post("/invitations", status_code=status.HTTP_201_CREATED)
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
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_invitation_created",
            event_details={
                "invitation_id": str(invitation_doc["_id"]),
                "invitee_email": invitation.invitee_email,
                "circle_count": len(circle_oids)
            }
        )
        
        from os import getenv
        base_url = getenv("REPLIT_DOMAINS", "localhost:5000").split(",")[0]
        if not base_url.startswith("http"):
            base_url = f"https://{base_url}"
        invite_url = f"{base_url}/accept-family-invite?token={token}"
        
        invitation_response = FamilyInvitationResponse(
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
        
        return create_success_response(
            message="Invitation created successfully",
            data=invitation_response.model_dump()
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
            await family_repo.add_member(
                str(circle_id),
                str(current_user.id),
                str(invitation["inviter_id"])
            )
        
        await invitation_repo.update(
            {"_id": invitation["_id"]},
            {
                "status": "accepted",
                "accepted_at": datetime.utcnow()
            }
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_invitation_accepted",
            event_details={
                "invitation_id": str(invitation["_id"]),
                "inviter_id": str(invitation["inviter_id"])
            }
        )
        
        return create_message_response("Invitation accepted successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to accept invitation: {str(e)}")


