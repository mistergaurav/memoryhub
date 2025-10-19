from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.family.family_traditions import (
    FamilyTraditionCreate, FamilyTraditionUpdate, FamilyTraditionResponse
)
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



@router.post("/", response_model=FamilyTraditionResponse, status_code=status.HTTP_201_CREATED)
async def create_tradition(
    tradition: FamilyTraditionCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new family tradition"""
    try:
        family_circle_oids = [safe_object_id(cid) for cid in tradition.family_circle_ids if safe_object_id(cid)]
        
        tradition_data = {
            "title": tradition.title,
            "description": tradition.description,
            "category": tradition.category,
            "frequency": tradition.frequency,
            "typical_date": tradition.typical_date,
            "origin_story": tradition.origin_story,
            "instructions": tradition.instructions,
            "photos": tradition.photos,
            "videos": tradition.videos,
            "created_by": ObjectId(current_user.id),
            "family_circle_ids": family_circle_oids,
            "followers": [],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("family_traditions").insert_one(tradition_data)
        tradition_doc = await get_collection("family_traditions").find_one({"_id": result.inserted_id})
        
        return FamilyTraditionResponse(
            id=str(tradition_doc["_id"]),
            title=tradition_doc["title"],
            description=tradition_doc["description"],
            category=tradition_doc["category"],
            frequency=tradition_doc["frequency"],
            typical_date=tradition_doc.get("typical_date"),
            origin_story=tradition_doc.get("origin_story"),
            instructions=tradition_doc.get("instructions"),
            photos=tradition_doc.get("photos", []),
            videos=tradition_doc.get("videos", []),
            created_by=str(tradition_doc["created_by"]),
            created_by_name=current_user.full_name,
            family_circle_ids=[str(cid) for cid in tradition_doc.get("family_circle_ids", [])],
            followers_count=len(tradition_doc.get("followers", [])),
            created_at=tradition_doc["created_at"],
            updated_at=tradition_doc["updated_at"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create tradition: {str(e)}")


@router.get("/", response_model=List[FamilyTraditionResponse])
async def list_traditions(
    category: Optional[str] = None,
    frequency: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """List family traditions"""
    try:
        query = {}
        
        if category:
            query["category"] = category
        if frequency:
            query["frequency"] = frequency
        
        traditions_cursor = get_collection("family_traditions").find(query).sort("created_at", -1)
        
        traditions = []
        async for tradition_doc in traditions_cursor:
            creator = await get_collection("users").find_one({"_id": tradition_doc["created_by"]})
            
            traditions.append(FamilyTraditionResponse(
                id=str(tradition_doc["_id"]),
                title=tradition_doc["title"],
                description=tradition_doc["description"],
                category=tradition_doc["category"],
                frequency=tradition_doc["frequency"],
                typical_date=tradition_doc.get("typical_date"),
                origin_story=tradition_doc.get("origin_story"),
                instructions=tradition_doc.get("instructions"),
                photos=tradition_doc.get("photos", []),
                videos=tradition_doc.get("videos", []),
                created_by=str(tradition_doc["created_by"]),
                created_by_name=creator.get("full_name") if creator else None,
                family_circle_ids=[str(cid) for cid in tradition_doc.get("family_circle_ids", [])],
                followers_count=len(tradition_doc.get("followers", [])),
                created_at=tradition_doc["created_at"],
                updated_at=tradition_doc["updated_at"]
            ))
        
        return traditions
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list traditions: {str(e)}")


@router.get("/{tradition_id}", response_model=FamilyTraditionResponse)
async def get_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific tradition"""
    try:
        tradition_oid = safe_object_id(tradition_id)
        if not tradition_oid:
            raise HTTPException(status_code=400, detail="Invalid tradition ID")
        
        tradition_doc = await get_collection("family_traditions").find_one({"_id": tradition_oid})
        if not tradition_doc:
            raise HTTPException(status_code=404, detail="Tradition not found")
        
        creator = await get_collection("users").find_one({"_id": tradition_doc["created_by"]})
        
        return FamilyTraditionResponse(
            id=str(tradition_doc["_id"]),
            title=tradition_doc["title"],
            description=tradition_doc["description"],
            category=tradition_doc["category"],
            frequency=tradition_doc["frequency"],
            typical_date=tradition_doc.get("typical_date"),
            origin_story=tradition_doc.get("origin_story"),
            instructions=tradition_doc.get("instructions"),
            photos=tradition_doc.get("photos", []),
            videos=tradition_doc.get("videos", []),
            created_by=str(tradition_doc["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in tradition_doc.get("family_circle_ids", [])],
            followers_count=len(tradition_doc.get("followers", [])),
            created_at=tradition_doc["created_at"],
            updated_at=tradition_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get tradition: {str(e)}")


@router.put("/{tradition_id}", response_model=FamilyTraditionResponse)
async def update_tradition(
    tradition_id: str,
    tradition_update: FamilyTraditionUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a tradition"""
    try:
        tradition_oid = safe_object_id(tradition_id)
        if not tradition_oid:
            raise HTTPException(status_code=400, detail="Invalid tradition ID")
        
        tradition_doc = await get_collection("family_traditions").find_one({"_id": tradition_oid})
        if not tradition_doc:
            raise HTTPException(status_code=404, detail="Tradition not found")
        
        if str(tradition_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this tradition")
        
        update_data = {k: v for k, v in tradition_update.dict(exclude_unset=True).items() if v is not None}
        
        if "family_circle_ids" in update_data:
            update_data["family_circle_ids"] = [safe_object_id(cid) for cid in update_data["family_circle_ids"] if safe_object_id(cid)]
        
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("family_traditions").update_one(
            {"_id": tradition_oid},
            {"$set": update_data}
        )
        
        updated_tradition = await get_collection("family_traditions").find_one({"_id": tradition_oid})
        creator = await get_collection("users").find_one({"_id": updated_tradition["created_by"]})
        
        return FamilyTraditionResponse(
            id=str(updated_tradition["_id"]),
            title=updated_tradition["title"],
            description=updated_tradition["description"],
            category=updated_tradition["category"],
            frequency=updated_tradition["frequency"],
            typical_date=updated_tradition.get("typical_date"),
            origin_story=updated_tradition.get("origin_story"),
            instructions=updated_tradition.get("instructions"),
            photos=updated_tradition.get("photos", []),
            videos=updated_tradition.get("videos", []),
            created_by=str(updated_tradition["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in updated_tradition.get("family_circle_ids", [])],
            followers_count=len(updated_tradition.get("followers", [])),
            created_at=updated_tradition["created_at"],
            updated_at=updated_tradition["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update tradition: {str(e)}")


@router.delete("/{tradition_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a tradition"""
    try:
        tradition_oid = safe_object_id(tradition_id)
        if not tradition_oid:
            raise HTTPException(status_code=400, detail="Invalid tradition ID")
        
        tradition_doc = await get_collection("family_traditions").find_one({"_id": tradition_oid})
        if not tradition_doc:
            raise HTTPException(status_code=404, detail="Tradition not found")
        
        if str(tradition_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this tradition")
        
        await get_collection("family_traditions").delete_one({"_id": tradition_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete tradition: {str(e)}")


@router.post("/{tradition_id}/follow", status_code=status.HTTP_200_OK)
async def follow_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Follow a tradition"""
    try:
        tradition_oid = safe_object_id(tradition_id)
        if not tradition_oid:
            raise HTTPException(status_code=400, detail="Invalid tradition ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_traditions").update_one(
            {"_id": tradition_oid},
            {"$addToSet": {"followers": user_oid}}
        )
        
        return {"message": "Now following this tradition"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to follow tradition: {str(e)}")


@router.delete("/{tradition_id}/follow", status_code=status.HTTP_200_OK)
async def unfollow_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Unfollow a tradition"""
    try:
        tradition_oid = safe_object_id(tradition_id)
        if not tradition_oid:
            raise HTTPException(status_code=400, detail="Invalid tradition ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_traditions").update_one(
            {"_id": tradition_oid},
            {"$pull": {"followers": user_oid}}
        )
        
        return {"message": "Unfollowed tradition"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unfollow tradition: {str(e)}")
