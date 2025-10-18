from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Request
from fastapi.responses import StreamingResponse, JSONResponse
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from bson import ObjectId
from pydantic import BaseModel, Field
import json
import zipfile
import io
import os

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.utils.audit_logger import log_data_export, log_data_deletion, log_consent_update, log_privacy_settings_update

router = APIRouter()

# GDPR Request Models
class ConsentUpdate(BaseModel):
    analytics: bool = Field(True, description="Consent for analytics")
    marketing: bool = Field(False, description="Consent for marketing communications")
    personalization: bool = Field(True, description="Consent for personalized content")
    data_sharing: bool = Field(False, description="Consent for sharing data with third parties")

class DataDeletionRequest(BaseModel):
    confirmation: bool = Field(..., description="User must confirm deletion")
    feedback: Optional[str] = Field(None, description="Optional feedback")

class PrivacySettings(BaseModel):
    profile_visibility: str = Field("friends", description="public, friends, or private")
    show_email: bool = Field(False, description="Show email on profile")
    show_activity: bool = Field(True, description="Show activity to others")
    allow_indexing: bool = Field(False, description="Allow search engine indexing")
    allow_messages: bool = Field(True, description="Allow messages from other users")

# GDPR Endpoints

@router.get("/data-export")
async def request_data_export(
    background_tasks: BackgroundTasks,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Request a full export of user's data (GDPR Article 20 - Right to Data Portability)"""
    try:
        # Log audit event
        await log_data_export(current_user.id, "json", request.client.host if request.client else None)
        
        # Collect all user data
        user_data = await _collect_user_data(current_user.id)
        
        # Create JSON export
        export_json = json.dumps(user_data, indent=2, default=str)
        
        # Create export record
        export_record = {
            "user_id": ObjectId(current_user.id),
            "requested_at": datetime.utcnow(),
            "status": "completed",
            "data_size": len(export_json)
        }
        await get_collection("data_exports").insert_one(export_record)
        
        # Return as downloadable JSON
        return StreamingResponse(
            io.BytesIO(export_json.encode()),
            media_type="application/json",
            headers={
                "Content-Disposition": f"attachment; filename=memory_hub_data_{current_user.id}_{datetime.utcnow().strftime('%Y%m%d')}.json"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error exporting data: {str(e)}")

@router.get("/data-export/archive")
async def request_full_archive(
    background_tasks: BackgroundTasks,
    current_user: UserInDB = Depends(get_current_user)
):
    """Request a complete archive including files (GDPR Article 20)"""
    try:
        # Create in-memory ZIP file
        zip_buffer = io.BytesIO()
        
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            # Add JSON data export
            user_data = await _collect_user_data(current_user.id)
            zip_file.writestr("user_data.json", json.dumps(user_data, indent=2, default=str))
            
            # Add memories with media files
            memories = await get_collection("memories").find({"owner_id": ObjectId(current_user.id)}).to_list(length=None)
            for memory in memories:
                memory_dir = f"memories/{memory['_id']}/"
                zip_file.writestr(
                    f"{memory_dir}memory.json",
                    json.dumps(await _serialize_memory(memory), indent=2, default=str)
                )
                
                # Add media files if they exist
                for idx, media_url in enumerate(memory.get("media_urls", [])):
                    if media_url.startswith("/api/v1/memories/media/"):
                        filename = media_url.split("/")[-1]
                        file_path = os.path.join("uploads/memories", filename)
                        if os.path.exists(file_path):
                            with open(file_path, 'rb') as f:
                                zip_file.writestr(f"{memory_dir}{filename}", f.read())
            
            # Add vault files
            files = await get_collection("files").find({"owner_id": ObjectId(current_user.id)}).to_list(length=None)
            for file_doc in files:
                file_dir = f"vault/{file_doc['_id']}/"
                zip_file.writestr(
                    f"{file_dir}metadata.json",
                    json.dumps(await _serialize_file(file_doc), indent=2, default=str)
                )
                
                # Add actual file if it exists
                file_path = file_doc.get("file_path")
                if file_path and os.path.exists(file_path):
                    with open(file_path, 'rb') as f:
                        zip_file.writestr(f"{file_dir}{file_doc['name']}", f.read())
        
        zip_buffer.seek(0)
        
        # Create export record
        export_record = {
            "user_id": ObjectId(current_user.id),
            "requested_at": datetime.utcnow(),
            "export_type": "full_archive",
            "status": "completed",
            "data_size": zip_buffer.getbuffer().nbytes
        }
        await get_collection("data_exports").insert_one(export_record)
        
        return StreamingResponse(
            zip_buffer,
            media_type="application/zip",
            headers={
                "Content-Disposition": f"attachment; filename=memory_hub_archive_{current_user.id}_{datetime.utcnow().strftime('%Y%m%d')}.zip"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating archive: {str(e)}")

@router.get("/consent")
async def get_consent_settings(current_user: UserInDB = Depends(get_current_user)):
    """Get user's consent settings (GDPR Article 7)"""
    try:
        user = await get_collection("users").find_one({"_id": ObjectId(current_user.id)})
        consent = user.get("consent", {
            "analytics": True,
            "marketing": False,
            "personalization": True,
            "data_sharing": False,
            "updated_at": datetime.utcnow()
        })
        return consent
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching consent: {str(e)}")

@router.put("/consent")
async def update_consent_settings(
    consent: ConsentUpdate,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update user's consent settings (GDPR Article 7)"""
    try:
        consent_data = consent.dict()
        consent_data["updated_at"] = datetime.utcnow()
        
        # Log audit event
        await log_consent_update(current_user.id, consent_data, request.client.host if request.client else None)
        
        await get_collection("users").update_one(
            {"_id": ObjectId(current_user.id)},
            {"$set": {"consent": consent_data}}
        )
        
        # Log consent change
        await get_collection("consent_log").insert_one({
            "user_id": ObjectId(current_user.id),
            "consent_settings": consent_data,
            "timestamp": datetime.utcnow()
        })
        
        return {"message": "Consent settings updated successfully", "consent": consent_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating consent: {str(e)}")

@router.get("/privacy-settings")
async def get_privacy_settings(current_user: UserInDB = Depends(get_current_user)):
    """Get user's privacy settings"""
    try:
        user = await get_collection("users").find_one({"_id": ObjectId(current_user.id)})
        privacy = user.get("privacy_settings", {
            "profile_visibility": "friends",
            "show_email": False,
            "show_activity": True,
            "allow_indexing": False,
            "allow_messages": True
        })
        return privacy
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching privacy settings: {str(e)}")

@router.put("/privacy-settings")
async def update_privacy_settings(
    privacy: PrivacySettings,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update user's privacy settings"""
    try:
        privacy_data = privacy.dict()
        
        # Log audit event
        await log_privacy_settings_update(current_user.id, privacy_data, request.client.host if request.client else None)
        
        await get_collection("users").update_one(
            {"_id": ObjectId(current_user.id)},
            {"$set": {"privacy_settings": privacy_data, "updated_at": datetime.utcnow()}}
        )
        
        return {"message": "Privacy settings updated successfully", "privacy": privacy_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating privacy settings: {str(e)}")

@router.post("/request-deletion")
async def request_account_deletion(
    deletion_request: DataDeletionRequest,
    background_tasks: BackgroundTasks,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Request account deletion (GDPR Article 17 - Right to Erasure)"""
    try:
        if not deletion_request.confirmation:
            raise HTTPException(status_code=400, detail="Deletion must be confirmed")
        
        # Log audit event
        await log_data_deletion(current_user.id, "account_deletion_request", deletion_request.feedback, request.client.host if request.client else None)
        
        # Create deletion request
        deletion_doc = {
            "user_id": ObjectId(current_user.id),
            "requested_at": datetime.utcnow(),
            "scheduled_deletion": datetime.utcnow() + timedelta(days=30),  # 30-day grace period
            "status": "pending",
            "feedback": deletion_request.feedback
        }
        
        result = await get_collection("deletion_requests").insert_one(deletion_doc)
        
        # Mark user account as deletion pending
        await get_collection("users").update_one(
            {"_id": ObjectId(current_user.id)},
            {"$set": {
                "deletion_pending": True,
                "deletion_request_id": result.inserted_id,
                "updated_at": datetime.utcnow()
            }}
        )
        
        return {
            "message": "Account deletion scheduled",
            "scheduled_deletion": deletion_doc["scheduled_deletion"],
            "grace_period_days": 30,
            "cancellation_info": "You can cancel this request within 30 days by logging in"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error requesting deletion: {str(e)}")

@router.post("/cancel-deletion")
async def cancel_account_deletion(current_user: UserInDB = Depends(get_current_user)):
    """Cancel a pending account deletion request"""
    try:
        user = await get_collection("users").find_one({"_id": ObjectId(current_user.id)})
        
        if not user.get("deletion_pending"):
            raise HTTPException(status_code=400, detail="No pending deletion request")
        
        # Cancel deletion request
        await get_collection("deletion_requests").update_one(
            {"_id": user.get("deletion_request_id")},
            {"$set": {"status": "cancelled", "cancelled_at": datetime.utcnow()}}
        )
        
        # Remove deletion flag from user
        await get_collection("users").update_one(
            {"_id": ObjectId(current_user.id)},
            {"$unset": {"deletion_pending": "", "deletion_request_id": ""},
             "$set": {"updated_at": datetime.utcnow()}}
        )
        
        return {"message": "Account deletion cancelled successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error cancelling deletion: {str(e)}")

@router.get("/data-processing-info")
async def get_data_processing_info():
    """Get information about data processing (GDPR Article 13 - Transparency)"""
    return {
        "data_controller": {
            "name": "Memory Hub",
            "contact": "privacy@memoryhub.com"
        },
        "data_collected": [
            "Personal information (name, email)",
            "Profile data (avatar, bio, location)",
            "Content (memories, files, collections)",
            "Usage data (login times, feature usage)",
            "Technical data (IP address, browser info)"
        ],
        "purposes": [
            "Provide and maintain the service",
            "Improve user experience",
            "Communicate with users",
            "Ensure security"
        ],
        "legal_basis": [
            "Contract performance",
            "Legitimate interests",
            "User consent"
        ],
        "data_retention": "Data is retained while your account is active and for 30 days after deletion request",
        "third_party_sharing": "We do not share your data with third parties without consent",
        "user_rights": [
            "Right to access (Article 15)",
            "Right to rectification (Article 16)",
            "Right to erasure (Article 17)",
            "Right to data portability (Article 20)",
            "Right to object (Article 21)",
            "Right to withdraw consent (Article 7)"
        ],
        "contact": "For privacy inquiries, contact privacy@memoryhub.com"
    }

@router.get("/export-history")
async def get_export_history(current_user: UserInDB = Depends(get_current_user)):
    """Get history of data exports"""
    try:
        exports = await get_collection("data_exports").find({
            "user_id": ObjectId(current_user.id)
        }).sort("requested_at", -1).limit(10).to_list(length=10)
        
        return [
            {
                "id": str(export["_id"]),
                "requested_at": export["requested_at"],
                "export_type": export.get("export_type", "json"),
                "status": export["status"],
                "data_size": export.get("data_size", 0)
            }
            for export in exports
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching export history: {str(e)}")

# Helper functions

async def _collect_user_data(user_id: str) -> Dict[str, Any]:
    """Collect all user data for export"""
    user_obj_id = ObjectId(user_id)
    
    # Get user profile
    user = await get_collection("users").find_one({"_id": user_obj_id})
    user_data = {
        "id": str(user["_id"]),
        "email": user.get("email"),
        "full_name": user.get("full_name"),
        "bio": user.get("bio"),
        "city": user.get("city"),
        "country": user.get("country"),
        "website": user.get("website"),
        "created_at": user.get("created_at"),
        "updated_at": user.get("updated_at"),
        "settings": user.get("settings", {}),
        "consent": user.get("consent", {}),
        "privacy_settings": user.get("privacy_settings", {})
    }
    
    # Get memories
    memories = await get_collection("memories").find({"owner_id": user_obj_id}).to_list(length=None)
    user_data["memories"] = [await _serialize_memory(m) for m in memories]
    
    # Get collections
    collections = await get_collection("collections").find({"owner_id": user_obj_id}).to_list(length=None)
    user_data["collections"] = [await _serialize_collection(c) for c in collections]
    
    # Get files
    files = await get_collection("files").find({"owner_id": user_obj_id}).to_list(length=None)
    user_data["files"] = [await _serialize_file(f) for f in files]
    
    # Get relationships
    relationships = await get_collection("relationships").find({
        "$or": [
            {"follower_id": user_obj_id},
            {"following_id": user_obj_id}
        ]
    }).to_list(length=None)
    user_data["relationships"] = [await _serialize_relationship(r) for r in relationships]
    
    # Get activity
    activities = await get_collection("activities").find({"user_id": user_obj_id}).to_list(length=None)
    user_data["activities"] = [await _serialize_activity(a) for a in activities]
    
    return user_data

async def _serialize_memory(memory: dict) -> dict:
    """Serialize memory document"""
    return {
        "id": str(memory["_id"]),
        "title": memory.get("title"),
        "content": memory.get("content"),
        "tags": memory.get("tags", []),
        "privacy": memory.get("privacy"),
        "media_urls": memory.get("media_urls", []),
        "location": memory.get("location"),
        "mood": memory.get("mood"),
        "created_at": memory.get("created_at"),
        "updated_at": memory.get("updated_at")
    }

async def _serialize_collection(collection: dict) -> dict:
    """Serialize collection document"""
    return {
        "id": str(collection["_id"]),
        "name": collection.get("name"),
        "description": collection.get("description"),
        "privacy": collection.get("privacy"),
        "tags": collection.get("tags", []),
        "created_at": collection.get("created_at"),
        "updated_at": collection.get("updated_at")
    }

async def _serialize_file(file_doc: dict) -> dict:
    """Serialize file document"""
    return {
        "id": str(file_doc["_id"]),
        "name": file_doc.get("name"),
        "description": file_doc.get("description"),
        "file_type": file_doc.get("file_type"),
        "file_size": file_doc.get("file_size"),
        "created_at": file_doc.get("created_at")
    }

async def _serialize_relationship(relationship: dict) -> dict:
    """Serialize relationship document"""
    return {
        "id": str(relationship["_id"]),
        "follower_id": str(relationship.get("follower_id")),
        "following_id": str(relationship.get("following_id")),
        "status": relationship.get("status"),
        "created_at": relationship.get("created_at")
    }

async def _serialize_activity(activity: dict) -> dict:
    """Serialize activity document"""
    return {
        "id": str(activity["_id"]),
        "activity_type": activity.get("activity_type"),
        "details": activity.get("details"),
        "created_at": activity.get("created_at")
    }

# Alias endpoints for better API compatibility
@router.post("/delete-account")
async def delete_account_alias(
    deletion_request: DataDeletionRequest,
    background_tasks: BackgroundTasks,
    current_user: UserInDB = Depends(get_current_user)
):
    """Alias for /request-deletion endpoint"""
    return await request_account_deletion(deletion_request, background_tasks, current_user)

@router.get("/data-info")
async def data_info_alias():
    """Alias for /data-processing-info endpoint"""
    return await get_data_processing_info()
