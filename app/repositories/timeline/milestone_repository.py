"""Repository for user milestones."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class MilestoneRepository(BaseRepository):
    """Repository for user milestone operations."""
    
    def __init__(self):
        super().__init__("user_milestones")
    
    async def find_by_owner(
        self,
        owner_id: str,
        skip: int = 0,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Find all milestones by owner."""
        owner_oid = self.validate_object_id(owner_id, "owner_id")
        return await self.find_many(
            {"owner_id": owner_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def check_ownership(
        self,
        milestone_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """Check if user owns the milestone."""
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        milestone = await self.find_one(
            {"_id": milestone_oid},
            raise_404=True,
            error_message="Milestone not found"
        )
        assert milestone is not None
        
        is_owner = milestone.get("owner_id") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the milestone owner can perform this action"
            )
        
        return is_owner
    
    async def get_feed(
        self,
        user_id: str,
        skip: int = 0,
        limit: int = 20,
        scope_filter: Optional[str] = None,
        person_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get timeline feed for user based on visibility and relationships.
        
        Args:
            user_id: Current user ID
            skip: Number of items to skip
            limit: Maximum items to return
            scope_filter: Optional filter by scope (private, friends, family, public)
            person_id: Optional filter by specific person
            
        Returns:
            Dict with items and total count
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        # Build query for visibility
        query: Dict[str, Any] = {
            "$or": [
                {"owner_id": user_oid},  # User's own milestones
                {"audience_scope": "public"}  # Public milestones
            ]
        }
        
        # Add scope filter if provided
        if scope_filter:
            if scope_filter == "private":
                query = {"owner_id": user_oid, "audience_scope": "private"}
            elif scope_filter in ["friends", "family"]:
                query["audience_scope"] = scope_filter
        
        # Add person filter if provided
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            query["owner_id"] = person_oid
        
        # Get total count
        total = await self.count(query)
        
        # Get items
        items = await self.find_many(
            query,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
        
        return {
            "items": items,
            "total": total,
            "page": (skip // limit) + 1 if limit > 0 else 1,
            "page_size": limit
        }
    
    async def increment_engagement(
        self,
        milestone_id: str,
        field: str,
        amount: int = 1
    ) -> Dict[str, Any]:
        """
        Atomically increment engagement count.
        
        Args:
            milestone_id: Milestone ID
            field: Field to increment (likes_count, comments_count, reactions_count)
            amount: Amount to increment (default 1, use -1 to decrement)
            
        Returns:
            Updated milestone document
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        
        # Validate field
        valid_fields = ["likes_count", "comments_count", "reactions_count"]
        if field not in valid_fields:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid engagement field. Must be one of: {valid_fields}"
            )
        
        # Atomic increment
        result = await self.collection.update_one(
            {"_id": milestone_oid},
            {
                "$inc": {f"engagement_counts.{field}": amount},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Milestone not found")
        
        # Return updated document
        updated = await self.find_one({"_id": milestone_oid}, raise_404=True)
        assert updated is not None
        return updated
