from datetime import datetime
from typing import List, Optional
from enum import Enum
from pydantic import BaseModel, Field
from bson import ObjectId
from app.models.user import PyObjectId


class FamilyRelationType(str, Enum):
    PARENT = "parent"
    CHILD = "child"
    SIBLING = "sibling"
    SPOUSE = "spouse"
    GRANDPARENT = "grandparent"
    GRANDCHILD = "grandchild"
    UNCLE = "uncle"
    AUNT = "aunt"
    NIECE = "niece"
    NEPHEW = "nephew"
    COUSIN = "cousin"
    IN_LAW = "in_law"
    STEP_PARENT = "step_parent"
    STEP_CHILD = "step_child"
    STEP_SIBLING = "step_sibling"
    GODPARENT = "godparent"
    GODCHILD = "godchild"
    FRIEND = "friend"
    CLOSE_FRIEND = "close_friend"
    OTHER = "other"


class FamilyCircleType(str, Enum):
    IMMEDIATE_FAMILY = "immediate_family"
    EXTENDED_FAMILY = "extended_family"
    CLOSE_FRIENDS = "close_friends"
    WORK_FRIENDS = "work_friends"
    CUSTOM = "custom"


class FamilyRelationshipBase(BaseModel):
    user_id: PyObjectId
    related_user_id: PyObjectId
    relation_type: FamilyRelationType
    relation_label: Optional[str] = None  # Custom label like "Mom", "Uncle Joe"
    notes: Optional[str] = None


class FamilyRelationshipCreate(BaseModel):
    related_user_id: str
    relation_type: FamilyRelationType
    relation_label: Optional[str] = None
    notes: Optional[str] = None


class FamilyRelationshipInDB(FamilyRelationshipBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyRelationshipResponse(BaseModel):
    id: str
    user_id: str
    related_user_id: str
    related_user_name: Optional[str] = None
    related_user_avatar: Optional[str] = None
    related_user_email: Optional[str] = None
    relation_type: FamilyRelationType
    relation_label: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class FamilyCircleBase(BaseModel):
    name: str
    description: Optional[str] = None
    circle_type: FamilyCircleType = FamilyCircleType.CUSTOM
    avatar_url: Optional[str] = None
    color: Optional[str] = None  # Hex color for UI


class FamilyCircleCreate(FamilyCircleBase):
    member_ids: List[str] = Field(default_factory=list)


class FamilyCircleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    circle_type: Optional[FamilyCircleType] = None
    avatar_url: Optional[str] = None
    color: Optional[str] = None


class FamilyCircleInDB(FamilyCircleBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    owner_id: PyObjectId
    member_ids: List[PyObjectId] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyCircleResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    circle_type: FamilyCircleType
    avatar_url: Optional[str] = None
    color: Optional[str] = None
    owner_id: str
    member_count: int
    members: List[dict] = Field(default_factory=list)  # List of user info
    created_at: datetime
    updated_at: datetime


class FamilyInvitationBase(BaseModel):
    inviter_id: PyObjectId
    invitee_email: str
    relation_type: FamilyRelationType
    relation_label: Optional[str] = None
    message: Optional[str] = None
    circle_ids: List[PyObjectId] = Field(default_factory=list)  # Auto-add to these circles


class FamilyInvitationCreate(BaseModel):
    invitee_email: str
    relation_type: FamilyRelationType
    relation_label: Optional[str] = None
    message: Optional[str] = None
    circle_ids: List[str] = Field(default_factory=list)


class FamilyInvitationInDB(FamilyInvitationBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    token: str
    status: str = "pending"  # pending, accepted, declined, expired
    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime
    accepted_at: Optional[datetime] = None
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyInvitationResponse(BaseModel):
    id: str
    inviter_id: str
    inviter_name: Optional[str] = None
    invitee_email: str
    relation_type: FamilyRelationType
    relation_label: Optional[str] = None
    message: Optional[str] = None
    circle_ids: List[str]
    circle_names: List[str] = Field(default_factory=list)
    token: str
    status: str
    invite_url: str
    created_at: datetime
    expires_at: datetime
    accepted_at: Optional[datetime] = None


class FamilyTreeNode(BaseModel):
    user_id: str
    name: str
    avatar_url: Optional[str] = None
    relation_type: Optional[FamilyRelationType] = None
    relation_label: Optional[str] = None
    children: List["FamilyTreeNode"] = Field(default_factory=list)


class AddFamilyMemberRequest(BaseModel):
    email: str
    relation_type: FamilyRelationType
    relation_label: Optional[str] = None
    notes: Optional[str] = None
    send_invitation: bool = True
    invitation_message: Optional[str] = None
