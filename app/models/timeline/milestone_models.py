"""User milestone models for timeline system."""
from datetime import datetime
from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field
from bson import ObjectId
from app.models.user import PyObjectId


class AudienceScope(str, Enum):
    """Audience visibility scope for milestones."""
    PRIVATE = "private"
    FRIENDS = "friends"
    FAMILY = "family"
    PUBLIC = "public"


class UserMilestoneBase(BaseModel):
    """Base milestone model."""
    title: str
    content: str
    media: List[str] = Field(default_factory=list)
    audience_scope: AudienceScope = AudienceScope.PRIVATE
    circle_ids: List[str] = Field(default_factory=list)


class UserMilestoneCreate(UserMilestoneBase):
    """Model for creating a milestone."""
    pass


class UserMilestoneUpdate(BaseModel):
    """Model for updating a milestone."""
    title: Optional[str] = None
    content: Optional[str] = None
    media: Optional[List[str]] = None
    audience_scope: Optional[AudienceScope] = None
    circle_ids: Optional[List[str]] = None


class UserMilestoneInDB(BaseModel):
    """Database model for milestone."""
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    owner_id: PyObjectId
    circle_ids: List[PyObjectId] = Field(default_factory=list)
    audience_scope: AudienceScope
    title: str
    content: str
    media: List[str] = Field(default_factory=list)
    engagement_counts: Dict[str, int] = Field(default_factory=lambda: {
        "likes_count": 0,
        "comments_count": 0,
        "reactions_count": 0
    })
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class UserMilestoneResponse(BaseModel):
    """Response model for milestone."""
    id: str
    owner_id: str
    owner_name: Optional[str] = None
    owner_avatar: Optional[str] = None
    circle_ids: List[str] = Field(default_factory=list)
    audience_scope: AudienceScope
    title: str
    content: str
    media: List[str] = Field(default_factory=list)
    engagement_counts: Dict[str, int] = Field(default_factory=dict)
    created_at: datetime
    updated_at: datetime
