from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.family.family_albums import (
    FamilyAlbumCreate, FamilyAlbumUpdate, FamilyAlbumResponse,
    AlbumPhotoCreate, AlbumPhotoResponse
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.repositories.family_repository import FamilyAlbumsRepository
from app.utils.validators import validate_object_ids
from app.utils.audit_logger import log_audit_event
from app.models.responses import create_success_response, create_paginated_response, create_message_response

router = APIRouter()
albums_repo = FamilyAlbumsRepository()


async def get_creator_info(created_by_id: ObjectId) -> Dict[str, Any]:
    """Helper function to get creator information"""
    creator = await get_collection("users").find_one({"_id": created_by_id})
    return {
        "full_name": creator.get("full_name") if creator else None,
        "avatar": creator.get("avatar") if creator else None
    }


def build_album_response(album_doc: Dict[str, Any], creator_name: Optional[str] = None) -> FamilyAlbumResponse:
    """Helper function to build album response"""
    return FamilyAlbumResponse(
        id=str(album_doc["_id"]),
        title=album_doc["title"],
        description=album_doc.get("description"),
        cover_photo=album_doc.get("cover_photo"),
        privacy=album_doc["privacy"],
        created_by=str(album_doc["created_by"]),
        created_by_name=creator_name,
        family_circle_ids=[str(cid) for cid in album_doc.get("family_circle_ids", [])],
        member_ids=[str(mid) for mid in album_doc.get("member_ids", [])],
        photos_count=len(album_doc.get("photos", [])),
        created_at=album_doc["created_at"],
        updated_at=album_doc["updated_at"]
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_family_album(
    album: FamilyAlbumCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a new family album with privacy controls.
    
    - Validates circle IDs and member IDs
    - Applies privacy settings (private, family_circle, specific_members, public)
    - Logs album creation for audit trail
    """
    family_circle_oids = validate_object_ids(album.family_circle_ids, "family_circle_ids") if album.family_circle_ids else []
    member_oids = validate_object_ids(album.member_ids, "member_ids") if album.member_ids else []
    
    album_data = {
        "title": album.title,
        "description": album.description,
        "cover_photo": album.cover_photo,
        "privacy": album.privacy,
        "created_by": ObjectId(current_user.id),
        "family_circle_ids": family_circle_oids,
        "member_ids": member_oids,
        "photos": [],
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    album_doc = await albums_repo.create(album_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="album_created",
        event_details={
            "album_id": str(album_doc["_id"]),
            "title": album.title,
            "privacy": album.privacy
        }
    )
    
    response = build_album_response(album_doc, current_user.full_name)
    
    return create_success_response(
        message="Album created successfully",
        data=response.model_dump()
    )


@router.get("/")
async def list_family_albums(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of albums per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List all albums the user has access to with pagination.
    
    - Returns owned albums, albums where user is a member, and public albums
    - Supports pagination with configurable page size
    - Includes creator information and photo counts
    """
    skip = (page - 1) * page_size
    
    albums = await albums_repo.find_accessible_albums(
        user_id=str(current_user.id),
        skip=skip,
        limit=page_size
    )
    
    total = await albums_repo.count_accessible_albums(str(current_user.id))
    
    album_responses = []
    for album_doc in albums:
        creator_info = await get_creator_info(album_doc["created_by"])
        album_responses.append(build_album_response(album_doc, creator_info["full_name"]))
    
    return create_paginated_response(
        items=[a.model_dump() for a in album_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Albums retrieved successfully"
    )


@router.get("/{album_id}")
async def get_family_album(
    album_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a specific album with access control.
    
    - Verifies user has access to view the album
    - Returns complete album details including photos
    """
    await albums_repo.check_album_access(album_id, str(current_user.id), raise_error=True)
    
    album_doc = await albums_repo.find_by_id(
        album_id,
        raise_404=True,
        error_message="Album not found"
    )
    assert album_doc is not None
    
    creator_info = await get_creator_info(album_doc["created_by"])
    response = build_album_response(album_doc, creator_info["full_name"])
    
    return create_success_response(
        message="Album retrieved successfully",
        data=response.model_dump()
    )


@router.put("/{album_id}")
async def update_family_album(
    album_id: str,
    album_update: FamilyAlbumUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Update an album (owner only).
    
    - Only album owner can update
    - Validates IDs if provided
    - Logs update for audit trail
    """
    await albums_repo.check_album_ownership(album_id, str(current_user.id), raise_error=True)
    
    update_data = {k: v for k, v in album_update.model_dump(exclude_unset=True).items() if v is not None}
    
    if "family_circle_ids" in update_data:
        update_data["family_circle_ids"] = validate_object_ids(update_data["family_circle_ids"], "family_circle_ids")
    if "member_ids" in update_data:
        update_data["member_ids"] = validate_object_ids(update_data["member_ids"], "member_ids")
    
    update_data["updated_at"] = datetime.utcnow()
    
    updated_album = await albums_repo.update_by_id(album_id, update_data)
    assert updated_album is not None
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="album_updated",
        event_details={
            "album_id": album_id,
            "updated_fields": list(update_data.keys())
        }
    )
    
    creator_info = await get_creator_info(updated_album["created_by"])
    response = build_album_response(updated_album, creator_info["full_name"])
    
    return create_success_response(
        message="Album updated successfully",
        data=response.model_dump()
    )


@router.delete("/{album_id}", status_code=status.HTTP_200_OK)
async def delete_family_album(
    album_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete an album (owner only).
    
    - Only album owner can delete
    - Removes all associated comments
    - Logs deletion for audit trail (GDPR compliance)
    """
    album_doc = await albums_repo.find_by_id(album_id, raise_404=True)
    assert album_doc is not None
    
    await albums_repo.check_album_ownership(album_id, str(current_user.id), raise_error=True)
    
    await albums_repo.delete_by_id(album_id)
    
    await get_collection("album_comments").delete_many({"album_id": ObjectId(album_id)})
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="album_deleted",
        event_details={
            "album_id": album_id,
            "title": album_doc.get("title"),
            "photos_count": len(album_doc.get("photos", []))
        }
    )
    
    return create_message_response("Album deleted successfully")


@router.post("/{album_id}/photos", status_code=status.HTTP_201_CREATED)
async def add_photo_to_album(
    album_id: str,
    photo: AlbumPhotoCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Add a photo to an album.
    
    - Album owner and members can add photos
    - Creates photo with uploader information
    - Updates album's updated_at timestamp
    """
    await albums_repo.check_album_access(album_id, str(current_user.id), raise_error=True)
    
    photo_data = {
        "_id": ObjectId(),
        "url": photo.url,
        "caption": photo.caption,
        "uploaded_by": ObjectId(current_user.id),
        "uploaded_by_name": current_user.full_name,
        "likes": [],
        "uploaded_at": datetime.utcnow()
    }
    
    await albums_repo.add_photo_to_album(album_id, photo_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="album_photo_added",
        event_details={
            "album_id": album_id,
            "photo_id": str(photo_data["_id"])
        }
    )
    
    photo_response = AlbumPhotoResponse(
        id=str(photo_data["_id"]),
        url=photo_data["url"],
        caption=photo_data.get("caption"),
        uploaded_by=str(photo_data["uploaded_by"]),
        uploaded_by_name=photo_data.get("uploaded_by_name"),
        likes_count=0,
        uploaded_at=photo_data["uploaded_at"]
    )
    
    return create_success_response(
        message="Photo added successfully",
        data=photo_response.model_dump()
    )


@router.get("/{album_id}/photos")
async def get_album_photos(
    album_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get all photos in an album.
    
    - Verifies user has access to view the album
    - Returns all photos with likes count
    """
    await albums_repo.check_album_access(album_id, str(current_user.id), raise_error=True)
    
    album_doc = await albums_repo.find_by_id(album_id, raise_404=True)
    assert album_doc is not None
    
    photos = []
    for photo in album_doc.get("photos", []):
        photos.append(AlbumPhotoResponse(
            id=str(photo["_id"]),
            url=photo["url"],
            caption=photo.get("caption"),
            uploaded_by=str(photo["uploaded_by"]),
            uploaded_by_name=photo.get("uploaded_by_name"),
            likes_count=len(photo.get("likes", [])),
            uploaded_at=photo["uploaded_at"]
        ))
    
    return create_success_response(
        message=f"Retrieved {len(photos)} photos",
        data=[p.model_dump() for p in photos]
    )


@router.delete("/{album_id}/photos/{photo_id}", status_code=status.HTTP_200_OK)
async def delete_photo_from_album(
    album_id: str,
    photo_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete a photo from an album.
    
    - Album owner can delete any photo
    - Photo uploader can delete their own photo
    - Logs deletion for audit trail
    """
    album_doc = await albums_repo.find_by_id(album_id, raise_404=True)
    assert album_doc is not None
    
    is_owner = str(album_doc["created_by"]) == current_user.id
    
    if not is_owner:
        photo = next((p for p in album_doc.get("photos", []) if str(p["_id"]) == photo_id), None)
        if not photo or str(photo["uploaded_by"]) != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="You can only delete photos you uploaded unless you own the album"
            )
    
    await albums_repo.remove_photo_from_album(album_id, photo_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="album_photo_deleted",
        event_details={
            "album_id": album_id,
            "photo_id": photo_id
        }
    )
    
    return create_message_response("Photo deleted successfully")


@router.post("/{album_id}/photos/{photo_id}/like", status_code=status.HTTP_200_OK)
async def like_photo(
    album_id: str,
    photo_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Like a photo in an album"""
    await albums_repo.check_album_access(album_id, str(current_user.id), raise_error=True)
    
    success = await albums_repo.toggle_photo_like(
        album_id=album_id,
        photo_id=photo_id,
        user_id=str(current_user.id),
        add_like=True
    )
    
    if not success:
        raise HTTPException(
            status_code=404,
            detail="Photo not found in album"
        )
    
    return create_message_response("Photo liked successfully")


@router.delete("/{album_id}/photos/{photo_id}/like", status_code=status.HTTP_200_OK)
async def unlike_photo(
    album_id: str,
    photo_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Unlike a photo in an album"""
    await albums_repo.check_album_access(album_id, str(current_user.id), raise_error=True)
    
    success = await albums_repo.toggle_photo_like(
        album_id=album_id,
        photo_id=photo_id,
        user_id=str(current_user.id),
        add_like=False
    )
    
    if not success:
        raise HTTPException(
            status_code=404,
            detail="Photo not found in album"
        )
    
    return create_message_response("Photo unliked successfully")
