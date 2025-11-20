"""Comment endpoints for milestone timeline."""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.models.timeline import (
    MilestoneCommentCreate,
    MilestoneCommentUpdate,
    MilestoneCommentResponse
)
from app.repositories.timeline import CommentRepository, MilestoneRepository
from app.models.responses import create_success_response
from app.utils.audit_logger import log_audit_event


router = APIRouter()
comment_repo = CommentRepository()
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


def build_comment_response(comment: dict, user_info: dict, replies: List[dict] = None) -> dict:
    """Build comment response with user info."""
    return MilestoneCommentResponse(
        id=str(comment["_id"]),
        milestone_id=str(comment["milestone_id"]),
        author_id=str(comment["author_id"]),
        author_name=user_info["name"],
        author_avatar=user_info["avatar"],
        body=comment["body"],
        parent_comment_id=str(comment["parent_comment_id"]) if comment.get("parent_comment_id") else None,
        visibility=comment["visibility"],
        created_at=comment["created_at"],
        updated_at=comment["updated_at"],
        replies=replies or []
    ).model_dump()


@router.post("/milestones/{milestone_id}/comments", status_code=status.HTTP_201_CREATED)
async def create_comment(
    milestone_id: str,
    comment: MilestoneCommentCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a comment to a milestone."""
    try:
        # Verify milestone exists
        milestone = await milestone_repo.find_by_id(
            milestone_id,
            raise_404=True,
            error_message="Milestone not found"
        )
        assert milestone is not None
        
        # Validate parent comment if provided
        parent_oid = None
        if comment.parent_comment_id:
            parent_oid = comment_repo.validate_object_id(
                comment.parent_comment_id,
                "parent_comment_id"
            )
            # Verify parent exists and belongs to same milestone
            parent = await comment_repo.find_one({"_id": parent_oid}, raise_404=True)
            assert parent is not None
            if str(parent.get("milestone_id")) != milestone_id:
                raise HTTPException(
                    status_code=400,
                    detail="Parent comment does not belong to this milestone"
                )
        
        # Create comment
        comment_data = {
            "milestone_id": ObjectId(milestone_id),
            "author_id": ObjectId(current_user.id),
            "body": comment.body,
            "parent_comment_id": parent_oid,
            "visibility": comment.visibility
        }
        
        created = await comment_repo.create(comment_data)
        
        # Increment comment count on milestone
        await milestone_repo.increment_engagement(
            milestone_id,
            "comments_count",
            1
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="comment_created",
            event_details={
                "comment_id": str(created["_id"]),
                "milestone_id": milestone_id
            }
        )
        
        # Get user info
        user_info = await get_user_info(ObjectId(current_user.id))
        
        response = build_comment_response(created, user_info)
        
        return create_success_response(
            message="Comment created successfully",
            data=response
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create comment: {str(e)}"
        )


@router.get("/milestones/{milestone_id}/comments")
async def get_comments(
    milestone_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all comments for a milestone (supports nested comments)."""
    try:
        # Verify milestone exists
        await milestone_repo.find_by_id(
            milestone_id,
            raise_404=True,
            error_message="Milestone not found"
        )
        
        # Get nested comments
        comments = await comment_repo.get_nested_comments(milestone_id)
        
        # Enrich with user info
        response_comments = []
        for comment in comments:
            user_info = await get_user_info(comment["author_id"])
            
            # Process replies recursively
            replies = []
            for reply in comment.get("replies", []):
                reply_user_info = await get_user_info(reply["author_id"])
                replies.append(build_comment_response(reply, reply_user_info))
            
            response_comments.append(build_comment_response(comment, user_info, replies))
        
        return create_success_response(
            message="Comments retrieved successfully",
            data=response_comments
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve comments: {str(e)}"
        )


@router.put("/comments/{comment_id}")
async def update_comment(
    comment_id: str,
    comment: MilestoneCommentUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a comment (author only)."""
    try:
        # Check authorship
        await comment_repo.check_authorship(comment_id, str(current_user.id))
        
        # Build update data
        update_data = {}
        if comment.body is not None:
            update_data["body"] = comment.body
        if comment.visibility is not None:
            update_data["visibility"] = comment.visibility
        
        if not update_data:
            raise HTTPException(
                status_code=400,
                detail="No fields to update"
            )
        
        updated = await comment_repo.update(comment_id, update_data)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="comment_updated",
            event_details={"comment_id": comment_id}
        )
        
        # Get user info
        user_info = await get_user_info(ObjectId(current_user.id))
        
        response = build_comment_response(updated, user_info)
        
        return create_success_response(
            message="Comment updated successfully",
            data=response
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update comment: {str(e)}"
        )


@router.delete("/comments/{comment_id}")
async def delete_comment(
    comment_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a comment (author only)."""
    try:
        # Check authorship
        await comment_repo.check_authorship(comment_id, str(current_user.id))
        
        # Get comment to find milestone
        comment_doc = await comment_repo.find_by_id(comment_id, raise_404=True)
        assert comment_doc is not None
        
        milestone_id = str(comment_doc["milestone_id"])
        
        # Delete comment
        await comment_repo.delete(comment_id)
        
        # Decrement comment count on milestone
        await milestone_repo.increment_engagement(
            milestone_id,
            "comments_count",
            -1
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="comment_deleted",
            event_details={"comment_id": comment_id}
        )
        
        return create_success_response(
            message="Comment deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete comment: {str(e)}"
        )
