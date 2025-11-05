"""Repository for genealogyrelationship operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class GenealogyRelationshipRepository(BaseRepository):
    """Repository for genealogy relationships."""
    
    def __init__(self):
        super().__init__("genealogy_relationships")
    
    async def find_by_tree(
        self,
        tree_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Find all relationships in a family tree."""
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        return await self.find_many(
            {"family_id": tree_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_existing_relationship(
        self,
        person1_id: ObjectId,
        person2_id: ObjectId,
        relationship_type: str,
        family_id: ObjectId
    ) -> Optional[Dict[str, Any]]:
        """Check if a specific relationship already exists between two persons.
        
        This checks for an exact match of the relationship in the specified direction.
        """
        return await self.find_one({
            "family_id": family_id,
            "person1_id": person1_id,
            "person2_id": person2_id,
            "relationship_type": relationship_type
        }, raise_404=False)
    
    async def find_any_relationship_between(
        self,
        person1_id: ObjectId,
        person2_id: ObjectId,
        family_id: ObjectId
    ) -> List[Dict[str, Any]]:
        """Find any existing relationships between two persons (in either direction)."""
        return await self.find_many({
            "family_id": family_id,
            "$or": [
                {"person1_id": person1_id, "person2_id": person2_id},
                {"person1_id": person2_id, "person2_id": person1_id}
            ]
        })

