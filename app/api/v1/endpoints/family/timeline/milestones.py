"""Milestone endpoints for timeline system."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.models.timeline import (
    UserMilestoneCreate,
    UserMilestoneUpdate,
    UserMilestoneResponse,
    AudienceScope
)
from app.repositories.timeline import MilestoneRepository
from app.repositories.relationships import RelationshipRepository
from app.models.responses import create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event


router = APIRouter()
milestone_repo = MilestoneRepository()
relationship_repo = RelationshipRepository()


async def get_user_info(user_id: ObjectId) -> dict:
    """Get basic user info."""
    from app.repositories.family.users import UserRepository
    user_repo = UserRepository()
    user = await user_repo.find_one({"_id": user_id}, raise_404=False)
    if user:
        return {
            "id": str(user["_id"]),
            "name": user.get("full_name", "Unknown User"),
            "avatar": user.get("avatar_url")
        }
    return {"id": str(user_id), "name": "Unknown User", "avatar": None}


@router.post("/milestones", status_code=status.HTTP_201_CREATED)
async def create_milestone(
    milestone: UserMilestoneCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new milestone."""
    try:
        # Convert circle_ids to ObjectIds
        circle_oids = []
        if milestone.circle_ids:
            circle_oids = milestone_repo.validate_object_ids(
                milestone.circle_ids,
                "circle_ids"
            )
        
        # Create milestone data
        milestone_data = {
            "owner_id": ObjectId(current_user.id),
            "circle_ids": circle_oids,
            "audience_scope": milestone.audience_scope,
            "title": milestone.title,
            "content": milestone.content,
            "media": milestone.media,
            "engagement_counts": {
                "likes_count": 0,
                "comments_count": 0,
                "reactions_count": 0
            }
        }
        
        created = await milestone_repo.create(milestone_data)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="milestone_created",
            event_details={
                "milestone_id": str(created["_id"]),
                "audience_scope": milestone.audience_scope
            }
        )
        
        # Get user info
        user_info = await get_user_info(ObjectId(current_user.id))
        
        response = UserMilestoneResponse(
            id=str(created["_id"]),
            owner_id=str(created["owner_id"]),
            owner_name=user_info["name"],
            owner_avatar=user_info["avatar"],
            circle_ids=[str(oid) for oid in created.get("circle_ids", [])],
            audience_scope=created["audience_scope"],
            title=created["title"],
            content=created["content"],
            media=created.get("media", []),
            engagement_counts=created.get("engagement_counts", {}),
            created_at=created["created_at"],
            updated_at=created["updated_at"]
        )
        
        return create_success_response(
            message="Milestone created successfully",
            data=response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create milestone: {str(e)}"
        )


@router.get("/milestones/{milestone_id}")
async def get_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a single milestone by ID."""
    try:
        milestone = await milestone_repo.find_by_id(
            milestone_id,
            raise_404=True,
            error_message="Milestone not found"
        )
        assert milestone is not None
        
        # Check visibility
        owner_id = milestone.get("owner_id")
        audience_scope = milestone.get("audience_scope")
        
        # Owner can always see
        if owner_id != ObjectId(current_user.id):
            # Check visibility based on scope
            if audience_scope == AudienceScope.PRIVATE:
                raise HTTPException(
                    status_code=403,
                    detail="You do not have permission to view this milestone"
                )
            elif audience_scope in [AudienceScope.FRIENDS, AudienceScope.FAMILY]:
                # Check relationship
                relationships = await relationship_repo.get_accepted_relationships(
                    str(current_user.id),
                    relationship_type=audience_scope if audience_scope == "family" else "friend"
                )
                related_user_ids = [str(r.get("related_user_id")) for r in relationships]
                if str(owner_id) not in related_user_ids:
                    raise HTTPException(
                        status_code=403,
                        detail="You do not have permission to view this milestone"
                    )
        
        # Get owner info
        user_info = await get_user_info(owner_id)
        
        response = UserMilestoneResponse(
            id=str(milestone["_id"]),
            owner_id=str(milestone["owner_id"]),
            owner_name=user_info["name"],
            owner_avatar=user_info["avatar"],
            circle_ids=[str(oid) for oid in milestone.get("circle_ids", [])],
            audience_scope=milestone["audience_scope"],
            title=milestone["title"],
            content=milestone["content"],
            media=milestone.get("media", []),
            engagement_counts=milestone.get("engagement_counts", {}),
            created_at=milestone["created_at"],
            updated_at=milestone["updated_at"]
        )
        
        return create_success_response(
            message="Milestone retrieved successfully",
            data=response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve milestone: {str(e)}"
        )


@router.put("/milestones/{milestone_id}")
async def update_milestone(
    milestone_id: str,
    milestone: UserMilestoneUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a milestone (owner only)."""
    try:
        # Check ownership
        await milestone_repo.check_ownership(milestone_id, str(current_user.id))
        
        # Build update data
        update_data = {}
        if milestone.title is not None:
            update_data["title"] = milestone.title
        if milestone.content is not None:
            update_data["content"] = milestone.content
        if milestone.media is not None:
            update_data["media"] = milestone.media
        if milestone.audience_scope is not None:
            update_data["audience_scope"] = milestone.audience_scope
        if milestone.circle_ids is not None:
            circle_oids = milestone_repo.validate_object_ids(
                milestone.circle_ids,
                "circle_ids"
            )
            update_data["circle_ids"] = circle_oids
        
        if not update_data:
            raise HTTPException(
                status_code=400,
                detail="No fields to update"
            )
        
        updated = await milestone_repo.update(milestone_id, update_data)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="milestone_updated",
            event_details={"milestone_id": milestone_id}
        )
        
        # Get owner info
        user_info = await get_user_info(ObjectId(current_user.id))
        
        response = UserMilestoneResponse(
            id=str(updated["_id"]),
            owner_id=str(updated["owner_id"]),
            owner_name=user_info["name"],
            owner_avatar=user_info["avatar"],
            circle_ids=[str(oid) for oid in updated.get("circle_ids", [])],
            audience_scope=updated["audience_scope"],
            title=updated["title"],
            content=updated["content"],
            media=updated.get("media", []),
            engagement_counts=updated.get("engagement_counts", {}),
            created_at=updated["created_at"],
            updated_at=updated["updated_at"]
        )
        
        return create_success_response(
            message="Milestone updated successfully",
            data=response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update milestone: {str(e)}"
        )


@router.delete("/milestones/{milestone_id}")
async def delete_milestone(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a milestone (owner only)."""
    try:
        # Check ownership
        await milestone_repo.check_ownership(milestone_id, str(current_user.id))
        
        await milestone_repo.delete(milestone_id)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="milestone_deleted",
            event_details={"milestone_id": milestone_id}
        )
        
        return create_success_response(
            message="Milestone deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete milestone: {str(e)}"
        )


@router.get("/feed")
async def get_timeline_feed(
    skip: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(20, ge=1, le=100, description="Number of items to return"),
    scope_filter: Optional[str] = Query(None, description="Filter by scope (private, friends, family, public)"),
    person_id: Optional[str] = Query(None, description="Filter by specific person"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get timeline feed in reverse chronological order.
    Returns milestones visible to current user based on relationships and audience_scope.
    """
    try:
        result = await milestone_repo.get_feed(
            user_id=str(current_user.id),
            skip=skip,
            limit=limit,
            scope_filter=scope_filter,
            person_id=person_id
        )
        
        # Enrich with user info
        items = []
        for milestone in result["items"]:
            user_info = await get_user_info(milestone["owner_id"])
            
            items.append(UserMilestoneResponse(
                id=str(milestone["_id"]),
                owner_id=str(milestone["owner_id"]),
                owner_name=user_info["name"],
                owner_avatar=user_info["avatar"],
                circle_ids=[str(oid) for oid in milestone.get("circle_ids", [])],
                audience_scope=milestone["audience_scope"],
                title=milestone["title"],
                content=milestone["content"],
                media=milestone.get("media", []),
                engagement_counts=milestone.get("engagement_counts", {}),
                created_at=milestone["created_at"],
                updated_at=milestone["updated_at"]
            ).model_dump())
        
        return create_paginated_response(
            items=items,
            total=result["total"],
            page=result["page"],
            page_size=result["page_size"],
            message="Timeline feed retrieved successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve feed: {str(e)}"
        )
