from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from datetime import datetime, timedelta
from bson import ObjectId
import secrets

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

@router.post("/files/{file_id}/share")
async def create_share_link(
    file_id: str,
    expires_in_days: int = 7,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a shareable link for a file"""
    file_doc = await get_collection("files").find_one({
        "_id": ObjectId(file_id),
        "owner_id": ObjectId(current_user.id)
    })
    
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Generate a unique share token
    share_token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(days=expires_in_days)
    
    share_data = {
        "file_id": ObjectId(file_id),
        "owner_id": ObjectId(current_user.id),
        "share_token": share_token,
        "created_at": datetime.utcnow(),
        "expires_at": expires_at,
        "access_count": 0
    }
    
    result = await get_collection("share_links").insert_one(share_data)
    
    return {
        "share_token": share_token,
        "share_url": f"/api/v1/sharing/files/{share_token}",
        "expires_at": expires_at
    }

@router.get("/files/{share_token}")
async def access_shared_file(share_token: str):
    """Access a shared file via share token"""
    share_doc = await get_collection("share_links").find_one({"share_token": share_token})
    
    if not share_doc:
        raise HTTPException(status_code=404, detail="Share link not found")
    
    if share_doc["expires_at"] < datetime.utcnow():
        raise HTTPException(status_code=410, detail="Share link has expired")
    
    # Increment access count
    await get_collection("share_links").update_one(
        {"_id": share_doc["_id"]},
        {"$inc": {"access_count": 1}}
    )
    
    # Get file details
    file_doc = await get_collection("files").find_one({"_id": share_doc["file_id"]})
    
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")
    
    return {
        "file_id": str(file_doc["_id"]),
        "name": file_doc["name"],
        "description": file_doc.get("description"),
        "file_type": file_doc["file_type"],
        "file_size": file_doc["file_size"],
        "download_url": f"/api/v1/vault/download/{file_doc['_id']}"
    }

@router.get("/files/{file_id}/links")
async def list_share_links(
    file_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """List all share links for a file"""
    file_doc = await get_collection("files").find_one({
        "_id": ObjectId(file_id),
        "owner_id": ObjectId(current_user.id)
    })
    
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")
    
    links = await get_collection("share_links").find({
        "file_id": ObjectId(file_id)
    }).to_list(length=None)
    
    return {
        "links": [
            {
                "share_token": link["share_token"],
                "created_at": link["created_at"],
                "expires_at": link["expires_at"],
                "access_count": link.get("access_count", 0),
                "is_expired": link["expires_at"] < datetime.utcnow()
            }
            for link in links
        ]
    }

@router.delete("/links/{share_token}")
async def revoke_share_link(
    share_token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Revoke a share link"""
    share_doc = await get_collection("share_links").find_one({"share_token": share_token})
    
    if not share_doc:
        raise HTTPException(status_code=404, detail="Share link not found")
    
    if str(share_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to revoke this link")
    
    await get_collection("share_links").delete_one({"_id": share_doc["_id"]})
    
    return {"message": "Share link revoked"}
