import os
import mimetypes
from pathlib import Path
from typing import Optional, Tuple
from fastapi import UploadFile, HTTPException, status

# Allowed file types and their extensions
ALLOWED_EXTENSIONS = {
    'image': ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'],
    'video': ['.mp4', '.webm', '.mov', '.avi', '.mkv'],
    'document': ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt'],
    'audio': ['.mp3', '.wav', '.ogg', '.m4a'],
    'archive': ['.zip', '.rar', '.7z', '.tar', '.gz']
}

def get_file_type(filename: str) -> str:
    """Determine the file type based on extension"""
    ext = Path(filename).suffix.lower()
    for file_type, extensions in ALLOWED_EXTENSIONS.items():
        if ext in extensions:
            return file_type
    return 'other'

def validate_file_extension(filename: str) -> None:
    """Check if the file extension is allowed"""
    ext = Path(filename).suffix.lower()
    if not any(ext in exts for exts in ALLOWED_EXTENSIONS.values()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type {ext} is not allowed"
        )

async def save_upload_file(upload_file: UploadFile, upload_dir: str) -> Tuple[str, str, int]:
    """Save uploaded file and return (file_path, mime_type, file_size)"""
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, upload_file.filename)
    
    # Save file
    file_size = 0
    with open(file_path, "wb") as buffer:
        while content := await upload_file.read(1024 * 1024):  # 1MB chunks
            file_size += len(content)
            buffer.write(content)
    
    # Get MIME type
    mime_type, _ = mimetypes.guess_type(file_path)
    if mime_type is None:
        mime_type = 'application/octet-stream'
    
    return file_path, mime_type, file_size

def get_file_size(file_path: str) -> int:
    """Get file size in bytes"""
    return os.path.getsize(file_path)

def get_available_space(owner_id: str) -> int:
    """Get available space for user (in bytes)"""
    # Default 1GB storage per user
    default_quota = 1024 * 1024 * 1024
    # TODO: Implement actual storage quota check from user settings
    return default_quota