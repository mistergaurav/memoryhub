"""User repository for user lookup and query operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from ..base_repository import BaseRepository


class UserRepository(BaseRepository):
    """
    Repository for user operations.
    Provides user lookup and query methods.
    """
    
    def __init__(self):
        super().__init__("users")
    
    async def find_by_email(
        self,
        email: str,
        raise_404: bool = False
    ) -> Optional[Dict[str, Any]]:
        """
        Find user by email address.
        
        Args:
            email: Email address (case-insensitive)
            raise_404: Whether to raise 404 if not found
            
        Returns:
            User document if found
        """
        return await self.find_one(
            {"email": email.lower()},
            raise_404=raise_404,
            error_message="User not found"
        )
    
    async def get_user_name(
        self,
        user_id: str
    ) -> Optional[str]:
        """
        Get user's full name by ID.
        
        Args:
            user_id: String representation of user ID
            
        Returns:
            User's full name if found, None otherwise
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        user = await self.find_one({"_id": user_oid}, raise_404=False)
        return user.get("full_name") if user else None
    
    async def get_user_names(
        self,
        user_ids: List[str]
    ) -> Dict[str, str]:
        """
        Get multiple users' names by IDs.
        
        Args:
            user_ids: List of user ID strings
            
        Returns:
            Dictionary mapping user_id to full_name
        """
        user_oids = [self.validate_object_id(uid, "user_id") for uid in user_ids]
        users = await self.find_many(
            {"_id": {"$in": user_oids}},
            limit=len(user_oids)
        )
        return {str(user["_id"]): user.get("full_name", "") for user in users}
    
    async def search_users(
        self,
        query: str,
        exclude_user_id: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Search for users by username, email, or full name.
        
        Args:
            query: Search query
            exclude_user_id: Optional user ID to exclude from results
            limit: Maximum number of results
            
        Returns:
            List of matching users
        """
        search_regex = {"$regex": query, "$options": "i"}
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"username": search_regex},
                {"email": search_regex},
                {"full_name": search_regex}
            ]
        }
        
        if exclude_user_id:
            exclude_oid = self.validate_object_id(exclude_user_id, "exclude_user_id")
            filter_dict["_id"] = {"$ne": exclude_oid}
        
        return await self.find_many(filter_dict, limit=limit)
