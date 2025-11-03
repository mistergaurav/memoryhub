"""Repository for familyinvitation operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class FamilyInvitationRepository(BaseRepository):
    """Repository for family invitations."""
    
    def __init__(self):
        super().__init__("family_invitations")
    
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
            Invitation document
        """
        return await self.find_one(
            {"token": token},
            raise_404=raise_404,
            error_message="Invitation not found"
        )
    
    async def find_by_inviter(
        self,
        inviter_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all invitations sent by a user.
        
        Args:
            inviter_id: String representation of inviter user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of invitations
        """
        inviter_oid = self.validate_object_id(inviter_id, "inviter_id")
        return await self.find_many(
            {"inviter_id": inviter_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_by_invitee(
        self,
        invitee_email: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all invitations for an email address.
        
        Args:
            invitee_email: Email address of invitee
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of invitations
        """
        return await self.find_many(
            {"invitee_email": invitee_email.lower()},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )

