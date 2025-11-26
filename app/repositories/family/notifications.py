"""Repository for notifications."""
from typing import List, Dict, Any, Optional
from bson import ObjectId
from datetime import datetime
from ..base_repository import BaseRepository


class NotificationRepository(BaseRepository):
    """
    Repository for user notifications.
    Manages notification creation, retrieval, and status updates.
    """
    
    def __init__(self):
        super().__init__("notifications")
    
    async def create_notification(
        self,
        user_id: str,
        notification_type: str,
        title: str,
        message: str,
        related_id: Optional[str] = None,
        actor_id: Optional[str] = None,
        target_type: Optional[str] = None,
        target_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        approval_status: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new notification for a user.
        
        Args:
            user_id: String representation of user ID
            notification_type: Type of notification
            title: Notification title
            message: Notification message
            related_id: Optional related resource ID (deprecated, use target_id)
            actor_id: Optional ID of user who triggered the notification
            target_type: Optional type of target resource
            target_id: Optional ID of target resource
            metadata: Optional additional data
            approval_status: Optional status for approval requests
            
        Returns:
            Created notification document
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        # Use actor_id if provided, otherwise default to user_id
        actor_oid = self.validate_object_id(actor_id, "actor_id") if actor_id else user_oid
        
        notification_data = {
            "user_id": user_oid,
            "actor_id": actor_oid,
            "type": notification_type,
            "title": title,
            "message": message,
            "target_type": target_type,
            "target_id": target_id or related_id,  # Support both for backward compatibility
            "is_read": False,  # Changed from 'read' to 'is_read'
            "created_at": datetime.utcnow()
        }
        
        if metadata:
            notification_data["metadata"] = metadata
            
        if approval_status:
            notification_data["approval_status"] = approval_status
        
        return await self.create(notification_data)

