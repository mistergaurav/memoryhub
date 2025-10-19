from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class RecordType(str, Enum):
    MEDICAL = "medical"
    VACCINATION = "vaccination"
    ALLERGY = "allergy"
    MEDICATION = "medication"
    CONDITION = "condition"
    PROCEDURE = "procedure"
    LAB_RESULT = "lab_result"
    APPOINTMENT = "appointment"


class Severity(str, Enum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class HealthRecordCreate(BaseModel):
    family_member_id: str
    record_type: RecordType
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    date: str
    provider: Optional[str] = Field(None, max_length=200)
    location: Optional[str] = Field(None, max_length=200)
    severity: Optional[Severity] = None
    attachments: List[str] = []
    notes: Optional[str] = Field(None, max_length=1000)
    medications: List[str] = []
    is_confidential: bool = True


class HealthRecordUpdate(BaseModel):
    record_type: Optional[RecordType] = None
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    date: Optional[str] = None
    provider: Optional[str] = Field(None, max_length=200)
    location: Optional[str] = Field(None, max_length=200)
    severity: Optional[Severity] = None
    attachments: Optional[List[str]] = None
    notes: Optional[str] = Field(None, max_length=1000)
    medications: Optional[List[str]] = None
    is_confidential: Optional[bool] = None


class HealthRecordResponse(BaseModel):
    id: str
    family_id: str
    family_member_id: str
    family_member_name: Optional[str] = None
    record_type: RecordType
    title: str
    description: Optional[str] = None
    date: str
    provider: Optional[str] = None
    location: Optional[str] = None
    severity: Optional[Severity] = None
    attachments: List[str] = []
    notes: Optional[str] = None
    medications: List[str] = []
    is_confidential: bool
    created_at: datetime
    updated_at: datetime
    created_by: str


class VaccinationRecordCreate(BaseModel):
    family_member_id: str
    vaccine_name: str = Field(..., min_length=1, max_length=200)
    date_administered: str
    provider: Optional[str] = Field(None, max_length=200)
    lot_number: Optional[str] = Field(None, max_length=100)
    next_dose_date: Optional[str] = None
    notes: Optional[str] = Field(None, max_length=500)


class VaccinationRecordResponse(BaseModel):
    id: str
    family_id: str
    family_member_id: str
    family_member_name: Optional[str] = None
    vaccine_name: str
    date_administered: str
    provider: Optional[str] = None
    lot_number: Optional[str] = None
    next_dose_date: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    created_by: str
