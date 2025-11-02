from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
from fastapi import HTTPException

from app.repositories.base_repository import BaseRepository


class LegacyLettersRepository(BaseRepository):
    """
    Repository for legacy letters with delivery and read tracking.
    Provides queries for sent and received letters with privacy controls.
    """
    
    def __init__(self):
        super().__init__("legacy_letters")
    
    async def find_sent_letters(
        self,
        author_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all letters sent by a user.
        
        Args:
            author_id: String representation of author user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of sent letters
        """
        author_oid = self.validate_object_id(author_id, "author_id")
        
        return await self.find_many(
            {"author_id": author_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def count_sent_letters(
        self,
        author_id: str
    ) -> int:
        """Count letters sent by a user."""
        author_oid = self.validate_object_id(author_id, "author_id")
        
        return await self.count({"author_id": author_oid})
    
    async def find_received_letters(
        self,
        recipient_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all delivered letters received by a user.
        
        Args:
            recipient_id: String representation of recipient user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of received letters
        """
        recipient_oid = self.validate_object_id(recipient_id, "recipient_id")
        
        return await self.find_many(
            {
                "recipient_ids": recipient_oid,
                "status": {"$in": ["delivered", "read"]}
            },
            skip=skip,
            limit=limit,
            sort_by="delivered_at",
            sort_order=-1
        )
    
    async def count_received_letters(
        self,
        recipient_id: str
    ) -> int:
        """Count delivered letters received by a user."""
        recipient_oid = self.validate_object_id(recipient_id, "recipient_id")
        
        return await self.count({
            "recipient_ids": recipient_oid,
            "status": {"$in": ["delivered", "read"]}
        })
    
    async def check_letter_ownership(
        self,
        letter_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user is the author of a letter.
        
        Args:
            letter_id: String representation of letter ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not author
            
        Returns:
            True if user is author
            
        Raises:
            HTTPException: If user is not author and raise_error=True
        """
        letter_oid = self.validate_object_id(letter_id, "letter_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        letter = await self.find_one(
            {"_id": letter_oid},
            raise_404=True,
            error_message="Letter not found"
        )
        assert letter is not None
        
        is_author = letter.get("author_id") == user_oid
        
        if not is_author and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the letter author can perform this action"
            )
        
        return is_author
    
    async def mark_as_read(
        self,
        letter_id: str,
        user_id: str
    ) -> bool:
        """
        Mark a letter as read by a recipient.
        
        Args:
            letter_id: String representation of letter ID
            user_id: String representation of user ID
            
        Returns:
            True if operation successful
        """
        letter_oid = self.validate_object_id(letter_id, "letter_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        result = await self.collection.update_one(
            {"_id": letter_oid},
            {
                "$addToSet": {"read_by": user_oid},
                "$set": {"status": "read"}
            }
        )
        
        return result.modified_count > 0
    
    async def check_recipient_access(
        self,
        letter_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user is a recipient of a letter.
        
        Args:
            letter_id: String representation of letter ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not recipient
            
        Returns:
            True if user is recipient
            
        Raises:
            HTTPException: If user is not recipient and raise_error=True
        """
        letter_oid = self.validate_object_id(letter_id, "letter_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        letter = await self.find_one(
            {"_id": letter_oid},
            raise_404=True,
            error_message="Letter not found"
        )
        assert letter is not None
        
        is_recipient = user_oid in letter.get("recipient_ids", [])
        
        if not is_recipient and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You are not a recipient of this letter"
            )
        
        return is_recipient

