from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Union
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

def safe_object_id(id_str: str) -> ObjectId:
    """Safely convert string to ObjectId, raise 400 if invalid"""
    try:
        return ObjectId(id_str)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid collection ID format")

async def _prepare_collection_response(col_doc: dict, current_user_id: str, include_memories: bool = False) -> Union[CollectionResponse, CollectionWithMemories]:
    """Prepare collection document for API response with error handling"""
    try:
        # Safely get owner information
        owner = await get_collection("users").find_one({"_id": col_doc.get("owner_id")})
        owner_name = "Unknown User"
        if owner:
            owner_name = owner.get("full_name") or owner.get("email", "Unknown User")
        
        # Count memories in collection
        memory_count = await get_collection("collection_memories").count_documents({
            "collection_id": col_doc["_id"]
        })
        
        base_data = {
            "id": str(col_doc["_id"]),
            "name": col_doc.get("name", "Untitled Collection"),
            "description": col_doc.get("description"),
            "cover_image_url": col_doc.get("cover_image_url"),
            "privacy": col_doc.get("privacy", CollectionPrivacy.PRIVATE),
            "tags": col_doc.get("tags", []),
            "owner_id": str(col_doc.get("owner_id", "")),
            "owner_name": owner_name,
            "memory_count": memory_count,
            "created_at": col_doc.get("created_at", datetime.utcnow()),
            "updated_at": col_doc.get("updated_at", datetime.utcnow()),
            "is_owner": str(col_doc.get("owner_id", "")) == current_user_id
        }
        
        if include_memories:
            try:
                memory_docs = await get_collection("collection_memories").find({
                    "collection_id": col_doc["_id"]
                }).to_list(length=None)
                
                base_data["memory_ids"] = [str(doc["memory_id"]) for doc in memory_docs if "memory_id" in doc]
                return CollectionWithMemories(**base_data)
            except Exception as e:
                # If memory fetching fails, return without memories
                base_data["memory_ids"] = []
                return CollectionWithMemories(**base_data)
        
        return CollectionResponse(**base_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error preparing collection response: {str(e)}")

@router.post("/", response_model=CollectionResponse, status_code=status.HTTP_201_CREATED)
async def create_collection(
    collection: CollectionCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new collection"""
    try:
        collection_data = {
            "name": collection.name or "Untitled Collection",
            "description": collection.description,
            "cover_image_url": collection.cover_image_url,
            "privacy": collection.privacy or CollectionPrivacy.PRIVATE,
            "tags": collection.tags or [],
            "owner_id": ObjectId(current_user.id),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("collections").insert_one(collection_data)
        col_doc = await get_collection("collections").find_one({"_id": result.inserted_id})
        
        if not col_doc:
            raise HTTPException(status_code=500, detail="Failed to create collection")
        
        return await _prepare_collection_response(col_doc, current_user.id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating collection: {str(e)}")

@router.get("/", response_model=List[CollectionResponse])
async def list_collections(
    privacy: Optional[CollectionPrivacy] = None,
    tag: Optional[str] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """List collections with filtering"""
    try:
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
            try:
                collections.append(await _prepare_collection_response(col_doc, current_user.id))
            except Exception:
                # Skip collections that fail to process
                continue
        
        return collections
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing collections: {str(e)}")

@router.get("/{collection_id}", response_model=CollectionWithMemories)
async def get_collection_detail(
    collection_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get collection details with memories"""
    try:
        col_obj_id = safe_object_id(collection_id)
        col_doc = await get_collection("collections").find_one({"_id": col_obj_id})
        
        if not col_doc:
            raise HTTPException(status_code=404, detail="Collection not found")
        
        # Check access permissions
        is_owner = str(col_doc.get("owner_id")) == current_user.id
        collection_privacy = col_doc.get("privacy", CollectionPrivacy.PRIVATE)
        
        if not is_owner and collection_privacy == CollectionPrivacy.PRIVATE:
            raise HTTPException(status_code=403, detail="Not authorized to view this collection")
        
        return await _prepare_collection_response(col_doc, current_user.id, include_memories=True)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching collection: {str(e)}")

@router.put("/{collection_id}", response_model=CollectionResponse)
async def update_collection(
    collection_id: str,
    collection_update: CollectionUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a collection"""
    try:
        col_obj_id = safe_object_id(collection_id)
        col_doc = await get_collection("collections").find_one({"_id": col_obj_id})
        
        if not col_doc:
            raise HTTPException(status_code=404, detail="Collection not found")
        
        if str(col_doc.get("owner_id")) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to edit this collection")
        
        update_data = collection_update.dict(exclude_unset=True)
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("collections").update_one(
            {"_id": col_obj_id},
            {"$set": update_data}
        )
        
        updated_doc = await get_collection("collections").find_one({"_id": col_obj_id})
        if not updated_doc:
            raise HTTPException(status_code=500, detail="Failed to update collection")
        
        return await _prepare_collection_response(updated_doc, current_user.id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating collection: {str(e)}")

@router.delete("/{collection_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_collection(
    collection_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a collection"""
    try:
        col_obj_id = safe_object_id(collection_id)
        col_doc = await get_collection("collections").find_one({"_id": col_obj_id})
        
        if not col_doc:
            raise HTTPException(status_code=404, detail="Collection not found")
        
        if str(col_doc.get("owner_id")) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this collection")
        
        # Delete collection and all memory associations
        await get_collection("collections").delete_one({"_id": col_obj_id})
        await get_collection("collection_memories").delete_many({"collection_id": col_obj_id})
        
        # Revoke all share links for this collection
        await get_collection("share_links").update_many(
            {"resource_type": "collection", "resource_id": col_obj_id},
            {"$set": {"is_active": False}}
        )
        
        return None
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting collection: {str(e)}")

@router.post("/{collection_id}/memories/{memory_id}", status_code=status.HTTP_200_OK)
async def add_memory_to_collection(
    collection_id: str,
    memory_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a memory to a collection"""
    try:
        col_obj_id = safe_object_id(collection_id)
        mem_obj_id = safe_object_id(memory_id)
        
        col_doc = await get_collection("collections").find_one({"_id": col_obj_id})
        if not col_doc:
            raise HTTPException(status_code=404, detail="Collection not found")
        
        if str(col_doc.get("owner_id")) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to modify this collection")
        
        memory_doc = await get_collection("memories").find_one({"_id": mem_obj_id})
        if not memory_doc:
            raise HTTPException(status_code=404, detail="Memory not found")
        
        # Check if memory is already in collection
        existing = await get_collection("collection_memories").find_one({
            "collection_id": col_obj_id,
            "memory_id": mem_obj_id
        })
        
        if existing:
            return {"message": "Memory already in collection"}
        
        await get_collection("collection_memories").insert_one({
            "collection_id": col_obj_id,
            "memory_id": mem_obj_id,
            "added_at": datetime.utcnow()
        })
        
        return {"message": "Memory added to collection successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error adding memory: {str(e)}")

@router.delete("/{collection_id}/memories/{memory_id}", status_code=status.HTTP_200_OK)
async def remove_memory_from_collection(
    collection_id: str,
    memory_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove a memory from a collection"""
    try:
        col_obj_id = safe_object_id(collection_id)
        mem_obj_id = safe_object_id(memory_id)
        
        col_doc = await get_collection("collections").find_one({"_id": col_obj_id})
        if not col_doc:
            raise HTTPException(status_code=404, detail="Collection not found")
        
        if str(col_doc.get("owner_id")) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to modify this collection")
        
        result = await get_collection("collection_memories").delete_one({
            "collection_id": col_obj_id,
            "memory_id": mem_obj_id
        })
        
        if result.deleted_count == 0:
            return {"message": "Memory not in collection"}
        
        return {"message": "Memory removed from collection successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error removing memory: {str(e)}")

@router.get("/{collection_id}/memories", response_model=List[dict])
async def get_collection_memories(
    collection_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all memories in a collection"""
    try:
        col_obj_id = safe_object_id(collection_id)
        col_doc = await get_collection("collections").find_one({"_id": col_obj_id})
        
        if not col_doc:
            raise HTTPException(status_code=404, detail="Collection not found")
        
        # Check access permissions
        is_owner = str(col_doc.get("owner_id")) == current_user.id
        collection_privacy = col_doc.get("privacy", CollectionPrivacy.PRIVATE)
        
        if not is_owner and collection_privacy == CollectionPrivacy.PRIVATE:
            raise HTTPException(status_code=403, detail="Not authorized to view this collection")
        
        memory_links = await get_collection("collection_memories").find({
            "collection_id": col_obj_id
        }).to_list(length=None)
        
        memories = []
        for link in memory_links:
            try:
                memory_doc = await get_collection("memories").find_one({"_id": link.get("memory_id")})
                if memory_doc:
                    owner = await get_collection("users").find_one({"_id": memory_doc.get("owner_id")})
                    
                    memories.append({
                        "id": str(memory_doc["_id"]),
                        "title": memory_doc.get("title", "Untitled"),
                        "content": memory_doc.get("content", ""),
                        "image_url": memory_doc.get("media_urls", [None])[0] if memory_doc.get("media_urls") else None,
                        "owner_name": owner.get("full_name", "Unknown") if owner else "Unknown",
                        "created_at": memory_doc.get("created_at", datetime.utcnow()).isoformat(),
                        "privacy": memory_doc.get("privacy", "private"),
                        "tags": memory_doc.get("tags", [])
                    })
            except Exception:
                # Skip memories that fail to process
                continue
        
        return memories
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching collection memories: {str(e)}")
