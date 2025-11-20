"""Reaction endpoints for milestone timeline."""
from fastapi import APIRouter, Depends, HTTPException, status
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.models.timeline import (
    MilestoneReactionCreate,
    ReactionsSummary
)
from app.repositories.timeline import ReactionRepository, MilestoneRepository
from app.models.responses import create_success_response
from app.utils.audit_logger import log_audit_event


router = APIRouter()
reaction_repo = ReactionRepository()
milestone_repo = MilestoneRepository()


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


@router.post("/milestones/{milestone_id}/reactions", status_code=status.HTTP_201_CREATED)
async def add_or_update_reaction(
    milestone_id: str,
    reaction: MilestoneReactionCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add or update a reaction to a milestone."""
    try:
        # Verify milestone exists
        await milestone_repo.find_by_id(
            milestone_id,
            raise_404=True,
            error_message="Milestone not found"
        )
        
        # Check if user already has a reaction
        existing = await reaction_repo.find_user_reaction(
            milestone_id,
            str(current_user.id)
        )
        
        # Upsert reaction
        created_or_updated = await reaction_repo.upsert_reaction(
            milestone_id,
            str(current_user.id),
            reaction.reaction_type
        )
        
        # If this is a new reaction, increment count
        if not existing:
            await milestone_repo.increment_engagement(
                milestone_id,
                "reactions_count",
                1
            )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="reaction_added" if not existing else "reaction_updated",
            event_details={
                "reaction_id": str(created_or_updated["_id"]),
                "milestone_id": milestone_id,
                "reaction_type": reaction.reaction_type
            }
        )
        
        return create_success_response(
            message="Reaction added successfully" if not existing else "Reaction updated successfully",
            data={"reaction_id": str(created_or_updated["_id"])}
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to add reaction: {str(e)}"
        )


@router.delete("/milestones/{milestone_id}/reactions")
async def remove_reaction(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove user's reaction from a milestone."""
    try:
        # Verify milestone exists
        await milestone_repo.find_by_id(
            milestone_id,
            raise_404=True,
            error_message="Milestone not found"
        )
        
        # Delete reaction
        deleted = await reaction_repo.delete_user_reaction(
            milestone_id,
            str(current_user.id)
        )
        
        if not deleted:
            raise HTTPException(
                status_code=404,
                detail="No reaction found to remove"
            )
        
        # Decrement count
        await milestone_repo.increment_engagement(
            milestone_id,
            "reactions_count",
            -1
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="reaction_removed",
            event_details={"milestone_id": milestone_id}
        )
        
        return create_success_response(
            message="Reaction removed successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to remove reaction: {str(e)}"
        )


@router.get("/milestones/{milestone_id}/reactions")
async def get_reactions_summary(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get reactions summary for a milestone."""
    try:
        # Verify milestone exists
        await milestone_repo.find_by_id(
            milestone_id,
            raise_404=True,
            error_message="Milestone not found"
        )
        
        # Get summary
        summary = await reaction_repo.get_reactions_summary(
            milestone_id,
            str(current_user.id)
        )
        
        # Enrich recent reactors with user info
        enriched_reactors = []
        for reactor in summary.get("recent_reactors", [])[:10]:
            user_info = await get_user_info(ObjectId(reactor["actor_id"]))
            enriched_reactors.append({
                "actor_id": reactor["actor_id"],
                "actor_name": user_info["name"],
                "actor_avatar": user_info["avatar"],
                "reaction_type": reactor["reaction_type"]
            })
        
        response = ReactionsSummary(
            total_count=summary["total_count"],
            reactions_by_type=summary["reactions_by_type"],
            user_reaction=summary.get("user_reaction"),
            recent_reactors=enriched_reactors
        )
        
        return create_success_response(
            message="Reactions summary retrieved successfully",
            data=response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve reactions: {str(e)}"
        )
