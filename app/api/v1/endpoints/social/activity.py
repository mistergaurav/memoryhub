from fastapi import APIRouter, Depends, Query
from typing import List, Dict, Any
from datetime import datetime, timedelta
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

# Register both routes to handle with and without trailing slash
@router.get("/")
async def get_activity(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get activity feed (alias for /feed endpoint for frontend compatibility)"""
    return await get_activity_feed(page=page, limit=limit, current_user=current_user)


@router.get("/feed")
async def get_activity_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get activity feed from followed users using MongoDB aggregation"""
    current_user_id = ObjectId(current_user.id)
    
    # 1. Get users that current user follows
    relationships = await get_collection("relationships").find({
        "follower_id": current_user_id,
        "status": "accepted"
    }).to_list(length=None)
    following_ids = [rel["following_id"] for rel in relationships]
    
    # 2. Get family members
    family_rels = await get_collection("family_relationships").find({
        "user_id": current_user_id
    }).to_list(length=None)
    family_ids = [rel["related_user_id"] for rel in family_rels]
    
    # 3. Get circles user is a member of
    my_circles = await get_collection("family_circles").find({
        "member_ids": current_user_id
    }).to_list(length=None)
    my_circle_ids = [str(circle["_id"]) for circle in my_circles]
    
    skip = (page - 1) * limit
    
    # Complex match condition for memories
    memory_match = {
        "$or": [
            # 1. Own memories
            {"owner_id": current_user_id},
            
            # 2. Public/Friends memories from people I follow
            {
                "owner_id": {"$in": following_ids},
                "privacy": {"$in": ["public", "friends"]} 
            },
            
            # 3. Family memories from relatives
            {
                "owner_id": {"$in": family_ids},
                "privacy": "family"
            },
            
            # 4. Circle memories
            {
                "family_circle_ids": {"$in": my_circle_ids},
                "privacy": "family_circle"
            },
            
            # 5. Specific users (shared with me)
            {
                "allowed_user_ids": str(current_user_id),
                "privacy": "specific_users"
            }
        ]
    }

    # Use MongoDB aggregation with $unionWith and $facet for accurate pagination
    pipeline = [
        {
            "$match": memory_match
        },
        {
            "$addFields": {
                "type": "memory"
            }
        },
        {
            "$unionWith": {
                "coll": "hub_items",
                "pipeline": [
                    {
                        "$match": {
                            "owner_id": {"$in": following_ids},
                            "privacy": {"$ne": "private"}
                        }
                    },
                    {
                        "$addFields": {
                            "type": "hub_item"
                        }
                    }
                ]
            }
        },
        {
            "$sort": {"created_at": -1}
        },
        {
            "$facet": {
                "metadata": [
                    {"$count": "total"}
                ],
                "data": [
                    {"$skip": skip},
                    {"$limit": limit + 1}  # Fetch one extra to check has_more
                ]
            }
        }
    ]
    
    result = await get_collection("memories").aggregate(pipeline).to_list(length=1)
    
    if not result:
        return {
            "activities": [],
            "total": 0,
            "page": page,
            "has_more": False
        }
    
    total_count = result[0]["metadata"][0]["total"] if result[0]["metadata"] else 0
    items = result[0]["data"]
    
    # Check if there are more results
    has_more = len(items) > limit
    # Trim to requested limit
    if has_more:
        items = items[:limit]
    
    activities = []
    for item in items:
        owner = await get_collection("users").find_one({"_id": item["owner_id"]})
        activity_data = {
            "type": item["type"],
            "id": str(item["_id"]),
            "user_id": str(item["owner_id"]),
            "user_name": owner.get("full_name") if owner is not None else "Unknown",
            "user_avatar": owner.get("avatar_url") if owner is not None else None,
            "created_at": item["created_at"]
        }
        
        if item["type"] == "memory":
            activity_data.update({
                "title": item["title"],
                "content": item.get("content", "")[:200],
                "media_urls": item.get("media_urls", [])
            })
        else:  # hub_item
            activity_data.update({
                "item_type": item["item_type"],
                "title": item["title"],
                "content": item.get("content", "")[:200]
            })
        
        activities.append(activity_data)
    
    return {
        "activities": activities,
        "total": total_count,
        "page": page,
        "has_more": has_more
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
