"""Repository for relationships with dual-row pattern."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from ..base_repository import BaseRepository


class RelationshipRepository(BaseRepository):
    """Repository for relationship operations using dual-row pattern."""
    
    def __init__(self):
        super().__init__("relationships")
    
    async def create_relationship_pair(
        self,
        user_id: str,
        related_user_id: str,
        relationship_type: str,
        relationship_label: Optional[str] = None,
        message: Optional[str] = None
    ) -> tuple[Dict[str, Any], Dict[str, Any]]:
        """
        Create dual-row relationship (one for each user).
        
        Args:
            user_id: Requester user ID
            related_user_id: Related user ID
            relationship_type: Type of relationship
            relationship_label: Optional custom label
            message: Optional invitation message
            
        Returns:
            Tuple of (requester_row, receiver_row)
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        related_oid = self.validate_object_id(related_user_id, "related_user_id")
        
        # Check if relationship already exists
        existing = await self.find_one(
            {
                "$or": [
                    {"user_id": user_oid, "related_user_id": related_oid},
                    {"user_id": related_oid, "related_user_id": user_oid}
                ]
            },
            raise_404=False
        )
        
        if existing:
            raise HTTPException(
                status_code=400,
                detail="Relationship already exists between these users"
            )
        
        metadata = {}
        if message:
            metadata["invitation_message"] = message
        
        # Create row for requester
        requester_row = {
            "user_id": user_oid,
            "related_user_id": related_oid,
            "relationship_type": relationship_type,
            "relationship_label": relationship_label,
            "status": "pending",
            "requester_id": user_oid,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "metadata": metadata
        }
        
        # Create row for receiver
        receiver_row = {
            "user_id": related_oid,
            "related_user_id": user_oid,
            "relationship_type": relationship_type,
            "relationship_label": relationship_label,
            "status": "pending",
            "requester_id": user_oid,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "metadata": metadata
        }
        
        # Insert both rows
        created_requester = await self.create(requester_row)
        created_receiver = await self.create(receiver_row)
        
        return (created_requester, created_receiver)
    
    async def find_by_user(
        self,
        user_id: str,
        status_filter: Optional[str] = None,
        relationship_type_filter: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Find all relationships for a user."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        query: Dict[str, Any] = {"user_id": user_oid}
        
        if status_filter:
            query["status"] = status_filter
        
        if relationship_type_filter:
            query["relationship_type"] = relationship_type_filter
        
        return await self.find_many(
            query,
            skip=skip,
            limit=limit,
            sort_by="created_at",
            sort_order=-1
        )
    
    async def find_pending_requests(
        self,
        user_id: str
    ) -> List[Dict[str, Any]]:
        """Find all pending relationship requests where user is the receiver."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        return await self.find_many(
            {
                "user_id": user_oid,
                "status": "pending",
                "requester_id": {"$ne": user_oid}  # Not the requester
            },
            sort_by="created_at",
            sort_order=-1
        )
    
    async def accept_relationship(
        self,
        relationship_id: str,
        user_id: str
    ) -> tuple[Dict[str, Any], Dict[str, Any]]:
        """
        Accept a relationship request (updates both rows).
        
        Args:
            relationship_id: ID of the relationship row
            user_id: User accepting (must be receiver)
            
        Returns:
            Tuple of (updated_receiver_row, updated_requester_row)
        """
        relationship_oid = self.validate_object_id(relationship_id, "relationship_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        # Get the relationship
        relationship = await self.find_one(
            {"_id": relationship_oid},
            raise_404=True,
            error_message="Relationship not found"
        )
        assert relationship is not None
        
        # Verify user is the receiver (not the requester)
        if relationship.get("user_id") != user_oid:
            raise HTTPException(
                status_code=403,
                detail="You cannot accept this relationship"
            )
        
        if relationship.get("requester_id") == user_oid:
            raise HTTPException(
                status_code=400,
                detail="Cannot accept your own relationship request"
            )
        
        if relationship.get("status") != "pending":
            raise HTTPException(
                status_code=400,
                detail=f"Cannot accept relationship with status: {relationship.get('status')}"
            )
        
        # Update receiver row (current relationship)
        await self.collection.update_one(
            {"_id": relationship_oid},
            {
                "$set": {
                    "status": "accepted",
                    "updated_at": datetime.utcnow()
                }
            }
        )
        
        # Find and update requester row (mirror relationship)
        requester_row = await self.find_one(
            {
                "user_id": relationship["related_user_id"],
                "related_user_id": user_oid,
                "requester_id": relationship["requester_id"]
            },
            raise_404=True,
            error_message="Requester relationship not found"
        )
        assert requester_row is not None
        
        await self.collection.update_one(
            {"_id": requester_row["_id"]},
            {
                "$set": {
                    "status": "accepted",
                    "updated_at": datetime.utcnow()
                }
            }
        )
        
        # Get updated documents
        updated_receiver = await self.find_one({"_id": relationship_oid}, raise_404=True)
        updated_requester = await self.find_one({"_id": requester_row["_id"]}, raise_404=True)
        
        assert updated_receiver is not None
        assert updated_requester is not None
        
        return (updated_receiver, updated_requester)
    
    async def reject_relationship(
        self,
        relationship_id: str,
        user_id: str
    ) -> tuple[Dict[str, Any], Dict[str, Any]]:
        """Reject a relationship request (updates both rows)."""
        relationship_oid = self.validate_object_id(relationship_id, "relationship_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        relationship = await self.find_one(
            {"_id": relationship_oid},
            raise_404=True,
            error_message="Relationship not found"
        )
        assert relationship is not None
        
        if relationship.get("user_id") != user_oid:
            raise HTTPException(
                status_code=403,
                detail="You cannot reject this relationship"
            )
        
        # Update receiver row
        await self.collection.update_one(
            {"_id": relationship_oid},
            {
                "$set": {
                    "status": "rejected",
                    "updated_at": datetime.utcnow()
                }
            }
        )
        
        # Find and update requester row
        requester_row = await self.find_one(
            {
                "user_id": relationship["related_user_id"],
                "related_user_id": user_oid,
                "requester_id": relationship["requester_id"]
            },
            raise_404=False
        )
        
        if requester_row:
            await self.collection.update_one(
                {"_id": requester_row["_id"]},
                {
                    "$set": {
                        "status": "rejected",
                        "updated_at": datetime.utcnow()
                    }
                }
            )
        
        updated_receiver = await self.find_one({"_id": relationship_oid}, raise_404=True)
        updated_requester = await self.find_one({"_id": requester_row["_id"]}, raise_404=True) if requester_row else None
        
        assert updated_receiver is not None
        assert updated_requester is not None
        
        return (updated_receiver, updated_requester)
    
    async def block_relationship(
        self,
        relationship_id: str,
        user_id: str
    ) -> Dict[str, Any]:
        """Block a relationship (updates both rows)."""
        relationship_oid = self.validate_object_id(relationship_id, "relationship_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        relationship = await self.find_one(
            {"_id": relationship_oid},
            raise_404=True,
            error_message="Relationship not found"
        )
        assert relationship is not None
        
        if relationship.get("user_id") != user_oid:
            raise HTTPException(
                status_code=403,
                detail="You cannot block this relationship"
            )
        
        # Update both rows to blocked
        await self.collection.update_one(
            {"_id": relationship_oid},
            {
                "$set": {
                    "status": "blocked",
                    "updated_at": datetime.utcnow()
                }
            }
        )
        
        # Find and update other row
        other_row = await self.find_one(
            {
                "user_id": relationship["related_user_id"],
                "related_user_id": user_oid
            },
            raise_404=False
        )
        
        if other_row:
            await self.collection.update_one(
                {"_id": other_row["_id"]},
                {
                    "$set": {
                        "status": "blocked",
                        "updated_at": datetime.utcnow()
                    }
                }
            )
        
        updated = await self.find_one({"_id": relationship_oid}, raise_404=True)
        assert updated is not None
        return updated
    
    async def delete_relationship_pair(
        self,
        relationship_id: str,
        user_id: str
    ) -> bool:
        """Delete both rows of a relationship."""
        relationship_oid = self.validate_object_id(relationship_id, "relationship_id")
        user_oid = self.validate_object_id(user_id, "user_id")
        
        relationship = await self.find_one(
            {"_id": relationship_oid},
            raise_404=True,
            error_message="Relationship not found"
        )
        assert relationship is not None
        
        if relationship.get("user_id") != user_oid:
            raise HTTPException(
                status_code=403,
                detail="You cannot delete this relationship"
            )
        
        # Delete current row
        await self.collection.delete_one({"_id": relationship_oid})
        
        # Delete mirror row
        await self.collection.delete_one(
            {
                "user_id": relationship["related_user_id"],
                "related_user_id": user_oid
            }
        )
        
        return True
    
    async def get_accepted_relationships(
        self,
        user_id: str,
        relationship_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get all accepted relationships for a user."""
        user_oid = self.validate_object_id(user_id, "user_id")
        
        query: Dict[str, Any] = {
            "user_id": user_oid,
            "status": "accepted"
        }
        
        if relationship_type:
            query["relationship_type"] = relationship_type
        
        return await self.find_many(query, limit=500)
