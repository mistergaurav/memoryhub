from datetime import datetime
from typing import Optional, List, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field, HttpUrl
from bson import ObjectId
from .user import PyObjectId

class FileType(str, Enum):
    IMAGE = "image"
    VIDEO = "video"
    DOCUMENT = "document"
    AUDIO = "audio"
    ARCHIVE = "archive"
    OTHER = "other"

class FilePrivacy(str, Enum):
    PRIVATE = "private"
    FRIENDS = "friends"
    PUBLIC = "public"

class FileBase(BaseModel):
    name: str
    description: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    privacy: FilePrivacy = FilePrivacy.PRIVATE
    metadata: Dict[str, Any] = Field(default_factory=dict)

class FileCreate(FileBase):
    pass

class FileUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    tags: Optional[List[str]] = None
    privacy: Optional[FilePrivacy] = None
    metadata: Optional[Dict[str, Any]] = None

class FileInDB(FileBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    owner_id: PyObjectId
    file_path: str
    file_type: FileType
    file_size: int  # in bytes
    mime_type: str
    is_favorite: bool = False
    download_count: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True

class FileResponse(FileInDB):
    download_url: str
    owner_name: Optional[str] = None
    owner_avatar: Optional[str] = None

class VaultStats(BaseModel):
    total_files: int
    total_size: int  # in bytes
    by_type: Dict[FileType, int]