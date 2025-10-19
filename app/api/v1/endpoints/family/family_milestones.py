from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.family.family_milestones import (
    FamilyMilestoneCreate, FamilyMilestoneUpdate, FamilyMilestoneResponse
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



@router.post("/", response_model=FamilyMilestoneResponse, status_code=status.HTTP_201_CREATED)
async def create_milestone(
    milestone: FamilyMilestoneCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new family milestone"""
    try:
        family_circle_oids = [safe_object_id(cid) for cid in milestone.family_circle_ids if safe_object_id(cid)]
        person_oid = safe_object_id(milestone.person_id) if milestone.person_id else None
        
        person_name = None
        if person_oid:
            person = await get_collection("users").find_one({"_id": person_oid})
            if person:
                person_name = person.get("full_name")
        
        milestone_data = {
            "title": milestone.title,
            "description": milestone.description,
            "milestone_type": milestone.milestone_type,
            "milestone_date": milestone.milestone_date,
            "person_id": person_oid,
            "person_name": person_name,
            "photos": milestone.photos,
            "created_by": ObjectId(current_user.id),
            "family_circle_ids": family_circle_oids,
            "likes": [],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("family_milestones").insert_one(milestone_data)
        milestone_doc = await get_collection("family_milestones").find_one({"_id": result.inserted_id})
        
        return FamilyMilestoneResponse(
            id=str(milestone_doc["_id"]),
            title=milestone_doc["title"],
            description=milestone_doc.get("description"),
            milestone_type=milestone_doc["milestone_type"],
            milestone_date=milestone_doc["milestone_date"],
            person_id=str(milestone_doc["person_id"]) if milestone_doc.get("person_id") else None,
            person_name=milestone_doc.get("person_name"),
            photos=milestone_doc.get("photos", []),
            created_by=str(milestone_doc["created_by"]),
            created_by_name=current_user.full_name,
            family_circle_ids=[str(cid) for cid in milestone_doc.get("family_circle_ids", [])],
            likes_count=len(milestone_doc.get("likes", [])),
            created_at=milestone_doc["created_at"],
            updated_at=milestone_doc["updated_at"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create milestone: {str(e)}")


@router.get("/", response_model=List[FamilyMilestoneResponse])
async def list_milestones(
    person_id: Optional[str] = None,
    milestone_type: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """List family milestones"""
    try:
        user_oid = ObjectId(current_user.id)
        
        query = {
            "$or": [
                {"created_by": user_oid},
                {"family_circle_ids": {"$exists": True}}
            ]
        }
        
        if person_id:
            person_oid = safe_object_id(person_id)
            if person_oid:
                query["person_id"] = person_oid
        
        if milestone_type:
            query["milestone_type"] = milestone_type
        
        milestones_cursor = get_collection("family_milestones").find(query).sort("milestone_date", -1)
        
        milestones = []
        async for milestone_doc in milestones_cursor:
            creator = await get_collection("users").find_one({"_id": milestone_doc["created_by"]})
            
            milestones.append(FamilyMilestoneResponse(
                id=str(milestone_doc["_id"]),
                title=milestone_doc["title"],
                description=milestone_doc.get("description"),
                milestone_type=milestone_doc["milestone_type"],
                milestone_date=milestone_doc["milestone_date"],
                person_id=str(milestone_doc["person_id"]) if milestone_doc.get("person_id") else None,
                person_name=milestone_doc.get("person_name"),
                photos=milestone_doc.get("photos", []),
                created_by=str(milestone_doc["created_by"]),
                created_by_name=creator.get("full_name") if creator else None,
                family_circle_ids=[str(cid) for cid in milestone_doc.get("family_circle_ids", [])],
                likes_count=len(milestone_doc.get("likes", [])),
                created_at=milestone_doc["created_at"],
                updated_at=milestone_doc["updated_at"]
            ))
        
        return milestones
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list milestones: {str(e)}")


@router.get("/{milestone_id}", response_model=FamilyMilestoneResponse)
async def get_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific milestone"""
    try:
        milestone_oid = safe_object_id(milestone_id)
        if not milestone_oid:
            raise HTTPException(status_code=400, detail="Invalid milestone ID")
        
        milestone_doc = await get_collection("family_milestones").find_one({"_id": milestone_oid})
        if not milestone_doc:
            raise HTTPException(status_code=404, detail="Milestone not found")
        
        creator = await get_collection("users").find_one({"_id": milestone_doc["created_by"]})
        
        return FamilyMilestoneResponse(
            id=str(milestone_doc["_id"]),
            title=milestone_doc["title"],
            description=milestone_doc.get("description"),
            milestone_type=milestone_doc["milestone_type"],
            milestone_date=milestone_doc["milestone_date"],
            person_id=str(milestone_doc["person_id"]) if milestone_doc.get("person_id") else None,
            person_name=milestone_doc.get("person_name"),
            photos=milestone_doc.get("photos", []),
            created_by=str(milestone_doc["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in milestone_doc.get("family_circle_ids", [])],
            likes_count=len(milestone_doc.get("likes", [])),
            created_at=milestone_doc["created_at"],
            updated_at=milestone_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get milestone: {str(e)}")


@router.put("/{milestone_id}", response_model=FamilyMilestoneResponse)
async def update_milestone(
    milestone_id: str,
    milestone_update: FamilyMilestoneUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a milestone"""
    try:
        milestone_oid = safe_object_id(milestone_id)
        if not milestone_oid:
            raise HTTPException(status_code=400, detail="Invalid milestone ID")
        
        milestone_doc = await get_collection("family_milestones").find_one({"_id": milestone_oid})
        if not milestone_doc:
            raise HTTPException(status_code=404, detail="Milestone not found")
        
        if str(milestone_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this milestone")
        
        update_data = {k: v for k, v in milestone_update.dict(exclude_unset=True).items() if v is not None}
        
        if "family_circle_ids" in update_data:
            update_data["family_circle_ids"] = [safe_object_id(cid) for cid in update_data["family_circle_ids"] if safe_object_id(cid)]
        
        if "person_id" in update_data:
            person_oid = safe_object_id(update_data["person_id"])
            if person_oid:
                update_data["person_id"] = person_oid
                person = await get_collection("users").find_one({"_id": person_oid})
                if person:
                    update_data["person_name"] = person.get("full_name")
        
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("family_milestones").update_one(
            {"_id": milestone_oid},
            {"$set": update_data}
        )
        
        updated_milestone = await get_collection("family_milestones").find_one({"_id": milestone_oid})
        creator = await get_collection("users").find_one({"_id": updated_milestone["created_by"]})
        
        return FamilyMilestoneResponse(
            id=str(updated_milestone["_id"]),
            title=updated_milestone["title"],
            description=updated_milestone.get("description"),
            milestone_type=updated_milestone["milestone_type"],
            milestone_date=updated_milestone["milestone_date"],
            person_id=str(updated_milestone["person_id"]) if updated_milestone.get("person_id") else None,
            person_name=updated_milestone.get("person_name"),
            photos=updated_milestone.get("photos", []),
            created_by=str(updated_milestone["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in updated_milestone.get("family_circle_ids", [])],
            likes_count=len(updated_milestone.get("likes", [])),
            created_at=updated_milestone["created_at"],
            updated_at=updated_milestone["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update milestone: {str(e)}")


@router.delete("/{milestone_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a milestone"""
    try:
        milestone_oid = safe_object_id(milestone_id)
        if not milestone_oid:
            raise HTTPException(status_code=400, detail="Invalid milestone ID")
        
        milestone_doc = await get_collection("family_milestones").find_one({"_id": milestone_oid})
        if not milestone_doc:
            raise HTTPException(status_code=404, detail="Milestone not found")
        
        if str(milestone_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this milestone")
        
        await get_collection("family_milestones").delete_one({"_id": milestone_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete milestone: {str(e)}")


@router.post("/{milestone_id}/like", status_code=status.HTTP_200_OK)
async def like_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Like a milestone"""
    try:
        milestone_oid = safe_object_id(milestone_id)
        if not milestone_oid:
            raise HTTPException(status_code=400, detail="Invalid milestone ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_milestones").update_one(
            {"_id": milestone_oid},
            {"$addToSet": {"likes": user_oid}}
        )
        
        return {"message": "Milestone liked successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to like milestone: {str(e)}")


@router.delete("/{milestone_id}/like", status_code=status.HTTP_200_OK)
async def unlike_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Unlike a milestone"""
    try:
        milestone_oid = safe_object_id(milestone_id)
        if not milestone_oid:
            raise HTTPException(status_code=400, detail="Invalid milestone ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_milestones").update_one(
            {"_id": milestone_oid},
            {"$pull": {"likes": user_oid}}
        )
        
        return {"message": "Milestone unliked successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unlike milestone: {str(e)}")
