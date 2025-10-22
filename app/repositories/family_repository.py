from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime, timedelta
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


class FamilyAlbumsRepository(BaseRepository):
    """
    Repository for family albums with photo management.
    Provides access control, privacy checks, and photo operations.
    """
    
    def __init__(self):
        super().__init__("family_albums")
    
    async def find_accessible_albums(
        self,
        user_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all albums the user has access to (owned, member, or public).
        
        Args:
            user_id: String representation of user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of accessible albums
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_many(
            {
                "$or": [
                    {"created_by": user_oid},
                    {"member_ids": user_oid},
                    {"privacy": "public"}
                ]
            },
            skip=skip,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def count_accessible_albums(self, user_id: str) -> int:
        """Count total albums accessible to user."""
        user_oid = self.validate_object_id(user_id, "user_id")
        return await self.count({
            "$or": [
                {"created_by": user_oid},
                {"member_ids": user_oid},
                {"privacy": "public"}
            ]
        })
    
    async def check_album_ownership(
        self,
        album_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns an album.
        
        Args:
            album_id: String representation of album ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        album = await self.find_one(
            {"_id": album_oid},
            raise_404=True,
            error_message="Album not found"
        )
        assert album is not None
        
        is_owner = album.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the album owner can perform this action"
            )
        
        return is_owner
    
    async def check_album_access(
        self,
        album_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user has access to view an album.
        
        Args:
            album_id: String representation of album ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if no access
            
        Returns:
            True if user has access
            
        Raises:
            HTTPException: If user has no access and raise_error=True
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        album = await self.find_one(
            {"_id": album_oid},
            raise_404=True,
            error_message="Album not found"
        )
        assert album is not None
        
        is_owner = album.get("created_by") == user_oid
        is_member = user_oid in album.get("member_ids", [])
        is_public = album.get("privacy") == "public"
        has_access = is_owner or is_member or is_public
        
        if not has_access and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You do not have access to this album"
            )
        
        return has_access
    
    async def add_photo_to_album(
        self,
        album_id: str,
        photo_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Add a photo to an album using atomic operation.
        
        Args:
            album_id: String representation of album ID
            photo_data: Photo document to add
            
        Returns:
            Updated album document
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        
        await self.collection.update_one(
            {"_id": album_oid},
            {
                "$push": {"photos": photo_data},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_album = await self.find_one({"_id": album_oid}, raise_404=True)
        assert updated_album is not None
        return updated_album
    
    async def remove_photo_from_album(
        self,
        album_id: str,
        photo_id: str
    ) -> Dict[str, Any]:
        """
        Remove a photo from an album using atomic operation.
        
        Args:
            album_id: String representation of album ID
            photo_id: String representation of photo ID
            
        Returns:
            Updated album document
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        photo_oid = self.validate_object_id(photo_id, "photo_id")
        
        await self.collection.update_one(
            {"_id": album_oid},
            {
                "$pull": {"photos": {"_id": photo_oid}},
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        updated_album = await self.find_one({"_id": album_oid}, raise_404=True)
        assert updated_album is not None
        return updated_album
    
    async def toggle_photo_like(
        self,
        album_id: str,
        photo_id: str,
        user_id: str,
        add_like: bool = True
    ) -> bool:
        """
        Add or remove a like from a photo.
        
        Args:
            album_id: String representation of album ID
            photo_id: String representation of photo ID
            user_id: String representation of user ID
            add_like: True to add like, False to remove
            
        Returns:
            True if operation was successful
        """
        album_oid = self.validate_object_id(album_id, "album_id")
        photo_oid = self.validate_object_id(photo_id, "photo_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_like else "$pull"
        
        result = await self.collection.update_one(
            {"_id": album_oid, "photos._id": photo_oid},
            {operation: {"photos.$.likes": user_oid}}
        )
        
        return result.modified_count > 0


class FamilyCalendarRepository(BaseRepository):
    """
    Repository for family calendar events with recurrence and conflict detection.
    Provides timezone-aware queries and attendee management.
    """
    
    def __init__(self):
        super().__init__("family_events")
    
    async def find_user_events(
        self,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Find all events for a user (created or attending).
        
        Args:
            user_id: String representation of user ID
            start_date: Optional filter by start date
            end_date: Optional filter by end date
            event_type: Optional filter by event type
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of events
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ]
        }
        
        if start_date:
            filter_dict["event_date"] = {"$gte": start_date}
        if end_date:
            if "event_date" in filter_dict:
                filter_dict["event_date"]["$lte"] = end_date
            else:
                filter_dict["event_date"] = {"$lte": end_date}
        if event_type:
            filter_dict["event_type"] = event_type
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="event_date",
            sort_order=1
        )
    
    async def count_user_events(
        self,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_type: Optional[str] = None
    ) -> int:
        """Count events matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ]
        }
        
        if start_date:
            filter_dict["event_date"] = {"$gte": start_date}
        if end_date:
            if "event_date" in filter_dict:
                filter_dict["event_date"]["$lte"] = end_date
            else:
                filter_dict["event_date"] = {"$lte": end_date}
        if event_type:
            filter_dict["event_type"] = event_type
        
        return await self.count(filter_dict)
    
    async def check_event_ownership(
        self,
        event_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns an event.
        
        Args:
            event_id: String representation of event ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        event_oid = self.validate_object_id(event_id, "event_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        event = await self.find_one(
            {"_id": event_oid},
            raise_404=True,
            error_message="Event not found"
        )
        assert event is not None
        
        is_owner = event.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the event creator can perform this action"
            )
        
        return is_owner
    
    async def detect_conflicts(
        self,
        user_id: str,
        event_date: datetime,
        end_date: Optional[datetime] = None,
        exclude_event_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Detect scheduling conflicts for a user.
        
        Args:
            user_id: String representation of user ID
            event_date: Start date/time of the event
            end_date: Optional end date/time
            exclude_event_id: Optional event ID to exclude from conflict check
            
        Returns:
            List of conflicting events
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        event_end = end_date or event_date
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"attendee_ids": user_oid}
            ],
            "$or": [
                {
                    "event_date": {"$lte": event_date},
                    "end_date": {"$gte": event_date}
                },
                {
                    "event_date": {"$lte": event_end},
                    "end_date": {"$gte": event_end}
                },
                {
                    "event_date": {"$gte": event_date},
                    "event_date": {"$lte": event_end}
                }
            ]
        }
        
        if exclude_event_id:
            exclude_oid = self.validate_object_id(exclude_event_id, "exclude_event_id")
            filter_dict["_id"] = {"$ne": exclude_oid}
        
        return await self.find_many(filter_dict, limit=10)
    
    async def get_upcoming_birthdays(
        self,
        user_id: str,
        days_ahead: int = 30
    ) -> List[Dict[str, Any]]:
        """
        Get upcoming birthdays for a user.
        
        Args:
            user_id: String representation of user ID
            days_ahead: Number of days to look ahead
            
        Returns:
            List of birthday events
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        end_date = datetime.utcnow() + timedelta(days=days_ahead)
        
        return await self.find_many(
            {
                "event_type": "birthday",
                "event_date": {"$lte": end_date},
                "$or": [
                    {"created_by": user_oid},
                    {"attendee_ids": user_oid}
                ]
            },
            sort_by="event_date",
            sort_order=1,
            limit=50
        )


class FamilyMilestonesRepository(BaseRepository):
    """
    Repository for family milestones with photo management and like functionality.
    Provides queries for milestone tracking and social engagement.
    """
    
    def __init__(self):
        super().__init__("family_milestones")
    
    async def find_user_milestones(
        self,
        user_id: str,
        person_id: Optional[str] = None,
        milestone_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find milestones for a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            person_id: Optional filter by person ID
            milestone_type: Optional filter by milestone type
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of milestones
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"family_circle_ids": {"$exists": True}}
            ]
        }
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            filter_dict["person_id"] = person_oid
        
        if milestone_type:
            filter_dict["milestone_type"] = milestone_type
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="milestone_date",
            sort_order=-1
        )
    
    async def count_user_milestones(
        self,
        user_id: str,
        person_id: Optional[str] = None,
        milestone_type: Optional[str] = None
    ) -> int:
        """Count milestones matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"created_by": user_oid},
                {"family_circle_ids": {"$exists": True}}
            ]
        }
        
        if person_id:
            person_oid = self.validate_object_id(person_id, "person_id")
            filter_dict["person_id"] = person_oid
        
        if milestone_type:
            filter_dict["milestone_type"] = milestone_type
        
        return await self.count(filter_dict)
    
    async def check_milestone_ownership(
        self,
        milestone_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a milestone.
        
        Args:
            milestone_id: String representation of milestone ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        milestone = await self.find_one(
            {"_id": milestone_oid},
            raise_404=True,
            error_message="Milestone not found"
        )
        assert milestone is not None
        
        is_owner = milestone.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the milestone creator can perform this action"
            )
        
        return is_owner
    
    async def toggle_like(
        self,
        milestone_id: str,
        user_id: str,
        add_like: bool = True
    ) -> bool:
        """
        Toggle like on a milestone.
        
        Args:
            milestone_id: String representation of milestone ID
            user_id: String representation of user ID
            add_like: True to add like, False to remove
            
        Returns:
            True if operation successful
        """
        milestone_oid = self.validate_object_id(milestone_id, "milestone_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_like else "$pull"
        
        result = await self.collection.update_one(
            {"_id": milestone_oid},
            {operation: {"likes": user_oid}}
        )
        
        return result.modified_count > 0


class FamilyRecipesRepository(BaseRepository):
    """
    Repository for family recipes with ratings and favorites management.
    Provides queries for recipe tracking and social engagement.
    """
    
    def __init__(self):
        super().__init__("family_recipes")
    
    async def find_user_recipes(
        self,
        user_id: str,
        category: Optional[str] = None,
        difficulty: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find recipes accessible to a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            category: Optional filter by category
            difficulty: Optional filter by difficulty
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of recipes
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if difficulty:
            filter_dict["difficulty"] = difficulty
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def count_user_recipes(
        self,
        user_id: str,
        category: Optional[str] = None,
        difficulty: Optional[str] = None
    ) -> int:
        """Count recipes matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if difficulty:
            filter_dict["difficulty"] = difficulty
        
        return await self.count(filter_dict)
    
    async def check_recipe_ownership(
        self,
        recipe_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        recipe = await self.find_one(
            {"_id": recipe_oid},
            raise_404=True,
            error_message="Recipe not found"
        )
        assert recipe is not None
        
        is_owner = recipe.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the recipe creator can perform this action"
            )
        
        return is_owner
    
    async def toggle_favorite(
        self,
        recipe_id: str,
        user_id: str,
        add_favorite: bool = True
    ) -> bool:
        """
        Toggle favorite on a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            user_id: String representation of user ID
            add_favorite: True to add favorite, False to remove
            
        Returns:
            True if operation successful
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_favorite else "$pull"
        
        result = await self.collection.update_one(
            {"_id": recipe_oid},
            {operation: {"favorites": user_oid}}
        )
        
        return result.modified_count > 0
    
    async def add_rating(
        self,
        recipe_id: str,
        user_id: str,
        rating: int,
        comment: Optional[str] = None
    ) -> bool:
        """
        Add or update a rating for a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            user_id: String representation of user ID
            rating: Rating value (1-5)
            comment: Optional comment
            
        Returns:
            True if operation successful
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        await self.collection.update_one(
            {"_id": recipe_oid},
            {"$pull": {"ratings": {"user_id": user_oid}}}
        )
        
        result = await self.collection.update_one(
            {"_id": recipe_oid},
            {
                "$push": {
                    "ratings": {
                        "user_id": user_oid,
                        "rating": rating,
                        "comment": comment,
                        "created_at": datetime.utcnow()
                    }
                }
            }
        )
        
        return result.modified_count > 0
    
    async def increment_times_made(
        self,
        recipe_id: str
    ) -> bool:
        """
        Increment the times_made counter for a recipe.
        
        Args:
            recipe_id: String representation of recipe ID
            
        Returns:
            True if operation successful
        """
        recipe_oid = self.validate_object_id(recipe_id, "recipe_id")
        
        result = await self.collection.update_one(
            {"_id": recipe_oid},
            {"$inc": {"times_made": 1}}
        )
        
        return result.modified_count > 0


class FamilyTraditionsRepository(BaseRepository):
    """
    Repository for family traditions with follower management.
    Provides queries for tradition tracking and social engagement.
    """
    
    def __init__(self):
        super().__init__("family_traditions")
    
    async def find_user_traditions(
        self,
        user_id: str,
        category: Optional[str] = None,
        frequency: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find traditions accessible to a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            category: Optional filter by category
            frequency: Optional filter by frequency
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of traditions
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if frequency:
            filter_dict["frequency"] = frequency
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def count_user_traditions(
        self,
        user_id: str,
        category: Optional[str] = None,
        frequency: Optional[str] = None
    ) -> int:
        """Count traditions matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {}
        
        if category:
            filter_dict["category"] = category
        if frequency:
            filter_dict["frequency"] = frequency
        
        return await self.count(filter_dict)
    
    async def check_tradition_ownership(
        self,
        tradition_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a tradition.
        
        Args:
            tradition_id: String representation of tradition ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        tradition_oid = self.validate_object_id(tradition_id, "tradition_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        tradition = await self.find_one(
            {"_id": tradition_oid},
            raise_404=True,
            error_message="Tradition not found"
        )
        assert tradition is not None
        
        is_owner = tradition.get("created_by") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the tradition creator can perform this action"
            )
        
        return is_owner
    
    async def toggle_follow(
        self,
        tradition_id: str,
        user_id: str,
        add_follow: bool = True
    ) -> bool:
        """
        Toggle follow on a tradition.
        
        Args:
            tradition_id: String representation of tradition ID
            user_id: String representation of user ID
            add_follow: True to follow, False to unfollow
            
        Returns:
            True if operation successful
        """
        tradition_oid = self.validate_object_id(tradition_id, "tradition_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_follow else "$pull"
        
        result = await self.collection.update_one(
            {"_id": tradition_oid},
            {operation: {"followers": user_oid}}
        )
        
        return result.modified_count > 0


class LegacyLettersRepository(BaseRepository):
    """
    Repository for legacy letters with delivery and read tracking.
    Provides queries for sent and received letters with privacy controls.
    """
    
    def __init__(self):
        super().__init__("legacy_letters")
    
    async def find_sent_letters(
        self,
        author_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all letters sent by a user.
        
        Args:
            author_id: String representation of author user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of sent letters
        """
        author_oid = self.validate_object_id(author_id, "author_id")
        
        return await self.find_many(
            {"author_id": author_oid},
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def count_sent_letters(
        self,
        author_id: str
    ) -> int:
        """Count letters sent by a user."""
        author_oid = self.validate_object_id(author_id, "author_id")
        
        return await self.count({"author_id": author_oid})
    
    async def find_received_letters(
        self,
        recipient_id: str,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all delivered letters received by a user.
        
        Args:
            recipient_id: String representation of recipient user ID
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of received letters
        """
        recipient_oid = self.validate_object_id(recipient_id, "recipient_id")
        
        return await self.find_many(
            {
                "recipient_ids": recipient_oid,
                "status": {"$in": ["delivered", "read"]}
            },
            skip=skip,
            limit=limit,
            sort_by="delivered_at",
            sort_order=-1
        )
    
    async def count_received_letters(
        self,
        recipient_id: str
    ) -> int:
        """Count delivered letters received by a user."""
        recipient_oid = self.validate_object_id(recipient_id, "recipient_id")
        
        return await self.count({
            "recipient_ids": recipient_oid,
            "status": {"$in": ["delivered", "read"]}
        })
    
    async def check_letter_ownership(
        self,
        letter_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user is the author of a letter.
        
        Args:
            letter_id: String representation of letter ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not author
            
        Returns:
            True if user is author
            
        Raises:
            HTTPException: If user is not author and raise_error=True
        """
        letter_oid = self.validate_object_id(letter_id, "letter_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        letter = await self.find_one(
            {"_id": letter_oid},
            raise_404=True,
            error_message="Letter not found"
        )
        assert letter is not None
        
        is_author = letter.get("author_id") == user_oid
        
        if not is_author and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the letter author can perform this action"
            )
        
        return is_author
    
    async def mark_as_read(
        self,
        letter_id: str,
        user_id: str
    ) -> bool:
        """
        Mark a letter as read by a recipient.
        
        Args:
            letter_id: String representation of letter ID
            user_id: String representation of user ID
            
        Returns:
            True if operation successful
        """
        letter_oid = self.validate_object_id(letter_id, "letter_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        result = await self.collection.update_one(
            {"_id": letter_oid},
            {
                "$addToSet": {"read_by": user_oid},
                "$set": {"status": "read"}
            }
        )
        
        return result.modified_count > 0
    
    async def check_recipient_access(
        self,
        letter_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user is a recipient of a letter.
        
        Args:
            letter_id: String representation of letter ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not recipient
            
        Returns:
            True if user is recipient
            
        Raises:
            HTTPException: If user is not recipient and raise_error=True
        """
        letter_oid = self.validate_object_id(letter_id, "letter_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        letter = await self.find_one(
            {"_id": letter_oid},
            raise_404=True,
            error_message="Letter not found"
        )
        assert letter is not None
        
        is_recipient = user_oid in letter.get("recipient_ids", [])
        
        if not is_recipient and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You are not a recipient of this letter"
            )
        
        return is_recipient


class HubItemsRepository(BaseRepository):
    """
    Repository for collaborative hub items with privacy controls and social features.
    Provides access control, view tracking, and engagement features (likes, bookmarks).
    """
    
    def __init__(self):
        super().__init__("hub_items")
    
    async def find_user_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all hub items owned by a user with optional filtering.
        
        Args:
            user_id: String representation of user ID
            item_type: Optional filter by item type
            privacy: Optional filter by privacy level
            tag: Optional filter by tag
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of hub items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {"owner_id": user_oid}
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def find_accessible_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Find all hub items accessible to a user (owned or public).
        
        Args:
            user_id: String representation of user ID
            item_type: Optional filter by item type
            privacy: Optional filter by privacy level
            tag: Optional filter by tag
            skip: Number of documents to skip
            limit: Maximum number to return
            
        Returns:
            List of accessible hub items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"owner_id": user_oid},
                {"privacy": "public"}
            ]
        }
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.find_many(
            filter_dict,
            skip=skip,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def count_user_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None
    ) -> int:
        """Count items owned by user matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {"owner_id": user_oid}
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.count(filter_dict)
    
    async def count_accessible_items(
        self,
        user_id: str,
        item_type: Optional[str] = None,
        privacy: Optional[str] = None,
        tag: Optional[str] = None
    ) -> int:
        """Count items accessible to user matching criteria."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"owner_id": user_oid},
                {"privacy": "public"}
            ]
        }
        
        if item_type:
            filter_dict["item_type"] = item_type
        if privacy:
            filter_dict["privacy"] = privacy
        if tag:
            filter_dict["tags"] = tag
        
        return await self.count(filter_dict)
    
    async def check_item_ownership(
        self,
        item_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user owns a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if not owner
            
        Returns:
            True if user is owner
            
        Raises:
            HTTPException: If user is not owner and raise_error=True
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        item = await self.find_one(
            {"_id": item_oid},
            raise_404=True,
            error_message="Hub item not found"
        )
        assert item is not None
        
        is_owner = item.get("owner_id") == user_oid
        
        if not is_owner and raise_error:
            raise HTTPException(
                status_code=403,
                detail="Only the item owner can perform this action"
            )
        
        return is_owner
    
    async def check_item_access(
        self,
        item_id: str,
        user_id: str,
        raise_error: bool = True
    ) -> bool:
        """
        Check if user has access to view a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            raise_error: Whether to raise HTTPException if no access
            
        Returns:
            True if user has access
            
        Raises:
            HTTPException: If user has no access and raise_error=True
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        item = await self.find_one(
            {"_id": item_oid},
            raise_404=True,
            error_message="Hub item not found"
        )
        assert item is not None
        
        is_owner = item.get("owner_id") == user_oid
        is_public = item.get("privacy") == "public"
        has_access = is_owner or is_public
        
        if not has_access and raise_error:
            raise HTTPException(
                status_code=403,
                detail="You do not have access to this hub item"
            )
        
        return has_access
    
    async def increment_view_count(
        self,
        item_id: str
    ) -> bool:
        """
        Increment the view count for a hub item.
        
        Args:
            item_id: String representation of item ID
            
        Returns:
            True if operation successful
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        
        result = await self.collection.update_one(
            {"_id": item_oid},
            {"$inc": {"view_count": 1}}
        )
        
        return result.modified_count > 0
    
    async def toggle_like(
        self,
        item_id: str,
        user_id: str,
        add_like: bool = True
    ) -> bool:
        """
        Toggle like on a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            add_like: True to add like, False to remove
            
        Returns:
            True if operation successful
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_like else "$pull"
        
        result = await self.collection.update_one(
            {"_id": item_oid},
            {operation: {"likes": user_oid}}
        )
        
        return result.modified_count > 0
    
    async def toggle_bookmark(
        self,
        item_id: str,
        user_id: str,
        add_bookmark: bool = True
    ) -> bool:
        """
        Toggle bookmark on a hub item.
        
        Args:
            item_id: String representation of item ID
            user_id: String representation of user ID
            add_bookmark: True to add bookmark, False to remove
            
        Returns:
            True if operation successful
        """
        item_oid = self.validate_object_id(item_id, "item_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        operation = "$addToSet" if add_bookmark else "$pull"
        
        result = await self.collection.update_one(
            {"_id": item_oid},
            {operation: {"bookmarks": user_oid}}
        )
        
        return result.modified_count > 0
    
    async def search_items(
        self,
        user_id: str,
        query: str,
        item_types: Optional[List[str]] = None,
        tags: Optional[List[str]] = None,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Search hub items with text search and filters.
        
        Args:
            user_id: String representation of user ID
            query: Text search query
            item_types: Optional filter by item types
            tags: Optional filter by tags
            limit: Maximum number of results
            
        Returns:
            List of matching hub items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        filter_dict: Dict[str, Any] = {
            "$or": [
                {"owner_id": user_oid},
                {"privacy": "public"}
            ],
            "$text": {"$search": query}
        }
        
        if item_types:
            filter_dict["item_type"] = {"$in": item_types}
        if tags:
            filter_dict["tags"] = {"$in": tags}
        
        return await self.find_many(
            filter_dict,
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
    
    async def get_stats(
        self,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Get statistics for user's hub items.
        
        Args:
            user_id: String representation of user ID
            
        Returns:
            Dictionary with statistics
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        pipeline = [
            {"$match": {"owner_id": user_oid}},
            {
                "$group": {
                    "_id": "$item_type",
                    "count": {"$sum": 1}
                }
            }
        ]
        
        items_by_type = await self.aggregate(pipeline)
        
        total_items = sum(item["count"] for item in items_by_type)
        items_by_type_dict = {item["_id"]: item["count"] for item in items_by_type}
        
        total_views_pipeline = [
            {"$match": {"owner_id": user_oid}},
            {
                "$group": {
                    "_id": None,
                    "total_views": {"$sum": "$view_count"},
                    "total_likes": {"$sum": {"$size": {"$ifNull": ["$likes", []]}}}
                }
            }
        ]
        
        engagement = await self.aggregate(total_views_pipeline)
        total_views = engagement[0]["total_views"] if engagement else 0
        total_likes = engagement[0]["total_likes"] if engagement else 0
        
        return {
            "total_items": total_items,
            "items_by_type": items_by_type_dict,
            "total_views": total_views,
            "total_likes": total_likes
        }
    
    async def get_recent_activity(
        self,
        user_id: str,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get recent activity for user's hub items.
        
        Args:
            user_id: String representation of user ID
            limit: Maximum number of activity items
            
        Returns:
            List of recent activity items
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_many(
            {"owner_id": user_oid},
            limit=limit,
            sort_by="updated_at",
            sort_order=-1
        )
