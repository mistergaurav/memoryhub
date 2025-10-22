from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from bson import ObjectId
from datetime import datetime

from app.models.family.legacy_letters import (
    LegacyLetterCreate, LegacyLetterUpdate, LegacyLetterResponse,
    ReceivedLetterResponse
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.utils.validators import safe_object_id

router = APIRouter()



@router.post("/", response_model=LegacyLetterResponse, status_code=status.HTTP_201_CREATED)
async def create_legacy_letter(
    letter: LegacyLetterCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new legacy letter"""
    try:
        recipient_oids = [safe_object_id(rid) for rid in letter.recipient_ids if safe_object_id(rid)]
        
        if not recipient_oids:
            raise HTTPException(status_code=400, detail="At least one valid recipient required")
        
        letter_data = {
            "title": letter.title,
            "content": letter.content,
            "delivery_date": letter.delivery_date,
            "encrypt": letter.encrypt,
            "author_id": ObjectId(current_user.id),
            "recipient_ids": recipient_oids,
            "attachments": letter.attachments,
            "status": "draft" if letter.delivery_date > datetime.utcnow() else "scheduled",
            "delivered_at": None,
            "read_by": [],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("legacy_letters").insert_one(letter_data)
        letter_doc = await get_collection("legacy_letters").find_one({"_id": result.inserted_id})
        
        if not letter_doc:
            raise HTTPException(status_code=500, detail="Failed to create letter")
        
        recipient_names = []
        for recipient_id in letter_doc.get("recipient_ids", []):
            user = await get_collection("users").find_one({"_id": recipient_id})
            if user:
                recipient_names.append(user.get("full_name", ""))
        
        return LegacyLetterResponse(
            id=str(letter_doc["_id"]),
            title=letter_doc["title"],
            content=None,
            delivery_date=letter_doc["delivery_date"],
            encrypt=letter_doc["encrypt"],
            author_id=str(letter_doc["author_id"]),
            author_name=current_user.full_name,
            recipient_ids=[str(rid) for rid in letter_doc["recipient_ids"]],
            recipient_names=recipient_names,
            attachments=letter_doc.get("attachments", []),
            status=letter_doc["status"],
            delivered_at=letter_doc.get("delivered_at"),
            read_count=len(letter_doc.get("read_by", [])),
            created_at=letter_doc["created_at"],
            updated_at=letter_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create letter: {str(e)}")


@router.get("/sent", response_model=List[LegacyLetterResponse])
async def list_sent_letters(
    current_user: UserInDB = Depends(get_current_user)
):
    """List letters sent by the current user"""
    try:
        user_oid = ObjectId(current_user.id)
        
        letters_cursor = get_collection("legacy_letters").find({
            "author_id": user_oid
        }).sort("created_at", -1)
        
        letters = []
        async for letter_doc in letters_cursor:
            recipient_names = []
            for recipient_id in letter_doc.get("recipient_ids", []):
                user = await get_collection("users").find_one({"_id": recipient_id})
                if user:
                    recipient_names.append(user.get("full_name", ""))
            
            letters.append(LegacyLetterResponse(
                id=str(letter_doc["_id"]),
                title=letter_doc["title"],
                content=None,
                delivery_date=letter_doc["delivery_date"],
                encrypt=letter_doc["encrypt"],
                author_id=str(letter_doc["author_id"]),
                author_name=current_user.full_name,
                recipient_ids=[str(rid) for rid in letter_doc["recipient_ids"]],
                recipient_names=recipient_names,
                attachments=letter_doc.get("attachments", []),
                status=letter_doc["status"],
                delivered_at=letter_doc.get("delivered_at"),
                read_count=len(letter_doc.get("read_by", [])),
                created_at=letter_doc["created_at"],
                updated_at=letter_doc["updated_at"]
            ))
        
        return letters
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list sent letters: {str(e)}")


@router.get("/received", response_model=List[ReceivedLetterResponse])
async def list_received_letters(
    current_user: UserInDB = Depends(get_current_user)
):
    """List letters received by the current user"""
    try:
        user_oid = ObjectId(current_user.id)
        
        letters_cursor = get_collection("legacy_letters").find({
            "recipient_ids": user_oid,
            "status": {"$in": ["delivered", "read"]}
        }).sort("delivered_at", -1)
        
        letters = []
        async for letter_doc in letters_cursor:
            author = await get_collection("users").find_one({"_id": letter_doc["author_id"]})
            
            letters.append(ReceivedLetterResponse(
                id=str(letter_doc["_id"]),
                title=letter_doc["title"],
                content=letter_doc["content"],
                delivery_date=letter_doc["delivery_date"],
                author_id=str(letter_doc["author_id"]),
                author_name=author.get("full_name") if author else None,
                attachments=letter_doc.get("attachments", []),
                delivered_at=letter_doc["delivered_at"],
                is_read=user_oid in letter_doc.get("read_by", []),
                created_at=letter_doc["created_at"]
            ))
        
        return letters
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list received letters: {str(e)}")


@router.get("/{letter_id}", response_model=LegacyLetterResponse)
async def get_legacy_letter(
    letter_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific letter"""
    try:
        letter_oid = safe_object_id(letter_id)
        if not letter_oid:
            raise HTTPException(status_code=400, detail="Invalid letter ID")
        
        letter_doc = await get_collection("legacy_letters").find_one({"_id": letter_oid})
        if not letter_doc:
            raise HTTPException(status_code=404, detail="Letter not found")
        
        user_oid = ObjectId(current_user.id)
        
        if str(letter_doc["author_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to view this letter")
        
        author = await get_collection("users").find_one({"_id": letter_doc["author_id"]})
        
        recipient_names = []
        for recipient_id in letter_doc.get("recipient_ids", []):
            user = await get_collection("users").find_one({"_id": recipient_id})
            if user:
                recipient_names.append(user.get("full_name", ""))
        
        return LegacyLetterResponse(
            id=str(letter_doc["_id"]),
            title=letter_doc["title"],
            content=letter_doc["content"] if str(letter_doc["author_id"]) == current_user.id else None,
            delivery_date=letter_doc["delivery_date"],
            encrypt=letter_doc["encrypt"],
            author_id=str(letter_doc["author_id"]),
            author_name=author.get("full_name") if author else None,
            recipient_ids=[str(rid) for rid in letter_doc["recipient_ids"]],
            recipient_names=recipient_names,
            attachments=letter_doc.get("attachments", []),
            status=letter_doc["status"],
            delivered_at=letter_doc.get("delivered_at"),
            read_count=len(letter_doc.get("read_by", [])),
            created_at=letter_doc["created_at"],
            updated_at=letter_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get letter: {str(e)}")


@router.put("/{letter_id}", response_model=LegacyLetterResponse)
async def update_legacy_letter(
    letter_id: str,
    letter_update: LegacyLetterUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a letter (only if not delivered yet)"""
    try:
        letter_oid = safe_object_id(letter_id)
        if not letter_oid:
            raise HTTPException(status_code=400, detail="Invalid letter ID")
        
        letter_doc = await get_collection("legacy_letters").find_one({"_id": letter_oid})
        if not letter_doc:
            raise HTTPException(status_code=404, detail="Letter not found")
        
        if str(letter_doc["author_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this letter")
        
        if letter_doc["status"] in ["delivered", "read"]:
            raise HTTPException(status_code=400, detail="Cannot update a delivered letter")
        
        update_data = {k: v for k, v in letter_update.dict(exclude_unset=True).items() if v is not None}
        
        if "recipient_ids" in update_data:
            update_data["recipient_ids"] = [safe_object_id(rid) for rid in update_data["recipient_ids"] if safe_object_id(rid)]
        
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("legacy_letters").update_one(
            {"_id": letter_oid},
            {"$set": update_data}
        )
        
        updated_letter = await get_collection("legacy_letters").find_one({"_id": letter_oid})
        if not updated_letter:
            raise HTTPException(status_code=404, detail="Letter not found after update")
        
        author = await get_collection("users").find_one({"_id": updated_letter["author_id"]})
        
        recipient_names = []
        for recipient_id in updated_letter.get("recipient_ids", []):
            user = await get_collection("users").find_one({"_id": recipient_id})
            if user:
                recipient_names.append(user.get("full_name", ""))
        
        return LegacyLetterResponse(
            id=str(updated_letter["_id"]),
            title=updated_letter["title"],
            content=None,
            delivery_date=updated_letter["delivery_date"],
            encrypt=updated_letter["encrypt"],
            author_id=str(updated_letter["author_id"]),
            author_name=author.get("full_name") if author else None,
            recipient_ids=[str(rid) for rid in updated_letter["recipient_ids"]],
            recipient_names=recipient_names,
            attachments=updated_letter.get("attachments", []),
            status=updated_letter["status"],
            delivered_at=updated_letter.get("delivered_at"),
            read_count=len(updated_letter.get("read_by", [])),
            created_at=updated_letter["created_at"],
            updated_at=updated_letter["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update letter: {str(e)}")


@router.delete("/{letter_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_legacy_letter(
    letter_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a letter (only if not delivered yet)"""
    try:
        letter_oid = safe_object_id(letter_id)
        if not letter_oid:
            raise HTTPException(status_code=400, detail="Invalid letter ID")
        
        letter_doc = await get_collection("legacy_letters").find_one({"_id": letter_oid})
        if not letter_doc:
            raise HTTPException(status_code=404, detail="Letter not found")
        
        if str(letter_doc["author_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this letter")
        
        if letter_doc["status"] in ["delivered", "read"]:
            raise HTTPException(status_code=400, detail="Cannot delete a delivered letter")
        
        await get_collection("legacy_letters").delete_one({"_id": letter_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete letter: {str(e)}")


@router.post("/{letter_id}/mark-read", status_code=status.HTTP_200_OK)
async def mark_letter_read(
    letter_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark a received letter as read"""
    try:
        letter_oid = safe_object_id(letter_id)
        if not letter_oid:
            raise HTTPException(status_code=400, detail="Invalid letter ID")
        
        user_oid = ObjectId(current_user.id)
        
        letter_doc = await get_collection("legacy_letters").find_one({"_id": letter_oid})
        if not letter_doc:
            raise HTTPException(status_code=404, detail="Letter not found")
        
        if user_oid not in letter_doc.get("recipient_ids", []):
            raise HTTPException(status_code=403, detail="Not a recipient of this letter")
        
        await get_collection("legacy_letters").update_one(
            {"_id": letter_oid},
            {
                "$addToSet": {"read_by": user_oid},
                "$set": {"status": "read"}
            }
        )
        
        return {"message": "Letter marked as read"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to mark letter as read: {str(e)}")
