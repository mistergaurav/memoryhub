"""Relationship endpoints using dual-row pattern."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.models.relationships import (
    RelationshipInviteRequest,
    RelationshipResponse,
    RelationshipStatus
)
from app.repositories.relationships import RelationshipRepository
from app.models.responses import create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event


router = APIRouter()
relationship_repo = RelationshipRepository()


async def get_user_info(user_id: ObjectId) -> dict:
    """Get basic user info."""
    from app.repositories.family.users import UserRepository
    user_repo = UserRepository()
    user = await user_repo.find_one({"_id": user_id}, raise_404=False)
    if user:
        return {
            "id": str(user["_id"]),
            "name": user.get("full_name", "Unknown User"),
            "avatar": user.get("avatar_url"),
            "email": user.get("email")
        }
    return {"id": str(user_id), "name": "Unknown User", "avatar": None, "email": None}


def build_relationship_response(relationship: dict) -> dict:
    """Build relationship response."""
    return {
        "id": str(relationship["_id"]),
        "user_id": str(relationship["user_id"]),
        "related_user_id": str(relationship["related_user_id"]),
        "relationship_type": relationship["relationship_type"],
        "relationship_label": relationship.get("relationship_label"),
        "status": relationship["status"],
        "requester_id": str(relationship["requester_id"]),
        "is_requester": relationship["user_id"] == relationship["requester_id"],
        "created_at": relationship["created_at"],
        "updated_at": relationship["updated_at"],
        "metadata": relationship.get("metadata", {})
    }


@router.post("/invite", status_code=status.HTTP_201_CREATED)
async def send_relationship_invite(
    invite: RelationshipInviteRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Send a relationship invitation.
    Creates two rows (dual-row pattern): one for sender, one for receiver.
    """
    try:
        # Validate related user exists
        from app.repositories.family.users import UserRepository
        user_repo = UserRepository()
        related_user = await user_repo.find_by_id(
            invite.related_user_id,
            raise_404=True,
            error_message="Related user not found"
        )
        
        # Cannot send to self
        if invite.related_user_id == str(current_user.id):
            raise HTTPException(
                status_code=400,
                detail="Cannot send relationship invitation to yourself"
            )
        
        # Create relationship pair
        requester_row, receiver_row = await relationship_repo.create_relationship_pair(
            user_id=str(current_user.id),
            related_user_id=invite.related_user_id,
            relationship_type=invite.relationship_type,
            relationship_label=invite.relationship_label,
            message=invite.message
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="relationship_invite_sent",
            event_details={
                "relationship_id": str(requester_row["_id"]),
                "related_user_id": invite.related_user_id,
                "relationship_type": invite.relationship_type
            }
        )
        
        # Get related user info
        related_user_info = await get_user_info(ObjectId(invite.related_user_id))
        
        response_data = build_relationship_response(requester_row)
        response_data["related_user_name"] = related_user_info["name"]
        response_data["related_user_avatar"] = related_user_info["avatar"]
        response_data["related_user_email"] = related_user_info["email"]
        
        return create_success_response(
            message="Relationship invitation sent successfully",
            data=response_data
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send invitation: {str(e)}"
        )


@router.get("")
async def get_relationships(
    status_filter: Optional[str] = Query(None, description="Filter by status"),
    relationship_type_filter: Optional[str] = Query(None, description="Filter by relationship type"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user's relationships with optional filters."""
    try:
        skip = (page - 1) * page_size
        
        relationships = await relationship_repo.find_by_user(
            user_id=str(current_user.id),
            status_filter=status_filter,
            relationship_type_filter=relationship_type_filter,
            skip=skip,
            limit=page_size
        )
        
        # Enrich with user info
        enriched = []
        for rel in relationships:
            related_user_info = await get_user_info(rel["related_user_id"])
            
            response_data = build_relationship_response(rel)
            response_data["related_user_name"] = related_user_info["name"]
            response_data["related_user_avatar"] = related_user_info["avatar"]
            response_data["related_user_email"] = related_user_info["email"]
            
            enriched.append(response_data)
        
        # Count total
        total = len(enriched)  # Simple count for now
        
        return create_paginated_response(
            items=enriched,
            total=total,
            page=page,
            page_size=page_size,
            message="Relationships retrieved successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve relationships: {str(e)}"
        )


@router.get("/requests")
async def get_pending_requests(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get pending relationship requests where user is the receiver."""
    try:
        requests = await relationship_repo.find_pending_requests(
            str(current_user.id)
        )
        
        # Enrich with user info
        enriched = []
        for req in requests:
            related_user_info = await get_user_info(req["related_user_id"])
            
            response_data = build_relationship_response(req)
            response_data["related_user_name"] = related_user_info["name"]
            response_data["related_user_avatar"] = related_user_info["avatar"]
            response_data["related_user_email"] = related_user_info["email"]
            
            enriched.append(response_data)
        
        return create_success_response(
            message="Pending requests retrieved successfully",
            data=enriched
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve requests: {str(e)}"
        )


@router.post("/{relationship_id}/accept")
async def accept_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Accept a relationship request (updates both rows to accepted)."""
    try:
        receiver_row, requester_row = await relationship_repo.accept_relationship(
            relationship_id,
            str(current_user.id)
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="relationship_accepted",
            event_details={
                "relationship_id": relationship_id,
                "requester_id": str(requester_row["user_id"])
            }
        )
        
        # Get related user info
        related_user_info = await get_user_info(receiver_row["related_user_id"])
        
        response_data = build_relationship_response(receiver_row)
        response_data["related_user_name"] = related_user_info["name"]
        response_data["related_user_avatar"] = related_user_info["avatar"]
        
        return create_success_response(
            message="Relationship accepted successfully",
            data=response_data
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to accept relationship: {str(e)}"
        )


@router.post("/{relationship_id}/reject")
async def reject_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Reject a relationship request (updates both rows)."""
    try:
        receiver_row, requester_row = await relationship_repo.reject_relationship(
            relationship_id,
            str(current_user.id)
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="relationship_rejected",
            event_details={"relationship_id": relationship_id}
        )
        
        return create_success_response(
            message="Relationship rejected successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to reject relationship: {str(e)}"
        )


@router.post("/{relationship_id}/block")
async def block_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Block a relationship (updates both rows)."""
    try:
        blocked = await relationship_repo.block_relationship(
            relationship_id,
            str(current_user.id)
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="relationship_blocked",
            event_details={"relationship_id": relationship_id}
        )
        
        return create_success_response(
            message="Relationship blocked successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to block relationship: {str(e)}"
        )


@router.delete("/{relationship_id}")
async def delete_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a relationship (removes both rows)."""
    try:
        await relationship_repo.delete_relationship_pair(
            relationship_id,
            str(current_user.id)
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="relationship_deleted",
            event_details={"relationship_id": relationship_id}
        )
        
        return create_success_response(
            message="Relationship deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete relationship: {str(e)}"
        )
