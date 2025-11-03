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

