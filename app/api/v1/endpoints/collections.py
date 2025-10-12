from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

from app.schemas.collection import (
    CollectionCreate,
    CollectionUpdate,
    CollectionResponse,
    CollectionWithMemories,
    CollectionPrivacy
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

async def _prepare_collection_response(col_doc: dict, current_user_id: str, include_memories: bool = False) -> CollectionResponse | CollectionWithMemories:
    """Prepare collection document for API response"""
    owner = await get_collection("users").find_one({"_id": col_doc["owner_id"]})
    
    memory_count = await get_collection("collection_memories").count_documents({
        "collection_id": col_doc["_id"]
    })
    
    base_data = {
        "id": str(col_doc["_id"]),
        "name": col_doc["name"],
        "description": col_doc.get("description"),
        "cover_image_url": col_doc.get("cover_image_url"),
        "privacy": col_doc["privacy"],
        "tags": col_doc.get("tags", []),
        "owner_id": str(col_doc["owner_id"]),
        "owner_name": owner.get("full_name") if owner else "Unknown User",
        "memory_count": memory_count,
        "created_at": col_doc["created_at"],
        "updated_at": col_doc["updated_at"],
        "is_owner": str(col_doc["owner_id"]) == current_user_id
    }
    
    if include_memories:
        memory_docs = await get_collection("collection_memories").find({
            "collection_id": col_doc["_id"]
        }).to_list(length=None)
        
        base_data["memory_ids"] = [str(doc["memory_id"]) for doc in memory_docs]
        return CollectionWithMemories(**base_data)
    
    return CollectionResponse(**base_data)

@router.post("/", response_model=CollectionResponse, status_code=status.HTTP_201_CREATED)
async def create_collection(
    collection: CollectionCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new collection"""
    collection_data = {
        "name": collection.name,
        "description": collection.description,
        "cover_image_url": collection.cover_image_url,
        "privacy": collection.privacy,
        "tags": collection.tags,
        "owner_id": ObjectId(current_user.id),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await get_collection("collections").insert_one(collection_data)
    col_doc = await get_collection("collections").find_one({"_id": result.inserted_id})
    
    if not col_doc:
        raise HTTPException(status_code=500, detail="Failed to create collection")
    
    return await _prepare_collection_response(col_doc, current_user.id)

@router.get("/", response_model=List[CollectionResponse])
async def list_collections(
    privacy: Optional[CollectionPrivacy] = None,
    tag: Optional[str] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """List collections"""
    query = {"owner_id": ObjectId(current_user.id)}
    
    if privacy:
        query["privacy"] = privacy
    if tag:
        query["tags"] = tag
    if search:
        query["name"] = {"$regex": search, "$options": "i"}
    
    skip = (page - 1) * limit
    cursor = get_collection("collections").find(query).sort("updated_at", -1).skip(skip).limit(limit)
    
    collections = []
    async for col_doc in cursor:
        collections.append(await _prepare_collection_response(col_doc, current_user.id))
    
    return collections

@router.get("/{collection_id}", response_model=CollectionWithMemories)
async def get_collection_detail(
    collection_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get collection details with memories"""
    col_doc = await get_collection("collections").find_one({"_id": ObjectId(collection_id)})
    if not col_doc:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    return await _prepare_collection_response(col_doc, current_user.id, include_memories=True)

@router.put("/{collection_id}", response_model=CollectionResponse)
async def update_collection(
    collection_id: str,
    collection_update: CollectionUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a collection"""
    col_doc = await get_collection("collections").find_one({"_id": ObjectId(collection_id)})
    if not col_doc:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    if str(col_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this collection")
    
    update_data = collection_update.dict(exclude_unset=True)
    update_data["updated_at"] = datetime.utcnow()
    
    await get_collection("collections").update_one(
        {"_id": ObjectId(collection_id)},
        {"$set": update_data}
    )
    
    updated_doc = await get_collection("collections").find_one({"_id": ObjectId(collection_id)})
    if not updated_doc:
        raise HTTPException(status_code=500, detail="Failed to update collection")
    
    return await _prepare_collection_response(updated_doc, current_user.id)

@router.delete("/{collection_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_collection(
    collection_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a collection"""
    col_doc = await get_collection("collections").find_one({"_id": ObjectId(collection_id)})
    if not col_doc:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    if str(col_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this collection")
    
    await get_collection("collections").delete_one({"_id": ObjectId(collection_id)})
    await get_collection("collection_memories").delete_many({"collection_id": ObjectId(collection_id)})

@router.post("/{collection_id}/memories/{memory_id}", status_code=status.HTTP_200_OK)
async def add_memory_to_collection(
    collection_id: str,
    memory_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a memory to a collection"""
    col_doc = await get_collection("collections").find_one({"_id": ObjectId(collection_id)})
    if not col_doc:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    if str(col_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to modify this collection")
    
    memory_doc = await get_collection("memories").find_one({"_id": ObjectId(memory_id)})
    if not memory_doc:
        raise HTTPException(status_code=404, detail="Memory not found")
    
    existing = await get_collection("collection_memories").find_one({
        "collection_id": ObjectId(collection_id),
        "memory_id": ObjectId(memory_id)
    })
    
    if existing:
        return {"message": "Memory already in collection"}
    
    await get_collection("collection_memories").insert_one({
        "collection_id": ObjectId(collection_id),
        "memory_id": ObjectId(memory_id),
        "added_at": datetime.utcnow()
    })
    
    return {"message": "Memory added to collection"}

@router.delete("/{collection_id}/memories/{memory_id}", status_code=status.HTTP_200_OK)
async def remove_memory_from_collection(
    collection_id: str,
    memory_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove a memory from a collection"""
    col_doc = await get_collection("collections").find_one({"_id": ObjectId(collection_id)})
    if not col_doc:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    if str(col_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to modify this collection")
    
    result = await get_collection("collection_memories").delete_one({
        "collection_id": ObjectId(collection_id),
        "memory_id": ObjectId(memory_id)
    })
    
    if result.deleted_count == 0:
        return {"message": "Memory not in collection"}
    
    return {"message": "Memory removed from collection"}
