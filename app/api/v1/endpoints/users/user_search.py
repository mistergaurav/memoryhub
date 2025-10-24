from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.family_repository import FamilyMembersRepository, FamilyRepository
from app.models.responses import create_success_response
from app.utils.audit_logger import log_audit_event

router = APIRouter()

family_members_repo = FamilyMembersRepository()
family_repo = FamilyRepository()


def format_family_member(member_doc: dict) -> dict:
    """Format family member document for API response"""
    return {
        "id": str(member_doc["_id"]),
        "name": member_doc.get("name", ""),
        "relationship": member_doc.get("relationship"),
        "avatar_url": member_doc.get("avatar_url"),
        "type": "family_member"
    }


def format_circle_member(user_doc: dict) -> dict:
    """Format circle member (user) document for API response"""
    return {
        "id": str(user_doc["_id"]),
        "name": user_doc.get("full_name", ""),
        "username": user_doc.get("username"),
        "avatar_url": user_doc.get("avatar_url"),
        "type": "circle_member"
    }


@router.get("/search-family-circle")
async def search_family_circle_members(
    query: str = Query(..., min_length=1, description="Search query string"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results per category"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Search for family members and circle members by name.
    
    - Searches family members in user's family (case-insensitive by name)
    - Searches circle members across all circles where user is owner or member
    - Returns deduplicated results sorted by relevance (exact matches first)
    - Logs search operation for audit trail
    
    **Query Parameters:**
    - query: Search string (min 1 character)
    - limit: Max results per category (1-50, default 10)
    
    **Returns:**
    - family_members: List of matching family members
    - circle_members: List of matching circle members (users)
    """
    try:
        family_members = await family_members_repo.search_by_name(
            family_id=str(current_user.id),
            query=query,
            limit=limit
        )
        
        circle_members = await family_repo.search_circle_members(
            user_id=str(current_user.id),
            query=query,
            limit=limit
        )
        
        seen_ids = set()
        unique_circle_members = []
        
        for member in circle_members:
            member_id = str(member["_id"])
            if member_id not in seen_ids:
                seen_ids.add(member_id)
                unique_circle_members.append(member)
        
        formatted_family_members = [format_family_member(m) for m in family_members]
        formatted_circle_members = [format_circle_member(m) for m in unique_circle_members]
        
        await log_audit_event(
            user_id=str(current_user.id),
            event_type="user_search",
            event_details={
                "query": query,
                "family_members_found": len(formatted_family_members),
                "circle_members_found": len(formatted_circle_members),
                "total_results": len(formatted_family_members) + len(formatted_circle_members)
            }
        )
        
        return create_success_response(
            data={
                "family_members": formatted_family_members,
                "circle_members": formatted_circle_members
            },
            message=f"Found {len(formatted_family_members)} family members and {len(formatted_circle_members)} circle members"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error searching for members: {str(e)}"
        )
