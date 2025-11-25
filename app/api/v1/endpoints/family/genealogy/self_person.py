"""Self-person creation endpoint for genealogy tree initialization."""
from fastapi import APIRouter, Depends, HTTPException, status
from bson import ObjectId
from datetime import datetime

from app.models.user import UserInDB
from app.core.security import get_current_user
from app.api.v1.endpoints.family.genealogy.schemas import GenealogyPersonResponse
from app.api.v1.endpoints.family.genealogy.repository import (
    GenealogyPersonRepository,
    GenealogTreeMembershipRepository
)
from app.api.v1.endpoints.family.genealogy.utils import person_doc_to_response
from app.models.responses import create_success_response
from app.utils.audit_logger import log_audit_event

router = APIRouter()

genealogy_person_repo = GenealogyPersonRepository()
tree_membership_repo = GenealogTreeMembershipRepository()


@router.post("/persons/self", status_code=status.HTTP_201_CREATED)
async def create_self_person(
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a genealogy person record for the current user.
    This is typically the first person added to a user's family tree.
    """
    user_oid = ObjectId(current_user.id)
    
    # Check if user already has a self-person
    existing_self = await genealogy_person_repo.find_one(
        {
            "family_id": user_oid,
            "linked_user_id": user_oid
        },
        raise_404=False
    )
    
    if existing_self:
        raise HTTPException(
            status_code=400,
            detail="You already have a person record in your family tree"
        )
    
    # Extract name from user's full_name or email
    full_name = current_user.full_name or current_user.email.split('@')[0]
    name_parts = full_name.split(' ', 1)
    first_name = name_parts[0]
    last_name = name_parts[1] if len(name_parts) > 1 else ""
    
    # Create person data
    person_data = {
        "family_id": user_oid,
        "first_name": first_name,
        "last_name": last_name,
        "gender": "unknown",  # User can update later
        "is_alive": True,
        "linked_user_id": user_oid,
        "source": "platform_user",
        "approval_status": "approved",  # Self-person is auto-approved
        "created_by": user_oid,
        "biography": f"This is my profile in the family tree.",
        "photo_url": getattr(current_user, 'avatar_url', None)
    }
    
    person_doc = await genealogy_person_repo.create(person_data)
    person_id = person_doc["_id"]
    
    # Create owner membership
    owner_membership = await tree_membership_repo.find_by_tree_and_user(
        tree_id=str(user_oid),
        user_id=str(current_user.id)
    )
    
    if not owner_membership:
        await tree_membership_repo.create_membership(
            tree_id=str(user_oid),
            user_id=str(current_user.id),
            role="owner",
            granted_by=str(current_user.id)
        )
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_SELF_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": str(person_id),
            "tree_id": str(user_oid)
        }
    )
    
    return create_success_response(
        message="Your profile has been created in the family tree",
        data=person_doc_to_response(person_doc)
    )
