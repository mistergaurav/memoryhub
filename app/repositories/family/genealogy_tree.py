"""Repository for genealogy tree queries with relationship traversal."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class GenealogyTreeRepository(BaseRepository):
    """
    Repository for genealogy tree queries with relationship traversal.
    Provides methods for building family trees and finding descendants/ancestors.
    """
    
    def __init__(self):
        super().__init__("genealogy_persons")
    
    async def get_family_tree(
        self,
        person_id: str,
        max_depth: int = 3
    ) -> Dict[str, Any]:
        """
        Build family tree using graph traversal.
        
        Uses MongoDB's $graphLookup to traverse relationships and build
        a hierarchical family tree structure.
        
        Args:
            person_id: Root person ID to build tree from
            max_depth: Maximum depth of tree traversal (default: 3 generations)
            
        Returns:
            Dictionary containing the root person and their family tree
        """
        person_oid = self.validate_object_id(person_id, "person_id")
        
        person = await self.find_one(
            {"_id": person_oid},
            raise_404=True,
            error_message="Person not found"
        )
        
        pipeline = [
            {"$match": {"_id": person_oid}},
            {
                "$graphLookup": {
                    "from": "genealogy_relationships",
                    "startWith": "$_id",
                    "connectFromField": "_id",
                    "connectToField": "person1_id",
                    "as": "descendants",
                    "maxDepth": max_depth,
                    "depthField": "generation"
                }
            },
            {
                "$graphLookup": {
                    "from": "genealogy_relationships",
                    "startWith": "$_id",
                    "connectFromField": "_id",
                    "connectToField": "person2_id",
                    "as": "ancestors",
                    "maxDepth": max_depth,
                    "depthField": "generation"
                }
            },
            {
                "$lookup": {
                    "from": "genealogy_persons",
                    "localField": "descendants.person2_id",
                    "foreignField": "_id",
                    "as": "descendant_persons"
                }
            },
            {
                "$lookup": {
                    "from": "genealogy_persons",
                    "localField": "ancestors.person1_id",
                    "foreignField": "_id",
                    "as": "ancestor_persons"
                }
            }
        ]
        
        result = await self.aggregate(pipeline)
        
        if not result:
            raise HTTPException(status_code=404, detail="Person not found")
        
        return result[0]
    
    async def get_descendants(
        self,
        person_id: str,
        max_depth: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Get all descendants using aggregation pipeline.
        
        Finds all descendants of a person up to a specified depth
        using MongoDB aggregation.
        
        Args:
            person_id: Root person ID
            max_depth: Maximum depth to traverse (default: 3 generations)
            
        Returns:
            List of descendant person documents with relationship metadata
        """
        person_oid = self.validate_object_id(person_id, "person_id")
        
        await self.find_one(
            {"_id": person_oid},
            raise_404=True,
            error_message="Person not found"
        )
        
        pipeline = [
            {"$match": {"_id": person_oid}},
            {
                "$graphLookup": {
                    "from": "genealogy_relationships",
                    "startWith": "$_id",
                    "connectFromField": "_id",
                    "connectToField": "person1_id",
                    "as": "descendant_relationships",
                    "maxDepth": max_depth,
                    "depthField": "generation",
                    "restrictSearchWithMatch": {
                        "relationship_type": {"$in": ["parent", "child"]}
                    }
                }
            },
            {"$unwind": "$descendant_relationships"},
            {
                "$lookup": {
                    "from": "genealogy_persons",
                    "localField": "descendant_relationships.person2_id",
                    "foreignField": "_id",
                    "as": "descendant_person"
                }
            },
            {"$unwind": "$descendant_person"},
            {
                "$project": {
                    "_id": "$descendant_person._id",
                    "first_name": "$descendant_person.first_name",
                    "last_name": "$descendant_person.last_name",
                    "birth_date": "$descendant_person.birth_date",
                    "generation": "$descendant_relationships.generation",
                    "relationship_type": "$descendant_relationships.relationship_type"
                }
            },
            {"$sort": {"generation": 1, "last_name": 1}}
        ]
        
        return await self.aggregate(pipeline)

