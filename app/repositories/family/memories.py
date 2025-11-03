"""Repository for memories."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from ..base_repository import BaseRepository


class MemoryRepository(BaseRepository):
    """
    Repository for memories.
    Manages memory queries and associations with genealogy persons.
    """
    
    def __init__(self):
        super().__init__("memories")
    
    async def find_by_genealogy_person(
        self,
        person_id: str,
        skip: int = 0,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Find all memories associated with a genealogy person.
        
        Args:
            person_id: String representation of person ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of memories
        """
        return await self.find_many(
            {"genealogy_person_ids": person_id},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )

