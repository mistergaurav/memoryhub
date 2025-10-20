from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId


class EventType(str, Enum):
    BIRTHDAY = "birthday"
    ANNIVERSARY = "anniversary"
    DEATH_ANNIVERSARY = "death_anniversary"
    GATHERING = "gathering"
    HOLIDAY = "holiday"
    REMINDER = "reminder"
    HISTORICAL_EVENT = "historical_event"
    OTHER = "other"


class EventRecurrence(str, Enum):
    NONE = "none"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


class FamilyEventBase(BaseModel):
    title: str
    description: Optional[str] = None
    event_type: EventType
    event_date: datetime
    end_date: Optional[datetime] = None
    location: Optional[str] = None
    recurrence: EventRecurrence = EventRecurrence.NONE


class FamilyEventCreate(FamilyEventBase):
    family_circle_ids: List[str] = Field(default_factory=list)
    attendee_ids: List[str] = Field(default_factory=list)
    reminder_minutes: Optional[int] = None
    genealogy_person_id: Optional[str] = None
    auto_generated: bool = False


class FamilyEventUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    event_type: Optional[EventType] = None
    event_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    location: Optional[str] = None
    recurrence: Optional[EventRecurrence] = None
    family_circle_ids: Optional[List[str]] = None
    attendee_ids: Optional[List[str]] = None
    reminder_minutes: Optional[int] = None


class FamilyEventInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    title: str
    description: Optional[str] = None
    event_type: EventType
    event_date: datetime
    end_date: Optional[datetime] = None
    location: Optional[str] = None
    recurrence: EventRecurrence
    created_by: PyObjectId
    family_circle_ids: List[PyObjectId] = Field(default_factory=list)
    attendee_ids: List[PyObjectId] = Field(default_factory=list)
    reminder_minutes: Optional[int] = None
    reminder_sent: bool = False
    genealogy_person_id: Optional[PyObjectId] = None
    auto_generated: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyEventResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    event_type: EventType
    event_date: datetime
    end_date: Optional[datetime] = None
    location: Optional[str] = None
    recurrence: EventRecurrence
    created_by: str
    created_by_name: Optional[str] = None
    family_circle_ids: List[str]
    attendee_ids: List[str]
    attendee_names: List[str] = Field(default_factory=list)
    reminder_minutes: Optional[int] = None
    genealogy_person_id: Optional[str] = None
    genealogy_person_name: Optional[str] = None
    auto_generated: bool = False
    created_at: datetime
    updated_at: datetime
