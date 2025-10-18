from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

class Location(BaseModel):
    latitude: float
    longitude: float
    address: Optional[str] = None
    place_name: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None

class PlaceCreate(BaseModel):
    name: str
    description: Optional[str] = None
    location: Location
    category: Optional[str] = None
    tags: List[str] = []

@router.post("/")
async def create_place(
    place: PlaceCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new place"""
    db = get_database()
    
    place_data = {
        **place.dict(),
        "user_id": str(current_user.id),
        "memory_count": 0,
        "created_at": datetime.utcnow()
    }
    
    result = await db.places.insert_one(place_data)
    place_data["_id"] = str(result.inserted_id)
    
    return place_data

@router.get("/")
async def get_places(
    category: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user's places"""
    db = get_database()
    
    query = {"user_id": str(current_user.id)}
    if category:
        query["category"] = category
    
    places = await db.places.find(query).sort("name", 1).to_list(100)
    
    for place in places:
        place["_id"] = str(place["_id"])
    
    return places

@router.get("/nearby")
async def get_nearby_places(
    latitude: float,
    longitude: float,
    radius: int = 10,  # km
    current_user: UserInDB = Depends(get_current_user)
):
    """Get places near a location"""
    db = get_database()
    
    # Simple distance calculation (for production, use geospatial queries)
    places = await db.places.find({
        "user_id": str(current_user.id)
    }).to_list(1000)
    
    for place in places:
        place["_id"] = str(place["_id"])
    
    # In production, filter by actual distance
    return places

@router.get("/{place_id}/memories")
async def get_place_memories(
    place_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get memories at a specific place"""
    db = get_database()
    
    memories = await db.memories.find({
        "place_id": place_id,
        "user_id": str(current_user.id)
    }).sort("created_at", -1).to_list(100)
    
    for memory in memories:
        memory["_id"] = str(memory["_id"])
    
    return memories

@router.delete("/{place_id}")
async def delete_place(
    place_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a place"""
    db = get_database()
    
    place = await db.places.find_one({"_id": ObjectId(place_id)})
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    if place["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await db.places.delete_one({"_id": ObjectId(place_id)})
    
    return {"message": "Place deleted"}
