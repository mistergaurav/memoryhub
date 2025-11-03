"""Repository for hub items."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class HubItemsRepository(BaseRepository):
    """
    Repository for collaborative hub items with privacy controls and social features.
    Provides access control, view tracking, and engagement features (likes, bookmarks).
    """
    
    def __init__(self):
        super().__init__("hub_items")
    
    async def find_user_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all hub items owned by a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            item_type: Optional filter by item type
            privacy: Optional filter by privacy level
            tag: Optional filter by tag
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of hub items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {"owner_id": user_oid}
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def find_accessible_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all hub items accessible to a user (owned or public).
        
        Args:
            user_id: String representation of user ID
            item_type: Optional filter by item type
            privacy: Optional filter by privacy level
            tag: Optional filter by tag
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of accessible hub items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"owner_id": user_oid},
                {"privacy": "public"}
            ]
        }
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def count_user_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None
    ) -> int:
        """Count items owned by user matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {"owner_id": user_oid}
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.count(filter_dict)
    
    async def count_accessible_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None
    ) -> int:
        """Count items accessible to user matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"owner_id": user_oid},
                {"privacy": "public"}
            ]
        }
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.count(filter_dict)
    
    async def check_item_ownership(
        self,
        item_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        item = await self.find_one(
            {"_id": item_oid},
            raise_404=True,
            error_message="Hub item not found"
        )
        assert item is not None
        
        is_owner = item.get("owner_id") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the item owner can perform this action"
            )
        
        return is_owner
    
    async def check_item_access(
        self,
        item_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user has access to view a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if no access
            
        Returns:
            True if user has access
            
        Raises:
            HTTPException: If user has no access and raise_error=True
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        item = await self.find_one(
            {"_id": item_oid},
            raise_404=True,
            error_message="Hub item not found"
        )
        assert item is not None
        
        is_owner = item.get("owner_id") == user_oid
        is_public = item.get("privacy") == "public"
        has_access = is_owner or is_public
        
        if not has_access and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You do not have access to this hub item"
            )
        
        return has_access
    
    async def increment_view_count(
        self,
        item_id: str
    ) -> bool:
        """
        Increment the view count for a hub item.
        
        Args:
            item_id: String representation of item ID
            
        Returns:
            True if operation successful
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        
        result = await self.collection.update_one(
            {"_id": item_oid},
            {"$inc": {"view_count": 1}}
        )
        
        return result.modified_count > 0
    
    async def toggle_like(
        self,
        item_id: str,
        user_id: str,
        add_like: bool = True
    ) -> bool:
        """
        Toggle like on a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            add_like: True to add like, False to remove
            
        Returns:
            True if operation successful
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_like else "$pull"
        
        result = await self.collection.update_one(
            {"_id": item_oid},
            {operation: {"likes": user_oid}}
        )
        
        return result.modified_count > 0
    
    async def toggle_bookmark(
        self,
        item_id: str,
        user_id: str,
        add_bookmark: bool = True
    ) -> bool:
        """
        Toggle bookmark on a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            add_bookmark: True to add bookmark, False to remove
            
        Returns:
            True if operation successful
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_bookmark else "$pull"
        
        result = await self.collection.update_one(
            {"_id": item_oid},
            {operation: {"bookmarks": user_oid}}
        )
        
        return result.modified_count > 0
    
    async def search_items(
        self,
        user_id: str,
        query: str,
        item_types: Optional[List[str]] = None,
        tags: Optional[List[str]] = None,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Search hub items with text search and filters.
        
        Args:
            user_id: String representation of user ID
            query: Text search query
            item_types: Optional filter by item types
            tags: Optional filter by tags
            limit: Maximum number of results
            
        Returns:
            List of matching hub items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"owner_id": user_oid},
                {"privacy": "public"}
            ],
            "$text": {"$search": query}
        }
        
        if item_types:
            filter_dict["item_type"] = {"$in": item_types}
        if tags:
            filter_dict["tags"] = {"$in": tags}
        
        return await self.find_many(
            filter_dict,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def get_stats(
        self,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Get statistics for user's hub items.
        
        Args:
            user_id: String representation of user ID
            
        Returns:
            Dictionary with statistics
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        pipeline = [
            {"$match": {"owner_id": user_oid}},
            {
                "$group": {
                    "_id": "$item_type",
                    "count": {"$sum": 1}
                }
            }
        ]
        
        items_by_type = await self.aggregate(pipeline)
        
        total_items = sum(item["count"] for item in items_by_type)
        items_by_type_dict = {item["_id"]: item["count"] for item in items_by_type}
        
        total_views_pipeline = [
            {"$match": {"owner_id": user_oid}},
            {
                "$group": {
                    "_id": None,
                    "total_views": {"$sum": "$view_count"},
                    "total_likes": {"$sum": {"$size": {"$ifNull": ["$likes", []]}}}
                }
            }
        ]
        
        engagement = await self.aggregate(total_views_pipeline)
        total_views = engagement[0]["total_views"] if engagement else 0
        total_likes = engagement[0]["total_likes"] if engagement else 0
        
        return {
            "total_items": total_items,
            "items_by_type": items_by_type_dict,
            "total_views": total_views,
            "total_likes": total_likes
        }
    
    async def get_recent_activity(
        self,
        user_id: str,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get recent activity for user's hub items.
        
        Args:
            user_id: String representation of user ID
            limit: Maximum number of activity items
            
        Returns:
            List of recent activity items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_many(
            {"owner_id": user_oid},
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )

