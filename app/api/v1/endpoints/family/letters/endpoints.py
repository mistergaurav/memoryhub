from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from .schemas import (
    LegacyLetterCreate, LegacyLetterUpdate, LegacyLetterResponse,
    ReceivedLetterResponse
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from .repository import LegacyLettersRepository
from app.repositories.family_repository import UserRepository
from app.utils.validators import validate_object_ids
from app.utils.audit_logger import log_audit_event
from app.models.responses import create_success_response, create_paginated_response, create_message_response

router = APIRouter()
letters_repo = LegacyLettersRepository()
user_repo = UserRepository()


async def get_recipient_names(recipient_ids: List[ObjectId]) -> List[str]:
    """Helper function to get recipient names efficiently"""
    if not recipient_ids:
        return []
    
    user_id_strs = [str(rid) for rid in recipient_ids]
    user_names_dict = await user_repo.get_user_names(user_id_strs)
    return [user_names_dict.get(uid, "") for uid in user_id_strs]


async def get_author_name(author_id: ObjectId) -> Optional[str]:
    """Helper function to get author name"""
    return await user_repo.get_user_name(str(author_id))


def build_letter_response(letter_doc: Dict[str, Any], author_name: Optional[str] = None, recipient_names: Optional[List[str]] = None, include_content: bool = False) -> LegacyLetterResponse:
    """Helper function to build letter response"""
    return LegacyLetterResponse(
        id=str(letter_doc["_id"]),
        title=letter_doc["title"],
        content=letter_doc.get("content") if include_content else None,
        delivery_date=letter_doc["delivery_date"],
        encrypt=letter_doc["encrypt"],
        author_id=str(letter_doc["author_id"]),
        author_name=author_name,
        recipient_ids=[str(rid) for rid in letter_doc["recipient_ids"]],
        recipient_names=recipient_names or [],
        attachments=letter_doc.get("attachments", []),
        status=letter_doc["status"],
        delivered_at=letter_doc.get("delivered_at"),
        read_count=len(letter_doc.get("read_by", [])),
        created_at=letter_doc["created_at"],
        updated_at=letter_doc["updated_at"]
    )


def build_received_letter_response(letter_doc: Dict[str, Any], author_name: Optional[str] = None, user_id: Optional[str] = None) -> ReceivedLetterResponse:
    """Helper function to build received letter response"""
    user_oid = ObjectId(user_id) if user_id else None
    is_read = user_oid in letter_doc.get("read_by", []) if user_oid else False
    
    return ReceivedLetterResponse(
        id=str(letter_doc["_id"]),
        title=letter_doc["title"],
        content=letter_doc["content"],
        delivery_date=letter_doc["delivery_date"],
        author_id=str(letter_doc["author_id"]),
        author_name=author_name,
        attachments=letter_doc.get("attachments", []),
        delivered_at=letter_doc["delivered_at"],
        is_read=is_read,
        created_at=letter_doc["created_at"]
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_legacy_letter(
    letter: LegacyLetterCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a new legacy letter for future delivery.
    
    - Validates recipient IDs
    - Sets delivery date and encryption options
    - Determines status based on delivery date
    - Logs creation for audit trail
    """
    recipient_oids = validate_object_ids(letter.recipient_ids, "recipient_ids")
    
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
    
    letter_doc = await letters_repo.create(letter_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="legacy_letter_created",
        event_details={
            "letter_id": str(letter_doc["_id"]),
            "title": letter.title,
            "recipient_count": len(recipient_oids),
            "delivery_date": letter.delivery_date.isoformat()
        }
    )
    
    recipient_names = await get_recipient_names(letter_doc["recipient_ids"])
    response = build_letter_response(letter_doc, current_user.full_name, recipient_names)
    
    return create_success_response(
        message="Legacy letter created successfully",
        data=response.model_dump()
    )


@router.get("/")
async def list_legacy_letters(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of letters per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List all legacy letters for the current user with pagination.
    
    - Returns all letters authored by the user (sent letters)
    - Includes recipient information
    - Content is hidden for privacy until delivered
    """
    skip = (page - 1) * page_size
    
    letters = await letters_repo.find_sent_letters(
        author_id=str(current_user.id),
        skip=skip,
        limit=page_size
    )
    
    total = await letters_repo.count_sent_letters(str(current_user.id))
    
    letter_responses = []
    for letter_doc in letters:
        recipient_names = await get_recipient_names(letter_doc.get("recipient_ids", []))
        letter_responses.append(build_letter_response(letter_doc, current_user.full_name, recipient_names))
    
    return create_paginated_response(
        items=[l.model_dump() for l in letter_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Legacy letters retrieved successfully"
    )


@router.get("/sent")
async def list_sent_letters(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of letters per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List letters sent by the current user with pagination.
    
    - Returns all letters authored by the user
    - Includes recipient information
    - Content is hidden for privacy until delivered
    """
    skip = (page - 1) * page_size
    
    letters = await letters_repo.find_sent_letters(
        author_id=str(current_user.id),
        skip=skip,
        limit=page_size
    )
    
    total = await letters_repo.count_sent_letters(str(current_user.id))
    
    letter_responses = []
    for letter_doc in letters:
        recipient_names = await get_recipient_names(letter_doc.get("recipient_ids", []))
        letter_responses.append(build_letter_response(letter_doc, current_user.full_name, recipient_names))
    
    return create_paginated_response(
        items=[l.model_dump() for l in letter_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Sent letters retrieved successfully"
    )


@router.get("/received")
async def list_received_letters(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of letters per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List letters received by the current user with pagination.
    
    - Returns only delivered letters
    - Includes full content for delivered letters
    - Tracks read status
    """
    skip = (page - 1) * page_size
    
    letters = await letters_repo.find_received_letters(
        recipient_id=str(current_user.id),
        skip=skip,
        limit=page_size
    )
    
    total = await letters_repo.count_received_letters(str(current_user.id))
    
    letter_responses = []
    for letter_doc in letters:
        author_name = await get_author_name(letter_doc["author_id"])
        letter_responses.append(build_received_letter_response(letter_doc, author_name, str(current_user.id)))
    
    return create_paginated_response(
        items=[l.model_dump() for l in letter_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Received letters retrieved successfully"
    )


@router.get("/{letter_id}")
async def get_legacy_letter(
    letter_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a specific letter (author only).
    
    - Only the author can view their sent letters
    - Includes full content and recipient information
    """
    letter_doc = await letters_repo.find_by_id(
        letter_id,
        raise_404=True,
        error_message="Letter not found"
    )
    assert letter_doc is not None
    
    await letters_repo.check_letter_ownership(letter_id, str(current_user.id), raise_error=True)
    
    author_name = await get_author_name(letter_doc["author_id"])
    recipient_names = await get_recipient_names(letter_doc.get("recipient_ids", []))
    
    response = build_letter_response(letter_doc, author_name, recipient_names, include_content=True)
    
    return create_success_response(
        message="Letter retrieved successfully",
        data=response.model_dump()
    )


@router.put("/{letter_id}")
async def update_legacy_letter(
    letter_id: str,
    letter_update: LegacyLetterUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Update a letter (author only, before delivery).
    
    - Only letter author can update
    - Cannot update after delivery
    - Validates recipient IDs if provided
    - Logs update for audit trail
    """
    letter_doc = await letters_repo.find_by_id(letter_id, raise_404=True)
    assert letter_doc is not None
    
    await letters_repo.check_letter_ownership(letter_id, str(current_user.id), raise_error=True)
    
    if letter_doc["status"] in ["delivered", "read"]:
        raise HTTPException(status_code=400, detail="Cannot update a delivered letter")
    
    update_data = {k: v for k, v in letter_update.model_dump(exclude_unset=True).items() if v is not None}
    
    if "recipient_ids" in update_data:
        update_data["recipient_ids"] = validate_object_ids(update_data["recipient_ids"], "recipient_ids")
    
    update_data["updated_at"] = datetime.utcnow()
    
    updated_letter = await letters_repo.update_by_id(letter_id, update_data)
    assert updated_letter is not None
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="legacy_letter_updated",
        event_details={
            "letter_id": letter_id,
            "updated_fields": list(update_data.keys())
        }
    )
    
    author_name = await get_author_name(updated_letter["author_id"])
    recipient_names = await get_recipient_names(updated_letter.get("recipient_ids", []))
    
    response = build_letter_response(updated_letter, author_name, recipient_names)
    
    return create_success_response(
        message="Letter updated successfully",
        data=response.model_dump()
    )


@router.delete("/{letter_id}", status_code=status.HTTP_200_OK)
async def delete_legacy_letter(
    letter_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete a letter (author only, before delivery).
    
    - Only letter author can delete
    - Cannot delete after delivery
    - Logs deletion for audit trail (GDPR compliance)
    """
    letter_doc = await letters_repo.find_by_id(letter_id, raise_404=True)
    assert letter_doc is not None
    
    await letters_repo.check_letter_ownership(letter_id, str(current_user.id), raise_error=True)
    
    if letter_doc["status"] in ["delivered", "read"]:
        raise HTTPException(status_code=400, detail="Cannot delete a delivered letter")
    
    await letters_repo.delete_by_id(letter_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="legacy_letter_deleted",
        event_details={
            "letter_id": letter_id,
            "title": letter_doc.get("title")
        }
    )
    
    return create_message_response("Letter deleted successfully")


@router.post("/{letter_id}/mark-read", status_code=status.HTTP_200_OK)
async def mark_letter_read(
    letter_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Mark a received letter as read.
    
    - Only recipients can mark as read
    - Updates read status and count
    """
    letter_doc = await letters_repo.find_by_id(letter_id, raise_404=True)
    assert letter_doc is not None
    
    await letters_repo.check_recipient_access(letter_id, str(current_user.id), raise_error=True)
    
    await letters_repo.mark_as_read(letter_id, str(current_user.id))
    
    return create_message_response("Letter marked as read")
