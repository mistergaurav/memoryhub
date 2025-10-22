from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from .base_repository import BaseRepository


class FamilyRepository(BaseRepository):
    """
    Repository for Family Hub operations.
    Provides family-specific queries and authorization helpers.
    """
    
    def __init__(self):
        super().__init__("family_circles")
    
    async def find_by_owner(
        self,
        owner_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all family circles owned by a user.
        
        Args:
            owner_id: String representation of user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of family circles
        """
        owner_oid = self.validate_object_id(owner_id, "owner_id")
        return await self.find_many(
            {"owner_id": owner_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_by_member(
        self,
        member_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all family circles where user is a member.
        
        Args:
            member_id: String representation of user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of family circles
        """
        member_oid = self.validate_object_id(member_id, "member_id")
        return await self.find_many(
            {"member_ids": member_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def check_owner(
        self,
        circle_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user is the owner of a family circle.
        
        Args:
            circle_id: String representation of circle ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        circle = await self.find_one(
            {"_id": circle_oid},
            raise_404=True,
            error_message="Family circle not found"
        )
        assert circle is not None
        
        is_owner = circle.get("owner_id") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the circle owner can perform this action"
            )
        
        return is_owner
    
    async def check_member_access(
        self,
        circle_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user has access to a family circle (owner or member).
        
        Args:
            circle_id: String representation of circle ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if no access
            
        Returns:
            True if user has access
            
        Raises:
            HTTPException: If user has no access and raise_error=True
        """
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        circle = await self.find_one(
            {"_id": circle_oid},
            raise_404=True,
            error_message="Family circle not found"
        )
        assert circle is not None
        
        is_owner = circle.get("owner_id") == user_oid
        is_member = user_oid in circle.get("member_ids", [])
        has_access = is_owner or is_member
        
        if not has_access and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You do not have access to this family circle"
            )
        
        return has_access
    
    async def add_member(
        self,
        circle_id: str,
        member_id: str,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Add a member to a family circle (owner only).
        
        Args:
            circle_id: String representation of circle ID
            member_id: String representation of member to add
            user_id: String representation of requesting user ID
            
        Returns:
            Updated circle document
            
        Raises:
            HTTPException: If user is not owner or member already exists
        """
        await self.check_owner(circle_id, user_id, raise_error=True)
        
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        member_oid = self.validate_object_id(member_id, "member_id")
        
        circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert circle is not None
        
        if member_oid in circle.get("member_ids", []):
            raise HTTPException(
                status_code=400,
                detail="User is already a member of this circle"
            )
        
        result = await self.collection.update_one(
            {"_id": circle_oid},
            {
                "$push": {"member_ids": member_oid},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert updated_circle is not None
        return updated_circle
    
    async def remove_member(
        self,
        circle_id: str,
        member_id: str,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Remove a member from a family circle (owner only).
        
        Args:
            circle_id: String representation of circle ID
            member_id: String representation of member to remove
            user_id: String representation of requesting user ID
            
        Returns:
            Updated circle document
            
        Raises:
            HTTPException: If user is not owner or trying to remove owner
        """
        await self.check_owner(circle_id, user_id, raise_error=True)
        
        circle_oid = self.validate_object_id(circle_id, "circle_id")
        member_oid = self.validate_object_id(member_id, "member_id")
        
        circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert circle is not None
        
        if circle.get("owner_id") == member_oid:
            raise HTTPException(
                status_code=400,
                detail="Cannot remove the circle owner"
            )
        
        result = await self.collection.update_one(
            {"_id": circle_oid},
            {
                "$pull": {"member_ids": member_oid},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_circle = await self.find_one({"_id": circle_oid}, raise_404=True)
        assert updated_circle is not None
        return updated_circle


class FamilyRelationshipRepository(BaseRepository):
    """Repository for family relationships."""
    
    def __init__(self):
        super().__init__("family_relationships")
    
    async def find_by_user(
        self,
        user_id: str,
        relation_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all relationships for a user.
        
        Args:
            user_id: String representation of user ID
            relation_type: Optional filter by relation type
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of relationships
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {"user_id": user_oid}
        if relation_type:
            filter_dict["relation_type"] = relation_type
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def check_relationship_exists(
        self,
        user_id: str,
        related_user_id: str
    ) -> bool:
        """
        Check if a relationship already exists.
        
        Args:
            user_id: String representation of user ID
            related_user_id: String representation of related user ID
            
        Returns:
            True if relationship exists
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        related_oid = self.validate_object_id(related_user_id, "related_user_id")
        
        return await self.exists({
            "user_id": user_oid,
            "related_user_id": related_oid
        })


class FamilyInvitationRepository(BaseRepository):
    """Repository for family invitations."""
    
    def __init__(self):
        super().__init__("family_invitations")
    
    async def find_by_token(
        self,
        token: str,
        raise_404: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Find invitation by token.
        
        Args:
            token: Invitation token
            raise_404: Whether to raise 404 if not found
            
        Returns:
            Invitation document
        """
        return await self.find_one(
            {"token": token},
            raise_404=raise_404,
            error_message="Invitation not found"
        )
    
    async def find_by_inviter(
        self,
        inviter_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all invitations sent by a user.
        
        Args:
            inviter_id: String representation of inviter user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of invitations
        """
        inviter_oid = self.validate_object_id(inviter_id, "inviter_id")
        return await self.find_many(
            {"inviter_id": inviter_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_by_invitee(
        self,
        invitee_email: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all invitations for an email address.
        
        Args:
            invitee_email: Email address of invitee
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of invitations
        """
        return await self.find_many(
            {"invitee_email": invitee_email.lower()},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )


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


class FamilyTimelineRepository(BaseRepository):
    """
    Repository for family timeline aggregation across multiple collections.
    Aggregates events from memories, milestones, events, recipes, traditions, and albums.
    """
    
    def __init__(self):
        super().__init__("memories")
    
    async def get_timeline_events(
        self,
        family_id: str,
        skip: int = 0,
        limit: int = 20,
        event_types: Optional[List[str]] = None,
        person_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Aggregate timeline events from multiple sources with pagination.
        
        This method combines events from:
        - memories
        - family_milestones
        - family_events
        - family_recipes
        - family_traditions
        - family_albums
        
        Args:
            family_id: Family circle ID to get events for
            skip: Number of events to skip for pagination
            limit: Maximum number of events to return
            event_types: Optional list of event types to include
            person_id: Optional filter by person/user ID
            start_date: Optional filter by start date
            end_date: Optional filter by end date
            
        Returns:
            PaginatedResponse dictionary with timeline events
        """
        family_oid = self.validate_object_id(family_id, "family_id")
        
        match_stage: Dict[str, Any] = {"family_circle_ids": family_oid}
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            match_stage["$or"] = [
                {"user_id": person_oid},
                {"created_by": person_oid},
                {"person_id": person_oid}
            ]
        
        if start_date:
            match_stage["created_at"] = {"$gte": start_date}
        
        if end_date:
            if "created_at" in match_stage:
                match_stage["created_at"]["$lte"] = end_date
            else:
                match_stage["created_at"] = {"$lte": end_date}
        
        collections_to_query = []
        if event_types:
            type_mapping = {
                "memory": "memories",
                "milestone": "family_milestones",
                "event": "family_events",
                "recipe": "family_recipes",
                "tradition": "family_traditions",
                "album": "family_albums"
            }
            collections_to_query = [type_mapping.get(t, t) for t in event_types if t in type_mapping]
        else:
            collections_to_query = [
                "memories", "family_milestones", "family_events",
                "family_recipes", "family_traditions", "family_albums"
            ]
        
        pipeline = [
            {"$match": match_stage},
            {
                "$lookup": {
                    "from": "users",
                    "localField": "user_id",
                    "foreignField": "_id",
                    "as": "user_info"
                }
            },
            {
                "$addFields": {
                    "event_type": "memory",
                    "event_date": "$created_at",
                    "person_name": {
                        "$ifNull": [
                            {"$arrayElemAt": ["$user_info.full_name", 0]},
                            None
                        ]
                    }
                }
            },
            {
                "$project": {
                    "_id": 1,
                    "type": "$event_type",
                    "title": 1,
                    "description": {"$substr": [{"$ifNull": ["$content", ""]}, 0, 200]},
                    "date": "$event_date",
                    "person_name": 1,
                    "photos": {"$slice": [{"$ifNull": ["$attachments", []]}, 3]},
                    "tags": 1
                }
            },
            {"$sort": {"date": -1}}
        ]
        
        return await self.aggregate_paginated(pipeline, skip=skip, limit=limit)


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


class HealthRecordsRepository(BaseRepository):
    """
    Repository for health records with privacy controls.
    Handles sharing permissions and privacy-aware queries.
    """
    
    def __init__(self):
        super().__init__("health_records")
    
    async def get_shared_health_records(
        self,
        user_id: str,
        shared_with_user_id: str
    ) -> List[Dict[str, Any]]:
        """
        Get health records shared with a specific user.
        
        Implements privacy controls by checking sharing permissions
        and filtering confidential records based on access rights.
        
        Args:
            user_id: Owner of the health records
            shared_with_user_id: User requesting access to the records
            
        Returns:
            List of health records that the requesting user has access to
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        shared_with_oid = self.validate_object_id(shared_with_user_id, "shared_with_user_id")
        
        pipeline = [
            {"$match": {"family_id": user_oid}},
            {
                "$lookup": {
                    "from": "health_record_shares",
                    "let": {"record_id": "$_id"},
                    "pipeline": [
                        {
                            "$match": {
                                "$expr": {
                                    "$and": [
                                        {"$eq": ["$record_id", "$$record_id"]},
                                        {"$eq": ["$shared_with_user_id", shared_with_oid]}
                                    ]
                                }
                            }
                        }
                    ],
                    "as": "share_permission"
                }
            },
            {
                "$match": {
                    "$or": [
                        {"is_confidential": False},
                        {"share_permission": {"$ne": []}}
                    ]
                }
            },
            {
                "$lookup": {
                    "from": "family_members",
                    "localField": "family_member_id",
                    "foreignField": "_id",
                    "as": "member_info"
                }
            },
            {
                "$addFields": {
                    "family_member_name": {
                        "$ifNull": [
                            {"$arrayElemAt": ["$member_info.name", 0]},
                            None
                        ]
                    }
                }
            },
            {
                "$project": {
                    "share_permission": 0,
                    "member_info": 0
                }
            },
            {"$sort": {"date": -1}}
        ]
        
        return await self.aggregate(pipeline)
