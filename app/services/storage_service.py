"""
Storage Service - Handles file uploads and storage
Supports local filesystem with future S3/R2 support
"""
from typing import Optional, Tuple
from fastapi import UploadFile
from pathlib import Path
import os
import shutil
from datetime import datetime
from bson import ObjectId
import mimetypes


class StorageService:
    """Handles file storage operations"""
    
    def __init__(self):
        self.base_upload_dir = Path("uploads")
        self.base_upload_dir.mkdir(exist_ok=True)
        
        # Create subdirectories
        for subdir in ["audio", "images", "videos", "documents", "other"]:
            (self.base_upload_dir / subdir).mkdir(exist_ok=True)
    
    def _get_file_category(self, content_type: str) -> str:
        """Determine file category from content type"""
        if content_type.startswith("audio/"):
            return "audio"
        elif content_type.startswith("image/"):
            return "images"
        elif content_type.startswith("video/"):
            return "videos"
        elif content_type in ["application/pdf", "application/msword", 
                              "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]:
            return "documents"
        else:
            return "other"
    
    def _generate_unique_filename(self, original_filename: str, user_id: str) -> str:
        """Generate a unique filename"""
        file_id = str(ObjectId())
        ext = Path(original_filename).suffix
        safe_name = Path(original_filename).stem[:50]  # Limit name length
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        return f"{user_id}_{timestamp}_{file_id}{ext}"
    
    async def save_file(
        self, 
        file: UploadFile, 
        user_id: str,
        category: Optional[str] = None
    ) -> Tuple[str, str, int]:
        """
        Save uploaded file to storage
        
        Returns:
            Tuple of (file_path, file_url, file_size)
        """
        # Determine content type
        content_type = file.content_type or "application/octet-stream"
        
        # Get file category
        if category is None:
            category = self._get_file_category(content_type)
        
        # Generate unique filename
        unique_filename = self._generate_unique_filename(file.filename or "file", user_id)
        
        # Create user directory if needed
        user_dir = self.base_upload_dir / category / user_id[:8]  # First 8 chars of user_id for organization
        user_dir.mkdir(exist_ok=True)
        
        # Full file path
        file_path = user_dir / unique_filename
        
        # Save file
        file_size = 0
        with open(file_path, "wb") as buffer:
            content = await file.read()
            file_size = len(content)
            buffer.write(content)
        
        # Generate URL
        file_url = f"/uploads/{category}/{user_id[:8]}/{unique_filename}"
        
        return str(file_path), file_url, file_size
    
    async def delete_file(self, file_path: str) -> bool:
        """Delete a file from storage"""
        try:
            path = Path(file_path)
            if path.exists():
                path.unlink()
                return True
            return False
        except Exception as e:
            print(f"Failed to delete file {file_path}: {e}")
            return False
    
    def get_file_path(self, file_url: str) -> Optional[Path]:
        """Convert file URL to filesystem path"""
        if file_url.startswith("/uploads/"):
            relative_path = file_url.replace("/uploads/", "")
            return self.base_upload_dir / relative_path
        return None
    
    async def get_audio_duration(self, file_path: str) -> float:
        """Get audio file duration in seconds (requires ffmpeg or librosa)"""
        try:
            # Try using ffprobe (part of ffmpeg)
            import subprocess
            result = subprocess.run(
                ["ffprobe", "-v", "error", "-show_entries", "format=duration", 
                 "-of", "default=noprint_wrappers=1:nokey=1", file_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            if result.returncode == 0:
                return float(result.stdout.strip())
        except Exception:
            pass
        
        return 0.0  # Return 0 if unable to determine


# Global storage service instance
_storage_service: Optional[StorageService] = None


def get_storage_service() -> StorageService:
    """Get or create storage service singleton"""
    global _storage_service
    if _storage_service is None:
        _storage_service = StorageService()
    return _storage_service
