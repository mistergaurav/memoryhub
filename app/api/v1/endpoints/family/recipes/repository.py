from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
from fastapi import HTTPException

from app.repositories.base_repository import BaseRepository


class FamilyRecipesRepository(BaseRepository):
    """
    Repository for family recipes with ratings and favorites management.
    Provides queries for recipe tracking and social engagement.
    """
    
    def __init__(self):
        super().__init__("family_recipes")
    
    async def find_user_recipes(
        self,
        user_id: str,
        category: Optional[str] = None,
        difficulty: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find recipes accessible to a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            category: Optional filter by category
            difficulty: Optional filter by difficulty
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of recipes
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if difficulty:
            filter_dict["difficulty"] = difficulty
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def count_user_recipes(
        self,
        user_id: str,
        category: Optional[str] = None,
        difficulty: Optional[str] = None
    ) -> int:
        """Count recipes matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if difficulty:
            filter_dict["difficulty"] = difficulty
        
        return await self.count(filter_dict)
    
    async def check_recipe_ownership(
        self,
        recipe_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        recipe = await self.find_one(
            {"_id": recipe_oid},
            raise_404=True,
            error_message="Recipe not found"
        )
        assert recipe is not None
        
        is_owner = recipe.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the recipe creator can perform this action"
            )
        
        return is_owner
    
    async def toggle_favorite(
        self,
        recipe_id: str,
        user_id: str,
        add_favorite: bool = True
    ) -> bool:
        """
        Toggle favorite on a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            user_id: String representation of user ID
            add_favorite: True to add favorite, False to remove
            
        Returns:
            True if operation successful
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_favorite else "$pull"
        
        result = await self.collection.update_one(
            {"_id": recipe_oid},
            {operation: {"favorites": user_oid}}
        )
        
        return result.modified_count > 0
    
    async def add_rating(
        self,
        recipe_id: str,
        user_id: str,
        rating: int,
        comment: Optional[str] = None
    ) -> bool:
        """
        Add or update a rating for a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            user_id: String representation of user ID
            rating: Rating value (1-5)
            comment: Optional comment
            
        Returns:
            True if operation successful
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        await self.collection.update_one(
            {"_id": recipe_oid},
            {"$pull": {"ratings": {"user_id": user_oid}}}
        )
        
        result = await self.collection.update_one(
            {"_id": recipe_oid},
            {
                "$push": {
                    "ratings": {
                        "user_id": user_oid,
                        "rating": rating,
                        "comment": comment,
                        "created_at": datetime.utcnow()
                    }
                }
            }
        )
        
        return result.modified_count > 0
    
    async def increment_times_made(
        self,
        recipe_id: str
    ) -> bool:
        """
        Increment the times_made counter for a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            
        Returns:
            True if operation successful
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        
        result = await self.collection.update_one(
            {"_id": recipe_oid},
            {"$inc": {"times_made": 1}}
        )
        
        return result.modified_count > 0

