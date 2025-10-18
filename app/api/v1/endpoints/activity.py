from fastapi import APIRouter, Depends, Query
from typing import List, Dict, Any
from datetime import datetime, timedelta
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

@router.get("/feed")
async def get_activity_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get activity feed from followed users"""
    # Get users that current user follows
    relationships = await get_collection("relationships").find({
        "follower_id": ObjectId(current_user.id),
        "status": "accepted"
    }).to_list(length=None)
    
    following_ids = [rel["following_id"] for rel in relationships]
    following_ids.append(ObjectId(current_user.id))  # Include own activities
    
    activities = []
    
    # Get recent memories from followed users
    memories_cursor = get_collection("memories").find({
        "owner_id": {"$in": following_ids},
        "privacy": {"$ne": "private"}
    }).sort("created_at", -1).limit(limit)
    
    async for memory in memories_cursor:
        owner = await get_collection("users").find_one({"_id": memory["owner_id"]})
        activities.append({
            "type": "memory",
            "id": str(memory["_id"]),
            "title": memory["title"],
            "content": memory.get("content", "")[:200],
            "media_urls": memory.get("media_urls", []),
            "user_id": str(memory["owner_id"]),
            "user_name": owner.get("full_name") if owner else "Unknown",
            "user_avatar": owner.get("avatar_url"),
            "created_at": memory["created_at"]
        })
    
    # Get recent hub activities
    hub_items_cursor = get_collection("hub_items").find({
        "owner_id": {"$in": following_ids},
        "privacy": {"$ne": "private"}
    }).sort("created_at", -1).limit(limit)
    
    async for item in hub_items_cursor:
        owner = await get_collection("users").find_one({"_id": item["owner_id"]})
        activities.append({
            "type": "hub_item",
            "id": str(item["_id"]),
            "item_type": item["item_type"],
            "title": item["title"],
            "content": item.get("content", "")[:200],
            "user_id": str(item["owner_id"]),
            "user_name": owner.get("full_name") if owner else "Unknown",
            "user_avatar": owner.get("avatar_url"),
            "created_at": item["created_at"]
        })
    
    # Sort all activities by date
    activities.sort(key=lambda x: x["created_at"], reverse=True)
    
    # Paginate
    skip = (page - 1) * limit
    paginated_activities = activities[skip:skip + limit]
    
    return {
        "activities": paginated_activities,
        "total": len(activities),
        "page": page
    }

@router.get("/user/{user_id}")
async def get_user_activity(
    user_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get activity for a specific user"""
    activities = []
    
    # Get recent memories
    memories_cursor = get_collection("memories").find({
        "owner_id": ObjectId(user_id)
    }).sort("created_at", -1).limit(limit)
    
    async for memory in memories_cursor:
        activities.append({
            "type": "memory",
            "id": str(memory["_id"]),
            "title": memory["title"],
            "created_at": memory["created_at"]
        })
    
    # Get recent files
    files_cursor = get_collection("files").find({
        "owner_id": ObjectId(user_id)
    }).sort("created_at", -1).limit(limit)
    
    async for file in files_cursor:
        activities.append({
            "type": "file",
            "id": str(file["_id"]),
            "name": file["name"],
            "created_at": file["created_at"]
        })
    
    # Sort by date
    activities.sort(key=lambda x: x["created_at"], reverse=True)
    
    skip = (page - 1) * limit
    paginated_activities = activities[skip:skip + limit]
    
    return {
        "activities": paginated_activities,
        "total": len(activities),
        "page": page
    }
