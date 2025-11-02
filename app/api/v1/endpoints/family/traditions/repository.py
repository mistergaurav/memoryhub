from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
from fastapi import HTTPException

from app.repositories.base_repository import BaseRepository


class FamilyTraditionsRepository(BaseRepository):
    """
    Repository for family traditions with follower management.
    Provides queries for tradition tracking and social engagement.
    """
    
    def __init__(self):
        super().__init__("family_traditions")
    
    async def find_user_traditions(
        self,
        user_id: str,
        category: Optional[str] = None,
        frequency: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find traditions accessible to a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            category: Optional filter by category
            frequency: Optional filter by frequency
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of traditions
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if frequency:
            filter_dict["frequency"] = frequency
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def count_user_traditions(
        self,
        user_id: str,
        category: Optional[str] = None,
        frequency: Optional[str] = None
    ) -> int:
        """Count traditions matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if frequency:
            filter_dict["frequency"] = frequency
        
        return await self.count(filter_dict)
    
    async def check_tradition_ownership(
        self,
        tradition_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a tradition.
        
        Args:
            tradition_id: String representation of tradition ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        tradition_oid = self.validate_object_id(tradition_id, "tradition_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        tradition = await self.find_one(
            {"_id": tradition_oid},
            raise_404=True,
            error_message="Tradition not found"
        )
        assert tradition is not None
        
        is_owner = tradition.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the tradition creator can perform this action"
            )
        
        return is_owner
    
    async def toggle_follow(
        self,
        tradition_id: str,
        user_id: str,
        add_follow: bool = True
    ) -> bool:
        """
        Toggle follow on a tradition.
        
        Args:
            tradition_id: String representation of tradition ID
            user_id: String representation of user ID
            add_follow: True to follow, False to unfollow
            
        Returns:
            True if operation successful
        """
        tradition_oid = self.validate_object_id(tradition_id, "tradition_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_follow else "$pull"
        
        result = await self.collection.update_one(
            {"_id": tradition_oid},
            {operation: {"followers": user_oid}}
        )
        
        return result.modified_count > 0

