"""Family dashboard endpoint."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime, timedelta
from bson import ObjectId
import secrets

from app.models.family.family import (
    FamilyRelationshipCreate, FamilyRelationshipResponse,
    FamilyCircleCreate, FamilyCircleUpdate, FamilyCircleResponse,
    FamilyInvitationCreate, FamilyInvitationResponse,
    FamilyRelationType, FamilyTreeNode,
    AddFamilyMemberRequest
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.family_repository import (
    FamilyRepository,
    FamilyRelationshipRepository,
    FamilyInvitationRepository,
    UserRepository
)
from app.utils.family_validators import (
    validate_family_ownership,
    validate_family_member_access,
    validate_object_id_list,
    validate_user_exists,
    validate_relationship_ownership,
    validate_invitation_token,
    validate_invitation_for_user,
    validate_circle_ownership_for_invitations,
    validate_no_duplicate_relationship,
    validate_user_not_owner,
    validate_user_not_in_circle
)
from app.models.responses import create_message_response, create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event
from .utils import get_user_data

router = APIRouter()

family_repo = FamilyRepository()
relationship_repo = FamilyRelationshipRepository()
invitation_repo = FamilyInvitationRepository()
user_repo = UserRepository()


@router.get("/dashboard")
async def get_family_dashboard(
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get family dashboard with aggregated stats and recent activity.
    
    Uses repository layer to ensure proper access control:
    - Recent albums (user-accessible only)
    - Upcoming events (user is creator or attendee)
    - Recent milestones (user-accessible only)
    - Family circle stats (user is owner or member)
    
    Returns data with proper response envelope and audit trail.
    """
    from app.repositories.family_repository import (
        FamilyAlbumsRepository,
        FamilyCalendarRepository,
        FamilyMilestonesRepository
    )
    from app.models.responses import create_success_response
    from app.utils.audit_logger import log_audit_event
    
    try:
        albums_repo = FamilyAlbumsRepository()
        calendar_repo = FamilyCalendarRepository()
        milestones_repo = FamilyMilestonesRepository()
        
        recent_albums_docs = await albums_repo.find_accessible_albums(
            user_id=str(current_user.id),
            skip=0,
            limit=5
        )
        recent_albums = [
            {
                "id": str(album["_id"]),
                "title": album["title"],
                "photo_count": len(album.get("photos", [])),
                "created_at": album["created_at"]
            }
            for album in recent_albums_docs
        ]
        
        end_date = datetime.utcnow() + timedelta(days=30)
        upcoming_events_docs = await calendar_repo.find_user_events(
            user_id=str(current_user.id),
            start_date=datetime.utcnow(),
            end_date=end_date,
            skip=0,
            limit=10
        )
        upcoming_events = [
            {
                "id": str(event["_id"]),
                "title": event["title"],
                "event_type": event["event_type"],
                "event_date": event["event_date"]
            }
            for event in upcoming_events_docs
        ]
        
        recent_milestones_docs = await milestones_repo.find_user_milestones(
            user_id=str(current_user.id),
            skip=0,
            limit=5
        )
        recent_milestones = [
            {
                "id": str(milestone["_id"]),
                "title": milestone["title"],
                "milestone_type": milestone["milestone_type"],
                "milestone_date": milestone["milestone_date"]
            }
            for milestone in recent_milestones_docs
        ]
        
        user_oid = ObjectId(current_user.id)
        family_circles_count = await family_repo.count({
            "$or": [
                {"owner_id": user_oid},
                {"member_ids": user_oid}
            ]
        })
        
        relationships_count = await relationship_repo.count({
            "user_id": user_oid
        })
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="dashboard_accessed",
            event_details={
                "albums_count": len(recent_albums),
                "events_count": len(upcoming_events),
                "milestones_count": len(recent_milestones)
            }
        )
        
        # Recent activity aggregation
        recent_activity = []
        for album in recent_albums[:3]:
            recent_activity.append({
                "type": "album",
                "id": album["id"],
                "title": f"Created album '{album['title']}'",
                "timestamp": album["created_at"]
            })
        for event in upcoming_events[:3]:
            recent_activity.append({
                "type": "event",
                "id": event["id"],
                "title": f"Upcoming: {event['title']}",
                "timestamp": event["event_date"]
            })
        for milestone in recent_milestones[:3]:
            recent_activity.append({
                "type": "milestone",
                "id": milestone["id"],
                "title": f"Milestone: {milestone['title']}",
                "timestamp": milestone["milestone_date"]
            })
        
        # Sort by timestamp and limit to 10 most recent
        recent_activity.sort(key=lambda x: x["timestamp"], reverse=True)
        recent_activity = recent_activity[:10]
        
        # Quick action buttons
        quick_actions = [
            {
                "id": "create_album",
                "title": "Create Album",
                "icon": "photo_album",
                "route": "/family/albums/create"
            },
            {
                "id": "add_event",
                "title": "Add Event",
                "icon": "event",
                "route": "/family/calendar/create"
            },
            {
                "id": "log_milestone",
                "title": "Log Milestone",
                "icon": "celebration",
                "route": "/family/milestones/create"
            },
            {
                "id": "add_recipe",
                "title": "Add Recipe",
                "icon": "restaurant",
                "route": "/family/recipes/create"
            },
            {
                "id": "view_tree",
                "title": "Family Tree",
                "icon": "account_tree",
                "route": "/family/genealogy"
            }
        ]
        
        return create_success_response(
            message="Dashboard loaded successfully",
            data={
                "recent_albums": recent_albums,
                "upcoming_events": upcoming_events,
                "recent_milestones": recent_milestones,
                "recent_activity": recent_activity,
                "quick_actions": quick_actions,
                "stats": {
                    "family_circles": family_circles_count,
                    "relationships": relationships_count,
                    "albums": len(recent_albums),
                    "upcoming_events": len(upcoming_events),
                    "total_albums": len(recent_albums),
                    "total_events": len(upcoming_events),
                    "total_milestones": len(recent_milestones),
                    "total_recipes": 0  # TODO: Add recipes count
                }
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load dashboard: {str(e)}")
