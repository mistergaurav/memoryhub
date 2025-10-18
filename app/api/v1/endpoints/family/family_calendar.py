from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from bson import ObjectId
from datetime import datetime, timedelta

from app.models.family_calendar import (
    FamilyEventCreate, FamilyEventUpdate, FamilyEventResponse
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.utils.validators import validate_object_id, validate_object_ids

router = APIRouter()



@router.post("/events", response_model=FamilyEventResponse, status_code=status.HTTP_201_CREATED)
async def create_family_event(
    event: FamilyEventCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new family event"""
    try:
        family_circle_oids = validate_object_ids(event.family_circle_ids, "family_circle_ids") if event.family_circle_ids else []
        attendee_oids = validate_object_ids(event.attendee_ids, "attendee_ids") if event.attendee_ids else []
        
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
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("family_events").insert_one(event_data)
        event_doc = await get_collection("family_events").find_one({"_id": result.inserted_id})
        
        attendee_names = []
        for attendee_id in event_doc.get("attendee_ids", []):
            user = await get_collection("users").find_one({"_id": attendee_id})
            if user:
                attendee_names.append(user.get("full_name", ""))
        
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
            created_by_name=current_user.full_name,
            family_circle_ids=[str(cid) for cid in event_doc.get("family_circle_ids", [])],
            attendee_ids=[str(aid) for aid in event_doc.get("attendee_ids", [])],
            attendee_names=attendee_names,
            reminder_minutes=event_doc.get("reminder_minutes"),
            created_at=event_doc["created_at"],
            updated_at=event_doc["updated_at"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create event: {str(e)}")


@router.get("/events", response_model=List[FamilyEventResponse])
async def list_family_events(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    event_type: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """List family events"""
    try:
        user_oid = ObjectId(current_user.id)
        
        query = {
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ]
        }
        
        if start_date:
            query["event_date"] = {"$gte": start_date}
        if end_date:
            if "event_date" in query:
                query["event_date"]["$lte"] = end_date
            else:
                query["event_date"] = {"$lte": end_date}
        if event_type:
            query["event_type"] = event_type
        
        events_cursor = get_collection("family_events").find(query).sort("event_date", 1)
        
        events = []
        async for event_doc in events_cursor:
            creator = await get_collection("users").find_one({"_id": event_doc["created_by"]})
            
            attendee_names = []
            for attendee_id in event_doc.get("attendee_ids", []):
                user = await get_collection("users").find_one({"_id": attendee_id})
                if user:
                    attendee_names.append(user.get("full_name", ""))
            
            events.append(FamilyEventResponse(
                id=str(event_doc["_id"]),
                title=event_doc["title"],
                description=event_doc.get("description"),
                event_type=event_doc["event_type"],
                event_date=event_doc["event_date"],
                end_date=event_doc.get("end_date"),
                location=event_doc.get("location"),
                recurrence=event_doc["recurrence"],
                created_by=str(event_doc["created_by"]),
                created_by_name=creator.get("full_name") if creator else None,
                family_circle_ids=[str(cid) for cid in event_doc.get("family_circle_ids", [])],
                attendee_ids=[str(aid) for aid in event_doc.get("attendee_ids", [])],
                attendee_names=attendee_names,
                reminder_minutes=event_doc.get("reminder_minutes"),
                created_at=event_doc["created_at"],
                updated_at=event_doc["updated_at"]
            ))
        
        return events
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list events: {str(e)}")


@router.get("/events/{event_id}", response_model=FamilyEventResponse)
async def get_family_event(
    event_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific event"""
    try:
        event_oid = validate_object_id(event_id, "event_id")
        if not event_oid:
            raise HTTPException(status_code=400, detail="Invalid event ID")
        
        event_doc = await get_collection("family_events").find_one({"_id": event_oid})
        if not event_doc:
            raise HTTPException(status_code=404, detail="Event not found")
        
        creator = await get_collection("users").find_one({"_id": event_doc["created_by"]})
        
        attendee_names = []
        for attendee_id in event_doc.get("attendee_ids", []):
            user = await get_collection("users").find_one({"_id": attendee_id})
            if user:
                attendee_names.append(user.get("full_name", ""))
        
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
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in event_doc.get("family_circle_ids", [])],
            attendee_ids=[str(aid) for aid in event_doc.get("attendee_ids", [])],
            attendee_names=attendee_names,
            reminder_minutes=event_doc.get("reminder_minutes"),
            created_at=event_doc["created_at"],
            updated_at=event_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get event: {str(e)}")


@router.put("/events/{event_id}", response_model=FamilyEventResponse)
async def update_family_event(
    event_id: str,
    event_update: FamilyEventUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update an event"""
    try:
        event_oid = validate_object_id(event_id, "event_id")
        if not event_oid:
            raise HTTPException(status_code=400, detail="Invalid event ID")
        
        event_doc = await get_collection("family_events").find_one({"_id": event_oid})
        if not event_doc:
            raise HTTPException(status_code=404, detail="Event not found")
        
        if str(event_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this event")
        
        update_data = {k: v for k, v in event_update.dict(exclude_unset=True).items() if v is not None}
        
        if "family_circle_ids" in update_data:
            update_data["family_circle_ids"] = [safe_object_id(cid) for cid in update_data["family_circle_ids"] if safe_object_id(cid)]
        if "attendee_ids" in update_data:
            update_data["attendee_ids"] = [safe_object_id(aid) for aid in update_data["attendee_ids"] if safe_object_id(aid)]
        
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("family_events").update_one(
            {"_id": event_oid},
            {"$set": update_data}
        )
        
        updated_event = await get_collection("family_events").find_one({"_id": event_oid})
        creator = await get_collection("users").find_one({"_id": updated_event["created_by"]})
        
        attendee_names = []
        for attendee_id in updated_event.get("attendee_ids", []):
            user = await get_collection("users").find_one({"_id": attendee_id})
            if user:
                attendee_names.append(user.get("full_name", ""))
        
        return FamilyEventResponse(
            id=str(updated_event["_id"]),
            title=updated_event["title"],
            description=updated_event.get("description"),
            event_type=updated_event["event_type"],
            event_date=updated_event["event_date"],
            end_date=updated_event.get("end_date"),
            location=updated_event.get("location"),
            recurrence=updated_event["recurrence"],
            created_by=str(updated_event["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in updated_event.get("family_circle_ids", [])],
            attendee_ids=[str(aid) for aid in updated_event.get("attendee_ids", [])],
            attendee_names=attendee_names,
            reminder_minutes=updated_event.get("reminder_minutes"),
            created_at=updated_event["created_at"],
            updated_at=updated_event["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update event: {str(e)}")


@router.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_family_event(
    event_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete an event"""
    try:
        event_oid = validate_object_id(event_id, "event_id")
        if not event_oid:
            raise HTTPException(status_code=400, detail="Invalid event ID")
        
        event_doc = await get_collection("family_events").find_one({"_id": event_oid})
        if not event_doc:
            raise HTTPException(status_code=404, detail="Event not found")
        
        if str(event_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this event")
        
        await get_collection("family_events").delete_one({"_id": event_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete event: {str(e)}")


@router.get("/birthdays", response_model=List[FamilyEventResponse])
async def get_upcoming_birthdays(
    days_ahead: int = 30,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get upcoming birthdays"""
    try:
        user_oid = ObjectId(current_user.id)
        
        end_date = datetime.utcnow() + timedelta(days=days_ahead)
        
        events_cursor = get_collection("family_events").find({
            "event_type": "birthday",
            "event_date": {"$lte": end_date},
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ]
        }).sort("event_date", 1)
        
        events = []
        async for event_doc in events_cursor:
            creator = await get_collection("users").find_one({"_id": event_doc["created_by"]})
            
            attendee_names = []
            for attendee_id in event_doc.get("attendee_ids", []):
                user = await get_collection("users").find_one({"_id": attendee_id})
                if user:
                    attendee_names.append(user.get("full_name", ""))
            
            events.append(FamilyEventResponse(
                id=str(event_doc["_id"]),
                title=event_doc["title"],
                description=event_doc.get("description"),
                event_type=event_doc["event_type"],
                event_date=event_doc["event_date"],
                end_date=event_doc.get("end_date"),
                location=event_doc.get("location"),
                recurrence=event_doc["recurrence"],
                created_by=str(event_doc["created_by"]),
                created_by_name=creator.get("full_name") if creator else None,
                family_circle_ids=[str(cid) for cid in event_doc.get("family_circle_ids", [])],
                attendee_ids=[str(aid) for aid in event_doc.get("attendee_ids", [])],
                attendee_names=attendee_names,
                reminder_minutes=event_doc.get("reminder_minutes"),
                created_at=event_doc["created_at"],
                updated_at=event_doc["updated_at"]
            ))
        
        return events
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get birthdays: {str(e)}")
