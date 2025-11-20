"""Repository for milestone comments."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class CommentRepository(BaseRepository):
    """Repository for milestone comment operations."""
    
    def __init__(self):
        super().__init__("milestone_comments")
    
    async def find_by_milestone(
        self,
        milestone_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Find all comments for a milestone."""
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        return await self.find_many(
            {"milestone_id": milestone_oid, "parent_comment_id": None},  # Top-level only
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=1  # Chronological order
        )
    
    async def find_replies(
        self,
        parent_comment_id: str
    ) -> List[Dict[str, Any]]:
        """Find all replies to a comment."""
        parent_oid = self.validate_object_id(parent_comment_id, "parent_comment_id")
        return await self.find_many(
            {"parent_comment_id": parent_oid},
            sort_by="created_at",
            sort_order=1
        )
    
    async def check_authorship(
        self,
        comment_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """Check if user is the comment author."""
        comment_oid = self.validate_object_id(comment_id, "comment_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        comment = await self.find_one(
            {"_id": comment_oid},
            raise_404=True,
            error_message="Comment not found"
        )
        assert comment is not None
        
        is_author = comment.get("author_id") == user_oid
        
        if not is_author and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the comment author can perform this action"
            )
        
        return is_author
    
    async def count_by_milestone(
        self,
        milestone_id: str
    ) -> int:
        """Count all comments for a milestone."""
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        return await self.count({"milestone_id": milestone_oid})
    
    async def get_nested_comments(
        self,
        milestone_id: str
    ) -> List[Dict[str, Any]]:
        """
        Get all comments with nested replies for a milestone.
        
        Returns top-level comments with their replies nested.
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        
        # Get all comments for this milestone
        all_comments = await self.find_many(
            {"milestone_id": milestone_oid},
            limit=500,
            sort_by="created_at",
            sort_order=1
        )
        
        # Separate top-level and replies
        top_level = []
        replies_map: Dict[str, List[Dict[str, Any]]] = {}
        
        for comment in all_comments:
            if comment.get("parent_comment_id") is None:
                top_level.append(comment)
            else:
                parent_id = str(comment["parent_comment_id"])
                if parent_id not in replies_map:
                    replies_map[parent_id] = []
                replies_map[parent_id].append(comment)
        
        # Attach replies to top-level comments
        for comment in top_level:
            comment_id = str(comment["_id"])
            comment["replies"] = replies_map.get(comment_id, [])
        
        return top_level
