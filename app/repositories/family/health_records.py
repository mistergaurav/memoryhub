"""Repository for health records with caching."""
from typing import List, Dict, Any, Optional, Callable, Awaitable
from bson import ObjectId
from datetime import datetime
import time
from ..base_repository import BaseRepository


class HealthRecordsRepository(BaseRepository):
    """
    Repository for health records with subject association model and privacy controls.
    Supports SELF/FAMILY/FRIEND subject types with comprehensive query and authorization methods.
    
    Implements async-compatible in-memory caching with 5-minute TTL for frequently accessed queries.
    Cache is automatically cleared after create/update operations to ensure data consistency.
    """
    
    _cache: Dict[str, tuple[float, Any]] = {}
    
    def __init__(self):
        super().__init__("health_records")
    
    async def _get_cached(
        self,
        cache_key: str,
        fetch_func: Callable[[], Awaitable[Any]],
        ttl: int = 300
    ) -> Any:
        """
        Helper method to get data from cache or execute fetch function.
        
        Implements TTL-based caching with automatic expiration. If cached data exists
        and hasn't expired, returns cached value. Otherwise, executes fetch_func,
        caches the result, and returns it.
        
        Args:
            cache_key: Unique key identifying the cached data
            fetch_func: Async function to fetch data if not in cache or expired
            ttl: Time-to-live in seconds (default: 300 = 5 minutes)
            
        Returns:
            Cached or freshly fetched data
        """
        current_time = time.time()
        
        if cache_key in self._cache:
            expiry_time, cached_data = self._cache[cache_key]
            if current_time < expiry_time:
                return cached_data
        
        fresh_data = await fetch_func()
        self._cache[cache_key] = (current_time + ttl, fresh_data)
        
        return fresh_data
    
    def _clear_cache(self) -> None:
        """
        Clear all cached health records data.
        
        Called automatically after create/update operations to ensure
        users always see the latest data. This prevents stale cache issues
        where new or modified records wouldn't appear until TTL expiration.
        """
        self._cache.clear()
    
    async def find_by_subject_type(
        self,
        family_id: str,
        subject_type: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Filter health records by subject type with pagination.
        
        Args:
            family_id: String representation of family circle ID
            subject_type: Subject type filter (SELF, FAMILY, or FRIEND)
            limit: Maximum number of records to return
            offset: Number of records to skip for pagination
            
        Returns:
            List of health records matching the subject type
        """
        family_oid = self.validate_object_id(family_id, "family_id")
        
        filter_dict: Dict[str, Any] = {
            "family_id": family_oid,
            "subject_type": subject_type.lower()
        }
        
        return await self.find_many(
            filter_dict,
            skip=offset,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_by_subject_user(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get all health records where subject_user_id matches.
        
        This returns records where the subject is the user themselves (SELF subject type).
        Uses indexed query on subject_user_id for optimal performance.
        
        CACHING: Results are cached for 5 minutes to improve performance for frequently
        accessed user health records. Cache is automatically cleared on create/update.
        
        Args:
            user_id: String representation of user ID
            limit: Maximum number of records to return
            offset: Number of records to skip for pagination
            
        Returns:
            List of health records for this user as subject
        """
        cache_key = f"find_by_subject_user:{user_id}:{limit}:{offset}"
        
        async def fetch_data() -> List[Dict[str, Any]]:
            user_oid = self.validate_object_id(user_id, "user_id")
            
            filter_dict: Dict[str, Any] = {
                "subject_user_id": user_oid,
                "subject_type": "self"
            }
            
            return await self.find_many(
                filter_dict,
                skip=offset,
                limit=limit,
                sort_by="date",
                sort_order=-1
            )
        
        return await self._get_cached(cache_key, fetch_data)
    
    async def find_by_subject_family_member(
        self,
        family_member_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get health records for a specific family member.
        
        This returns records where the subject is a family member (FAMILY subject type).
        Uses indexed query on subject_family_member_id for optimal performance.
        
        Args:
            family_member_id: String representation of family member ID
            limit: Maximum number of records to return
            offset: Number of records to skip for pagination
            
        Returns:
            List of health records for this family member
        """
        member_oid = self.validate_object_id(family_member_id, "family_member_id")
        
        filter_dict: Dict[str, Any] = {
            "subject_family_member_id": member_oid,
            "subject_type": "family"
        }
        
        return await self.find_many(
            filter_dict,
            skip=offset,
            limit=limit,
            sort_by="date",
            sort_order=-1
        )
    
    async def find_by_subject_friend(
        self,
        friend_circle_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get health records for a friend.
        
        This returns records where the subject is a friend (FRIEND subject type).
        Uses indexed query on subject_friend_circle_id for optimal performance.
        
        Args:
            friend_circle_id: String representation of friend circle ID
            limit: Maximum number of records to return
            offset: Number of records to skip for pagination
            
        Returns:
            List of health records for this friend
        """
        friend_oid = self.validate_object_id(friend_circle_id, "friend_circle_id")
        
        filter_dict: Dict[str, Any] = {
            "subject_friend_circle_id": friend_oid,
            "subject_type": "friend"
        }
        
        return await self.find_many(
            filter_dict,
            skip=offset,
            limit=limit,
            sort_by="date",
            sort_order=-1
        )
    
    async def find_by_assigned_user(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get all health records assigned to a user (including shared records).
        
        This returns records where the user is in the assigned_user_ids array.
        Uses indexed query on assigned_user_ids for optimal performance.
        
        CACHING: Results are cached for 5 minutes to improve performance for frequently
        accessed assigned health records. Cache is automatically cleared on create/update.
        
        Args:
            user_id: String representation of user ID
            limit: Maximum number of records to return
            offset: Number of records to skip for pagination
            
        Returns:
            List of health records assigned to this user
        """
        cache_key = f"find_by_assigned_user:{user_id}:{limit}:{offset}"
        
        async def fetch_data() -> List[Dict[str, Any]]:
            user_oid = self.validate_object_id(user_id, "user_id")
            
            filter_dict: Dict[str, Any] = {
                "assigned_user_ids": user_oid
            }
            
            return await self.find_many(
                filter_dict,
                skip=offset,
                limit=limit,
                sort_by="date",
                sort_order=-1
            )
        
        return await self._get_cached(cache_key, fetch_data)
    
    async def check_user_access(
        self,
        record_id: str,
        user_id: str
    ) -> bool:
        """
        Verify if user has access to a specific health record.
        
        Checks access based on:
        1. User is the creator of the record
        2. User is in the assigned_user_ids list
        3. User is the subject (for SELF type records)
        
        Args:
            record_id: String representation of health record ID
            user_id: String representation of user ID
            
        Returns:
            True if user has access, False otherwise
        """
        record_oid = self.validate_object_id(record_id, "record_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        record = await self.find_one(
            {"_id": record_oid},
            raise_404=False
        )
        
        if not record:
            return False
        
        # Check if user is the creator
        if record.get("created_by") == user_oid:
            return True
        
        # Check if user is assigned to this record
        if user_oid in record.get("assigned_user_ids", []):
            return True
        
        # Check if user is the subject (for SELF type records)
        if record.get("subject_type") == "self" and record.get("subject_user_id") == user_oid:
            return True
        
        return False
    
    async def get_accessible_records(
        self,
        user_id: str,
        filters: Optional[Dict[str, Any]] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get all health records the user can access with optional filters.
        
        Returns records where user is:
        - The creator (created_by)
        - Assigned to the record (in assigned_user_ids)
        - The subject (for SELF type records)
        
        Optional filters can include:
        - record_type: Filter by specific record type
        - date_from: Filter records from this date onwards
        - date_to: Filter records up to this date
        - subject_type: Filter by subject type (SELF/FAMILY/FRIEND)
        - family_id: Filter by family circle
        
        CACHING: Results are cached for 5 minutes to improve performance for the main
        listing query used by UI. Cache key includes all parameters. Cache is 
        automatically cleared on create/update.
        
        Args:
            user_id: String representation of user ID
            filters: Optional dictionary of filter criteria
            limit: Maximum number of records to return
            offset: Number of records to skip for pagination
            
        Returns:
            List of accessible health records matching the filters
        """
        filters_str = str(sorted(filters.items())) if filters else "none"
        cache_key = f"get_accessible_records:{user_id}:{filters_str}:{limit}:{offset}"
        
        async def fetch_data() -> List[Dict[str, Any]]:
            user_oid = self.validate_object_id(user_id, "user_id")
            
            # Build base access query
            filter_dict: Dict[str, Any] = {
                "$or": [
                    {"created_by": user_oid},
                    {"assigned_user_ids": user_oid},
                    {"subject_type": "self", "subject_user_id": user_oid}
                ]
            }
            
            # Apply optional filters
            if filters:
                # Filter by record type
                if "record_type" in filters:
                    filter_dict["record_type"] = filters["record_type"]
                
                # Filter by date range
                if "date_from" in filters or "date_to" in filters:
                    date_filter: Dict[str, Any] = {}
                    if "date_from" in filters:
                        date_filter["$gte"] = filters["date_from"]
                    if "date_to" in filters:
                        date_filter["$lte"] = filters["date_to"]
                    filter_dict["date"] = date_filter
                
                # Filter by subject type
                if "subject_type" in filters:
                    filter_dict["subject_type"] = filters["subject_type"].lower()
                
                # Filter by family circle
                if "family_id" in filters:
                    family_oid = self.validate_object_id(filters["family_id"], "family_id")
                    filter_dict["family_id"] = family_oid
            
            return await self.find_many(
                filter_dict,
                skip=offset,
                limit=limit,
                sort_by="date",
                sort_order=-1
            )
        
        return await self._get_cached(cache_key, fetch_data)
    
    async def get_shared_health_records(
        self,
        user_id: str,
        shared_with_user_id: str
    ) -> List[Dict[str, Any]]:
        """
        Get health records shared with a specific user.
        
        Implements privacy controls by checking sharing permissions
        and filtering confidential records based on access rights.
        
        Args:
            user_id: Owner of the health records
            shared_with_user_id: User requesting access to the records
            
        Returns:
            List of health records that the requesting user has access to
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        shared_with_oid = self.validate_object_id(shared_with_user_id, "shared_with_user_id")
        
        pipeline = [
            {"$match": {"family_id": user_oid}},
            {
                "$lookup": {
                    "from": "health_record_shares",
                    "let": {"record_id": "$_id"},
                    "pipeline": [
                        {
                            "$match": {
                                "$expr": {
                                    "$and": [
                                        {"$eq": ["$record_id", "$$record_id"]},
                                        {"$eq": ["$shared_with_user_id", shared_with_oid]}
                                    ]
                                }
                            }
                        }
                    ],
                    "as": "share_permission"
                }
            },
            {
                "$match": {
                    "$or": [
                        {"is_confidential": False},
                        {"share_permission": {"$ne": []}}
                    ]
                }
            },
            {
                "$lookup": {
                    "from": "family_members",
                    "localField": "family_member_id",
                    "foreignField": "_id",
                    "as": "member_info"
                }
            },
            {
                "$addFields": {
                    "family_member_name": {
                        "$ifNull": [
                            {"$arrayElemAt": ["$member_info.name", 0]},
                            None
                        ]
                    }
                }
            },
            {
                "$project": {
                    "share_permission": 0,
                    "member_info": 0
                }
            },
            {"$sort": {"date": -1}}
        ]
        
        return await self.aggregate(pipeline)
    
    async def create(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new health record and clear cache.
        
        Overrides BaseRepository.create() to automatically clear cached
        health records after successful creation, ensuring users immediately
        see new records without waiting for cache expiration.
        
        Args:
            data: Document data to insert
            
        Returns:
            Created health record document with _id
        """
        result = await super().create(data)
        self._clear_cache()
        return result
    
    async def update_by_id(
        self,
        doc_id: str,
        update_data: Dict[str, Any],
        raise_404: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Update a health record by ID and clear cache.
        
        Overrides BaseRepository.update_by_id() to automatically clear cached
        health records after successful update, ensuring users see modified
        records without waiting for cache expiration.
        
        Args:
            doc_id: String representation of document ID
            update_data: Data to update
            raise_404: Whether to raise 404 if not found
            
        Returns:
            Updated health record document
        """
        result = await super().update_by_id(doc_id, update_data, raise_404)
        self._clear_cache()
        return result
    
    async def update(
        self,
        filter_dict: Dict[str, Any],
        update_data: Dict[str, Any],
        raise_404: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Update a health record and clear cache.
        
        Overrides BaseRepository.update() to automatically clear cached
        health records after successful update, ensuring users see modified
        records without waiting for cache expiration.
        
        Args:
            filter_dict: MongoDB filter criteria
            update_data: Data to update
            raise_404: Whether to raise 404 if not found
            
        Returns:
            Updated health record document
        """
        result = await super().update(filter_dict, update_data, raise_404)
        self._clear_cache()
        return result
    
    async def delete_by_id(self, doc_id: str, raise_404: bool = True) -> bool:
        """
        Delete a health record by ID and clear cache.
        
        Overrides BaseRepository.delete_by_id() to automatically clear cached
        health records after successful deletion, ensuring users don't see
        deleted records in cached query results.
        
        Args:
            doc_id: String representation of document ID
            raise_404: Whether to raise 404 if not found
            
        Returns:
            True if deleted
        """
        result = await super().delete_by_id(doc_id, raise_404)
        self._clear_cache()
        return result
    
    async def delete(
        self,
        filter_dict: Dict[str, Any],
        raise_404: bool = True
    ) -> bool:
        """
        Delete a health record and clear cache.
        
        Overrides BaseRepository.delete() to automatically clear cached
        health records after successful deletion, ensuring users don't see
        deleted records in cached query results.
        
        Args:
            filter_dict: MongoDB filter criteria
            raise_404: Whether to raise 404 if not found
            
        Returns:
            True if deleted
        """
        result = await super().delete(filter_dict, raise_404)
        self._clear_cache()
        return result
    
    async def delete_many(self, filter_dict: Dict[str, Any]) -> int:
        """
        Delete multiple health records and clear cache.
        
        Overrides BaseRepository.delete_many() to automatically clear cached
        health records after bulk deletion, ensuring users don't see
        deleted records in cached query results.
        
        Args:
            filter_dict: MongoDB filter criteria
            
        Returns:
            Number of documents deleted
        """
        result = await super().delete_many(filter_dict)
        self._clear_cache()
        return result

