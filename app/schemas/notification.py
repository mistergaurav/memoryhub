from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class NotificationType(str, Enum):
    LIKE = "like"
    COMMENT = "comment"
    FOLLOW = "follow"
    HUB_INVITE = "hub_invite"
    MENTION = "mention"
    MEMORY_SHARE = "memory_share"
    HEALTH_RECORD_ASSIGNMENT = "health_record_assignment"
    HEALTH_REMINDER_ASSIGNMENT = "health_reminder_assignment"
    HEALTH_RECORD_APPROVED = "health_record_approved"
    HEALTH_RECORD_REJECTED = "health_record_rejected"

class NotificationResponse(BaseModel):
    id: str
    type: NotificationType
    title: str
    message: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    actor_id: str
    actor_name: Optional[str] = None
    actor_avatar: Optional[str] = None
    is_read: bool = False
    created_at: datetime

class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
    total: int
    unread_count: int
    page: int
    pages: int
