from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime, timedelta
from bson import ObjectId
import secrets

from app.models.family import (
    FamilyRelationshipCreate, FamilyRelationshipResponse,
    FamilyCircleCreate, FamilyCircleUpdate, FamilyCircleResponse,
    FamilyInvitationCreate, FamilyInvitationResponse,
    FamilyRelationType, FamilyTreeNode,
    AddFamilyMemberRequest
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.utils.validators import validate_object_id, validate_object_ids, validate_user_has_access

router = APIRouter()


@router.post("/relationships", response_model=FamilyRelationshipResponse, status_code=status.HTTP_201_CREATED)
async def create_family_relationship(
    relationship: FamilyRelationshipCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family relationship"""
    try:
        related_user_oid = validate_object_id(relationship.related_user_id, "related_user_id")
        
        related_user = await get_collection("users").find_one({"_id": related_user_oid})
        if not related_user:
            raise HTTPException(status_code=404, detail="Related user not found")
        
        existing = await get_collection("family_relationships").find_one({
            "user_id": ObjectId(current_user.id),
            "related_user_id": related_user_oid
        })
        
        if existing:
            raise HTTPException(status_code=400, detail="Relationship already exists")
        
        relationship_data = {
            "user_id": ObjectId(current_user.id),
            "related_user_id": related_user_oid,
            "relation_type": relationship.relation_type,
            "relation_label": relationship.relation_label,
            "notes": relationship.notes,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("family_relationships").insert_one(relationship_data)
        relationship_doc = await get_collection("family_relationships").find_one({"_id": result.inserted_id})
        
        return FamilyRelationshipResponse(
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create relationship: {str(e)}")


@router.get("/relationships", response_model=List[FamilyRelationshipResponse])
async def list_family_relationships(
    relation_type: Optional[FamilyRelationType] = None,
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(50, ge=1, le=100, description="Number of records to return"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all family relationships for the current user with pagination"""
    try:
        query = {"user_id": ObjectId(current_user.id)}
        if relation_type:
            query["relation_type"] = relation_type.value
        
        cursor = get_collection("family_relationships").find(query).skip(skip).limit(limit).sort("created_at", -1)
        relationships = []
        
        async for rel_doc in cursor:
            related_user = await get_collection("users").find_one({"_id": rel_doc["related_user_id"]})
            relationships.append(FamilyRelationshipResponse(
                id=str(rel_doc["_id"]),
                user_id=str(rel_doc["user_id"]),
                related_user_id=str(rel_doc["related_user_id"]),
                related_user_name=related_user.get("full_name") if related_user else None,
                related_user_avatar=related_user.get("avatar_url") if related_user else None,
                related_user_email=related_user.get("email") if related_user else None,
                relation_type=rel_doc["relation_type"],
                relation_label=rel_doc.get("relation_label"),
                notes=rel_doc.get("notes"),
                created_at=rel_doc["created_at"],
                updated_at=rel_doc["updated_at"]
            ))
        
        return relationships
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list relationships: {str(e)}")


@router.delete("/relationships/{relationship_id}")
async def delete_family_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a family relationship"""
    try:
        relationship_oid = validate_object_id(relationship_id, "relationship_id")
        
        relationship = await get_collection("family_relationships").find_one({
            "_id": relationship_oid,
            "user_id": ObjectId(current_user.id)
        })
        
        if not relationship:
            raise HTTPException(status_code=404, detail="Relationship not found")
        
        await get_collection("family_relationships").delete_one({"_id": relationship_oid})
        return {"message": "Relationship deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete relationship: {str(e)}")


@router.post("/circles", response_model=FamilyCircleResponse, status_code=status.HTTP_201_CREATED)
async def create_family_circle(
    circle: FamilyCircleCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family circle"""
    try:
        member_oids = validate_object_ids(circle.member_ids, "member_ids") if circle.member_ids else []
        
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
        
        result = await get_collection("family_circles").insert_one(circle_data)
        circle_doc = await get_collection("family_circles").find_one({"_id": result.inserted_id})
        
        members = []
        for member_id in circle_doc["member_ids"]:
            user = await get_collection("users").find_one({"_id": member_id})
            if user:
                members.append({
                    "id": str(user["_id"]),
                    "name": user.get("full_name"),
                    "avatar": user.get("avatar_url")
                })
        
        return FamilyCircleResponse(
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
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create circle: {str(e)}")


@router.get("/circles", response_model=List[FamilyCircleResponse])
async def list_family_circles(
    current_user: UserInDB = Depends(get_current_user)
):
    """List all family circles for the current user"""
    try:
        query = {"member_ids": ObjectId(current_user.id)}
        cursor = get_collection("family_circles").find(query)
        circles = []
        
        async for circle_doc in cursor:
            members = []
            for member_id in circle_doc.get("member_ids", []):
                user = await get_collection("users").find_one({"_id": member_id})
                if user:
                    members.append({
                        "id": str(user["_id"]),
                        "name": user.get("full_name"),
                        "avatar": user.get("avatar_url")
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
        
        return circles
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
        circle_oid = validate_object_id(circle_id, "circle_id")
        user_oid = validate_object_id(user_id, "user_id")
        
        circle = await get_collection("family_circles").find_one({"_id": circle_oid})
        if not circle:
            raise HTTPException(status_code=404, detail="Circle not found")
        
        if circle["owner_id"] != ObjectId(current_user.id):
            raise HTTPException(status_code=403, detail="Only circle owner can add members")
        
        user = await get_collection("users").find_one({"_id": user_oid})
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        if user_oid in circle.get("member_ids", []):
            raise HTTPException(status_code=400, detail="User is already a member")
        
        await get_collection("family_circles").update_one(
            {"_id": circle_oid},
            {
                "$push": {"member_ids": user_oid},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        return {"message": "Member added successfully"}
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
        circle_oid = validate_object_id(circle_id, "circle_id")
        user_oid = validate_object_id(user_id, "user_id")
        
        circle = await get_collection("family_circles").find_one({"_id": circle_oid})
        if not circle:
            raise HTTPException(status_code=404, detail="Circle not found")
        
        if circle["owner_id"] != ObjectId(current_user.id):
            raise HTTPException(status_code=403, detail="Only circle owner can remove members")
        
        if circle["owner_id"] == user_oid:
            raise HTTPException(status_code=400, detail="Cannot remove circle owner")
        
        await get_collection("family_circles").update_one(
            {"_id": circle_oid},
            {
                "$pull": {"member_ids": user_oid},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        return {"message": "Member removed successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to remove member: {str(e)}")


@router.post("/invitations", response_model=FamilyInvitationResponse, status_code=status.HTTP_201_CREATED)
async def create_family_invitation(
    invitation: FamilyInvitationCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a family invitation"""
    try:
        circle_oids = validate_object_ids(invitation.circle_ids, "circle_ids")
        circle_names = []
        for circle_oid in circle_oids:
            circle = await get_collection("family_circles").find_one({"_id": circle_oid})
            if circle and circle.get("owner_id") == ObjectId(current_user.id):
                circle_names.append(circle.get("name", ""))
            else:
                raise HTTPException(status_code=403, detail="Can only create invitations for circles you own")
        
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
        
        result = await get_collection("family_invitations").insert_one(invitation_data)
        invitation_doc = await get_collection("family_invitations").find_one({"_id": result.inserted_id})
        
        from os import getenv
        base_url = getenv("REPLIT_DOMAINS", "localhost:5000").split(",")[0]
        if not base_url.startswith("http"):
            base_url = f"https://{base_url}"
        invite_url = f"{base_url}/accept-family-invite?token={token}"
        
        return FamilyInvitationResponse(
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
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create invitation: {str(e)}")


@router.post("/invitations/{token}/accept")
async def accept_family_invitation(
    token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Accept a family invitation"""
    try:
        invitation = await get_collection("family_invitations").find_one({"token": token})
        if not invitation:
            raise HTTPException(status_code=404, detail="Invitation not found")
        
        if invitation["status"] != "pending":
            raise HTTPException(status_code=400, detail="Invitation already processed")
        
        if invitation["expires_at"] < datetime.utcnow():
            await get_collection("family_invitations").update_one(
                {"_id": invitation["_id"]},
                {"$set": {"status": "expired"}}
            )
            raise HTTPException(status_code=410, detail="Invitation expired")
        
        if current_user.email.lower() != invitation["invitee_email"]:
            raise HTTPException(status_code=403, detail="This invitation is not for you")
        
        relationship_data = {
            "user_id": invitation["inviter_id"],
            "related_user_id": ObjectId(current_user.id),
            "relation_type": invitation["relation_type"],
            "relation_label": invitation.get("relation_label"),
            "notes": f"Added via invitation",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        await get_collection("family_relationships").insert_one(relationship_data)
        
        for circle_id in invitation.get("circle_ids", []):
            await get_collection("family_circles").update_one(
                {"_id": circle_id},
                {
                    "$addToSet": {"member_ids": ObjectId(current_user.id)},
                    "$set": {"updated_at": datetime.utcnow()}
                }
            )
        
        await get_collection("family_invitations").update_one(
            {"_id": invitation["_id"]},
            {
                "$set": {
                    "status": "accepted",
                    "accepted_at": datetime.utcnow()
                }
            }
        )
        
        return {"message": "Invitation accepted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to accept invitation: {str(e)}")


@router.get("/tree", response_model=List[FamilyTreeNode])
async def get_family_tree(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get the family tree for the current user"""
    try:
        cursor = get_collection("family_relationships").find({"user_id": ObjectId(current_user.id)})
        tree_nodes = []
        
        async for rel in cursor:
            user = await get_collection("users").find_one({"_id": rel["related_user_id"]})
            if user:
                tree_nodes.append(FamilyTreeNode(
                    user_id=str(user["_id"]),
                    name=user.get("full_name", "Unknown"),
                    avatar_url=user.get("avatar_url"),
                    relation_type=rel["relation_type"],
                    relation_label=rel.get("relation_label"),
                    children=[]
                ))
        
        return tree_nodes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get family tree: {str(e)}")


@router.post("/add-member", response_model=dict)
async def add_family_member(
    request: AddFamilyMemberRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Smart endpoint to add a family member - creates relationship and optionally sends invitation"""
    try:
        user = await get_collection("users").find_one({"email": request.email.lower()})
        
        if user:
            existing = await get_collection("family_relationships").find_one({
                "user_id": ObjectId(current_user.id),
                "related_user_id": user["_id"]
            })
            
            if existing:
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
            await get_collection("family_relationships").insert_one(relationship_data)
            
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
            result = await get_collection("family_invitations").insert_one(invitation_data)
            
            from os import getenv
            base_url = getenv("REPLIT_DOMAINS", "localhost:5000").split(",")[0]
            if not base_url.startswith("http"):
                base_url = f"https://{base_url}"
            invite_url = f"{base_url}/accept-family-invite?token={token}"
            
            return {
                "status": "invited",
                "message": "Invitation sent successfully",
                "invitation_id": str(result.inserted_id),
                "invite_url": invite_url,
                "email": request.email
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add family member: {str(e)}")
