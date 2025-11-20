"""Milestone reaction models."""
from datetime import datetime
from typing import Optional, Dict, List
from enum import Enum
from pydantic import BaseModel, Field
from bson import ObjectId
from app.models.user import PyObjectId


class ReactionType(str, Enum):
    """Types of reactions."""
    LIKE = "like"
    LOVE = "love"
    WOW = "wow"
    SAD = "sad"
    ANGRY = "angry"


class MilestoneReactionBase(BaseModel):
    """Base reaction model."""
    reaction_type: ReactionType


class MilestoneReactionCreate(MilestoneReactionBase):
    """Model for creating/updating a reaction."""
    pass


class MilestoneReactionInDB(BaseModel):
    """Database model for reaction."""
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    milestone_id: PyObjectId
    actor_id: PyObjectId
    reaction_type: ReactionType
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class MilestoneReactionResponse(BaseModel):
    """Response model for reaction."""
    id: str
    milestone_id: str
    actor_id: str
    actor_name: Optional[str] = None
    actor_avatar: Optional[str] = None
    reaction_type: ReactionType
    created_at: datetime


class ReactionsSummary(BaseModel):
    """Summary of all reactions on a milestone."""
    total_count: int = 0
    reactions_by_type: Dict[str, int] = Field(default_factory=dict)
    user_reaction: Optional[ReactionType] = None
    recent_reactors: List[Dict[str, str]] = Field(default_factory=list)
