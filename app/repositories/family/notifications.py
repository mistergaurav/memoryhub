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
        related_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new notification for a user.
        
        Args:
            user_id: String representation of user ID
            notification_type: Type of notification
            title: Notification title
            message: Notification message
            related_id: Optional related resource ID
            
        Returns:
            Created notification document
        """
        user_oid = self.validate_object_id(user_id, "user_id")
        
        notification_data = {
            "user_id": user_oid,
            "type": notification_type,
            "title": title,
            "message": message,
            "related_id": related_id,
            "read": False,
            "created_at": datetime.utcnow()
        }
        
        return await self.create(notification_data)

