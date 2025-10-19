from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId


class AlbumPrivacy(str, Enum):
    PRIVATE = "private"
    FAMILY_CIRCLE = "family_circle"
    SPECIFIC_MEMBERS = "specific_members"
    PUBLIC = "public"


class AlbumPhotoBase(BaseModel):
    url: str
    caption: Optional[str] = None
    uploaded_by: PyObjectId
    uploaded_by_name: Optional[str] = None


class AlbumPhotoCreate(BaseModel):
    url: str
    caption: Optional[str] = None


class AlbumPhotoInDB(AlbumPhotoBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    likes: List[PyObjectId] = Field(default_factory=list)
    uploaded_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class AlbumPhotoResponse(BaseModel):
    id: str
    url: str
    caption: Optional[str] = None
    uploaded_by: str
    uploaded_by_name: Optional[str] = None
    likes_count: int = 0
    uploaded_at: datetime


class FamilyAlbumBase(BaseModel):
    title: str
    description: Optional[str] = None
    cover_photo: Optional[str] = None
    privacy: AlbumPrivacy = AlbumPrivacy.FAMILY_CIRCLE


class FamilyAlbumCreate(FamilyAlbumBase):
    family_circle_ids: List[str] = Field(default_factory=list)
    member_ids: List[str] = Field(default_factory=list)


class FamilyAlbumUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    cover_photo: Optional[str] = None
    privacy: Optional[AlbumPrivacy] = None
    family_circle_ids: Optional[List[str]] = None
    member_ids: Optional[List[str]] = None


class FamilyAlbumInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    title: str
    description: Optional[str] = None
    cover_photo: Optional[str] = None
    privacy: AlbumPrivacy
    created_by: PyObjectId
    family_circle_ids: List[PyObjectId] = Field(default_factory=list)
    member_ids: List[PyObjectId] = Field(default_factory=list)
    photos: List[AlbumPhotoInDB] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyAlbumResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    cover_photo: Optional[str] = None
    privacy: AlbumPrivacy
    created_by: str
    created_by_name: Optional[str] = None
    family_circle_ids: List[str]
    member_ids: List[str]
    photos_count: int = 0
    created_at: datetime
    updated_at: datetime


class AlbumCommentCreate(BaseModel):
    photo_id: str
    content: str


class AlbumCommentResponse(BaseModel):
    id: str
    album_id: str
    photo_id: str
    user_id: str
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None
    content: str
    created_at: datetime
