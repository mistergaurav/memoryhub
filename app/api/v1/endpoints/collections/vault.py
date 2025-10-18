import os
import shutil
from datetime import datetime
from typing import List, Optional
from fastapi import (
    APIRouter, Depends, HTTPException, status, 
    UploadFile, File, Form, Query, BackgroundTasks
)
from fastapi.responses import FileResponse
from bson import ObjectId
from pathlib import Path
import mimetypes

from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.models.user import UserInDB
from app.models.vault import (
    FileInDB, FileCreate, FileUpdate, FileResponse,
    VaultStats, FileType, FilePrivacy
)
from app.utils.vault_utils import (
    save_upload_file, get_file_type, validate_file_extension,
    get_file_size, get_available_space
)
from app.core.config import settings

router = APIRouter()

# Configure upload directory
UPLOAD_BASE_DIR = "uploads/vault"
os.makedirs(UPLOAD_BASE_DIR, exist_ok=True)

def get_user_upload_dir(user_id: str) -> str:
    """Get user's upload directory path"""
    return os.path.join(UPLOAD_BASE_DIR, str(user_id))

@router.post("/upload", response_model=FileResponse)
async def upload_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    name: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    tags: List[str] = Form([]),
    privacy: FilePrivacy = Form(FilePrivacy.PRIVATE),
    current_user: UserInDB = Depends(get_current_user)
):
    """Upload a file to the user's vault"""
    # Validate file
    validate_file_extension(file.filename)
    
    # Get or generate file name
    file_name = name or file.filename
    file_ext = Path(file.filename).suffix
    file_type = get_file_type(file.filename)
    
    # Check available space
    available_space = get_available_space(current_user.id)
    # Note: Actual size check would be better after upload, but we do a pre-check here
    if file.size > available_space:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Not enough storage space"
        )
    
    # Create user's upload directory if it doesn't exist
    user_upload_dir = get_user_upload_dir(current_user.id)
    os.makedirs(user_upload_dir, exist_ok=True)
    
    try:
        # Save the file
        file_path, mime_type, file_size = await save_upload_file(file, user_upload_dir)
        
        # Create file record in database
        file_data = {
            "name": file_name,
            "description": description,
            "tags": tags,
            "privacy": privacy,
            "owner_id": ObjectId(current_user.id),
            "file_path": file_path,
            "file_type": file_type,
            "file_size": file_size,
            "mime_type": mime_type,
            "metadata": {
                "original_filename": file.filename,
                "content_type": file.content_type
            }
        }
        
        result = await get_collection("files").insert_one(file_data)
        file_doc = await get_collection("files").find_one({"_id": result.inserted_id})
        
        return await _prepare_file_response(file_doc, current_user)
        
    except Exception as e:
        # Clean up if something went wrong
        if 'file_path' in locals() and os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading file: {str(e)}"
        )

@router.get("/files/{file_id}", response_model=FileResponse)
async def get_file(
    file_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get file metadata"""
    file_doc = await get_collection("files").find_one({"_id": ObjectId(file_id)})
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Check permissions
    if str(file_doc["owner_id"]) != current_user.id and file_doc["privacy"] != "public":
        raise HTTPException(status_code=403, detail="Not authorized to access this file")
    
    return await _prepare_file_response(file_doc, current_user)

@router.get("/download/{file_id}")
async def download_file(
    file_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Download a file"""
    file_doc = await get_collection("files").find_one({"_id": ObjectId(file_id)})
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Check permissions
    if str(file_doc["owner_id"]) != current_user.id and file_doc["privacy"] != "public":
        raise HTTPException(status_code=403, detail="Not authorized to download this file")
    
    # Increment download count
    await get_collection("files").update_one(
        {"_id": ObjectId(file_id)},
        {"$inc": {"download_count": 1}}
    )
    
    # Return the file
    if not os.path.exists(file_doc["file_path"]):
        raise HTTPException(status_code=404, detail="File not found on server")
    
    return FileResponse(
        file_doc["file_path"],
        filename=file_doc["name"],
        media_type=file_doc.get("mime_type", "application/octet-stream")
    )

@router.get("/", response_model=List[FileResponse])
async def list_files(
    file_type: Optional[FileType] = None,
    privacy: Optional[FilePrivacy] = None,
    tag: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """List files with filtering and pagination"""
    query = {"owner_id": ObjectId(current_user.id)}
    
    if file_type:
        query["file_type"] = file_type
    if privacy:
        query["privacy"] = privacy
    if tag:
        query["tags"] = tag
    if search:
        query["$text"] = {"$search": search}
    
    skip = (page - 1) * limit
    cursor = get_collection("files").find(query).skip(skip).limit(limit)
    
    files = []
    async for file_doc in cursor:
        files.append(await _prepare_file_response(file_doc, current_user))
    
    return files

@router.put("/{file_id}", response_model=FileResponse)
async def update_file(
    file_id: str,
    file_update: FileUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update file metadata"""
    file_doc = await get_collection("files").find_one({"_id": ObjectId(file_id)})
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")
    
    if str(file_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this file")
    
    update_data = file_update.dict(exclude_unset=True)
    update_data["updated_at"] = datetime.utcnow()
    
    await get_collection("files").update_one(
        {"_id": ObjectId(file_id)},
        {"$set": update_data}
    )
    
    updated_file = await get_collection("files").find_one({"_id": ObjectId(file_id)})
    return await _prepare_file_response(updated_file, current_user)

@router.delete("/{file_id}")
async def delete_file(
    file_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a file"""
    file_doc = await get_collection("files").find_one({"_id": ObjectId(file_id)})
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")
    
    if str(file_doc["owner_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this file")
    
    # Delete file from storage
    if os.path.exists(file_doc["file_path"]):
        os.remove(file_doc["file_path"])
    
    # Delete database record
    await get_collection("files").delete_one({"_id": ObjectId(file_id)})
    
    return {"message": "File deleted successfully"}

@router.get("/stats", response_model=VaultStats)
async def get_vault_stats(current_user: UserInDB = Depends(get_current_user)):
    """Get vault statistics"""
    # Get total files and size
    pipeline = [
        {"$match": {"owner_id": ObjectId(current_user.id)}},
        {"$group": {
            "_id": None,
            "total_files": {"$sum": 1},
            "total_size": {"$sum": "$file_size"},
            "by_type": {"$push": {"type": "$file_type", "count": 1, "size": "$file_size"}}
        }}
    ]
    
    result = await get_collection("files").aggregate(pipeline).to_list(1)
    
    if not result:
        return VaultStats(
            total_files=0,
            total_size=0,
            by_type={}
        )
    
    # Process file types
    by_type = {}
    for item in result[0].get("by_type", []):
        file_type = item["type"]
        if file_type not in by_type:
            by_type[file_type] = 0
        by_type[file_type] += 1
    
    return VaultStats(
        total_files=result[0]["total_files"],
        total_size=result[0]["total_size"],
        by_type=by_type
    )

async def _prepare_file_response(file_doc: dict, current_user: UserInDB) -> dict:
    """Prepare file response with additional data"""
    file_doc["id"] = str(file_doc["_id"])
    file_doc["owner_id"] = str(file_doc["owner_id"])
    
    # Add owner info
    if "owner" not in file_doc:
        owner = await get_collection("users").find_one({"_id": ObjectId(file_doc["owner_id"])})
        if owner:
            file_doc["owner_name"] = owner.get("full_name")
            file_doc["owner_avatar"] = owner.get("avatar_url")
    
    # Generate download URL
    file_doc["download_url"] = f"/api/v1/vault/download/{file_doc['_id']}"
    
    return file_doc