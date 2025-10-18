from fastapi import APIRouter, Depends, Query
from typing import List, Dict, Any
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

@router.get("/")
async def list_tags(
    sort_by: str = Query("count", regex="^(count|name)$"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all tags used by the user with counts"""
    # Aggregate tags from memories
    memory_tags = await get_collection("memories").aggregate([
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$unwind": "$tags"},
        {"$group": {"_id": "$tags", "count": {"$sum": 1}}},
        {"$project": {"tag": "$_id", "count": 1, "_id": 0}}
    ]).to_list(length=None)
    
    # Aggregate tags from files
    file_tags = await get_collection("files").aggregate([
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$unwind": "$tags"},
        {"$group": {"_id": "$tags", "count": {"$sum": 1}}},
        {"$project": {"tag": "$_id", "count": 1, "_id": 0}}
    ]).to_list(length=None)
    
    # Aggregate tags from hub items
    hub_tags = await get_collection("hub_items").aggregate([
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$unwind": "$tags"},
        {"$group": {"_id": "$tags", "count": {"$sum": 1}}},
        {"$project": {"tag": "$_id", "count": 1, "_id": 0}}
    ]).to_list(length=None)
    
    # Merge all tags
    tag_map: Dict[str, int] = {}
    for tag_data in memory_tags + file_tags + hub_tags:
        tag = tag_data["tag"]
        count = tag_data["count"]
        tag_map[tag] = tag_map.get(tag, 0) + count
    
    tags = [{"tag": tag, "count": count} for tag, count in tag_map.items()]
    
    # Sort
    if sort_by == "count":
        tags.sort(key=lambda x: x["count"], reverse=True)
    else:
        tags.sort(key=lambda x: x["tag"])
    
    return {"tags": tags}

@router.get("/popular")
async def get_popular_tags(
    limit: int = Query(10, ge=1, le=50),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get most popular tags"""
    tags = await list_tags("count", current_user)
    return {"tags": tags["tags"][:limit]}

@router.get("/{tag}/content")
async def get_content_by_tag(
    tag: str,
    content_type: str = Query(None, regex="^(memory|file|hub_item|collection)$"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all content with a specific tag"""
    results = []
    
    # Get memories with tag
    if not content_type or content_type == "memory":
        memories = await get_collection("memories").find({
            "owner_id": ObjectId(current_user.id),
            "tags": tag
        }).limit(limit).to_list(length=None)
        
        for memory in memories:
            results.append({
                "type": "memory",
                "id": str(memory["_id"]),
                "title": memory["title"],
                "created_at": memory.get("created_at")
            })
    
    # Get files with tag
    if not content_type or content_type == "file":
        files = await get_collection("files").find({
            "owner_id": ObjectId(current_user.id),
            "tags": tag
        }).limit(limit).to_list(length=None)
        
        for file in files:
            results.append({
                "type": "file",
                "id": str(file["_id"]),
                "name": file["name"],
                "created_at": file.get("created_at")
            })
    
    # Get hub items with tag
    if not content_type or content_type == "hub_item":
        hub_items = await get_collection("hub_items").find({
            "owner_id": ObjectId(current_user.id),
            "tags": tag
        }).limit(limit).to_list(length=None)
        
        for item in hub_items:
            results.append({
                "type": "hub_item",
                "id": str(item["_id"]),
                "title": item["title"],
                "created_at": item.get("created_at")
            })
    
    # Get collections with tag
    if not content_type or content_type == "collection":
        collections = await get_collection("collections").find({
            "owner_id": ObjectId(current_user.id),
            "tags": tag
        }).limit(limit).to_list(length=None)
        
        for col in collections:
            results.append({
                "type": "collection",
                "id": str(col["_id"]),
                "name": col["name"],
                "created_at": col.get("created_at")
            })
    
    # Paginate
    skip = (page - 1) * limit
    paginated_results = results[skip:skip + limit]
    
    return {
        "tag": tag,
        "results": paginated_results,
        "total": len(results),
        "page": page
    }

@router.put("/{tag}/rename")
async def rename_tag(
    tag: str,
    new_tag: str = Query(..., min_length=1, max_length=50),
    current_user: UserInDB = Depends(get_current_user)
):
    """Rename a tag across all content"""
    # Update memories
    await get_collection("memories").update_many(
        {"owner_id": ObjectId(current_user.id), "tags": tag},
        {"$set": {"tags.$": new_tag}}
    )
    
    # Update files
    await get_collection("files").update_many(
        {"owner_id": ObjectId(current_user.id), "tags": tag},
        {"$set": {"tags.$": new_tag}}
    )
    
    # Update hub items
    await get_collection("hub_items").update_many(
        {"owner_id": ObjectId(current_user.id), "tags": tag},
        {"$set": {"tags.$": new_tag}}
    )
    
    # Update collections
    await get_collection("collections").update_many(
        {"owner_id": ObjectId(current_user.id), "tags": tag},
        {"$set": {"tags.$": new_tag}}
    )
    
    return {"message": f"Tag '{tag}' renamed to '{new_tag}'"}

@router.delete("/{tag}")
async def delete_tag(
    tag: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a tag from all content"""
    # Remove from memories
    await get_collection("memories").update_many(
        {"owner_id": ObjectId(current_user.id)},
        {"$pull": {"tags": tag}}
    )
    
    # Remove from files
    await get_collection("files").update_many(
        {"owner_id": ObjectId(current_user.id)},
        {"$pull": {"tags": tag}}
    )
    
    # Remove from hub items
    await get_collection("hub_items").update_many(
        {"owner_id": ObjectId(current_user.id)},
        {"$pull": {"tags": tag}}
    )
    
    # Remove from collections
    await get_collection("collections").update_many(
        {"owner_id": ObjectId(current_user.id)},
        {"$pull": {"tags": tag}}
    )
    
    return {"message": f"Tag '{tag}' deleted from all content"}
