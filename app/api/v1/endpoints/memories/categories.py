from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None
    color: Optional[str] = "#3B82F6"
    icon: Optional[str] = "folder"

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None

@router.post("/")
async def create_category(
    category: CategoryCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new category"""
    db = get_database()
    
    # Check if category already exists
    existing = await db.categories.find_one({
        "user_id": str(current_user.id),
        "name": category.name
    })
    
    if existing:
        raise HTTPException(status_code=400, detail="Category already exists")
    
    category_data = {
        "user_id": str(current_user.id),
        "name": category.name,
        "description": category.description,
        "color": category.color,
        "icon": category.icon,
        "memory_count": 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.categories.insert_one(category_data)
    category_data["_id"] = str(result.inserted_id)
    
    return category_data

@router.get("/")
async def get_categories(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all user categories"""
    db = get_database()
    
    categories = await db.categories.find({
        "user_id": str(current_user.id)
    }).sort("name", 1).to_list(100)
    
    for category in categories:
        category["_id"] = str(category["_id"])
    
    return categories

@router.get("/{category_id}")
async def get_category(
    category_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific category"""
    db = get_database()
    
    category = await db.categories.find_one({"_id": ObjectId(category_id)})
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    if category["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    category["_id"] = str(category["_id"])
    return category

@router.put("/{category_id}")
async def update_category(
    category_id: str,
    category: CategoryUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a category"""
    db = get_database()
    
    existing = await db.categories.find_one({"_id": ObjectId(category_id)})
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found")
    
    if existing["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    update_data = {k: v for k, v in category.dict().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()
    
    await db.categories.update_one(
        {"_id": ObjectId(category_id)},
        {"$set": update_data}
    )
    
    updated_category = await db.categories.find_one({"_id": ObjectId(category_id)})
    updated_category["_id"] = str(updated_category["_id"])
    
    return updated_category

@router.delete("/{category_id}")
async def delete_category(
    category_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a category"""
    db = get_database()
    
    category = await db.categories.find_one({"_id": ObjectId(category_id)})
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    if category["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Remove category from all memories
    await db.memories.update_many(
        {"category_id": category_id},
        {"$unset": {"category_id": ""}}
    )
    
    await db.categories.delete_one({"_id": ObjectId(category_id)})
    
    return {"message": "Category deleted"}

@router.get("/{category_id}/memories")
async def get_category_memories(
    category_id: str,
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get memories in a category"""
    db = get_database()
    
    skip = (page - 1) * limit
    memories = await db.memories.find({
        "category_id": category_id,
        "user_id": str(current_user.id)
    }).sort("created_at", -1).skip(skip).limit(limit).to_list(limit)
    
    for memory in memories:
        memory["_id"] = str(memory["_id"])
    
    return memories
