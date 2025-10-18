from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Query
from bson import ObjectId

from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.models.user import UserInDB
from app.models.hub import (
    HubItemCreate, HubItemUpdate, HubItemResponse,
    HubItemType, HubItemPrivacy, HubSection, HubLayout, HubStats
)
from app.utils.hub_utils import get_hub_stats, get_recent_activity, search_hub_items

router = APIRouter()

# Alias endpoints for better API compatibility
@router.get("/", response_model=List[HubItemResponse])
async def list_hub_items_alias(
    item_type: Optional[HubItemType] = None,
    privacy: Optional[HubItemPrivacy] = None,
    tag: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """Alias for /items endpoint - list hub items"""
    return await list_hub_items(item_type, privacy, tag, search, page, limit, current_user)

@router.post("/", response_model=HubItemResponse)
async def create_hub_item_alias(
    item: HubItemCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Alias for /items endpoint - create hub item"""
    return await create_hub_item(item, current_user)

@router.get("/dashboard", response_model=Dict[str, Any])
async def get_hub_dashboard(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get hub dashboard with stats and recent activity"""
    stats = await get_hub_stats(current_user.id)
    recent_activity = await get_recent_activity(current_user.id)
    
    return {
        "stats": stats,
        "recent_activity": recent_activity,
        "quick_links": [
            {"title": "New Memory", "url": "/memories/new", "icon": "memory"},
            {"title": "Upload File", "url": "/vault/upload", "icon": "upload"},
            {"title": "Add Note", "url": "/hub/notes/new", "icon": "note"},
            {"title": "Add Task", "url": "/hub/tasks/new", "icon": "task"}
        ]
    }

@router.get("/items", response_model=List[HubItemResponse])
async def list_hub_items(
    item_type: Optional[HubItemType] = None,
    privacy: Optional[HubItemPrivacy] = None,
    tag: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """List hub items with filtering and pagination"""
    query = {"owner_id": ObjectId(current_user.id)}
    
    if item_type:
        query["item_type"] = item_type
    if privacy:
        query["privacy"] = privacy
    if tag:
        query["tags"] = tag
    if search:
        query["$text"] = {"$search": search}
    
    skip = (page - 1) * limit
    cursor = get_collection("hub_items").find(query).sort("updated_at", -1).skip(skip).limit(limit)
    
    items = []
    async for item in cursor:
        item["id"] = str(item["_id"])
        item["owner_id"] = str(item["owner_id"])
        items.append(item)
    
    return items

@router.post("/items", response_model=HubItemResponse)
async def create_hub_item(
    item: HubItemCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new hub item"""
    item_data = item.dict()
    item_data["owner_id"] = ObjectId(current_user.id)
    item_data["created_at"] = datetime.utcnow()
    item_data["updated_at"] = datetime.utcnow()
    
    result = await get_collection("hub_items").insert_one(item_data)
    created_item = await get_collection("hub_items").find_one({"_id": result.inserted_id})
    
    created_item["id"] = str(created_item["_id"])
    created_item["owner_id"] = str(created_item["owner_id"])
    return created_item

@router.get("/items/{item_id}", response_model=HubItemResponse)
async def get_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a hub item by ID"""
    item = await get_collection("hub_items").find_one({"_id": ObjectId(item_id)})
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    if str(item["owner_id"]) != current_user.id and item["privacy"] != "public":
        raise HTTPException(status_code=403, detail="Not authorized to view this item")
    
    # Increment view count
    await get_collection("hub_items").update_one(
        {"_id": ObjectId(item_id)},
        {"$inc": {"view_count": 1}}
    )
    
    item["id"] = str(item["_id"])
    item["owner_id"] = str(item["owner_id"])
    return item

@router.put("/items/{item_id}", response_model=HubItemResponse)
async def update_hub_item(
    item_id: str,
    item_update: HubItemUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a hub item"""
    item = await get_collection("hub_items").find_one({"_id": ObjectId(item_id)})
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    if str(item["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this item")
    
    update_data = item_update.dict(exclude_unset=True)
    update_data["updated_at"] = datetime.utcnow()
    
    await get_collection("hub_items").update_one(
        {"_id": ObjectId(item_id)},
        {"$set": update_data}
    )
    
    updated_item = await get_collection("hub_items").find_one({"_id": ObjectId(item_id)})
    updated_item["id"] = str(updated_item["_id"])
    updated_item["owner_id"] = str(updated_item["owner_id"])
    return updated_item

@router.delete("/items/{item_id}")
async def delete_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a hub item"""
    item = await get_collection("hub_items").find_one({"_id": ObjectId(item_id)})
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    if str(item["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this item")
    
    await get_collection("hub_items").delete_one({"_id": ObjectId(item_id)})
    return {"message": "Item deleted successfully"}

@router.get("/search", response_model=List[Dict[str, Any]])
async def search_hub(
    query: str,
    item_types: Optional[List[HubItemType]] = Query(None),
    tags: Optional[List[str]] = Query(None),
    limit: int = 10,
    current_user: UserInDB = Depends(get_current_user)
):
    """Search across all hub items"""
    return await search_hub_items(
        user_id=current_user.id,
        query=query,
        item_types=item_types,
        tags=tags,
        limit=limit
    )

@router.get("/stats", response_model=HubStats)
async def get_hub_statistics(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get hub statistics"""
    stats = await get_hub_stats(current_user.id)
    return HubStats(**stats)

@router.get("/activity", response_model=List[Dict[str, Any]])
async def get_recent_hub_activity(
    limit: int = 10,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get recent activity in the hub"""
    return await get_recent_activity(current_user.id, limit)