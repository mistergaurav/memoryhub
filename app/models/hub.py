from datetime import datetime
from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field
from bson import ObjectId
from .user import PyObjectId

class HubItemType(str, Enum):
    MEMORY = "memory"
    FILE = "file"
    NOTE = "note"
    LINK = "link"
    TASK = "task"

class HubItemPrivacy(str, Enum):
    PRIVATE = "private"
    FRIENDS = "friends"
    PUBLIC = "public"

class HubItemBase(BaseModel):
    title: str
    description: Optional[str] = None
    item_type: HubItemType
    content: Dict[str, Any] = Field(default_factory=dict)
    tags: List[str] = Field(default_factory=list)
    privacy: HubItemPrivacy = HubItemPrivacy.PRIVATE
    is_pinned: bool = False
    position: Optional[Dict[str, int]] = None  # For custom layout

class HubItemCreate(HubItemBase):
    pass

class HubItemUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    content: Optional[Dict[str, Any]] = None
    tags: Optional[List[str]] = None
    privacy: Optional[HubItemPrivacy] = None
    is_pinned: Optional[bool] = None
    position: Optional[Dict[str, int]] = None

class HubItemInDB(HubItemBase):
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

class HubItemResponse(HubItemInDB):
    is_liked: bool = False
    is_bookmarked: bool = False
    owner_name: Optional[str] = None
    owner_avatar: Optional[str] = None

class HubSection(BaseModel):
    name: str
    description: Optional[str] = None
    item_ids: List[str] = Field(default_factory=list)
    is_collapsed: bool = False
    position: int = 0

class HubLayout(BaseModel):
    sections: List[HubSection] = Field(default_factory=list)
    custom_css: Optional[str] = None
    theme: str = "default"

class HubStats(BaseModel):
    total_items: int = 0
    items_by_type: Dict[str, int] = Field(default_factory=dict)
    total_views: int = 0
    total_likes: int = 0
    storage_used: int = 0  # in bytes
    storage_quota: int = 1024 * 1024 * 1024  # 1GB default