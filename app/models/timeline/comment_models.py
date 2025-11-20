"""Milestone comment models."""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from bson import ObjectId
from app.models.user import PyObjectId


class MilestoneCommentBase(BaseModel):
    """Base comment model."""
    body: str
    visibility: str = "public"
    parent_comment_id: Optional[str] = None


class MilestoneCommentCreate(MilestoneCommentBase):
    """Model for creating a comment."""
    pass


class MilestoneCommentUpdate(BaseModel):
    """Model for updating a comment."""
    body: Optional[str] = None
    visibility: Optional[str] = None


class MilestoneCommentInDB(BaseModel):
    """Database model for comment."""
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    milestone_id: PyObjectId
    author_id: PyObjectId
    body: str
    parent_comment_id: Optional[PyObjectId] = None
    visibility: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class MilestoneCommentResponse(BaseModel):
    """Response model for comment."""
    id: str
    milestone_id: str
    author_id: str
    author_name: Optional[str] = None
    author_avatar: Optional[str] = None
    body: str
    parent_comment_id: Optional[str] = None
    visibility: str
    created_at: datetime
    updated_at: datetime
    replies: List["MilestoneCommentResponse"] = Field(default_factory=list)
