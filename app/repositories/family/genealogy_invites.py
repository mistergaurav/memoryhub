"""Repository for genealogy invite links."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from ..base_repository import BaseRepository


class GenealogyInviteLinksRepository(BaseRepository):
    """
    Repository for genealogy invitation links.
    Manages invite creation, validation, and redemption.
    """
    
    def __init__(self):
        super().__init__("genealogy_invite_links")
    
    async def find_by_token(
        self,
        token: str,
        raise_404: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Find invitation by token.
        
        Args:
            token: Invitation token
            raise_404: Whether to raise 404 if not found
            
        Returns:
            Invitation document if found
        """
        return await self.find_one(
            {"token": token},
            raise_404=raise_404,
            error_message="Invitation not found"
        )
    
    async def find_active_by_person(
        self,
        person_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Find active (pending, not expired) invitation for a person.
        
        Args:
            person_id: String representation of person ID
            
        Returns:
            Active invitation if exists
        """
        person_oid = self.validate_object_id(person_id, "person_id")
        return await self.find_one(
            {
                "person_id": person_oid,
                "status": "pending",
                "expires_at": {"$gt": datetime.utcnow()}
            },
            raise_404=False
        )
    
    async def find_by_family(
        self,
        family_id: str,
        status_filter: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all invitations for a family tree.
        
        Args:
            family_id: String representation of family ID
            status_filter: Optional filter by status
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of invitations
        """
        family_oid = self.validate_object_id(family_id, "family_id")
        
        filter_dict: Dict[str, Any] = {"family_id": family_oid}
        if status_filter:
            filter_dict["status"] = status_filter
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )

