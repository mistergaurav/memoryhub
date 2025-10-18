from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from bson import ObjectId
from pydantic import BaseModel, Field
import secrets
import os

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

# Pydantic models for sharing
class ShareLinkCreate(BaseModel):
    resource_type: str = Field(..., description="Type of resource: memory, collection, file, hub")
    resource_id: str = Field(..., description="ID of the resource to share")
    expires_in_days: int = Field(7, ge=1, le=365, description="Link expiration in days")
    max_uses: Optional[int] = Field(None, ge=1, description="Maximum number of uses")
    password: Optional[str] = Field(None, description="Optional password protection")
    allow_download: bool = Field(True, description="Allow downloads")
    description: Optional[str] = Field(None, description="Share description")

class ShareLinkResponse(BaseModel):
    id: str
    share_token: str
    share_url: str
    short_url: str
    qr_code_url: str
    resource_type: str
    resource_id: str
    resource_title: str
    created_at: datetime
    expires_at: datetime
    access_count: int
    max_uses: Optional[int]
    is_expired: bool
    is_password_protected: bool
    allow_download: bool
    description: Optional[str]

class ShareAccessRequest(BaseModel):
    password: Optional[str] = None

# Helper function to get resource details
async def get_resource_details(resource_type: str, resource_id: str) -> Dict[str, Any]:
    """Get details of the resource being shared"""
    try:
        obj_id = ObjectId(resource_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid resource ID format")
    
    resource_doc = None
    title = "Untitled"
    
    if resource_type == "memory":
        resource_doc = await get_collection("memories").find_one({"_id": obj_id})
        if resource_doc:
            title = resource_doc.get("title", "Untitled Memory")
    elif resource_type == "collection":
        resource_doc = await get_collection("collections").find_one({"_id": obj_id})
        if resource_doc:
            title = resource_doc.get("name", "Untitled Collection")
    elif resource_type == "file":
        resource_doc = await get_collection("files").find_one({"_id": obj_id})
        if resource_doc:
            title = resource_doc.get("name", "Untitled File")
    elif resource_type == "hub":
        resource_doc = await get_collection("hubs").find_one({"_id": obj_id})
        if resource_doc:
            title = resource_doc.get("name", "Untitled Hub")
    else:
        raise HTTPException(status_code=400, detail=f"Invalid resource type: {resource_type}")
    
    if not resource_doc:
        raise HTTPException(status_code=404, detail=f"{resource_type.capitalize()} not found")
    
    return {
        "doc": resource_doc,
        "title": title,
        "owner_id": resource_doc.get("owner_id")
    }

# Get base URL from request
def get_base_url(request: Request) -> str:
    """Get base URL from request"""
    domain = os.getenv("REPLIT_DEV_DOMAIN", "")
    if domain:
        return f"https://{domain}"
    return str(request.base_url).rstrip("/")

@router.post("/", response_model=ShareLinkResponse, status_code=status.HTTP_201_CREATED)
async def create_share_link(
    share_data: ShareLinkCreate,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a universal shareable link for any resource"""
    # Get resource details and verify ownership
    resource_info = await get_resource_details(share_data.resource_type, share_data.resource_id)
    
    # Verify ownership
    if str(resource_info["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to share this resource")
    
    # Generate unique share token
    share_token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(days=share_data.expires_in_days)
    
    # Hash password if provided
    hashed_password = None
    if share_data.password:
        from app.core.hashing import get_password_hash
        hashed_password = get_password_hash(share_data.password)
    
    # Create share link document
    share_doc = {
        "share_token": share_token,
        "resource_type": share_data.resource_type,
        "resource_id": ObjectId(share_data.resource_id),
        "owner_id": ObjectId(current_user.id),
        "created_at": datetime.utcnow(),
        "expires_at": expires_at,
        "access_count": 0,
        "max_uses": share_data.max_uses,
        "hashed_password": hashed_password,
        "allow_download": share_data.allow_download,
        "description": share_data.description,
        "is_active": True
    }
    
    result = await get_collection("share_links").insert_one(share_doc)
    
    # Generate URLs
    base_url = get_base_url(request)
    share_url = f"{base_url}/api/v1/sharing/{share_token}/access"
    # Short URLs removed for security (prevent token enumeration)
    short_url = share_url  # Use full URL for security
    qr_code_url = f"{base_url}/api/v1/sharing/{share_token}/qr"
    
    return ShareLinkResponse(
        id=str(result.inserted_id),
        share_token=share_token,
        share_url=share_url,
        short_url=short_url,
        qr_code_url=qr_code_url,
        resource_type=share_data.resource_type,
        resource_id=share_data.resource_id,
        resource_title=resource_info["title"],
        created_at=share_doc["created_at"],
        expires_at=share_doc["expires_at"],
        access_count=0,
        max_uses=share_data.max_uses,
        is_expired=False,
        is_password_protected=hashed_password is not None,
        allow_download=share_data.allow_download,
        description=share_data.description
    )

@router.post("/{share_token}/access")
async def access_shared_resource(
    share_token: str,
    access_request: ShareAccessRequest = ShareAccessRequest()
):
    """Access a shared resource via share token"""
    # Security: Only allow exact token matches to prevent enumeration attacks
    # Minimum token length requirement to prevent brute force
    if len(share_token) < 16:
        raise HTTPException(status_code=404, detail="Share link not found")
    
    # Find share link with exact match only (no partial matches or regex)
    share_doc = await get_collection("share_links").find_one({
        "share_token": share_token
    })
    
    if not share_doc:
        raise HTTPException(status_code=404, detail="Share link not found")
    
    # Check if link is active
    if not share_doc.get("is_active", True):
        raise HTTPException(status_code=410, detail="Share link has been revoked")
    
    # Check expiration
    if share_doc["expires_at"] < datetime.utcnow():
        raise HTTPException(status_code=410, detail="Share link has expired")
    
    # Check max uses
    if share_doc.get("max_uses") and share_doc.get("access_count", 0) >= share_doc["max_uses"]:
        raise HTTPException(status_code=410, detail="Share link has reached maximum uses")
    
    # Verify password if required
    if share_doc.get("hashed_password"):
        if not access_request.password:
            raise HTTPException(status_code=401, detail="Password required")
        
        from app.core.security import verify_password
        if not verify_password(access_request.password, share_doc["hashed_password"]):
            raise HTTPException(status_code=401, detail="Incorrect password")
    
    # Increment access count
    await get_collection("share_links").update_one(
        {"_id": share_doc["_id"]},
        {"$inc": {"access_count": 1}}
    )
    
    # Get resource details
    resource_type = share_doc["resource_type"]
    resource_id = share_doc["resource_id"]
    
    resource_data = None
    if resource_type == "memory":
        memory_doc = await get_collection("memories").find_one({"_id": resource_id})
        if memory_doc:
            owner = await get_collection("users").find_one({"_id": memory_doc["owner_id"]})
            resource_data = {
                "id": str(memory_doc["_id"]),
                "title": memory_doc["title"],
                "content": memory_doc.get("content", ""),
                "tags": memory_doc.get("tags", []),
                "media_urls": memory_doc.get("media_urls", []),
                "created_at": memory_doc["created_at"].isoformat(),
                "owner_name": owner.get("full_name", "Unknown") if owner else "Unknown",
                "allow_download": share_doc.get("allow_download", True)
            }
    
    elif resource_type == "collection":
        col_doc = await get_collection("collections").find_one({"_id": resource_id})
        if col_doc:
            owner = await get_collection("users").find_one({"_id": col_doc["owner_id"]})
            memory_count = await get_collection("collection_memories").count_documents({
                "collection_id": resource_id
            })
            resource_data = {
                "id": str(col_doc["_id"]),
                "name": col_doc["name"],
                "description": col_doc.get("description"),
                "cover_image_url": col_doc.get("cover_image_url"),
                "tags": col_doc.get("tags", []),
                "memory_count": memory_count,
                "owner_name": owner.get("full_name", "Unknown") if owner else "Unknown",
                "created_at": col_doc["created_at"].isoformat()
            }
    
    elif resource_type == "file":
        file_doc = await get_collection("files").find_one({"_id": resource_id})
        if file_doc:
            resource_data = {
                "id": str(file_doc["_id"]),
                "name": file_doc["name"],
                "description": file_doc.get("description"),
                "file_type": file_doc["file_type"],
                "file_size": file_doc["file_size"],
                "download_url": f"/api/v1/vault/download/{file_doc['_id']}" if share_doc.get("allow_download") else None
            }
    
    elif resource_type == "hub":
        hub_doc = await get_collection("hubs").find_one({"_id": resource_id})
        if hub_doc:
            owner = await get_collection("users").find_one({"_id": hub_doc["owner_id"]})
            member_count = await get_collection("hub_members").count_documents({"hub_id": resource_id})
            resource_data = {
                "id": str(hub_doc["_id"]),
                "name": hub_doc["name"],
                "description": hub_doc.get("description"),
                "cover_image_url": hub_doc.get("cover_image_url"),
                "member_count": member_count,
                "owner_name": owner.get("full_name", "Unknown") if owner else "Unknown",
                "created_at": hub_doc["created_at"].isoformat(),
                "join_url": f"/api/v1/social/hubs/join/{share_token}"
            }
    
    if not resource_data:
        raise HTTPException(status_code=404, detail="Resource not found")
    
    return {
        "resource_type": resource_type,
        "resource_data": resource_data,
        "description": share_doc.get("description"),
        "access_count": share_doc.get("access_count", 0) + 1,
        "expires_at": share_doc["expires_at"].isoformat()
    }

@router.get("/my-shares", response_model=List[ShareLinkResponse])
async def list_my_shares(
    request: Request,
    resource_type: Optional[str] = None,
    active_only: bool = True,
    current_user: UserInDB = Depends(get_current_user)
):
    """List all share links created by current user"""
    query = {"owner_id": ObjectId(current_user.id)}
    
    if resource_type:
        query["resource_type"] = resource_type
    
    if active_only:
        query["is_active"] = True
        query["expires_at"] = {"$gt": datetime.utcnow()}
    
    cursor = get_collection("share_links").find(query).sort("created_at", -1)
    
    shares = []
    base_url = get_base_url(request)
    
    async for share_doc in cursor:
        # Get resource title
        resource_info = await get_resource_details(
            share_doc["resource_type"], 
            str(share_doc["resource_id"])
        )
        
        is_expired = share_doc["expires_at"] < datetime.utcnow()
        
        shares.append(ShareLinkResponse(
            id=str(share_doc["_id"]),
            share_token=share_doc["share_token"],
            share_url=f"{base_url}/api/v1/sharing/{share_doc['share_token']}/access",
            short_url=f"{base_url}/api/v1/sharing/{share_doc['share_token']}/access",  # No short URLs for security
            qr_code_url=f"{base_url}/api/v1/sharing/{share_doc['share_token']}/qr",
            resource_type=share_doc["resource_type"],
            resource_id=str(share_doc["resource_id"]),
            resource_title=resource_info["title"],
            created_at=share_doc["created_at"],
            expires_at=share_doc["expires_at"],
            access_count=share_doc.get("access_count", 0),
            max_uses=share_doc.get("max_uses"),
            is_expired=is_expired,
            is_password_protected=share_doc.get("hashed_password") is not None,
            allow_download=share_doc.get("allow_download", True),
            description=share_doc.get("description")
        ))
    
    return shares

@router.delete("/{share_token}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_share_link(
    share_token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Revoke/deactivate a share link"""
    share_doc = await get_collection("share_links").find_one({"share_token": share_token})
    
    if not share_doc:
        raise HTTPException(status_code=404, detail="Share link not found")
    
    if str(share_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to revoke this link")
    
    await get_collection("share_links").update_one(
        {"_id": share_doc["_id"]},
        {"$set": {"is_active": False}}
    )
    
    return None

@router.get("/{share_token}/qr")
async def get_qr_code(share_token: str, request: Request):
    """Generate QR code for share link"""
    share_doc = await get_collection("share_links").find_one({"share_token": share_token})
    
    if not share_doc:
        raise HTTPException(status_code=404, detail="Share link not found")
    
    try:
        import qrcode
        from io import BytesIO
        from fastapi.responses import StreamingResponse
        
        base_url = get_base_url(request)
        share_url = f"{base_url}/api/v1/sharing/{share_token}"
        
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(share_url)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        buf = BytesIO()
        img.save(buf, format="PNG")
        buf.seek(0)
        
        return StreamingResponse(buf, media_type="image/png")
    except ImportError:
        raise HTTPException(status_code=501, detail="QR code generation not available")

@router.get("/{share_token}/stats")
async def get_share_stats(
    share_token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get statistics for a share link"""
    share_doc = await get_collection("share_links").find_one({"share_token": share_token})
    
    if not share_doc:
        raise HTTPException(status_code=404, detail="Share link not found")
    
    if str(share_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view stats")
    
    is_expired = share_doc["expires_at"] < datetime.utcnow()
    max_uses_reached = (
        share_doc.get("max_uses") and 
        share_doc.get("access_count", 0) >= share_doc["max_uses"]
    )
    
    return {
        "access_count": share_doc.get("access_count", 0),
        "max_uses": share_doc.get("max_uses"),
        "created_at": share_doc["created_at"],
        "expires_at": share_doc["expires_at"],
        "is_expired": is_expired,
        "is_active": share_doc.get("is_active", True),
        "max_uses_reached": max_uses_reached,
        "days_remaining": (share_doc["expires_at"] - datetime.utcnow()).days if not is_expired else 0
    }

# Legacy endpoints for backward compatibility
@router.post("/files/{file_id}/share")
async def create_file_share_link(
    file_id: str,
    expires_in_days: int = 7,
    request: Request = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a shareable link for a file (legacy endpoint)"""
    share_data = ShareLinkCreate(
        resource_type="file",
        resource_id=file_id,
        expires_in_days=expires_in_days
    )
    return await create_share_link(share_data, request, current_user)

@router.get("/files/{share_token}")
async def access_shared_file(share_token: str):
    """Access a shared file via share token (legacy endpoint)"""
    access_request = ShareAccessRequest()
    result = await access_shared_resource(share_token, access_request)
    
    if result["resource_type"] != "file":
        raise HTTPException(status_code=400, detail="This is not a file share link")
    
    return result["resource_data"]
