from datetime import datetime
from typing import List, Optional
from enum import Enum
from pydantic import BaseModel, Field
from bson import ObjectId
from app.models.user import PyObjectId

class HubRole(str, Enum):
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"

class HubPrivacy(str, Enum):
    PRIVATE = "private"
    INVITE_ONLY = "invite_only"
    PUBLIC = "public"

class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    EXPIRED = "expired"

class RelationshipStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    BLOCKED = "blocked"

class NotificationType(str, Enum):
    HEALTH_RECORD_ASSIGNMENT = "health_record_assignment"
    HEALTH_REMINDER_ASSIGNMENT = "health_reminder_assignment"
    HEALTH_RECORD_APPROVED = "health_record_approved"
    HEALTH_RECORD_REJECTED = "health_record_rejected"

class CollaborativeHubBase(BaseModel):
    name: str
    description: Optional[str] = None
    privacy: HubPrivacy = HubPrivacy.PRIVATE
    avatar_url: Optional[str] = None
    tags: List[str] = Field(default_factory=list)

class CollaborativeHubCreate(CollaborativeHubBase):
    pass

class CollaborativeHubUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    privacy: Optional[HubPrivacy] = None
    avatar_url: Optional[str] = None
    tags: Optional[List[str]] = None

class CollaborativeHubInDB(CollaborativeHubBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    owner_id: PyObjectId
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    member_count: int = 1
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True

class CollaborativeHubResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    privacy: HubPrivacy
    avatar_url: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    owner_id: str
    owner_name: Optional[str] = None
    member_count: int
    my_role: Optional[HubRole] = None
    created_at: datetime
    updated_at: datetime

class HubMemberBase(BaseModel):
    hub_id: PyObjectId
    user_id: PyObjectId
    role: HubRole = HubRole.MEMBER

class HubMemberCreate(HubMemberBase):
    pass

class HubMemberInDB(HubMemberBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    joined_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True

class HubMemberResponse(BaseModel):
    id: str
    user_id: str
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None
    role: HubRole
    joined_at: datetime

class HubInvitationBase(BaseModel):
    hub_id: PyObjectId
    inviter_id: PyObjectId
    invitee_email: str
    role: HubRole = HubRole.MEMBER
    message: Optional[str] = None

class HubInvitationCreate(HubInvitationBase):
    pass

class HubInvitationInDB(HubInvitationBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    status: InvitationStatus = InvitationStatus.PENDING
    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime
    responded_at: Optional[datetime] = None
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True

class HubInvitationResponse(BaseModel):
    id: str
    hub_id: str
    hub_name: str
    inviter_id: str
    inviter_name: Optional[str] = None
    invitee_email: str
    role: HubRole
    status: InvitationStatus
    message: Optional[str] = None
    created_at: datetime
    expires_at: datetime

class HubSharingLinkBase(BaseModel):
    hub_id: PyObjectId
    role: HubRole = HubRole.VIEWER
    max_uses: Optional[int] = None
    expires_at: Optional[datetime] = None

class HubSharingLinkCreate(HubSharingLinkBase):
    pass

class HubSharingLinkInDB(HubSharingLinkBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    token: str
    created_by: PyObjectId
    created_at: datetime = Field(default_factory=datetime.utcnow)
    use_count: int = 0
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True

class HubSharingLinkResponse(BaseModel):
    id: str
    hub_id: str
    hub_name: str
    token: str
    role: HubRole
    max_uses: Optional[int] = None
    use_count: int
    expires_at: Optional[datetime] = None
    created_at: datetime
    share_url: str

class RelationshipBase(BaseModel):
    follower_id: PyObjectId
    following_id: PyObjectId

class RelationshipCreate(RelationshipBase):
    pass

class RelationshipInDB(RelationshipBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    status: RelationshipStatus = RelationshipStatus.ACCEPTED
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True

class RelationshipResponse(BaseModel):
    id: str
    user_id: str
    user_name: Optional[str] = None
    user_avatar: Optional[str] = None
    user_bio: Optional[str] = None
    status: RelationshipStatus
    created_at: datetime
