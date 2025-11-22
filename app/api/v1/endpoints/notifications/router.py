from fastapi import APIRouter, Depends, HTTPException, status, Query, Body
from typing import List, Optional, Dict, Any
from datetime import datetime
from bson import ObjectId
import logging

from app.schemas.notification import (
    NotificationResponse,
    NotificationType
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

logger = logging.getLogger(__name__)

router = APIRouter()

async def _prepare_notification_response(notif_doc: dict) -> NotificationResponse:
    """Prepare notification document for API response"""
    actor = await get_collection("users").find_one({"_id": notif_doc["actor_id"]})
    
    return NotificationResponse(
        id=str(notif_doc["_id"]),
        type=notif_doc["type"],
        title=notif_doc["title"],
        message=notif_doc["message"],
        target_type=notif_doc.get("target_type"),
        target_id=str(notif_doc["target_id"]) if notif_doc.get("target_id") else None,
        actor_id=str(notif_doc["actor_id"]),
        actor_name=actor.get("full_name") or actor.get("email") or "Unknown User" if actor else "Unknown User",
        actor_avatar=actor.get("avatar_url") if actor else None,
        is_read=notif_doc.get("is_read", False),
        created_at=notif_doc["created_at"],
        health_record_id=str(notif_doc["health_record_id"]) if notif_doc.get("health_record_id") else None,
        assigner_id=str(notif_doc["assigner_id"]) if notif_doc.get("assigner_id") else None,
        assigner_name=notif_doc.get("assigner_name"),
        assigned_at=notif_doc.get("assigned_at"),
        has_reminder=notif_doc.get("has_reminder", False),
        reminder_due_at=notif_doc.get("reminder_due_at"),
        record_title=notif_doc.get("record_title"),
        record_type=notif_doc.get("record_type"),
        record_date=notif_doc.get("record_date"),
        approval_status=notif_doc.get("approval_status"),
        resolved_at=notif_doc.get("resolved_at"),
        metadata=notif_doc.get("metadata", {})
    )

@router.get("/")
async def list_notifications(
    is_read: Optional[bool] = None,
    notification_type: Optional[NotificationType] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """List notifications for current user"""
    user_id_obj = ObjectId(current_user.id)
    query: Dict[str, Any] = {"user_id": user_id_obj}
    
    if is_read is not None:
        query["is_read"] = is_read
    if notification_type:
        query["type"] = notification_type
    
    total = await get_collection("notifications").count_documents(query)
    unread_count = await get_collection("notifications").count_documents({
        "user_id": user_id_obj,
        "is_read": False
    })
    
    skip = (page - 1) * limit
    pages = (total + limit - 1) // limit
    
    cursor = get_collection("notifications").find(query).sort("created_at", -1).skip(skip).limit(limit)
    
    notifications = []
    async for notif_doc in cursor:
        notifications.append(await _prepare_notification_response(notif_doc))
    
    from app.models.responses import create_success_response
    
    return create_success_response(
        message="Notifications retrieved successfully",
        data={
            "notifications": notifications,
            "total": total,
            "unread_count": unread_count,
            "page": page,
            "pages": pages
        }
    )

@router.put("/{notification_id}/read", status_code=status.HTTP_200_OK)
async def mark_as_read(
    notification_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark a notification as read"""
    notif = await get_collection("notifications").find_one({
        "_id": ObjectId(notification_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    await get_collection("notifications").update_one(
        {"_id": ObjectId(notification_id)},
        {"$set": {"is_read": True}}
    )
    
    return {"message": "Notification marked as read"}

@router.put("/read-all", status_code=status.HTTP_200_OK)
async def mark_all_as_read(
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark all notifications as read"""
    result = await get_collection("notifications").update_many(
        {"user_id": ObjectId(current_user.id), "is_read": False},
        {"$set": {"is_read": True}}
    )
    
    return {"message": f"{result.modified_count} notifications marked as read"}

@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    notification_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a notification"""
    result = await get_collection("notifications").delete_one({
        "_id": ObjectId(notification_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")

@router.delete("/", status_code=status.HTTP_200_OK)
async def delete_all_notifications(
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete all notifications for current user"""
    result = await get_collection("notifications").delete_many({
        "user_id": ObjectId(current_user.id)
    })
    
    return {"message": f"{result.deleted_count} notifications deleted"}

# --- Settings Endpoints ---

@router.get("/settings")
async def get_notification_settings(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user notification settings"""
    return current_user.settings.get("notifications", {
        "email_notifications": True,
        "push_notifications": True,
        "health_updates": True,
        "family_activity": True,
        "memories": True
    })

@router.put("/settings")
async def update_notification_settings(
    settings: Dict[str, bool] = Body(...),
    current_user: UserInDB = Depends(get_current_user)
):
    """Update user notification settings"""
    # Merge with existing settings
    current_settings = current_user.settings.get("notifications", {})
    updated_settings = {**current_settings, **settings}
    
    await get_collection("users").update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": {"settings.notifications": updated_settings}}
    )
    
    return updated_settings
