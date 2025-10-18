from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from bson import ObjectId
from datetime import datetime

from app.models.parental_controls import (
    ParentalControlSettingsCreate, ParentalControlSettingsUpdate,
    ParentalControlSettingsResponse, ContentApprovalRequest,
    ContentApprovalRequestResponse, ApprovalDecision
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

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None



@router.post("/settings", response_model=ParentalControlSettingsResponse, status_code=status.HTTP_201_CREATED)
async def create_parental_controls(
    settings: ParentalControlSettingsCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create parental control settings for a child"""
    try:
        child_oid = safe_object_id(settings.child_user_id)
        if not child_oid:
            raise HTTPException(status_code=400, detail="Invalid child user ID")
        
        child_user = await get_collection("users").find_one({"_id": child_oid})
        if not child_user:
            raise HTTPException(status_code=404, detail="Child user not found")
        
        existing = await get_collection("parental_controls").find_one({
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid
        })
        
        if existing:
            raise HTTPException(status_code=400, detail="Parental controls already exist for this child")
        
        settings_data = {
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid,
            "content_rating_limit": settings.content_rating_limit,
            "require_approval_for_posts": settings.require_approval_for_posts,
            "require_approval_for_sharing": settings.require_approval_for_sharing,
            "restrict_external_contacts": settings.restrict_external_contacts,
            "allowed_features": settings.allowed_features,
            "screen_time_limit_minutes": settings.screen_time_limit_minutes,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("parental_controls").insert_one(settings_data)
        settings_doc = await get_collection("parental_controls").find_one({"_id": result.inserted_id})
        
        return ParentalControlSettingsResponse(
            id=str(settings_doc["_id"]),
            parent_user_id=str(settings_doc["parent_user_id"]),
            child_user_id=str(settings_doc["child_user_id"]),
            child_name=child_user.get("full_name"),
            content_rating_limit=settings_doc["content_rating_limit"],
            require_approval_for_posts=settings_doc["require_approval_for_posts"],
            require_approval_for_sharing=settings_doc["require_approval_for_sharing"],
            restrict_external_contacts=settings_doc["restrict_external_contacts"],
            allowed_features=settings_doc["allowed_features"],
            screen_time_limit_minutes=settings_doc.get("screen_time_limit_minutes"),
            created_at=settings_doc["created_at"],
            updated_at=settings_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create parental controls: {str(e)}")


@router.get("/settings", response_model=List[ParentalControlSettingsResponse])
async def list_parental_controls(
    current_user: UserInDB = Depends(get_current_user)
):
    """List all parental control settings created by the current user"""
    try:
        user_oid = ObjectId(current_user.id)
        
        settings_cursor = get_collection("parental_controls").find({
            "parent_user_id": user_oid
        })
        
        settings_list = []
        async for settings_doc in settings_cursor:
            child_user = await get_collection("users").find_one({"_id": settings_doc["child_user_id"]})
            
            settings_list.append(ParentalControlSettingsResponse(
                id=str(settings_doc["_id"]),
                parent_user_id=str(settings_doc["parent_user_id"]),
                child_user_id=str(settings_doc["child_user_id"]),
                child_name=child_user.get("full_name") if child_user else None,
                content_rating_limit=settings_doc["content_rating_limit"],
                require_approval_for_posts=settings_doc["require_approval_for_posts"],
                require_approval_for_sharing=settings_doc["require_approval_for_sharing"],
                restrict_external_contacts=settings_doc["restrict_external_contacts"],
                allowed_features=settings_doc["allowed_features"],
                screen_time_limit_minutes=settings_doc.get("screen_time_limit_minutes"),
                created_at=settings_doc["created_at"],
                updated_at=settings_doc["updated_at"]
            ))
        
        return settings_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list parental controls: {str(e)}")


@router.get("/settings/{child_user_id}", response_model=ParentalControlSettingsResponse)
async def get_parental_controls(
    child_user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get parental control settings for a specific child"""
    try:
        child_oid = safe_object_id(child_user_id)
        if not child_oid:
            raise HTTPException(status_code=400, detail="Invalid child user ID")
        
        settings_doc = await get_collection("parental_controls").find_one({
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid
        })
        
        if not settings_doc:
            raise HTTPException(status_code=404, detail="Parental controls not found for this child")
        
        child_user = await get_collection("users").find_one({"_id": child_oid})
        
        return ParentalControlSettingsResponse(
            id=str(settings_doc["_id"]),
            parent_user_id=str(settings_doc["parent_user_id"]),
            child_user_id=str(settings_doc["child_user_id"]),
            child_name=child_user.get("full_name") if child_user else None,
            content_rating_limit=settings_doc["content_rating_limit"],
            require_approval_for_posts=settings_doc["require_approval_for_posts"],
            require_approval_for_sharing=settings_doc["require_approval_for_sharing"],
            restrict_external_contacts=settings_doc["restrict_external_contacts"],
            allowed_features=settings_doc["allowed_features"],
            screen_time_limit_minutes=settings_doc.get("screen_time_limit_minutes"),
            created_at=settings_doc["created_at"],
            updated_at=settings_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get parental controls: {str(e)}")


@router.put("/settings/{child_user_id}", response_model=ParentalControlSettingsResponse)
async def update_parental_controls(
    child_user_id: str,
    settings_update: ParentalControlSettingsUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update parental control settings"""
    try:
        child_oid = safe_object_id(child_user_id)
        if not child_oid:
            raise HTTPException(status_code=400, detail="Invalid child user ID")
        
        settings_doc = await get_collection("parental_controls").find_one({
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid
        })
        
        if not settings_doc:
            raise HTTPException(status_code=404, detail="Parental controls not found for this child")
        
        update_data = {k: v for k, v in settings_update.dict(exclude_unset=True).items() if v is not None}
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("parental_controls").update_one(
            {"_id": settings_doc["_id"]},
            {"$set": update_data}
        )
        
        updated_settings = await get_collection("parental_controls").find_one({"_id": settings_doc["_id"]})
        child_user = await get_collection("users").find_one({"_id": child_oid})
        
        return ParentalControlSettingsResponse(
            id=str(updated_settings["_id"]),
            parent_user_id=str(updated_settings["parent_user_id"]),
            child_user_id=str(updated_settings["child_user_id"]),
            child_name=child_user.get("full_name") if child_user else None,
            content_rating_limit=updated_settings["content_rating_limit"],
            require_approval_for_posts=updated_settings["require_approval_for_posts"],
            require_approval_for_sharing=updated_settings["require_approval_for_sharing"],
            restrict_external_contacts=updated_settings["restrict_external_contacts"],
            allowed_features=updated_settings["allowed_features"],
            screen_time_limit_minutes=updated_settings.get("screen_time_limit_minutes"),
            created_at=updated_settings["created_at"],
            updated_at=updated_settings["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update parental controls: {str(e)}")


@router.delete("/settings/{child_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_parental_controls(
    child_user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete parental control settings"""
    try:
        child_oid = safe_object_id(child_user_id)
        if not child_oid:
            raise HTTPException(status_code=400, detail="Invalid child user ID")
        
        result = await get_collection("parental_controls").delete_one({
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid
        })
        
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Parental controls not found for this child")
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete parental controls: {str(e)}")


@router.post("/approval-requests", response_model=ContentApprovalRequestResponse, status_code=status.HTTP_201_CREATED)
async def create_approval_request(
    request: ContentApprovalRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a content approval request (by child)"""
    try:
        content_oid = safe_object_id(request.content_id)
        if not content_oid:
            raise HTTPException(status_code=400, detail="Invalid content ID")
        
        child_oid = ObjectId(current_user.id)
        
        settings_doc = await get_collection("parental_controls").find_one({
            "child_user_id": child_oid
        })
        
        if not settings_doc:
            raise HTTPException(status_code=404, detail="No parental controls found")
        
        request_data = {
            "child_user_id": child_oid,
            "parent_user_id": settings_doc["parent_user_id"],
            "content_type": request.content_type,
            "content_id": content_oid,
            "content_title": request.content_title,
            "content_preview": request.content_preview,
            "status": "pending",
            "parent_notes": None,
            "created_at": datetime.utcnow(),
            "reviewed_at": None
        }
        
        result = await get_collection("approval_requests").insert_one(request_data)
        request_doc = await get_collection("approval_requests").find_one({"_id": result.inserted_id})
        
        return ContentApprovalRequestResponse(
            id=str(request_doc["_id"]),
            child_user_id=str(request_doc["child_user_id"]),
            child_name=current_user.full_name,
            parent_user_id=str(request_doc["parent_user_id"]),
            content_type=request_doc["content_type"],
            content_id=str(request_doc["content_id"]),
            content_title=request_doc.get("content_title"),
            content_preview=request_doc.get("content_preview"),
            status=request_doc["status"],
            parent_notes=request_doc.get("parent_notes"),
            created_at=request_doc["created_at"],
            reviewed_at=request_doc.get("reviewed_at")
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create approval request: {str(e)}")


@router.get("/approval-requests/pending", response_model=List[ContentApprovalRequestResponse])
async def list_pending_approval_requests(
    current_user: UserInDB = Depends(get_current_user)
):
    """List pending approval requests for parent"""
    try:
        user_oid = ObjectId(current_user.id)
        
        requests_cursor = get_collection("approval_requests").find({
            "parent_user_id": user_oid,
            "status": "pending"
        }).sort("created_at", -1)
        
        requests = []
        async for request_doc in requests_cursor:
            child_user = await get_collection("users").find_one({"_id": request_doc["child_user_id"]})
            
            requests.append(ContentApprovalRequestResponse(
                id=str(request_doc["_id"]),
                child_user_id=str(request_doc["child_user_id"]),
                child_name=child_user.get("full_name") if child_user else None,
                parent_user_id=str(request_doc["parent_user_id"]),
                content_type=request_doc["content_type"],
                content_id=str(request_doc["content_id"]),
                content_title=request_doc.get("content_title"),
                content_preview=request_doc.get("content_preview"),
                status=request_doc["status"],
                parent_notes=request_doc.get("parent_notes"),
                created_at=request_doc["created_at"],
                reviewed_at=request_doc.get("reviewed_at")
            ))
        
        return requests
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list approval requests: {str(e)}")


@router.post("/approval-requests/{request_id}/review", response_model=ContentApprovalRequestResponse)
async def review_approval_request(
    request_id: str,
    decision: ApprovalDecision,
    current_user: UserInDB = Depends(get_current_user)
):
    """Review an approval request (by parent)"""
    try:
        request_oid = safe_object_id(request_id)
        if not request_oid:
            raise HTTPException(status_code=400, detail="Invalid request ID")
        
        request_doc = await get_collection("approval_requests").find_one({"_id": request_oid})
        if not request_doc:
            raise HTTPException(status_code=404, detail="Approval request not found")
        
        if str(request_doc["parent_user_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to review this request")
        
        await get_collection("approval_requests").update_one(
            {"_id": request_oid},
            {
                "$set": {
                    "status": decision.status,
                    "parent_notes": decision.parent_notes,
                    "reviewed_at": datetime.utcnow()
                }
            }
        )
        
        updated_request = await get_collection("approval_requests").find_one({"_id": request_oid})
        child_user = await get_collection("users").find_one({"_id": updated_request["child_user_id"]})
        
        return ContentApprovalRequestResponse(
            id=str(updated_request["_id"]),
            child_user_id=str(updated_request["child_user_id"]),
            child_name=child_user.get("full_name") if child_user else None,
            parent_user_id=str(updated_request["parent_user_id"]),
            content_type=updated_request["content_type"],
            content_id=str(updated_request["content_id"]),
            content_title=updated_request.get("content_title"),
            content_preview=updated_request.get("content_preview"),
            status=updated_request["status"],
            parent_notes=updated_request.get("parent_notes"),
            created_at=updated_request["created_at"],
            reviewed_at=updated_request.get("reviewed_at")
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to review approval request: {str(e)}")
