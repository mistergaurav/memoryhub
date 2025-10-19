"""
Media serving endpoints - Serve uploaded files
"""
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path
import os

router = APIRouter()

UPLOAD_DIR = Path("uploads")


@router.get("/uploads/{category}/{user_folder}/{filename}")
async def serve_uploaded_file(category: str, user_folder: str, filename: str):
    """Serve uploaded files (audio, images, videos, documents)"""
    # Construct file path
    file_path = UPLOAD_DIR / category / user_folder / filename
    
    # Security: Prevent path traversal attacks
    try:
        file_path = file_path.resolve()
        UPLOAD_DIR.resolve() in file_path.parents
    except:
        raise HTTPException(status_code=404, detail="File not found")
    
    # Check if file exists
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=404, detail="File not found")
    
    # Determine media type
    media_types = {
        ".mp3": "audio/mpeg",
        ".wav": "audio/wav",
        ".ogg": "audio/ogg",
        ".m4a": "audio/mp4",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".webp": "image/webp",
        ".mp4": "video/mp4",
        ".webm": "video/webm",
        ".pdf": "application/pdf",
        ".doc": "application/msword",
        ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    }
    
    file_ext = file_path.suffix.lower()
    media_type = media_types.get(file_ext, "application/octet-stream")
    
    return FileResponse(
        path=str(file_path),
        media_type=media_type,
        filename=filename
    )
