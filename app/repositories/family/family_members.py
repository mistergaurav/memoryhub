"""Repository for familymembers operations."""
from typing import List, Dict, Any, Optional, Union
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class FamilyMembersRepository(BaseRepository):
    """
    Repository for family members.
    Manages family member records for health tracking and other family features.
    """
    
    def __init__(self):
        super().__init__("family_members")
    
    async def find_by_family(
        self,
        family_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Find all members in a family.
        
        Args:
            family_id: String representation of family ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of family members
        """
        family_oid = self.validate_object_id(family_id, "family_id")
        return await self.find_many(
            {"family_id": family_oid},
            skip=skip,
            limit=limit,
            sort_by="name",
            sort_order=1
        )
    
    async def get_member_name(
        self,
        member_id: str
    ) -> Optional[str]:
        """
        Get family member's name by ID.
        
        Args:
            member_id: String representation of member ID
            
        Returns:
            Member's name if found, None otherwise
        """
        member_oid = self.validate_object_id(member_id, "member_id")
        member = await self.find_one({"_id": member_oid}, raise_404=False)
        return member.get("name") if member else None
    
    async def search_by_name(
        self,
        family_id: Union[str, ObjectId],
        query: str,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Search family members by name (case-insensitive).
        
        Args:
            family_id: String or ObjectId representation of family ID
            query: Search query string
            limit: Maximum number of results (default: 10)
            
        Returns:
            List of family members matching the query
        """
        if isinstance(family_id, str):
            family_oid = self.validate_object_id(family_id, "family_id")
        else:
            family_oid = family_id
        
        search_regex = {"$regex": query, "$options": "i"}
        filter_dict = {
            "family_id": family_oid,
            "name": search_regex
        }
        
        results = await self.find_many(
            filter_dict,
            limit=limit,
            sort_by="name",
            sort_order=1
        )
        
        exact_matches = [r for r in results if r.get("name", "").lower() == query.lower()]
        partial_matches = [r for r in results if r.get("name", "").lower() != query.lower()]
        
        return exact_matches + partial_matches

