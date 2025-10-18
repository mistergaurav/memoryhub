from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from typing import List, Optional
from datetime import datetime, timedelta
from bson import ObjectId
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

@router.post("/")
async def create_story(
    content: Optional[str] = None,
    file: UploadFile = File(None),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new story (expires in 24 hours)"""
    db = get_database()
    
    story_data = {
        "user_id": str(current_user.id),
        "content": content,
        "media_url": None,
        "media_type": None,
        "views": [],
        "created_at": datetime.utcnow(),
        "expires_at": datetime.utcnow() + timedelta(hours=24),
        "is_active": True
    }
    
    if file:
        # Save file logic here
        story_data["media_url"] = f"/stories/media/{file.filename}"
        story_data["media_type"] = file.content_type
    
    result = await db.stories.insert_one(story_data)
    story_data["_id"] = str(result.inserted_id)
    
    return story_data

@router.get("/")
async def get_stories(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get active stories from followed users"""
    db = get_database()
    
    # Get list of followed users
    user_doc = await db.users.find_one({"_id": ObjectId(current_user.id)})
    following = user_doc.get("following", [])
    following.append(str(current_user.id))  # Include own stories
    
    # Get active stories
    stories = await db.stories.find({
        "user_id": {"$in": following},
        "expires_at": {"$gt": datetime.utcnow()},
        "is_active": True
    }).sort("created_at", -1).to_list(100)
    
    for story in stories:
        story["_id"] = str(story["_id"])
    
    return stories

@router.post("/{story_id}/view")
async def mark_story_viewed(
    story_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark a story as viewed"""
    db = get_database()
    
    await db.stories.update_one(
        {"_id": ObjectId(story_id)},
        {
            "$addToSet": {"views": str(current_user.id)},
            "$inc": {"view_count": 1}
        }
    )
    
    return {"message": "Story viewed"}

@router.delete("/{story_id}")
async def delete_story(
    story_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a story"""
    db = get_database()
    
    story = await db.stories.find_one({"_id": ObjectId(story_id)})
    if not story:
        raise HTTPException(status_code=404, detail="Story not found")
    
    if story["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await db.stories.delete_one({"_id": ObjectId(story_id)})
    
    return {"message": "Story deleted"}

@router.get("/user/{user_id}")
async def get_user_stories(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get stories from a specific user"""
    db = get_database()
    
    stories = await db.stories.find({
        "user_id": user_id,
        "expires_at": {"$gt": datetime.utcnow()},
        "is_active": True
    }).sort("created_at", -1).to_list(100)
    
    for story in stories:
        story["_id"] = str(story["_id"])
    
    return stories
