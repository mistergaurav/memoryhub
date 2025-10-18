"""
Audit logging utilities for GDPR compliance and security tracking.
Logs critical user actions for compliance and security auditing.
"""
from datetime import datetime
from typing import Dict, Any, Optional
from bson import ObjectId
from app.db.mongodb import get_collection


async def log_audit_event(
    user_id: str,
    event_type: str,
    event_details: Dict[str, Any],
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None
):
    """
    Log an audit event for GDPR compliance and security tracking.
    
    Args:
        user_id: The ID of the user performing the action
        event_type: Type of event (e.g., 'data_export', 'data_deletion', 'consent_update')
        event_details: Dictionary containing event-specific details
        ip_address: Optional IP address of the request
        user_agent: Optional user agent string
    """
    try:
        audit_log = {
            "user_id": ObjectId(user_id),
            "event_type": event_type,
            "event_details": event_details,
            "ip_address": ip_address,
            "user_agent": user_agent,
            "timestamp": datetime.utcnow(),
            "created_at": datetime.utcnow()
        }
        
        await get_collection("audit_logs").insert_one(audit_log)
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")


async def log_data_export(user_id: str, export_format: str, ip_address: Optional[str] = None):
    """Log a data export request"""
    await log_audit_event(
        user_id=user_id,
        event_type="data_export",
        event_details={"export_format": export_format},
        ip_address=ip_address
    )


async def log_data_deletion(user_id: str, deletion_type: str, feedback: Optional[str] = None, ip_address: Optional[str] = None):
    """Log a data deletion request"""
    await log_audit_event(
        user_id=user_id,
        event_type="data_deletion",
        event_details={
            "deletion_type": deletion_type,
            "feedback": feedback
        },
        ip_address=ip_address
    )


async def log_consent_update(user_id: str, consent_changes: Dict[str, bool], ip_address: Optional[str] = None):
    """Log consent preference updates"""
    await log_audit_event(
        user_id=user_id,
        event_type="consent_update",
        event_details={"consent_changes": consent_changes},
        ip_address=ip_address
    )


async def log_privacy_settings_update(user_id: str, settings_changes: Dict[str, Any], ip_address: Optional[str] = None):
    """Log privacy settings updates"""
    await log_audit_event(
        user_id=user_id,
        event_type="privacy_settings_update",
        event_details={"settings_changes": settings_changes},
        ip_address=ip_address
    )
