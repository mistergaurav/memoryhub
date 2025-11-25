from pydantic import BaseModel, Field, validator, field_validator
from typing import Optional, List
from datetime import datetime
from enum import Enum
import re


class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"
    UNKNOWN = "unknown"


class RelationshipType(str, Enum):
    PARENT = "parent"
    CHILD = "child"
    SPOUSE = "spouse"
    SIBLING = "sibling"
    GRANDPARENT = "grandparent"
    GRANDCHILD = "grandchild"
    AUNT_UNCLE = "aunt_uncle"
    NIECE_NEPHEW = "niece_nephew"
    COUSIN = "cousin"


class PersonSource(str, Enum):
    MANUAL = "manual"
    PLATFORM_USER = "platform_user"
    IMPORT = "import"
    OTHER = "other"


class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


class ApprovalStatus(str, Enum):
    APPROVED = "approved"
    PENDING = "pending"
    REJECTED = "rejected"


class RelationshipSpec(BaseModel):
    person_id: str
    relationship_type: RelationshipType
    notes: Optional[str] = Field(None, max_length=500)


class GenealogyPersonCreate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    maiden_name: Optional[str] = Field(None, max_length=100)
    gender: Gender
    birth_date: Optional[str] = None
    birth_place: Optional[str] = Field(None, max_length=200)
    death_date: Optional[str] = None
    death_place: Optional[str] = Field(None, max_length=200)
    is_alive: Optional[bool] = None
    biography: Optional[str] = Field(None, max_length=5000)
    photo_url: Optional[str] = None
    occupation: Optional[str] = Field(None, max_length=200)
    notes: Optional[str] = Field(None, max_length=2000)
    linked_user_id: Optional[str] = None
    source: Optional[PersonSource] = PersonSource.MANUAL
    relationships: Optional[List[RelationshipSpec]] = None
    # New fields for invitation and status tracking
    pending_invite_email: Optional[str] = Field(None, max_length=200)  # Email to send invite to
    is_memorial: bool = False  # True if this is a memorial profile (deceased)
    approval_status: Optional[ApprovalStatus] = ApprovalStatus.APPROVED
    
    @validator('birth_date', 'death_date')
    def validate_date_format(cls, v):
        if v is None or v == "":
            return v
        date_pattern = r'^\d{4}-\d{2}-\d{2}$'
        if not re.match(date_pattern, v):
            raise ValueError('Date must be in YYYY-MM-DD format or empty')
        try:
            datetime.strptime(v, '%Y-%m-%d')
        except ValueError:
            raise ValueError('Invalid date value')
        return v


class GenealogyPersonUpdate(BaseModel):
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    maiden_name: Optional[str] = Field(None, max_length=100)
    gender: Optional[Gender] = None
    birth_date: Optional[str] = None
    birth_place: Optional[str] = Field(None, max_length=200)
    death_date: Optional[str] = None
    death_place: Optional[str] = Field(None, max_length=200)
    is_alive: Optional[bool] = None
    biography: Optional[str] = Field(None, max_length=5000)
    photo_url: Optional[str] = None
    occupation: Optional[str] = Field(None, max_length=200)
    notes: Optional[str] = Field(None, max_length=2000)
    linked_user_id: Optional[str] = None
    pending_invite_email: Optional[str] = Field(None, max_length=200)
    is_memorial: Optional[bool] = None
    approval_status: Optional[ApprovalStatus] = None
    rejection_reason: Optional[str] = Field(None, max_length=500)
    
    @validator('birth_date', 'death_date')
    def validate_date_format(cls, v):
        if v is None or v == "":
            return v
        date_pattern = r'^\d{4}-\d{2}-\d{2}$'
        if not re.match(date_pattern, v):
            raise ValueError('Date must be in YYYY-MM-DD format or empty')
        try:
            datetime.strptime(v, '%Y-%m-%d')
        except ValueError:
            raise ValueError('Invalid date value')
        return v


class GenealogyPersonResponse(BaseModel):
    """
    Response model for genealogy person with field aliases for compatibility.
    
    Supports both naming conventions:
    - Backend: birth_date, death_date, is_alive, family_id
    - Frontend (legacy): date_of_birth, date_of_death, is_deceased, tree_id
    """
    model_config = {"populate_by_name": True}
    
    id: str
    family_id: str = Field(alias="tree_id")  # Alias for frontend compatibility
    first_name: str
    last_name: str
    maiden_name: Optional[str] = None
    gender: Gender
    
    # Date fields with aliases for frontend compatibility
    birth_date: Optional[str] = Field(None, alias="date_of_birth")
    birth_place: Optional[str] = Field(None, alias="place_of_birth")
    death_date: Optional[str] = Field(None, alias="date_of_death")
    death_place: Optional[str] = Field(None, alias="place_of_death")
    is_alive: bool = Field(True, alias="is_deceased")  # Note: is_deceased is inverse of is_alive
    
    biography: Optional[str] = None
    photo_url: Optional[str] = None
    occupation: Optional[str] = None
    notes: Optional[str] = None
    linked_user_id: Optional[str] = None
    source: PersonSource = PersonSource.MANUAL
    
    # New fields
    pending_invite_email: Optional[str] = None
    is_memorial: bool = False
    approval_status: ApprovalStatus = ApprovalStatus.APPROVED
    rejection_reason: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    created_by: str
    notes: Optional[str] = None
    linked_user_id: Optional[str] = None
    source: PersonSource = PersonSource.MANUAL
    
    # New fields
    pending_invite_email: Optional[str] = None
    is_memorial: bool = False
    approval_status: ApprovalStatus = ApprovalStatus.APPROVED
    rejection_reason: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    created_by: str
    notes: Optional[str] = None
    linked_user_id: Optional[str] = None
    source: Optional[PersonSource] = PersonSource.MANUAL
    created_at: datetime
    updated_at: datetime
    created_by: str
    age: Optional[int] = None
    lifespan: Optional[int] = None
    health_records_count: int = 0
    hereditary_conditions: List[str] = []
    # New fields for enhanced genealogy tracking
    person_status: Optional[str] = None  # Computed: alive_platform_user, alive_pending_invite, alive_no_invite, deceased
    pending_invite_email: Optional[str] = None
    is_memorial: bool = False
    invite_token: Optional[str] = None  # Active invitation token if any
    invitation_status: Optional[InvitationStatus] = None  # Status of pending invitation
    invitation_sent_at: Optional[datetime] = None
    invitation_expires_at: Optional[datetime] = None
    linked_username: Optional[str] = None  # Username of linked platform user
    linked_full_name: Optional[str] = None  # Full name of linked platform user
    memory_count: int = 0  # Count of memories associated with this person
    
    @property
    def is_deceased(self) -> bool:
        """Property to get is_deceased (inverse of is_alive) for frontend compatibility."""
        return not self.is_alive
    
    @property
    def tree_id(self) -> str:
        """Property alias for family_id to support frontend."""
        return self.family_id


class GenealogyRelationshipCreate(BaseModel):
    person1_id: str
    person2_id: str
    relationship_type: RelationshipType
    notes: Optional[str] = Field(None, max_length=500)


class GenealogyRelationshipResponse(BaseModel):
    id: str
    family_id: str
    person1_id: str
    person2_id: str
    relationship_type: RelationshipType
    notes: Optional[str] = None
    created_at: datetime
    created_by: str


class FamilyTreeNode(BaseModel):
    """
    Tree node representing a person and their immediate family relationships.
    
    Note: parents, children, spouses, siblings can be either:
    - List of person IDs (strings) for lazy loading
    - List of GenealogyPersonResponse objects for full data
    """
    person: GenealogyPersonResponse
    relationships: List[GenealogyRelationshipResponse] = []
    
    # Relationship arrays - can be IDs or full person objects
    parents: List = []  # List[str] or List[GenealogyPersonResponse]
    children: List = []  # List[str] or List[GenealogyPersonResponse]
    spouses: List = []  # List[str] or List[GenealogyPersonResponse]
    siblings: List = []  # List[str] or List[GenealogyPersonResponse]


class UserSearchResult(BaseModel):
    id: str
    username: str
    email: str
    full_name: Optional[str] = None
    profile_photo: Optional[str] = None
    already_linked: bool = False


class FamilyHubInvitationCreate(BaseModel):
    person_id: str
    invited_user_id: str
    message: Optional[str] = Field(None, max_length=500)


class FamilyHubInvitationResponse(BaseModel):
    id: str
    family_id: str
    person_id: str
    inviter_id: str
    invited_user_id: str
    message: Optional[str] = None
    status: InvitationStatus
    created_at: datetime
    responded_at: Optional[datetime] = None


class InvitationAction(BaseModel):
    action: str = Field(..., pattern="^(accept|decline)$")


# Tree Membership Models
class TreeMemberRole(str, Enum):
    OWNER = "owner"
    MEMBER = "member"
    VIEWER = "viewer"


class TreeMembershipCreate(BaseModel):
    tree_id: str  # family_id that owns the tree
    user_id: str
    role: TreeMemberRole = TreeMemberRole.VIEWER


class TreeMembershipResponse(BaseModel):
    id: str
    tree_id: str
    user_id: str
    username: Optional[str] = None
    full_name: Optional[str] = None
    profile_photo: Optional[str] = None
    role: TreeMemberRole
    joined_at: datetime
    granted_by: str


class TreeMembershipUpdate(BaseModel):
    role: TreeMemberRole


# Invitation Link Models (Token-based)
class InviteLinkCreate(BaseModel):
    person_id: str  # The genealogy person to link the invitee to
    email: Optional[str] = Field(None, max_length=200)  # Optional email to send invitation
    message: Optional[str] = Field(None, max_length=500)
    expires_in_days: int = Field(30, ge=1, le=365)  # Token expiry


class InviteLinkResponse(BaseModel):
    id: str
    family_id: str
    person_id: str
    person_name: str  # For display
    token: str
    email: Optional[str] = None
    message: Optional[str] = None
    status: InvitationStatus
    invite_url: str
    created_by: str
    created_at: datetime
    expires_at: datetime
    accepted_at: Optional[datetime] = None
    accepted_by: Optional[str] = None  # user_id who claimed it


class InviteRedemptionRequest(BaseModel):
    token: str


# Enhanced Person Models with new fields
class PersonStatus(str, Enum):
    ALIVE_PLATFORM_USER = "alive_platform_user"  # Linked to platform user
    ALIVE_PENDING_INVITE = "alive_pending_invite"  # Invited but not joined
    ALIVE_NO_INVITE = "alive_no_invite"  # Alive but no platform presence
    DECEASED = "deceased"  # Memorial profile
