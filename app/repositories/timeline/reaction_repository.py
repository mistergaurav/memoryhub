"""Repository for milestone reactions."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class ReactionRepository(BaseRepository):
    """Repository for milestone reaction operations."""
    
    def __init__(self):
        super().__init__("milestone_reactions")
    
    async def find_by_milestone(
        self,
        milestone_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Find all reactions for a milestone."""
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        return await self.find_many(
            {"milestone_id": milestone_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_user_reaction(
        self,
        milestone_id: str,
        user_id: str
    ) -> Optional[Dict[str, Any]]:
        """Find user's reaction to a milestone."""
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_one(
            {"milestone_id": milestone_oid, "actor_id": user_oid},
            raise_404=False
        )
    
    async def upsert_reaction(
        self,
        milestone_id: str,
        user_id: str,
        reaction_type: str
    ) -> Dict[str, Any]:
        """
        Create or update user's reaction to a milestone.
        
        Args:
            milestone_id: Milestone ID
            user_id: User ID
            reaction_type: Type of reaction
            
        Returns:
            The created/updated reaction document
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        # Check if reaction exists
        existing = await self.find_one(
            {"milestone_id": milestone_oid, "actor_id": user_oid},
            raise_404=False
        )
        
        if existing:
            # Update existing reaction
            result = await self.collection.update_one(
                {"_id": existing["_id"]},
                {
                    "$set": {
                        "reaction_type": reaction_type,
                        "created_at": datetime.utcnow()  # Update timestamp
                    }
                }
            )
            updated = await self.find_one({"_id": existing["_id"]}, raise_404=True)
            assert updated is not None
            return updated
        else:
            # Create new reaction
            reaction_data = {
                "milestone_id": milestone_oid,
                "actor_id": user_oid,
                "reaction_type": reaction_type,
                "created_at": datetime.utcnow()
            }
            return await self.create(reaction_data)
    
    async def delete_user_reaction(
        self,
        milestone_id: str,
        user_id: str
    ) -> bool:
        """
        Delete user's reaction to a milestone.
        
        Returns:
            True if reaction was deleted, False if no reaction existed
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        result = await self.collection.delete_one(
            {"milestone_id": milestone_oid, "actor_id": user_oid}
        )
        
        return result.deleted_count > 0
    
    async def get_reactions_summary(
        self,
        milestone_id: str,
        current_user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get summary of all reactions for a milestone.
        
        Args:
            milestone_id: Milestone ID
            current_user_id: Optional current user ID to include their reaction
            
        Returns:
            Summary dict with counts by type and user's reaction
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        
        # Get all reactions
        reactions = await self.find_many(
            {"milestone_id": milestone_oid},
            limit=1000  # High limit for counting
        )
        
        # Count by type
        reactions_by_type: Dict[str, int] = {}
        user_reaction = None
        recent_reactors = []
        
        for reaction in reactions:
            reaction_type = reaction.get("reaction_type", "like")
            reactions_by_type[reaction_type] = reactions_by_type.get(reaction_type, 0) + 1
            
            # Check if this is current user's reaction
            if current_user_id:
                user_oid = self.validate_object_id(current_user_id, "user_id")
                if reaction.get("actor_id") == user_oid:
                    user_reaction = reaction_type
            
            # Collect recent reactors (limit to 10)
            if len(recent_reactors) < 10:
                recent_reactors.append({
                    "actor_id": str(reaction.get("actor_id")),
                    "reaction_type": reaction_type
                })
        
        return {
            "total_count": len(reactions),
            "reactions_by_type": reactions_by_type,
            "user_reaction": user_reaction,
            "recent_reactors": recent_reactors
        }
    
    async def count_by_milestone(
        self,
        milestone_id: str
    ) -> int:
        """Count all reactions for a milestone."""
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        return await self.count({"milestone_id": milestone_oid})
