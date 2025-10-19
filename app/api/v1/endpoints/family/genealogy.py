from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.family.genealogy import (
    GenealogyPersonCreate, GenealogyPersonUpdate, GenealogyPersonResponse,
    GenealogyRelationshipCreate, GenealogyRelationshipResponse,
    FamilyTreeNode
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None


@router.post("/persons", response_model=GenealogyPersonResponse, status_code=status.HTTP_201_CREATED)
async def create_genealogy_person(
    person: GenealogyPersonCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new genealogy person"""
    try:
        person_data = {
            "family_id": ObjectId(current_user.id),
            "first_name": person.first_name,
            "last_name": person.last_name,
            "maiden_name": person.maiden_name,
            "gender": person.gender,
            "birth_date": person.birth_date,
            "birth_place": person.birth_place,
            "death_date": person.death_date,
            "death_place": person.death_place,
            "biography": person.biography,
            "photo_url": person.photo_url,
            "occupation": person.occupation,
            "notes": person.notes,
            "created_by": ObjectId(current_user.id),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("genealogy_persons").insert_one(person_data)
        person_doc = await get_collection("genealogy_persons").find_one({"_id": result.inserted_id})
        
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
            biography=person_doc.get("biography"),
            photo_url=person_doc.get("photo_url"),
            occupation=person_doc.get("occupation"),
            notes=person_doc.get("notes"),
            created_at=person_doc["created_at"],
            updated_at=person_doc["updated_at"],
            created_by=str(person_doc["created_by"])
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create person: {str(e)}")


@router.get("/persons", response_model=List[GenealogyPersonResponse])
async def list_genealogy_persons(
    current_user: UserInDB = Depends(get_current_user)
):
    """List all persons in family tree"""
    try:
        user_oid = ObjectId(current_user.id)
        
        persons_cursor = get_collection("genealogy_persons").find({
            "family_id": user_oid
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
                biography=person_doc.get("biography"),
                photo_url=person_doc.get("photo_url"),
                occupation=person_doc.get("occupation"),
                notes=person_doc.get("notes"),
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
        
        if str(person_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to view this person")
        
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
            biography=person_doc.get("biography"),
            photo_url=person_doc.get("photo_url"),
            occupation=person_doc.get("occupation"),
            notes=person_doc.get("notes"),
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
        
        if str(person_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this person")
        
        update_data = {k: v for k, v in person_update.dict(exclude_unset=True).items() if v is not None}
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("genealogy_persons").update_one(
            {"_id": person_oid},
            {"$set": update_data}
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
            biography=updated_person.get("biography"),
            photo_url=updated_person.get("photo_url"),
            occupation=updated_person.get("occupation"),
            notes=updated_person.get("notes"),
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
        
        if str(person_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this person")
        
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
                biography=person_doc.get("biography"),
                photo_url=person_doc.get("photo_url"),
                occupation=person_doc.get("occupation"),
                notes=person_doc.get("notes"),
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
