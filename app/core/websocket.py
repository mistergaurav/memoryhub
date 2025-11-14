"""
WebSocket connection manager for real-time notifications and updates
"""
from typing import Dict, Set, List, Optional
from fastapi import WebSocket, WebSocketDisconnect
import json
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections for real-time updates"""
    
    def __init__(self):
        # user_id -> set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # family_id -> set of user_ids
        self.family_subscriptions: Dict[str, Set[str]] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        """Accept and register a new WebSocket connection"""
        await websocket.accept()
        
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        
        self.active_connections[user_id].add(websocket)
        logger.info(f"WebSocket connected for user {user_id}. Total connections: {len(self.active_connections[user_id])}")
    
    def disconnect(self, websocket: WebSocket, user_id: str):
        """Remove a WebSocket connection"""
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            
            # Clean up empty sets
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
                logger.info(f"All connections closed for user {user_id}")
            else:
                logger.info(f"WebSocket disconnected for user {user_id}. Remaining: {len(self.active_connections[user_id])}")
    
    def subscribe_to_family(self, user_id: str, family_id: str):
        """Subscribe a user to family-wide notifications"""
        if family_id not in self.family_subscriptions:
            self.family_subscriptions[family_id] = set()
        
        self.family_subscriptions[family_id].add(user_id)
        logger.info(f"User {user_id} subscribed to family {family_id}")
    
    def unsubscribe_from_family(self, user_id: str, family_id: str):
        """Unsubscribe a user from family-wide notifications"""
        if family_id in self.family_subscriptions:
            self.family_subscriptions[family_id].discard(user_id)
            
            if not self.family_subscriptions[family_id]:
                del self.family_subscriptions[family_id]
    
    async def send_personal_message(self, message: dict, user_id: str):
        """Send a message to a specific user (all their connections)"""
        if user_id not in self.active_connections:
            logger.debug(f"No active connections for user {user_id}")
            return
        
        # Add timestamp if not present
        if "timestamp" not in message:
            message["timestamp"] = datetime.utcnow().isoformat()
        
        message_json = json.dumps(message)
        disconnected = set()
        
        for connection in self.active_connections[user_id]:
            try:
                await connection.send_text(message_json)
            except WebSocketDisconnect:
                disconnected.add(connection)
            except Exception as e:
                logger.error(f"Error sending message to user {user_id}: {str(e)}")
                disconnected.add(connection)
        
        # Clean up disconnected connections
        for connection in disconnected:
            self.disconnect(connection, user_id)
    
    async def send_to_family(self, message: dict, family_id: str, exclude_user_ids: Optional[List[str]] = None):
        """Send a message to all members of a family"""
        if family_id not in self.family_subscriptions:
            logger.debug(f"No subscriptions for family {family_id}")
            return
        
        exclude_user_ids = exclude_user_ids or []
        user_ids = self.family_subscriptions[family_id] - set(exclude_user_ids)
        
        for user_id in user_ids:
            await self.send_personal_message(message, user_id)
    
    async def broadcast_to_users(self, message: dict, user_ids: List[str]):
        """Send a message to multiple specific users"""
        for user_id in user_ids:
            await self.send_personal_message(message, user_id)
    
    async def broadcast(self, message: str):
        """Broadcast a message to all connected users (rarely used)"""
        for user_connections in self.active_connections.values():
            for connection in user_connections:
                try:
                    await connection.send_text(message)
                except:
                    pass


# Global connection manager instance
connection_manager = ConnectionManager()


# WebSocket message types
class WSMessageType:
    """WebSocket message event types"""
    # Notifications
    NOTIFICATION_CREATED = "notification.created"
    NOTIFICATION_UPDATED = "notification.updated"
    NOTIFICATION_DELETED = "notification.deleted"
    
    # Health records
    HEALTH_RECORD_ASSIGNED = "health_record.assigned"
    HEALTH_RECORD_APPROVED = "health_record.approved"
    HEALTH_RECORD_REJECTED = "health_record.rejected"
    HEALTH_RECORD_UPDATED = "health_record.updated"
    HEALTH_RECORD_STATUS_CHANGED = "health_record.status_changed"
    
    # Reminders
    REMINDER_CREATED = "reminder.created"
    REMINDER_DUE = "reminder.due"
    
    # Connection
    CONNECTION_ACK = "connection.acknowledged"
    ERROR = "error"
    PING = "ping"
    PONG = "pong"


def create_ws_message(event_type: str, data: dict, user_id: Optional[str] = None) -> dict:
    """Create a standardized WebSocket message"""
    return {
        "event": event_type,
        "data": data,
        "timestamp": datetime.utcnow().isoformat(),
        "user_id": user_id
    }
