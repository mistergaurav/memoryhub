from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId


class TraditionCategory(str, Enum):
    HOLIDAY = "holiday"
    BIRTHDAY = "birthday"
    CULTURAL = "cultural"
    RELIGIOUS = "religious"
    FAMILY_CUSTOM = "family_custom"
    SEASONAL = "seasonal"
    MEAL = "meal"
    CELEBRATION = "celebration"
    OTHER = "other"


class TraditionFrequency(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"
    OCCASIONAL = "occasional"


class FamilyTraditionBase(BaseModel):
    title: str
    description: str
    category: TraditionCategory
    frequency: TraditionFrequency
    typical_date: Optional[str] = None  # e.g., "December 25", "First Sunday of month"


class FamilyTraditionCreate(FamilyTraditionBase):
    origin_story: Optional[str] = None
    instructions: Optional[str] = None
    photos: List[str] = Field(default_factory=list)
    videos: List[str] = Field(default_factory=list)
    family_circle_ids: List[str] = Field(default_factory=list)
    origin_ancestor_id: Optional[str] = None
    generations_passed: Optional[int] = None
    country_of_origin: Optional[str] = Field(None, max_length=100)


class FamilyTraditionUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[TraditionCategory] = None
    frequency: Optional[TraditionFrequency] = None
    typical_date: Optional[str] = None
    origin_story: Optional[str] = None
    instructions: Optional[str] = None
    photos: Optional[List[str]] = None
    videos: Optional[List[str]] = None
    family_circle_ids: Optional[List[str]] = None
    origin_ancestor_id: Optional[str] = None
    generations_passed: Optional[int] = None
    country_of_origin: Optional[str] = Field(None, max_length=100)


class FamilyTraditionInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    title: str
    description: str
    category: TraditionCategory
    frequency: TraditionFrequency
    typical_date: Optional[str] = None
    origin_story: Optional[str] = None
    instructions: Optional[str] = None
    photos: List[str] = Field(default_factory=list)
    videos: List[str] = Field(default_factory=list)
    created_by: PyObjectId
    family_circle_ids: List[PyObjectId] = Field(default_factory=list)
    followers: List[PyObjectId] = Field(default_factory=list)
    origin_ancestor_id: Optional[PyObjectId] = None
    generations_passed: Optional[int] = None
    country_of_origin: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyTraditionResponse(BaseModel):
    id: str
    title: str
    description: str
    category: TraditionCategory
    frequency: TraditionFrequency
    typical_date: Optional[str] = None
    origin_story: Optional[str] = None
    instructions: Optional[str] = None
    photos: List[str]
    videos: List[str]
    created_by: str
    created_by_name: Optional[str] = None
    family_circle_ids: List[str]
    followers_count: int = 0
    origin_ancestor_id: Optional[str] = None
    origin_ancestor_name: Optional[str] = None
    generations_passed: Optional[int] = None
    country_of_origin: Optional[str] = None
    created_at: datetime
    updated_at: datetime
