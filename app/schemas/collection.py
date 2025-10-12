from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class CollectionPrivacy(str, Enum):
    PRIVATE = "private"
    FRIENDS = "friends"
    PUBLIC = "public"

class CollectionCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    cover_image_url: Optional[str] = None
    privacy: CollectionPrivacy = CollectionPrivacy.PRIVATE
    tags: List[str] = []

class CollectionUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    cover_image_url: Optional[str] = None
    privacy: Optional[CollectionPrivacy] = None
    tags: Optional[List[str]] = None

class CollectionResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    cover_image_url: Optional[str] = None
    privacy: CollectionPrivacy
    tags: List[str]
    owner_id: str
    owner_name: Optional[str] = None
    memory_count: int = 0
    created_at: datetime
    updated_at: datetime
    is_owner: bool = False

class CollectionWithMemories(CollectionResponse):
    memory_ids: List[str]
