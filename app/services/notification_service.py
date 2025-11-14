"""
Service for creating and broadcasting notifications with WebSocket support
"""
from typing import Optional, Dict, Any
from datetime import datetime
from bson import ObjectId
import logging

from app.db.mongodb import get_collection
from app.core.websocket import connection_manager, WSMessageType, create_ws_message
from app.schemas.notification import NotificationType, NotificationStatus
from app.repositories.audit_log_repository import AuditLogRepository
from app.schemas.audit_log import AuditLogCreate, AuditAction, HealthRecordAuditMetadata

logger = logging.getLogger(__name__)


class NotificationService:
    """Service for managing notifications with real-time updates"""
    
    def __init__(self):
        self.audit_repo = AuditLogRepository()
    
    async def create_health_record_assignment_notification(
        self,
        assignee_id: str,
        assigner_id: str,
        assigner_name: str,
        health_record_id: str,
        record_title: str,
        record_type: str,
        record_date: str,
        has_reminder: bool = False,
        reminder_due_at: Optional[datetime] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Create a health record assignment notification and broadcast via WebSocket.
        
        Args:
            assignee_id: ID of user receiving the notification
            assigner_id: ID of user who assigned the record
            assigner_name: Name of user who assigned the record
            health_record_id: ID of the health record
            record_title: Title of the health record
            record_type: Type of health record
            record_date: Date of the health record
            has_reminder: Whether a reminder is set
            reminder_due_at: When the reminder is due
            metadata: Additional metadata
        
        Returns:
            Created notification document
        """
        try:
            notification_data = {
                "user_id": ObjectId(assignee_id),
                "type": NotificationType.HEALTH_RECORD_ASSIGNED.value,
                "title": "New Health Record Assigned",
                "message": f"{assigner_name} has assigned you a health record: {record_title}",
                "actor_id": ObjectId(assigner_id),
                "target_type": "health_record",
                "target_id": ObjectId(health_record_id),
                "health_record_id": ObjectId(health_record_id),
                "assigner_id": ObjectId(assigner_id),
                "assigner_name": assigner_name,
                "assigned_at": datetime.utcnow(),
                "has_reminder": has_reminder,
                "reminder_due_at": reminder_due_at,
                "record_title": record_title,
                "record_type": record_type,
                "record_date": record_date,
                "approval_status": NotificationStatus.PENDING.value,
                "is_read": False,
                "created_at": datetime.utcnow(),
                "metadata": metadata or {}
            }
            
            result = await get_collection("notifications").insert_one(notification_data)
            notification_data["_id"] = result.inserted_id
            
            # Broadcast via WebSocket
            await self._broadcast_notification_created(assignee_id, notification_data)
            
            logger.info(f"Health record assignment notification created for user {assignee_id}")
            return notification_data
        
        except Exception as e:
            logger.error(f"Error creating health record assignment notification: {str(e)}")
            return None
    
    async def update_notification_status(
        self,
        notification_id: str,
        approval_status: NotificationStatus,
        resolved_by: str,
        resolved_by_name: str
    ) -> bool:
        """
        Update notification approval status and broadcast the change.
        
        Args:
            notification_id: ID of the notification
            approval_status: New approval status
            resolved_by: ID of user who resolved it
            resolved_by_name: Name of user who resolved it
        
        Returns:
            True if successful, False otherwise
        """
        try:
            update_data = {
                "approval_status": approval_status.value if isinstance(approval_status, NotificationStatus) else approval_status,
                "resolved_at": datetime.utcnow(),
                "resolved_by": ObjectId(resolved_by),
                "resolved_by_name": resolved_by_name
            }
            
            result = await get_collection("notifications").update_one(
                {"_id": ObjectId(notification_id)},
                {"$set": update_data}
            )
            
            if result.modified_count > 0:
                # Get updated notification
                notification = await get_collection("notifications").find_one({
                    "_id": ObjectId(notification_id)
                })
                
                if notification:
                    # Broadcast to assignee
                    await self._broadcast_notification_updated(
                        str(notification["user_id"]),
                        notification
                    )
                    
                    # Broadcast to assigner
                    await self._broadcast_health_record_status_changed(
                        str(notification.get("assigner_id")),
                        notification.get("health_record_id"),
                        approval_status,
                        resolved_by_name
                    )
                
                return True
            
            return False
        
        except Exception as e:
            logger.error(f"Error updating notification status: {str(e)}")
            return False
    
    async def _broadcast_notification_created(
        self,
        user_id: str,
        notification_data: Dict[str, Any]
    ):
        """Broadcast notification.created event via WebSocket"""
        try:
            message = create_ws_message(
                WSMessageType.NOTIFICATION_CREATED,
                {
                    "id": str(notification_data["_id"]),
                    "type": notification_data["type"],
                    "title": notification_data["title"],
                    "message": notification_data["message"],
                    "health_record_id": str(notification_data.get("health_record_id")) if notification_data.get("health_record_id") else None,
                    "assigner_name": notification_data.get("assigner_name"),
                    "record_title": notification_data.get("record_title"),
                    "has_reminder": notification_data.get("has_reminder", False),
                    "created_at": notification_data["created_at"].isoformat()
                },
                user_id
            )
            
            await connection_manager.send_personal_message(message, user_id)
        
        except Exception as e:
            logger.error(f"Error broadcasting notification created: {str(e)}")
    
    async def _broadcast_notification_updated(
        self,
        user_id: str,
        notification_data: Dict[str, Any]
    ):
        """Broadcast notification.updated event via WebSocket"""
        try:
            message = create_ws_message(
                WSMessageType.NOTIFICATION_UPDATED,
                {
                    "id": str(notification_data["_id"]),
                    "approval_status": notification_data.get("approval_status"),
                    "resolved_at": notification_data.get("resolved_at").isoformat() if notification_data.get("resolved_at") else None,
                    "resolved_by_name": notification_data.get("resolved_by_name")
                },
                user_id
            )
            
            await connection_manager.send_personal_message(message, user_id)
        
        except Exception as e:
            logger.error(f"Error broadcasting notification updated: {str(e)}")
    
    async def _broadcast_health_record_status_changed(
        self,
        assigner_id: str,
        health_record_id: ObjectId,
        new_status: str,
        resolved_by_name: str
    ):
        """Broadcast health_record.status_changed event to the assigner"""
        try:
            # Convert status to string if it's an Enum
            status_value = new_status.value if hasattr(new_status, 'value') else new_status
            
            message = create_ws_message(
                WSMessageType.HEALTH_RECORD_STATUS_CHANGED,
                {
                    "health_record_id": str(health_record_id),
                    "new_status": status_value,
                    "resolved_by": resolved_by_name,
                    "timestamp": datetime.utcnow().isoformat()
                },
                assigner_id
            )
            
            await connection_manager.send_personal_message(message, assigner_id)
        
        except Exception as e:
            logger.error(f"Error broadcasting health record status changed: {str(e)}")
    
    async def create_audit_log(
        self,
        resource_type: str,
        resource_id: str,
        action: AuditAction,
        actor_id: str,
        actor_name: str,
        target_user_id: Optional[str] = None,
        target_user_name: Optional[str] = None,
        old_value: Optional[Dict[str, Any]] = None,
        new_value: Optional[Dict[str, Any]] = None,
        remarks: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Create an audit log entry.
        
        Returns:
            True if successful, False otherwise
        """
        try:
            log_data = AuditLogCreate(
                resource_type=resource_type,
                resource_id=resource_id,
                action=action,
                actor_id=actor_id,
                actor_name=actor_name,
                target_user_id=target_user_id,
                target_user_name=target_user_name,
                old_value=old_value,
                new_value=new_value,
                remarks=remarks,
                metadata=metadata or {}
            )
            
            await self.audit_repo.create_log(log_data)
            return True
        
        except Exception as e:
            logger.error(f"Error creating audit log: {str(e)}")
            return False
