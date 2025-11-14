"""
Repository for audit log operations
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from bson import ObjectId
import logging

from app.db.mongodb import get_collection
from app.schemas.audit_log import AuditLogCreate, AuditLogResponse, AuditAction

logger = logging.getLogger(__name__)


class AuditLogRepository:
    """Repository for managing audit logs"""
    
    def __init__(self):
        self.collection_name = "audit_logs"
    
    async def create_log(self, log_data: AuditLogCreate) -> Dict[str, Any]:
        """Create a new audit log entry"""
        try:
            log_dict = log_data.model_dump(exclude_none=True)
            log_dict["created_at"] = datetime.utcnow()
            
            # Convert string IDs to ObjectIds
            if "resource_id" in log_dict and ObjectId.is_valid(log_dict["resource_id"]):
                log_dict["resource_id"] = ObjectId(log_dict["resource_id"])
            
            if "actor_id" in log_dict and ObjectId.is_valid(log_dict["actor_id"]):
                log_dict["actor_id"] = ObjectId(log_dict["actor_id"])
            
            if "target_user_id" in log_dict and log_dict["target_user_id"] and ObjectId.is_valid(log_dict["target_user_id"]):
                log_dict["target_user_id"] = ObjectId(log_dict["target_user_id"])
            
            result = await get_collection(self.collection_name).insert_one(log_dict)
            log_dict["_id"] = result.inserted_id
            
            logger.info(f"Audit log created: {log_data.action} on {log_data.resource_type} by {log_data.actor_name}")
            return log_dict
        
        except Exception as e:
            logger.error(f"Error creating audit log: {str(e)}")
            raise
    
    async def find_by_resource(
        self,
        resource_type: str,
        resource_id: str,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Find all audit logs for a specific resource"""
        try:
            resource_oid = ObjectId(resource_id) if ObjectId.is_valid(resource_id) else resource_id
            
            cursor = get_collection(self.collection_name).find({
                "resource_type": resource_type,
                "resource_id": resource_oid
            }).sort("created_at", -1).skip(skip).limit(limit)
            
            logs = await cursor.to_list(length=limit)
            return logs
        
        except Exception as e:
            logger.error(f"Error finding audit logs for resource {resource_id}: {str(e)}")
            return []
    
    async def find_by_actor(
        self,
        actor_id: str,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Find all audit logs by a specific actor"""
        try:
            actor_oid = ObjectId(actor_id) if ObjectId.is_valid(actor_id) else actor_id
            
            cursor = get_collection(self.collection_name).find({
                "actor_id": actor_oid
            }).sort("created_at", -1).skip(skip).limit(limit)
            
            logs = await cursor.to_list(length=limit)
            return logs
        
        except Exception as e:
            logger.error(f"Error finding audit logs for actor {actor_id}: {str(e)}")
            return []
    
    async def find_by_action(
        self,
        action: AuditAction,
        resource_type: Optional[str] = None,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Find all audit logs for a specific action type"""
        try:
            query: Dict[str, Any] = {"action": action}
            
            if resource_type:
                query["resource_type"] = resource_type
            
            cursor = get_collection(self.collection_name).find(query).sort("created_at", -1).skip(skip).limit(limit)
            
            logs = await cursor.to_list(length=limit)
            return logs
        
        except Exception as e:
            logger.error(f"Error finding audit logs for action {action}: {str(e)}")
            return []
    
    def format_response(self, log_doc: Dict[str, Any]) -> AuditLogResponse:
        """Format audit log document as response"""
        return AuditLogResponse(
            id=str(log_doc["_id"]),
            resource_type=log_doc["resource_type"],
            resource_id=str(log_doc["resource_id"]),
            action=log_doc["action"],
            actor_id=str(log_doc["actor_id"]),
            actor_name=log_doc["actor_name"],
            target_user_id=str(log_doc["target_user_id"]) if log_doc.get("target_user_id") else None,
            target_user_name=log_doc.get("target_user_name"),
            old_value=log_doc.get("old_value"),
            new_value=log_doc.get("new_value"),
            remarks=log_doc.get("remarks"),
            metadata=log_doc.get("metadata", {}),
            ip_address=log_doc.get("ip_address"),
            user_agent=log_doc.get("user_agent"),
            created_at=log_doc["created_at"]
        )
