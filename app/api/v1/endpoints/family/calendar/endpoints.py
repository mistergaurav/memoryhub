from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime, timedelta

from .schemas import (
    FamilyEventCreate, FamilyEventUpdate, FamilyEventResponse
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from .repository import FamilyCalendarRepository
from app.utils.validators import validate_object_ids
from app.utils.audit_logger import log_audit_event
from app.models.responses import create_success_response, create_paginated_response, create_message_response

router = APIRouter()
calendar_repo = FamilyCalendarRepository()


async def get_attendee_info(attendee_ids: List[ObjectId]) -> List[str]:
    """Helper function to get attendee names efficiently"""
    if not attendee_ids:
        return []
    
    users_cursor = get_collection("users").find({"_id": {"$in": attendee_ids}})
    attendee_names = []
    async for user in users_cursor:
        attendee_names.append(user.get("full_name", ""))
    return attendee_names


async def get_creator_name(created_by_id: ObjectId) -> Optional[str]:
    """Helper function to get creator name"""
    creator = await get_collection("users").find_one({"_id": created_by_id})
    return creator.get("full_name") if creator else None


def build_event_response(event_doc: Dict[str, Any], creator_name: Optional[str] = None, attendee_names: Optional[List[str]] = None) -> FamilyEventResponse:
    """Helper function to build event response"""
    return FamilyEventResponse(
        id=str(event_doc["_id"]),
        title=event_doc["title"],
        description=event_doc.get("description"),
        event_type=event_doc["event_type"],
        event_date=event_doc["event_date"],
        end_date=event_doc.get("end_date"),
        location=event_doc.get("location"),
        recurrence=event_doc["recurrence"],
        created_by=str(event_doc["created_by"]),
        created_by_name=creator_name,
        family_circle_ids=[str(cid) for cid in event_doc.get("family_circle_ids", [])],
        attendee_ids=[str(aid) for aid in event_doc.get("attendee_ids", [])],
        attendee_names=attendee_names or [],
        reminder_minutes=event_doc.get("reminder_minutes"),
        genealogy_person_id=str(event_doc["genealogy_person_id"]) if event_doc.get("genealogy_person_id") else None,
        genealogy_person_name=event_doc.get("genealogy_person_name"),
        auto_generated=event_doc.get("auto_generated", False),
        created_at=event_doc["created_at"],
        updated_at=event_doc["updated_at"]
    )


@router.post("/events", status_code=status.HTTP_201_CREATED)
async def create_family_event(
    event: FamilyEventCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a new family event with optional conflict detection.
    
    - Validates circle IDs and attendee IDs
    - Supports recurrence patterns (none, daily, weekly, monthly, yearly)
    - Optional reminder configuration
    - Genealogy integration for auto-generated events
    """
    family_circle_oids = validate_object_ids(event.family_circle_ids, "family_circle_ids") if event.family_circle_ids else []
    
    # If no family circles provided, default to current user's ID (personal timeline)
    if not family_circle_oids:
        family_circle_oids.append(ObjectId(current_user.id))
    
    attendee_oids = validate_object_ids(event.attendee_ids, "attendee_ids") if event.attendee_ids else []
    
    genealogy_person_oid = None
    if event.genealogy_person_id:
        genealogy_person_oid = ObjectId(event.genealogy_person_id)
    
    event_data = {
        "title": event.title,
        "description": event.description,
        "event_type": event.event_type,
        "event_date": event.event_date,
        "end_date": event.end_date,
        "location": event.location,
        "recurrence": event.recurrence,
        "created_by": ObjectId(current_user.id),
        "family_circle_ids": family_circle_oids,
        "attendee_ids": attendee_oids,
        "reminder_minutes": event.reminder_minutes,
        "reminder_sent": False,
        "genealogy_person_id": genealogy_person_oid,
        "auto_generated": event.auto_generated,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    event_doc = await calendar_repo.create(event_data)
    
    conflicts = await calendar_repo.detect_conflicts(
        user_id=str(current_user.id),
        event_date=event.event_date,
        end_date=event.end_date,
        exclude_event_id=str(event_doc["_id"])
    )
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="calendar_event_created",
        event_details={
            "event_id": str(event_doc["_id"]),
            "title": event.title,
            "event_type": event.event_type,
            "has_conflicts": len(conflicts) > 0
        }
    )
    
    attendee_names = await get_attendee_info(attendee_oids)
    response = build_event_response(event_doc, current_user.full_name, attendee_names)
    
    result_data = {
        "event": response.model_dump(),
        "conflicts": len(conflicts),
        "conflict_warning": f"This event conflicts with {len(conflicts)} other event(s)" if conflicts else None
    }
    
    return create_success_response(
        message="Event created successfully" + (f" (conflicts detected with {len(conflicts)} event(s))" if conflicts else ""),
        data=result_data
    )


@router.get("/events")
async def list_family_events(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=100, description="Number of events per page"),
    start_date: Optional[datetime] = Query(None, description="Filter by start date"),
    end_date: Optional[datetime] = Query(None, description="Filter by end date"),
    event_type: Optional[str] = Query(None, description="Filter by event type"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List family events with pagination and filtering.
    
    - Returns events created by user or where user is an attendee
    - Supports date range filtering
    - Supports event type filtering
    - Sorted chronologically by event date
    """
    skip = (page - 1) * page_size
    
    events = await calendar_repo.find_user_events(
        user_id=str(current_user.id),
        start_date=start_date,
        end_date=end_date,
        event_type=event_type,
        skip=skip,
        limit=page_size
    )
    
    total = await calendar_repo.count_user_events(
        user_id=str(current_user.id),
        start_date=start_date,
        end_date=end_date,
        event_type=event_type
    )
    
    event_responses = []
    for event_doc in events:
        creator_name = await get_creator_name(event_doc["created_by"])
        attendee_names = await get_attendee_info(event_doc.get("attendee_ids", []))
        event_responses.append(build_event_response(event_doc, creator_name, attendee_names))
    
    return create_paginated_response(
        items=[e.model_dump() for e in event_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Events retrieved successfully"
    )


@router.get("/events/{event_id}")
async def get_family_event(
    event_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a specific event with full details.
    
    - Returns complete event information
    - Includes creator and attendee names
    """
    event_doc = await calendar_repo.find_by_id(
        event_id,
        raise_404=True,
        error_message="Event not found"
    )
    assert event_doc is not None
    
    creator_name = await get_creator_name(event_doc["created_by"])
    attendee_names = await get_attendee_info(event_doc.get("attendee_ids", []))
    response = build_event_response(event_doc, creator_name, attendee_names)
    
    return create_success_response(
        message="Event retrieved successfully",
        data=response.model_dump()
    )


@router.put("/events/{event_id}")
async def update_family_event(
    event_id: str,
    event_update: FamilyEventUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Update an event (owner only).
    
    - Only event creator can update
    - Validates IDs if provided
    - Detects new conflicts after update
    - Logs update for audit trail
    """
    await calendar_repo.check_event_ownership(event_id, str(current_user.id), raise_error=True)
    
    update_data = {k: v for k, v in event_update.model_dump(exclude_unset=True).items() if v is not None}
    
    if "family_circle_ids" in update_data:
        update_data["family_circle_ids"] = validate_object_ids(update_data["family_circle_ids"], "family_circle_ids")
    if "attendee_ids" in update_data:
        update_data["attendee_ids"] = validate_object_ids(update_data["attendee_ids"], "attendee_ids")
    
    update_data["updated_at"] = datetime.utcnow()
    
    updated_event = await calendar_repo.update_by_id(event_id, update_data)
    assert updated_event is not None
    
    conflicts = []
    if "event_date" in update_data or "end_date" in update_data:
        conflicts = await calendar_repo.detect_conflicts(
            user_id=str(current_user.id),
            event_date=updated_event["event_date"],
            end_date=updated_event.get("end_date"),
            exclude_event_id=event_id
        )
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="calendar_event_updated",
        event_details={
            "event_id": event_id,
            "updated_fields": list(update_data.keys()),
            "has_conflicts": len(conflicts) > 0
        }
    )
    
    creator_name = await get_creator_name(updated_event["created_by"])
    attendee_names = await get_attendee_info(updated_event.get("attendee_ids", []))
    response = build_event_response(updated_event, creator_name, attendee_names)
    
    result_data = {
        "event": response.model_dump(),
        "conflicts": len(conflicts),
        "conflict_warning": f"This event now conflicts with {len(conflicts)} other event(s)" if conflicts else None
    }
    
    return create_success_response(
        message="Event updated successfully",
        data=result_data
    )


@router.delete("/events/{event_id}", status_code=status.HTTP_200_OK)
async def delete_family_event(
    event_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete an event (owner only).
    
    - Only event creator can delete
    - Logs deletion for audit trail
    """
    event_doc = await calendar_repo.find_by_id(event_id, raise_404=True)
    assert event_doc is not None
    
    await calendar_repo.check_event_ownership(event_id, str(current_user.id), raise_error=True)
    
    await calendar_repo.delete_by_id(event_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="calendar_event_deleted",
        event_details={
            "event_id": event_id,
            "title": event_doc.get("title"),
            "event_type": event_doc.get("event_type")
        }
    )
    
    return create_message_response("Event deleted successfully")


@router.get("/birthdays")
async def get_upcoming_birthdays(
    days_ahead: int = Query(30, ge=1, le=365, description="Number of days to look ahead"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get upcoming birthdays for the user.
    
    - Returns birthday events within specified days
    - Includes auto-generated genealogy birthdays
    - Sorted chronologically
    """
    events = await calendar_repo.get_upcoming_birthdays(
        user_id=str(current_user.id),
        days_ahead=days_ahead
    )
    
    event_responses = []
    for event_doc in events:
        creator_name = await get_creator_name(event_doc["created_by"])
        attendee_names = await get_attendee_info(event_doc.get("attendee_ids", []))
        event_responses.append(build_event_response(event_doc, creator_name, attendee_names))
    
    return create_success_response(
        message=f"Found {len(event_responses)} upcoming birthdays",
        data=[e.model_dump() for e in event_responses]
    )


@router.post("/events/{event_id}/conflicts")
async def check_event_conflicts(
    event_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Check for scheduling conflicts with an event.
    
    - Returns list of conflicting events
    - Useful for conflict resolution
    """
    event_doc = await calendar_repo.find_by_id(event_id, raise_404=True)
    assert event_doc is not None
    
    conflicts = await calendar_repo.detect_conflicts(
        user_id=str(current_user.id),
        event_date=event_doc["event_date"],
        end_date=event_doc.get("end_date"),
        exclude_event_id=event_id
    )
    
    conflict_responses = []
    for conflict_doc in conflicts:
        creator_name = await get_creator_name(conflict_doc["created_by"])
        attendee_names = await get_attendee_info(conflict_doc.get("attendee_ids", []))
        conflict_responses.append(build_event_response(conflict_doc, creator_name, attendee_names))
    
    return create_success_response(
        message=f"Found {len(conflict_responses)} conflicting event(s)",
        data={
            "count": len(conflict_responses),
            "conflicts": [c.model_dump() for c in conflict_responses]
        }
    )
