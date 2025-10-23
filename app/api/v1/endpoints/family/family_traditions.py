from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.family.family_traditions import (
    FamilyTraditionCreate, FamilyTraditionUpdate, FamilyTraditionResponse
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.family_repository import FamilyTraditionsRepository, UserRepository
from app.utils.validators import validate_object_ids
from app.utils.audit_logger import log_audit_event
from app.models.responses import create_success_response, create_paginated_response, create_message_response

router = APIRouter()
traditions_repo = FamilyTraditionsRepository()
user_repo = UserRepository()


async def get_creator_name(created_by_id: ObjectId) -> Optional[str]:
    """Helper function to get creator name"""
    return await user_repo.get_user_name(str(created_by_id))


def build_tradition_response(tradition_doc: Dict[str, Any], creator_name: Optional[str] = None) -> FamilyTraditionResponse:
    """Helper function to build tradition response"""
    return FamilyTraditionResponse(
        id=str(tradition_doc["_id"]),
        title=tradition_doc["title"],
        description=tradition_doc["description"],
        category=tradition_doc["category"],
        frequency=tradition_doc["frequency"],
        typical_date=tradition_doc.get("typical_date"),
        origin_story=tradition_doc.get("origin_story"),
        instructions=tradition_doc.get("instructions"),
        photos=tradition_doc.get("photos", []),
        videos=tradition_doc.get("videos", []),
        created_by=str(tradition_doc["created_by"]),
        created_by_name=creator_name,
        family_circle_ids=[str(cid) for cid in tradition_doc.get("family_circle_ids", [])],
        followers_count=len(tradition_doc.get("followers", [])),
        created_at=tradition_doc["created_at"],
        updated_at=tradition_doc["updated_at"]
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_tradition(
    tradition: FamilyTraditionCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a new family tradition.
    
    - Validates circle IDs
    - Creates tradition with category and frequency
    - Logs creation for audit trail
    """
    family_circle_oids = validate_object_ids(tradition.family_circle_ids, "family_circle_ids") if tradition.family_circle_ids else []
    
    tradition_data = {
        "title": tradition.title,
        "description": tradition.description,
        "category": tradition.category,
        "frequency": tradition.frequency,
        "typical_date": tradition.typical_date,
        "origin_story": tradition.origin_story,
        "instructions": tradition.instructions,
        "photos": tradition.photos,
        "videos": tradition.videos,
        "created_by": ObjectId(current_user.id),
        "family_circle_ids": family_circle_oids,
        "followers": [],
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    tradition_doc = await traditions_repo.create(tradition_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="tradition_created",
        event_details={
            "tradition_id": str(tradition_doc["_id"]),
            "title": tradition.title,
            "category": tradition.category
        }
    )
    
    response = build_tradition_response(tradition_doc, current_user.full_name)
    
    return create_success_response(
        message="Tradition created successfully",
        data=response.model_dump()
    )


@router.get("/")
async def list_traditions(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of traditions per page"),
    category: Optional[str] = Query(None, description="Filter by category"),
    frequency: Optional[str] = Query(None, description="Filter by frequency"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List all traditions with pagination and optional filtering.
    
    - Supports pagination with configurable page size
    - Filters by category and frequency
    - Includes creator information and follower counts
    """
    skip = (page - 1) * page_size
    
    traditions = await traditions_repo.find_user_traditions(
        user_id=str(current_user.id),
        category=category,
        frequency=frequency,
        skip=skip,
        limit=page_size
    )
    
    total = await traditions_repo.count_user_traditions(
        user_id=str(current_user.id),
        category=category,
        frequency=frequency
    )
    
    tradition_responses = []
    for tradition_doc in traditions:
        creator_name = await get_creator_name(tradition_doc["created_by"])
        tradition_responses.append(build_tradition_response(tradition_doc, creator_name))
    
    return create_paginated_response(
        items=[t.model_dump() for t in tradition_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Traditions retrieved successfully"
    )


@router.get("/{tradition_id}")
async def get_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a specific tradition by ID.
    
    - Returns complete tradition details
    - Includes follower count
    """
    tradition_doc = await traditions_repo.find_by_id(
        tradition_id,
        raise_404=True,
        error_message="Tradition not found"
    )
    assert tradition_doc is not None
    
    creator_name = await get_creator_name(tradition_doc["created_by"])
    response = build_tradition_response(tradition_doc, creator_name)
    
    return create_success_response(
        message="Tradition retrieved successfully",
        data=response.model_dump()
    )


@router.put("/{tradition_id}")
async def update_tradition(
    tradition_id: str,
    tradition_update: FamilyTraditionUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Update a tradition (owner only).
    
    - Only tradition creator can update
    - Validates IDs if provided
    - Logs update for audit trail
    """
    await traditions_repo.check_tradition_ownership(tradition_id, str(current_user.id), raise_error=True)
    
    update_data = {k: v for k, v in tradition_update.model_dump(exclude_unset=True).items() if v is not None}
    
    if "family_circle_ids" in update_data:
        update_data["family_circle_ids"] = validate_object_ids(update_data["family_circle_ids"], "family_circle_ids")
    
    update_data["updated_at"] = datetime.utcnow()
    
    updated_tradition = await traditions_repo.update_by_id(tradition_id, update_data)
    assert updated_tradition is not None
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="tradition_updated",
        event_details={
            "tradition_id": tradition_id,
            "updated_fields": list(update_data.keys())
        }
    )
    
    creator_name = await get_creator_name(updated_tradition["created_by"])
    response = build_tradition_response(updated_tradition, creator_name)
    
    return create_success_response(
        message="Tradition updated successfully",
        data=response.model_dump()
    )


@router.delete("/{tradition_id}", status_code=status.HTTP_200_OK)
async def delete_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete a tradition (owner only).
    
    - Only tradition creator can delete
    - Logs deletion for audit trail (GDPR compliance)
    """
    tradition_doc = await traditions_repo.find_by_id(tradition_id, raise_404=True)
    assert tradition_doc is not None
    
    await traditions_repo.check_tradition_ownership(tradition_id, str(current_user.id), raise_error=True)
    
    await traditions_repo.delete_by_id(tradition_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="tradition_deleted",
        event_details={
            "tradition_id": tradition_id,
            "title": tradition_doc.get("title")
        }
    )
    
    return create_message_response("Tradition deleted successfully")


@router.post("/{tradition_id}/follow", status_code=status.HTTP_200_OK)
async def follow_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Follow a tradition to receive updates.
    
    - Adds user to followers list
    - Tracks tradition engagement
    """
    await traditions_repo.find_by_id(tradition_id, raise_404=True, error_message="Tradition not found")
    
    await traditions_repo.toggle_follow(
        tradition_id=tradition_id,
        user_id=str(current_user.id),
        add_follow=True
    )
    
    return create_message_response("Now following this tradition")


@router.delete("/{tradition_id}/follow", status_code=status.HTTP_200_OK)
async def unfollow_tradition(
    tradition_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Unfollow a tradition.
    
    - Removes user from followers list
    """
    await traditions_repo.find_by_id(tradition_id, raise_404=True, error_message="Tradition not found")
    
    await traditions_repo.toggle_follow(
        tradition_id=tradition_id,
        user_id=str(current_user.id),
        add_follow=False
    )
    
    return create_message_response("Unfollowed tradition")
