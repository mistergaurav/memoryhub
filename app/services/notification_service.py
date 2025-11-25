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
from app.schemas.audit_log import AuditLogCreate, AuditAction

logger = logging.getLogger(__name__)


class NotificationService:
    """Service for managing notifications with real-time updates"""
    
    def __init__(self):
        self.audit_repo = AuditLogRepository()
    
    def _get_setting_key(self, notification_type: str) -> Optional[str]:
        """Map notification type to setting key"""
        # This mapping should align with the settings keys in the frontend/router
        if notification_type in [NotificationType.HEALTH_RECORD_ASSIGNED, NotificationType.HEALTH_RECORD_APPROVED, NotificationType.HEALTH_RECORD_REJECTED]:
            return "health_updates"
        if notification_type in [NotificationType.FAMILY_INVITE, NotificationType.FAMILY_MEMBER_ADDED]:
            return "family_activity"
        # Add other mappings as needed
        return None

    async def create_notification(
        self,
        user_id: str,
        type: str,
        title: str,
        message: str,
        actor_id: str,
        target_type: Optional[str] = None,
        target_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        # Health record specific fields
        health_record_id: Optional[str] = None,
        assigner_id: Optional[str] = None,
        assigner_name: Optional[str] = None,
        has_reminder: bool = False,
        reminder_due_at: Optional[datetime] = None,
        record_title: Optional[str] = None,
        record_type: Optional[str] = None,
        record_date: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a notification and broadcast via WebSocket, respecting user settings.
        """
        try:
            # Check user settings
            user = await get_collection("users").find_one({"_id": ObjectId(user_id)})
            if not user:
                logger.warning(f"User {user_id} not found for notification")
                return None
                
            settings = user.get("settings", {}).get("notifications", {})
            setting_key = self._get_setting_key(type)
            
            # Default to True if setting is missing
            if setting_key and not settings.get(setting_key, True):
                logger.info(f"Notification {type} suppressed for user {user_id} by setting {setting_key}")
                return None

            notification_data = {
                "user_id": ObjectId(user_id),
                "type": type,
                "title": title,
                "message": message,
                "actor_id": ObjectId(actor_id),
                "is_read": False,
                "created_at": datetime.utcnow(),
                "metadata": metadata or {}
            }
            
            if target_type:
                notification_data["target_type"] = target_type
            if target_id:
                notification_data["target_id"] = ObjectId(target_id)
                
            # Health record specific fields
            if health_record_id:
                notification_data["health_record_id"] = ObjectId(health_record_id)
            if assigner_id:
                notification_data["assigner_id"] = ObjectId(assigner_id)
            if assigner_name:
                notification_data["assigner_name"] = assigner_name
            if has_reminder:
                notification_data["has_reminder"] = has_reminder
            if reminder_due_at:
                notification_data["reminder_due_at"] = reminder_due_at
            if record_title:
                notification_data["record_title"] = record_title
            if record_type:
                notification_data["record_type"] = record_type
            if record_date:
                notification_data["record_date"] = record_date
            
            if type == NotificationType.HEALTH_RECORD_ASSIGNED:
                notification_data["approval_status"] = NotificationStatus.PENDING.value

            result = await get_collection("notifications").insert_one(notification_data)
            notification_data["_id"] = result.inserted_id
            
            # Broadcast via WebSocket
            await self._broadcast_notification_created(user_id, notification_data)
            
            # Send Push Notification
            await self.send_push_notification(
                user_id=user_id,
                title=title,
                body=message,
                data={
                    "type": type,
                    "id": str(notification_data["_id"]),
                    "click_action": "FLUTTER_NOTIFICATION_CLICK"
                }
            )
            
            logger.info(f"Notification created for user {user_id}, type: {type}")
            return notification_data
        
        except Exception as e:
            logger.error(f"Error creating notification: {str(e)}")
            return None

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
        Wrapper for creating health record assignment notification.
        """
        return await self.create_notification(
            user_id=assignee_id,
            type=NotificationType.HEALTH_RECORD_ASSIGNED.value,
            title="New Health Record Assigned",
            message=f"{assigner_name} has assigned you a health record: {record_title}",
            actor_id=assigner_id,
            target_type="health_record",
            target_id=health_record_id,
            health_record_id=health_record_id,
            assigner_id=assigner_id,
            assigner_name=assigner_name,
            has_reminder=has_reminder,
            reminder_due_at=reminder_due_at,
            record_title=record_title,
            record_type=record_type,
            record_date=record_date,
            metadata=metadata
        )
    
    async def update_notification_status(
        self,
        notification_id: str,
        approval_status: NotificationStatus,
        resolved_by: str,
        resolved_by_name: str
    ) -> bool:
        """
        Update notification approval status and broadcast the change.
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
    
    async def send_push_notification(
        self,
        user_id: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ):
        """Send FCM push notification"""
        try:
            # Get user's FCM tokens
            user = await get_collection("users").find_one({"_id": ObjectId(user_id)})
            if not user or "fcm_tokens" not in user:
                return

            tokens = user["fcm_tokens"]
            if not tokens:
                return

            # In a real implementation, we would use firebase_admin here
            # For now, we'll log it as a placeholder for the actual FCM call
            # from firebase_admin import messaging
            
            logger.info(f"Sending push notification to user {user_id}: {title} - {body}")
            
            # Placeholder for FCM logic:
            # message = messaging.MulticastMessage(
            #     notification=messaging.Notification(
            #         title=title,
            #         body=body,
            #     ),
            #     data=data or {},
            #     tokens=tokens,
            # )
            # response = messaging.send_multicast(message)
            # logger.info(f"FCM response: {response.success_count} messages sent successfully")

        except Exception as e:
            logger.error(f"Error sending push notification: {str(e)}")

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
