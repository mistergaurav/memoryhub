"""Repository for family operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class FamilyRepository(BaseRepository):
    """
    Repository for Family Hub operations.
    Provides family-specific queries and authorization helpers.
    """
    
    def __init__(self):
        super().__init__("family_circles")
    
    async def find_by_owner(
        self,
        owner_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all family circles owned by a user.
        
        Args:
            owner_id: String representation of user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of family circles
        """
        owner_oid = self.validate_object_id(owner_id, "owner_id")
        return await self.find_many(
            {"owner_id": owner_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_by_member(
        self,
        member_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all family circles where user is a member.
        
        Args:
            member_id: String representation of user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of family circles
        """
        member_oid = self.validate_object_id(member_id, "member_id")
        return await self.find_many(
            {"member_ids": member_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def count_by_member(
        self,
        member_id: str
    ) -> int:
        """
        Count all family circles where user is a member.
        
        Args:
            member_id: String representation of user ID
            
        Returns:
            Count of family circles
        """
        member_oid = self.validate_object_id(member_id, "member_id")
        return await self.count({"member_ids": member_oid})
    
    async def check_owner(
        self,
        circle_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user is the owner of a family circle.
        
        Args:
            circle_id: String representation of circle ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        circle = await self.find_one(
            {"_id": circle_oid},
            raise_404=True,
            error_message="Family circle not found"
        )
        assert circle is not None
        
        is_owner = circle.get("owner_id") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the circle owner can perform this action"
            )
        
        return is_owner
    
    async def check_member_access(
        self,
        circle_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user has access to a family circle (owner or member).
        
        Args:
            circle_id: String representation of circle ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if no access
            
        Returns:
            True if user has access
            
        Raises:
            HTTPException: If user has no access and raise_error=True
        """
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        circle = await self.find_one(
            {"_id": circle_oid},
            raise_404=True,
            error_message="Family circle not found"
        )
        assert circle is not None
        
        is_owner = circle.get("owner_id") == user_oid
        is_member = user_oid in circle.get("member_ids", [])
        has_access = is_owner or is_member
        
        if not has_access and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You do not have access to this family circle"
            )
        
        return has_access
    
    async def add_member(
        self,
        circle_id: str,
        member_id: str,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Add a member to a family circle (owner only).
        
        Args:
            circle_id: String representation of circle ID
            member_id: String representation of member to add
            user_id: String representation of requesting user ID
            
        Returns:
            Updated circle document
            
        Raises:
            HTTPException: If user is not owner or member already exists
        """
        await self.check_owner(circle_id, user_id, raise_error=True)
        
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        member_oid = self.validate_object_id(member_id, "member_id")
        
        circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert circle is not None
        
        if member_oid in circle.get("member_ids", []):
            raise HTTPException(
                status_code=400,
                detail="User is already a member of this circle"
            )
        
        result = await self.collection.update_one(
            {"_id": circle_oid},
            {
                "$push": {"member_ids": member_oid},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert updated_circle is not None
        return updated_circle
    
    async def remove_member(
        self,
        circle_id: str,
        member_id: str,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Remove a member from a family circle (owner only).
        
        Args:
            circle_id: String representation of circle ID
            member_id: String representation of member to remove
            user_id: String representation of requesting user ID
            
        Returns:
            Updated circle document
            
        Raises:
            HTTPException: If user is not owner or trying to remove owner
        """
        await self.check_owner(circle_id, user_id, raise_error=True)
        
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        member_oid = self.validate_object_id(member_id, "member_id")
        
        circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert circle is not None
        
        if circle.get("owner_id") == member_oid:
            raise HTTPException(
                status_code=400,
                detail="Cannot remove the circle owner"
            )
        
        result = await self.collection.update_one(
            {"_id": circle_oid},
            {
                "$pull": {"member_ids": member_oid},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert updated_circle is not None
        return updated_circle
    
    async def search_circle_members(
        self,
        user_id: str,
        query: str,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Search members across all circles where user is owner or member.
        
        Args:
            user_id: String representation of user ID
            query: Search query string
            limit: Maximum number of results (default: 10)
            
        Returns:
            List of users matching the query from user's circles
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        circles = await self.find_many(
            {
                "$or": [
                    {"owner_id": user_oid},
                    {"member_ids": user_oid}
                ]
            },
            limit=100
        )
        
        if not circles:
            return []
        
        member_ids_set = set()
        for circle in circles:
            if circle.get("owner_id"):
                member_ids_set.add(circle["owner_id"])
            
            if circle.get("member_ids"):
                member_ids_set.update(circle["member_ids"])
        
        if not member_ids_set:
            return []
        
        user_repo = UserRepository()
        search_regex = {"$regex": query, "$options": "i"}
        
        filter_dict = {
            "_id": {"$in": list(member_ids_set)},
            "$or": [
                {"full_name": search_regex},
                {"username": search_regex}
            ]
        }
        
        results = await user_repo.find_many(filter_dict, limit=limit)
        
        exact_matches = []
        partial_matches = []
        
        for r in results:
            full_name = r.get("full_name", "").lower()
            username = r.get("username", "").lower() if r.get("username") else ""
            query_lower = query.lower()
            
            if full_name == query_lower or username == query_lower:
                exact_matches.append(r)
            else:
                partial_matches.append(r)
        
        return exact_matches + partial_matches

