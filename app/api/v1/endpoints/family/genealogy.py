from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.family.genealogy import (
    GenealogyPersonCreate, GenealogyPersonUpdate, GenealogyPersonResponse,
    GenealogyRelationshipCreate, GenealogyRelationshipResponse,
    FamilyTreeNode, PersonSource, UserSearchResult,
    FamilyHubInvitationCreate, FamilyHubInvitationResponse, InvitationAction, InvitationStatus
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection, get_database
from app.utils.genealogy_helpers import safe_object_id, compute_is_alive, validate_object_id

router = APIRouter()


async def get_tree_membership(tree_id: ObjectId, user_id: ObjectId):
    """Get user's membership in a family tree (returns None if not a member)"""
    return await get_collection("genealogy_tree_memberships").find_one({
        "tree_id": tree_id,
        "user_id": user_id
    })


async def ensure_tree_access(tree_id: ObjectId, user_id: ObjectId, required_roles: List[str] = None):
    """
    Verify user has access to a tree with required role(s).
    If tree is user's own tree and no membership exists, auto-create owner membership.
    Raises HTTPException if access denied.
    """
    membership = await get_tree_membership(tree_id, user_id)
    
    # If user is accessing their own tree and no membership exists, auto-create it
    if str(tree_id) == str(user_id) and not membership:
        membership_data = {
            "tree_id": tree_id,
            "user_id": user_id,
            "role": "owner",
            "joined_at": datetime.utcnow(),
            "granted_by": user_id
        }
        await get_collection("genealogy_tree_memberships").insert_one(membership_data)
        membership = membership_data
    
    if not membership:
        raise HTTPException(status_code=403, detail="You do not have access to this family tree")
    
    if required_roles and membership["role"] not in required_roles:
        raise HTTPException(
            status_code=403,
            detail=f"Access denied. Required role: {'/'.join(required_roles)}, your role: {membership['role']}"
        )
    
    return membership


@router.post("/persons", response_model=GenealogyPersonResponse, status_code=status.HTTP_201_CREATED)
async def create_genealogy_person(
    person: GenealogyPersonCreate,
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new genealogy person with optional relationships"""
    try:
        # Determine which tree to add person to (default: user's own tree)
        tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
        if not tree_oid:
            raise HTTPException(status_code=400, detail="Invalid tree_id")
        
        # Verify user has owner or member access to this tree
        await ensure_tree_access(tree_oid, ObjectId(current_user.id), required_roles=["owner", "member"])
        
        linked_user_oid = None
        
        if person.linked_user_id:
            linked_user_oid = safe_object_id(person.linked_user_id)
            if not linked_user_oid:
                raise HTTPException(status_code=400, detail="Invalid linked_user_id")
            
            user_doc = await get_collection("users").find_one({"_id": linked_user_oid})
            if not user_doc:
                raise HTTPException(status_code=404, detail="Linked user not found")
            
            existing_link = await get_collection("genealogy_persons").find_one({
                "linked_user_id": linked_user_oid
            })
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
            "linked_user_id": linked_user_oid,
            "source": person.source,
            "created_by": ObjectId(current_user.id),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        db = get_database()
        async with await db.client.start_session() as session:
            async with session.start_transaction():
                result = await get_collection("genealogy_persons").insert_one(person_data, session=session)
                person_id = result.inserted_id
                
                if person.relationships:
                    for rel_spec in person.relationships:
                        related_person_oid = safe_object_id(rel_spec.person_id)
                        if not related_person_oid:
                            raise HTTPException(status_code=400, detail=f"Invalid person_id in relationship: {rel_spec.person_id}")
                        
                        related_person = await get_collection("genealogy_persons").find_one(
                            {"_id": related_person_oid}, session=session
                        )
                        if not related_person:
                            raise HTTPException(status_code=404, detail=f"Related person not found: {rel_spec.person_id}")
                        
                        # Ensure related person belongs to the same tree
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
                            "created_by": ObjectId(current_user.id),
                            "created_at": datetime.utcnow()
                        }
                        await get_collection("genealogy_relationships").insert_one(
                            relationship_data, session=session
                        )
        
        person_doc = await get_collection("genealogy_persons").find_one({"_id": person_id})
        
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create person: {str(e)}")


@router.get("/persons", response_model=List[GenealogyPersonResponse])
async def list_genealogy_persons(
    tree_id: Optional[str] = Query(None, description="Tree ID (defaults to user's own tree)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all persons in family tree (supports shared trees via memberships)"""
    try:
        # Determine which tree to query (default: user's own tree)
        tree_oid = safe_object_id(tree_id) if tree_id else ObjectId(current_user.id)
        if not tree_oid:
            raise HTTPException(status_code=400, detail="Invalid tree_id")
        
        # Verify user has access to this tree (any role: owner, member, viewer)
        await ensure_tree_access(tree_oid, ObjectId(current_user.id))
        
        persons_cursor = get_collection("genealogy_persons").find({
            "family_id": tree_oid
        }).sort("last_name", 1)
        
        persons = []
        async for person_doc in persons_cursor:
            persons.append(GenealogyPersonResponse(
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
            ))
        
        return persons
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list persons: {str(e)}")


@router.get("/persons/{person_id}", response_model=GenealogyPersonResponse)
async def get_genealogy_person(
    person_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific person"""
    try:
        person_oid = safe_object_id(person_id)
        if not person_oid:
            raise HTTPException(status_code=400, detail="Invalid person ID")
        
        person_doc = await get_collection("genealogy_persons").find_one({"_id": person_oid})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        
        # Verify user has access to this tree (any role: owner/member/viewer)
        await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id))
        
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get person: {str(e)}")


@router.put("/persons/{person_id}", response_model=GenealogyPersonResponse)
async def update_genealogy_person(
    person_id: str,
    person_update: GenealogyPersonUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a person"""
    try:
        person_oid = safe_object_id(person_id)
        if not person_oid:
            raise HTTPException(status_code=400, detail="Invalid person ID")
        
        person_doc = await get_collection("genealogy_persons").find_one({"_id": person_oid})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        
        # Verify user has owner or member access (viewers cannot edit)
        await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id), required_roles=["owner", "member"])
        
        person_update_dict = person_update.dict(exclude_unset=True)
        update_data = {k: v for k, v in person_update_dict.items() if v is not None}
        unset_data = {}
        
        if "linked_user_id" in person_update_dict:
            if person_update.linked_user_id is None or person_update.linked_user_id == "":
                unset_data["linked_user_id"] = ""
                update_data.pop("linked_user_id", None)
            else:
                linked_user_oid = safe_object_id(person_update.linked_user_id)
                if not linked_user_oid:
                    raise HTTPException(status_code=400, detail="Invalid linked_user_id")
                
                user_doc = await get_collection("users").find_one({"_id": linked_user_oid})
                if not user_doc:
                    raise HTTPException(status_code=404, detail="Linked user not found")
                
                existing_link = await get_collection("genealogy_persons").find_one({
                    "linked_user_id": linked_user_oid,
                    "_id": {"$ne": person_oid}
                })
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
        
        update_data["updated_at"] = datetime.utcnow()
        
        update_ops = {"$set": update_data}
        if unset_data:
            update_ops["$unset"] = unset_data
        
        await get_collection("genealogy_persons").update_one(
            {"_id": person_oid},
            update_ops
        )
        
        updated_person = await get_collection("genealogy_persons").find_one({"_id": person_oid})
        
        return GenealogyPersonResponse(
            id=str(updated_person["_id"]),
            family_id=str(updated_person["family_id"]),
            first_name=updated_person["first_name"],
            last_name=updated_person["last_name"],
            maiden_name=updated_person.get("maiden_name"),
            gender=updated_person["gender"],
            birth_date=updated_person.get("birth_date"),
            birth_place=updated_person.get("birth_place"),
            death_date=updated_person.get("death_date"),
            death_place=updated_person.get("death_place"),
            is_alive=updated_person.get("is_alive", True),
            biography=updated_person.get("biography"),
            photo_url=updated_person.get("photo_url"),
            occupation=updated_person.get("occupation"),
            notes=updated_person.get("notes"),
            linked_user_id=str(updated_person["linked_user_id"]) if updated_person.get("linked_user_id") else None,
            source=updated_person.get("source", PersonSource.MANUAL),
            created_at=updated_person["created_at"],
            updated_at=updated_person["updated_at"],
            created_by=str(updated_person["created_by"])
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update person: {str(e)}")


@router.delete("/persons/{person_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_genealogy_person(
    person_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a person"""
    try:
        person_oid = safe_object_id(person_id)
        if not person_oid:
            raise HTTPException(status_code=400, detail="Invalid person ID")
        
        person_doc = await get_collection("genealogy_persons").find_one({"_id": person_oid})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        
        # Only tree owner can delete persons
        await ensure_tree_access(person_doc["family_id"], ObjectId(current_user.id), required_roles=["owner"])
        
        await get_collection("genealogy_persons").delete_one({"_id": person_oid})
        
        await get_collection("genealogy_relationships").delete_many({
            "$or": [
                {"person1_id": person_oid},
                {"person2_id": person_oid}
            ]
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete person: {str(e)}")


@router.get("/search-users", response_model=List[UserSearchResult])
async def search_platform_users(
    query: str = Query(..., min_length=2, description="Search query for username, email, or name"),
    limit: int = Query(20, ge=1, le=50, description="Maximum number of results"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Search for any platform user to link to genealogy persons or invite to family hub"""
    try:
        search_regex = {"$regex": query, "$options": "i"}
        users_cursor = get_collection("users").find({
            "_id": {"$ne": ObjectId(current_user.id)},
            "$or": [
                {"username": search_regex},
                {"email": search_regex},
                {"full_name": search_regex}
            ]
        }).limit(limit)
        
        linked_user_ids = set()
        linked_persons_cursor = get_collection("genealogy_persons").find(
            {"family_id": ObjectId(current_user.id), "linked_user_id": {"$exists": True, "$ne": None}},
            {"linked_user_id": 1}
        )
        async for person in linked_persons_cursor:
            if person.get("linked_user_id"):
                linked_user_ids.add(str(person["linked_user_id"]))
        
        results = []
        async for user_doc in users_cursor:
            user_id = str(user_doc["_id"])
            results.append(UserSearchResult(
                id=user_id,
                username=user_doc.get("username", ""),
                email=user_doc.get("email", ""),
                full_name=user_doc.get("full_name"),
                profile_photo=user_doc.get("profile_photo"),
                already_linked=user_id in linked_user_ids
            ))
        
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to search users: {str(e)}")


@router.post("/relationships", response_model=GenealogyRelationshipResponse, status_code=status.HTTP_201_CREATED)
async def create_genealogy_relationship(
    relationship: GenealogyRelationshipCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create relationship between two persons"""
    try:
        person1_oid = safe_object_id(relationship.person1_id)
        person2_oid = safe_object_id(relationship.person2_id)
        
        if not person1_oid or not person2_oid:
            raise HTTPException(status_code=400, detail="Invalid person ID")
        
        person1 = await get_collection("genealogy_persons").find_one({"_id": person1_oid})
        person2 = await get_collection("genealogy_persons").find_one({"_id": person2_oid})
        
        if not person1 or not person2:
            raise HTTPException(status_code=404, detail="One or both persons not found")
        
        if str(person1["family_id"]) != current_user.id or str(person2["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to create this relationship")
        
        relationship_data = {
            "family_id": ObjectId(current_user.id),
            "person1_id": person1_oid,
            "person2_id": person2_oid,
            "relationship_type": relationship.relationship_type,
            "notes": relationship.notes,
            "created_by": ObjectId(current_user.id),
            "created_at": datetime.utcnow()
        }
        
        result = await get_collection("genealogy_relationships").insert_one(relationship_data)
        relationship_doc = await get_collection("genealogy_relationships").find_one({"_id": result.inserted_id})
        
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create relationship: {str(e)}")


@router.get("/relationships", response_model=List[GenealogyRelationshipResponse])
async def list_genealogy_relationships(
    current_user: UserInDB = Depends(get_current_user)
):
    """List all relationships"""
    try:
        user_oid = ObjectId(current_user.id)
        
        relationships_cursor = get_collection("genealogy_relationships").find({
            "family_id": user_oid
        }).sort("created_at", -1)
        
        relationships = []
        async for rel_doc in relationships_cursor:
            relationships.append(GenealogyRelationshipResponse(
                id=str(rel_doc["_id"]),
                family_id=str(rel_doc["family_id"]),
                person1_id=str(rel_doc["person1_id"]),
                person2_id=str(rel_doc["person2_id"]),
                relationship_type=rel_doc["relationship_type"],
                notes=rel_doc.get("notes"),
                created_at=rel_doc["created_at"],
                created_by=str(rel_doc["created_by"])
            ))
        
        return relationships
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list relationships: {str(e)}")


@router.delete("/relationships/{relationship_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_genealogy_relationship(
    relationship_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a relationship"""
    try:
        relationship_oid = safe_object_id(relationship_id)
        if not relationship_oid:
            raise HTTPException(status_code=400, detail="Invalid relationship ID")
        
        relationship_doc = await get_collection("genealogy_relationships").find_one({"_id": relationship_oid})
        if not relationship_doc:
            raise HTTPException(status_code=404, detail="Relationship not found")
        
        if str(relationship_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this relationship")
        
        await get_collection("genealogy_relationships").delete_one({"_id": relationship_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete relationship: {str(e)}")


@router.get("/tree", response_model=List[FamilyTreeNode])
async def get_family_tree(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get complete family tree structure"""
    try:
        user_oid = ObjectId(current_user.id)
        
        persons_cursor = get_collection("genealogy_persons").find({"family_id": user_oid})
        relationships_cursor = get_collection("genealogy_relationships").find({"family_id": user_oid})
        
        persons_dict = {}
        async for person_doc in persons_cursor:
            person_response = GenealogyPersonResponse(
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
            persons_dict[str(person_doc["_id"])] = {
                "person": person_response,
                "relationships": [],
                "children": [],
                "parents": [],
                "spouse": None
            }
        
        relationships_list = []
        async for rel_doc in relationships_cursor:
            rel_response = GenealogyRelationshipResponse(
                id=str(rel_doc["_id"]),
                family_id=str(rel_doc["family_id"]),
                person1_id=str(rel_doc["person1_id"]),
                person2_id=str(rel_doc["person2_id"]),
                relationship_type=rel_doc["relationship_type"],
                notes=rel_doc.get("notes"),
                created_at=rel_doc["created_at"],
                created_by=str(rel_doc["created_by"])
            )
            relationships_list.append(rel_response)
            
            person1_id = str(rel_doc["person1_id"])
            person2_id = str(rel_doc["person2_id"])
            
            if person1_id in persons_dict:
                persons_dict[person1_id]["relationships"].append(rel_response)
                
                if rel_doc["relationship_type"] == "parent":
                    persons_dict[person1_id]["children"].append(person2_id)
                elif rel_doc["relationship_type"] == "child":
                    persons_dict[person1_id]["parents"].append(person2_id)
                elif rel_doc["relationship_type"] == "spouse":
                    persons_dict[person1_id]["spouse"] = person2_id
            
            if person2_id in persons_dict:
                persons_dict[person2_id]["relationships"].append(rel_response)
                
                if rel_doc["relationship_type"] == "parent":
                    persons_dict[person2_id]["parents"].append(person1_id)
                elif rel_doc["relationship_type"] == "child":
                    persons_dict[person2_id]["children"].append(person1_id)
                elif rel_doc["relationship_type"] == "spouse":
                    persons_dict[person2_id]["spouse"] = person1_id
        
        tree_nodes = [
            FamilyTreeNode(
                person=node_data["person"],
                relationships=node_data["relationships"],
                children=node_data["children"],
                parents=node_data["parents"],
                spouse=node_data["spouse"]
            )
            for node_data in persons_dict.values()
        ]
        
        return tree_nodes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get family tree: {str(e)}")


@router.post("/invitations", response_model=FamilyHubInvitationResponse, status_code=status.HTTP_201_CREATED)
async def send_family_hub_invitation(
    invitation: FamilyHubInvitationCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Send an invitation to a user to join your family hub and link to a genealogy person"""
    try:
        person_oid = safe_object_id(invitation.person_id)
        invited_user_oid = safe_object_id(invitation.invited_user_id)
        
        if not person_oid or not invited_user_oid:
            raise HTTPException(status_code=400, detail="Invalid person or user ID")
        
        person_doc = await get_collection("genealogy_persons").find_one({"_id": person_oid})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        
        if str(person_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to invite for this person")
        
        if not person_doc.get("is_alive", True):
            raise HTTPException(status_code=400, detail="Cannot invite for deceased persons")
        
        invited_user = await get_collection("users").find_one({"_id": invited_user_oid})
        if not invited_user:
            raise HTTPException(status_code=404, detail="Invited user not found")
        
        if str(invited_user_oid) == current_user.id:
            raise HTTPException(status_code=400, detail="Cannot invite yourself")
        
        existing_invitation = await get_collection("family_hub_invitations").find_one({
            "person_id": person_oid,
            "invited_user_id": invited_user_oid,
            "status": InvitationStatus.PENDING
        })
        if existing_invitation:
            raise HTTPException(status_code=400, detail="Pending invitation already exists for this user and person")
        
        if person_doc.get("linked_user_id"):
            raise HTTPException(status_code=400, detail="This person is already linked to a user")
        
        invitation_data = {
            "family_id": ObjectId(current_user.id),
            "person_id": person_oid,
            "inviter_id": ObjectId(current_user.id),
            "invited_user_id": invited_user_oid,
            "message": invitation.message,
            "status": InvitationStatus.PENDING,
            "created_at": datetime.utcnow(),
            "responded_at": None
        }
        
        result = await get_collection("family_hub_invitations").insert_one(invitation_data)
        invitation_doc = await get_collection("family_hub_invitations").find_one({"_id": result.inserted_id})
        
        inviter_name = getattr(current_user, 'username', None) or current_user.full_name or current_user.email
        notification_data = {
            "user_id": invited_user_oid,
            "type": "family_hub_invitation",
            "title": "Family Hub Invitation",
            "message": f"{inviter_name} invited you to join their family hub",
            "related_id": str(result.inserted_id),
            "read": False,
            "created_at": datetime.utcnow()
        }
        await get_collection("notifications").insert_one(notification_data)
        
        return FamilyHubInvitationResponse(
            id=str(invitation_doc["_id"]),
            family_id=str(invitation_doc["family_id"]),
            person_id=str(invitation_doc["person_id"]),
            inviter_id=str(invitation_doc["inviter_id"]),
            invited_user_id=str(invitation_doc["invited_user_id"]),
            message=invitation_doc.get("message"),
            status=invitation_doc["status"],
            created_at=invitation_doc["created_at"],
            responded_at=invitation_doc.get("responded_at")
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send invitation: {str(e)}")


@router.get("/invitations/sent", response_model=List[FamilyHubInvitationResponse])
async def list_sent_invitations(
    status_filter: Optional[str] = Query(None, description="Filter by status: pending, accepted, declined"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List invitations sent by current user"""
    try:
        query_filter = {"inviter_id": ObjectId(current_user.id)}
        if status_filter:
            query_filter["status"] = status_filter
        
        invitations_cursor = get_collection("family_hub_invitations").find(query_filter).sort("created_at", -1)
        
        invitations = []
        async for inv_doc in invitations_cursor:
            invitations.append(FamilyHubInvitationResponse(
                id=str(inv_doc["_id"]),
                family_id=str(inv_doc["family_id"]),
                person_id=str(inv_doc["person_id"]),
                inviter_id=str(inv_doc["inviter_id"]),
                invited_user_id=str(inv_doc["invited_user_id"]),
                message=inv_doc.get("message"),
                status=inv_doc["status"],
                created_at=inv_doc["created_at"],
                responded_at=inv_doc.get("responded_at")
            ))
        
        return invitations
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list sent invitations: {str(e)}")


@router.get("/invitations/received", response_model=List[FamilyHubInvitationResponse])
async def list_received_invitations(
    status_filter: Optional[str] = Query(None, description="Filter by status: pending, accepted, declined"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List invitations received by current user"""
    try:
        query_filter = {"invited_user_id": ObjectId(current_user.id)}
        if status_filter:
            query_filter["status"] = status_filter
        
        invitations_cursor = get_collection("family_hub_invitations").find(query_filter).sort("created_at", -1)
        
        invitations = []
        async for inv_doc in invitations_cursor:
            invitations.append(FamilyHubInvitationResponse(
                id=str(inv_doc["_id"]),
                family_id=str(inv_doc["family_id"]),
                person_id=str(inv_doc["person_id"]),
                inviter_id=str(inv_doc["inviter_id"]),
                invited_user_id=str(inv_doc["invited_user_id"]),
                message=inv_doc.get("message"),
                status=inv_doc["status"],
                created_at=inv_doc["created_at"],
                responded_at=inv_doc.get("responded_at")
            ))
        
        return invitations
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list received invitations: {str(e)}")


@router.post("/invitations/{invitation_id}/respond", response_model=FamilyHubInvitationResponse)
async def respond_to_invitation(
    invitation_id: str,
    action: InvitationAction,
    current_user: UserInDB = Depends(get_current_user)
):
    """Accept or decline a family hub invitation"""
    try:
        invitation_oid = safe_object_id(invitation_id)
        if not invitation_oid:
            raise HTTPException(status_code=400, detail="Invalid invitation ID")
        
        invitation_doc = await get_collection("family_hub_invitations").find_one({"_id": invitation_oid})
        if not invitation_doc:
            raise HTTPException(status_code=404, detail="Invitation not found")
        
        if str(invitation_doc["invited_user_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to respond to this invitation")
        
        if invitation_doc["status"] != InvitationStatus.PENDING:
            raise HTTPException(status_code=400, detail="Invitation has already been responded to")
        
        new_status = InvitationStatus.ACCEPTED if action.action == "accept" else InvitationStatus.DECLINED
        
        db = get_database()
        async with await db.client.start_session() as session:
            async with session.start_transaction():
                if action.action == "accept":
                    person_doc = await get_collection("genealogy_persons").find_one(
                        {"_id": invitation_doc["person_id"]}, session=session
                    )
                    if not person_doc:
                        raise HTTPException(status_code=404, detail="Person not found")
                    
                    if person_doc.get("linked_user_id"):
                        raise HTTPException(status_code=400, detail="Person is already linked to another user")
                    
                    await get_collection("genealogy_persons").update_one(
                        {"_id": invitation_doc["person_id"]},
                        {
                            "$set": {
                                "linked_user_id": ObjectId(current_user.id),
                                "source": PersonSource.PLATFORM_USER,
                                "updated_at": datetime.utcnow()
                            }
                        },
                        session=session
                    )
                
                await get_collection("family_hub_invitations").update_one(
                    {"_id": invitation_oid},
                    {
                        "$set": {
                            "status": new_status,
                            "responded_at": datetime.utcnow()
                        }
                    },
                    session=session
                )
        
        updated_invitation = await get_collection("family_hub_invitations").find_one({"_id": invitation_oid})
        
        responder_name = getattr(current_user, 'username', None) or current_user.full_name or current_user.email
        notification_data = {
            "user_id": updated_invitation["inviter_id"],
            "type": "invitation_response",
            "title": f"Invitation {new_status}",
            "message": f"{responder_name} {new_status} your family hub invitation",
            "related_id": invitation_id,
            "read": False,
            "created_at": datetime.utcnow()
        }
        await get_collection("notifications").insert_one(notification_data)
        
        return FamilyHubInvitationResponse(
            id=str(updated_invitation["_id"]),
            family_id=str(updated_invitation["family_id"]),
            person_id=str(updated_invitation["person_id"]),
            inviter_id=str(updated_invitation["inviter_id"]),
            invited_user_id=str(updated_invitation["invited_user_id"]),
            message=updated_invitation.get("message"),
            status=updated_invitation["status"],
            created_at=updated_invitation["created_at"],
            responded_at=updated_invitation.get("responded_at")
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to respond to invitation: {str(e)}")


@router.delete("/invitations/{invitation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_invitation(
    invitation_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Cancel a pending invitation (only by inviter)"""
    try:
        invitation_oid = safe_object_id(invitation_id)
        if not invitation_oid:
            raise HTTPException(status_code=400, detail="Invalid invitation ID")
        
        invitation_doc = await get_collection("family_hub_invitations").find_one({"_id": invitation_oid})
        if not invitation_doc:
            raise HTTPException(status_code=404, detail="Invitation not found")
        
        if str(invitation_doc["inviter_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to cancel this invitation")
        
        if invitation_doc["status"] != InvitationStatus.PENDING:
            raise HTTPException(status_code=400, detail="Can only cancel pending invitations")
        
        await get_collection("family_hub_invitations").update_one(
            {"_id": invitation_oid},
            {
                "$set": {
                    "status": InvitationStatus.CANCELLED,
                    "responded_at": datetime.utcnow()
                }
            }
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to cancel invitation: {str(e)}")


# ==============================================================================
# TREE MEMBERSHIP ENDPOINTS - For shared family tree access control
# ==============================================================================

@router.get("/tree-memberships", response_model=List[dict])
async def list_tree_memberships(
    tree_id: Optional[str] = Query(None, description="Filter by tree_id (family_id)"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all tree memberships - either for current user or for a specific tree they own"""
    try:
        if tree_id:
            # Verify user is owner or member of this tree
            tree_oid = safe_object_id(tree_id)
            if not tree_oid:
                raise HTTPException(status_code=400, detail="Invalid tree_id")
            
            # Check if user is owner or member
            membership = await get_collection("genealogy_tree_memberships").find_one({
                "tree_id": tree_oid,
                "user_id": ObjectId(current_user.id)
            })
            
            if not membership:
                raise HTTPException(status_code=403, detail="Not authorized to view this tree's memberships")
            
            # Get all memberships for this tree
            query = {"tree_id": tree_oid}
        else:
            # Get all trees where current user is a member
            query = {"user_id": ObjectId(current_user.id)}
        
        memberships_cursor = get_collection("genealogy_tree_memberships").find(query).sort("joined_at", -1)
        
        memberships = []
        async for membership_doc in memberships_cursor:
            # Get user details
            user_doc = await get_collection("users").find_one({"_id": membership_doc["user_id"]})
            
            membership_data = {
                "id": str(membership_doc["_id"]),
                "tree_id": str(membership_doc["tree_id"]),
                "user_id": str(membership_doc["user_id"]),
                "username": user_doc.get("username", "") if user_doc else "",
                "full_name": user_doc.get("full_name") if user_doc else None,
                "profile_photo": user_doc.get("profile_photo") if user_doc else None,
                "role": membership_doc["role"],
                "joined_at": membership_doc["joined_at"],
                "granted_by": str(membership_doc["granted_by"])
            }
            memberships.append(membership_data)
        
        return memberships
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list memberships: {str(e)}")


@router.post("/tree-memberships", status_code=status.HTTP_201_CREATED)
async def create_tree_membership(
    user_id: str = Query(..., description="User ID to grant access to"),
    role: str = Query("viewer", description="Role: owner, member, or viewer"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Grant tree access to another user (only tree owner can do this)"""
    try:
        # Verify the requesting user is the tree owner (tree_id is current_user.id)
        tree_oid = ObjectId(current_user.id)
        
        # Check if requesting user is owner of their own tree
        owner_membership = await get_collection("genealogy_tree_memberships").find_one({
            "tree_id": tree_oid,
            "user_id": tree_oid,
            "role": "owner"
        })
        
        if not owner_membership:
            # Create owner membership if it doesn't exist
            await get_collection("genealogy_tree_memberships").insert_one({
                "tree_id": tree_oid,
                "user_id": tree_oid,
                "role": "owner",
                "joined_at": datetime.utcnow(),
                "granted_by": tree_oid
            })
        
        # Validate user_id
        target_user_oid = safe_object_id(user_id)
        if not target_user_oid:
            raise HTTPException(status_code=400, detail="Invalid user_id")
        
        # Check if user exists
        user_exists = await get_collection("users").find_one({"_id": target_user_oid})
        if not user_exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if membership already exists
        existing = await get_collection("genealogy_tree_memberships").find_one({
            "tree_id": tree_oid,
            "user_id": target_user_oid
        })
        
        if existing:
            raise HTTPException(status_code=400, detail="User already has access to this tree")
        
        # Create membership
        membership_data = {
            "tree_id": tree_oid,
            "user_id": target_user_oid,
            "role": role,
            "joined_at": datetime.utcnow(),
            "granted_by": ObjectId(current_user.id)
        }
        
        result = await get_collection("genealogy_tree_memberships").insert_one(membership_data)
        
        # Send notification to the user
        granter_name = getattr(current_user, 'username', None) or current_user.full_name or current_user.email
        notification_data = {
            "user_id": target_user_oid,
            "type": "tree_access_granted",
            "title": "Family Tree Access Granted",
            "message": f"{granter_name} granted you {role} access to their family tree",
            "related_id": str(result.inserted_id),
            "read": False,
            "created_at": datetime.utcnow()
        }
        await get_collection("notifications").insert_one(notification_data)
        
        return {"message": "Tree access granted successfully", "membership_id": str(result.inserted_id)}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to grant tree access: {str(e)}")


# ==============================================================================
# INVITATION LINK ENDPOINTS - Token-based invitations for living family members
# ==============================================================================

@router.post("/invite-links", status_code=status.HTTP_201_CREATED)
async def create_invite_link(
    person_id: str = Query(..., description="Genealogy person ID to link invitation to"),
    email: Optional[str] = Query(None, description="Email to send invitation to"),
    message: Optional[str] = Query(None, description="Personal message"),
    expires_in_days: int = Query(30, ge=1, le=365, description="Expiry in days"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Create an invitation link for a living family member to join the platform"""
    try:
        import secrets
        
        person_oid = safe_object_id(person_id)
        if not person_oid:
            raise HTTPException(status_code=400, detail="Invalid person_id")
        
        # Verify person exists and belongs to user's tree
        person_doc = await get_collection("genealogy_persons").find_one({"_id": person_oid})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        
        if str(person_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to invite for this person")
        
        # Verify person is alive and not already linked
        if not person_doc.get("is_alive", True):
            raise HTTPException(status_code=400, detail="Cannot send invitation for deceased person")
        
        if person_doc.get("linked_user_id"):
            raise HTTPException(status_code=400, detail="Person is already linked to a platform user")
        
        # Check if there's already a pending invitation
        existing_invite = await get_collection("genealogy_invite_links").find_one({
            "person_id": person_oid,
            "status": "pending",
            "expires_at": {"$gt": datetime.utcnow()}
        })
        
        if existing_invite:
            raise HTTPException(status_code=400, detail="An active invitation already exists for this person")
        
        # Generate unique token
        token = secrets.token_urlsafe(32)
        expires_at = datetime.utcnow() + __import__('datetime').timedelta(days=expires_in_days)
        
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
        
        result = await get_collection("genealogy_invite_links").insert_one(invite_data)
        
        # Update person with invitation details
        await get_collection("genealogy_persons").update_one(
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
        
        return {
            "id": str(result.inserted_id),
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create invitation: {str(e)}")


@router.post("/join/{token}", status_code=status.HTTP_200_OK)
async def redeem_invite_link(
    token: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Redeem an invitation link and link user to genealogy person"""
    try:
        # Find invitation by token
        invite_doc = await get_collection("genealogy_invite_links").find_one({"token": token})
        if not invite_doc:
            raise HTTPException(status_code=404, detail="Invitation not found")
        
        # Check if expired
        if invite_doc["expires_at"] < datetime.utcnow():
            await get_collection("genealogy_invite_links").update_one(
                {"_id": invite_doc["_id"]},
                {"$set": {"status": "expired"}}
            )
            raise HTTPException(status_code=400, detail="Invitation has expired")
        
        # Check if already accepted
        if invite_doc["status"] != "pending":
            raise HTTPException(status_code=400, detail=f"Invitation has already been {invite_doc['status']}")
        
        # Get person
        person_doc = await get_collection("genealogy_persons").find_one({"_id": invite_doc["person_id"]})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        
        # Check if person is already linked
        if person_doc.get("linked_user_id"):
            raise HTTPException(status_code=400, detail="This person is already linked to another user")
        
        # Link user to person
        db = get_database()
        async with await db.client.start_session() as session:
            async with session.start_transaction():
                # Update person
                await get_collection("genealogy_persons").update_one(
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
                
                # Update invitation
                await get_collection("genealogy_invite_links").update_one(
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
                
                # Grant tree membership to the new user
                membership_exists = await get_collection("genealogy_tree_memberships").find_one({
                    "tree_id": invite_doc["family_id"],
                    "user_id": ObjectId(current_user.id)
                }, session=session)
                
                if not membership_exists:
                    await get_collection("genealogy_tree_memberships").insert_one({
                        "tree_id": invite_doc["family_id"],
                        "user_id": ObjectId(current_user.id),
                        "role": "member",
                        "joined_at": datetime.utcnow(),
                        "granted_by": invite_doc["created_by"]
                    }, session=session)
        
        # Send notification to tree owner
        joiner_name = getattr(current_user, 'username', None) or current_user.full_name or current_user.email
        notification_data = {
            "user_id": invite_doc["family_id"],
            "type": "invitation_accepted",
            "title": "Family Tree Invitation Accepted",
            "message": f"{joiner_name} joined your family tree",
            "related_id": str(invite_doc["person_id"]),
            "read": False,
            "created_at": datetime.utcnow()
        }
        await get_collection("notifications").insert_one(notification_data)
        
        # Auto-provision: Add new member to tree owner's "Family Tree Members" circle
        # Find or create the circle
        tree_circle = await get_collection("family_circles").find_one({
            "owner_id": invite_doc["family_id"],
            "name": "Family Tree Members"
        })
        
        if tree_circle:
            # Add new member to existing circle
            if ObjectId(current_user.id) not in tree_circle.get("member_ids", []):
                await get_collection("family_circles").update_one(
                    {"_id": tree_circle["_id"]},
                    {
                        "$addToSet": {"member_ids": ObjectId(current_user.id)},
                        "$set": {"updated_at": datetime.utcnow()}
                    }
                )
        else:
            # Create new "Family Tree Members" circle
            circle_data = {
                "name": "Family Tree Members",
                "description": "Members who have access to the family genealogy tree",
                "circle_type": "extended_family",
                "owner_id": invite_doc["family_id"],
                "member_ids": [invite_doc["family_id"], ObjectId(current_user.id)],
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            await get_collection("family_circles").insert_one(circle_data)
        
        return {
            "message": "Successfully joined family tree",
            "person_id": str(invite_doc["person_id"]),
            "tree_id": str(invite_doc["family_id"])
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to redeem invitation: {str(e)}")


@router.get("/invite-links", response_model=List[dict])
async def list_invite_links(
    status_filter: Optional[str] = Query(None, description="Filter by status"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all invitation links created by current user"""
    try:
        query = {"family_id": ObjectId(current_user.id)}
        if status_filter:
            query["status"] = status_filter
        
        invites_cursor = get_collection("genealogy_invite_links").find(query).sort("created_at", -1)
        
        invites = []
        async for invite_doc in invites_cursor:
            person_doc = await get_collection("genealogy_persons").find_one({"_id": invite_doc["person_id"]})
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
            invites.append(invite_data)
        
        return invites
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list invitations: {str(e)}")


# ==============================================================================
# PERSON TIMELINE ENDPOINT - For viewing memories associated with a person
# ==============================================================================

@router.get("/persons/{person_id}/timeline", response_model=List[dict])
async def get_person_timeline(
    person_id: str,
    skip: int = Query(0, ge=0, description="Skip N memories"),
    limit: int = Query(20, ge=1, le=100, description="Limit results"),
    current_user: UserInDB = Depends(get_current_user)
):
    """Get timeline of all memories associated with this genealogy person (Facebook-style)"""
    try:
        person_oid = safe_object_id(person_id)
        if not person_oid:
            raise HTTPException(status_code=400, detail="Invalid person_id")
        
        # Verify person exists
        person_doc = await get_collection("genealogy_persons").find_one({"_id": person_oid})
        if not person_doc:
            raise HTTPException(status_code=404, detail="Person not found")
        
        # Check if user has access to this tree
        tree_id = person_doc["family_id"]
        membership = await get_collection("genealogy_tree_memberships").find_one({
            "tree_id": tree_id,
            "user_id": ObjectId(current_user.id)
        })
        
        if not membership and str(tree_id) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to view this person's timeline")
        
        # Find all memories that reference this person in genealogy_person_ids
        memories_cursor = get_collection("memories").find({
            "genealogy_person_ids": str(person_oid)
        }).sort("created_at", -1).skip(skip).limit(limit)
        
        memories = []
        async for memory_doc in memories_cursor:
            # Get owner info
            owner_doc = await get_collection("users").find_one({"_id": memory_doc["owner_id"]})
            
            memory_data = {
                "id": str(memory_doc["_id"]),
                "title": memory_doc.get("title", ""),
                "content": memory_doc.get("content", ""),
                "media_urls": memory_doc.get("media_urls", []),
                "tags": memory_doc.get("tags", []),
                "created_at": memory_doc["created_at"],
                "owner_id": str(memory_doc["owner_id"]),
                "owner_username": owner_doc.get("username", "") if owner_doc else "",
                "owner_full_name": owner_doc.get("full_name") if owner_doc else None,
                "like_count": memory_doc.get("like_count", 0),
                "comment_count": memory_doc.get("comment_count", 0)
            }
            memories.append(memory_data)
        
        return memories
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get timeline: {str(e)}")
