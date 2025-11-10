from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


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


class GenealogyPersonCreate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    maiden_name: Optional[str] = Field(None, max_length=100)
    gender: Gender
    birth_date: Optional[str] = None
    birth_place: Optional[str] = Field(None, max_length=200)
    death_date: Optional[str] = None
    death_place: Optional[str] = Field(None, max_length=200)
    biography: Optional[str] = Field(None, max_length=5000)
    photo_url: Optional[str] = None
    occupation: Optional[str] = Field(None, max_length=200)
    notes: Optional[str] = Field(None, max_length=2000)


class GenealogyPersonUpdate(BaseModel):
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    maiden_name: Optional[str] = Field(None, max_length=100)
    gender: Optional[Gender] = None
    birth_date: Optional[str] = None
    birth_place: Optional[str] = Field(None, max_length=200)
    death_date: Optional[str] = None
    death_place: Optional[str] = Field(None, max_length=200)
    biography: Optional[str] = Field(None, max_length=5000)
    photo_url: Optional[str] = None
    occupation: Optional[str] = Field(None, max_length=200)
    notes: Optional[str] = Field(None, max_length=2000)


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
    biography: Optional[str] = None
    photo_url: Optional[str] = None
    occupation: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    created_by: str


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
