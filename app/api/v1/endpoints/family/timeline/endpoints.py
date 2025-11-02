from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.user import UserInDB
from app.core.security import get_current_user
from .repository import FamilyTimelineRepository
from app.repositories.family_repository import (
    FamilyRepository, FamilyMilestonesRepository,
    FamilyRecipesRepository, FamilyTraditionsRepository, FamilyAlbumsRepository,
    FamilyCalendarRepository
)
from app.repositories.base_repository import BaseRepository
from app.models.responses import create_success_response, create_paginated_response

router = APIRouter()

timeline_repo = FamilyTimelineRepository()
family_repo = FamilyRepository()
memories_repo = BaseRepository("memories")
milestones_repo = FamilyMilestonesRepository()
events_repo = FamilyCalendarRepository()
recipes_repo = FamilyRecipesRepository()
traditions_repo = FamilyTraditionsRepository()
albums_repo = FamilyAlbumsRepository()


@router.get("/")
async def get_family_timeline(
    person_id: Optional[str] = None,
    circle_id: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    event_types: Optional[str] = None,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a comprehensive family timeline combining memories, milestones, events, and more with pagination"""
    user_id = str(current_user.id)
    
    if circle_id:
        await family_repo.check_member_access(circle_id, user_id, raise_error=True)
        family_id = circle_id
    else:
        family_id = user_id
    
    event_type_list = event_types.split(",") if event_types else None
    
    skip = (page - 1) * page_size
    
    result = await timeline_repo.get_timeline_events(
        family_id=family_id,
        skip=skip,
        limit=page_size,
        event_types=event_type_list,
        person_id=person_id,
        start_date=start_date,
        end_date=end_date
    )
    
    if isinstance(result, dict) and "items" in result and "total" in result:
        return create_paginated_response(
            items=result["items"],
            total=result["total"],
            page=page,
            page_size=page_size,
            message="Timeline events retrieved successfully"
        )
    else:
        return result


@router.get("/stats")
async def get_timeline_stats(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get statistics for the family timeline"""
    user_oid = ObjectId(current_user.id)
    
    memories_count = await memories_repo.count({"user_id": user_oid})
    milestones_count = await milestones_repo.count({"created_by": user_oid})
    events_count = await events_repo.count({"created_by": user_oid})
    recipes_count = await recipes_repo.count({"created_by": user_oid})
    traditions_count = await traditions_repo.count({"created_by": user_oid})
    albums_count = await albums_repo.count({"created_by": user_oid})
    
    total_count = memories_count + milestones_count + events_count + recipes_count + traditions_count + albums_count
    
    stats_data = {
        "memories": memories_count,
        "milestones": milestones_count,
        "events": events_count,
        "recipes": recipes_count,
        "traditions": traditions_count,
        "albums": albums_count,
        "total": total_count
    }
    
    return create_success_response(
        message="Timeline statistics retrieved successfully",
        data=stats_data
    )
