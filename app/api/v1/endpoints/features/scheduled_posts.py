from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

class ScheduledPostCreate(BaseModel):
    content: str
    scheduled_time: datetime
    post_type: str = "memory"  # memory, story, status
    media_urls: List[str] = []
    tags: List[str] = []
    privacy: str = "private"

@router.post("/")
async def create_scheduled_post(
    post: ScheduledPostCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a scheduled post"""
    db = get_database()
    
    # Validate scheduled time is in future
    if post.scheduled_time <= datetime.utcnow():
        raise HTTPException(status_code=400, detail="Scheduled time must be in the future")
    
    post_data = {
        **post.dict(),
        "user_id": str(current_user.id),
        "status": "scheduled",
        "created_at": datetime.utcnow()
    }
    
    result = await db.scheduled_posts.insert_one(post_data)
    post_data["_id"] = str(result.inserted_id)
    
    return post_data

@router.get("/")
async def get_scheduled_posts(
    status: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user's scheduled posts"""
    db = get_database()
    
    query = {"user_id": str(current_user.id)}
    if status:
        query["status"] = status
    
    posts = await db.scheduled_posts.find(query).sort("scheduled_time", 1).to_list(100)
    
    for post in posts:
        post["_id"] = str(post["_id"])
    
    return posts

@router.get("/{post_id}")
async def get_scheduled_post(
    post_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific scheduled post"""
    db = get_database()
    
    post = await db.scheduled_posts.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Scheduled post not found")
    
    if post["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    post["_id"] = str(post["_id"])
    return post

@router.put("/{post_id}")
async def update_scheduled_post(
    post_id: str,
    post: ScheduledPostCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a scheduled post"""
    db = get_database()
    
    existing = await db.scheduled_posts.find_one({"_id": ObjectId(post_id)})
    if not existing:
        raise HTTPException(status_code=404, detail="Scheduled post not found")
    
    if existing["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    if existing["status"] != "scheduled":
        raise HTTPException(status_code=400, detail="Can only edit scheduled posts")
    
    await db.scheduled_posts.update_one(
        {"_id": ObjectId(post_id)},
        {"$set": post.dict()}
    )
    
    updated = await db.scheduled_posts.find_one({"_id": ObjectId(post_id)})
    updated["_id"] = str(updated["_id"])
    
    return updated

@router.delete("/{post_id}")
async def delete_scheduled_post(
    post_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a scheduled post"""
    db = get_database()
    
    post = await db.scheduled_posts.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Scheduled post not found")
    
    if post["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await db.scheduled_posts.delete_one({"_id": ObjectId(post_id)})
    
    return {"message": "Scheduled post deleted"}

@router.post("/{post_id}/publish-now")
async def publish_now(
    post_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Publish a scheduled post immediately"""
    db = get_database()
    
    post = await db.scheduled_posts.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Scheduled post not found")
    
    if post["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Create the actual post based on type
    if post["post_type"] == "memory":
        memory_data = {
            "user_id": post["user_id"],
            "content": post["content"],
            "tags": post["tags"],
            "privacy": post["privacy"],
            "created_at": datetime.utcnow()
        }
        await db.memories.insert_one(memory_data)
    
    # Mark as published
    await db.scheduled_posts.update_one(
        {"_id": ObjectId(post_id)},
        {"$set": {"status": "published", "published_at": datetime.utcnow()}}
    )
    
    return {"message": "Post published"}
