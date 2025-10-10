from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import FileResponse
from bson import ObjectId
import os
import shutil
from pathlib import Path

from app.core.security import get_current_user, get_password_hash, oauth2_scheme
from app.db.mongodb import get_collection
from app.models.user import (
    UserInDB, UserCreate, UserUpdate, UserResponse, 
    UserProfileResponse, UserSettingsUpdate, UserRole
)

router = APIRouter()

# Configure upload directory
AVATAR_UPLOAD_DIR = "uploads/avatars"
os.makedirs(AVATAR_UPLOAD_DIR, exist_ok=True)

@router.get("/me", response_model=UserProfileResponse)
async def read_users_me(current_user: UserInDB = Depends(get_current_user)):
    """Get current user profile with stats"""
    # Get user stats
    stats = {
        "memories": await get_collection("memories").count_documents({"owner_id": current_user.id}),
        "files": await get_collection("files").count_documents({"owner_id": current_user.id}),
        "followers": await get_collection("relationships").count_documents({"following_id": current_user.id, "status": "accepted"}),
        "following": await get_collection("relationships").count_documents({"follower_id": current_user.id, "status": "accepted"})
    }
    
    user_dict = current_user.dict()
    user_dict["stats"] = stats
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
    return UserResponse(**updated_user)

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
    return UserResponse(**updated_user)

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
    return UserResponse(**updated_user)

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