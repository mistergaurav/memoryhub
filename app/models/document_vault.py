from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class DocumentType(str, Enum):
    BIRTH_CERTIFICATE = "birth_certificate"
    PASSPORT = "passport"
    DRIVERS_LICENSE = "drivers_license"
    SSN_CARD = "ssn_card"
    INSURANCE = "insurance"
    WILL = "will"
    DEED = "deed"
    TITLE = "title"
    CONTRACT = "contract"
    TAX_DOCUMENT = "tax_document"
    MEDICAL_RECORD = "medical_record"
    EDUCATION = "education"
    OTHER = "other"


class AccessLevel(str, Enum):
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"
    NO_ACCESS = "no_access"


class DocumentVaultCreate(BaseModel):
    document_type: DocumentType
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    file_url: str
    file_name: str
    file_size: int
    mime_type: str
    family_member_id: Optional[str] = None
    expiration_date: Optional[str] = None
    document_number: Optional[str] = Field(None, max_length=100)
    issuing_authority: Optional[str] = Field(None, max_length=200)
    tags: List[str] = []
    notes: Optional[str] = Field(None, max_length=1000)
    is_encrypted: bool = False
    access_level: AccessLevel = AccessLevel.OWNER


class DocumentVaultUpdate(BaseModel):
    document_type: Optional[DocumentType] = None
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    family_member_id: Optional[str] = None
    expiration_date: Optional[str] = None
    document_number: Optional[str] = Field(None, max_length=100)
    issuing_authority: Optional[str] = Field(None, max_length=200)
    tags: Optional[List[str]] = None
    notes: Optional[str] = Field(None, max_length=1000)
    access_level: Optional[AccessLevel] = None


class DocumentVaultResponse(BaseModel):
    id: str
    family_id: str
    document_type: DocumentType
    title: str
    description: Optional[str] = None
    file_url: str
    file_name: str
    file_size: int
    mime_type: str
    family_member_id: Optional[str] = None
    family_member_name: Optional[str] = None
    expiration_date: Optional[str] = None
    document_number: Optional[str] = None
    issuing_authority: Optional[str] = None
    tags: List[str] = []
    notes: Optional[str] = None
    is_encrypted: bool
    access_level: AccessLevel
    created_at: datetime
    updated_at: datetime
    created_by: str
    last_accessed_at: Optional[datetime] = None


class DocumentAccessLogResponse(BaseModel):
    id: str
    document_id: str
    user_id: str
    user_name: str
    action: str
    timestamp: datetime
    ip_address: Optional[str] = None
