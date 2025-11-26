from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
from fastapi import HTTPException

from app.repositories.base_repository import BaseRepository


class GenealogTreeMembershipRepository(BaseRepository):
    """
    Repository for genealogy tree memberships.
    Manages user access and roles within family trees.
    """
    
    def __init__(self):
        super().__init__("genealogy_tree_memberships")
    
    async def find_by_tree_and_user(
        self,
        tree_id: str,
        user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Find membership for a specific user in a tree.
        
        Args:
            tree_id: String representation of tree ID
            user_id: String representation of user ID
            
        Returns:
            Membership document if found
        """
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_one(
            {"tree_id": tree_oid, "user_id": user_oid},
            raise_404=False
        )
    
    async def find_by_tree(
        self,
        tree_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Find all members of a tree.
        
        Args:
            tree_id: String representation of tree ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of tree memberships
        """
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        return await self.find_many(
            {"tree_id": tree_oid},
            skip=skip,
            limit=limit,
            sort_by="joined_at",
            sort_order=-1
        )
    
    async def create_membership(
        self,
        tree_id: str,
        user_id: str,
        role: str = "member",
        granted_by: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new tree membership.
        
        Args:
            tree_id: String representation of tree ID
            user_id: String representation of user ID
            role: User's role in the tree (owner, member, viewer)
            granted_by: Optional user ID who granted access
            
        Returns:
            Created membership document
        """
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        granted_by_oid = self.validate_object_id(granted_by, "granted_by") if granted_by else user_oid
        
        membership_data = {
            "tree_id": tree_oid,
            "user_id": user_oid,
            "role": role,
            "joined_at": datetime.utcnow(),
            "granted_by": granted_by_oid
        }
        
        return await self.create(membership_data)



class GenealogyPersonRepository(BaseRepository):
    """Repository for genealogy persons."""
    
    def __init__(self):
        super().__init__("genealogy_persons")
    
    async def find_by_tree(
        self,
        tree_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Find all persons in a family tree."""
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        return await self.find_many(
            {"family_id": tree_oid},
            skip=skip,
            limit=limit,
            sort_by="last_name",
            sort_order=1
        )

    async def find_by_trees(
        self,
        tree_ids: List[str],
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Find all persons in multiple family trees."""
        tree_oids = self.validate_object_ids(tree_ids, "tree_ids")
        return await self.find_many(
            {"family_id": {"$in": tree_oids}},
            skip=skip,
            limit=limit,
            sort_by="last_name",
            sort_order=1
        )



class GenealogyRelationshipRepository(BaseRepository):
    """Repository for genealogy relationships."""
    
    def __init__(self):
        super().__init__("genealogy_relationships")
    
    async def find_by_tree(
        self,
        tree_id: str,
        person_id: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Find all relationships in a family tree, optionally filtered by person."""
        tree_oid = self.validate_object_id(tree_id, "tree_id")
        query = {"family_id": tree_oid}
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            # Find relationships where person is either person1 or person2
            query["$or"] = [
                {"person1_id": person_oid},
                {"person2_id": person_oid}
            ]
            
        return await self.find_many(
            query,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )

    async def find_by_trees(
        self,
        tree_ids: List[str],
        person_id: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Find all relationships in multiple family trees, optionally filtered by person."""
        tree_oids = self.validate_object_ids(tree_ids, "tree_ids")
        query = {"family_id": {"$in": tree_oids}}
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            # Find relationships where person is either person1 or person2
            query["$or"] = [
                {"person1_id": person_oid},
                {"person2_id": person_oid}
            ]
            
        return await self.find_many(
            query,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )



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



