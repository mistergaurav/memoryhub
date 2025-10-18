from fastapi import APIRouter, Depends, Query
from typing import Dict, Any, List
from datetime import datetime, timedelta
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

@router.get("/overview")
async def get_analytics_overview(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get analytics overview with key metrics"""
    # Count all content types
    memories_count = await get_collection("memories").count_documents({"owner_id": ObjectId(current_user.id)})
    files_count = await get_collection("files").count_documents({"owner_id": ObjectId(current_user.id)})
    hub_items_count = await get_collection("hub_items").count_documents({"owner_id": ObjectId(current_user.id)})
    collections_count = await get_collection("collections").count_documents({"owner_id": ObjectId(current_user.id)})
    
    # Count social metrics
    followers_count = await get_collection("relationships").count_documents({
        "following_id": ObjectId(current_user.id),
        "status": "accepted"
    })
    following_count = await get_collection("relationships").count_documents({
        "follower_id": ObjectId(current_user.id),
        "status": "accepted"
    })
    
    # Get total storage used
    storage_pipeline = [
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$group": {"_id": None, "total_size": {"$sum": "$file_size"}}}
    ]
    storage_result = await get_collection("files").aggregate(storage_pipeline).to_list(length=1)
    total_storage = storage_result[0]["total_size"] if storage_result else 0
    
    return {
        "content": {
            "memories": memories_count,
            "files": files_count,
            "hub_items": hub_items_count,
            "collections": collections_count
        },
        "social": {
            "followers": followers_count,
            "following": following_count
        },
        "storage": {
            "used_bytes": total_storage,
            "used_mb": round(total_storage / (1024 * 1024), 2)
        }
    }

@router.get("/activity-chart")
async def get_activity_chart(
    period: str = Query("30d", regex="^(7d|30d|90d|1y)$"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get activity chart data for a period"""
    days_map = {"7d": 7, "30d": 30, "90d": 90, "1y": 365}
    days = days_map[period]
    
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # Get memories created per day
    memories_pipeline = [
        {"$match": {
            "owner_id": ObjectId(current_user.id),
            "created_at": {"$gte": start_date}
        }},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "count": {"$sum": 1}
        }},
        {"$sort": {"_id": 1}}
    ]
    
    memories_data = await get_collection("memories").aggregate(memories_pipeline).to_list(length=None)
    
    # Get files uploaded per day
    files_pipeline = [
        {"$match": {
            "owner_id": ObjectId(current_user.id),
            "created_at": {"$gte": start_date}
        }},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "count": {"$sum": 1}
        }},
        {"$sort": {"_id": 1}}
    ]
    
    files_data = await get_collection("files").aggregate(files_pipeline).to_list(length=None)
    
    return {
        "period": period,
        "memories": [{"date": item["_id"], "count": item["count"]} for item in memories_data],
        "files": [{"date": item["_id"], "count": item["count"]} for item in files_data]
    }

@router.get("/top-tags")
async def get_top_tags(
    limit: int = Query(10, ge=1, le=50),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get most used tags"""
    pipeline = [
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$unwind": "$tags"},
        {"$group": {"_id": "$tags", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": limit}
    ]
    
    tags_data = await get_collection("memories").aggregate(pipeline).to_list(length=None)
    
    return {
        "tags": [{"tag": item["_id"], "count": item["count"]} for item in tags_data]
    }

@router.get("/mood-trends")
async def get_mood_trends(
    period: str = Query("30d", regex="^(7d|30d|90d)$"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get mood trends over time"""
    days_map = {"7d": 7, "30d": 30, "90d": 90}
    days = days_map[period]
    
    start_date = datetime.utcnow() - timedelta(days=days)
    
    pipeline = [
        {"$match": {
            "owner_id": ObjectId(current_user.id),
            "mood": {"$exists": True, "$ne": None},
            "created_at": {"$gte": start_date}
        }},
        {"$group": {
            "_id": "$mood",
            "count": {"$sum": 1}
        }},
        {"$sort": {"count": -1}}
    ]
    
    mood_data = await get_collection("memories").aggregate(pipeline).to_list(length=None)
    
    return {
        "period": period,
        "moods": [{"mood": item["_id"], "count": item["count"]} for item in mood_data]
    }

@router.get("/storage-breakdown")
async def get_storage_breakdown(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get storage breakdown by file type"""
    pipeline = [
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$group": {
            "_id": "$file_type",
            "total_size": {"$sum": "$file_size"},
            "count": {"$sum": 1}
        }},
        {"$sort": {"total_size": -1}}
    ]
    
    storage_data = await get_collection("files").aggregate(pipeline).to_list(length=None)
    
    return {
        "breakdown": [
            {
                "file_type": item["_id"] or "unknown",
                "total_size_bytes": item["total_size"],
                "total_size_mb": round(item["total_size"] / (1024 * 1024), 2),
                "count": item["count"]
            }
            for item in storage_data
        ]
    }
