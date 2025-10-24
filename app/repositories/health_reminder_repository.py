from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
from fastapi import HTTPException
from .base_repository import BaseRepository


class HealthReminderRepository(BaseRepository):
    """
    Repository for health record reminders with scheduling and notification support.
    Handles reminder CRUD operations, due date queries, and status management.
    """
    
    def __init__(self):
        super().__init__("health_record_reminders")
    
    async def find_by_record(
        self,
        record_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all reminders for a specific health record.
        
        Args:
            record_id: String representation of health record ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of reminders
        """
        record_oid = self.validate_object_id(record_id, "record_id")
        return await self.find_many(
            {"record_id": record_oid},
            skip=skip,
            limit=limit,
            sort_by="due_at",
            sort_order=1
        )
    
    async def find_upcoming_for_user(
        self,
        user_id: str,
        days_ahead: int = 7,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find upcoming reminders for a user within specified days.
        
        Args:
            user_id: String representation of assigned user ID
            days_ahead: Number of days to look ahead
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of upcoming reminders
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        now = datetime.utcnow()
        future_date = now + timedelta(days=days_ahead)
        
        return await self.find_many(
            {
                "assigned_user_id": user_oid,
                "status": {"$in": ["pending", "snoozed"]},
                "due_at": {
                    "$gte": now,
                    "$lte": future_date
                }
            },
            skip=skip,
            limit=limit,
            sort_by="due_at",
            sort_order=1
        )
    
    async def find_overdue_for_user(
        self,
        user_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find overdue reminders for a user.
        
        Args:
            user_id: String representation of assigned user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of overdue reminders
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        now = datetime.utcnow()
        
        return await self.find_many(
            {
                "assigned_user_id": user_oid,
                "status": {"$in": ["pending", "snoozed"]},
                "due_at": {"$lt": now}
            },
            skip=skip,
            limit=limit,
            sort_by="due_at",
            sort_order=-1
        )
    
    async def find_due_now(
        self,
        grace_minutes: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Find reminders that are due right now (within grace period).
        Used by reminder scheduler/worker for sending notifications.
        
        Args:
            grace_minutes: Grace period in minutes for "due now"
            
        Returns:
            List of reminders due for notification
        """
        now = datetime.utcnow()
        grace_period = now + timedelta(minutes=grace_minutes)
        
        return await self.find_many(
            {
                "status": "pending",
                "due_at": {
                    "$gte": now,
                    "$lte": grace_period
                }
            },
            limit=1000,
            sort_by="due_at",
            sort_order=1
        )
    
    async def mark_as_sent(
        self,
        reminder_id: str
    ) -> Dict[str, Any]:
        """
        Mark a reminder as sent after notification is delivered.
        
        Args:
            reminder_id: String representation of reminder ID
            
        Returns:
            Updated reminder document
        """
        result = await self.update_by_id(
            reminder_id,
            {
                "status": "sent",
                "sent_at": datetime.utcnow()
            }
        )
        if not result:
            raise HTTPException(status_code=404, detail="Reminder not found")
        return result
    
    async def mark_as_completed(
        self,
        reminder_id: str
    ) -> Dict[str, Any]:
        """
        Mark a reminder as completed by user.
        
        Args:
            reminder_id: String representation of reminder ID
            
        Returns:
            Updated reminder document
        """
        result = await self.update_by_id(
            reminder_id,
            {
                "status": "completed",
                "completed_at": datetime.utcnow()
            }
        )
        if not result:
            raise HTTPException(status_code=404, detail="Reminder not found")
        return result
    
    async def snooze_reminder(
        self,
        reminder_id: str,
        snooze_until: datetime
    ) -> Dict[str, Any]:
        """
        Snooze a reminder to a later time.
        
        Args:
            reminder_id: String representation of reminder ID
            snooze_until: New due date/time for the reminder
            
        Returns:
            Updated reminder document
        """
        result = await self.update_by_id(
            reminder_id,
            {
                "status": "snoozed",
                "due_at": snooze_until,
                "snoozed_at": datetime.utcnow()
            }
        )
        if not result:
            raise HTTPException(status_code=404, detail="Reminder not found")
        return result
    
    async def get_reminder_statistics(
        self,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Get reminder statistics for a user.
        
        Args:
            user_id: String representation of assigned user ID
            
        Returns:
            Dictionary with reminder statistics
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        now = datetime.utcnow()
        
        pipeline = [
            {"$match": {"assigned_user_id": user_oid}},
            {
                "$facet": {
                    "total": [{"$count": "count"}],
                    "by_status": [
                        {"$group": {"_id": "$status", "count": {"$sum": 1}}}
                    ],
                    "by_type": [
                        {"$group": {"_id": "$reminder_type", "count": {"$sum": 1}}}
                    ],
                    "upcoming": [
                        {
                            "$match": {
                                "status": {"$in": ["pending", "snoozed"]},
                                "due_at": {"$gte": now}
                            }
                        },
                        {"$count": "count"}
                    ],
                    "overdue": [
                        {
                            "$match": {
                                "status": {"$in": ["pending", "snoozed"]},
                                "due_at": {"$lt": now}
                            }
                        },
                        {"$count": "count"}
                    ]
                }
            }
        ]
        
        results = await self.aggregate(pipeline)
        if not results:
            return {
                "total": 0,
                "by_status": {},
                "by_type": {},
                "upcoming": 0,
                "overdue": 0
            }
        
        result = results[0]
        
        return {
            "total": result["total"][0]["count"] if result["total"] else 0,
            "by_status": {item["_id"]: item["count"] for item in result["by_status"]},
            "by_type": {item["_id"]: item["count"] for item in result["by_type"]},
            "upcoming": result["upcoming"][0]["count"] if result["upcoming"] else 0,
            "overdue": result["overdue"][0]["count"] if result["overdue"] else 0
        }
    
    async def check_user_access(
        self,
        reminder_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user has access to a reminder (creator or assigned user).
        
        Args:
            reminder_id: String representation of reminder ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if no access
            
        Returns:
            True if user has access
            
        Raises:
            HTTPException: If user has no access and raise_error=True
        """
        reminder = await self.find_by_id(
            reminder_id,
            raise_404=True,
            error_message="Reminder not found"
        )
        assert reminder is not None
        
        user_oid = self.validate_object_id(user_id, "user_id")
        
        is_creator = reminder.get("created_by") == user_oid
        is_assigned = reminder.get("assigned_user_id") == user_oid
        has_access = is_creator or is_assigned
        
        if not has_access and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You do not have access to this reminder"
            )
        
        return has_access
