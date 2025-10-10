import os
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from bson import ObjectId
from app.db.mongodb import get_collection

async def get_hub_stats(user_id: str) -> Dict[str, Any]:
    """Get comprehensive stats for the user's hub"""
    # Get item counts
    pipeline = [
        {"$match": {"owner_id": ObjectId(user_id)}},
        {"$group": {
            "_id": "$item_type",
            "count": {"$sum": 1},
            "views": {"$sum": "$view_count"},
            "likes": {"$sum": "$like_count"}
        }}
    ]
    
    stats = {
        "total_items": 0,
        "items_by_type": {},
        "total_views": 0,
        "total_likes": 0,
        "storage_used": 0,
        "storage_quota": 1024 * 1024 * 1024  # 1GB default
    }
    
    async for doc in get_collection("hub_items").aggregate(pipeline):
        stats["items_by_type"][doc["_id"]] = doc["count"]
        stats["total_items"] += doc["count"]
        stats["total_views"] += doc.get("views", 0)
        stats["total_likes"] += doc.get("likes", 0)
    
    # Get storage used from files
    file_stats = await get_collection("files").aggregate([
        {"$match": {"owner_id": ObjectId(user_id)}},
        {"$group": {
            "_id": None,
            "total_size": {"$sum": "$file_size"},
            "count": {"$sum": 1}
        }}
    ]).to_list(1)
    
    if file_stats:
        stats["storage_used"] = file_stats[0].get("total_size", 0)
    
    return stats

async def get_recent_activity(user_id: str, limit: int = 10) -> List[Dict[str, Any]]:
    """Get recent activity across all hub items"""
    pipeline = [
        {"$match": {"owner_id": ObjectId(user_id)}},
        {"$sort": {"updated_at": -1}},
        {"$limit": limit},
        {"$lookup": {
            "from": "users",
            "localField": "owner_id",
            "foreignField": "_id",
            "as": "owner"
        }},
        {"$unwind": "$owner"},
        {"$project": {
            "id": {"$toString": "$_id"},
            "title": 1,
            "item_type": 1,
            "updated_at": 1,
            "owner_name": "$owner.full_name",
            "owner_avatar": "$owner.avatar_url"
        }}
    ]
    
    return await get_collection("hub_items").aggregate(pipeline).to_list(limit)

async def search_hub_items(
    user_id: str,
    query: str,
    item_types: Optional[List[str]] = None,
    tags: Optional[List[str]] = None,
    limit: int = 20
) -> List[Dict[str, Any]]:
    """Search hub items with text and filters"""
    match = {
        "$and": [
            {"owner_id": ObjectId(user_id)},
            {"$text": {"$search": query}}
        ]
    }
    
    if item_types:
        match["$and"].append({"item_type": {"$in": item_types}})
    if tags:
        match["$and"].append({"tags": {"$all": tags}})
    
    pipeline = [
        {"$match": match},
        {"$sort": {"score": {"$meta": "textScore"}}},
        {"$limit": limit},
        {"$project": {
            "id": {"$toString": "$_id"},
            "title": 1,
            "description": 1,
            "item_type": 1,
            "tags": 1,
            "updated_at": 1,
            "score": {"$meta": "textScore"}
        }}
    ]
    
    return await get_collection("hub_items").aggregate(pipeline).to_list(limit)