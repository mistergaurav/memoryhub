"""
Audit log schemas for tracking health record actions
"""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum


class AuditAction(str, Enum):
    """Types of auditable actions"""
    CREATED = "created"
    UPDATED = "updated"
    DELETED = "deleted"
    ASSIGNED = "assigned"
    APPROVED = "approved"
    REJECTED = "rejected"
    VIEWED = "viewed"
    SHARED = "shared"
    UNSHARED = "unshared"


class AuditLogCreate(BaseModel):
    """Schema for creating an audit log entry"""
    resource_type: str = Field(..., description="Type of resource (e.g., health_record, reminder)")
    resource_id: str = Field(..., description="ID of the resource")
    action: AuditAction = Field(..., description="Action performed")
    actor_id: str = Field(..., description="ID of user who performed the action")
    actor_name: str = Field(..., description="Name of user who performed the action")
    target_user_id: Optional[str] = Field(None, description="ID of user affected by the action")
    target_user_name: Optional[str] = Field(None, description="Name of user affected by the action")
    old_value: Optional[Dict[str, Any]] = Field(None, description="Previous value before change")
    new_value: Optional[Dict[str, Any]] = Field(None, description="New value after change")
    remarks: Optional[str] = Field(None, max_length=1000, description="Additional notes or comments")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional contextual data")
    ip_address: Optional[str] = Field(None, description="IP address of the actor")
    user_agent: Optional[str] = Field(None, description="User agent string")


class AuditLogResponse(BaseModel):
    """Schema for audit log response"""
    id: str
    resource_type: str
    resource_id: str
    action: AuditAction
    actor_id: str
    actor_name: str
    target_user_id: Optional[str] = None
    target_user_name: Optional[str] = None
    old_value: Optional[Dict[str, Any]] = None
    new_value: Optional[Dict[str, Any]] = None
    remarks: Optional[str] = None
    metadata: Dict[str, Any] = {}
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    created_at: datetime


class HealthRecordAuditMetadata(BaseModel):
    """Metadata specific to health record audits"""
    record_title: Optional[str] = None
    record_type: Optional[str] = None
    subject_name: Optional[str] = None
    approval_status: Optional[str] = None
    visibility_scope: Optional[str] = None
    rejection_reason: Optional[str] = None
