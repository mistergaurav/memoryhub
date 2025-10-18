from fastapi import APIRouter, Depends
from typing import Dict, List, Optional
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

class PrivacySettings(BaseModel):
    profile_visibility: str = "public"  # public, friends, private
    memory_default_visibility: str = "private"
    show_location: bool = True
    show_online_status: bool = True
    allow_friend_requests: bool = True
    allow_tags: bool = True
    allow_comments: bool = True
    blocked_users: List[str] = []

@router.get("/settings")
async def get_privacy_settings(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user privacy settings"""
    db = get_database()
    
    user_doc = await db.users.find_one({"_id": ObjectId(current_user.id)})
    privacy = user_doc.get("privacy_settings", {})
    
    return PrivacySettings(**privacy) if privacy else PrivacySettings()

@router.put("/settings")
async def update_privacy_settings(
    settings: PrivacySettings,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update user privacy settings"""
    db = get_database()
    
    await db.users.update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": {"privacy_settings": settings.dict()}}
    )
    
    return settings

@router.post("/block/{user_id}")
async def block_user(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Block a user"""
    db = get_database()
    
    await db.users.update_one(
        {"_id": ObjectId(current_user.id)},
        {"$addToSet": {"privacy_settings.blocked_users": user_id}}
    )
    
    return {"message": "User blocked"}

@router.delete("/block/{user_id}")
async def unblock_user(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Unblock a user"""
    db = get_database()
    
    await db.users.update_one(
        {"_id": ObjectId(current_user.id)},
        {"$pull": {"privacy_settings.blocked_users": user_id}}
    )
    
    return {"message": "User unblocked"}

@router.get("/blocked")
async def get_blocked_users(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get list of blocked users"""
    db = get_database()
    
    user_doc = await db.users.find_one({"_id": ObjectId(current_user.id)})
    blocked_ids = user_doc.get("privacy_settings", {}).get("blocked_users", [])
    
    # Get user details for blocked users
    blocked_users = []
    for user_id in blocked_ids:
        user = await db.users.find_one({"_id": ObjectId(user_id)})
        if user:
            blocked_users.append({
                "id": str(user["_id"]),
                "email": user.get("email"),
                "full_name": user.get("full_name")
            })
    
    return blocked_users
