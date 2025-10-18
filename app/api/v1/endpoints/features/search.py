from fastapi import APIRouter, Depends, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

@router.get("/")
async def advanced_search(
    q: str = Query(..., min_length=1),
    content_type: Optional[str] = None,
    tags: Optional[List[str]] = Query(None),
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """Advanced search across all content types"""
    results = []
    
    # Search memories
    if not content_type or content_type == "memory":
        memory_query = {
            "owner_id": ObjectId(current_user.id),
            "$or": [
                {"title": {"$regex": q, "$options": "i"}},
                {"content": {"$regex": q, "$options": "i"}}
            ]
        }
        if tags:
            memory_query["tags"] = {"$in": tags}
        
        memories = await get_collection("memories").find(memory_query).limit(limit).to_list(length=None)
        for memory in memories:
            results.append({
                "type": "memory",
                "id": str(memory["_id"]),
                "title": memory["title"],
                "content": memory.get("content", "")[:200],
                "tags": memory.get("tags", []),
                "created_at": memory.get("created_at")
            })
    
    # Search files
    if not content_type or content_type == "file":
        file_query = {
            "owner_id": ObjectId(current_user.id),
            "$or": [
                {"name": {"$regex": q, "$options": "i"}},
                {"description": {"$regex": q, "$options": "i"}}
            ]
        }
        if tags:
            file_query["tags"] = {"$in": tags}
        
        files = await get_collection("files").find(file_query).limit(limit).to_list(length=None)
        for file in files:
            results.append({
                "type": "file",
                "id": str(file["_id"]),
                "name": file["name"],
                "description": file.get("description", ""),
                "tags": file.get("tags", []),
                "created_at": file.get("created_at")
            })
    
    # Search hub items
    if not content_type or content_type == "hub_item":
        hub_query = {
            "owner_id": ObjectId(current_user.id),
            "$or": [
                {"title": {"$regex": q, "$options": "i"}},
                {"content": {"$regex": q, "$options": "i"}}
            ]
        }
        if tags:
            hub_query["tags"] = {"$in": tags}
        
        hub_items = await get_collection("hub_items").find(hub_query).limit(limit).to_list(length=None)
        for item in hub_items:
            results.append({
                "type": "hub_item",
                "id": str(item["_id"]),
                "title": item["title"],
                "content": item.get("content", "")[:200],
                "tags": item.get("tags", []),
                "created_at": item.get("created_at")
            })
    
    # Search collections
    if not content_type or content_type == "collection":
        col_query = {
            "owner_id": ObjectId(current_user.id),
            "$or": [
                {"name": {"$regex": q, "$options": "i"}},
                {"description": {"$regex": q, "$options": "i"}}
            ]
        }
        if tags:
            col_query["tags"] = {"$in": tags}
        
        collections = await get_collection("collections").find(col_query).limit(limit).to_list(length=None)
        for col in collections:
            results.append({
                "type": "collection",
                "id": str(col["_id"]),
                "name": col["name"],
                "description": col.get("description", ""),
                "tags": col.get("tags", []),
                "created_at": col.get("created_at")
            })
    
    # Paginate
    skip = (page - 1) * limit
    paginated_results = results[skip:skip + limit]
    
    return {
        "results": paginated_results,
        "total": len(results),
        "page": page,
        "pages": (len(results) + limit - 1) // limit
    }

@router.get("/suggestions")
async def search_suggestions(
    q: str = Query(..., min_length=1),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get search suggestions based on query"""
    suggestions = []
    
    # Get tag suggestions
    tags_cursor = get_collection("memories").aggregate([
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$unwind": "$tags"},
        {"$match": {"tags": {"$regex": q, "$options": "i"}}},
        {"$group": {"_id": "$tags", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 5}
    ])
    
    async for tag in tags_cursor:
        suggestions.append({
            "type": "tag",
            "value": tag["_id"],
            "count": tag["count"]
        })
    
    # Get title suggestions from memories
    memories = await get_collection("memories").find({
        "owner_id": ObjectId(current_user.id),
        "title": {"$regex": q, "$options": "i"}
    }).limit(5).to_list(length=None)
    
    for memory in memories:
        suggestions.append({
            "type": "memory",
            "value": memory["title"],
            "id": str(memory["_id"])
        })
    
    return {"suggestions": suggestions}
