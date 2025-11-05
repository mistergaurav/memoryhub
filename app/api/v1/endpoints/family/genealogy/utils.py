"""Genealogy utility functions and mappers."""
from typing import Dict, Any, Optional
from bson import ObjectId
from fastapi import HTTPException, status

from .schemas import GenealogyPersonResponse, GenealogyRelationshipResponse, PersonSource, RelationshipType
from app.repositories.family_repository import UserRepository

user_repo = UserRepository()


def get_inverse_relationship_type(relationship_type: RelationshipType) -> Optional[RelationshipType]:
    """Get the inverse relationship type for asymmetric relationships.
    
    For symmetric relationships (spouse, sibling, cousin), returns None as they don't need inversion.
    For asymmetric relationships, returns the inverse type.
    """
    inverse_map = {
        RelationshipType.PARENT: RelationshipType.CHILD,
        RelationshipType.CHILD: RelationshipType.PARENT,
        RelationshipType.GRANDPARENT: RelationshipType.GRANDCHILD,
        RelationshipType.GRANDCHILD: RelationshipType.GRANDPARENT,
        RelationshipType.AUNT_UNCLE: RelationshipType.NIECE_NEPHEW,
        RelationshipType.NIECE_NEPHEW: RelationshipType.AUNT_UNCLE,
    }
    return inverse_map.get(relationship_type)


def is_symmetric_relationship(relationship_type: RelationshipType) -> bool:
    """Check if a relationship type is symmetric (bidirectional by nature)."""
    symmetric_types = {
        RelationshipType.SPOUSE,
        RelationshipType.SIBLING,
        RelationshipType.COUSIN,
    }
    return relationship_type in symmetric_types


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


async def validate_user_exists(user_id: str) -> Dict[str, Any]:
    """Validate that a user exists by their ID"""
    user = await user_repo.find_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User not found")
    return user


async def get_user_display_name(user_doc: Dict[str, Any]) -> str:
    """Get display name for a user"""
    return user_doc.get("full_name") or user_doc.get("email", "Unknown")
