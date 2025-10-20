from datetime import datetime
from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field, HttpUrl, validator, field_validator
from bson import ObjectId
from .user import PyObjectId

class MemoryPrivacy(str, Enum):
    PRIVATE = "private"
    FRIENDS = "friends"
    PUBLIC = "public"

class MemoryBase(BaseModel):
    title: str
    content: str
    media_urls: List[str] = Field(default_factory=list)
    tags: List[str] = Field(default_factory=list)
    privacy: MemoryPrivacy = MemoryPrivacy.PRIVATE
    location: Optional[Dict[str, float]] = None  # { "lat": 0.0, "lng": 0.0 }
    mood: Optional[str] = None
    weather: Optional[Dict[str, Any]] = None
    tagged_family_members: List[Dict[str, str]] = Field(default_factory=list)  # [{"user_id": "xxx", "relation": "mom"}]
    family_circle_ids: List[str] = Field(default_factory=list)  # Family circles this memory is shared with
    relationship_context: Optional[str] = None  # e.g., "Mom's Birthday", "Family Reunion"
    genealogy_person_ids: List[str] = Field(default_factory=list)  # Genealogy persons tagged in this memory
    family_tree_id: Optional[str] = None  # Family tree this memory belongs to
    
    @validator('title')
    def title_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip()
    
    @validator('content')
    def content_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Content cannot be empty')
        return v.strip()

class MemoryCreate(MemoryBase):
    pass

class MemoryUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    media_urls: Optional[List[str]] = None
    tags: Optional[List[str]] = None
    privacy: Optional[MemoryPrivacy] = None
    location: Optional[Dict[str, float]] = None
    mood: Optional[str] = None
    genealogy_person_ids: Optional[List[str]] = None
    family_tree_id: Optional[str] = None
    
    @field_validator('title', 'content', mode='before')
    def empty_str_to_none(cls, v):
        if v == "":
            return None
        return v

class MemoryInDB(MemoryBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    owner_id: PyObjectId
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    view_count: int = 0
    like_count: int = 0
    comment_count: int = 0
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True

class MemoryResponse(MemoryInDB):
    is_liked: bool = False
    is_bookmarked: bool = False
    owner_name: Optional[str] = None
    owner_avatar: Optional[str] = None

class MemorySearchParams(BaseModel):
    query: Optional[str] = None
    tags: Optional[List[str]] = None
    privacy: Optional[MemoryPrivacy] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    sort_by: str = "created_at"
    sort_order: str = "desc"
    page: int = 1
    limit: int = 20