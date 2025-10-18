from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId


class ContentRating(str, Enum):
    ALL_AGES = "all_ages"
    AGES_7_PLUS = "ages_7_plus"
    AGES_13_PLUS = "ages_13_plus"
    AGES_16_PLUS = "ages_16_plus"
    AGES_18_PLUS = "ages_18_plus"


class ApprovalStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class ParentalControlSettings(BaseModel):
    child_user_id: str
    content_rating_limit: ContentRating = ContentRating.ALL_AGES
    require_approval_for_posts: bool = True
    require_approval_for_sharing: bool = True
    restrict_external_contacts: bool = True
    allowed_features: List[str] = Field(default_factory=lambda: [
        "memories", "albums", "calendar", "recipes"
    ])
    screen_time_limit_minutes: Optional[int] = None


class ParentalControlSettingsCreate(ParentalControlSettings):
    pass


class ParentalControlSettingsUpdate(BaseModel):
    content_rating_limit: Optional[ContentRating] = None
    require_approval_for_posts: Optional[bool] = None
    require_approval_for_sharing: Optional[bool] = None
    restrict_external_contacts: Optional[bool] = None
    allowed_features: Optional[List[str]] = None
    screen_time_limit_minutes: Optional[int] = None


class ParentalControlSettingsInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    parent_user_id: PyObjectId
    child_user_id: PyObjectId
    content_rating_limit: ContentRating
    require_approval_for_posts: bool
    require_approval_for_sharing: bool
    restrict_external_contacts: bool
    allowed_features: List[str]
    screen_time_limit_minutes: Optional[int] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class ParentalControlSettingsResponse(BaseModel):
    id: str
    parent_user_id: str
    child_user_id: str
    child_name: Optional[str] = None
    content_rating_limit: ContentRating
    require_approval_for_posts: bool
    require_approval_for_sharing: bool
    restrict_external_contacts: bool
    allowed_features: List[str]
    screen_time_limit_minutes: Optional[int] = None
    created_at: datetime
    updated_at: datetime


class ContentApprovalRequest(BaseModel):
    content_type: str  # "memory", "album", "share", etc.
    content_id: str
    content_title: Optional[str] = None
    content_preview: Optional[str] = None


class ContentApprovalRequestInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    child_user_id: PyObjectId
    parent_user_id: PyObjectId
    content_type: str
    content_id: PyObjectId
    content_title: Optional[str] = None
    content_preview: Optional[str] = None
    status: ApprovalStatus = ApprovalStatus.PENDING
    parent_notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    reviewed_at: Optional[datetime] = None
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class ContentApprovalRequestResponse(BaseModel):
    id: str
    child_user_id: str
    child_name: Optional[str] = None
    parent_user_id: str
    content_type: str
    content_id: str
    content_title: Optional[str] = None
    content_preview: Optional[str] = None
    status: ApprovalStatus
    parent_notes: Optional[str] = None
    created_at: datetime
    reviewed_at: Optional[datetime] = None


class ApprovalDecision(BaseModel):
    status: ApprovalStatus
    parent_notes: Optional[str] = None
