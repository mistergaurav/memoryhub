from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.family.family_albums import (
    FamilyAlbumCreate, FamilyAlbumUpdate, FamilyAlbumResponse,
    AlbumPhotoCreate, AlbumPhotoResponse, AlbumCommentCreate,
    AlbumCommentResponse, AlbumPhotoInDB
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.utils.validators import validate_object_id, validate_object_ids

router = APIRouter()



@router.post("/", response_model=FamilyAlbumResponse, status_code=status.HTTP_201_CREATED)
async def create_family_album(
    album: FamilyAlbumCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new family album"""
    try:
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
        
        result = await get_collection("family_albums").insert_one(album_data)
        album_doc = await get_collection("family_albums").find_one({"_id": result.inserted_id})
        
        return FamilyAlbumResponse(
            id=str(album_doc["_id"]),
            title=album_doc["title"],
            description=album_doc.get("description"),
            cover_photo=album_doc.get("cover_photo"),
            privacy=album_doc["privacy"],
            created_by=str(album_doc["created_by"]),
            created_by_name=current_user.full_name,
            family_circle_ids=[str(cid) for cid in album_doc.get("family_circle_ids", [])],
            member_ids=[str(mid) for mid in album_doc.get("member_ids", [])],
            photos_count=len(album_doc.get("photos", [])),
            created_at=album_doc["created_at"],
            updated_at=album_doc["updated_at"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create album: {str(e)}")


@router.get("/", response_model=List[FamilyAlbumResponse])
async def list_family_albums(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(50, ge=1, le=100, description="Number of records to return"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all albums the user has access to with pagination"""
    try:
        user_oid = ObjectId(current_user.id)
        
        albums_cursor = get_collection("family_albums").find({
            "$or": [
                {"created_by": user_oid},
                {"member_ids": user_oid},
                {"privacy": "public"}
            ]
        }).skip(skip).limit(limit).sort("updated_at", -1)
        
        albums = []
        async for album_doc in albums_cursor:
            creator = await get_collection("users").find_one({"_id": album_doc["created_by"]})
            
            albums.append(FamilyAlbumResponse(
                id=str(album_doc["_id"]),
                title=album_doc["title"],
                description=album_doc.get("description"),
                cover_photo=album_doc.get("cover_photo"),
                privacy=album_doc["privacy"],
                created_by=str(album_doc["created_by"]),
                created_by_name=creator.get("full_name") if creator else None,
                family_circle_ids=[str(cid) for cid in album_doc.get("family_circle_ids", [])],
                member_ids=[str(mid) for mid in album_doc.get("member_ids", [])],
                photos_count=len(album_doc.get("photos", [])),
                created_at=album_doc["created_at"],
                updated_at=album_doc["updated_at"]
            ))
        
        return albums
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list albums: {str(e)}")


@router.get("/{album_id}", response_model=FamilyAlbumResponse)
async def get_family_album(
    album_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific album"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        if not album_oid:
            raise HTTPException(status_code=400, detail="Invalid album ID")
        
        album_doc = await get_collection("family_albums").find_one({"_id": album_oid})
        if not album_doc:
            raise HTTPException(status_code=404, detail="Album not found")
        
        creator = await get_collection("users").find_one({"_id": album_doc["created_by"]})
        
        return FamilyAlbumResponse(
            id=str(album_doc["_id"]),
            title=album_doc["title"],
            description=album_doc.get("description"),
            cover_photo=album_doc.get("cover_photo"),
            privacy=album_doc["privacy"],
            created_by=str(album_doc["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in album_doc.get("family_circle_ids", [])],
            member_ids=[str(mid) for mid in album_doc.get("member_ids", [])],
            photos_count=len(album_doc.get("photos", [])),
            created_at=album_doc["created_at"],
            updated_at=album_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get album: {str(e)}")


@router.put("/{album_id}", response_model=FamilyAlbumResponse)
async def update_family_album(
    album_id: str,
    album_update: FamilyAlbumUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update an album"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        if not album_oid:
            raise HTTPException(status_code=400, detail="Invalid album ID")
        
        album_doc = await get_collection("family_albums").find_one({"_id": album_oid})
        if not album_doc:
            raise HTTPException(status_code=404, detail="Album not found")
        
        if str(album_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this album")
        
        update_data = {k: v for k, v in album_update.dict(exclude_unset=True).items() if v is not None}
        
        if "family_circle_ids" in update_data:
            update_data["family_circle_ids"] = [safe_object_id(cid) for cid in update_data["family_circle_ids"] if safe_object_id(cid)]
        if "member_ids" in update_data:
            update_data["member_ids"] = [safe_object_id(mid) for mid in update_data["member_ids"] if safe_object_id(mid)]
        
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("family_albums").update_one(
            {"_id": album_oid},
            {"$set": update_data}
        )
        
        updated_album = await get_collection("family_albums").find_one({"_id": album_oid})
        creator = await get_collection("users").find_one({"_id": updated_album["created_by"]})
        
        return FamilyAlbumResponse(
            id=str(updated_album["_id"]),
            title=updated_album["title"],
            description=updated_album.get("description"),
            cover_photo=updated_album.get("cover_photo"),
            privacy=updated_album["privacy"],
            created_by=str(updated_album["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in updated_album.get("family_circle_ids", [])],
            member_ids=[str(mid) for mid in updated_album.get("member_ids", [])],
            photos_count=len(updated_album.get("photos", [])),
            created_at=updated_album["created_at"],
            updated_at=updated_album["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update album: {str(e)}")


@router.delete("/{album_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_family_album(
    album_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete an album"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        if not album_oid:
            raise HTTPException(status_code=400, detail="Invalid album ID")
        
        album_doc = await get_collection("family_albums").find_one({"_id": album_oid})
        if not album_doc:
            raise HTTPException(status_code=404, detail="Album not found")
        
        if str(album_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this album")
        
        await get_collection("family_albums").delete_one({"_id": album_oid})
        
        await get_collection("album_comments").delete_many({"album_id": album_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete album: {str(e)}")


@router.post("/{album_id}/photos", response_model=AlbumPhotoResponse, status_code=status.HTTP_201_CREATED)
async def add_photo_to_album(
    album_id: str,
    photo: AlbumPhotoCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a photo to an album"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        if not album_oid:
            raise HTTPException(status_code=400, detail="Invalid album ID")
        
        album_doc = await get_collection("family_albums").find_one({"_id": album_oid})
        if not album_doc:
            raise HTTPException(status_code=404, detail="Album not found")
        
        photo_data = {
            "_id": ObjectId(),
            "url": photo.url,
            "caption": photo.caption,
            "uploaded_by": ObjectId(current_user.id),
            "uploaded_by_name": current_user.full_name,
            "likes": [],
            "uploaded_at": datetime.utcnow()
        }
        
        await get_collection("family_albums").update_one(
            {"_id": album_oid},
            {
                "$push": {"photos": photo_data},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        return AlbumPhotoResponse(
            id=str(photo_data["_id"]),
            url=photo_data["url"],
            caption=photo_data.get("caption"),
            uploaded_by=str(photo_data["uploaded_by"]),
            uploaded_by_name=photo_data.get("uploaded_by_name"),
            likes_count=0,
            uploaded_at=photo_data["uploaded_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add photo: {str(e)}")


@router.get("/{album_id}/photos", response_model=List[AlbumPhotoResponse])
async def get_album_photos(
    album_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all photos in an album"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        if not album_oid:
            raise HTTPException(status_code=400, detail="Invalid album ID")
        
        album_doc = await get_collection("family_albums").find_one({"_id": album_oid})
        if not album_doc:
            raise HTTPException(status_code=404, detail="Album not found")
        
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
        
        return photos
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get photos: {str(e)}")


@router.delete("/{album_id}/photos/{photo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_photo_from_album(
    album_id: str,
    photo_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a photo from an album"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        photo_oid = validate_object_id(photo_id, "photo_id")
        
        if not album_oid or not photo_oid:
            raise HTTPException(status_code=400, detail="Invalid ID")
        
        album_doc = await get_collection("family_albums").find_one({"_id": album_oid})
        if not album_doc:
            raise HTTPException(status_code=404, detail="Album not found")
        
        if str(album_doc["created_by"]) != current_user.id:
            photo = next((p for p in album_doc.get("photos", []) if str(p["_id"]) == photo_id), None)
            if not photo or str(photo["uploaded_by"]) != current_user.id:
                raise HTTPException(status_code=403, detail="Not authorized to delete this photo")
        
        await get_collection("family_albums").update_one(
            {"_id": album_oid},
            {
                "$pull": {"photos": {"_id": photo_oid}},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete photo: {str(e)}")


@router.post("/{album_id}/photos/{photo_id}/like", status_code=status.HTTP_200_OK)
async def like_photo(
    album_id: str,
    photo_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Like a photo"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        photo_oid = validate_object_id(photo_id, "photo_id")
        
        if not album_oid or not photo_oid:
            raise HTTPException(status_code=400, detail="Invalid ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_albums").update_one(
            {"_id": album_oid, "photos._id": photo_oid},
            {"$addToSet": {"photos.$.likes": user_oid}}
        )
        
        return {"message": "Photo liked successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to like photo: {str(e)}")


@router.delete("/{album_id}/photos/{photo_id}/like", status_code=status.HTTP_200_OK)
async def unlike_photo(
    album_id: str,
    photo_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Unlike a photo"""
    try:
        album_oid = validate_object_id(album_id, "album_id")
        photo_oid = validate_object_id(photo_id, "photo_id")
        
        if not album_oid or not photo_oid:
            raise HTTPException(status_code=400, detail="Invalid ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_albums").update_one(
            {"_id": album_oid, "photos._id": photo_oid},
            {"$pull": {"photos.$.likes": user_oid}}
        )
        
        return {"message": "Photo unliked successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unlike photo: {str(e)}")
