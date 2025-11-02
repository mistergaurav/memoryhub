from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
from fastapi import HTTPException

from app.repositories.base_repository import BaseRepository


class FamilyCalendarRepository(BaseRepository):
    """
    Repository for family calendar events with recurrence and conflict detection.
    Provides timezone-aware queries and attendee management.
    """
    
    def __init__(self):
        super().__init__("family_events")
    
    async def find_user_events(
        self,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Find all events for a user (created or attending).
        
        Args:
            user_id: String representation of user ID
            start_date: Optional filter by start date
            end_date: Optional filter by end date
            event_type: Optional filter by event type
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of events
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ]
        }
        
        if start_date:
            filter_dict["event_date"] = {"$gte": start_date}
        if end_date:
            if "event_date" in filter_dict:
                filter_dict["event_date"]["$lte"] = end_date
            else:
                filter_dict["event_date"] = {"$lte": end_date}
        if event_type:
            filter_dict["event_type"] = event_type
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="event_date",
            sort_order=1
        )
    
    async def count_user_events(
        self,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_type: Optional[str] = None
    ) -> int:
        """Count events matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ]
        }
        
        if start_date:
            filter_dict["event_date"] = {"$gte": start_date}
        if end_date:
            if "event_date" in filter_dict:
                filter_dict["event_date"]["$lte"] = end_date
            else:
                filter_dict["event_date"] = {"$lte": end_date}
        if event_type:
            filter_dict["event_type"] = event_type
        
        return await self.count(filter_dict)
    
    async def check_event_ownership(
        self,
        event_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns an event.
        
        Args:
            event_id: String representation of event ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        event_oid = self.validate_object_id(event_id, "event_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        event = await self.find_one(
            {"_id": event_oid},
            raise_404=True,
            error_message="Event not found"
        )
        assert event is not None
        
        is_owner = event.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the event creator can perform this action"
            )
        
        return is_owner
    
    async def detect_conflicts(
        self,
        user_id: str,
        event_date: datetime,
        end_date: Optional[datetime] = None,
        exclude_event_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Detect scheduling conflicts for a user.
        
        Args:
            user_id: String representation of user ID
            event_date: Start date/time of the event
            end_date: Optional end date/time
            exclude_event_id: Optional event ID to exclude from conflict check
            
        Returns:
            List of conflicting events
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        event_end = end_date or event_date
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ],
            "$or": [
                {
                    "event_date": {"$lte": event_date},
                    "end_date": {"$gte": event_date}
                },
                {
                    "event_date": {"$lte": event_end},
                    "end_date": {"$gte": event_end}
                },
                {
                    "event_date": {"$gte": event_date},
                    "event_date": {"$lte": event_end}
                }
            ]
        }
        
        if exclude_event_id:
            exclude_oid = self.validate_object_id(exclude_event_id, "exclude_event_id")
            filter_dict["_id"] = {"$ne": exclude_oid}
        
        return await self.find_many(filter_dict, limit=10)
    
    async def get_upcoming_birthdays(
        self,
        user_id: str,
        days_ahead: int = 30
    ) -> List[Dict[str, Any]]:
        """
        Get upcoming birthdays for a user.
        
        Args:
            user_id: String representation of user ID
            days_ahead: Number of days to look ahead
            
        Returns:
            List of birthday events
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        end_date = datetime.utcnow() + timedelta(days=days_ahead)
        
        return await self.find_many(
            {
                "event_type": "birthday",
                "event_date": {"$lte": end_date},
                "$or": [
                    {"created_by": user_oid},
                    {"attendee_ids": user_oid}
                ]
            },
            sort_by="event_date",
            sort_order=1,
            limit=50
        )
