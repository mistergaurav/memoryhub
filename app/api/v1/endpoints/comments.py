from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

from app.schemas.comment import (
    CommentCreate,
    CommentUpdate,
    CommentResponse,
    CommentListResponse,
    CommentTarget
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

async def _prepare_comment_response(comment_doc: dict, current_user_id: str) -> CommentResponse:
    """Prepare comment document for API response"""
    author = await get_collection("users").find_one({"_id": comment_doc["author_id"]})
    
    likes_count = await get_collection("comment_likes").count_documents({
        "comment_id": comment_doc["_id"]
    })
    
    is_liked = await get_collection("comment_likes").find_one({
        "comment_id": comment_doc["_id"],
        "user_id": ObjectId(current_user_id)
    }) is not None
    
    return CommentResponse(
        id=str(comment_doc["_id"]),
        content=comment_doc["content"],
        target_type=comment_doc["target_type"],
        target_id=str(comment_doc["target_id"]),
        author_id=str(comment_doc["author_id"]),
        author_name=author.get("full_name") if author else "Unknown User",
        author_avatar=author.get("avatar_url") if author else None,
        created_at=comment_doc["created_at"],
        updated_at=comment_doc["updated_at"],
        likes_count=likes_count,
        is_liked=is_liked,
        is_author=str(comment_doc["author_id"]) == current_user_id
    )

@router.post("/", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def create_comment(
    comment: CommentCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new comment"""
    # Verify target exists
    if comment.target_type == CommentTarget.MEMORY:
        target_collection = "memories"
    elif comment.target_type == CommentTarget.HUB_ITEM:
        target_collection = "hub_items"
    elif comment.target_type == CommentTarget.FILE:
        target_collection = "files"
    else:
        raise HTTPException(status_code=400, detail="Invalid target type")
    
    target = await get_collection(target_collection).find_one({"_id": ObjectId(comment.target_id)})
    if not target:
        raise HTTPException(status_code=404, detail=f"{comment.target_type.value} not found")
    
    comment_data = {
        "content": comment.content,
        "target_type": comment.target_type,
        "target_id": ObjectId(comment.target_id),
        "author_id": ObjectId(current_user.id),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await get_collection("comments").insert_one(comment_data)
    comment_doc = await get_collection("comments").find_one({"_id": result.inserted_id})
    
    if not comment_doc:
        raise HTTPException(status_code=500, detail="Failed to create comment")
    
    return await _prepare_comment_response(comment_doc, current_user.id)

@router.get("/", response_model=CommentListResponse)
async def list_comments(
    target_type: CommentTarget,
    target_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user)
):
    """List comments for a target"""
    query = {
        "target_type": target_type,
        "target_id": ObjectId(target_id)
    }
    
    total = await get_collection("comments").count_documents(query)
    skip = (page - 1) * limit
    pages = (total + limit - 1) // limit
    
    cursor = get_collection("comments").find(query).sort("created_at", -1).skip(skip).limit(limit)
    
    comments = []
    async for comment_doc in cursor:
        comments.append(await _prepare_comment_response(comment_doc, current_user.id))
    
    return CommentListResponse(
        comments=comments,
        total=total,
        page=page,
        pages=pages
    )

@router.get("/{comment_id}", response_model=CommentResponse)
async def get_comment(
    comment_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific comment"""
    comment_doc = await get_collection("comments").find_one({"_id": ObjectId(comment_id)})
    if not comment_doc:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    return await _prepare_comment_response(comment_doc, current_user.id)

@router.put("/{comment_id}", response_model=CommentResponse)
async def update_comment(
    comment_id: str,
    comment_update: CommentUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a comment (only by author)"""
    comment_doc = await get_collection("comments").find_one({"_id": ObjectId(comment_id)})
    if not comment_doc:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    if str(comment_doc["author_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this comment")
    
    update_data = {
        "content": comment_update.content,
        "updated_at": datetime.utcnow()
    }
    
    await get_collection("comments").update_one(
        {"_id": ObjectId(comment_id)},
        {"$set": update_data}
    )
    
    updated_doc = await get_collection("comments").find_one({"_id": ObjectId(comment_id)})
    if not updated_doc:
        raise HTTPException(status_code=500, detail="Failed to update comment")
    
    return await _prepare_comment_response(updated_doc, current_user.id)

@router.delete("/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_comment(
    comment_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a comment (only by author or target owner)"""
    comment_doc = await get_collection("comments").find_one({"_id": ObjectId(comment_id)})
    if not comment_doc:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    # Check if user is comment author or target owner
    is_author = str(comment_doc["author_id"]) == current_user.id
    
    if comment_doc["target_type"] == "memory":
        target_collection = "memories"
    elif comment_doc["target_type"] == "hub_item":
        target_collection = "hub_items"
    elif comment_doc["target_type"] == "file":
        target_collection = "files"
    else:
        raise HTTPException(status_code=400, detail="Invalid target type")
    
    target = await get_collection(target_collection).find_one({"_id": comment_doc["target_id"]})
    is_target_owner = target and str(target.get("owner_id")) == current_user.id
    
    if not is_author and not is_target_owner:
        raise HTTPException(status_code=403, detail="Not authorized to delete this comment")
    
    await get_collection("comments").delete_one({"_id": ObjectId(comment_id)})
    await get_collection("comment_likes").delete_many({"comment_id": ObjectId(comment_id)})

@router.post("/{comment_id}/like", status_code=status.HTTP_200_OK)
async def like_comment(
    comment_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Like a comment"""
    comment_doc = await get_collection("comments").find_one({"_id": ObjectId(comment_id)})
    if not comment_doc:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    existing_like = await get_collection("comment_likes").find_one({
        "comment_id": ObjectId(comment_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if existing_like:
        return {"message": "Already liked"}
    
    await get_collection("comment_likes").insert_one({
        "comment_id": ObjectId(comment_id),
        "user_id": ObjectId(current_user.id),
        "created_at": datetime.utcnow()
    })
    
    return {"message": "Comment liked"}

@router.delete("/{comment_id}/like", status_code=status.HTTP_200_OK)
async def unlike_comment(
    comment_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Unlike a comment"""
    result = await get_collection("comment_likes").delete_one({
        "comment_id": ObjectId(comment_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if result.deleted_count == 0:
        return {"message": "Not liked"}
    
    return {"message": "Comment unliked"}
