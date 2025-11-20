"""Relationship models for dual-row pattern."""
from datetime import datetime
from typing import Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field
from bson import ObjectId
from app.models.user import PyObjectId


class RelationshipType(str, Enum):
    """Types of relationships."""
    FRIEND = "friend"
    FAMILY = "family"
    COUSIN = "cousin"
    BOYFRIEND = "boyfriend"
    GIRLFRIEND = "girlfriend"
    CLOSE_FRIEND = "close_friend"
    BEST_FRIEND = "best_friend"
    OTHER = "other"


class RelationshipStatus(str, Enum):
    """Status of relationship."""
    PENDING = "pending"
    ACCEPTED = "accepted"
    BLOCKED = "blocked"
    REJECTED = "rejected"


class RelationshipBase(BaseModel):
    """Base relationship model."""
    relationship_type: RelationshipType
    relationship_label: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class RelationshipInviteRequest(BaseModel):
    """Model for sending relationship invitation."""
    related_user_id: str
    relationship_type: RelationshipType
    relationship_label: Optional[str] = None
    message: Optional[str] = None


class RelationshipInDB(BaseModel):
    """Database model for relationship (dual-row pattern)."""
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    user_id: PyObjectId
    related_user_id: PyObjectId
    relationship_type: RelationshipType
    relationship_label: Optional[str] = None
    status: RelationshipStatus
    requester_id: PyObjectId
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class RelationshipResponse(BaseModel):
    """Response model for relationship."""
    id: str
    user_id: str
    related_user_id: str
    related_user_name: Optional[str] = None
    related_user_avatar: Optional[str] = None
    related_user_email: Optional[str] = None
    relationship_type: RelationshipType
    relationship_label: Optional[str] = None
    status: RelationshipStatus
    requester_id: str
    is_requester: bool = False
    created_at: datetime
    updated_at: datetime
    metadata: Dict[str, Any] = Field(default_factory=dict)
