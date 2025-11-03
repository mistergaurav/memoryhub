from typing import Dict, Any, Optional
from bson import ObjectId
from datetime import datetime

from app.repositories.base_repository import BaseRepository
from ..schemas.health_records import (
    HealthRecordReminderCreate,
    HealthRecordReminderUpdate,
    ReminderStatus,
)
from app.api.v1.endpoints.social.notifications import create_notification
from app.schemas.notification import NotificationType
from app.utils.audit_logger import log_audit_event
from app.repositories.family_repository import FamilyRepository


class ReminderService:
    """
    Service layer for health record reminders.
    
    Handles:
    - Reminder creation and management
    - Notification orchestration
    - Reminder status updates (complete, snooze)
    """
    
    def __init__(self):
        self.reminders_repo = BaseRepository("health_record_reminders")
        self.health_records_repo = BaseRepository("health_records")
    
    async def create_reminder(
        self,
        reminder: HealthRecordReminderCreate,
        current_user_id: str,
        current_user_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new health record reminder with authorization.
        
        Args:
            reminder: Reminder creation data
            current_user_id: ID of the user creating the reminder
            current_user_name: Name of the user creating the reminder
            
        Returns:
            Created reminder document
            
        Raises:
            HTTPException: If user doesn't have access to the health record
        """
        from fastapi import HTTPException, status
        
        record_oid = self.reminders_repo.validate_object_id(reminder.record_id, "record_id")
        
        record = await self.health_records_repo.find_by_id(
            reminder.record_id,
            raise_404=True,
            error_message="Health record not found"
        )
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Health record not found"
            )
        
        has_access = await self._check_record_access(record, current_user_id)
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to create reminder for this record"
            )
        
        assigned_user_oid = self.reminders_repo.validate_object_id(reminder.assigned_user_id, "assigned_user_id")
        
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
            "created_by": ObjectId(current_user_id)
        }
        
        reminder_doc = await self.reminders_repo.create(reminder_data)
        
        if reminder.assigned_user_id and reminder.assigned_user_id != current_user_id:
            await create_notification(
                user_id=reminder.assigned_user_id,
                notification_type=NotificationType.HEALTH_REMINDER_ASSIGNMENT,
                title="Health Reminder Assigned to You",
                message=f"{current_user_name or 'Someone'} created a health reminder '{reminder.title}' for you due on {reminder.due_at.strftime('%B %d, %Y')}.",
                actor_id=str(current_user_id),
                target_type="health_reminder",
                target_id=str(reminder_doc["_id"])
            )
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="CREATE_HEALTH_REMINDER",
            event_details={
                "resource_type": "health_record_reminder",
                "resource_id": str(reminder_doc["_id"]),
                "reminder_type": reminder.reminder_type,
                "record_id": reminder.record_id
            }
        )
        
        return reminder_doc
    
    async def update_reminder(
        self,
        reminder_id: str,
        reminder_update: HealthRecordReminderUpdate,
        current_user_id: str
    ) -> Dict[str, Any]:
        """
        Update a health record reminder.
        
        Args:
            reminder_id: ID of the reminder to update
            reminder_update: Update data
            current_user_id: ID of the user updating the reminder
            
        Returns:
            Updated reminder document
            
        Raises:
            HTTPException: If user doesn't have access
        """
        from fastapi import HTTPException, status
        
        reminder_doc = await self.reminders_repo.find_by_id(
            reminder_id,
            raise_404=True,
            error_message="Reminder not found"
        )
        
        record = await self.health_records_repo.find_one(
            {"_id": reminder_doc["record_id"]}
        )
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated health record not found"
            )
        
        has_access = await self._check_record_access(record, current_user_id)
        if not has_access:
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
        
        updated_reminder = await self.reminders_repo.update_by_id(reminder_id, update_data)
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="UPDATE_HEALTH_REMINDER",
            event_details={
                "resource_type": "health_record_reminder",
                "resource_id": reminder_id,
                "updates": list(update_data.keys())
            }
        )
        
        return updated_reminder
    
    async def delete_reminder(
        self,
        reminder_id: str,
        current_user_id: str
    ) -> bool:
        """
        Delete a health record reminder.
        
        Args:
            reminder_id: ID of the reminder to delete
            current_user_id: ID of the user deleting the reminder
            
        Returns:
            True if deleted successfully
            
        Raises:
            HTTPException: If user doesn't have access
        """
        from fastapi import HTTPException, status
        
        reminder_doc = await self.reminders_repo.find_by_id(
            reminder_id,
            raise_404=True,
            error_message="Reminder not found"
        )
        
        record = await self.health_records_repo.find_one(
            {"_id": reminder_doc["record_id"]}
        )
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated health record not found"
            )
        
        has_access = await self._check_record_access(record, current_user_id)
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this reminder"
            )
        
        await self.reminders_repo.delete_by_id(reminder_id)
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="DELETE_HEALTH_REMINDER",
            event_details={
                "resource_type": "health_record_reminder",
                "resource_id": reminder_id,
                "reminder_type": reminder_doc.get("reminder_type", "unknown")
            }
        )
        
        return True
    
    async def snooze_reminder(
        self,
        reminder_id: str,
        snooze_until: datetime,
        current_user_id: str
    ) -> Dict[str, Any]:
        """
        Snooze a reminder until a specific time.
        
        Args:
            reminder_id: ID of the reminder to snooze
            snooze_until: New due date for the reminder
            current_user_id: ID of the user snoozing the reminder
            
        Returns:
            Updated reminder document
            
        Raises:
            HTTPException: If user doesn't have access
        """
        from fastapi import HTTPException, status
        
        reminder_doc = await self.reminders_repo.find_by_id(
            reminder_id,
            raise_404=True,
            error_message="Reminder not found"
        )
        
        record = await self.health_records_repo.find_one(
            {"_id": reminder_doc["record_id"]}
        )
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated health record not found"
            )
        
        has_access = await self._check_record_access(record, current_user_id)
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to snooze this reminder"
            )
        
        update_data = {
            "status": ReminderStatus.SNOOZED,
            "due_at": snooze_until,
            "metadata": {
                **reminder_doc.get("metadata", {}),
                "snoozed_at": datetime.utcnow(),
                "original_due_at": reminder_doc["due_at"]
            }
        }
        
        updated_reminder = await self.reminders_repo.update_by_id(reminder_id, update_data)
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="SNOOZE_HEALTH_REMINDER",
            event_details={
                "resource_type": "health_record_reminder",
                "resource_id": reminder_id,
                "snooze_until": str(snooze_until)
            }
        )
        
        return updated_reminder
    
    async def complete_reminder(
        self,
        reminder_id: str,
        current_user_id: str
    ) -> Dict[str, Any]:
        """
        Mark a reminder as completed.
        
        Args:
            reminder_id: ID of the reminder to complete
            current_user_id: ID of the user completing the reminder
            
        Returns:
            Updated reminder document
            
        Raises:
            HTTPException: If user doesn't have access
        """
        from fastapi import HTTPException, status
        
        reminder_doc = await self.reminders_repo.find_by_id(
            reminder_id,
            raise_404=True,
            error_message="Reminder not found"
        )
        
        record = await self.health_records_repo.find_one(
            {"_id": reminder_doc["record_id"]}
        )
        
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated health record not found"
            )
        
        has_access = await self._check_record_access(record, current_user_id)
        if not has_access:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to complete this reminder"
            )
        
        update_data = {
            "status": ReminderStatus.COMPLETED,
            "metadata": {
                **reminder_doc.get("metadata", {}),
                "completed_at": datetime.utcnow(),
                "completed_by": current_user_id
            }
        }
        
        updated_reminder = await self.reminders_repo.update_by_id(reminder_id, update_data)
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="COMPLETE_HEALTH_REMINDER",
            event_details={
                "resource_type": "health_record_reminder",
                "resource_id": reminder_id
            }
        )
        
        return updated_reminder
    
    async def check_reminder_access(
        self,
        reminder_doc: Dict[str, Any],
        current_user_id: str
    ) -> bool:
        """
        Check if user has access to a reminder.
        
        Args:
            reminder_doc: Reminder document
            current_user_id: ID of the current user
            
        Returns:
            True if user has access, False otherwise
        """
        record = await self.health_records_repo.find_one(
            {"_id": reminder_doc["record_id"]}
        )
        
        if not record:
            return False
        
        return await self._check_record_access(record, current_user_id)
    
    async def _check_record_access(
        self,
        record: Dict[str, Any],
        current_user_id: str
    ) -> bool:
        """
        Check if user has access to a health record for reminder operations.
        
        User has access if they:
        - Created the record
        - Are assigned to the record
        - Are the subject user
        - Are a member of the family circle (for FAMILY type)
        - Own the record (family_id equals user_id for personal records)
        
        Args:
            record: Health record document
            current_user_id: ID of the current user
            
        Returns:
            True if user has access, False otherwise
        """
        user_oid = ObjectId(current_user_id)
        
        if record.get("created_by") == user_oid:
            return True
        
        if user_oid in record.get("assigned_user_ids", []):
            return True
        
        if record.get("subject_user_id") == user_oid:
            return True
        
        if record.get("family_id") == user_oid:
            return True
        
        if record.get("subject_type") == "family":
            family_repo = FamilyRepository()
            try:
                family_id = record.get("family_id")
                if family_id:
                    is_member = await family_repo.check_member_access(
                        circle_id=str(family_id),
                        user_id=current_user_id,
                        raise_error=False
                    )
                    if is_member:
                        return True
            except Exception:
                pass
        
        return False
