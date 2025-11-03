"""Repository for familyrelationship operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class FamilyRelationshipRepository(BaseRepository):
    """Repository for family relationships."""
    
    def __init__(self):
        super().__init__("family_relationships")
    
    async def find_by_user(
        self,
        user_id: str,
        relation_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all relationships for a user.
        
        Args:
            user_id: String representation of user ID
            relation_type: Optional filter by relation type
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of relationships
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {"user_id": user_oid}
        if relation_type:
            filter_dict["relation_type"] = relation_type
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def check_relationship_exists(
        self,
        user_id: str,
        related_user_id: str
    ) -> bool:
        """
        Check if a relationship already exists.
        
        Args:
            user_id: String representation of user ID
            related_user_id: String representation of related user ID
            
        Returns:
            True if relationship exists
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        related_oid = self.validate_object_id(related_user_id, "related_user_id")
        
        return await self.exists({
            "user_id": user_oid,
            "related_user_id": related_oid
        })
    
    async def count_by_user(
        self,
        user_id: str,
        relation_type: Optional[str] = None
    ) -> int:
        """
        Count all relationships for a user.
        
        Args:
            user_id: String representation of user ID
            relation_type: Optional filter by relation type
            
        Returns:
            Count of relationships
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {"user_id": user_oid}
        if relation_type:
            filter_dict["relation_type"] = relation_type
        
        return await self.count(filter_dict)

