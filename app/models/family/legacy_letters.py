from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId


class LetterStatus(str, Enum):
    DRAFT = "draft"
    SCHEDULED = "scheduled"
    DELIVERED = "delivered"
    READ = "read"


class LegacyLetterBase(BaseModel):
    title: str
    content: str
    delivery_date: datetime
    encrypt: bool = False


class LegacyLetterCreate(LegacyLetterBase):
    recipient_ids: List[str]
    attachments: List[str] = Field(default_factory=list)


class LegacyLetterUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    delivery_date: Optional[datetime] = None
    recipient_ids: Optional[List[str]] = None
    attachments: Optional[List[str]] = None
    encrypt: Optional[bool] = None


class LegacyLetterInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    title: str
    content: str
    delivery_date: datetime
    encrypt: bool
    author_id: PyObjectId
    recipient_ids: List[PyObjectId]
    attachments: List[str] = Field(default_factory=list)
    status: LetterStatus = LetterStatus.DRAFT
    delivered_at: Optional[datetime] = None
    read_by: List[PyObjectId] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class LegacyLetterResponse(BaseModel):
    id: str
    title: str
    content: Optional[str] = None  # Hidden until delivered
    delivery_date: datetime
    encrypt: bool
    author_id: str
    author_name: Optional[str] = None
    recipient_ids: List[str]
    recipient_names: List[str] = Field(default_factory=list)
    attachments: List[str]
    status: LetterStatus
    delivered_at: Optional[datetime] = None
    read_count: int = 0
    created_at: datetime
    updated_at: datetime


class ReceivedLetterResponse(BaseModel):
    id: str
    title: str
    content: str
    delivery_date: datetime
    author_id: str
    author_name: Optional[str] = None
    attachments: List[str]
    delivered_at: datetime
    is_read: bool = False
    created_at: datetime
