from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class CommentTarget(str, Enum):
    MEMORY = "memory"
    HUB_ITEM = "hub_item"
    FILE = "file"

class CommentCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)
    target_type: CommentTarget
    target_id: str

class CommentUpdate(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)

class CommentResponse(BaseModel):
    id: str
    content: str
    target_type: CommentTarget
    target_id: str
    author_id: str
    author_name: Optional[str] = None
    author_avatar: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    likes_count: int = 0
    is_liked: bool = False
    is_author: bool = False

class CommentListResponse(BaseModel):
    comments: list[CommentResponse]
    total: int
    page: int
    pages: int
