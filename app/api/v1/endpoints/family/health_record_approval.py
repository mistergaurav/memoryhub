from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, List
from bson import ObjectId
from datetime import datetime
from pydantic import BaseModel, Field

from app.models.family.health_records import (
    ApprovalStatus, VisibilityType, FamilyCircleType
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.features.health_records.repositories.health_records_repository import HealthRecordsRepository
from app.repositories.family.users import UserRepository
from app.models.responses import create_success_response
from app.services.notification_service import NotificationService
from app.schemas.notification import NotificationStatus
from app.utils.audit_logger import log_audit_event

router = APIRouter()

health_records_repo = HealthRecordsRepository()
users_repo = UserRepository()
notification_service = NotificationService()


class ApprovalRequest(BaseModel):
    """Request model for approving a health record with visibility settings"""
    visibility_type: VisibilityType
    visibility_user_ids: List[str] = Field(default_factory=list)
    visibility_family_circles: List[FamilyCircleType] = Field(default_factory=list)


class RejectionRequest(BaseModel):
    """Request model for rejecting a health record"""
    rejection_reason: str = Field(..., min_length=1, max_length=500)


@router.post("/{record_id}/approve", status_code=status.HTTP_200_OK)
async def approve_health_record(
    record_id: str,
    approval: ApprovalRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Approve a pending health record and set visibility settings.
    Only the subject user or assigned users can approve.
    """
    # Find the health record
    record_doc = await health_records_repo.find_by_id(
        record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    if not record_doc:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    user_oid = ObjectId(current_user.id)
    
    # Check if user has permission to approve
    is_subject = record_doc.get("subject_user_id") == user_oid
    is_assigned = user_oid in record_doc.get("assigned_user_ids", [])
    
    if not (is_subject or is_assigned):
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to approve this health record"
        )
    
    # Check if already approved or rejected
    current_status = record_doc.get("approval_status")
    if current_status == ApprovalStatus.APPROVED.value:
        raise HTTPException(status_code=400, detail="Health record is already approved")
    if current_status == ApprovalStatus.REJECTED.value:
        raise HTTPException(status_code=400, detail="Health record has been rejected")
    
    # Validate visibility settings
    if approval.visibility_type == VisibilityType.SELECT_USERS:
        if not approval.visibility_user_ids:
            raise HTTPException(
                status_code=400,
                detail="visibility_user_ids is required when visibility_type is SELECT_USERS"
            )
        # Validate user IDs exist
        for user_id in approval.visibility_user_ids:
            try:
                ObjectId(user_id)
            except Exception:
                raise HTTPException(status_code=400, detail=f"Invalid user ID: {user_id}")
    
    if approval.visibility_type == VisibilityType.FAMILY_CIRCLE:
        if not approval.visibility_family_circles:
            raise HTTPException(
                status_code=400,
                detail="visibility_family_circles is required when visibility_type is FAMILY_CIRCLE"
            )
    
    # Update the health record
    update_data = {
        "approval_status": ApprovalStatus.APPROVED.value,
        "approved_at": datetime.utcnow(),
        "approved_by": str(current_user.id),
        "visibility_type": approval.visibility_type.value,
        "visibility_user_ids": [
            ObjectId(uid) for uid in approval.visibility_user_ids
        ] if approval.visibility_user_ids else [],
        "visibility_family_circles": [
            circle.value for circle in approval.visibility_family_circles
        ] if approval.visibility_family_circles else []
    }
    
    updated_record = await health_records_repo.update_by_id(record_id, update_data)
    
    if not updated_record:
        raise HTTPException(status_code=500, detail="Failed to approve health record")
    
    # Update notification status if exists
    from app.db.mongodb import get_collection
    notification = await get_collection("notifications").find_one({
        "health_record_id": ObjectId(record_id),
        "user_id": user_oid,
        "type": "health_record_assigned"
    })
    
    if notification:
        await notification_service.update_notification_status(
            str(notification["_id"]),
            NotificationStatus.APPROVED,
            str(current_user.id),
            current_user.full_name or current_user.email
        )
    
    # Log audit event
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="APPROVE_HEALTH_RECORD",
        event_details={
            "resource_type": "health_record",
            "resource_id": record_id,
            "visibility_type": approval.visibility_type.value,
            "approved_by": current_user.full_name or current_user.email
        }
    )
    
    return create_success_response(
        message="Health record approved successfully",
        data={
            "id": record_id,
            "approval_status": ApprovalStatus.APPROVED.value,
            "approved_at": update_data["approved_at"].isoformat(),
            "visibility_type": approval.visibility_type.value
        }
    )


@router.post("/{record_id}/reject", status_code=status.HTTP_200_OK)
async def reject_health_record(
    record_id: str,
    rejection: RejectionRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Reject a pending health record.
    Only the subject user or assigned users can reject.
    """
    # Find the health record
    record_doc = await health_records_repo.find_by_id(
        record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    if not record_doc:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    user_oid = ObjectId(current_user.id)
    
    # Check if user has permission to reject
    is_subject = record_doc.get("subject_user_id") == user_oid
    is_assigned = user_oid in record_doc.get("assigned_user_ids", [])
    
    if not (is_subject or is_assigned):
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to reject this health record"
        )
    
    # Check if already approved or rejected
    current_status = record_doc.get("approval_status")
    if current_status == ApprovalStatus.APPROVED.value:
        raise HTTPException(status_code=400, detail="Cannot reject an approved health record")
    if current_status == ApprovalStatus.REJECTED.value:
        raise HTTPException(status_code=400, detail="Health record is already rejected")
    
    # Update the health record
    update_data = {
        "approval_status": ApprovalStatus.REJECTED.value,
        "approved_at": datetime.utcnow(),
        "approved_by": str(current_user.id),
        "rejection_reason": rejection.rejection_reason
    }
    
    updated_record = await health_records_repo.update_by_id(record_id, update_data)
    
    if not updated_record:
        raise HTTPException(status_code=500, detail="Failed to reject health record")
    
    # Update notification status if exists
    from app.db.mongodb import get_collection
    notification = await get_collection("notifications").find_one({
        "health_record_id": ObjectId(record_id),
        "user_id": user_oid,
        "type": "health_record_assigned"
    })
    
    if notification:
        await notification_service.update_notification_status(
            str(notification["_id"]),
            NotificationStatus.REJECTED,
            str(current_user.id),
            current_user.full_name or current_user.email
        )
    
    # Log audit event
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="REJECT_HEALTH_RECORD",
        event_details={
            "resource_type": "health_record",
            "resource_id": record_id,
            "rejection_reason": rejection.rejection_reason,
            "rejected_by": current_user.full_name or current_user.email
        }
    )
    
    return create_success_response(
        message="Health record rejected successfully",
        data={
            "id": record_id,
            "approval_status": ApprovalStatus.REJECTED.value,
            "rejected_at": update_data["approved_at"].isoformat(),
            "rejection_reason": rejection.rejection_reason
        }
    )


@router.get("/pending", status_code=status.HTTP_200_OK)
async def get_pending_approvals(
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get all pending health records awaiting approval by the current user.
    """
    user_oid = ObjectId(current_user.id)
    
    # Find all pending records where user is subject or assigned
    pending_records = await health_records_repo.find_many(
        filter_dict={
            "approval_status": ApprovalStatus.PENDING_APPROVAL.value,
            "$or": [
                {"subject_user_id": user_oid},
                {"assigned_user_ids": user_oid}
            ]
        },
        sort_by="created_at",
        sort_order=-1,
        limit=100
    )
    
    # Batch-fetch creator information
    unique_creator_ids = set()
    for record in pending_records:
        if record.get("created_by"):
            unique_creator_ids.add(str(record["created_by"]))
    
    creator_lookup = {}
    if unique_creator_ids:
        creators = await users_repo.find_many(
            filter_dict={"_id": {"$in": [ObjectId(uid) for uid in unique_creator_ids]}},
            limit=len(unique_creator_ids)
        )
        creator_lookup = {
            str(creator["_id"]): {
                "full_name": creator.get("full_name", ""),
                "email": creator.get("email", ""),
                "avatar": creator.get("avatar_url", "")
            }
            for creator in creators
        }
    
    # Format response
    formatted_records = []
    for record in pending_records:
        creator_id = str(record["created_by"])
        creator_info = creator_lookup.get(creator_id, {})
        
        formatted_records.append({
            "id": str(record["_id"]),
            "title": record["title"],
            "record_type": record["record_type"],
            "description": record.get("description"),
            "date": record["date"],
            "severity": record.get("severity"),
            "created_by": creator_id,
            "created_by_name": creator_info.get("full_name", "Unknown"),
            "created_by_email": creator_info.get("email", ""),
            "created_by_avatar": creator_info.get("avatar", ""),
            "created_at": record["created_at"].isoformat(),
            "can_approve": True
        })
    
    return create_success_response(
        message=f"Found {len(formatted_records)} pending approvals",
        data={
            "pending_approvals": formatted_records,
            "total": len(formatted_records)
        }
    )
