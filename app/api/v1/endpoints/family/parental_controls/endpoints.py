from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from typing import List
from bson import ObjectId
from datetime import datetime

from .schemas import (
    ParentalControlSettingsCreate, ParentalControlSettingsUpdate,
    ParentalControlSettingsResponse, ContentApprovalRequest,
    ContentApprovalRequestResponse, ApprovalDecision
)
from app.models.user import UserInDB
from app.models.responses import create_paginated_response, create_success_response
from app.core.security import get_current_user
from app.repositories.base_repository import BaseRepository
from app.utils.family_validators import validate_parent_child_relationship
from app.utils.audit_logger import log_audit_event

router = APIRouter()

parental_controls_repo = BaseRepository("parental_controls")
approval_requests_repo = BaseRepository("approval_requests")
users_repo = BaseRepository("users")


@router.post("/settings", status_code=status.HTTP_201_CREATED)
async def create_parental_controls(
    settings: ParentalControlSettingsCreate,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create parental control settings for a child"""
    child_oid = parental_controls_repo.validate_object_id(settings.child_user_id, "child_user_id")
    
    ip_address = request.client.host if request.client else None
    
    await validate_parent_child_relationship(
        parent_id=current_user.id,
        child_id=settings.child_user_id,
        ip_address=ip_address
    )
    
    child_user = await users_repo.find_by_id(
        settings.child_user_id,
        raise_404=True,
        error_message="Child user not found"
    )
    
    existing = await parental_controls_repo.find_one({
        "parent_user_id": ObjectId(current_user.id),
        "child_user_id": child_oid
    }, raise_404=False)
    
    if existing:
        raise HTTPException(status_code=400, detail="Parental controls already exist for this child")
    
    settings_data = {
        "parent_user_id": ObjectId(current_user.id),
        "child_user_id": child_oid,
        "content_rating_limit": settings.content_rating_limit,
        "require_approval_for_posts": settings.require_approval_for_posts,
        "require_approval_for_sharing": settings.require_approval_for_sharing,
        "restrict_external_contacts": settings.restrict_external_contacts,
        "allowed_features": settings.allowed_features,
        "screen_time_limit_minutes": settings.screen_time_limit_minutes
    }
    
    settings_doc = await parental_controls_repo.create(settings_data)
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="parental_control_created",
        event_details={
            "child_user_id": settings.child_user_id,
            "settings": {
                "content_rating_limit": settings.content_rating_limit,
                "require_approval_for_posts": settings.require_approval_for_posts,
                "require_approval_for_sharing": settings.require_approval_for_sharing,
                "restrict_external_contacts": settings.restrict_external_contacts
            }
        },
        ip_address=ip_address
    )
    
    settings_response = ParentalControlSettingsResponse(
        id=str(settings_doc["_id"]),
        parent_user_id=str(settings_doc["parent_user_id"]),
        child_user_id=str(settings_doc["child_user_id"]),
        child_name=child_user.get("full_name") if child_user else None,
        content_rating_limit=settings_doc["content_rating_limit"],
        require_approval_for_posts=settings_doc["require_approval_for_posts"],
        require_approval_for_sharing=settings_doc["require_approval_for_sharing"],
        restrict_external_contacts=settings_doc["restrict_external_contacts"],
        allowed_features=settings_doc["allowed_features"],
        screen_time_limit_minutes=settings_doc.get("screen_time_limit_minutes"),
        created_at=settings_doc["created_at"],
        updated_at=settings_doc["updated_at"]
    )
    
    return create_success_response(
        message="Parental controls created successfully",
        data=settings_response.model_dump()
    )


@router.get("/settings")
async def list_parental_controls(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of records to return"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all parental control settings created by the current user"""
    user_oid = ObjectId(current_user.id)
    
    filter_dict = {"parent_user_id": user_oid}
    settings_list_docs = await parental_controls_repo.find_many(
        filter_dict,
        skip=skip,
        limit=limit,
        sort_by="created_at",
        sort_order=-1
    )
    
    total = await parental_controls_repo.count(filter_dict)
    
    settings_list = []
    for settings_doc in settings_list_docs:
        child_user = await users_repo.find_by_id(
            str(settings_doc["child_user_id"]),
            raise_404=False
        )
        
        settings_list.append(ParentalControlSettingsResponse(
            id=str(settings_doc["_id"]),
            parent_user_id=str(settings_doc["parent_user_id"]),
            child_user_id=str(settings_doc["child_user_id"]),
            child_name=child_user.get("full_name") if child_user else None,
            content_rating_limit=settings_doc["content_rating_limit"],
            require_approval_for_posts=settings_doc["require_approval_for_posts"],
            require_approval_for_sharing=settings_doc["require_approval_for_sharing"],
            restrict_external_contacts=settings_doc["restrict_external_contacts"],
            allowed_features=settings_doc["allowed_features"],
            screen_time_limit_minutes=settings_doc.get("screen_time_limit_minutes"),
            created_at=settings_doc["created_at"],
            updated_at=settings_doc["updated_at"]
        ))
    
    page = (skip // limit) + 1 if limit > 0 else 1
    return create_paginated_response(
        items=settings_list,
        total=total,
        page=page,
        page_size=limit,
        message="Parental control settings retrieved successfully"
    )


@router.get("/settings/{child_user_id}")
async def get_parental_controls(
    child_user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get parental control settings for a specific child"""
    child_oid = parental_controls_repo.validate_object_id(child_user_id, "child_user_id")
    
    settings_doc = await parental_controls_repo.find_one(
        {
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid
        },
        raise_404=True,
        error_message="Parental controls not found for this child"
    )
    
    child_user = await users_repo.find_by_id(child_user_id, raise_404=False)
    
    if not settings_doc:
        raise HTTPException(status_code=404, detail="Parental controls not found")
    
    settings_response = ParentalControlSettingsResponse(
        id=str(settings_doc["_id"]),
        parent_user_id=str(settings_doc["parent_user_id"]),
        child_user_id=str(settings_doc["child_user_id"]),
        child_name=child_user.get("full_name") if child_user else None,
        content_rating_limit=settings_doc["content_rating_limit"],
        require_approval_for_posts=settings_doc["require_approval_for_posts"],
        require_approval_for_sharing=settings_doc["require_approval_for_sharing"],
        restrict_external_contacts=settings_doc["restrict_external_contacts"],
        allowed_features=settings_doc["allowed_features"],
        screen_time_limit_minutes=settings_doc.get("screen_time_limit_minutes"),
        created_at=settings_doc["created_at"],
        updated_at=settings_doc["updated_at"]
    )
    
    return create_success_response(
        message="Parental controls retrieved successfully",
        data=settings_response.model_dump()
    )


@router.put("/settings/{child_user_id}")
async def update_parental_controls(
    child_user_id: str,
    settings_update: ParentalControlSettingsUpdate,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update parental control settings"""
    child_oid = parental_controls_repo.validate_object_id(child_user_id, "child_user_id")
    
    ip_address = request.client.host if request.client else None
    
    await validate_parent_child_relationship(
        parent_id=current_user.id,
        child_id=child_user_id,
        ip_address=ip_address
    )
    
    settings_doc = await parental_controls_repo.find_one(
        {
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid
        },
        raise_404=True,
        error_message="Parental controls not found for this child"
    )
    
    update_data = {k: v for k, v in settings_update.dict(exclude_unset=True).items() if v is not None}
    
    if not settings_doc:
        raise HTTPException(status_code=404, detail="Parental controls not found")
    
    updated_settings = await parental_controls_repo.update(
        {"_id": settings_doc["_id"]},
        update_data,
        raise_404=True
    )
    
    child_user = await users_repo.find_by_id(child_user_id, raise_404=False)
    
    if not updated_settings:
        raise HTTPException(status_code=404, detail="Parental controls not found after update")
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="parental_control_updated",
        event_details={
            "child_user_id": child_user_id,
            "updates": update_data
        },
        ip_address=ip_address
    )
    
    settings_response = ParentalControlSettingsResponse(
        id=str(updated_settings["_id"]),
        parent_user_id=str(updated_settings["parent_user_id"]),
        child_user_id=str(updated_settings["child_user_id"]),
        child_name=child_user.get("full_name") if child_user else None,
        content_rating_limit=updated_settings["content_rating_limit"],
        require_approval_for_posts=updated_settings["require_approval_for_posts"],
        require_approval_for_sharing=updated_settings["require_approval_for_sharing"],
        restrict_external_contacts=updated_settings["restrict_external_contacts"],
        allowed_features=updated_settings["allowed_features"],
        screen_time_limit_minutes=updated_settings.get("screen_time_limit_minutes"),
        created_at=updated_settings["created_at"],
        updated_at=updated_settings["updated_at"]
    )
    
    return create_success_response(
        message="Parental controls updated successfully",
        data=settings_response.model_dump()
    )


@router.delete("/settings/{child_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_parental_controls(
    child_user_id: str,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete parental control settings"""
    child_oid = parental_controls_repo.validate_object_id(child_user_id, "child_user_id")
    
    ip_address = request.client.host if request.client else None
    
    await validate_parent_child_relationship(
        parent_id=current_user.id,
        child_id=child_user_id,
        ip_address=ip_address
    )
    
    deleted = await parental_controls_repo.delete(
        {
            "parent_user_id": ObjectId(current_user.id),
            "child_user_id": child_oid
        },
        raise_404=True
    )
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="parental_control_deleted",
        event_details={
            "child_user_id": child_user_id
        },
        ip_address=ip_address
    )


@router.post("/approval-requests", status_code=status.HTTP_201_CREATED)
async def create_approval_request(
    request: ContentApprovalRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a content approval request (by child)"""
    content_oid = approval_requests_repo.validate_object_id(request.content_id, "content_id")
    child_oid = ObjectId(current_user.id)
    
    settings_doc = await parental_controls_repo.find_one(
        {"child_user_id": child_oid},
        raise_404=True,
        error_message="No parental controls found"
    )
    
    if not settings_doc:
        raise HTTPException(status_code=404, detail="No parental controls found")
    
    request_data = {
        "child_user_id": child_oid,
        "parent_user_id": settings_doc["parent_user_id"],
        "content_type": request.content_type,
        "content_id": content_oid,
        "content_title": request.content_title,
        "content_preview": request.content_preview,
        "status": "pending",
        "parent_notes": None,
        "reviewed_at": None
    }
    
    request_doc = await approval_requests_repo.create(request_data)
    
    approval_response = ContentApprovalRequestResponse(
        id=str(request_doc["_id"]),
        child_user_id=str(request_doc["child_user_id"]),
        child_name=current_user.full_name,
        parent_user_id=str(request_doc["parent_user_id"]),
        content_type=request_doc["content_type"],
        content_id=str(request_doc["content_id"]),
        content_title=request_doc.get("content_title"),
        content_preview=request_doc.get("content_preview"),
        status=request_doc["status"],
        parent_notes=request_doc.get("parent_notes"),
        created_at=request_doc["created_at"],
        reviewed_at=request_doc.get("reviewed_at")
    )
    
    return create_success_response(
        message="Approval request created successfully",
        data=approval_response.model_dump()
    )


@router.get("/approval-requests/pending")
async def list_pending_approval_requests(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of records to return"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List pending approval requests for parent"""
    user_oid = ObjectId(current_user.id)
    
    filter_dict = {
        "parent_user_id": user_oid,
        "status": "pending"
    }
    
    requests_docs = await approval_requests_repo.find_many(
        filter_dict,
        skip=skip,
        limit=limit,
        sort_by="created_at",
        sort_order=-1
    )
    
    total = await approval_requests_repo.count(filter_dict)
    
    requests = []
    for request_doc in requests_docs:
        child_user = await users_repo.find_by_id(
            str(request_doc["child_user_id"]),
            raise_404=False
        )
        
        requests.append(ContentApprovalRequestResponse(
            id=str(request_doc["_id"]),
            child_user_id=str(request_doc["child_user_id"]),
            child_name=child_user.get("full_name") if child_user else None,
            parent_user_id=str(request_doc["parent_user_id"]),
            content_type=request_doc["content_type"],
            content_id=str(request_doc["content_id"]),
            content_title=request_doc.get("content_title"),
            content_preview=request_doc.get("content_preview"),
            status=request_doc["status"],
            parent_notes=request_doc.get("parent_notes"),
            created_at=request_doc["created_at"],
            reviewed_at=request_doc.get("reviewed_at")
        ))
    
    page = (skip // limit) + 1 if limit > 0 else 1
    return create_paginated_response(
        items=requests,
        total=total,
        page=page,
        page_size=limit,
        message="Pending approval requests retrieved successfully"
    )


@router.post("/approval-requests/{request_id}/review")
async def review_approval_request(
    request_id: str,
    decision: ApprovalDecision,
    request: Request,
    current_user: UserInDB = Depends(get_current_user)
):
    """Review an approval request (by parent)"""
    request_doc = await approval_requests_repo.find_by_id(
        request_id,
        raise_404=True,
        error_message="Approval request not found"
    )
    
    ip_address = request.client.host if request.client else None
    
    if str(request_doc["parent_user_id"]) != current_user.id:
        await log_audit_event(
            user_id=current_user.id,
            event_type="parental_control_security_violation",
            event_details={
                "violation_type": "unauthorized_approval_review_attempt",
                "approval_request_id": request_id,
                "actual_parent_id": str(request_doc["parent_user_id"])
            },
            ip_address=ip_address
        )
        raise HTTPException(status_code=403, detail="Not authorized to review this request")
    
    if not request_doc:
        raise HTTPException(status_code=404, detail="Approval request not found")
    
    update_data = {
        "status": decision.status,
        "parent_notes": decision.parent_notes,
        "reviewed_at": datetime.utcnow()
    }
    
    updated_request = await approval_requests_repo.update(
        {"_id": request_doc["_id"]},
        update_data,
        raise_404=True
    )
    
    if not updated_request:
        raise HTTPException(status_code=404, detail="Approval request not found after update")
    
    child_user = await users_repo.find_by_id(
        str(updated_request["child_user_id"]),
        raise_404=False
    )
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="approval_request_reviewed",
        event_details={
            "request_id": request_id,
            "child_user_id": str(updated_request["child_user_id"]),
            "decision": decision.status,
            "content_type": updated_request["content_type"],
            "content_id": str(updated_request["content_id"])
        },
        ip_address=ip_address
    )
    
    approval_response = ContentApprovalRequestResponse(
        id=str(updated_request["_id"]),
        child_user_id=str(updated_request["child_user_id"]),
        child_name=child_user.get("full_name") if child_user else None,
        parent_user_id=str(updated_request["parent_user_id"]),
        content_type=updated_request["content_type"],
        content_id=str(updated_request["content_id"]),
        content_title=updated_request.get("content_title"),
        content_preview=updated_request.get("content_preview"),
        status=updated_request["status"],
        parent_notes=updated_request.get("parent_notes"),
        created_at=updated_request["created_at"],
        reviewed_at=updated_request.get("reviewed_at")
    )
    
    return create_success_response(
        message="Approval request reviewed successfully",
        data=approval_response.model_dump()
    )
