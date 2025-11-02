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

router = APIRouter()

family_repo = FamilyRepository()
relationship_repo = FamilyRelationshipRepository()
invitation_repo = FamilyInvitationRepository()
user_repo = UserRepository()


async def get_user_data(user_id: ObjectId) -> dict:
    """Helper function to get user data by ID"""
    user = await user_repo.find_one({"_id": user_id}, raise_404=False)
    if user:
        return {
            "id": str(user["_id"]),
            "name": user.get("full_name"),
            "avatar": user.get("avatar_url"),
            "email": user.get("email")
        }
    return {"id": str(user_id), "name": None, "avatar": None, "email": None}


@router.post("/relationships", status_code=status.HTTP_201_CREATED)
async def create_family_relationship(
    relationship: FamilyRelationshipCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family relationship"""
    try:
        related_user = await validate_user_exists(relationship.related_user_id, "related user")
        
        await validate_no_duplicate_relationship(
            str(current_user.id),
            relationship.related_user_id
        )
        
        relationship_data = {
            "user_id": ObjectId(current_user.id),
            "related_user_id": ObjectId(relationship.related_user_id),
            "relation_type": relationship.relation_type,
            "relation_label": relationship.relation_label,
            "notes": relationship.notes,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        relationship_doc = await relationship_repo.create(relationship_data)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_relationship_created",
            event_details={
                "relationship_id": str(relationship_doc["_id"]),
                "related_user_id": relationship.related_user_id,
                "relation_type": relationship.relation_type
            }
        )
        
        relationship_response = FamilyRelationshipResponse(
            id=str(relationship_doc["_id"]),
            user_id=str(relationship_doc["user_id"]),
            related_user_id=str(relationship_doc["related_user_id"]),
            related_user_name=related_user.get("full_name"),
            related_user_avatar=related_user.get("avatar_url"),
            related_user_email=related_user.get("email"),
            relation_type=relationship_doc["relation_type"],
            relation_label=relationship_doc.get("relation_label"),
            notes=relationship_doc.get("notes"),
            created_at=relationship_doc["created_at"],
            updated_at=relationship_doc["updated_at"]
        )
        
        return create_success_response(
            message="Relationship created successfully",
            data=relationship_response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create relationship: {str(e)}")


@router.get("/relationships")
async def list_family_relationships(
    relation_type: Optional[FamilyRelationType] = None,
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=100, description="Number of records per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all family relationships for the current user with pagination"""
    try:
        skip = (page - 1) * page_size
        
        relationships_docs = await relationship_repo.find_by_user(
            str(current_user.id),
            relation_type=relation_type.value if relation_type else None,
            skip=skip,
            limit=page_size
        )
        
        total = await relationship_repo.count_by_user(
            str(current_user.id),
            relation_type=relation_type.value if relation_type else None
        )
        
        relationships = []
        for rel_doc in relationships_docs:
            user_data = await get_user_data(rel_doc["related_user_id"])
            relationships.append(FamilyRelationshipResponse(
                id=str(rel_doc["_id"]),
                user_id=str(rel_doc["user_id"]),
                related_user_id=str(rel_doc["related_user_id"]),
                related_user_name=user_data.get("name"),
                related_user_avatar=user_data.get("avatar"),
                related_user_email=user_data.get("email"),
                relation_type=rel_doc["relation_type"],
                relation_label=rel_doc.get("relation_label"),
                notes=rel_doc.get("notes"),
                created_at=rel_doc["created_at"],
                updated_at=rel_doc["updated_at"]
            ))
        
        return create_paginated_response(
            items=[r.model_dump() for r in relationships],
            total=total,
            page=page,
            page_size=page_size,
            message="Relationships retrieved successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list relationships: {str(e)}")


@router.delete("/relationships/{relationship_id}")
async def delete_family_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a family relationship"""
    try:
        await validate_relationship_ownership(str(current_user.id), relationship_id)
        
        await relationship_repo.delete_by_id(relationship_id)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_relationship_deleted",
            event_details={"relationship_id": relationship_id}
        )
        
        return create_message_response("Relationship deleted successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete relationship: {str(e)}")


@router.post("/circles", status_code=status.HTTP_201_CREATED)
async def create_family_circle(
    circle: FamilyCircleCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family circle"""
    try:
        member_oids = validate_object_id_list(circle.member_ids, "member_ids") if circle.member_ids else []
        
        member_oids.append(ObjectId(current_user.id))
        member_oids = list(set(member_oids))
        
        circle_data = {
            "name": circle.name,
            "description": circle.description,
            "circle_type": circle.circle_type,
            "avatar_url": circle.avatar_url,
            "color": circle.color,
            "owner_id": ObjectId(current_user.id),
            "member_ids": member_oids,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        circle_doc = await family_repo.create(circle_data)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_circle_created",
            event_details={
                "circle_id": str(circle_doc["_id"]),
                "name": circle.name,
                "circle_type": circle.circle_type,
                "member_count": len(circle_doc["member_ids"])
            }
        )
        
        members = []
        for member_id in circle_doc["member_ids"]:
            user_data = await get_user_data(member_id)
            if user_data.get("name"):
                members.append({
                    "id": user_data["id"],
                    "name": user_data["name"],
                    "avatar": user_data["avatar"]
                })
        
        circle_response = FamilyCircleResponse(
            id=str(circle_doc["_id"]),
            name=circle_doc["name"],
            description=circle_doc.get("description"),
            circle_type=circle_doc["circle_type"],
            avatar_url=circle_doc.get("avatar_url"),
            color=circle_doc.get("color"),
            owner_id=str(circle_doc["owner_id"]),
            member_count=len(circle_doc["member_ids"]),
            members=members,
            created_at=circle_doc["created_at"],
            updated_at=circle_doc["updated_at"]
        )
        
        return create_success_response(
            message="Circle created successfully",
            data=circle_response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create circle: {str(e)}")


@router.get("/circles")
async def list_family_circles(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=100, description="Number of circles per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all family circles for the current user with pagination"""
    try:
        skip = (page - 1) * page_size
        circles_docs = await family_repo.find_by_member(str(current_user.id), skip=skip, limit=page_size)
        total = await family_repo.count_by_member(str(current_user.id))
        circles = []
        
        for circle_doc in circles_docs:
            members = []
            for member_id in circle_doc.get("member_ids", []):
                user_data = await get_user_data(member_id)
                if user_data.get("name"):
                    members.append({
                        "id": user_data["id"],
                        "name": user_data["name"],
                        "avatar": user_data["avatar"]
                    })
            
            circles.append(FamilyCircleResponse(
                id=str(circle_doc["_id"]),
                name=circle_doc["name"],
                description=circle_doc.get("description"),
                circle_type=circle_doc["circle_type"],
                avatar_url=circle_doc.get("avatar_url"),
                color=circle_doc.get("color"),
                owner_id=str(circle_doc["owner_id"]),
                member_count=len(circle_doc.get("member_ids", [])),
                members=members,
                created_at=circle_doc["created_at"],
                updated_at=circle_doc["updated_at"]
            ))
        
        return create_paginated_response(
            items=[c.model_dump() for c in circles],
            total=total,
            page=page,
            page_size=page_size,
            message="Circles retrieved successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list circles: {str(e)}")


@router.post("/circles/{circle_id}/members/{user_id}")
async def add_member_to_circle(
    circle_id: str,
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a member to a family circle"""
    try:
        circle = await validate_family_ownership(
            str(current_user.id),
            circle_id,
            "family_circles"
        )
        
        await validate_user_exists(user_id, "user")
        
        await validate_user_not_in_circle(circle, user_id)
        
        await family_repo.add_member(circle_id, user_id, str(current_user.id))
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_circle_member_added",
            event_details={"circle_id": circle_id, "member_id": user_id}
        )
        
        return create_message_response("Member added successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add member: {str(e)}")


@router.delete("/circles/{circle_id}/members/{user_id}")
async def remove_member_from_circle(
    circle_id: str,
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove a member from a family circle"""
    try:
        circle = await validate_family_ownership(
            str(current_user.id),
            circle_id,
            "family_circles"
        )
        
        await validate_user_not_owner(circle, user_id)
        
        await family_repo.remove_member(circle_id, user_id, str(current_user.id))
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_circle_member_removed",
            event_details={"circle_id": circle_id, "member_id": user_id}
        )
        
        return create_message_response("Member removed successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to remove member: {str(e)}")


@router.post("/invitations", status_code=status.HTTP_201_CREATED)
async def create_family_invitation(
    invitation: FamilyInvitationCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family invitation"""
    try:
        circles = await validate_circle_ownership_for_invitations(
            str(current_user.id),
            invitation.circle_ids
        )
        
        circle_names = [circle.get("name", "") for circle in circles]
        circle_oids = [circle["_id"] for circle in circles]
        
        token = secrets.token_urlsafe(32)
        
        invitation_data = {
            "inviter_id": ObjectId(current_user.id),
            "invitee_email": invitation.invitee_email.lower(),
            "relation_type": invitation.relation_type,
            "relation_label": invitation.relation_label,
            "message": invitation.message,
            "circle_ids": circle_oids,
            "token": token,
            "status": "pending",
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(days=7)
        }
        
        invitation_doc = await invitation_repo.create(invitation_data)
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_invitation_created",
            event_details={
                "invitation_id": str(invitation_doc["_id"]),
                "invitee_email": invitation.invitee_email,
                "circle_count": len(circle_oids)
            }
        )
        
        from os import getenv
        base_url = getenv("REPLIT_DOMAINS", "localhost:5000").split(",")[0]
        if not base_url.startswith("http"):
            base_url = f"https://{base_url}"
        invite_url = f"{base_url}/accept-family-invite?token={token}"
        
        invitation_response = FamilyInvitationResponse(
            id=str(invitation_doc["_id"]),
            inviter_id=str(invitation_doc["inviter_id"]),
            inviter_name=current_user.full_name,
            invitee_email=invitation_doc["invitee_email"],
            relation_type=invitation_doc["relation_type"],
            relation_label=invitation_doc.get("relation_label"),
            message=invitation_doc.get("message"),
            circle_ids=[str(cid) for cid in invitation_doc.get("circle_ids", [])],
            circle_names=circle_names,
            token=invitation_doc["token"],
            status=invitation_doc["status"],
            invite_url=invite_url,
            created_at=invitation_doc["created_at"],
            expires_at=invitation_doc["expires_at"]
        )
        
        return create_success_response(
            message="Invitation created successfully",
            data=invitation_response.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create invitation: {str(e)}")


@router.post("/invitations/{token}/accept")
async def accept_family_invitation(
    token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Accept a family invitation"""
    try:
        invitation = await validate_invitation_token(token)
        
        await validate_invitation_for_user(invitation, current_user.email)
        
        relationship_data = {
            "user_id": invitation["inviter_id"],
            "related_user_id": ObjectId(current_user.id),
            "relation_type": invitation["relation_type"],
            "relation_label": invitation.get("relation_label"),
            "notes": f"Added via invitation",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        await relationship_repo.create(relationship_data)
        
        for circle_id in invitation.get("circle_ids", []):
            await family_repo.add_member(
                str(circle_id),
                str(current_user.id),
                str(invitation["inviter_id"])
            )
        
        await invitation_repo.update(
            {"_id": invitation["_id"]},
            {
                "status": "accepted",
                "accepted_at": datetime.utcnow()
            }
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="family_invitation_accepted",
            event_details={
                "invitation_id": str(invitation["_id"]),
                "inviter_id": str(invitation["inviter_id"])
            }
        )
        
        return create_message_response("Invitation accepted successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to accept invitation: {str(e)}")


@router.get("/tree")
async def get_family_tree(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(100, ge=1, le=500, description="Number of nodes per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get the family tree for the current user with pagination"""
    try:
        skip = (page - 1) * page_size
        relationships_docs = await relationship_repo.find_by_user(str(current_user.id), skip=skip, limit=page_size)
        total = await relationship_repo.count_by_user(str(current_user.id))
        tree_nodes = []
        
        for rel in relationships_docs:
            user_data = await get_user_data(rel["related_user_id"])
            if user_data.get("name"):
                tree_nodes.append(FamilyTreeNode(
                    user_id=user_data["id"],
                    name=user_data.get("name", "Unknown"),
                    avatar_url=user_data.get("avatar"),
                    relation_type=rel["relation_type"],
                    relation_label=rel.get("relation_label"),
                    children=[]
                ))
        
        return create_paginated_response(
            items=[node.model_dump() for node in tree_nodes],
            total=total,
            page=page,
            page_size=page_size,
            message="Family tree retrieved successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get family tree: {str(e)}")


@router.post("/add-member", response_model=dict)
async def add_family_member(
    request: AddFamilyMemberRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Smart endpoint to add a family member - creates relationship and optionally sends invitation"""
    try:
        user = await user_repo.find_by_email(request.email)
        
        if user:
            relationship_exists = await relationship_repo.check_relationship_exists(
                str(current_user.id),
                str(user["_id"])
            )
            
            if relationship_exists:
                return {
                    "status": "already_exists",
                    "message": "Family relationship already exists",
                    "user_id": str(user["_id"])
                }
            
            relationship_data = {
                "user_id": ObjectId(current_user.id),
                "related_user_id": user["_id"],
                "relation_type": request.relation_type,
                "relation_label": request.relation_label,
                "notes": request.notes,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            await relationship_repo.create(relationship_data)
            
            return {
                "status": "added",
                "message": "Family member added successfully",
                "user_id": str(user["_id"]),
                "user_name": user.get("full_name")
            }
        else:
            if not request.send_invitation:
                return {
                    "status": "not_found",
                    "message": "User not found. Set send_invitation=true to invite them.",
                    "email": request.email
                }
            
            token = secrets.token_urlsafe(32)
            invitation_data = {
                "inviter_id": ObjectId(current_user.id),
                "invitee_email": request.email.lower(),
                "relation_type": request.relation_type,
                "relation_label": request.relation_label,
                "message": request.invitation_message or f"{current_user.full_name} would like to add you as their {request.relation_type} on Memory Hub",
                "circle_ids": [],
                "token": token,
                "status": "pending",
                "created_at": datetime.utcnow(),
                "expires_at": datetime.utcnow() + timedelta(days=7)
            }
            invitation_doc = await invitation_repo.create(invitation_data)
            
            from os import getenv
            base_url = getenv("REPLIT_DOMAINS", "localhost:5000").split(",")[0]
            if not base_url.startswith("http"):
                base_url = f"https://{base_url}"
            invite_url = f"{base_url}/accept-family-invite?token={token}"
            
            return {
                "status": "invited",
                "message": "Invitation sent successfully",
                "invitation_id": str(invitation_doc["_id"]),
                "invite_url": invite_url,
                "email": request.email
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add family member: {str(e)}")


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
