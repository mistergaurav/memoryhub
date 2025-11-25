"""Repository for genealogyperson operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class GenealogyPersonRepository(BaseRepository):
    """Repository for genealogy persons."""
    
    def __init__(self):
        super().__init__("genealogy_persons")
    
    async def find_by_tree(
        self,
        tree_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Find all persons in a family tree."""
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        return await self.find_many(
            {"family_id": tree_oid},
            skip=skip,
            limit=limit,
            sort_by="last_name",
            sort_order=1
        )

    async def search_persons(
        self,
        query: str,
        tree_id: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Search for persons by name."""
        filter_dict = {
            "$or": [
                {"first_name": {"$regex": query, "$options": "i"}},
                {"last_name": {"$regex": query, "$options": "i"}},
                {"maiden_name": {"$regex": query, "$options": "i"}}
            ]
        }
        
        if tree_id:
            tree_oid = self.validate_object_id(tree_id, "tree_id")
            filter_dict["family_id"] = tree_oid
            
        return await self.find_many(
            filter_dict,
            limit=limit,
            sort_by="first_name",
            sort_order=1
        )

