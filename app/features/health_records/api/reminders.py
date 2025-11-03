from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from ..schemas.health_records import (
    HealthRecordReminderCreate,
    HealthRecordReminderUpdate,
    HealthRecordReminderResponse,
    ReminderStatus,
)
from ..services.reminder_service import ReminderService
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.base_repository import BaseRepository
from app.models.responses import create_success_response, create_paginated_response

router = APIRouter()

reminder_service = ReminderService()
reminders_repo = BaseRepository("health_record_reminders")
health_records_repo = BaseRepository("health_records")


def reminder_to_response(reminder_doc: dict, record_title: Optional[str] = None, user_name: Optional[str] = None) -> HealthRecordReminderResponse:
    """Convert MongoDB reminder document to response model"""
    return HealthRecordReminderResponse(
        id=str(reminder_doc["_id"]),
        record_id=str(reminder_doc["record_id"]),
        record_title=record_title,
        assigned_user_id=str(reminder_doc["assigned_user_id"]),
        assigned_user_name=user_name,
        reminder_type=reminder_doc["reminder_type"],
        title=reminder_doc["title"],
        description=reminder_doc.get("description"),
        due_at=reminder_doc["due_at"],
        repeat_frequency=reminder_doc["repeat_frequency"],
        repeat_count=reminder_doc.get("repeat_count"),
        delivery_channels=reminder_doc["delivery_channels"],
        status=reminder_doc["status"],
        metadata=reminder_doc.get("metadata", {}),
        created_at=reminder_doc["created_at"],
        updated_at=reminder_doc["updated_at"],
        created_by=str(reminder_doc["created_by"])
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_reminder(
    reminder: HealthRecordReminderCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new health record reminder"""
    reminder_doc = await reminder_service.create_reminder(
        reminder,
        str(current_user.id),
        current_user.full_name
    )
    
    record = await health_records_repo.find_one({"_id": reminder_doc["record_id"]})
    record_title = record.get("title") if record else None
    
    return create_success_response(
        message="Reminder created successfully",
        data=reminder_to_response(reminder_doc, record_title)
    )


@router.get("/")
async def list_reminders(
    record_id: Optional[str] = Query(None, description="Filter by health record ID"),
    assigned_user_id: Optional[str] = Query(None, description="Filter by assigned user ID"),
    reminder_status: Optional[ReminderStatus] = Query(None, description="Filter by status"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List health record reminders with optional filtering"""
    query: Dict[str, Any] = {}
    user_oid = ObjectId(current_user.id)
    
    if record_id:
        record_oid = reminders_repo.validate_object_id(record_id, "record_id")
        record = await health_records_repo.find_by_id(
            record_id,
            raise_404=True,
            error_message="Health record not found"
        )
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Health record not found"
            )
        
        has_access = (
            str(record["family_id"]) == current_user.id or
            record.get("subject_user_id") == user_oid or
            user_oid in record.get("assigned_user_ids", [])
        )
        
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view reminders for this record"
            )
        
        query["record_id"] = record_oid
    else:
        user_records = await health_records_repo.find_many(
            filter_dict={"family_id": user_oid},
            limit=10000
        )
        
        assigned_records = await health_records_repo.find_many(
            filter_dict={
                "$or": [
                    {"subject_user_id": user_oid},
                    {"assigned_user_ids": user_oid}
                ]
            },
            limit=10000
        )
        
        all_record_ids = list(set([r["_id"] for r in user_records] + [r["_id"] for r in assigned_records]))
        
        query["$or"] = [
            {"record_id": {"$in": all_record_ids}},
            {"assigned_user_id": user_oid}
        ]
    
    if assigned_user_id:
        assigned_oid = reminders_repo.validate_object_id(assigned_user_id, "assigned_user_id")
        query["assigned_user_id"] = assigned_oid
    
    if reminder_status:
        query["status"] = reminder_status
    
    skip = (page - 1) * page_size
    reminders = await reminders_repo.find_many(
        filter_dict=query,
        skip=skip,
        limit=page_size,
        sort_by="due_at",
        sort_order=1
    )
    
    total = await reminders_repo.count(query)
    
    reminder_responses = []
    for reminder_doc in reminders:
        try:
            record = await health_records_repo.find_one(
                {"_id": reminder_doc["record_id"]}
            )
            record_title = record.get("title") if record else None
        except:
            record_title = None
        
        reminder_responses.append(reminder_to_response(reminder_doc, record_title))
    
    return create_paginated_response(
        items=reminder_responses,
        total=total,
        page=page,
        page_size=page_size,
        message="Reminders retrieved successfully"
    )


@router.get("/{reminder_id}")
async def get_reminder(
    reminder_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific reminder"""
    reminder_doc = await reminders_repo.find_by_id(
        reminder_id,
        raise_404=True,
        error_message="Reminder not found"
    )
    
    if not reminder_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found"
        )
    
    record = await health_records_repo.find_one(
        {"_id": reminder_doc["record_id"]}
    )
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Associated health record not found"
        )
    
    if str(record["family_id"]) != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this reminder"
        )
    
    return create_success_response(
        message="Reminder retrieved successfully",
        data=reminder_to_response(reminder_doc, record.get("title"))
    )


@router.put("/{reminder_id}")
async def update_reminder(
    reminder_id: str,
    reminder_update: HealthRecordReminderUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a health record reminder"""
    updated_reminder = await reminder_service.update_reminder(
        reminder_id,
        reminder_update,
        str(current_user.id)
    )
    
    record = await health_records_repo.find_one(
        {"_id": updated_reminder["record_id"]}
    )
    
    return create_success_response(
        message="Reminder updated successfully",
        data=reminder_to_response(updated_reminder, record.get("title") if record else None)
    )


@router.delete("/{reminder_id}", status_code=status.HTTP_200_OK)
async def delete_reminder(
    reminder_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a health record reminder"""
    await reminder_service.delete_reminder(reminder_id, str(current_user.id))
    return create_success_response(message="Reminder deleted successfully")


@router.post("/{reminder_id}/snooze", status_code=status.HTTP_200_OK)
async def snooze_reminder(
    reminder_id: str,
    snooze_until: datetime,
    current_user: UserInDB = Depends(get_current_user)
):
    """Snooze a reminder until a specific time"""
    updated_reminder = await reminder_service.snooze_reminder(
        reminder_id,
        snooze_until,
        str(current_user.id)
    )
    
    record = await health_records_repo.find_one(
        {"_id": updated_reminder["record_id"]}
    )
    
    return create_success_response(
        message="Reminder snoozed successfully",
        data=reminder_to_response(updated_reminder, record.get("title") if record else None)
    )


@router.post("/{reminder_id}/complete", status_code=status.HTTP_200_OK)
async def complete_reminder(
    reminder_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark a reminder as completed"""
    updated_reminder = await reminder_service.complete_reminder(
        reminder_id,
        str(current_user.id)
    )
    
    record = await health_records_repo.find_one(
        {"_id": updated_reminder["record_id"]}
    )
    
    return create_success_response(
        message="Reminder completed successfully",
        data=reminder_to_response(updated_reminder, record.get("title") if record else None)
    )
