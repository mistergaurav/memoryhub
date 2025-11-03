"""Family tree building and retrieval."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime, timedelta
import secrets

from .schemas import (
    GenealogyPersonCreate, GenealogyPersonUpdate, GenealogyPersonResponse,
    GenealogyRelationshipCreate, GenealogyRelationshipResponse,
    FamilyTreeNode, PersonSource, UserSearchResult,
    FamilyHubInvitationCreate, FamilyHubInvitationResponse, InvitationAction, InvitationStatus
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database
from app.utils.genealogy_helpers import safe_object_id, compute_is_alive
from .repository import (
    GenealogyPersonRepository,
    GenealogyRelationshipRepository,
    GenealogyTreeRepository,
    GenealogTreeMembershipRepository
)
from app.repositories.family_repository import (
    UserRepository,
    NotificationRepository,
    GenealogyInviteLinksRepository,
    MemoryRepository,
    FamilyRepository
)
from app.models.responses import create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event

router = APIRouter()

genealogy_person_repo = GenealogyPersonRepository()
genealogy_relationship_repo = GenealogyRelationshipRepository()
genealogy_tree_repo = GenealogyTreeRepository()
tree_membership_repo = GenealogTreeMembershipRepository()
user_repo = UserRepository()
notification_repo = NotificationRepository()
invite_links_repo = GenealogyInviteLinksRepository()
memory_repo = MemoryRepository()
family_repo = FamilyRepository()


from .utils import person_doc_to_response, relationship_doc_to_response, get_user_display_name, validate_user_exists
from .permissions import get_tree_membership, ensure_tree_access

@router.get("/tree")
async def get_family_tree(
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get complete family tree structure"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id))
    
    persons = await genealogy_person_repo.find_by_tree(tree_id=str(tree_oid), limit=1000)
    relationships = await genealogy_relationship_repo.find_by_tree(tree_id=str(tree_oid), limit=1000)
    
    persons_dict = {}
    for person_doc in persons:
        person_response = person_doc_to_response(person_doc)
        persons_dict[person_response.id] = {
            "person": person_response,
            "parents": [],
            "children": [],
            "spouses": [],
            "siblings": []
        }
    
    for rel_doc in relationships:
        rel = relationship_doc_to_response(rel_doc)
        p1_id, p2_id = rel.person1_id, rel.person2_id
        rel_type = rel.relationship_type.lower()
        
        if rel_type == "parent":
            if p1_id in persons_dict and p2_id in persons_dict:
                persons_dict[p2_id]["parents"].append(persons_dict[p1_id]["person"])
                persons_dict[p1_id]["children"].append(persons_dict[p2_id]["person"])
        elif rel_type == "child":
            if p1_id in persons_dict and p2_id in persons_dict:
                persons_dict[p1_id]["parents"].append(persons_dict[p2_id]["person"])
                persons_dict[p2_id]["children"].append(persons_dict[p1_id]["person"])
        elif rel_type == "spouse":
            if p1_id in persons_dict and p2_id in persons_dict:
                persons_dict[p1_id]["spouses"].append(persons_dict[p2_id]["person"])
                persons_dict[p2_id]["spouses"].append(persons_dict[p1_id]["person"])
        elif rel_type == "sibling":
            if p1_id in persons_dict and p2_id in persons_dict:
                persons_dict[p1_id]["siblings"].append(persons_dict[p2_id]["person"])
                persons_dict[p2_id]["siblings"].append(persons_dict[p1_id]["person"])
    
    tree_nodes = [
        FamilyTreeNode(
            person=node["person"],
            parents=node["parents"],
            children=node["children"],
            spouses=node["spouses"],
            siblings=node["siblings"]
        )
        for node in persons_dict.values()
    ]
    
    return create_success_response(
        message="Family tree retrieved successfully",
        data=tree_nodes
    )


@router.get("/tree/members")
async def get_tree_members(
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all members (users) who have access to this tree"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id))
    
    memberships = await tree_membership_repo.find_by_tree(tree_id=str(tree_oid), limit=100)
    
    user_ids = [str(m["user_id"]) for m in memberships]
    user_names = await user_repo.get_user_names(user_ids) if user_ids else {}
    
    members = []
    for membership in memberships:
        user_id = str(membership["user_id"])
        user_doc = await user_repo.find_one({"_id": membership["user_id"]}, raise_404=False)
        
        if user_doc:
            members.append({
                "user_id": user_id,
                "username": user_doc.get("username", ""),
                "full_name": user_doc.get("full_name"),
                "profile_photo": user_doc.get("profile_photo"),
                "role": membership["role"],
                "joined_at": membership["joined_at"]
            })
    
    return create_success_response(
        message="Tree members retrieved successfully",
        data=members
    )


@router.post("/tree/grant-access", status_code=status.HTTP_200_OK)
async def grant_tree_access(
    user_id: str = Query(..., description="User ID to grant access to"),
    role: str = Query("viewer", description="Role to grant (owner, member, viewer)"),
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to your own tree)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Grant access to family tree (owner only)"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id), required_roles=["owner"])
    
    if role not in ["owner", "member", "viewer"]:
        raise HTTPException(status_code=400, detail="Invalid role. Must be one of: owner, member, viewer")
    
    target_user_oid = safe_object_id(user_id)
    if not target_user_oid:
        raise HTTPException(status_code=400, detail="Invalid user_id")
    
    user_doc = await validate_user_exists(user_id)
    
    existing = await tree_membership_repo.find_by_tree_and_user(
        tree_id=str(tree_oid),
        user_id=user_id
    )
    if existing:
        raise HTTPException(status_code=400, detail="User already has access to this tree")
    
    membership = await tree_membership_repo.create_membership(
        tree_id=str(tree_oid),
        user_id=user_id,
        role=role,
        granted_by=str(current_user.id)
    )
    
    granter_name = await get_user_display_name(
        {"username": getattr(current_user, 'username', None),
         "full_name": current_user.full_name,
         "email": current_user.email}
    )
    
    await notification_repo.create_notification(
        user_id=user_id,
        notification_type="tree_access_granted",
        title="Family Tree Access Granted",
        message=f"{granter_name} granted you {role} access to their family tree",
        related_id=str(membership["_id"])
    )
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="GRANT_TREE_ACCESS",
        event_details={
            "resource_type": "genealogy_tree",
            "resource_id": str(tree_oid),
            "granted_to": user_id,
            "role": role
        }
    )
    
    return create_success_response(
        message="Tree access granted successfully",
        data={"membership_id": str(membership["_id"])}
    )


