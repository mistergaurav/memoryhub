from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.family.health_records import (
    HealthRecordReminderCreate,
    HealthRecordReminderUpdate, 
    HealthRecordReminderResponse,
    ReminderStatus
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.base_repository import BaseRepository
from app.models.responses import create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event

router = APIRouter()

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
    # Validate record exists and user has access
    record_oid = reminders_repo.validate_object_id(reminder.record_id, "record_id")
    
    record = await health_records_repo.find_by_id(
        reminder.record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    # Verify user owns the health record
    if str(record["family_id"]) != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create reminder for this record"
        )
    
    # Validate assigned user
    assigned_user_oid = reminders_repo.validate_object_id(reminder.assigned_user_id, "assigned_user_id")
    
    # Create reminder
    reminder_data = {
        "record_id": record_oid,
        "assigned_user_id": assigned_user_oid,
        "reminder_type": reminder.reminder_type,
        "title": reminder.title,
        "description": reminder.description,
        "due_at": reminder.due_at,
        "repeat_frequency": reminder.repeat_frequency,
        "repeat_count": reminder.repeat_count,
        "delivery_channels": reminder.delivery_channels,
        "status": ReminderStatus.PENDING,
        "metadata": reminder.metadata,
        "created_by": ObjectId(current_user.id)
    }
    
    reminder_doc = await reminders_repo.create(reminder_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_HEALTH_REMINDER",
        event_details={
            "resource_type": "health_record_reminder",
            "resource_id": str(reminder_doc["_id"]),
            "reminder_type": reminder.reminder_type,
            "record_id": reminder.record_id
        }
    )
    
    return create_success_response(
        message="Reminder created successfully",
        data=reminder_to_response(reminder_doc, record.get("title"))
    )


@router.get("/")
async def list_reminders(
    record_id: Optional[str] = Query(None, description="Filter by health record ID"),
    assigned_user_id: Optional[str] = Query(None, description="Filter by assigned user ID"),
    status: Optional[ReminderStatus] = Query(None, description="Filter by status"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List health record reminders with optional filtering"""
    query: Dict[str, Any] = {}
    
    # If record_id is provided, verify user has access to that record
    if record_id:
        record_oid = reminders_repo.validate_object_id(record_id, "record_id")
        record = await health_records_repo.find_by_id(
            record_id,
            raise_404=True,
            error_message="Health record not found"
        )
        
        if str(record["family_id"]) != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view reminders for this record"
            )
        
        query["record_id"] = record_oid
    else:
        # Find all health records for this user
        user_records = await health_records_repo.find_many(
            filter_dict={"family_id": ObjectId(current_user.id)},
            limit=10000  # Get all user's records
        )
        record_ids = [record["_id"] for record in user_records]
        query["record_id"] = {"$in": record_ids}
    
    if assigned_user_id:
        assigned_oid = reminders_repo.validate_object_id(assigned_user_id, "assigned_user_id")
        query["assigned_user_id"] = assigned_oid
    
    if status:
        query["status"] = status
    
    skip = (page - 1) * page_size
    reminders = await reminders_repo.find_many(
        filter_dict=query,
        skip=skip,
        limit=page_size,
        sort_by="due_at",
        sort_order=1  # Ascending - earliest first
    )
    
    total = await reminders_repo.count(query)
    
    # Enrich reminders with record titles
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
    
    # Verify user has access to the associated health record
    record = await health_records_repo.find_one(
        {"_id": reminder_doc["record_id"]}
    )
    
    if not record or str(record["family_id"]) != current_user.id:
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
    reminder_doc = await reminders_repo.find_by_id(
        reminder_id,
        raise_404=True,
        error_message="Reminder not found"
    )
    
    # Verify user has access to the associated health record
    record = await health_records_repo.find_one(
        {"_id": reminder_doc["record_id"]}
    )
    
    if not record or str(record["family_id"]) != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this reminder"
        )
    
    update_data = {k: v for k, v in reminder_update.dict(exclude_unset=True).items() if v is not None}
    
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No update data provided"
        )
    
    updated_reminder = await reminders_repo.update_by_id(reminder_id, update_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="UPDATE_HEALTH_REMINDER",
        event_details={
            "resource_type": "health_record_reminder",
            "resource_id": reminder_id,
            "updates": list(update_data.keys())
        }
    )
    
    return create_success_response(
        message="Reminder updated successfully",
        data=reminder_to_response(updated_reminder, record.get("title"))
    )


@router.delete("/{reminder_id}", status_code=status.HTTP_200_OK)
async def delete_reminder(
    reminder_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a health record reminder"""
    reminder_doc = await reminders_repo.find_by_id(
        reminder_id,
        raise_404=True,
        error_message="Reminder not found"
    )
    
    # Verify user has access to the associated health record
    record = await health_records_repo.find_one(
        {"_id": reminder_doc["record_id"]}
    )
    
    if not record or str(record["family_id"]) != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this reminder"
        )
    
    await reminders_repo.delete_by_id(reminder_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="DELETE_HEALTH_REMINDER",
        event_details={
            "resource_type": "health_record_reminder",
            "resource_id": reminder_id,
            "reminder_type": reminder_doc.get("reminder_type", "unknown")
        }
    )
    
    return create_success_response(message="Reminder deleted successfully")


@router.post("/{reminder_id}/snooze", status_code=status.HTTP_200_OK)
async def snooze_reminder(
    reminder_id: str,
    snooze_until: datetime,
    current_user: UserInDB = Depends(get_current_user)
):
    """Snooze a reminder until a specific time"""
    reminder_doc = await reminders_repo.find_by_id(
        reminder_id,
        raise_404=True,
        error_message="Reminder not found"
    )
    
    # Verify user has access
    record = await health_records_repo.find_one(
        {"_id": reminder_doc["record_id"]}
    )
    
    if not record or str(record["family_id"]) != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to snooze this reminder"
        )
    
    # Update reminder
    update_data = {
        "status": ReminderStatus.SNOOZED,
        "due_at": snooze_until,
        "metadata": {
            **reminder_doc.get("metadata", {}),
            "snoozed_at": datetime.utcnow(),
            "original_due_at": reminder_doc["due_at"]
        }
    }
    
    updated_reminder = await reminders_repo.update_by_id(reminder_id, update_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="SNOOZE_HEALTH_REMINDER",
        event_details={
            "resource_type": "health_record_reminder",
            "resource_id": reminder_id,
            "snooze_until": str(snooze_until)
        }
    )
    
    return create_success_response(
        message="Reminder snoozed successfully",
        data=reminder_to_response(updated_reminder, record.get("title"))
    )


@router.post("/{reminder_id}/complete", status_code=status.HTTP_200_OK)
async def complete_reminder(
    reminder_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark a reminder as completed"""
    reminder_doc = await reminders_repo.find_by_id(
        reminder_id,
        raise_404=True,
        error_message="Reminder not found"
    )
    
    # Verify user has access
    record = await health_records_repo.find_one(
        {"_id": reminder_doc["record_id"]}
    )
    
    if not record or str(record["family_id"]) != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to complete this reminder"
        )
    
    # Update reminder status
    update_data = {
        "status": ReminderStatus.COMPLETED,
        "metadata": {
            **reminder_doc.get("metadata", {}),
            "completed_at": datetime.utcnow(),
            "completed_by": current_user.id
        }
    }
    
    updated_reminder = await reminders_repo.update_by_id(reminder_id, update_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="COMPLETE_HEALTH_REMINDER",
        event_details={
            "resource_type": "health_record_reminder",
            "resource_id": reminder_id
        }
    )
    
    return create_success_response(
        message="Reminder marked as completed",
        data=reminder_to_response(updated_reminder, record.get("title"))
    )
