import os
import json
from datetime import datetime
from typing import List, Optional
from fastapi import (
    APIRouter, Depends, HTTPException, status, 
    UploadFile, File, Form, Query
)
from fastapi.responses import FileResponse
from bson import ObjectId
import shutil
import uuid

from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.models.memory import (
    MemoryCreate, MemoryInDB, MemoryUpdate, 
    MemoryResponse, MemorySearchParams, MemoryPrivacy
)
from app.models.user import UserInDB
from app.utils.memory_utils import (
    process_memory_search_filters, 
    get_sort_params,
    increment_memory_counter
)
from app.core.config import settings

router = APIRouter()

# Configure upload directory
UPLOAD_DIR = "uploads/memories"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/", response_model=MemoryInDB)
async def create_memory(
    title: str = Form(...),
    content: str = Form(...),
    tags: str = Form("[]"),  # Accept tags as JSON string
    privacy: MemoryPrivacy = Form(MemoryPrivacy.PRIVATE),
    location: Optional[str] = Form(None),
    mood: Optional[str] = Form(None),
    files: List[UploadFile] = File([]),
    current_user: UserInDB = Depends(get_current_user)
):
    # Parse tags from JSON string
    try:
        tags_list = json.loads(tags) if tags else []
    except json.JSONDecodeError:
        tags_list = []
    
    # Save uploaded files
    media_urls = []
    for file in files:
        if file.filename:
            file_extension = os.path.splitext(file.filename)[1]
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            file_path = os.path.join(UPLOAD_DIR, unique_filename)
            
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            
            media_url = f"/api/v1/memories/media/{unique_filename}"
            media_urls.append(media_url)
    
    # Create memory
    memory_data = {
        "title": title,
        "content": content,
        "tags": tags_list,
        "privacy": privacy,
        "media_urls": media_urls,
        "owner_id": ObjectId(current_user.id),
        "mood": mood
    }
    
    if location:
        try:
            lat, lng = map(float, location.split(','))
            memory_data["location"] = {"lat": lat, "lng": lng}
        except:
            pass
    
    result = await get_collection("memories").insert_one(memory_data)
    memory = await get_collection("memories").find_one({"_id": result.inserted_id})
    return await _prepare_memory_response(memory, current_user.id)

@router.get("/media/{filename}")
async def get_media(filename: str):
    file_path = os.path.join(UPLOAD_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path)

@router.get("/search/", response_model=List[MemoryResponse])
async def search_memories(
    query: Optional[str] = None,
    tags: Optional[List[str]] = Query(None),
    privacy: Optional[MemoryPrivacy] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    sort_by: str = "created_at",
    sort_order: str = "desc",
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    search_params = {
        "query": query,
        "tags": tags,
        "privacy": privacy,
        "start_date": start_date,
        "end_date": end_date,
        "sort_by": sort_by,
        "sort_order": sort_order,
        "page": page,
        "limit": limit
    }
    
    filters = await process_memory_search_filters(search_params, current_user.id)
    sort = get_sort_params(sort_by, sort_order)
    
    skip = (page - 1) * limit
    cursor = get_collection("memories").find(filters).sort(sort).skip(skip).limit(limit)
    
    memories = []
    async for memory in cursor:
        memories.append(await _prepare_memory_response(memory, current_user.id))
    
    return memories

@router.get("/{memory_id}", response_model=MemoryResponse)
async def get_memory(
    memory_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    memory = await get_collection("memories").find_one({"_id": ObjectId(memory_id)})
    if not memory:
        raise HTTPException(status_code=404, detail="Memory not found")
    
    # Increment view count
    await increment_memory_counter(memory_id, "view_count")
    
    return await _prepare_memory_response(memory, current_user.id)

async def _prepare_memory_response(memory: dict, current_user_id: str) -> dict:
    memory["id"] = str(memory["_id"])
    memory["owner_id"] = str(memory["owner_id"])
    
    # Add additional user data
    user = await get_collection("users").find_one({"_id": ObjectId(memory["owner_id"])})
    if user:
        memory["owner_name"] = user.get("full_name")
        memory["owner_avatar"] = user.get("avatar_url")
    
    # Check if current user has liked or bookmarked this memory
    memory["is_liked"] = await get_collection("likes").find_one({
        "memory_id": ObjectId(memory["_id"]),
        "user_id": ObjectId(current_user_id)
    }) is not None
    
    memory["is_bookmarked"] = await get_collection("bookmarks").find_one({
        "memory_id": ObjectId(memory["_id"]),
        "user_id": ObjectId(current_user_id)
    }) is not None
    
    return memory

# Add more endpoints for likes, comments, bookmarks, etc.
@router.post("/{memory_id}/like")
async def like_memory(
    memory_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    # Check if already liked
    existing_like = await get_collection("likes").find_one({
        "memory_id": ObjectId(memory_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if existing_like:
        # Unlike
        await get_collection("likes").delete_one({"_id": existing_like["_id"]})
        await increment_memory_counter(memory_id, "like_count", -1)
        return {"liked": False}
    else:
        # Like
        await get_collection("likes").insert_one({
            "memory_id": ObjectId(memory_id),
            "user_id": ObjectId(current_user.id),
            "created_at": datetime.utcnow()
        })
        await increment_memory_counter(memory_id, "like_count", 1)
        return {"liked": True}

@router.post("/{memory_id}/bookmark")
async def bookmark_memory(
    memory_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    # Check if already bookmarked
    existing_bookmark = await get_collection("bookmarks").find_one({
        "memory_id": ObjectId(memory_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if existing_bookmark:
        # Remove bookmark
        await get_collection("bookmarks").delete_one({"_id": existing_bookmark["_id"]})
        return {"bookmarked": False}
    else:
        # Add bookmark
        await get_collection("bookmarks").insert_one({
            "memory_id": ObjectId(memory_id),
            "user_id": ObjectId(current_user.id),
            "created_at": datetime.utcnow()
        })
        return {"bookmarked": True}

# Add more endpoints as needed...