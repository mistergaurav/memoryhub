"""
WebSocket endpoint for real-time global notifications
"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from fastapi.responses import JSONResponse
import logging
import json
from typing import Optional

from app.core.websocket import connection_manager, WSMessageType, create_ws_message
from app.core.config import settings
from app.models.user import UserInDB, PyObjectId
from app.db.mongodb import get_collection
from jose import jwt, JWTError

logger = logging.getLogger(__name__)

router = APIRouter()

async def get_user_from_token(token: str) -> Optional[UserInDB]:
    """Authenticate user from WebSocket token"""
    try:
        # Decode JWT token
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        
        if not payload or payload.get("type") != "access":
            return None
        
        # Get user email from token
        email = payload.get("sub")
        if not email:
            return None
        
        # Find user by email
        user_doc = await get_collection("users").find_one({"email": email})
        if not user_doc:
            return None
        
        # Create UserInDB instance
        user_doc["_id"] = PyObjectId(user_doc["_id"])
        return UserInDB(**user_doc)
    except Exception as e:
        logger.error(f"Error authenticating WebSocket user: {str(e)}")
        return None

@router.websocket("/ws/notifications")
async def websocket_notifications(
    websocket: WebSocket,
    token: str = Query(..., description="JWT authentication token")
):
    """
    WebSocket endpoint for real-time notifications.
    """
    # Authenticate user
    user = await get_user_from_token(token)
    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid or expired token")
        return
    
    # Accept connection
    await connection_manager.connect(websocket, str(user.id))
    
    try:
        # Send connection acknowledgment
        await websocket.send_json(create_ws_message(
            WSMessageType.CONNECTION_ACK,
            {
                "message": "Connected successfully",
                "user_id": str(user.id),
                "user_name": user.full_name or "Unknown"
            }
        ))
        
        # Subscribe to user's families (for family-wide notifications)
        try:
            from app.repositories.family_repository import FamilyRepository
            family_repo = FamilyRepository()
            user_circles = await family_repo.find_by_member(str(user.id), limit=100)
            
            for circle in user_circles:
                if circle and "_id" in circle:
                    family_id = str(circle["_id"])
                    connection_manager.subscribe_to_family(str(user.id), family_id)
        except Exception as e:
            logger.error(f"Error subscribing to families: {str(e)}")
        
        # Keep connection alive and handle client messages
        while True:
            try:
                # Wait for client messages
                data = await websocket.receive_text()
                
                # Parse message
                try:
                    message = json.loads(data)
                    event = message.get("event")
                    
                    # Handle ping/pong
                    if event == WSMessageType.PING:
                        await websocket.send_json(create_ws_message(
                            WSMessageType.PONG,
                            {"message": "pong"}
                        ))
                    else:
                        logger.debug(f"Received message from user {user.id}: {event}")
                
                except json.JSONDecodeError:
                    pass # Ignore invalid JSON
            
            except WebSocketDisconnect:
                break
            except Exception as e:
                logger.error(f"Error in WebSocket loop for user {user.id}: {str(e)}")
                break
    
    except Exception as e:
        logger.error(f"WebSocket error for user {user.id}: {str(e)}")
    
    finally:
        # Cleanup: unsubscribe from all families
        for family_id in list(connection_manager.family_subscriptions.keys()):
            if str(user.id) in connection_manager.family_subscriptions.get(family_id, set()):
                connection_manager.unsubscribe_from_family(str(user.id), family_id)
        
        # Disconnect
        connection_manager.disconnect(websocket, str(user.id))

@router.get("/ws/status")
async def websocket_status():
    """Get WebSocket server status (for debugging)"""
    return JSONResponse({
        "active_connections": len(connection_manager.active_connections),
        "total_users": sum(len(conns) for conns in connection_manager.active_connections.values()),
        "families": len(connection_manager.family_subscriptions)
    })
