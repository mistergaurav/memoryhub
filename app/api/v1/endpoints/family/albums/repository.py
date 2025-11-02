from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException

from app.repositories.base_repository import BaseRepository


class FamilyAlbumsRepository(BaseRepository):
    """
    Repository for family albums with photo management.
    Provides access control, privacy checks, and photo operations.
    """
    
    def __init__(self):
        super().__init__("family_albums")
    
    async def find_accessible_albums(
        self,
        user_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all albums the user has access to (owned, member, or public).
        
        Args:
            user_id: String representation of user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of accessible albums
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_many(
            {
                "$or": [
                    {"created_by": user_oid},
                    {"member_ids": user_oid},
                    {"privacy": "public"}
                ]
            },
            skip=skip,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def count_accessible_albums(self, user_id: str) -> int:
        """Count total albums accessible to user."""
        user_oid = self.validate_object_id(user_id, "user_id")
        return await self.count({
            "$or": [
                {"created_by": user_oid},
                {"member_ids": user_oid},
                {"privacy": "public"}
            ]
        })
    
    async def check_album_ownership(
        self,
        album_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns an album.
        
        Args:
            album_id: String representation of album ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        album = await self.find_one(
            {"_id": album_oid},
            raise_404=True,
            error_message="Album not found"
        )
        assert album is not None
        
        is_owner = album.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the album owner can perform this action"
            )
        
        return is_owner
    
    async def check_album_access(
        self,
        album_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user has access to view an album.
        
        Args:
            album_id: String representation of album ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if no access
            
        Returns:
            True if user has access
            
        Raises:
            HTTPException: If user has no access and raise_error=True
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        album = await self.find_one(
            {"_id": album_oid},
            raise_404=True,
            error_message="Album not found"
        )
        assert album is not None
        
        is_owner = album.get("created_by") == user_oid
        is_member = user_oid in album.get("member_ids", [])
        is_public = album.get("privacy") == "public"
        has_access = is_owner or is_member or is_public
        
        if not has_access and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You do not have access to this album"
            )
        
        return has_access
    
    async def add_photo_to_album(
        self,
        album_id: str,
        photo_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Add a photo to an album using atomic operation.
        
        Args:
            album_id: String representation of album ID
            photo_data: Photo document to add
            
        Returns:
            Updated album document
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        
        await self.collection.update_one(
            {"_id": album_oid},
            {
                "$push": {"photos": photo_data},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_album = await self.find_one({"_id": album_oid}, raise_404=True)
        assert updated_album is not None
        return updated_album
    
    async def remove_photo_from_album(
        self,
        album_id: str,
        photo_id: str
    ) -> Dict[str, Any]:
        """
        Remove a photo from an album using atomic operation.
        
        Args:
            album_id: String representation of album ID
            photo_id: String representation of photo ID
            
        Returns:
            Updated album document
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        photo_oid = self.validate_object_id(photo_id, "photo_id")
        
        await self.collection.update_one(
            {"_id": album_oid},
            {
                "$pull": {"photos": {"_id": photo_oid}},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_album = await self.find_one({"_id": album_oid}, raise_404=True)
        assert updated_album is not None
        return updated_album
    
    async def toggle_photo_like(
        self,
        album_id: str,
        photo_id: str,
        user_id: str,
        add_like: bool = True
    ) -> bool:
        """
        Add or remove a like from a photo.
        
        Args:
            album_id: String representation of album ID
            photo_id: String representation of photo ID
            user_id: String representation of user ID
            add_like: True to add like, False to remove
            
        Returns:
            True if operation was successful
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        photo_oid = self.validate_object_id(photo_id, "photo_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_like else "$pull"
        
        result = await self.collection.update_one(
            {"_id": album_oid, "photos._id": photo_oid},
            {operation: {"photos.$.likes": user_oid}}
        )
        
        return result.modified_count > 0
