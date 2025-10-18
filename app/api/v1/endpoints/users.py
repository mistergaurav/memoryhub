from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import FileResponse
from bson import ObjectId
import os
import shutil
from pathlib import Path

from app.core.security import get_current_user, oauth2_scheme
from app.core.hashing import get_password_hash
from app.db.mongodb import get_collection
from app.models.user import (
    UserInDB, UserCreate, UserUpdate, UserResponse, 
    UserProfileResponse, UserSettingsUpdate, UserRole
)

router = APIRouter()

# Configure upload directory
AVATAR_UPLOAD_DIR = "uploads/avatars"
os.makedirs(AVATAR_UPLOAD_DIR, exist_ok=True)

def convert_user_doc(user_doc: dict) -> dict:
    """Convert MongoDB user document to response format"""
    if not user_doc:
        return None
    
    result = dict(user_doc)
    if "_id" in result:
        result["id"] = str(result.pop("_id"))
    
    # Ensure required fields are present
    if "created_at" not in result:
        result["created_at"] = result.get("created_at", datetime.utcnow())
    if "updated_at" not in result:
        result["updated_at"] = result.get("updated_at", datetime.utcnow())
    
    return result

@router.get("/me", response_model=UserProfileResponse)
async def read_users_me(current_user: UserInDB = Depends(get_current_user)):
    """Get current user profile with stats"""
    # Get user stats
    stats = {
        "memories": await get_collection("memories").count_documents({"owner_id": ObjectId(current_user.id)}),
        "files": await get_collection("files").count_documents({"owner_id": ObjectId(current_user.id)}),
        "followers": await get_collection("relationships").count_documents({"following_id": ObjectId(current_user.id), "status": "accepted"}),
        "following": await get_collection("relationships").count_documents({"follower_id": ObjectId(current_user.id), "status": "accepted"})
    }
    
    user_dict = {
        "id": str(current_user.id),
        "email": current_user.email,
        "full_name": current_user.full_name,
        "avatar_url": current_user.avatar_url,
        "bio": current_user.bio,
        "is_active": current_user.is_active,
        "role": current_user.role,
        "created_at": current_user.created_at,
        "updated_at": current_user.updated_at,
        "stats": stats
    }
    return user_dict

@router.put("/me", response_model=UserResponse)
async def update_user_me(
    user_update: UserUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update current user profile"""
    update_data = user_update.dict(exclude_unset=True)
    update_data["updated_at"] = datetime.utcnow()
    
    if "email" in update_data and update_data["email"] != current_user.email:
        # Check if email is already taken
        existing_user = await get_collection("users").find_one({"email": update_data["email"]})
        if existing_user and str(existing_user["_id"]) != str(current_user.id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    await get_collection("users").update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": update_data}
    )
    
    updated_user = await get_collection("users").find_one({"_id": ObjectId(current_user.id)})
    return UserResponse(**convert_user_doc(updated_user))

@router.put("/me/password")
async def change_password(
    current_password: str,
    new_password: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Change current user's password"""
    from app.core.security import verify_password
    
    # Verify current password
    if not verify_password(current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect current password"
        )
    
    # Update password
    hashed_password = get_password_hash(new_password)
    await get_collection("users").update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": {"hashed_password": hashed_password, "updated_at": datetime.utcnow()}}
    )
    
    return {"message": "Password updated successfully"}

@router.post("/me/avatar", response_model=UserResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: UserInDB = Depends(get_current_user)
):
    """Upload user avatar"""
    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only JPEG, PNG, and WebP images are allowed"
        )
    
    # Create user's avatar directory
    user_avatar_dir = os.path.join(AVATAR_UPLOAD_DIR, str(current_user.id))
    os.makedirs(user_avatar_dir, exist_ok=True)
    
    # Generate unique filename
    file_extension = Path(file.filename).suffix
    filename = f"avatar{file_extension}"
    file_path = os.path.join(user_avatar_dir, filename)
    
    # Save the file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Update user's avatar URL
    avatar_url = f"/api/v1/users/me/avatar/{filename}"
    await get_collection("users").update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": {"avatar_url": avatar_url, "updated_at": datetime.utcnow()}}
    )
    
    # Return updated user
    updated_user = await get_collection("users").find_one({"_id": ObjectId(current_user.id)})
    return UserResponse(**convert_user_doc(updated_user))

@router.get("/me/avatar/{filename}")
async def get_avatar(
    filename: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user avatar"""
    file_path = os.path.join(AVATAR_UPLOAD_DIR, str(current_user.id), filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Avatar not found")
    
    return FileResponse(file_path)

@router.get("/settings", response_model=dict)
async def get_user_settings(current_user: UserInDB = Depends(get_current_user)):
    """Get current user settings"""
    user = await get_collection("users").find_one({"_id": ObjectId(current_user.id)})
    return user.get("settings", {
        "push_notifications": True,
        "email_notifications": True,
        "theme": "light"
    })

@router.get("/{user_id}", response_model=UserProfileResponse)
async def get_user(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user profile by ID"""
    user = await get_collection("users").find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get user stats
    stats = {
        "memories": await get_collection("memories").count_documents({
            "owner_id": user_id,
            "$or": [
                {"privacy": "public"},
                {"owner_id": current_user.id}
            ]
        }),
        "public_files": await get_collection("files").count_documents({
            "owner_id": user_id,
            "privacy": "public"
        })
    }
    
    user_dict = {**user, "id": str(user["_id"])}
    user_dict["stats"] = stats
    return user_dict

@router.get("/", response_model=List[UserResponse])
async def list_users(
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """List users with search and pagination"""
    query = {}
    if search:
        query["$or"] = [
            {"email": {"$regex": search, "$options": "i"}},
            {"full_name": {"$regex": search, "$options": "i"}}
        ]
    
    skip = (page - 1) * limit
    cursor = get_collection("users").find(query).skip(skip).limit(limit)
    
    users = []
    async for user in cursor:
        user["id"] = str(user["_id"])
        users.append(user)
    
    return users

@router.put("/me/settings", response_model=UserResponse)
async def update_user_settings(
    settings_update: UserSettingsUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update current user settings"""
    update_data = settings_update.dict(exclude_unset=True)
    
    await get_collection("users").update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": {"settings": update_data, "updated_at": datetime.utcnow()}}
    )
    
    updated_user = await get_collection("users").find_one({"_id": ObjectId(current_user.id)})
    return UserResponse(**convert_user_doc(updated_user))

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_me(
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete current user account"""
    # Delete user's data (implement soft delete in production)
    await get_collection("users").delete_one({"_id": ObjectId(current_user.id)})
    
    # Clean up user's files (in production, consider moving to a background task)
    user_upload_dir = os.path.join("uploads/vault", str(current_user.id))
    if os.path.exists(user_upload_dir):
        shutil.rmtree(user_upload_dir)
    
    user_avatar_dir = os.path.join(AVATAR_UPLOAD_DIR, str(current_user.id))
    if os.path.exists(user_avatar_dir):
        shutil.rmtree(user_avatar_dir)
    
    return None

@router.get("/{user_id}/profile")
async def get_user_profile(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a user's full profile with recent memories and stats"""
    user_doc = await get_collection("users").find_one({"_id": ObjectId(user_id)})
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get relationship status
    relationship = await get_collection("relationships").find_one({
        "follower_id": ObjectId(current_user.id),
        "following_id": ObjectId(user_id)
    })
    
    # Get user stats
    stats = {
        "memories": await get_collection("memories").count_documents({"owner_id": ObjectId(user_id)}),
        "files": await get_collection("files").count_documents({"owner_id": ObjectId(user_id)}),
        "followers": await get_collection("relationships").count_documents({"following_id": ObjectId(user_id), "status": "accepted"}),
        "following": await get_collection("relationships").count_documents({"follower_id": ObjectId(user_id), "status": "accepted"})
    }
    
    # Get recent public/friends memories (based on privacy and relationship)
    memory_query = {"owner_id": ObjectId(user_id)}
    if str(user_id) != str(current_user.id):
        if relationship and relationship.get("status") == "accepted":
            memory_query["privacy"] = {"$in": ["public", "friends"]}
        else:
            memory_query["privacy"] = "public"
    
    cursor = get_collection("memories").find(memory_query).sort("created_at", -1).limit(10)
    
    recent_memories = []
    async for memory_doc in cursor:
        recent_memories.append({
            "id": str(memory_doc["_id"]),
            "title": memory_doc["title"],
            "content": memory_doc.get("content", "")[:200],
            "media_urls": memory_doc.get("media_urls", []),
            "tags": memory_doc.get("tags", []),
            "created_at": memory_doc["created_at"],
            "like_count": memory_doc.get("like_count", 0)
        })
    
    return {
        "id": str(user_doc["_id"]),
        "email": user_doc["email"],
        "full_name": user_doc.get("full_name"),
        "avatar_url": user_doc.get("avatar_url"),
        "bio": user_doc.get("bio"),
        "city": user_doc.get("city"),
        "country": user_doc.get("country"),
        "website": user_doc.get("website"),
        "created_at": user_doc.get("created_at"),
        "stats": stats,
        "recent_memories": recent_memories,
        "is_following": relationship is not None and relationship.get("status") == "accepted",
        "is_own_profile": str(user_id) == str(current_user.id)
    }

# Fix the get_user_profile endpoint to handle invalid ObjectIds
async def safe_object_id(id_str: str) -> ObjectId:
    """Safely convert string to ObjectId, raise 400 if invalid"""
    try:
        return ObjectId(id_str)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid ID format")
