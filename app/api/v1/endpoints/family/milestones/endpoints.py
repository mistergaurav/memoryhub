from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from .schemas import (
    FamilyMilestoneCreate, FamilyMilestoneUpdate, FamilyMilestoneResponse
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from .repository import FamilyMilestonesRepository
from app.repositories.family_repository import UserRepository
from app.utils.validators import validate_object_ids
from app.utils.audit_logger import log_audit_event
from app.models.responses import create_success_response, create_paginated_response, create_message_response

router = APIRouter()
milestones_repo = FamilyMilestonesRepository()
user_repo = UserRepository()


async def get_person_name(person_id: Optional[ObjectId]) -> Optional[str]:
    """Helper function to get person name"""
    if not person_id:
        return None
    return await user_repo.get_user_name(str(person_id))


async def get_creator_name(created_by_id: ObjectId) -> Optional[str]:
    """Helper function to get creator name"""
    return await user_repo.get_user_name(str(created_by_id))


def build_milestone_response(milestone_doc: Dict[str, Any], creator_name: Optional[str] = None) -> FamilyMilestoneResponse:
    """Helper function to build milestone response"""
    return FamilyMilestoneResponse(
        id=str(milestone_doc["_id"]),
        title=milestone_doc["title"],
        description=milestone_doc.get("description"),
        milestone_type=milestone_doc["milestone_type"],
        milestone_date=milestone_doc["milestone_date"],
        person_id=str(milestone_doc["person_id"]) if milestone_doc.get("person_id") else None,
        person_name=milestone_doc.get("person_name"),
        genealogy_person_id=str(milestone_doc["genealogy_person_id"]) if milestone_doc.get("genealogy_person_id") else None,
        genealogy_person_name=milestone_doc.get("genealogy_person_name"),
        photos=milestone_doc.get("photos", []),
        created_by=str(milestone_doc["created_by"]),
        created_by_name=creator_name,
        family_circle_ids=[str(cid) for cid in milestone_doc.get("family_circle_ids", [])],
        likes_count=len(milestone_doc.get("likes", [])),
        auto_generated=milestone_doc.get("auto_generated", False),
        generation=milestone_doc.get("generation"),
        created_at=milestone_doc["created_at"],
        updated_at=milestone_doc["updated_at"]
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_milestone(
    milestone: FamilyMilestoneCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a new family milestone.
    
    - Supports various milestone types (birth, graduation, wedding, etc.)
    - Can link to specific family members
    - Supports photo attachments
    - Tracks genealogy integration
    """
    # Convert circle_ids to ObjectIds
    family_circle_oids = validate_object_ids(milestone.family_circle_ids, "family_circle_ids") if milestone.family_circle_ids else []
    
    # If no family circles provided, default to current user's ID (personal timeline)
    if not family_circle_oids:
        family_circle_oids.append(ObjectId(current_user.id))
    
    person_oid = None
    person_name = None
    if milestone.person_id:
        person_oid = ObjectId(milestone.person_id)
        person_name = await get_person_name(person_oid)
    
    genealogy_person_oid = None
    if milestone.genealogy_person_id:
        genealogy_person_oid = ObjectId(milestone.genealogy_person_id)
    
    milestone_data = {
        "title": milestone.title,
        "description": milestone.description,
        "milestone_type": milestone.milestone_type,
        "milestone_date": milestone.milestone_date,
        "person_id": person_oid,
        "person_name": person_name,
        "genealogy_person_id": genealogy_person_oid,
        "photos": milestone.photos,
        "created_by": ObjectId(current_user.id),
        "family_circle_ids": family_circle_oids,
        "likes": [],
        "auto_generated": milestone.auto_generated,
        "generation": milestone.generation,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    milestone_doc = await milestones_repo.create(milestone_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="milestone_created",
        event_details={
            "milestone_id": str(milestone_doc["_id"]),
            "title": milestone.title,
            "milestone_type": milestone.milestone_type,
            "auto_generated": milestone.auto_generated
        }
    )
    
    response = build_milestone_response(milestone_doc, current_user.full_name)
    
    return create_success_response(
        message="Milestone created successfully",
        data=response.model_dump()
    )


@router.get("/")
async def list_milestones(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=100, description="Number of milestones per page"),
    person_id: Optional[str] = Query(None, description="Filter by person ID"),
    milestone_type: Optional[str] = Query(None, description="Filter by milestone type"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List family milestones with pagination and filtering.
    
    - Returns milestones created by user or in their family circles
    - Supports filtering by person and milestone type
    - Sorted by milestone date (newest first)
    """
    skip = (page - 1) * page_size
    
    milestones = await milestones_repo.find_user_milestones(
        user_id=str(current_user.id),
        person_id=person_id,
        milestone_type=milestone_type,
        skip=skip,
        limit=page_size
    )
    
    total = await milestones_repo.count_user_milestones(
        user_id=str(current_user.id),
        person_id=person_id,
        milestone_type=milestone_type
    )
    
    milestone_responses = []
    for milestone_doc in milestones:
        creator_name = await get_creator_name(milestone_doc["created_by"])
        milestone_responses.append(build_milestone_response(milestone_doc, creator_name))
    
    return create_paginated_response(
        items=[m.model_dump() for m in milestone_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Milestones retrieved successfully"
    )


@router.get("/{milestone_id}")
async def get_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a specific milestone with full details.
    
    - Returns complete milestone information
    - Includes creator name and like count
    """
    milestone_doc = await milestones_repo.find_by_id(
        milestone_id,
        raise_404=True,
        error_message="Milestone not found"
    )
    assert milestone_doc is not None
    
    creator_name = await get_creator_name(milestone_doc["created_by"])
    response = build_milestone_response(milestone_doc, creator_name)
    
    return create_success_response(
        message="Milestone retrieved successfully",
        data=response.model_dump()
    )


@router.put("/{milestone_id}")
async def update_milestone(
    milestone_id: str,
    milestone_update: FamilyMilestoneUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Update a milestone (owner only).
    
    - Only milestone creator can update
    - Validates IDs if provided
    - Updates person name if person_id changes
    - Logs update for audit trail
    """
    await milestones_repo.check_milestone_ownership(milestone_id, str(current_user.id), raise_error=True)
    
    update_data = {k: v for k, v in milestone_update.model_dump(exclude_unset=True).items() if v is not None}
    
    if "family_circle_ids" in update_data:
        update_data["family_circle_ids"] = validate_object_ids(update_data["family_circle_ids"], "family_circle_ids")
    
    if "person_id" in update_data:
        person_oid = ObjectId(update_data["person_id"])
        update_data["person_id"] = person_oid
        update_data["person_name"] = await get_person_name(person_oid)
    
    update_data["updated_at"] = datetime.utcnow()
    
    updated_milestone = await milestones_repo.update_by_id(milestone_id, update_data)
    assert updated_milestone is not None
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="milestone_updated",
        event_details={
            "milestone_id": milestone_id,
            "updated_fields": list(update_data.keys())
        }
    )
    
    creator_name = await get_creator_name(updated_milestone["created_by"])
    response = build_milestone_response(updated_milestone, creator_name)
    
    return create_success_response(
        message="Milestone updated successfully",
        data=response.model_dump()
    )


@router.delete("/{milestone_id}", status_code=status.HTTP_200_OK)
async def delete_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete a milestone (owner only).
    
    - Only milestone creator can delete
    - Logs deletion for audit trail
    """
    milestone_doc = await milestones_repo.find_by_id(milestone_id, raise_404=True)
    assert milestone_doc is not None
    
    await milestones_repo.check_milestone_ownership(milestone_id, str(current_user.id), raise_error=True)
    
    await milestones_repo.delete_by_id(milestone_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="milestone_deleted",
        event_details={
            "milestone_id": milestone_id,
            "title": milestone_doc.get("title"),
            "milestone_type": milestone_doc.get("milestone_type")
        }
    )
    
    return create_message_response("Milestone deleted successfully")


@router.post("/{milestone_id}/like", status_code=status.HTTP_200_OK)
async def like_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Like a milestone.
    
    - Adds user to likes array (prevents duplicates)
    - Returns updated like count
    """
    success = await milestones_repo.toggle_like(
        milestone_id=milestone_id,
        user_id=str(current_user.id),
        add_like=True
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Milestone not found or already liked")
    
    milestone_doc = await milestones_repo.find_by_id(milestone_id)
    likes_count = len(milestone_doc.get("likes", [])) if milestone_doc else 0
    
    return create_success_response(
        message="Milestone liked successfully",
        data={"likes_count": likes_count}
    )


@router.delete("/{milestone_id}/like", status_code=status.HTTP_200_OK)
async def unlike_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Unlike a milestone.
    
    - Removes user from likes array
    - Returns updated like count
    """
    success = await milestones_repo.toggle_like(
        milestone_id=milestone_id,
        user_id=str(current_user.id),
        add_like=False
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Milestone not found or not liked")
    
    milestone_doc = await milestones_repo.find_by_id(milestone_id)
    likes_count = len(milestone_doc.get("likes", [])) if milestone_doc else 0
    
    return create_success_response(
        message="Milestone unliked successfully",
        data={"likes_count": likes_count}
    )
