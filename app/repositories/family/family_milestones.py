"""Repository for family milestones."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class FamilyMilestonesRepository(BaseRepository):
    """
    Repository for family milestones with photo management and like functionality.
    Provides queries for milestone tracking and social engagement.
    """
    
    def __init__(self):
        super().__init__("family_milestones")
    
    async def find_user_milestones(
        self,
        user_id: str,
        person_id: Optional[str] = None,
        milestone_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find milestones for a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            person_id: Optional filter by person ID
            milestone_type: Optional filter by milestone type
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of milestones
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"family_circle_ids": {"$exists": True}}
            ]
        }
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            filter_dict["person_id"] = person_oid
        
        if milestone_type:
            filter_dict["milestone_type"] = milestone_type
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="milestone_date",
            sort_order=-1
        )
    
    async def count_user_milestones(
        self,
        user_id: str,
        person_id: Optional[str] = None,
        milestone_type: Optional[str] = None
    ) -> int:
        """Count milestones matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"family_circle_ids": {"$exists": True}}
            ]
        }
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            filter_dict["person_id"] = person_oid
        
        if milestone_type:
            filter_dict["milestone_type"] = milestone_type
        
        return await self.count(filter_dict)
    
    async def check_milestone_ownership(
        self,
        milestone_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a milestone.
        
        Args:
            milestone_id: String representation of milestone ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        milestone = await self.find_one(
            {"_id": milestone_oid},
            raise_404=True,
            error_message="Milestone not found"
        )
        assert milestone is not None
        
        is_owner = milestone.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the milestone creator can perform this action"
            )
        
        return is_owner
    
    async def toggle_like(
        self,
        milestone_id: str,
        user_id: str,
        add_like: bool = True
    ) -> bool:
        """
        Toggle like on a milestone.
        
        Args:
            milestone_id: String representation of milestone ID
            user_id: String representation of user ID
            add_like: True to add like, False to remove
            
        Returns:
            True if operation successful
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_like else "$pull"
        
        result = await self.collection.update_one(
            {"_id": milestone_oid},
            {operation: {"likes": user_oid}}
        )
        
        return result.modified_count > 0

