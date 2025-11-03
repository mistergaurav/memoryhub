"""Platform user search for genealogy."""
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



@router.get("/search-users")
async def search_platform_users(
    query: str = Query(..., min_length=2, description="Search query for username, email, or name"),
    limit: int = Query(20, ge=1, le=50, description="Maximum number of results"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Search for any platform user to link to genealogy persons or invite to family hub"""
    users = await user_repo.search_users(
        query=query,
        exclude_user_id=str(current_user.id),
        limit=limit
    )
    
    linked_persons = await genealogy_person_repo.find_many(
        {"family_id": ObjectId(current_user.id), "linked_user_id": {"$exists": True, "$ne": None}},
        limit=1000
    )
    linked_user_ids = {str(person.get("linked_user_id")) for person in linked_persons if person.get("linked_user_id")}
    
    results = []
    for user_doc in users:
        user_id = str(user_doc["_id"])
        results.append({
            "id": user_id,
            "username": user_doc.get("username", ""),
            "email": user_doc.get("email", ""),
            "full_name": user_doc.get("full_name"),
            "profile_photo": user_doc.get("profile_photo"),
            "already_linked": user_id in linked_user_ids
        })
    
    return create_success_response(
        message="Users found successfully",
        data=results
    )


