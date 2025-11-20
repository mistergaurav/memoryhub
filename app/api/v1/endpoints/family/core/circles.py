"""Family circle operations endpoints."""
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


@router.post("/circles", status_code=status.HTTP_201_CREATED)
async def create_family_circle(
    circle: FamilyCircleCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family circle with custom relationship categories and member profiles"""
    try:
        member_oids = validate_object_id_list(circle.member_ids, "member_ids") if circle.member_ids else []
        
        member_oids.append(ObjectId(current_user.id))
        member_oids = list(set(member_oids))
        
        member_profiles_data = []
        for profile in circle.member_profiles:
            member_profiles_data.append({
                "user_id": profile.user_id,
                "display_name": profile.display_name,
                "relationship_label": profile.relationship_label,
                "avatar_url": profile.avatar_url,
                "email": profile.email,
                "added_date": profile.added_date,
                "notes": profile.notes
            })
        
        circle_data = {
            "name": circle.name,
            "description": circle.description,
            "circle_type": circle.circle_type,
            "custom_category": circle.custom_category,
            "avatar_url": circle.avatar_url,
            "color": circle.color,
            "owner_id": ObjectId(current_user.id),
            "member_ids": member_oids,
            "member_profiles": member_profiles_data,
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
        
        from app.models.family.family import CircleMemberProfile
        member_profiles = []
        for profile_data in circle_doc.get("member_profiles", []):
            member_profiles.append(CircleMemberProfile(**profile_data))
        
        circle_response = FamilyCircleResponse(
            id=str(circle_doc["_id"]),
            name=circle_doc["name"],
            description=circle_doc.get("description"),
            circle_type=circle_doc["circle_type"],
            custom_category=circle_doc.get("custom_category"),
            avatar_url=circle_doc.get("avatar_url"),
            color=circle_doc.get("color"),
            owner_id=str(circle_doc["owner_id"]),
            member_count=len(circle_doc["member_ids"]),
            members=members,
            member_profiles=member_profiles,
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
            
            from app.models.family.family import CircleMemberProfile
            member_profiles = []
            for profile_data in circle_doc.get("member_profiles", []):
                member_profiles.append(CircleMemberProfile(**profile_data))
            
            circles.append(FamilyCircleResponse(
                id=str(circle_doc["_id"]),
                name=circle_doc["name"],
                description=circle_doc.get("description"),
                circle_type=circle_doc["circle_type"],
                custom_category=circle_doc.get("custom_category"),
                avatar_url=circle_doc.get("avatar_url"),
                color=circle_doc.get("color"),
                owner_id=str(circle_doc["owner_id"]),
                member_count=len(circle_doc.get("member_ids", [])),
                members=members,
                member_profiles=member_profiles,
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


@router.post("/circles/{circle_id}/profiles")
async def add_person_profile_to_circle(
    circle_id: str,
    profile_data: dict,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a person profile to a relationship category/circle"""
    try:
        from app.models.family.family import CircleMemberProfile
        
        circle = await validate_family_ownership(
            str(current_user.id),
            circle_id,
            "family_circles"
        )
        
        user_id = profile_data.get("user_id")
        display_name = profile_data.get("display_name")
        
        if not display_name:
            raise HTTPException(
                status_code=400,
                detail="display_name is required for person profile"
            )
        
        if not user_id:
            user_id = display_name.lower().replace(" ", "_")
        
        profile = CircleMemberProfile(
            user_id=user_id,
            display_name=display_name,
            relationship_label=profile_data.get("relationship_label"),
            avatar_url=profile_data.get("avatar_url"),
            email=profile_data.get("email"),
            notes=profile_data.get("notes")
        )
        
        circle_oid = ObjectId(circle_id)
        profile_dict = profile.model_dump()
        
        result = await family_repo.collection.update_one(
            {"_id": circle_oid},
            {
                "$push": {"member_profiles": profile_dict},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        if profile.user_id:
            try:
                user_oid = ObjectId(profile.user_id)
                existing_members = circle.get("member_ids", [])
                if user_oid not in existing_members:
                    await family_repo.collection.update_one(
                        {"_id": circle_oid},
                        {
                            "$push": {"member_ids": user_oid},
                            "$set": {"updated_at": datetime.utcnow()}
                        }
                    )
            except Exception:
                pass
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="circle_profile_added",
            event_details={
                "circle_id": circle_id,
                "display_name": profile.display_name
            }
        )
        
        return create_success_response(
            message="Person profile added successfully",
            data=profile.model_dump()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add profile: {str(e)}")


@router.put("/circles/{circle_id}/profiles/{user_id}")
async def update_person_profile_in_circle(
    circle_id: str,
    user_id: str,
    update_data: dict,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a person profile within a relationship category/circle"""
    try:
        circle = await validate_family_ownership(
            str(current_user.id),
            circle_id,
            "family_circles"
        )
        
        circle_oid = ObjectId(circle_id)
        
        update_fields = {}
        if "display_name" in update_data:
            update_fields["member_profiles.$.display_name"] = update_data["display_name"]
        if "relationship_label" in update_data:
            update_fields["member_profiles.$.relationship_label"] = update_data["relationship_label"]
        if "avatar_url" in update_data:
            update_fields["member_profiles.$.avatar_url"] = update_data["avatar_url"]
        if "email" in update_data:
            update_fields["member_profiles.$.email"] = update_data["email"]
        if "notes" in update_data:
            update_fields["member_profiles.$.notes"] = update_data["notes"]
        
        update_fields["updated_at"] = datetime.utcnow()
        
        result = await family_repo.collection.update_one(
            {
                "_id": circle_oid,
                "member_profiles.user_id": user_id
            },
            {"$set": update_fields}
        )
        
        if result.modified_count == 0:
            raise HTTPException(
                status_code=404,
                detail="Person profile not found in this circle"
            )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="circle_profile_updated",
            event_details={
                "circle_id": circle_id,
                "profile_user_id": user_id
            }
        )
        
        return create_message_response("Person profile updated successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")


@router.delete("/circles/{circle_id}/profiles/{user_id}")
async def remove_person_profile_from_circle(
    circle_id: str,
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove a person profile from a relationship category/circle"""
    try:
        circle = await validate_family_ownership(
            str(current_user.id),
            circle_id,
            "family_circles"
        )
        
        circle_oid = ObjectId(circle_id)
        
        result = await family_repo.collection.update_one(
            {"_id": circle_oid},
            {
                "$pull": {"member_profiles": {"user_id": user_id}},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="circle_profile_removed",
            event_details={
                "circle_id": circle_id,
                "profile_user_id": user_id
            }
        )
        
        return create_message_response("Person profile removed successfully")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to remove profile: {str(e)}")


@router.get("/circles/by-category/{circle_type}")
async def get_circles_by_category(
    circle_type: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all circles of a specific relationship category for the current user"""
    try:
        from app.models.family.family import CircleMemberProfile
        
        user_oid = ObjectId(current_user.id)
        
        circles_docs = await family_repo.find_many(
            {
                "member_ids": user_oid,
                "circle_type": circle_type
            },
            limit=100,
            sort_by="created_at",
            sort_order=-1
        )
        
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
            
            member_profiles = []
            for profile_data in circle_doc.get("member_profiles", []):
                member_profiles.append(CircleMemberProfile(**profile_data))
            
            circles.append(FamilyCircleResponse(
                id=str(circle_doc["_id"]),
                name=circle_doc["name"],
                description=circle_doc.get("description"),
                circle_type=circle_doc["circle_type"],
                custom_category=circle_doc.get("custom_category"),
                avatar_url=circle_doc.get("avatar_url"),
                color=circle_doc.get("color"),
                owner_id=str(circle_doc["owner_id"]),
                member_count=len(circle_doc.get("member_ids", [])),
                members=members,
                member_profiles=member_profiles,
                created_at=circle_doc["created_at"],
                updated_at=circle_doc["updated_at"]
            ))
        
        return create_success_response(
            message=f"Circles of type '{circle_type}' retrieved successfully",
            data=[c.model_dump() for c in circles]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get circles by category: {str(e)}")


