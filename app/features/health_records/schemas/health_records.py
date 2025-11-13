from pydantic import BaseModel, Field, model_validator
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
    GENETIC_CONDITION = "genetic_condition"
    FAMILY_HISTORY = "family_history"


class Severity(str, Enum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class Inheritance(str, Enum):
    AUTOSOMAL_DOMINANT = "autosomal_dominant"
    AUTOSOMAL_RECESSIVE = "autosomal_recessive"
    X_LINKED = "x_linked"
    Y_LINKED = "y_linked"
    MITOCHONDRIAL = "mitochondrial"
    MULTIFACTORIAL = "multifactorial"
    UNKNOWN = "unknown"


class SubjectType(str, Enum):
    SELF = "self"
    FAMILY = "family"
    FRIEND = "friend"


class ApprovalStatus(str, Enum):
    DRAFT = "draft"
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    REJECTED = "rejected"


class VisibilityScope(str, Enum):
    """Visibility scope for approved health records"""
    PRIVATE = "private"  # Visible only to subject user and assigned users
    FAMILY = "family"    # Visible to all family circle members
    PUBLIC = "public"    # Visible to all family members (same as family for now)


class HealthRecordCreate(BaseModel):
    subject_type: SubjectType = SubjectType.SELF
    subject_user_id: Optional[str] = None
    subject_family_member_id: Optional[str] = None
    subject_friend_circle_id: Optional[str] = None
    assigned_user_ids: List[str] = []
    family_member_id: Optional[str] = None
    genealogy_person_id: Optional[str] = None
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
    is_hereditary: bool = False
    inheritance_pattern: Optional[Inheritance] = None
    age_of_onset: Optional[int] = None
    affected_relatives: List[str] = []
    genetic_test_results: Optional[str] = Field(None, max_length=2000)
    requested_visibility: Optional[VisibilityScope] = VisibilityScope.PRIVATE
    
    @model_validator(mode='after')
    def validate_subject_consistency(self):
        if self.subject_type == SubjectType.SELF:
            if not self.subject_user_id:
                raise ValueError("subject_user_id is required when subject_type is SELF")
            if self.subject_family_member_id or self.subject_friend_circle_id:
                raise ValueError("subject_family_member_id and subject_friend_circle_id must be None when subject_type is SELF")
        
        elif self.subject_type == SubjectType.FAMILY:
            if not self.subject_family_member_id:
                raise ValueError("subject_family_member_id is required when subject_type is FAMILY")
            if self.subject_friend_circle_id:
                raise ValueError("subject_friend_circle_id must be None when subject_type is FAMILY")
        
        elif self.subject_type == SubjectType.FRIEND:
            if not self.subject_friend_circle_id:
                raise ValueError("subject_friend_circle_id is required when subject_type is FRIEND")
            if self.subject_family_member_id or self.family_member_id or self.genealogy_person_id:
                raise ValueError("subject_family_member_id, family_member_id, and genealogy_person_id must be None when subject_type is FRIEND")
        
        return self


class HealthRecordUpdate(BaseModel):
    subject_type: Optional[SubjectType] = None
    subject_user_id: Optional[str] = None
    subject_family_member_id: Optional[str] = None
    subject_friend_circle_id: Optional[str] = None
    assigned_user_ids: Optional[List[str]] = None
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
    is_hereditary: Optional[bool] = None
    inheritance_pattern: Optional[Inheritance] = None
    age_of_onset: Optional[int] = None
    affected_relatives: Optional[List[str]] = None
    genetic_test_results: Optional[str] = Field(None, max_length=2000)
    approval_status: Optional[ApprovalStatus] = None
    approved_at: Optional[datetime] = None
    approved_by: Optional[str] = None
    rejection_reason: Optional[str] = None
    visibility_scope: Optional[VisibilityScope] = None
    
    @model_validator(mode='after')
    def validate_subject_consistency_on_update(self):
        if self.subject_type is not None:
            if self.subject_type == SubjectType.SELF:
                if self.subject_user_id is None:
                    raise ValueError("subject_user_id must be provided when updating subject_type to SELF")
                if self.subject_family_member_id is not None or self.subject_friend_circle_id is not None:
                    raise ValueError("subject_family_member_id and subject_friend_circle_id must not be set when subject_type is SELF")
            
            elif self.subject_type == SubjectType.FAMILY:
                if self.subject_family_member_id is None:
                    raise ValueError("subject_family_member_id must be provided when updating subject_type to FAMILY")
                if self.subject_friend_circle_id is not None:
                    raise ValueError("subject_friend_circle_id must not be set when subject_type is FAMILY")
            
            elif self.subject_type == SubjectType.FRIEND:
                if self.subject_friend_circle_id is None:
                    raise ValueError("subject_friend_circle_id must be provided when updating subject_type to FRIEND")
                if self.subject_family_member_id is not None:
                    raise ValueError("subject_family_member_id must not be set when subject_type is FRIEND")
        
        return self


class HealthRecordResponse(BaseModel):
    id: str
    family_id: str
    subject_type: SubjectType = SubjectType.SELF
    subject_user_id: Optional[str] = None
    subject_name: Optional[str] = None
    subject_family_member_id: Optional[str] = None
    subject_friend_circle_id: Optional[str] = None
    assigned_user_ids: List[str] = []
    family_member_id: Optional[str] = None
    family_member_name: Optional[str] = None
    genealogy_person_id: Optional[str] = None
    genealogy_person_name: Optional[str] = None
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
    is_hereditary: bool = False
    inheritance_pattern: Optional[Inheritance] = None
    age_of_onset: Optional[int] = None
    affected_relatives: List[str] = []
    affected_relatives_names: List[str] = []
    genetic_test_results: Optional[str] = None
    approval_status: Optional[ApprovalStatus] = ApprovalStatus.APPROVED
    approved_at: Optional[datetime] = None
    approved_by: Optional[str] = None
    rejection_reason: Optional[str] = None
    visibility_scope: VisibilityScope = VisibilityScope.PRIVATE
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


class FamilyHealthPattern(BaseModel):
    condition_name: str
    affected_count: int
    affected_persons: List[str] = []
    inheritance_pattern: Optional[Inheritance] = None
    severity_distribution: dict = {}
    earliest_age_of_onset: Optional[int] = None
    average_age_of_onset: Optional[int] = None


class FamilyHealthInsights(BaseModel):
    total_records: int
    hereditary_conditions_count: int
    genetic_patterns: List[FamilyHealthPattern] = []
    common_conditions: List[dict] = []
    most_affected_generation: Optional[str] = None
    health_risk_factors: List[str] = []


class ReminderType(str, Enum):
    APPOINTMENT = "appointment"
    MEDICATION = "medication"
    VACCINATION = "vaccination"
    LAB_TEST = "lab_test"
    CHECKUP = "checkup"
    REFILL = "refill"
    CUSTOM = "custom"


class ReminderStatus(str, Enum):
    PENDING = "pending"
    SENT = "sent"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    SNOOZED = "snoozed"


class DeliveryChannel(str, Enum):
    IN_APP = "in_app"
    EMAIL = "email"
    PUSH = "push"
    SMS = "sms"


class RepeatFrequency(str, Enum):
    ONCE = "once"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


class HealthRecordReminderCreate(BaseModel):
    record_id: str
    assigned_user_id: str
    reminder_type: ReminderType
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    due_at: datetime
    repeat_frequency: RepeatFrequency = RepeatFrequency.ONCE
    repeat_count: Optional[int] = Field(None, ge=1, le=365)
    delivery_channels: List[DeliveryChannel] = [DeliveryChannel.IN_APP]
    metadata: dict = {}


class HealthRecordReminderUpdate(BaseModel):
    reminder_type: Optional[ReminderType] = None
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    due_at: Optional[datetime] = None
    repeat_frequency: Optional[RepeatFrequency] = None
    repeat_count: Optional[int] = Field(None, ge=1, le=365)
    delivery_channels: Optional[List[DeliveryChannel]] = None
    status: Optional[ReminderStatus] = None
    metadata: Optional[dict] = None


class HealthRecordReminderResponse(BaseModel):
    id: str
    record_id: str
    record_title: Optional[str] = None
    assigned_user_id: str
    assigned_user_name: Optional[str] = None
    reminder_type: ReminderType
    title: str
    description: Optional[str] = None
    due_at: datetime
    repeat_frequency: RepeatFrequency
    repeat_count: Optional[int] = None
    delivery_channels: List[DeliveryChannel]
    status: ReminderStatus
    metadata: dict
    created_at: datetime
    updated_at: datetime
    created_by: str


class HealthRecordApprovalRequest(BaseModel):
    """Request schema for approving a health record with visibility selection"""
    visibility_scope: VisibilityScope = Field(..., description="Visibility scope for the approved record")
