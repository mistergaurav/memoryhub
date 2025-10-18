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
    """Create a voice note"""
    db = get_database()
    
    # Save audio file
    filename_str = audio_file.filename or "audio.mp3"
    file_extension = os.path.splitext(filename_str)[1]
    filename = f"voice_{ObjectId()}_{audio_file.filename}"
    
    voice_note_data = {
        "user_id": str(current_user.id),
        "title": title,
        "description": description,
        "tags": tags.split(",") if tags else [],
        "audio_url": f"/voice-notes/media/{filename}",
        "duration": 0,  # To be calculated
        "file_size": 0,
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
    """Transcribe a voice note to text (placeholder for future integration)"""
    db = get_database()
    
    note = await db.voice_notes.find_one({"_id": ObjectId(note_id)})
    if not note:
        raise HTTPException(status_code=404, detail="Voice note not found")
    
    # Verify ownership
    if note["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to transcribe this voice note")
    
    # Placeholder for transcription service integration
    transcription = "Transcription feature coming soon..."
    
    await db.voice_notes.update_one(
        {"_id": ObjectId(note_id)},
        {"$set": {"transcription": transcription}}
    )
    
    return {"transcription": transcription}
