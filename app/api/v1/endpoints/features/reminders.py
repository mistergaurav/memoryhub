from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

class ReminderCreate(BaseModel):
    title: str
    description: Optional[str] = None
    reminder_date: datetime
    memory_id: Optional[str] = None

class ReminderUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    reminder_date: Optional[datetime] = None
    is_completed: Optional[bool] = None

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_reminder(
    reminder: ReminderCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new reminder"""
    reminder_data = {
        "title": reminder.title,
        "description": reminder.description,
        "reminder_date": reminder.reminder_date,
        "user_id": ObjectId(current_user.id),
        "is_completed": False,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    if reminder.memory_id:
        memory = await get_collection("memories").find_one({"_id": ObjectId(reminder.memory_id)})
        if memory:
            reminder_data["memory_id"] = ObjectId(reminder.memory_id)
    
    result = await get_collection("reminders").insert_one(reminder_data)
    reminder_doc = await get_collection("reminders").find_one({"_id": result.inserted_id})
    
    if reminder_doc:
        reminder_doc["id"] = str(reminder_doc.pop("_id"))
        reminder_doc["user_id"] = str(reminder_doc["user_id"])
        if "memory_id" in reminder_doc:
            reminder_doc["memory_id"] = str(reminder_doc["memory_id"])
    
    return reminder_doc

@router.get("/")
async def list_reminders(
    is_completed: Optional[bool] = None,
    upcoming: bool = False,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """List reminders"""
    query = {"user_id": ObjectId(current_user.id)}
    
    if is_completed is not None:
        query["is_completed"] = is_completed
    
    if upcoming:
        query["reminder_date"] = {"$gte": datetime.utcnow()}
        query["is_completed"] = False
    
    total = await get_collection("reminders").count_documents(query)
    skip = (page - 1) * limit
    
    cursor = get_collection("reminders").find(query).sort("reminder_date", 1).skip(skip).limit(limit)
    
    reminders = []
    async for reminder_doc in cursor:
        reminder_doc["id"] = str(reminder_doc.pop("_id"))
        reminder_doc["user_id"] = str(reminder_doc["user_id"])
        if "memory_id" in reminder_doc:
            reminder_doc["memory_id"] = str(reminder_doc["memory_id"])
        reminders.append(reminder_doc)
    
    return {
        "reminders": reminders,
        "total": total,
        "page": page,
        "pages": (total + limit - 1) // limit
    }

@router.put("/{reminder_id}")
async def update_reminder(
    reminder_id: str,
    reminder_update: ReminderUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a reminder"""
    reminder_doc = await get_collection("reminders").find_one({
        "_id": ObjectId(reminder_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if not reminder_doc:
        raise HTTPException(status_code=404, detail="Reminder not found")
    
    update_data = reminder_update.dict(exclude_unset=True)
    update_data["updated_at"] = datetime.utcnow()
    
    await get_collection("reminders").update_one(
        {"_id": ObjectId(reminder_id)},
        {"$set": update_data}
    )
    
    updated_doc = await get_collection("reminders").find_one({"_id": ObjectId(reminder_id)})
    
    if updated_doc:
        updated_doc["id"] = str(updated_doc.pop("_id"))
        updated_doc["user_id"] = str(updated_doc["user_id"])
        if "memory_id" in updated_doc:
            updated_doc["memory_id"] = str(updated_doc["memory_id"])
    
    return updated_doc

@router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(
    reminder_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a reminder"""
    result = await get_collection("reminders").delete_one({
        "_id": ObjectId(reminder_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Reminder not found")
