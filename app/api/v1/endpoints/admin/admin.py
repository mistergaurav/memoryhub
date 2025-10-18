from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Dict, Any
from datetime import datetime, timedelta
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

async def verify_admin(current_user: UserInDB = Depends(get_current_user)):
    """Verify user is admin"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

@router.get("/stats/overview")
async def get_admin_overview(
    admin: UserInDB = Depends(verify_admin)
):
    """Get admin dashboard overview statistics"""
    total_users = await get_collection("users").count_documents({})
    total_memories = await get_collection("memories").count_documents({})
    total_files = await get_collection("files").count_documents({})
    total_collections = await get_collection("collections").count_documents({})
    total_hubs = await get_collection("hubs").count_documents({})
    
    # Active users (logged in last 24 hours - approximation based on recent activity)
    yesterday = datetime.utcnow() - timedelta(days=1)
    active_users_count = await get_collection("memories").distinct("owner_id", {
        "created_at": {"$gte": yesterday}
    })
    
    # User growth (new users last 7 days)
    week_ago = datetime.utcnow() - timedelta(days=7)
    new_users = await get_collection("users").count_documents({
        "created_at": {"$gte": week_ago}
    })
    
    # Storage stats
    storage_pipeline = [
        {"$group": {"_id": None, "total_size": {"$sum": "$file_size"}}}
    ]
    storage_result = await get_collection("files").aggregate(storage_pipeline).to_list(length=1)
    total_storage = storage_result[0]["total_size"] if storage_result else 0
    
    return {
        "users": {
            "total": total_users,
            "active_24h": len(active_users_count),
            "new_7d": new_users
        },
        "content": {
            "memories": total_memories,
            "files": total_files,
            "collections": total_collections,
            "hubs": total_hubs
        },
        "storage": {
            "total_bytes": total_storage,
            "total_gb": round(total_storage / (1024 ** 3), 2)
        }
    }

@router.get("/users")
async def list_all_users(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    search: str = Query(None),
    admin: UserInDB = Depends(verify_admin)
):
    """List all users with pagination and search"""
    query = {}
    if search:
        query["$or"] = [
            {"email": {"$regex": search, "$options": "i"}},
            {"full_name": {"$regex": search, "$options": "i"}}
        ]
    
    total = await get_collection("users").count_documents(query)
    skip = (page - 1) * limit
    
    cursor = get_collection("users").find(query).sort("created_at", -1).skip(skip).limit(limit)
    
    users = []
    async for user_doc in cursor:
        # Get user stats
        memories_count = await get_collection("memories").count_documents({"owner_id": user_doc["_id"]})
        files_count = await get_collection("files").count_documents({"owner_id": user_doc["_id"]})
        
        users.append({
            "id": str(user_doc["_id"]),
            "email": user_doc["email"],
            "full_name": user_doc.get("full_name"),
            "role": user_doc.get("role", "user"),
            "is_active": user_doc.get("is_active", True),
            "created_at": user_doc.get("created_at"),
            "stats": {
                "memories": memories_count,
                "files": files_count
            }
        })
    
    return {
        "users": users,
        "total": total,
        "page": page,
        "pages": (total + limit - 1) // limit
    }

@router.put("/users/{user_id}/role")
async def update_user_role(
    user_id: str,
    role: str = Query(..., regex="^(user|admin)$"),
    admin: UserInDB = Depends(verify_admin)
):
    """Update user role"""
    result = await get_collection("users").update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"role": role}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"message": f"User role updated to {role}"}

@router.put("/users/{user_id}/status")
async def update_user_status(
    user_id: str,
    is_active: bool,
    admin: UserInDB = Depends(verify_admin)
):
    """Activate or deactivate user"""
    result = await get_collection("users").update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"is_active": is_active}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    
    status_text = "activated" if is_active else "deactivated"
    return {"message": f"User {status_text}"}

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: str,
    admin: UserInDB = Depends(verify_admin)
):
    """Delete user and all their data"""
    user_object_id = ObjectId(user_id)
    
    # Delete user data
    await get_collection("memories").delete_many({"owner_id": user_object_id})
    await get_collection("files").delete_many({"owner_id": user_object_id})
    await get_collection("hub_items").delete_many({"owner_id": user_object_id})
    await get_collection("collections").delete_many({"owner_id": user_object_id})
    await get_collection("notifications").delete_many({"user_id": user_object_id})
    await get_collection("reminders").delete_many({"user_id": user_object_id})
    await get_collection("relationships").delete_many({
        "$or": [
            {"follower_id": user_object_id},
            {"following_id": user_object_id}
        ]
    })
    
    # Delete user
    result = await get_collection("users").delete_one({"_id": user_object_id})
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"message": "User and all data deleted"}

@router.get("/stats/activity")
async def get_activity_stats(
    period: str = Query("7d", regex="^(7d|30d|90d)$"),
    admin: UserInDB = Depends(verify_admin)
):
    """Get platform activity statistics"""
    days_map = {"7d": 7, "30d": 30, "90d": 90}
    days = days_map[period]
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # User registrations over time
    users_pipeline = [
        {"$match": {"created_at": {"$gte": start_date}}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "count": {"$sum": 1}
        }},
        {"$sort": {"_id": 1}}
    ]
    
    user_growth = await get_collection("users").aggregate(users_pipeline).to_list(length=None)
    
    # Content creation over time
    memories_pipeline = [
        {"$match": {"created_at": {"$gte": start_date}}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "count": {"$sum": 1}
        }},
        {"$sort": {"_id": 1}}
    ]
    
    content_creation = await get_collection("memories").aggregate(memories_pipeline).to_list(length=None)
    
    return {
        "period": period,
        "user_growth": [{"date": item["_id"], "count": item["count"]} for item in user_growth],
        "content_creation": [{"date": item["_id"], "count": item["count"]} for item in content_creation]
    }

@router.get("/stats/popular-tags")
async def get_popular_tags(
    limit: int = Query(20, ge=1, le=100),
    admin: UserInDB = Depends(verify_admin)
):
    """Get most popular tags across platform"""
    pipeline = [
        {"$unwind": "$tags"},
        {"$group": {"_id": "$tags", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": limit}
    ]
    
    tags_data = await get_collection("memories").aggregate(pipeline).to_list(length=None)
    
    return {
        "tags": [{"tag": item["_id"], "count": item["count"]} for item in tags_data]
    }
