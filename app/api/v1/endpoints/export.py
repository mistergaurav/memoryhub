from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from typing import Optional
from datetime import datetime
from bson import ObjectId
import os
import zipfile
import json

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

EXPORT_DIR = "exports"
os.makedirs(EXPORT_DIR, exist_ok=True)

@router.post("/memories/json")
async def export_memories_json(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """Export memories as JSON"""
    query = {"owner_id": ObjectId(current_user.id)}
    
    if start_date:
        query["created_at"] = query.get("created_at", {})
        query["created_at"]["$gte"] = datetime.fromisoformat(start_date)
    
    if end_date:
        query["created_at"] = query.get("created_at", {})
        query["created_at"]["$lte"] = datetime.fromisoformat(end_date)
    
    memories = await get_collection("memories").find(query).to_list(length=None)
    
    # Convert ObjectId to string for JSON serialization
    for memory in memories:
        memory["_id"] = str(memory["_id"])
        memory["owner_id"] = str(memory["owner_id"])
        if "created_at" in memory:
            memory["created_at"] = memory["created_at"].isoformat()
        if "updated_at" in memory:
            memory["updated_at"] = memory["updated_at"].isoformat()
    
    # Save to file
    filename = f"memories_export_{current_user.id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
    filepath = os.path.join(EXPORT_DIR, filename)
    
    with open(filepath, "w") as f:
        json.dump({"memories": memories, "exported_at": datetime.utcnow().isoformat()}, f, indent=2)
    
    return {
        "download_url": f"/api/v1/export/download/{filename}",
        "filename": filename,
        "count": len(memories)
    }

@router.post("/files/zip")
async def export_files_zip(
    file_ids: Optional[list[str]] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """Export files as ZIP archive"""
    query = {"owner_id": ObjectId(current_user.id)}
    
    if file_ids:
        query["_id"] = {"$in": [ObjectId(fid) for fid in file_ids]}
    
    files = await get_collection("files").find(query).to_list(length=None)
    
    if not files:
        raise HTTPException(status_code=404, detail="No files found to export")
    
    # Create ZIP file
    zip_filename = f"files_export_{current_user.id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.zip"
    zip_filepath = os.path.join(EXPORT_DIR, zip_filename)
    
    with zipfile.ZipFile(zip_filepath, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_doc in files:
            file_path = file_doc.get("file_path")
            if file_path and os.path.exists(file_path):
                # Add file to ZIP with its original name
                arcname = file_doc.get("name", os.path.basename(file_path))
                zipf.write(file_path, arcname=arcname)
    
    return {
        "download_url": f"/api/v1/export/download/{zip_filename}",
        "filename": zip_filename,
        "files_count": len(files)
    }

@router.post("/full-backup")
async def create_full_backup(
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a full backup of all user data"""
    # Export all data
    memories = await get_collection("memories").find({"owner_id": ObjectId(current_user.id)}).to_list(length=None)
    files = await get_collection("files").find({"owner_id": ObjectId(current_user.id)}).to_list(length=None)
    hub_items = await get_collection("hub_items").find({"owner_id": ObjectId(current_user.id)}).to_list(length=None)
    collections = await get_collection("collections").find({"owner_id": ObjectId(current_user.id)}).to_list(length=None)
    
    # Convert ObjectIds to strings
    def convert_doc(doc):
        doc["_id"] = str(doc["_id"])
        doc["owner_id"] = str(doc["owner_id"])
        if "created_at" in doc:
            doc["created_at"] = doc["created_at"].isoformat()
        if "updated_at" in doc:
            doc["updated_at"] = doc["updated_at"].isoformat()
        return doc
    
    backup_data = {
        "user_id": current_user.id,
        "backup_date": datetime.utcnow().isoformat(),
        "memories": [convert_doc(m) for m in memories],
        "files": [convert_doc(f) for f in files],
        "hub_items": [convert_doc(h) for h in hub_items],
        "collections": [convert_doc(c) for c in collections]
    }
    
    # Save backup
    filename = f"full_backup_{current_user.id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
    filepath = os.path.join(EXPORT_DIR, filename)
    
    with open(filepath, "w") as f:
        json.dump(backup_data, f, indent=2)
    
    return {
        "download_url": f"/api/v1/export/download/{filename}",
        "filename": filename,
        "stats": {
            "memories": len(memories),
            "files": len(files),
            "hub_items": len(hub_items),
            "collections": len(collections)
        }
    }

@router.get("/download/{filename}")
async def download_export(
    filename: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Download an exported file"""
    # Verify filename belongs to current user
    if current_user.id not in filename:
        raise HTTPException(status_code=403, detail="Not authorized to download this file")
    
    filepath = os.path.join(EXPORT_DIR, filename)
    
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Export file not found")
    
    return FileResponse(
        path=filepath,
        filename=filename,
        media_type="application/octet-stream"
    )
