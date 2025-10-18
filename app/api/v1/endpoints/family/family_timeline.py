from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()
def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None



@router.get("/")
async def get_family_timeline(
    person_id: Optional[str] = None,
    circle_id: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    event_types: Optional[str] = None,
    limit: int = 100,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a comprehensive family timeline combining memories, milestones, events, and more"""
    try:
        user_oid = ObjectId(current_user.id)
        timeline_items = []
        
        base_query: Dict[str, Any] = {}
        if person_id:
            person_oid = safe_object_id(person_id)
            if person_oid:
                base_query["$or"] = [
                    {"user_id": person_oid},
                    {"created_by": person_oid},
                    {"person_id": person_oid}
                ]
        
        if circle_id:
            circle_oid = safe_object_id(circle_id)
            if circle_oid:
                base_query["family_circle_ids"] = circle_oid
        
        if start_date:
            base_query["$and"] = base_query.get("$and", [])
            base_query["$and"].append({"created_at": {"$gte": start_date}})
        
        if end_date:
            base_query["$and"] = base_query.get("$and", [])
            if "$and" in base_query:
                for cond in base_query["$and"]:
                    if "created_at" in cond:
                        cond["created_at"]["$lte"] = end_date
                        break
                else:
                    base_query["$and"].append({"created_at": {"$lte": end_date}})
            else:
                base_query["$and"] = [{"created_at": {"$lte": end_date}}]
        
        types_to_fetch = event_types.split(",") if event_types else [
            "memory", "milestone", "event", "recipe", "tradition", "album"
        ]
        
        if "memory" in types_to_fetch:
            memories_cursor = get_collection("memories").find(base_query).limit(limit)
            async for memory in memories_cursor:
                creator = await get_collection("users").find_one({"_id": memory.get("user_id")})
                timeline_items.append({
                    "id": str(memory["_id"]),
                    "type": "memory",
                    "title": memory.get("title", "Untitled Memory"),
                    "description": memory.get("content", "")[:200],
                    "date": memory.get("created_at"),
                    "person_name": creator.get("full_name") if creator else None,
                    "photos": memory.get("attachments", [])[:3],
                    "tags": memory.get("tags", [])
                })
        
        if "milestone" in types_to_fetch:
            milestones_cursor = get_collection("family_milestones").find(base_query).limit(limit)
            async for milestone in milestones_cursor:
                creator = await get_collection("users").find_one({"_id": milestone.get("created_by")})
                timeline_items.append({
                    "id": str(milestone["_id"]),
                    "type": "milestone",
                    "title": milestone.get("title"),
                    "description": milestone.get("description", "")[:200],
                    "date": milestone.get("milestone_date"),
                    "person_name": milestone.get("person_name") or (creator.get("full_name") if creator else None),
                    "photos": milestone.get("photos", [])[:3],
                    "milestone_type": milestone.get("milestone_type"),
                    "likes_count": len(milestone.get("likes", []))
                })
        
        if "event" in types_to_fetch:
            events_cursor = get_collection("family_events").find(base_query).limit(limit)
            async for event in events_cursor:
                creator = await get_collection("users").find_one({"_id": event.get("created_by")})
                timeline_items.append({
                    "id": str(event["_id"]),
                    "type": "event",
                    "title": event.get("title"),
                    "description": event.get("description", "")[:200],
                    "date": event.get("event_date"),
                    "person_name": creator.get("full_name") if creator else None,
                    "location": event.get("location"),
                    "event_type": event.get("event_type"),
                    "attendees_count": len(event.get("attendee_ids", []))
                })
        
        if "recipe" in types_to_fetch:
            recipes_cursor = get_collection("family_recipes").find(base_query).limit(limit)
            async for recipe in recipes_cursor:
                creator = await get_collection("users").find_one({"_id": recipe.get("created_by")})
                timeline_items.append({
                    "id": str(recipe["_id"]),
                    "type": "recipe",
                    "title": recipe.get("title"),
                    "description": recipe.get("description", "")[:200],
                    "date": recipe.get("created_at"),
                    "person_name": creator.get("full_name") if creator else None,
                    "photos": recipe.get("photos", [])[:3],
                    "category": recipe.get("category"),
                    "difficulty": recipe.get("difficulty")
                })
        
        if "tradition" in types_to_fetch:
            traditions_cursor = get_collection("family_traditions").find(base_query).limit(limit)
            async for tradition in traditions_cursor:
                creator = await get_collection("users").find_one({"_id": tradition.get("created_by")})
                timeline_items.append({
                    "id": str(tradition["_id"]),
                    "type": "tradition",
                    "title": tradition.get("title"),
                    "description": tradition.get("description", "")[:200],
                    "date": tradition.get("created_at"),
                    "person_name": creator.get("full_name") if creator else None,
                    "photos": tradition.get("photos", [])[:3],
                    "category": tradition.get("category"),
                    "frequency": tradition.get("frequency")
                })
        
        if "album" in types_to_fetch:
            albums_cursor = get_collection("family_albums").find(base_query).limit(limit)
            async for album in albums_cursor:
                creator = await get_collection("users").find_one({"_id": album.get("created_by")})
                timeline_items.append({
                    "id": str(album["_id"]),
                    "type": "album",
                    "title": album.get("title"),
                    "description": album.get("description", "")[:200],
                    "date": album.get("created_at"),
                    "person_name": creator.get("full_name") if creator else None,
                    "cover_photo": album.get("cover_photo"),
                    "photos_count": len(album.get("photos", []))
                })
        
        timeline_items.sort(key=lambda x: x.get("date") or datetime.min, reverse=True)
        
        timeline_items = timeline_items[:limit]
        
        return {
            "items": timeline_items,
            "total": len(timeline_items),
            "has_more": len(timeline_items) >= limit
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get timeline: {str(e)}")


@router.get("/stats")
async def get_timeline_stats(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get statistics for the family timeline"""
    try:
        user_oid = ObjectId(current_user.id)
        
        memories_count = await get_collection("memories").count_documents({"user_id": user_oid})
        milestones_count = await get_collection("family_milestones").count_documents({})
        events_count = await get_collection("family_events").count_documents({})
        recipes_count = await get_collection("family_recipes").count_documents({})
        traditions_count = await get_collection("family_traditions").count_documents({})
        albums_count = await get_collection("family_albums").count_documents({})
        
        return {
            "memories": memories_count,
            "milestones": milestones_count,
            "events": events_count,
            "recipes": recipes_count,
            "traditions": traditions_count,
            "albums": albums_count,
            "total": memories_count + milestones_count + events_count + recipes_count + traditions_count + albums_count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get timeline stats: {str(e)}")
