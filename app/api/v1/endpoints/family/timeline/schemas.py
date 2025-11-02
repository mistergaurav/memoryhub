from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class TimelineEventType(str, Enum):
    BIRTH = "birth"
    DEATH = "death"
    MARRIAGE = "marriage"
    HEALTH_RECORD = "health_record"
    CALENDAR_EVENT = "calendar_event"
    MILESTONE = "milestone"
    TRADITION = "tradition"
    IMMIGRATION = "immigration"
    ACHIEVEMENT = "achievement"


class TimelineEvent(BaseModel):
    id: str
    event_type: TimelineEventType
    title: str
    description: Optional[str] = None
    event_date: datetime
    genealogy_person_id: Optional[str] = None
    genealogy_person_name: Optional[str] = None
    generation: Optional[int] = None
    location: Optional[str] = None
    photos: List[str] = []
    source_collection: str
    source_id: str
    importance: int = 0


class FamilyTimelineResponse(BaseModel):
    events: List[TimelineEvent] = []
    total_events: int = 0
    date_range: dict = {}
    generations_covered: List[int] = []
    event_type_counts: dict = {}


class TimelineFilter(BaseModel):
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    event_types: List[TimelineEventType] = []
    genealogy_person_ids: List[str] = []
    generations: List[int] = []
    include_health: bool = True
    include_traditions: bool = True
    include_milestones: bool = True
    include_calendar: bool = True
