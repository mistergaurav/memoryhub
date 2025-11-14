"""
Notification details endpoint for health record assignments
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from datetime import datetime
from bson import ObjectId
import logging

from app.schemas.notification import HealthRecordNotificationDetail, NotificationStatus
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.models.responses import create_success_response

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/{notification_id}/details", response_model=None)
async def get_notification_details(
    notification_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get detailed information for a health record assignment notification.
    
    This endpoint provides all the information needed to display the notification
    details page, including the health record summary, assigner info, and action buttons.
    """
    try:
        # Get notification
        notification = await get_collection("notifications").find_one({
            "_id": ObjectId(notification_id),
            "user_id": ObjectId(current_user.id)
        })
        
        if not notification:
            raise HTTPException(status_code=404, detail="Notification not found")
        
        # Check if this is a health record assignment notification
        if notification.get("type") != "health_record_assigned":
            raise HTTPException(
                status_code=400,
                detail="This endpoint is only for health record assignment notifications"
            )
        
        health_record_id = notification.get("health_record_id")
        if not health_record_id:
            raise HTTPException(
                status_code=400,
                detail="No health record associated with this notification"
            )
        
        # Get health record
        health_record = await get_collection("health_records").find_one({
            "_id": health_record_id
        })
        
        if not health_record:
            raise HTTPException(status_code=404, detail="Health record not found")
        
        # Get assigner information
        assigner_id = notification.get("assigner_id") or health_record.get("created_by")
        assigner = await get_collection("users").find_one({"_id": assigner_id})
        
        assigner_name = notification.get("assigner_name") or (assigner.get("full_name") if assigner else "Unknown")
        assigner_avatar = assigner.get("avatar_url") if assigner else None
        
        # Check if there's a reminder
        reminder = None
        if notification.get("has_reminder"):
            reminder = await get_collection("health_record_reminders").find_one({
                "record_id": health_record_id,
                "assigned_user_id": ObjectId(current_user.id),
                "status": {"$nin": ["completed", "cancelled"]}
            })
        
        # Determine approval status
        approval_status = notification.get("approval_status", "pending")
        if health_record.get("approval_status") == "approved":
            approval_status = "approved"
        elif health_record.get("approval_status") == "rejected":
            approval_status = "rejected"
        
        # Check if user can approve/reject
        can_approve = approval_status == "pending" and str(current_user.id) in [
            str(uid) for uid in health_record.get("assigned_user_ids", [])
        ]
        can_reject = can_approve
        
        # Build detailed response
        detail = HealthRecordNotificationDetail(
            notification_id=str(notification["_id"]),
            health_record_id=str(health_record["_id"]),
            record_title=health_record.get("title", "Untitled Record"),
            record_type=health_record.get("record_type", "medical"),
            record_description=health_record.get("description"),
            record_date=health_record.get("date", ""),
            record_provider=health_record.get("provider"),
            record_severity=health_record.get("severity"),
            assigner_id=str(assigner_id),
            assigner_name=assigner_name,
            assigner_avatar=assigner_avatar,
            assigned_at=notification.get("assigned_at") or notification.get("created_at"),
            has_reminder=notification.get("has_reminder", False),
            reminder_due_at=reminder.get("due_at") if reminder else None,
            reminder_title=reminder.get("title") if reminder else None,
            approval_status=NotificationStatus(approval_status),
            can_approve=can_approve,
            can_reject=can_reject,
            record_summary={
                "medications": health_record.get("medications", []),
                "notes": health_record.get("notes"),
                "attachments": health_record.get("attachments", []),
                "is_confidential": health_record.get("is_confidential", False),
                "visibility_scope": health_record.get("visibility_scope", "private")
            },
            metadata=notification.get("metadata", {})
        )
        
        return create_success_response(
            message="Notification details retrieved successfully",
            data=detail
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting notification details: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="An error occurred while retrieving notification details"
        )


@router.get("/health-records/{record_id}/summary")
async def get_health_record_summary(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a summary of a health record for notification display.
    
    This is a lightweight endpoint that returns only the essential information
    needed to display in notification details.
    """
    try:
        # Get health record
        health_record = await get_collection("health_records").find_one({
            "_id": ObjectId(record_id)
        })
        
        if not health_record:
            raise HTTPException(status_code=404, detail="Health record not found")
        
        # Check if user has access
        user_oid = ObjectId(current_user.id)
        has_access = (
            health_record.get("created_by") == user_oid or
            user_oid in health_record.get("assigned_user_ids", []) or
            health_record.get("subject_user_id") == user_oid
        )
        
        if not has_access:
            raise HTTPException(status_code=403, detail="Not authorized to view this record")
        
        # Get creator information
        creator = await get_collection("users").find_one({"_id": health_record.get("created_by")})
        
        summary = {
            "id": str(health_record["_id"]),
            "title": health_record.get("title"),
            "type": health_record.get("record_type"),
            "description": health_record.get("description"),
            "date": health_record.get("date"),
            "provider": health_record.get("provider"),
            "severity": health_record.get("severity"),
            "approval_status": health_record.get("approval_status", "approved"),
            "visibility_scope": health_record.get("visibility_scope", "private"),
            "created_by_name": creator.get("full_name") if creator else "Unknown",
            "created_at": health_record.get("created_at"),
            "has_attachments": len(health_record.get("attachments", [])) > 0,
            "has_medications": len(health_record.get("medications", [])) > 0,
            "is_confidential": health_record.get("is_confidential", False)
        }
        
        return create_success_response(
            message="Health record summary retrieved successfully",
            data=summary
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting health record summary: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="An error occurred while retrieving health record summary"
        )
