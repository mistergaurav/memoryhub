from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database
import os

router = APIRouter()

@router.post("/")
async def create_voice_note(
    title: str = Form(...),
    description: Optional[str] = Form(None),
    tags: Optional[str] = Form(None),
    audio_file: UploadFile = File(...),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a voice note with actual audio file storage"""
    from app.services import get_storage_service
    
    db = get_database()
    storage = get_storage_service()
    
    # Validate audio file type
    if not audio_file.content_type or not audio_file.content_type.startswith("audio/"):
        raise HTTPException(status_code=400, detail="File must be an audio file")
    
    # Save audio file to storage
    try:
        file_path, file_url, file_size = await storage.save_file(
            file=audio_file,
            user_id=str(current_user.id),
            category="audio"
        )
        
        # Get audio duration if possible
        duration = await storage.get_audio_duration(file_path)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save audio file: {str(e)}")
    
    voice_note_data = {
        "user_id": str(current_user.id),
        "title": title,
        "description": description,
        "tags": tags.split(",") if tags else [],
        "audio_url": file_url,
        "file_path": file_path,
        "duration": duration,
        "file_size": file_size,
        "original_filename": audio_file.filename,
        "content_type": audio_file.content_type,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.voice_notes.insert_one(voice_note_data)
    voice_note_data["_id"] = str(result.inserted_id)
    
    return voice_note_data

@router.get("/")
async def get_voice_notes(
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get user's voice notes"""
    db = get_database()
    
    skip = (page - 1) * limit
    voice_notes = await db.voice_notes.find({
        "user_id": str(current_user.id)
    }).sort("created_at", -1).skip(skip).limit(limit).to_list(limit)
    
    for note in voice_notes:
        note["_id"] = str(note["_id"])
    
    return voice_notes

@router.get("/{note_id}")
async def get_voice_note(
    note_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific voice note"""
    db = get_database()
    
    note = await db.voice_notes.find_one({"_id": ObjectId(note_id)})
    if not note:
        raise HTTPException(status_code=404, detail="Voice note not found")
    
    # Verify ownership
    if note["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to access this voice note")
    
    note["_id"] = str(note["_id"])
    return note

@router.delete("/{note_id}")
async def delete_voice_note(
    note_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a voice note"""
    db = get_database()
    
    note = await db.voice_notes.find_one({"_id": ObjectId(note_id)})
    if not note:
        raise HTTPException(status_code=404, detail="Voice note not found")
    
    if note["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await db.voice_notes.delete_one({"_id": ObjectId(note_id)})
    
    return {"message": "Voice note deleted"}

@router.post("/{note_id}/transcribe")
async def transcribe_voice_note(
    note_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Transcribe a voice note to text using Whisper AI or similar service"""
    db = get_database()
    
    note = await db.voice_notes.find_one({"_id": ObjectId(note_id)})
    if not note:
        raise HTTPException(status_code=404, detail="Voice note not found")
    
    # Verify ownership
    if note["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to transcribe this voice note")
    
    # Check if already transcribed
    if note.get("transcription"):
        return {
            "transcription": note["transcription"],
            "transcribed_at": note.get("transcribed_at"),
            "cached": True
        }
    
    # Try to transcribe using OpenAI Whisper API (if configured)
    transcription = None
    openai_api_key = os.getenv("OPENAI_API_KEY")
    
    if openai_api_key and note.get("file_path"):
        try:
            import httpx
            
            file_path = note.get("file_path")
            if os.path.exists(file_path):
                # Call OpenAI Whisper API
                async with httpx.AsyncClient() as client:
                    with open(file_path, "rb") as audio_file:
                        files = {"file": (note.get("original_filename", "audio.mp3"), audio_file, note.get("content_type", "audio/mpeg"))}
                        data = {"model": "whisper-1"}
                        
                        response = await client.post(
                            "https://api.openai.com/v1/audio/transcriptions",
                            headers={"Authorization": f"Bearer {openai_api_key}"},
                            files=files,
                            data=data,
                            timeout=60.0
                        )
                        
                        if response.status_code == 200:
                            result = response.json()
                            transcription = result.get("text", "")
        except Exception as e:
            print(f"Transcription failed: {e}")
    
    # Fallback if transcription not available
    if not transcription:
        transcription = "[Transcription service not configured. Please add OPENAI_API_KEY to enable automatic transcription.]"
    
    # Save transcription
    transcribed_at = datetime.utcnow()
    await db.voice_notes.update_one(
        {"_id": ObjectId(note_id)},
        {
            "$set": {
                "transcription": transcription,
                "transcribed_at": transcribed_at
            }
        }
    )
    
    return {
        "transcription": transcription,
        "transcribed_at": transcribed_at,
        "cached": False
    }
