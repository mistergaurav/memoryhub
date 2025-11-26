from typing import List, Optional, Dict, Set, Tuple
from bson import ObjectId
from datetime import datetime

from app.repositories.family_repository import (
    GenealogyPersonRepository,
    GenealogyRelationshipRepository,
    GenealogyTreeRepository
)
from app.models.family.genealogy import RelationshipType

class GenealogyLogicService:
    def __init__(self):
        self.person_repo = GenealogyPersonRepository()
        self.relationship_repo = GenealogyRelationshipRepository()
        self.tree_repo = GenealogyTreeRepository()

    async def validate_relationship(
        self, 
        person_id: str, 
        relationship_type: RelationshipType, 
        related_person_id: str,
        is_biological: bool = True
    ) -> None:
        """
        Validates if a relationship can be created based on biological constraints.
        Raises ValueError if validation fails.
        """
        if relationship_type == RelationshipType.PARENT and is_biological:
            # Check if person already has biological parents
            parents = await self.relationship_repo.find_parents(person_id)
            bio_parents = [p for p in parents if p.get("is_biological", True)]
            
            # Get gender of the new parent
            new_parent = await self.person_repo.find_by_id(related_person_id)
            if not new_parent:
                raise ValueError("Related person not found")
                
            new_parent_gender = new_parent.get("gender")
            
            for parent_rel in bio_parents:
                parent_id = parent_rel["person2_id"] if str(parent_rel["person1_id"]) == person_id else parent_rel["person1_id"]
                parent = await self.person_repo.find_by_id(str(parent_id))
                
                if parent and parent.get("gender") == new_parent_gender:
                    raise ValueError(f"Person already has a biological {new_parent_gender} parent")

    async def propagate_tree_merge(self, source_user_id: str, target_user_id: str, depth: int = 4):
        """
        Intelligently merges the family tree of target_user into source_user's tree.
        This is triggered when source_user links target_user (e.g. as a father).
        
        Args:
            source_user_id: The user who is adding the link (User A)
            target_user_id: The user being linked (User B)
            depth: How many generations to traverse (default 4)
        """
        # 1. Get the "Self" person for both users in their respective trees
        source_self = await self.person_repo.find_one({
            "linked_user_id": ObjectId(source_user_id),
            "family_id": ObjectId(source_user_id)
        })
        
        target_self = await self.person_repo.find_one({
            "linked_user_id": ObjectId(target_user_id),
            "family_id": ObjectId(target_user_id)
        })
        
        if not source_self or not target_self:
            return # Cannot merge if profiles don't exist
            
        # 2. Start Traversal from Target Self
        # We need to map Target Tree Person IDs -> Source Tree Person IDs to avoid duplicates
        # Map: { str(target_person_id): str(source_person_id) }
        id_map = {str(target_self["_id"]): str(source_self["_id"])}
        
        # We also need to know the "Self" representation of Target in Source's tree
        # (This should have been created by the approval process already, but let's find it)
        target_in_source = await self.person_repo.find_one({
            "linked_user_id": ObjectId(target_user_id),
            "family_id": ObjectId(source_user_id)
        })
        
        if target_in_source:
            id_map[str(target_self["_id"])] = str(target_in_source["_id"])
            
        await self._recursive_merge(
            current_person_id=str(target_self["_id"]),
            target_family_id=str(target_self["family_id"]),
            source_family_id=str(source_self["family_id"]),
            id_map=id_map,
            current_depth=0,
            max_depth=depth,
            source_user_id=source_user_id
        )

    async def _recursive_merge(
        self,
        current_person_id: str,
        target_family_id: str,
        source_family_id: str,
        id_map: Dict[str, str],
        current_depth: int,
        max_depth: int,
        source_user_id: str
    ):
        if current_depth >= max_depth:
            return

        # Get all relationships for this person in the TARGET tree
        relationships = await self.relationship_repo.find_by_person(current_person_id)
        
        for rel in relationships:
            # Identify the relative
            is_p1 = str(rel["person1_id"]) == current_person_id
            relative_id = str(rel["person2_id"]) if is_p1 else str(rel["person1_id"])
            
            if relative_id in id_map:
                continue # Already processed
                
            # Fetch relative details
            relative = await self.person_repo.find_by_id(relative_id)
            if not relative:
                continue
                
            # Create/Find this relative in SOURCE tree
            # First, check if they are a platform user linked person
            new_person_id = None
            if relative.get("linked_user_id"):
                existing_in_source = await self.person_repo.find_one({
                    "linked_user_id": relative["linked_user_id"],
                    "family_id": ObjectId(source_family_id)
                })
                if existing_in_source:
                    new_person_id = str(existing_in_source["_id"])
            
            if not new_person_id:
                # Create copy
                new_person_data = {
                    "family_id": ObjectId(source_family_id),
                    "first_name": relative.get("first_name"),
                    "last_name": relative.get("last_name"),
                    "maiden_name": relative.get("maiden_name"),
                    "gender": relative.get("gender"),
                    "birth_date": relative.get("birth_date"),
                    "birth_place": relative.get("birth_place"),
                    "death_date": relative.get("death_date"),
                    "death_place": relative.get("death_place"),
                    "is_alive": relative.get("is_alive"),
                    "biography": relative.get("biography"),
                    "photo_url": relative.get("photo_url"),
                    "occupation": relative.get("occupation"),
                    "notes": relative.get("notes"),
                    "linked_user_id": relative.get("linked_user_id"),
                    "source": "import", # Mark as imported
                    "approval_status": "approved", # Auto-approve imported historical figures
                    "created_by": ObjectId(source_user_id),
                    "created_at": datetime.utcnow()
                }
                new_person = await self.person_repo.create(new_person_data)
                new_person_id = str(new_person["_id"])
            
            # Update Map
            id_map[relative_id] = new_person_id
            
            # Create Relationship in Source Tree
            # Map the IDs
            source_p1 = id_map[str(rel["person1_id"])]
            source_p2 = id_map[str(rel["person2_id"])]
            
            # Check if relationship exists
            existing_rel = await self.relationship_repo.find_one({
                "family_id": ObjectId(source_family_id),
                "$or": [
                    {"person1_id": ObjectId(source_p1), "person2_id": ObjectId(source_p2)},
                    {"person1_id": ObjectId(source_p2), "person2_id": ObjectId(source_p1)}
                ]
            })
            
            if not existing_rel:
                new_rel_data = {
                    "family_id": ObjectId(source_family_id),
                    "person1_id": ObjectId(source_p1),
                    "person2_id": ObjectId(source_p2),
                    "relationship_type": rel["relationship_type"],
                    "is_biological": rel.get("is_biological", True),
                    "notes": rel.get("notes"),
                    "created_by": ObjectId(source_user_id),
                    "created_at": datetime.utcnow()
                }
                await self.relationship_repo.create(new_rel_data)
                
            # Recurse
            await self._recursive_merge(
                current_person_id=relative_id,
                target_family_id=target_family_id,
                source_family_id=source_family_id,
                id_map=id_map,
                current_depth=current_depth + 1,
                max_depth=max_depth,
                source_user_id=source_user_id
            )
