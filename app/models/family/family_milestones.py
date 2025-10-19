from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId


class MilestoneType(str, Enum):
    BIRTH = "birth"
    FIRST_STEPS = "first_steps"
    FIRST_WORDS = "first_words"
    FIRST_DAY_SCHOOL = "first_day_school"
    GRADUATION = "graduation"
    FIRST_JOB = "first_job"
    ENGAGEMENT = "engagement"
    WEDDING = "wedding"
    ANNIVERSARY = "anniversary"
    NEW_HOME = "new_home"
    RETIREMENT = "retirement"
    ACHIEVEMENT = "achievement"
    TRAVEL = "travel"
    OTHER = "other"


class FamilyMilestoneBase(BaseModel):
    title: str
    description: Optional[str] = None
    milestone_type: MilestoneType
    milestone_date: datetime
    person_id: Optional[str] = None  # Family member this milestone is about


class FamilyMilestoneCreate(FamilyMilestoneBase):
    photos: List[str] = Field(default_factory=list)
    family_circle_ids: List[str] = Field(default_factory=list)


class FamilyMilestoneUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    milestone_type: Optional[MilestoneType] = None
    milestone_date: Optional[datetime] = None
    person_id: Optional[str] = None
    photos: Optional[List[str]] = None
    family_circle_ids: Optional[List[str]] = None


class FamilyMilestoneInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    title: str
    description: Optional[str] = None
    milestone_type: MilestoneType
    milestone_date: datetime
    person_id: Optional[PyObjectId] = None
    person_name: Optional[str] = None
    photos: List[str] = Field(default_factory=list)
    created_by: PyObjectId
    family_circle_ids: List[PyObjectId] = Field(default_factory=list)
    likes: List[PyObjectId] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyMilestoneResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    milestone_type: MilestoneType
    milestone_date: datetime
    person_id: Optional[str] = None
    person_name: Optional[str] = None
    photos: List[str]
    created_by: str
    created_by_name: Optional[str] = None
    family_circle_ids: List[str]
    likes_count: int = 0
    created_at: datetime
    updated_at: datetime
