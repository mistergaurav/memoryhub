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
    id: str
    family_id: str
    first_name: str
    last_name: str
    maiden_name: Optional[str] = None
    gender: Gender
    birth_date: Optional[str] = None
    birth_place: Optional[str] = None
    death_date: Optional[str] = None
    death_place: Optional[str] = None
    is_alive: bool = True
    biography: Optional[str] = None
    photo_url: Optional[str] = None
    occupation: Optional[str] = None
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
    person: GenealogyPersonResponse
    relationships: List[GenealogyRelationshipResponse] = []
    children: List[str] = []
    parents: List[str] = []
    spouse: Optional[str] = None


class UserSearchResult(BaseModel):
    id: str
    username: str
    email: str
    full_name: Optional[str] = None
    profile_photo: Optional[str] = None
    already_linked: bool = False


class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    CANCELLED = "cancelled"


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
