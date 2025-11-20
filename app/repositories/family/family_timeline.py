"""Repository for family timeline aggregation."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from ..base_repository import BaseRepository


class FamilyTimelineRepository(BaseRepository):
    """
    Repository for family timeline aggregation across multiple collections.
    Aggregates events from memories, milestones, events, recipes, traditions, and albums.
    """
    
    def __init__(self):
        super().__init__("family_milestones")
    
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
        - family_milestones
        - family_events
        - memories
        
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
        
        # Base match for all collections
        base_match = {}
        if start_date:
            base_match["created_at"] = {"$gte": start_date}
        if end_date:
            if "created_at" in base_match:
                base_match["created_at"]["$lte"] = end_date
            else:
                base_match["created_at"] = {"$lte": end_date}
                
        # Collection-specific match stages
        milestone_match = {**base_match, "family_circle_ids": family_oid}
        event_match = {**base_match, "family_circle_ids": family_oid}
        # Memories usually use 'circle_ids' or 'family_circle_ids' depending on implementation.
        # Assuming 'circle_ids' for generic memories or 'family_circle_ids' if specific.
        # Let's assume 'circle_ids' for now as per standard memory model, but check if it needs to match family_oid.
        # If memories are shared with the family circle, they should have the family_oid in circle_ids.
        memory_match = {**base_match, "circle_ids": family_oid} 
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            milestone_match["$or"] = [{"person_id": person_oid}, {"genealogy_person_id": person_oid}]
            event_match["$or"] = [{"attendee_ids": person_oid}, {"genealogy_person_id": person_oid}]
            memory_match["user_id"] = person_oid

        # Main pipeline starting with family_milestones
        pipeline = [
            {"$match": milestone_match},
            {"$addFields": {
                "event_type": "milestone",
                "event_date": "$milestone_date",
                "source_collection": "family_milestones"
            }},
            {"$project": {
                "_id": 1,
                "event_type": 1,
                "title": 1,
                "description": 1,
                "event_date": 1,
                "photos": 1,
                "created_by": 1,
                "created_at": 1,
                "updated_at": 1,
                "genealogy_person_id": 1,
                "person_id": 1
            }}
        ]

        # Union with family_events
        pipeline.append({
            "$unionWith": {
                "coll": "family_events",
                "pipeline": [
                    {"$match": event_match},
                    {"$addFields": {
                        "event_type": "calendar_event",
                        "photos": [], # Events might not have photos initially
                        "source_collection": "family_events"
                    }},
                    {"$project": {
                        "_id": 1,
                        "event_type": 1,
                        "title": 1,
                        "description": 1,
                        "event_date": 1,
                        "photos": 1,
                        "created_by": 1,
                        "created_at": 1,
                        "updated_at": 1,
                        "genealogy_person_id": 1,
                        "location": 1
                    }}
                ]
            }
        })

        # Union with memories
        pipeline.append({
            "$unionWith": {
                "coll": "memories",
                "pipeline": [
                    {"$match": memory_match},
                    {"$addFields": {
                        "event_type": "memory",
                        "event_date": "$created_at",
                        "source_collection": "memories",
                        "photos": "$media" # Assuming 'media' field in memories
                    }},
                    {"$project": {
                        "_id": 1,
                        "event_type": 1,
                        "title": 1,
                        "description": "$content", # Map content to description
                        "event_date": 1,
                        "photos": 1,
                        "created_by": "$user_id", # Map user_id to created_by
                        "created_at": 1,
                        "updated_at": 1
                    }}
                ]
            }
        })

        # Union with memories (if needed and schema matches)
        # For now, focusing on Milestones and Events as primary timeline items
        
        # Sort and Paginate
        pipeline.extend([
            {"$sort": {"event_date": -1}},
            {"$facet": {
                "metadata": [{"$count": "total"}],
                "data": [{"$skip": skip}, {"$limit": limit}]
            }},
            {"$project": {
                "total": {"$arrayElemAt": ["$metadata.total", 0]},
                "items": "$data"
            }}
        ])
        
        result = await self.collection.aggregate(pipeline).to_list(length=1)
        
        if not result:
            return {"items": [], "total": 0, "page": 1, "page_size": limit}
            
        data = result[0]
        total = data.get("total", 0)
        items = data.get("items", [])
        
        # Enrich items with user info if needed (can be done here or in a separate loop)
        # For performance, we might want to do a $lookup in the pipeline, but let's keep it simple first
        
        return {
            "items": items,
            "total": total,
            "page": (skip // limit) + 1 if limit > 0 else 1,
            "page_size": limit
        }

