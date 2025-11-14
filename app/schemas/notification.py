from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum


class NotificationType(str, Enum):
    CONNECTION_REQUEST = "connection_request"
    CONNECTION_ACCEPTED = "connection_accepted"
    HUB_INVITE = "hub_invite"
    HUB_JOIN_REQUEST = "hub_join_request"
    HUB_POST = "hub_post"
    COMMENT = "comment"
    LIKE = "like"
    MENTION = "mention"
    SHARE = "share"
    FOLLOW = "follow"
    EVENT_REMINDER = "event_reminder"
    BIRTHDAY = "birthday"
    ANNIVERSARY = "anniversary"
    HEALTH_RECORD_ASSIGNED = "health_record_assigned"
    HEALTH_RECORD_APPROVED = "health_record_approved"
    HEALTH_RECORD_REJECTED = "health_record_rejected"
    REMINDER_DUE = "reminder_due"
    SYSTEM = "system"


class NotificationStatus(str, Enum):
    """Status for health record assignment notifications"""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class NotificationBase(BaseModel):
    type: NotificationType
    title: str
    message: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    is_read: bool = False


class NotificationCreate(NotificationBase):
    user_id: str
    actor_id: str
    # Health record assignment specific fields
    health_record_id: Optional[str] = None
    assigner_id: Optional[str] = None
    assigner_name: Optional[str] = None
    assigned_at: Optional[datetime] = None
    has_reminder: bool = False
    reminder_due_at: Optional[datetime] = None
    record_title: Optional[str] = None
    record_type: Optional[str] = None
    record_date: Optional[str] = None
    approval_status: Optional[NotificationStatus] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class NotificationResponse(BaseModel):
    id: str
    type: NotificationType
    title: str
    message: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    actor_id: str
    actor_name: str
    actor_avatar: Optional[str] = None
    is_read: bool
    created_at: datetime
    # Health record assignment specific fields
    health_record_id: Optional[str] = None
    assigner_id: Optional[str] = None
    assigner_name: Optional[str] = None
    assigned_at: Optional[datetime] = None
    has_reminder: bool = False
    reminder_due_at: Optional[datetime] = None
    record_title: Optional[str] = None
    record_type: Optional[str] = None
    record_date: Optional[str] = None
    approval_status: Optional[NotificationStatus] = None
    resolved_at: Optional[datetime] = None
    metadata: Dict[str, Any] = {}


class NotificationListResponse(BaseModel):
    notifications: List[NotificationResponse]
    total: int
    unread_count: int
    page: int
    pages: int


class HealthRecordNotificationDetail(BaseModel):
    """Detailed notification information for health record assignments"""
    notification_id: str
    health_record_id: str
    record_title: str
    record_type: str
    record_description: Optional[str] = None
    record_date: str
    record_provider: Optional[str] = None
    record_severity: Optional[str] = None
    assigner_id: str
    assigner_name: str
    assigner_avatar: Optional[str] = None
    assigned_at: datetime
    has_reminder: bool
    reminder_due_at: Optional[datetime] = None
    reminder_title: Optional[str] = None
    approval_status: NotificationStatus
    can_approve: bool
    can_reject: bool
    record_summary: Dict[str, Any] = {}
    metadata: Dict[str, Any] = {}
