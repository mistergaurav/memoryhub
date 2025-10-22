from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.hub import (
    HubItemCreate, HubItemUpdate, HubItemResponse,
    HubItemType, HubItemPrivacy, HubStats
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.repositories.family_repository import HubItemsRepository
from app.utils.audit_logger import log_audit_event
from app.models.responses import create_success_response, create_paginated_response, create_message_response

router = APIRouter()
hub_repo = HubItemsRepository()


async def get_owner_info(owner_id: ObjectId) -> Dict[str, Any]:
    """Helper function to get owner information efficiently"""
    owner = await get_collection("users").find_one({"_id": owner_id})
    return {
        "full_name": owner.get("full_name") if owner else None,
        "avatar": owner.get("avatar") if owner else None
    }


def build_item_response(
    item_doc: Dict[str, Any],
    owner_name: Optional[str] = None,
    owner_avatar: Optional[str] = None,
    user_id: Optional[str] = None
) -> HubItemResponse:
    """Helper function to build item response with engagement info"""
    likes = item_doc.get("likes", [])
    bookmarks = item_doc.get("bookmarks", [])
    
    is_liked = False
    is_bookmarked = False
    if user_id:
        user_oid = ObjectId(user_id)
        is_liked = user_oid in likes
        is_bookmarked = user_oid in bookmarks
    
    return HubItemResponse(
        _id=item_doc["_id"],
        title=item_doc["title"],
        description=item_doc.get("description"),
        item_type=item_doc["item_type"],
        content=item_doc.get("content", {}),
        tags=item_doc.get("tags", []),
        privacy=item_doc["privacy"],
        is_pinned=item_doc.get("is_pinned", False),
        position=item_doc.get("position"),
        owner_id=item_doc["owner_id"],
        owner_name=owner_name,
        owner_avatar=owner_avatar,
        created_at=item_doc["created_at"],
        updated_at=item_doc["updated_at"],
        view_count=item_doc.get("view_count", 0),
        like_count=len(likes),
        comment_count=item_doc.get("comment_count", 0),
        is_liked=is_liked,
        is_bookmarked=is_bookmarked
    )


@router.post("/items", status_code=status.HTTP_201_CREATED)
async def create_hub_item(
    item: HubItemCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a new hub item with privacy controls.
    
    - Supports various item types (memory, file, note, link, task)
    - Applies privacy settings (private, friends, public)
    - Initializes engagement metrics (views, likes, comments)
    - Logs item creation for audit trail
    """
    item_data = {
        "title": item.title,
        "description": item.description,
        "item_type": item.item_type,
        "content": item.content,
        "tags": item.tags,
        "privacy": item.privacy,
        "is_pinned": item.is_pinned,
        "position": item.position,
        "owner_id": ObjectId(current_user.id),
        "view_count": 0,
        "likes": [],
        "bookmarks": [],
        "comment_count": 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    item_doc = await hub_repo.create(item_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="hub_item_created",
        event_details={
            "item_id": str(item_doc["_id"]),
            "title": item.title,
            "item_type": item.item_type,
            "privacy": item.privacy
        }
    )
    
    response = build_item_response(item_doc, current_user.full_name, current_user.avatar_url, str(current_user.id))
    
    return create_success_response(
        message="Hub item created successfully",
        data=response.model_dump()
    )


@router.get("/items")
async def list_hub_items(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of items per page"),
    item_type: Optional[HubItemType] = Query(None, description="Filter by item type"),
    privacy: Optional[HubItemPrivacy] = Query(None, description="Filter by privacy level"),
    tag: Optional[str] = Query(None, description="Filter by tag"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List hub items with pagination and filtering.
    
    - Returns items owned by user and public items
    - Supports filtering by type, privacy, and tags
    - Includes owner information and engagement metrics
    - Sorted by most recently updated
    """
    skip = (page - 1) * page_size
    
    item_type_str = item_type.value if item_type else None
    privacy_str = privacy.value if privacy else None
    
    items = await hub_repo.find_user_items(
        user_id=str(current_user.id),
        item_type=item_type_str,
        privacy=privacy_str,
        tag=tag,
        skip=skip,
        limit=page_size
    )
    
    total = await hub_repo.count_user_items(
        user_id=str(current_user.id),
        item_type=item_type_str,
        privacy=privacy_str,
        tag=tag
    )
    
    item_responses = []
    for item_doc in items:
        owner_info = await get_owner_info(item_doc["owner_id"])
        item_responses.append(
            build_item_response(item_doc, owner_info["full_name"], owner_info["avatar"], str(current_user.id))
        )
    
    return create_paginated_response(
        items=[i.model_dump() for i in item_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Hub items retrieved successfully"
    )


@router.get("/items/{item_id}")
async def get_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a specific hub item with full details.
    
    - Verifies user has access to view the item
    - Increments view count
    - Returns complete item information
    """
    await hub_repo.check_item_access(item_id, str(current_user.id), raise_error=True)
    
    item_doc = await hub_repo.find_by_id(
        item_id,
        raise_404=True,
        error_message="Hub item not found"
    )
    assert item_doc is not None
    
    await hub_repo.increment_view_count(item_id)
    
    owner_info = await get_owner_info(item_doc["owner_id"])
    response = build_item_response(item_doc, owner_info["full_name"], owner_info["avatar"], str(current_user.id))
    
    return create_success_response(
        message="Hub item retrieved successfully",
        data=response.model_dump()
    )


@router.put("/items/{item_id}")
async def update_hub_item(
    item_id: str,
    item_update: HubItemUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Update a hub item (owner only).
    
    - Only item owner can update
    - Validates updated fields
    - Logs update for audit trail
    """
    await hub_repo.check_item_ownership(item_id, str(current_user.id), raise_error=True)
    
    update_data = {k: v for k, v in item_update.model_dump(exclude_unset=True).items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()
    
    updated_item = await hub_repo.update_by_id(item_id, update_data)
    assert updated_item is not None
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="hub_item_updated",
        event_details={
            "item_id": item_id,
            "updated_fields": list(update_data.keys())
        }
    )
    
    owner_info = await get_owner_info(updated_item["owner_id"])
    response = build_item_response(updated_item, owner_info["full_name"], owner_info["avatar"], str(current_user.id))
    
    return create_success_response(
        message="Hub item updated successfully",
        data=response.model_dump()
    )


@router.delete("/items/{item_id}", status_code=status.HTTP_200_OK)
async def delete_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete a hub item (owner only).
    
    - Only item owner can delete
    - Logs deletion for audit trail
    """
    item_doc = await hub_repo.find_by_id(item_id, raise_404=True)
    assert item_doc is not None
    
    await hub_repo.check_item_ownership(item_id, str(current_user.id), raise_error=True)
    
    await hub_repo.delete_by_id(item_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="hub_item_deleted",
        event_details={
            "item_id": item_id,
            "title": item_doc.get("title"),
            "item_type": item_doc.get("item_type")
        }
    )
    
    return create_message_response("Hub item deleted successfully")


@router.post("/items/{item_id}/like", status_code=status.HTTP_200_OK)
async def like_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Like a hub item.
    
    - Adds user to likes array (prevents duplicates)
    - Returns updated like count
    """
    await hub_repo.check_item_access(item_id, str(current_user.id), raise_error=True)
    
    success = await hub_repo.toggle_like(
        item_id=item_id,
        user_id=str(current_user.id),
        add_like=True
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Hub item not found or already liked")
    
    item_doc = await hub_repo.find_by_id(item_id)
    like_count = len(item_doc.get("likes", [])) if item_doc else 0
    
    return create_success_response(
        message="Hub item liked successfully",
        data={"like_count": like_count}
    )


@router.delete("/items/{item_id}/like", status_code=status.HTTP_200_OK)
async def unlike_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Unlike a hub item.
    
    - Removes user from likes array
    - Returns updated like count
    """
    await hub_repo.check_item_access(item_id, str(current_user.id), raise_error=True)
    
    success = await hub_repo.toggle_like(
        item_id=item_id,
        user_id=str(current_user.id),
        add_like=False
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Hub item not found or not liked")
    
    item_doc = await hub_repo.find_by_id(item_id)
    like_count = len(item_doc.get("likes", [])) if item_doc else 0
    
    return create_success_response(
        message="Hub item unliked successfully",
        data={"like_count": like_count}
    )


@router.post("/items/{item_id}/bookmark", status_code=status.HTTP_200_OK)
async def bookmark_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Bookmark a hub item.
    
    - Adds user to bookmarks array (prevents duplicates)
    - Returns success status
    """
    await hub_repo.check_item_access(item_id, str(current_user.id), raise_error=True)
    
    success = await hub_repo.toggle_bookmark(
        item_id=item_id,
        user_id=str(current_user.id),
        add_bookmark=True
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Hub item not found or already bookmarked")
    
    return create_message_response("Hub item bookmarked successfully")


@router.delete("/items/{item_id}/bookmark", status_code=status.HTTP_200_OK)
async def unbookmark_hub_item(
    item_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Remove bookmark from a hub item.
    
    - Removes user from bookmarks array
    - Returns success status
    """
    await hub_repo.check_item_access(item_id, str(current_user.id), raise_error=True)
    
    success = await hub_repo.toggle_bookmark(
        item_id=item_id,
        user_id=str(current_user.id),
        add_bookmark=False
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Hub item not found or not bookmarked")
    
    return create_message_response("Hub item bookmark removed successfully")


@router.get("/search")
async def search_hub_items(
    query: str = Query(..., description="Search query text"),
    item_types: Optional[List[HubItemType]] = Query(None, description="Filter by item types"),
    tags: Optional[List[str]] = Query(None, description="Filter by tags"),
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(10, ge=1, le=50, description="Number of results per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Search hub items with text search and filters.
    
    - Performs full-text search across item title and content
    - Supports filtering by item types and tags
    - Returns paginated results
    """
    skip = (page - 1) * page_size
    
    item_type_strs = [it.value for it in item_types] if item_types else None
    
    items = await hub_repo.search_items(
        user_id=str(current_user.id),
        query=query,
        item_types=item_type_strs,
        tags=tags,
        limit=page_size
    )
    
    item_responses = []
    for item_doc in items:
        owner_info = await get_owner_info(item_doc["owner_id"])
        item_responses.append(
            build_item_response(item_doc, owner_info["full_name"], owner_info["avatar"], str(current_user.id))
        )
    
    return create_success_response(
        message=f"Found {len(item_responses)} matching items",
        data=[i.model_dump() for i in item_responses]
    )


@router.get("/stats")
async def get_hub_statistics(
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get hub statistics for the user.
    
    - Returns total items count
    - Breakdown by item type
    - Total views and likes
    """
    stats = await hub_repo.get_stats(str(current_user.id))
    
    stats_response = HubStats(
        total_items=stats.get("total_items", 0),
        items_by_type=stats.get("items_by_type", {}),
        total_views=stats.get("total_views", 0),
        total_likes=stats.get("total_likes", 0),
        storage_used=0,
        storage_quota=1024 * 1024 * 1024
    )
    
    return create_success_response(
        message="Hub statistics retrieved successfully",
        data=stats_response.model_dump()
    )


@router.get("/activity")
async def get_recent_hub_activity(
    limit: int = Query(10, ge=1, le=50, description="Number of recent items"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get recent activity in the hub.
    
    - Returns most recently updated items
    - Includes engagement metrics
    - Limited to specified number of items
    """
    items = await hub_repo.get_recent_activity(
        user_id=str(current_user.id),
        limit=limit
    )
    
    item_responses = []
    for item_doc in items:
        owner_info = await get_owner_info(item_doc["owner_id"])
        item_responses.append(
            build_item_response(item_doc, owner_info["full_name"], owner_info["avatar"], str(current_user.id))
        )
    
    return create_success_response(
        message=f"Retrieved {len(item_responses)} recent activity items",
        data=[i.model_dump() for i in item_responses]
    )


@router.get("/dashboard")
async def get_hub_dashboard(
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get comprehensive hub dashboard with stats and recent activity.
    
    - Combines statistics and recent activity
    - Includes quick action links
    - Provides overview of user's hub
    """
    stats = await hub_repo.get_stats(str(current_user.id))
    recent_items = await hub_repo.get_recent_activity(str(current_user.id), limit=5)
    
    activity_responses = []
    for item_doc in recent_items:
        owner_info = await get_owner_info(item_doc["owner_id"])
        activity_responses.append(
            build_item_response(item_doc, owner_info["full_name"], owner_info["avatar"], str(current_user.id))
        )
    
    dashboard_data = {
        "stats": {
            "total_items": stats.get("total_items", 0),
            "items_by_type": stats.get("items_by_type", {}),
            "total_views": stats.get("total_views", 0),
            "total_likes": stats.get("total_likes", 0)
        },
        "recent_activity": [a.model_dump() for a in activity_responses],
        "quick_links": [
            {"title": "New Memory", "url": "/memories/new", "icon": "memory"},
            {"title": "Upload File", "url": "/vault/upload", "icon": "upload"},
            {"title": "Add Note", "url": "/hub/notes/new", "icon": "note"},
            {"title": "Add Task", "url": "/hub/tasks/new", "icon": "task"}
        ]
    }
    
    return create_success_response(
        message="Dashboard data retrieved successfully",
        data=dashboard_data
    )


@router.get("/")
async def list_hub_items_alias(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of items per page"),
    item_type: Optional[HubItemType] = Query(None, description="Filter by item type"),
    privacy: Optional[HubItemPrivacy] = Query(None, description="Filter by privacy level"),
    tag: Optional[str] = Query(None, description="Filter by tag"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Alias endpoint for /items - list hub items with pagination and filtering."""
    return await list_hub_items(page, page_size, item_type, privacy, tag, current_user)


@router.post("/")
async def create_hub_item_alias(
    item: HubItemCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Alias endpoint for /items - create a new hub item."""
    return await create_hub_item(item, current_user)
