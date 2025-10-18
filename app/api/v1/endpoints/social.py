from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from datetime import datetime, timedelta
from bson import ObjectId
import secrets
from app.models.user import UserInDB
from app.models.social import (
    CollaborativeHubCreate, CollaborativeHubUpdate, CollaborativeHubResponse,
    HubMemberResponse, HubInvitationCreate, HubInvitationResponse,
    HubSharingLinkCreate, HubSharingLinkResponse, HubRole, HubPrivacy,
    InvitationStatus, RelationshipResponse, RelationshipStatus
)
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

@router.post("/hubs", response_model=CollaborativeHubResponse, status_code=status.HTTP_201_CREATED)
async def create_hub(
    hub: CollaborativeHubCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new collaborative hub"""
    hub_data = hub.dict()
    hub_data["owner_id"] = ObjectId(current_user.id)
    hub_data["created_at"] = datetime.utcnow()
    hub_data["updated_at"] = datetime.utcnow()
    hub_data["member_count"] = 1
    
    result = await get_collection("hubs").insert_one(hub_data)
    
    member_data = {
        "hub_id": result.inserted_id,
        "user_id": ObjectId(current_user.id),
        "role": HubRole.OWNER,
        "joined_at": datetime.utcnow()
    }
    await get_collection("hub_members").insert_one(member_data)
    
    hub_doc = await get_collection("hubs").find_one({"_id": result.inserted_id})
    return await _prepare_hub_response(hub_doc, current_user.id)

@router.get("/hubs", response_model=List[CollaborativeHubResponse])
async def list_hubs(
    privacy: Optional[HubPrivacy] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """List hubs the user is a member of or can access"""
    member_hubs = await get_collection("hub_members").find({
        "user_id": ObjectId(current_user.id)
    }).to_list(length=None)
    
    hub_ids = [member["hub_id"] for member in member_hubs]
    
    query = {"_id": {"$in": hub_ids}}
    if privacy:
        query["privacy"] = privacy
    if search:
        query["$or"] = [
            {"name": {"$regex": search, "$options": "i"}},
            {"description": {"$regex": search, "$options": "i"}}
        ]
    
    skip = (page - 1) * limit
    cursor = get_collection("hubs").find(query).skip(skip).limit(limit)
    
    hubs = []
    async for hub_doc in cursor:
        hubs.append(await _prepare_hub_response(hub_doc, current_user.id))
    
    return hubs

@router.get("/hubs/{hub_id}", response_model=CollaborativeHubResponse)
async def get_hub(
    hub_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific hub"""
    hub_doc = await get_collection("hubs").find_one({"_id": ObjectId(hub_id)})
    if not hub_doc:
        raise HTTPException(status_code=404, detail="Hub not found")
    
    member = await get_collection("hub_members").find_one({
        "hub_id": ObjectId(hub_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if not member and hub_doc["privacy"] == HubPrivacy.PRIVATE:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return await _prepare_hub_response(hub_doc, current_user.id)

@router.put("/hubs/{hub_id}", response_model=CollaborativeHubResponse)
async def update_hub(
    hub_id: str,
    hub_update: CollaborativeHubUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a hub (owner or admin only)"""
    member = await get_collection("hub_members").find_one({
        "hub_id": ObjectId(hub_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if not member or member["role"] not in [HubRole.OWNER, HubRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    
    update_data = hub_update.dict(exclude_unset=True)
    update_data["updated_at"] = datetime.utcnow()
    
    await get_collection("hubs").update_one(
        {"_id": ObjectId(hub_id)},
        {"$set": update_data}
    )
    
    hub_doc = await get_collection("hubs").find_one({"_id": ObjectId(hub_id)})
    return await _prepare_hub_response(hub_doc, current_user.id)

@router.get("/hubs/{hub_id}/members", response_model=List[HubMemberResponse])
async def get_hub_members(
    hub_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all members of a hub"""
    cursor = get_collection("hub_members").find({"hub_id": ObjectId(hub_id)})
    
    members = []
    async for member_doc in cursor:
        user_doc = await get_collection("users").find_one({"_id": member_doc["user_id"]})
        members.append({
            "id": str(member_doc["_id"]),
            "user_id": str(member_doc["user_id"]),
            "user_name": user_doc.get("full_name") if user_doc else None,
            "user_avatar": user_doc.get("avatar_url") if user_doc else None,
            "role": member_doc["role"],
            "joined_at": member_doc["joined_at"]
        })
    
    return members

@router.get("/hubs/{hub_id}/memories", response_model=List[dict])
async def get_hub_memories(
    hub_id: str,
    page: int = 1,
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all memories shared to a hub"""
    member = await get_collection("hub_members").find_one({
        "hub_id": ObjectId(hub_id),
        "user_id": ObjectId(current_user.id)
    })
    
    hub_doc = await get_collection("hubs").find_one({"_id": ObjectId(hub_id)})
    if not hub_doc:
        raise HTTPException(status_code=404, detail="Hub not found")
    
    if not member and hub_doc.get("privacy") == "private":
        raise HTTPException(status_code=403, detail="Access denied")
    
    query = {"hub_id": ObjectId(hub_id)}
    skip = (page - 1) * limit
    cursor = get_collection("memories").find(query).sort("created_at", -1).skip(skip).limit(limit)
    
    memories = []
    async for memory_doc in cursor:
        owner_doc = await get_collection("users").find_one({"_id": memory_doc["owner_id"]})
        
        memories.append({
            "id": str(memory_doc["_id"]),
            "title": memory_doc.get("title"),
            "content": memory_doc.get("content"),
            "image_url": memory_doc.get("image_url"),
            "tags": memory_doc.get("tags", []),
            "owner_id": str(memory_doc["owner_id"]),
            "owner_name": owner_doc.get("full_name") if owner_doc else None,
            "owner_avatar": owner_doc.get("avatar_url") if owner_doc else None,
            "like_count": memory_doc.get("like_count", 0),
            "comment_count": memory_doc.get("comment_count", 0),
            "created_at": memory_doc["created_at"].isoformat(),
            "updated_at": memory_doc.get("updated_at", memory_doc["created_at"]).isoformat()
        })
    
    return memories

@router.post("/hubs/{hub_id}/invitations", response_model=HubInvitationResponse)
async def create_invitation(
    hub_id: str,
    invitation: HubInvitationCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create an invitation to join a hub"""
    member = await get_collection("hub_members").find_one({
        "hub_id": ObjectId(hub_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if not member or member["role"] not in [HubRole.OWNER, HubRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    
    invitation_data = invitation.dict()
    invitation_data["status"] = InvitationStatus.PENDING
    invitation_data["created_at"] = datetime.utcnow()
    invitation_data["expires_at"] = datetime.utcnow() + timedelta(days=7)
    
    result = await get_collection("hub_invitations").insert_one(invitation_data)
    
    invitation_doc = await get_collection("hub_invitations").find_one({"_id": result.inserted_id})
    hub_doc = await get_collection("hubs").find_one({"_id": invitation_doc["hub_id"]})
    inviter_doc = await get_collection("users").find_one({"_id": invitation_doc["inviter_id"]})
    
    return {
        "id": str(invitation_doc["_id"]),
        "hub_id": str(invitation_doc["hub_id"]),
        "hub_name": hub_doc["name"] if hub_doc else "",
        "inviter_id": str(invitation_doc["inviter_id"]),
        "inviter_name": inviter_doc.get("full_name") if inviter_doc else None,
        "invitee_email": invitation_doc["invitee_email"],
        "role": invitation_doc["role"],
        "status": invitation_doc["status"],
        "message": invitation_doc.get("message"),
        "created_at": invitation_doc["created_at"],
        "expires_at": invitation_doc["expires_at"]
    }

@router.post("/hubs/{hub_id}/sharing-links", response_model=HubSharingLinkResponse)
async def create_sharing_link(
    hub_id: str,
    link: HubSharingLinkCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a sharing link for a hub"""
    member = await get_collection("hub_members").find_one({
        "hub_id": ObjectId(hub_id),
        "user_id": ObjectId(current_user.id)
    })
    
    if not member or member["role"] not in [HubRole.OWNER, HubRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    
    link_data = link.dict()
    link_data["token"] = secrets.token_urlsafe(32)
    link_data["created_by"] = ObjectId(current_user.id)
    link_data["created_at"] = datetime.utcnow()
    link_data["use_count"] = 0
    
    result = await get_collection("hub_sharing_links").insert_one(link_data)
    
    link_doc = await get_collection("hub_sharing_links").find_one({"_id": result.inserted_id})
    hub_doc = await get_collection("hubs").find_one({"_id": link_doc["hub_id"]})
    
    return {
        "id": str(link_doc["_id"]),
        "hub_id": str(link_doc["hub_id"]),
        "hub_name": hub_doc["name"] if hub_doc else "",
        "token": link_doc["token"],
        "role": link_doc["role"],
        "max_uses": link_doc.get("max_uses"),
        "use_count": link_doc["use_count"],
        "expires_at": link_doc.get("expires_at"),
        "created_at": link_doc["created_at"],
        "share_url": f"/join/{link_doc['token']}"
    }

@router.get("/users/search", response_model=List[dict])
async def search_users(
    query: str = Query(..., min_length=1),
    limit: int = 20,
    current_user: UserInDB = Depends(get_current_user)
):
    """Search for users by name or email"""
    search_query = {
        "$or": [
            {"full_name": {"$regex": query, "$options": "i"}},
            {"email": {"$regex": query, "$options": "i"}}
        ],
        "_id": {"$ne": ObjectId(current_user.id)}
    }
    
    cursor = get_collection("users").find(search_query).limit(limit)
    
    users = []
    async for user_doc in cursor:
        relationship = await get_collection("relationships").find_one({
            "follower_id": ObjectId(current_user.id),
            "following_id": user_doc["_id"]
        })
        
        users.append({
            "id": str(user_doc["_id"]),
            "full_name": user_doc.get("full_name"),
            "email": user_doc["email"],
            "avatar_url": user_doc.get("avatar_url"),
            "bio": user_doc.get("bio"),
            "city": user_doc.get("city"),
            "country": user_doc.get("country"),
            "is_following": relationship is not None and relationship["status"] == RelationshipStatus.ACCEPTED
        })
    
    return users

@router.post("/users/{user_id}/follow")
async def follow_user(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Follow a user"""
    if user_id == str(current_user.id):
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    
    target_user = await get_collection("users").find_one({"_id": ObjectId(user_id)})
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    existing = await get_collection("relationships").find_one({
        "follower_id": ObjectId(current_user.id),
        "following_id": ObjectId(user_id)
    })
    
    if existing:
        raise HTTPException(status_code=400, detail="Already following this user")
    
    relationship_data = {
        "follower_id": ObjectId(current_user.id),
        "following_id": ObjectId(user_id),
        "status": RelationshipStatus.ACCEPTED,
        "created_at": datetime.utcnow()
    }
    
    await get_collection("relationships").insert_one(relationship_data)
    
    return {"message": "Successfully followed user"}

@router.delete("/users/{user_id}/follow")
async def unfollow_user(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Unfollow a user"""
    result = await get_collection("relationships").delete_one({
        "follower_id": ObjectId(current_user.id),
        "following_id": ObjectId(user_id)
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Not following this user")
    
    return {"message": "Successfully unfollowed user"}

@router.get("/users/{user_id}/followers", response_model=List[RelationshipResponse])
async def get_followers(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a user's followers"""
    cursor = get_collection("relationships").find({
        "following_id": ObjectId(user_id),
        "status": RelationshipStatus.ACCEPTED
    })
    
    followers = []
    async for rel_doc in cursor:
        user_doc = await get_collection("users").find_one({"_id": rel_doc["follower_id"]})
        if user_doc:
            followers.append({
                "id": str(rel_doc["_id"]),
                "user_id": str(user_doc["_id"]),
                "user_name": user_doc.get("full_name"),
                "user_avatar": user_doc.get("avatar_url"),
                "user_bio": user_doc.get("bio"),
                "status": rel_doc["status"],
                "created_at": rel_doc["created_at"]
            })
    
    return followers

@router.get("/users/{user_id}/following", response_model=List[RelationshipResponse])
async def get_following(
    user_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get users that a user is following"""
    cursor = get_collection("relationships").find({
        "follower_id": ObjectId(user_id),
        "status": RelationshipStatus.ACCEPTED
    })
    
    following = []
    async for rel_doc in cursor:
        user_doc = await get_collection("users").find_one({"_id": rel_doc["following_id"]})
        if user_doc:
            following.append({
                "id": str(rel_doc["_id"]),
                "user_id": str(user_doc["_id"]),
                "user_name": user_doc.get("full_name"),
                "user_avatar": user_doc.get("avatar_url"),
                "user_bio": user_doc.get("bio"),
                "status": rel_doc["status"],
                "created_at": rel_doc["created_at"]
            })
    
    return following

async def _prepare_hub_response(hub_doc, current_user_id: str):
    """Prepare hub response with additional data"""
    owner_doc = await get_collection("users").find_one({"_id": hub_doc["owner_id"]})
    
    member = await get_collection("hub_members").find_one({
        "hub_id": hub_doc["_id"],
        "user_id": ObjectId(current_user_id)
    })
    
    return {
        "id": str(hub_doc["_id"]),
        "name": hub_doc["name"],
        "description": hub_doc.get("description"),
        "privacy": hub_doc["privacy"],
        "avatar_url": hub_doc.get("avatar_url"),
        "tags": hub_doc.get("tags", []),
        "owner_id": str(hub_doc["owner_id"]),
        "owner_name": owner_doc.get("full_name") if owner_doc else None,
        "member_count": hub_doc.get("member_count", 1),
        "my_role": member["role"] if member else None,
        "created_at": hub_doc["created_at"],
        "updated_at": hub_doc["updated_at"]
    }
