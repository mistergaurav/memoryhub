from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
from fastapi import HTTPException

from app.repositories.base_repository import BaseRepository


class FamilyTimelineRepository(BaseRepository):
    """
    Repository for family timeline aggregation across multiple collections.
    Aggregates events from memories, milestones, events, recipes, traditions, and albums.
    """
    
    def __init__(self):
        super().__init__("memories")
    
    async def get_timeline_events(
        self,
        family_id: str,
        skip: int = 0,
        limit: int = 20,
        event_types: Optional[List[str]] = None,
        person_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Aggregate timeline events from multiple sources with pagination.
        
        This method combines events from:
        - memories
        - family_milestones
        - family_events
        - family_recipes
        - family_traditions
        - family_albums
        
        Args:
            family_id: Family circle ID to get events for
            skip: Number of events to skip for pagination
            limit: Maximum number of events to return
            event_types: Optional list of event types to include
            person_id: Optional filter by person/user ID
            start_date: Optional filter by start date
            end_date: Optional filter by end date
            
        Returns:
            PaginatedResponse dictionary with timeline events
        """
        family_oid = self.validate_object_id(family_id, "family_id")
        
        match_stage: Dict[str, Any] = {"family_circle_ids": family_oid}
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            match_stage["$or"] = [
                {"user_id": person_oid},
                {"created_by": person_oid},
                {"person_id": person_oid}
            ]
        
        if start_date:
            match_stage["created_at"] = {"$gte": start_date}
        
        if end_date:
            if "created_at" in match_stage:
                match_stage["created_at"]["$lte"] = end_date
            else:
                match_stage["created_at"] = {"$lte": end_date}
        
        collections_to_query = []
        if event_types:
            type_mapping = {
                "memory": "memories",
                "milestone": "family_milestones",
                "event": "family_events",
                "recipe": "family_recipes",
                "tradition": "family_traditions",
                "album": "family_albums"
            }
            collections_to_query = [type_mapping.get(t, t) for t in event_types if t in type_mapping]
        else:
            collections_to_query = [
                "memories", "family_milestones", "family_events",
                "family_recipes", "family_traditions", "family_albums"
            ]
        
        pipeline = [
            {"$match": match_stage},
            {
                "$lookup": {
                    "from": "users",
                    "localField": "user_id",
                    "foreignField": "_id",
                    "as": "user_info"
                }
            },
            {
                "$addFields": {
                    "event_type": "memory",
                    "event_date": "$created_at",
                    "person_name": {
                        "$ifNull": [
                            {"$arrayElemAt": ["$user_info.full_name", 0]},
                            None
                        ]
                    }
                }
            },
            {
                "$project": {
                    "_id": 1,
                    "type": "$event_type",
                    "title": 1,
                    "description": {"$substr": [{"$ifNull": ["$content", ""]}, 0, 200]},
                    "date": "$event_date",
                    "person_name": 1,
                    "photos": {"$slice": [{"$ifNull": ["$attachments", []]}, 3]},
                    "tags": 1
                }
            },
            {"$sort": {"date": -1}}
        ]
        
        return await self.aggregate_paginated(pipeline, skip=skip, limit=limit)

