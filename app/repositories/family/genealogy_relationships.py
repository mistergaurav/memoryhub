"""Repository for genealogyrelationship operations."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class GenealogyRelationshipRepository(BaseRepository):
    """Repository for genealogy relationships."""
    
    def __init__(self):
        super().__init__("genealogy_relationships")
    
    async def find_by_tree(
        self,
        tree_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Find all relationships in a family tree."""
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        return await self.find_many(
            {"family_id": tree_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_existing_relationship(
        self,
        person1_id: ObjectId,
        person2_id: ObjectId,
        relationship_type: str,
        family_id: ObjectId
    ) -> Optional[Dict[str, Any]]:
        """Check if a specific relationship already exists between two persons.
        
        This checks for an exact match of the relationship in the specified direction.
        """
        return await self.find_one({
            "family_id": family_id,
            "person1_id": person1_id,
            "person2_id": person2_id,
            "relationship_type": relationship_type
        }, raise_404=False)
    
    async def find_any_relationship_between(
        self,
        person1_id: ObjectId,
        person2_id: ObjectId,
        family_id: ObjectId
    ) -> List[Dict[str, Any]]:
        """Find any existing relationships between two persons (in either direction)."""
        return await self.find_many({
            "family_id": family_id,
            "$or": [
                {"person1_id": person1_id, "person2_id": person2_id},
                {"person1_id": person2_id, "person2_id": person1_id}
            ]
        })
    
    async def validate_no_circular_reference(
        self,
        person1_id: ObjectId,
        person2_id: ObjectId,
        relationship_type: str,
        family_id: ObjectId
    ) -> None:
        """
        Validate that creating this relationship won't create a circular reference.
        
        For parent-child relationships, ensures no circular ancestry:
        - A cannot be both parent and child of B
        - A cannot be ancestor of B if B is being set as ancestor of A
        
        Args:
            person1_id: First person in relationship
            person2_id: Second person in relationship  
            relationship_type: Type of relationship being created
            family_id: Family tree ID
            
        Raises:
            HTTPException: If circular reference would be created
        """
        # Only check for parent-child relationships
        if relationship_type not in ["parent", "child"]:
            return
        
        # Check for direct inverse relationship
        inverse_type = "child" if relationship_type == "parent" else "parent"
        inverse_exists = await self.find_existing_relationship(
            person1_id=person2_id,
            person2_id=person1_id,
            relationship_type=inverse_type,
            family_id=family_id
        )
        
        if inverse_exists:
            raise HTTPException(
                status_code=400,
                detail=f"Circular relationship detected: {relationship_type} relationship cannot be created because inverse relationship already exists"
            )
        
        # For more complex ancestry checking, we'd need to traverse the graph
        # For now, we just check direct circular references
        # TODO: Implement full ancestry path checking to prevent A->B->C->A cycles

    async def find_by_person(self, person_id: str) -> List[Dict[str, Any]]:
        """Find all relationships involving a specific person."""
        person_oid = self.validate_object_id(person_id, "person_id")
        return await self.find_many({
            "$or": [
                {"person1_id": person_oid},
                {"person2_id": person_oid}
            ]
        })

    async def find_parents(self, person_id: str) -> List[Dict[str, Any]]:
        """
        Find all parent relationships for a person.
        Returns relationships where the person is the CHILD.
        """
        person_oid = self.validate_object_id(person_id, "person_id")
        return await self.find_many({
            "$or": [
                # Case 1: Someone else (P1) is PARENT of Me (P2)
                {"person2_id": person_oid, "relationship_type": "parent"},
                # Case 2: Me (P1) is CHILD of Someone else (P2)
                {"person1_id": person_oid, "relationship_type": "child"}
            ]
        })
