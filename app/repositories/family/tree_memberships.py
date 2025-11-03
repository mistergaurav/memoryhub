"""Repository for genealogtreemembership operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class GenealogTreeMembershipRepository(BaseRepository):
    """
    Repository for genealogy tree memberships.
    Manages user access and roles within family trees.
    """
    
    def __init__(self):
        super().__init__("genealogy_tree_memberships")
    
    async def find_by_tree_and_user(
        self,
        tree_id: str,
        user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Find membership for a specific user in a tree.
        
        Args:
            tree_id: String representation of tree ID
            user_id: String representation of user ID
            
        Returns:
            Membership document if found
        """
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_one(
            {"tree_id": tree_oid, "user_id": user_oid},
            raise_404=False
        )
    
    async def find_by_tree(
        self,
        tree_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Find all members of a tree.
        
        Args:
            tree_id: String representation of tree ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of tree memberships
        """
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        return await self.find_many(
            {"tree_id": tree_oid},
            skip=skip,
            limit=limit,
            sort_by="joined_at",
            sort_order=-1
        )
    
    async def create_membership(
        self,
        tree_id: str,
        user_id: str,
        role: str = "member",
        granted_by: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new tree membership.
        
        Args:
            tree_id: String representation of tree ID
            user_id: String representation of user ID
            role: User's role in the tree (owner, member, viewer)
            granted_by: Optional user ID who granted access
            
        Returns:
            Created membership document
        """
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        granted_by_oid = self.validate_object_id(granted_by, "granted_by") if granted_by else user_oid
        
        membership_data = {
            "tree_id": tree_oid,
            "user_id": user_oid,
            "role": role,
            "joined_at": datetime.utcnow(),
            "granted_by": granted_by_oid
        }
        
        return await self.create(membership_data)

