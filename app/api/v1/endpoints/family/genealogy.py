from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime, timedelta
import secrets

from app.models.family.genealogy import (
    GenealogyPersonCreate, GenealogyPersonUpdate, GenealogyPersonResponse,
    GenealogyRelationshipCreate, GenealogyRelationshipResponse,
    FamilyTreeNode, PersonSource, UserSearchResult,
    FamilyHubInvitationCreate, FamilyHubInvitationResponse, InvitationAction, InvitationStatus
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database
from app.utils.genealogy_helpers import safe_object_id, compute_is_alive
from app.repositories.family_repository import (
    GenealogyPersonRepository,
    GenealogyRelationshipRepository,
    GenealogyTreeRepository,
    GenealogTreeMembershipRepository,
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


def person_doc_to_response(person_doc: dict) -> GenealogyPersonResponse:
    """Convert MongoDB person document to response model"""
    return GenealogyPersonResponse(
        id=str(person_doc["_id"]),
        family_id=str(person_doc["family_id"]),
        first_name=person_doc["first_name"],
        last_name=person_doc["last_name"],
        maiden_name=person_doc.get("maiden_name"),
        gender=person_doc["gender"],
        birth_date=person_doc.get("birth_date"),
        birth_place=person_doc.get("birth_place"),
        death_date=person_doc.get("death_date"),
        death_place=person_doc.get("death_place"),
        is_alive=person_doc.get("is_alive", True),
        biography=person_doc.get("biography"),
        photo_url=person_doc.get("photo_url"),
        occupation=person_doc.get("occupation"),
        notes=person_doc.get("notes"),
        linked_user_id=str(person_doc["linked_user_id"]) if person_doc.get("linked_user_id") else None,
        source=person_doc.get("source", PersonSource.MANUAL),
        created_at=person_doc["created_at"],
        updated_at=person_doc["updated_at"],
        created_by=str(person_doc["created_by"])
    )


def relationship_doc_to_response(relationship_doc: dict) -> GenealogyRelationshipResponse:
    """Convert MongoDB relationship document to response model"""
    return GenealogyRelationshipResponse(
        id=str(relationship_doc["_id"]),
        family_id=str(relationship_doc["family_id"]),
        person1_id=str(relationship_doc["person1_id"]),
        person2_id=str(relationship_doc["person2_id"]),
        relationship_type=relationship_doc["relationship_type"],
        notes=relationship_doc.get("notes"),
        created_at=relationship_doc["created_at"],
        created_by=str(relationship_doc["created_by"])
    )


async def get_tree_membership(tree_id: ObjectId, user_id: ObjectId):
    """Get user's membership in a family tree (returns None if not a member)"""
    return await tree_membership_repo.find_by_tree_and_user(
        tree_id=str(tree_id),
        user_id=str(user_id)
    )


async def ensure_tree_access(tree_id: ObjectId, user_id: ObjectId, required_roles: Optional[List[str]] = None):
    """
    Verify user has access to a tree with required role(s).
    If tree is user's own tree and no membership exists, auto-create owner membership.
    Raises HTTPException if access denied.
    """
    membership = await get_tree_membership(tree_id, user_id)
    
    if str(tree_id) == str(user_id) and not membership:
        membership = await tree_membership_repo.create_membership(
            tree_id=str(tree_id),
            user_id=str(user_id),
            role="owner",
            granted_by=str(user_id)
        )
    
    if not membership:
        raise HTTPException(status_code=403, detail="You do not have access to this family tree")
    
    if required_roles and membership["role"] not in required_roles:
        raise HTTPException(
            status_code=403,
            detail=f"Access denied. Required role: {'/'.join(required_roles)}, your role: {membership['role']}"
        )
    
    return membership


async def validate_user_exists(user_id: str) -> Dict[str, Any]:
    """Validate that a user exists, raise 404 if not"""
    user_oid = user_repo.validate_object_id(user_id, "user_id")
    user_doc = await user_repo.find_one(
        {"_id": user_oid},
        raise_404=True,
        error_message="User not found"
    )
    return user_doc


async def get_user_display_name(user_doc: Dict[str, Any]) -> str:
    """Get display name from user document"""
    return user_doc.get("username") or user_doc.get("full_name") or user_doc.get("email", "Unknown")


@router.post("/persons", status_code=status.HTTP_201_CREATED)
async def create_genealogy_person(
    person: GenealogyPersonCreate,
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new genealogy person with optional relationships"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id), required_roles=["owner", "member"])
    
    linked_user_oid = None
    
    if person.linked_user_id:
        linked_user_oid = genealogy_person_repo.validate_object_id(person.linked_user_id, "linked_user_id")
        
        await validate_user_exists(person.linked_user_id)
        
        existing_link = await genealogy_person_repo.find_one(
            {"linked_user_id": linked_user_oid},
            raise_404=False
        )
        if existing_link:
            raise HTTPException(
                status_code=400, 
                detail="This user is already linked to another genealogy person"
            )
        
        if person.source != PersonSource.PLATFORM_USER:
            person.source = PersonSource.PLATFORM_USER
    
    is_alive = compute_is_alive(person.death_date, person.is_alive)
    
    person_data = {
        "family_id": tree_oid,
        "first_name": person.first_name,
        "last_name": person.last_name,
        "maiden_name": person.maiden_name,
        "gender": person.gender,
        "birth_date": person.birth_date,
        "birth_place": person.birth_place,
        "death_date": person.death_date,
        "death_place": person.death_place,
        "is_alive": is_alive,
        "biography": person.biography,
        "photo_url": person.photo_url,
        "occupation": person.occupation,
        "notes": person.notes,
        "source": person.source,
        "created_by": ObjectId(current_user.id)
    }
    
    if linked_user_oid:
        person_data["linked_user_id"] = linked_user_oid
    
    person_doc = await genealogy_person_repo.create(person_data)
    person_id = person_doc["_id"]
    
    if person.relationships:
        for rel_spec in person.relationships:
            related_person_oid = genealogy_person_repo.validate_object_id(rel_spec.person_id, "related_person_id")
            
            related_person = await genealogy_person_repo.find_one(
                {"_id": related_person_oid},
                raise_404=True,
                error_message=f"Related person not found: {rel_spec.person_id}"
            )
            
            if str(related_person["family_id"]) != str(tree_oid):
                raise HTTPException(
                    status_code=403, 
                    detail="Cannot create relationship with person from a different family tree"
                )
            
            relationship_data = {
                "family_id": tree_oid,
                "person1_id": person_id,
                "person2_id": related_person_oid,
                "relationship_type": rel_spec.relationship_type,
                "notes": rel_spec.notes,
                "created_by": ObjectId(current_user.id)
            }
            await genealogy_relationship_repo.create(relationship_data)
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="CREATE_GENEALOGY_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": str(person_id),
            "tree_id": str(tree_oid),
            "first_name": person.first_name,
            "last_name": person.last_name
        }
    )
    
    return create_success_response(
        message="Person created successfully",
        data=person_doc_to_response(person_doc)
    )


@router.get("/persons")
async def list_genealogy_persons(
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all persons in family tree with pagination"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id))
    
    skip = (page - 1) * page_size
    persons = await genealogy_person_repo.find_by_tree(
        tree_id=str(tree_oid),
        skip=skip,
        limit=page_size
    )
    
    total = await genealogy_person_repo.count({"family_id": tree_oid})
    
    person_responses = [person_doc_to_response(doc) for doc in persons]
    
    return create_paginated_response(
        items=person_responses,
        total=total,
        page=page,
        page_size=page_size,
        message="Persons retrieved successfully"
    )


@router.get("/persons/{person_id}")
async def get_genealogy_person(
    person_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific person"""
    person_doc = await genealogy_person_repo.find_by_id(
        person_id,
        raise_404=True,
        error_message="Person not found"
    )
    
    await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id))
    
    return create_success_response(
        message="Person retrieved successfully",
        data=person_doc_to_response(person_doc)
    )


@router.put("/persons/{person_id}")
async def update_genealogy_person(
    person_id: str,
    person_update: GenealogyPersonUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a person"""
    person_doc = await genealogy_person_repo.find_by_id(
        person_id,
        raise_404=True,
        error_message="Person not found"
    )
    
    await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id), required_roles=["owner", "member"])
    
    person_update_dict = person_update.dict(exclude_unset=True)
    update_data = {k: v for k, v in person_update_dict.items() if v is not None}
    unset_data = {}
    
    if "linked_user_id" in person_update_dict:
        if person_update.linked_user_id is None or person_update.linked_user_id == "":
            unset_data["linked_user_id"] = ""
            update_data.pop("linked_user_id", None)
        else:
            linked_user_oid = genealogy_person_repo.validate_object_id(person_update.linked_user_id, "linked_user_id")
            
            await validate_user_exists(person_update.linked_user_id)
            
            existing_link = await genealogy_person_repo.find_one({
                "linked_user_id": linked_user_oid,
                "_id": {"$ne": ObjectId(person_id)}
            }, raise_404=False)
            
            if existing_link:
                raise HTTPException(
                    status_code=400, 
                    detail="This user is already linked to another genealogy person"
                )
            update_data["linked_user_id"] = linked_user_oid
    
    if "death_date" in update_data or "is_alive" in update_data:
        death_date = update_data.get("death_date", person_doc.get("death_date"))
        is_alive_override = update_data.get("is_alive")
        update_data["is_alive"] = compute_is_alive(death_date, is_alive_override)
    
    updated_person = await genealogy_person_repo.update_by_id(person_id, update_data)
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="UPDATE_GENEALOGY_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": person_id,
            "updates": list(update_data.keys())
        }
    )
    
    return create_success_response(
        message="Person updated successfully",
        data=person_doc_to_response(updated_person)
    )


@router.delete("/persons/{person_id}", status_code=status.HTTP_200_OK)
async def delete_genealogy_person(
    person_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a person"""
    person_doc = await genealogy_person_repo.find_by_id(
        person_id,
        raise_404=True,
        error_message="Person not found"
    )
    
    await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id), required_roles=["owner"])
    
    await genealogy_person_repo.delete_by_id(person_id)
    
    await genealogy_relationship_repo.collection.delete_many({
        "$or": [
            {"person1_id": ObjectId(person_id)},
            {"person2_id": ObjectId(person_id)}
        ]
    })
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="DELETE_GENEALOGY_PERSON",
        event_details={
            "resource_type": "genealogy_person",
            "resource_id": person_id,
            "first_name": person_doc.get("first_name"),
            "last_name": person_doc.get("last_name")
        }
    )
    
    return create_success_response(message="Person deleted successfully")


@router.get("/search-users")
async def search_platform_users(
    query: str = Query(..., min_length=2, description="Search query for username, email, or name"),
    limit: int = Query(20, ge=1, le=50, description="Maximum number of results"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Search for any platform user to link to genealogy persons or invite to family hub"""
    users = await user_repo.search_users(
        query=query,
        exclude_user_id=current_user.id,
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


@router.post("/relationships", status_code=status.HTTP_201_CREATED)
async def create_genealogy_relationship(
    relationship: GenealogyRelationshipCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create relationship between two persons"""
    person1_oid = genealogy_person_repo.validate_object_id(relationship.person1_id, "person1_id")
    person2_oid = genealogy_person_repo.validate_object_id(relationship.person2_id, "person2_id")
    
    person1 = await genealogy_person_repo.find_one(
        {"_id": person1_oid},
        raise_404=True,
        error_message="Person 1 not found"
    )
    person2 = await genealogy_person_repo.find_one(
        {"_id": person2_oid},
        raise_404=True,
        error_message="Person 2 not found"
    )
    
    if str(person1["family_id"]) != str(person2["family_id"]):
        raise HTTPException(status_code=400, detail="Cannot create relationship between persons from different trees")
    
    tree_id = person1["family_id"]
    
    await ensure_tree_access(tree_id, ObjectId(current_user.id), required_roles=["owner", "member"])
    
    relationship_data = {
        "family_id": tree_id,
        "person1_id": person1_oid,
        "person2_id": person2_oid,
        "relationship_type": relationship.relationship_type,
        "notes": relationship.notes,
        "created_by": ObjectId(current_user.id)
    }
    
    relationship_doc = await genealogy_relationship_repo.create(relationship_data)
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="CREATE_GENEALOGY_RELATIONSHIP",
        event_details={
            "resource_type": "genealogy_relationship",
            "resource_id": str(relationship_doc["_id"]),
            "relationship_type": relationship.relationship_type,
            "person1_id": relationship.person1_id,
            "person2_id": relationship.person2_id
        }
    )
    
    return create_success_response(
        message="Relationship created successfully",
        data=relationship_doc_to_response(relationship_doc)
    )


@router.get("/relationships")
async def list_genealogy_relationships(
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all relationships in a family tree with pagination"""
    tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
    if not tree_oid:
        raise HTTPException(status_code=400, detail="Invalid tree_id")
    
    await ensure_tree_access(tree_oid, ObjectId(current_user.id))
    
    skip = (page - 1) * page_size
    relationships = await genealogy_relationship_repo.find_by_tree(
        tree_id=str(tree_oid),
        skip=skip,
        limit=page_size
    )
    
    total = await genealogy_relationship_repo.count({"family_id": tree_oid})
    
    relationship_responses = [relationship_doc_to_response(doc) for doc in relationships]
    
    return create_paginated_response(
        items=relationship_responses,
        total=total,
        page=page,
        page_size=page_size,
        message="Relationships retrieved successfully"
    )


@router.delete("/relationships/{relationship_id}", status_code=status.HTTP_200_OK)
async def delete_genealogy_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a relationship"""
    relationship_doc = await genealogy_relationship_repo.find_by_id(
        relationship_id,
        raise_404=True,
        error_message="Relationship not found"
    )
    
    tree_id = relationship_doc["family_id"]
    
    await ensure_tree_access(tree_id, ObjectId(current_user.id), required_roles=["owner", "member"])
    
    await genealogy_relationship_repo.delete_by_id(relationship_id)
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="DELETE_GENEALOGY_RELATIONSHIP",
        event_details={
            "resource_type": "genealogy_relationship",
            "resource_id": relationship_id,
            "relationship_type": relationship_doc.get("relationship_type")
        }
    )
    
    return create_success_response(message="Relationship deleted successfully")


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
        granted_by=current_user.id
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
        user_id=current_user.id,
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


@router.post("/invite-links", status_code=status.HTTP_201_CREATED)
async def create_invite_link(
    person_id: str = Query(..., description="Genealogy person ID to link invitation to"),
    email: Optional[str] = Query(None, description="Email to send invitation to"),
    message: Optional[str] = Query(None, description="Personal message"),
    expires_in_days: int = Query(30, ge=1, le=365, description="Expiry in days"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create an invitation link for a living family member to join the platform"""
    person_oid = safe_object_id(person_id)
    if not person_oid:
        raise HTTPException(status_code=400, detail="Invalid person_id")
    
    person_doc = await genealogy_person_repo.find_one(
        {"_id": person_oid},
        raise_404=True,
        error_message="Person not found"
    )
    
    if str(person_doc["family_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to invite for this person")
    
    if not person_doc.get("is_alive", True):
        raise HTTPException(status_code=400, detail="Cannot send invitation for deceased person")
    
    if person_doc.get("linked_user_id"):
        raise HTTPException(status_code=400, detail="Person is already linked to a platform user")
    
    existing_invite = await invite_links_repo.find_active_by_person(person_id)
    
    if existing_invite:
        raise HTTPException(status_code=400, detail="An active invitation already exists for this person")
    
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(days=expires_in_days)
    
    invite_data = {
        "family_id": ObjectId(current_user.id),
        "person_id": person_oid,
        "token": token,
        "email": email,
        "message": message,
        "status": "pending",
        "created_by": ObjectId(current_user.id),
        "created_at": datetime.utcnow(),
        "expires_at": expires_at,
        "accepted_at": None,
        "accepted_by": None
    }
    
    invite_doc = await invite_links_repo.create(invite_data)
    
    await genealogy_person_repo.collection.update_one(
        {"_id": person_oid},
        {
            "$set": {
                "pending_invite_email": email,
                "invite_token": token,
                "invitation_sent_at": datetime.utcnow(),
                "invitation_expires_at": expires_at,
                "updated_at": datetime.utcnow()
            }
        }
    )
    
    person_name = f"{person_doc['first_name']} {person_doc['last_name']}"
    invite_url = f"/genealogy/join/{token}"
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="CREATE_INVITE_LINK",
        event_details={
            "resource_type": "genealogy_invite",
            "resource_id": str(invite_doc["_id"]),
            "person_id": person_id,
            "email": email
        }
    )
    
    return create_success_response(
        message="Invitation link created successfully",
        data={
            "id": str(invite_doc["_id"]),
            "family_id": str(current_user.id),
            "person_id": str(person_oid),
            "person_name": person_name,
            "token": token,
            "email": email,
            "message": message,
            "status": "pending",
            "invite_url": invite_url,
            "created_by": str(current_user.id),
            "created_at": invite_data["created_at"],
            "expires_at": expires_at
        }
    )


@router.post("/join/{token}", status_code=status.HTTP_200_OK)
async def redeem_invite_link(
    token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Redeem an invitation link and link user to genealogy person"""
    invite_doc = await invite_links_repo.find_by_token(token, raise_404=True)
    
    if invite_doc["expires_at"] < datetime.utcnow():
        await invite_links_repo.update_by_id(
            str(invite_doc["_id"]),
            {"status": "expired"}
        )
        raise HTTPException(status_code=400, detail="Invitation has expired")
    
    if invite_doc["status"] != "pending":
        raise HTTPException(status_code=400, detail=f"Invitation has already been {invite_doc['status']}")
    
    person_doc = await genealogy_person_repo.find_one(
        {"_id": invite_doc["person_id"]},
        raise_404=True,
        error_message="Person not found"
    )
    
    if person_doc.get("linked_user_id"):
        raise HTTPException(status_code=400, detail="This person is already linked to another user")
    
    db = get_database()
    async with await db.client.start_session() as session:
        async with session.start_transaction():
            await genealogy_person_repo.collection.update_one(
                {"_id": invite_doc["person_id"]},
                {
                    "$set": {
                        "linked_user_id": ObjectId(current_user.id),
                        "source": "platform_user",
                        "is_alive": True,
                        "updated_at": datetime.utcnow()
                    },
                    "$unset": {
                        "pending_invite_email": "",
                        "invite_token": ""
                    }
                },
                session=session
            )
            
            await invite_links_repo.collection.update_one(
                {"_id": invite_doc["_id"]},
                {
                    "$set": {
                        "status": "accepted",
                        "accepted_at": datetime.utcnow(),
                        "accepted_by": ObjectId(current_user.id)
                    }
                },
                session=session
            )
            
            membership_exists = await tree_membership_repo.find_by_tree_and_user(
                tree_id=str(invite_doc["family_id"]),
                user_id=current_user.id
            )
            
            if not membership_exists:
                await tree_membership_repo.create_membership(
                    tree_id=str(invite_doc["family_id"]),
                    user_id=current_user.id,
                    role="member",
                    granted_by=str(invite_doc["created_by"])
                )
    
    joiner_name = await get_user_display_name(
        {"username": getattr(current_user, 'username', None),
         "full_name": current_user.full_name,
         "email": current_user.email}
    )
    
    await notification_repo.create_notification(
        user_id=str(invite_doc["family_id"]),
        notification_type="invitation_accepted",
        title="Family Tree Invitation Accepted",
        message=f"{joiner_name} joined your family tree",
        related_id=str(invite_doc["person_id"])
    )
    
    tree_circle = await family_repo.find_one({
        "owner_id": invite_doc["family_id"],
        "name": "Family Tree Members"
    }, raise_404=False)
    
    if tree_circle:
        if ObjectId(current_user.id) not in tree_circle.get("member_ids", []):
            await family_repo.collection.update_one(
                {"_id": tree_circle["_id"]},
                {
                    "$addToSet": {"member_ids": ObjectId(current_user.id)},
                    "$set": {"updated_at": datetime.utcnow()}
                }
            )
    else:
        circle_data = {
            "name": "Family Tree Members",
            "description": "Members who have access to the family genealogy tree",
            "circle_type": "extended_family",
            "owner_id": invite_doc["family_id"],
            "member_ids": [invite_doc["family_id"], ObjectId(current_user.id)],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        await family_repo.create(circle_data)
    
    await log_audit_event(
        user_id=current_user.id,
        event_type="REDEEM_INVITE_LINK",
        event_details={
            "resource_type": "genealogy_invite",
            "resource_id": str(invite_doc["_id"]),
            "person_id": str(invite_doc["person_id"]),
            "tree_id": str(invite_doc["family_id"])
        }
    )
    
    return create_success_response(
        message="Successfully joined family tree",
        data={
            "person_id": str(invite_doc["person_id"]),
            "tree_id": str(invite_doc["family_id"])
        }
    )


@router.get("/invite-links")
async def list_invite_links(
    status_filter: Optional[str] = Query(None, description="Filter by status"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all invitation links created by current user"""
    invites = await invite_links_repo.find_by_family(
        family_id=current_user.id,
        status_filter=status_filter,
        limit=100
    )
    
    invite_responses = []
    for invite_doc in invites:
        person_doc = await genealogy_person_repo.find_one({"_id": invite_doc["person_id"]}, raise_404=False)
        person_name = f"{person_doc['first_name']} {person_doc['last_name']}" if person_doc else "Unknown"
        
        invite_data = {
            "id": str(invite_doc["_id"]),
            "family_id": str(invite_doc["family_id"]),
            "person_id": str(invite_doc["person_id"]),
            "person_name": person_name,
            "token": invite_doc["token"],
            "email": invite_doc.get("email"),
            "message": invite_doc.get("message"),
            "status": invite_doc["status"],
            "invite_url": f"/genealogy/join/{invite_doc['token']}",
            "created_by": str(invite_doc["created_by"]),
            "created_at": invite_doc["created_at"],
            "expires_at": invite_doc["expires_at"],
            "accepted_at": invite_doc.get("accepted_at"),
            "accepted_by": str(invite_doc["accepted_by"]) if invite_doc.get("accepted_by") else None
        }
        invite_responses.append(invite_data)
    
    return create_success_response(
        message="Invite links retrieved successfully",
        data=invite_responses
    )


@router.get("/persons/{person_id}/timeline")
async def get_person_timeline(
    person_id: str,
    skip: int = Query(0, ge=0, description="Skip N memories"),
    limit: int = Query(20, ge=1, le=100, description="Limit results"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get timeline of all memories associated with this genealogy person"""
    person_oid = safe_object_id(person_id)
    if not person_oid:
        raise HTTPException(status_code=400, detail="Invalid person_id")
    
    person_doc = await genealogy_person_repo.find_one(
        {"_id": person_oid},
        raise_404=True,
        error_message="Person not found"
    )
    
    tree_id = person_doc["family_id"]
    membership = await tree_membership_repo.find_by_tree_and_user(
        tree_id=str(tree_id),
        user_id=current_user.id
    )
    
    if not membership and str(tree_id) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this person's timeline")
    
    memories = await memory_repo.find_by_genealogy_person(
        person_id=str(person_oid),
        skip=skip,
        limit=limit
    )
    
    owner_ids = list({str(m["owner_id"]) for m in memories})
    owner_names = await user_repo.get_user_names(owner_ids) if owner_ids else {}
    
    memory_responses = []
    for memory_doc in memories:
        owner_id = str(memory_doc["owner_id"])
        owner_doc = await user_repo.find_one({"_id": memory_doc["owner_id"]}, raise_404=False)
        
        memory_data = {
            "id": str(memory_doc["_id"]),
            "title": memory_doc.get("title", ""),
            "content": memory_doc.get("content", ""),
            "media_urls": memory_doc.get("media_urls", []),
            "tags": memory_doc.get("tags", []),
            "created_at": memory_doc["created_at"],
            "owner_id": owner_id,
            "owner_username": owner_doc.get("username", "") if owner_doc else "",
            "owner_full_name": owner_doc.get("full_name") if owner_doc else None,
            "like_count": memory_doc.get("like_count", 0),
            "comment_count": memory_doc.get("comment_count", 0)
        }
        memory_responses.append(memory_data)
    
    return create_success_response(
        message="Person timeline retrieved successfully",
        data=memory_responses
    )

@router.post("/generate-invite-link", status_code=status.HTTP_200_OK)
async def generate_invite_link(
    current_user: UserInDB = Depends(get_current_user)
):
    """Generate a unique invite link"""
    token = secrets.token_urlsafe(32)
    # You would typically store this token in the database with an expiry date
    # and associate it with the user who generated it.
    # For this example, we'll just return the link.
    invite_link = f"/genealogy/join/{token}"
    return create_success_response(
        message="Invite link generated successfully",
        data={"invite_link": invite_link}
    )
