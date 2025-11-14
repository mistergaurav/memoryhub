from typing import Dict, Any, Optional, List
from bson import ObjectId
from datetime import datetime

from ..repositories.health_records_repository import HealthRecordsRepository
from ..schemas.health_records import (
    HealthRecordCreate,
    HealthRecordUpdate,
    HealthRecordResponse,
    ApprovalStatus,
    VisibilityScope,
)
from app.api.v1.endpoints.social.notifications import create_notification
from app.schemas.notification import NotificationType, NotificationStatus
from app.utils.audit_logger import log_audit_event
from app.repositories.family_repository import FamilyRepository, FamilyMembersRepository
from app.services.notification_service import NotificationService
from app.schemas.audit_log import AuditAction
from app.db.mongodb import get_collection
from app.core.websocket import connection_manager, create_ws_message, WSMessageType


class HealthRecordService:
    """
    Service layer for health records business logic.
    
    Handles:
    - Subject-type authorization (SELF/FAMILY/FRIEND)
    - Approval workflow
    - Business logic and validation
    - Notification orchestration
    """
    
    def __init__(self):
        self.repository = HealthRecordsRepository()
        self.notification_service = NotificationService()
    
    async def create_health_record(
        self,
        record: HealthRecordCreate,
        current_user_id: str,
        current_user_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new health record with approval workflow.
        
        If the record is created for another user (SELF type with different subject_user_id),
        it requires approval. Otherwise, it's auto-approved.
        
        Args:
            record: Health record creation data
            current_user_id: ID of the user creating the record
            current_user_name: Name of the user creating the record
            
        Returns:
            Created health record document
        """
        family_id = await self._determine_family_id(record, current_user_id)
        
        record_data = {
            "family_id": family_id,
            "subject_type": record.subject_type,
            "record_type": record.record_type,
            "title": record.title,
            "description": record.description,
            "date": record.date,
            "provider": record.provider,
            "location": record.location,
            "severity": record.severity,
            "attachments": record.attachments or [],
            "notes": record.notes,
            "medications": record.medications or [],
            "is_confidential": record.is_confidential if record.is_confidential is not None else False,
            "is_hereditary": record.is_hereditary if record.is_hereditary is not None else False,
            "inheritance_pattern": record.inheritance_pattern,
            "age_of_onset": record.age_of_onset,
            "affected_relatives": record.affected_relatives or [],
            "genetic_test_results": record.genetic_test_results,
            "created_by": ObjectId(current_user_id)
        }
        
        if record.subject_user_id:
            record_data["subject_user_id"] = self.repository.validate_object_id(record.subject_user_id, "subject_user_id")
        
        if record.subject_family_member_id:
            record_data["subject_family_member_id"] = self.repository.validate_object_id(record.subject_family_member_id, "subject_family_member_id")
        
        if record.subject_friend_circle_id:
            record_data["subject_friend_circle_id"] = self.repository.validate_object_id(record.subject_friend_circle_id, "subject_friend_circle_id")
        
        if record.assigned_user_ids:
            record_data["assigned_user_ids"] = [
                self.repository.validate_object_id(user_id, "assigned_user_id")
                for user_id in record.assigned_user_ids
            ]
        
        if record.family_member_id:
            record_data["family_member_id"] = self.repository.validate_object_id(record.family_member_id, "family_member_id")
        
        if record.genealogy_person_id:
            record_data["genealogy_person_id"] = self.repository.validate_object_id(record.genealogy_person_id, "genealogy_person_id")
        
        if record.subject_user_id and record.subject_user_id != current_user_id:
            record_data["approval_status"] = "pending_approval"
            record_data["requested_visibility"] = record.requested_visibility if record.requested_visibility else "private"
            record_data["visibility_scope"] = "private"
        else:
            record_data["approval_status"] = "approved"
            record_data["approved_at"] = datetime.utcnow()
            record_data["approved_by"] = str(current_user_id)
            record_data["visibility_scope"] = record.requested_visibility if record.requested_visibility else "private"
        
        record_doc = await self.repository.create(record_data)
        
        if record.subject_user_id and record.subject_user_id != current_user_id:
            await create_notification(
                user_id=record.subject_user_id,
                notification_type=NotificationType.HEALTH_RECORD_ASSIGNED,
                title="New Health Record Created for You",
                message=f"{current_user_name or 'Someone'} created a health record '{record.title}' for you. Please review and approve.",
                actor_id=str(current_user_id),
                target_type="health_record",
                target_id=str(record_doc["_id"]),
                health_record_id=str(record_doc["_id"]),
                assigner_id=str(current_user_id),
                assigner_name=current_user_name or "Unknown",
                has_reminder=False
            )
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="CREATE_HEALTH_RECORD",
            event_details={
                "resource_type": "health_record",
                "resource_id": str(record_doc["_id"]),
                "record_type": record.record_type,
                "subject_type": record.subject_type,
                "is_confidential": record.is_confidential
            }
        )
        
        return record_doc
    
    async def update_health_record(
        self,
        record_id: str,
        record_update: HealthRecordUpdate,
        current_user_id: str
    ) -> Dict[str, Any]:
        """
        Update a health record with proper authorization.
        
        Args:
            record_id: ID of the record to update
            record_update: Update data
            current_user_id: ID of the user updating the record
            
        Returns:
            Updated health record document
            
        Raises:
            HTTPException: If user doesn't have permission to update
        """
        from fastapi import HTTPException, status
        
        record_doc = await self.repository.find_by_id(
            record_id,
            raise_404=True,
            error_message="Health record not found"
        )
        
        if not record_doc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Health record not found")
        
        has_access = await self.check_user_has_access(record_doc, current_user_id)
        if not has_access:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to update this record")
        
        update_data = {k: v for k, v in record_update.dict(exclude_unset=True).items() if v is not None}
        
        updated_record = await self.repository.update_by_id(record_id, update_data)
        
        if not updated_record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update health record")
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="UPDATE_HEALTH_RECORD",
            event_details={
                "resource_type": "health_record",
                "resource_id": record_id,
                "updates": list(update_data.keys())
            }
        )
        
        return updated_record
    
    async def delete_health_record(
        self,
        record_id: str,
        current_user_id: str
    ) -> bool:
        """
        Delete a health record with proper authorization.
        
        Args:
            record_id: ID of the record to delete
            current_user_id: ID of the user deleting the record
            
        Returns:
            True if deleted successfully
            
        Raises:
            HTTPException: If user doesn't have permission to delete
        """
        from fastapi import HTTPException, status
        
        record_doc = await self.repository.find_by_id(
            record_id,
            raise_404=True,
            error_message="Health record not found"
        )
        
        if not record_doc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Health record not found")
        
        has_access = await self.check_user_has_access(record_doc, current_user_id)
        if not has_access:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this record")
        
        await self.repository.delete_by_id(record_id)
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="DELETE_HEALTH_RECORD",
            event_details={
                "resource_type": "health_record",
                "resource_id": record_id,
                "record_type": record_doc.get("record_type")
            }
        )
        
        return True
    
    async def approve_health_record(
        self,
        record_id: str,
        current_user_id: str,
        current_user_name: Optional[str] = None,
        visibility_scope: Optional[VisibilityScope] = None
    ) -> Dict[str, Any]:
        """
        Approve a health record that was created for you with visibility selection.
        
        Only the subject user can approve a record created for them.
        
        Args:
            record_id: ID of the record to approve
            current_user_id: ID of the user approving the record
            current_user_name: Name of the user approving the record
            visibility_scope: Visibility scope for the approved record (required)
            
        Returns:
            Approved health record document
            
        Raises:
            HTTPException: If user is not authorized or record status is invalid
        """
        from fastapi import HTTPException, status
        
        if not visibility_scope:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="visibility_scope is required when approving a health record"
            )
        
        record_doc = await self.repository.find_by_id(
            record_id,
            raise_404=True,
            error_message="Health record not found"
        )
        
        if not record_doc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Health record not found")
        
        subject_user_id = record_doc.get("subject_user_id")
        assigned_user_ids = record_doc.get("assigned_user_ids", [])
        
        is_subject_user = subject_user_id and str(subject_user_id) == current_user_id
        is_assigned_user = any(str(uid) == current_user_id for uid in assigned_user_ids)
        
        if not (is_subject_user or is_assigned_user):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the assigned user can approve this health record"
            )
        
        current_status = record_doc.get("approval_status", "approved")
        if current_status == "approved":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Health record is already approved"
            )
        if current_status == "rejected":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Health record has been rejected. Cannot approve a rejected record."
            )
        
        update_data = {
            "approval_status": "approved",
            "approved_at": datetime.utcnow(),
            "approved_by": str(current_user_id),
            "visibility_scope": visibility_scope.value if isinstance(visibility_scope, VisibilityScope) else str(visibility_scope)
        }
        
        updated_record = await self.repository.update_by_id(record_id, update_data)
        
        if not updated_record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update health record")
        
        # Find associated notification and update its status
        notification = await get_collection("notifications").find_one({
            "health_record_id": ObjectId(record_id),
            "type": "health_record_assigned",
            "user_id": ObjectId(current_user_id)
        })
        
        if notification:
            await self.notification_service.update_notification_status(
                notification_id=str(notification["_id"]),
                approval_status=NotificationStatus.APPROVED,
                resolved_by=current_user_id,
                resolved_by_name=current_user_name or "Unknown"
            )
        
        # Create audit log
        created_by = record_doc.get("created_by")
        await self.notification_service.create_audit_log(
            resource_type="health_record",
            resource_id=record_id,
            action=AuditAction.APPROVED,
            actor_id=current_user_id,
            actor_name=current_user_name or "Unknown",
            target_user_id=str(created_by) if created_by else None,
            target_user_name=None,
            old_value={"approval_status": record_doc.get("approval_status")},
            new_value={"approval_status": "approved", "visibility_scope": visibility_scope.value if isinstance(visibility_scope, VisibilityScope) else str(visibility_scope)},
            remarks=f"Health record approved with {visibility_scope.value if isinstance(visibility_scope, VisibilityScope) else str(visibility_scope)} visibility",
            metadata={
                "record_type": record_doc.get("record_type"),
                "record_title": record_doc.get("title")
            }
        )
        
        # Send notification to creator via legacy notification system
        if created_by:
            creator_id = str(created_by)
            if creator_id != current_user_id:
                record_title = record_doc.get("title", "Untitled")
                visibility_label = visibility_scope.value if isinstance(visibility_scope, VisibilityScope) else str(visibility_scope)
                await create_notification(
                    user_id=creator_id,
                    notification_type=NotificationType.HEALTH_RECORD_APPROVED,
                    title="Health Record Approved",
                    message=f"{current_user_name or 'Someone'} approved the health record '{record_title}' you created for them with {visibility_label} visibility.",
                    actor_id=str(current_user_id),
                    target_type="health_record",
                    target_id=record_id
                )
                
                # Broadcast WebSocket notification to creator
                try:
                    ws_message = create_ws_message(
                        WSMessageType.NOTIFICATION_UPDATED,
                        {
                            "health_record_id": record_id,
                            "new_status": "approved",
                            "approved_by": current_user_id,
                            "visibility_scope": visibility_scope.value if isinstance(visibility_scope, VisibilityScope) else str(visibility_scope)
                        }
                    )
                    await connection_manager.send_personal_message(ws_message, str(created_by))
                except Exception as e:
                    logger = __import__('logging').getLogger(__name__)
                    logger.error(f"Failed to send WebSocket notification to creator: {str(e)}")
        
        # Send WebSocket confirmation to approver
        try:
            ws_message = create_ws_message(
                WSMessageType.HEALTH_RECORD_APPROVED,
                {
                    "health_record_id": record_id,
                    "status": "approved",
                    "visibility_scope": visibility_scope.value if isinstance(visibility_scope, VisibilityScope) else str(visibility_scope)
                }
            )
            await connection_manager.send_personal_message(ws_message, current_user_id)
        except Exception as e:
            logger = __import__('logging').getLogger(__name__)
            logger.error(f"Failed to send WebSocket confirmation to approver: {str(e)}")
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="APPROVE_HEALTH_RECORD",
            event_details={
                "resource_type": "health_record",
                "resource_id": record_id,
                "record_type": record_doc.get("record_type"),
                "created_by": str(record_doc.get("created_by")) if record_doc.get("created_by") else None,
                "visibility_scope": visibility_scope.value if isinstance(visibility_scope, VisibilityScope) else str(visibility_scope)
            }
        )
        
        return updated_record
    
    async def reject_health_record(
        self,
        record_id: str,
        current_user_id: str,
        current_user_name: Optional[str] = None,
        rejection_reason: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Reject a health record that was created for you.
        
        Only the subject user can reject a record created for them.
        
        Args:
            record_id: ID of the record to reject
            current_user_id: ID of the user rejecting the record
            current_user_name: Name of the user rejecting the record
            rejection_reason: Optional reason for rejection
            
        Returns:
            Rejected health record document
            
        Raises:
            HTTPException: If user is not authorized or record status is invalid
        """
        from fastapi import HTTPException, status
        
        record_doc = await self.repository.find_by_id(
            record_id,
            raise_404=True,
            error_message="Health record not found"
        )
        
        if not record_doc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Health record not found")
        
        subject_user_id = record_doc.get("subject_user_id")
        assigned_user_ids = record_doc.get("assigned_user_ids", [])
        
        is_subject_user = subject_user_id and str(subject_user_id) == current_user_id
        is_assigned_user = any(str(uid) == current_user_id for uid in assigned_user_ids)
        
        if not (is_subject_user or is_assigned_user):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the assigned user can reject this health record"
            )
        
        current_status = record_doc.get("approval_status", "approved")
        if current_status == "approved":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Health record is already approved. Cannot reject an approved record."
            )
        if current_status == "rejected":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Health record is already rejected"
            )
        
        update_data = {
            "approval_status": "rejected"
        }
        
        if rejection_reason:
            update_data["rejection_reason"] = rejection_reason
        
        updated_record = await self.repository.update_by_id(record_id, update_data)
        
        if not updated_record:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to update health record")
        
        # Find associated notification and update its status
        notification = await get_collection("notifications").find_one({
            "health_record_id": ObjectId(record_id),
            "type": "health_record_assigned",
            "user_id": ObjectId(current_user_id)
        })
        
        if notification:
            await self.notification_service.update_notification_status(
                notification_id=str(notification["_id"]),
                approval_status=NotificationStatus.REJECTED,
                resolved_by=current_user_id,
                resolved_by_name=current_user_name or "Unknown"
            )
        
        # Create audit log
        created_by = record_doc.get("created_by")
        await self.notification_service.create_audit_log(
            resource_type="health_record",
            resource_id=record_id,
            action=AuditAction.REJECTED,
            actor_id=current_user_id,
            actor_name=current_user_name or "Unknown",
            target_user_id=str(created_by) if created_by else None,
            target_user_name=None,
            old_value={"approval_status": record_doc.get("approval_status")},
            new_value={"approval_status": "rejected"},
            remarks=rejection_reason or "No reason provided",
            metadata={
                "record_type": record_doc.get("record_type"),
                "record_title": record_doc.get("title"),
                "rejection_reason": rejection_reason
            }
        )
        
        # Send notification to creator via legacy notification system
        if created_by:
            creator_id = str(created_by)
            if creator_id != current_user_id:
                reason_text = f" Reason: {rejection_reason}" if rejection_reason else ""
                record_title = record_doc.get("title", "Untitled")
                await create_notification(
                    user_id=creator_id,
                    notification_type=NotificationType.HEALTH_RECORD_REJECTED,
                    title="Health Record Rejected",
                    message=f"{current_user_name or 'Someone'} rejected the health record '{record_title}' you created for them.{reason_text}",
                    actor_id=str(current_user_id),
                    target_type="health_record",
                    target_id=record_id
                )
                
                # Broadcast WebSocket notification to creator
                try:
                    ws_message = create_ws_message(
                        WSMessageType.NOTIFICATION_UPDATED,
                        {
                            "health_record_id": record_id,
                            "new_status": "rejected",
                            "rejected_by": current_user_id,
                            "rejection_reason": rejection_reason
                        }
                    )
                    await connection_manager.send_personal_message(ws_message, str(created_by))
                except Exception as e:
                    logger = __import__('logging').getLogger(__name__)
                    logger.error(f"Failed to send WebSocket notification to creator: {str(e)}")
        
        # Send WebSocket confirmation to rejector
        try:
            ws_message = create_ws_message(
                WSMessageType.HEALTH_RECORD_REJECTED,
                {
                    "health_record_id": record_id,
                    "status": "rejected",
                    "rejection_reason": rejection_reason
                }
            )
            await connection_manager.send_personal_message(ws_message, current_user_id)
        except Exception as e:
            logger = __import__('logging').getLogger(__name__)
            logger.error(f"Failed to send WebSocket confirmation to rejector: {str(e)}")
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="REJECT_HEALTH_RECORD",
            event_details={
                "resource_type": "health_record",
                "resource_id": record_id,
                "record_type": record_doc.get("record_type"),
                "created_by": str(record_doc.get("created_by")) if record_doc.get("created_by") else None,
                "rejection_reason": rejection_reason
            }
        )
        
        return updated_record
    
    async def check_user_has_access(
        self,
        record_doc: Dict[str, Any],
        current_user_id: str
    ) -> bool:
        """
        Check if user has access to modify a health record.
        
        User has access if they:
        - Created the record
        - Are the subject (for SELF type)
        - Are assigned to the record
        - Are a member of the family circle (for FAMILY type)
        - Own the record (family_id equals user_id for personal records)
        
        Args:
            record_doc: Health record document
            current_user_id: ID of the current user
            
        Returns:
            True if user has access, False otherwise
        """
        user_oid = ObjectId(current_user_id)
        
        if record_doc.get("created_by") == user_oid:
            return True
        
        if record_doc.get("subject_type") == "self" and record_doc.get("subject_user_id") == user_oid:
            return True
        
        if user_oid in record_doc.get("assigned_user_ids", []):
            return True
        
        if record_doc.get("family_id") == user_oid:
            return True
        
        if record_doc.get("subject_type") == "family":
            family_repo = FamilyRepository()
            try:
                family_id = record_doc.get("family_id")
                if family_id:
                    is_member = await family_repo.check_member_access(
                        circle_id=str(family_id),
                        user_id=current_user_id,
                        raise_error=False
                    )
                    if is_member:
                        return True
            except Exception:
                pass
        
        return False
    
    async def _determine_family_id(
        self,
        record: HealthRecordCreate,
        current_user_id: str
    ) -> ObjectId:
        """
        Determine the correct family_id based on subject_type.
        
        - For SELF: Use user_id (personal record)
        - For FAMILY: Get family circle ID from subject_family_member_id or user's first family circle
        - For FRIEND: Use subject_friend_circle_id
        
        Args:
            record: Health record creation data
            current_user_id: ID of the user creating the record
            
        Returns:
            ObjectId representing the family_id
        """
        if record.subject_type == "self":
            return ObjectId(current_user_id)
        
        elif record.subject_type == "family":
            if record.subject_family_member_id:
                family_members_repo = FamilyMembersRepository()
                family_member = await family_members_repo.find_by_id(
                    record.subject_family_member_id,
                    raise_404=False
                )
                if family_member and family_member.get("family_id"):
                    return family_member["family_id"]
            
            family_repo = FamilyRepository()
            user_circles = await family_repo.find_by_member(current_user_id, limit=1)
            if user_circles:
                return user_circles[0]["_id"]
            
            return ObjectId(current_user_id)
        
        elif record.subject_type == "friend":
            if record.subject_friend_circle_id:
                return self.repository.validate_object_id(record.subject_friend_circle_id, "subject_friend_circle_id")
            return ObjectId(current_user_id)
        
        return ObjectId(current_user_id)
    
    async def get_health_dashboard(
        self,
        current_user_id: str
    ) -> Dict[str, Any]:
        """
        Get comprehensive health dashboard with all accessible records and stats.
        
        Args:
            current_user_id: ID of the current user
            
        Returns:
            Dashboard data with statistics, pending approvals, and reminders
        """
        try:
            user_oid = self.repository.validate_object_id(current_user_id, "user_id")
        except Exception as e:
            from fastapi import HTTPException
            raise HTTPException(status_code=400, detail=f"Invalid user ID: {str(e)}")
        
        from app.repositories.base_repository import BaseRepository
        reminders_repo = BaseRepository("health_record_reminders")
        
        family_repo = FamilyRepository()
        try:
            user_circles = await family_repo.find_by_member(current_user_id, limit=100)
        except Exception:
            user_circles = []
        
        user_circle_ids = [circle["_id"] for circle in user_circles if circle and "_id" in circle]
        
        # Build visibility-aware query
        # Records visible to user are:
        # 1. Records where user is subject (always visible)
        # 2. Records where user is creator (always visible)
        # 3. Records where user is assigned (always visible)
        # 4. Records with family/public visibility in user's family circles
        
        query_conditions: List[Dict[str, Any]] = [
            # Always visible: user is subject
            {"subject_user_id": user_oid},
            # Always visible: user created the record
            {"created_by": user_oid},
            # Always visible: user is assigned
            {"assigned_user_ids": user_oid}
        ]
        
        # Add family/public visibility from user's circles
        if user_circle_ids:
            query_conditions.append({
                "family_id": {"$in": user_circle_ids},
                "visibility_scope": {"$in": ["family", "public"]}
            })
        
        all_records_query = {
            "approval_status": "approved",
            "$or": query_conditions
        }
        
        all_records = await self.repository.find_many(
            filter_dict=all_records_query,
            limit=1000
        )
        
        pending_approvals = [
            r for r in all_records
            if r.get("subject_user_id") == user_oid
            and r.get("approval_status") == "pending_approval"
        ]
        
        user_reminders = await reminders_repo.find_many(
            filter_dict={
                "$or": [
                    {"assigned_user_id": user_oid},
                    {"created_by": user_oid}
                ],
                "status": {"$in": ["pending", "sent"]}
            },
            limit=10,
            sort_by="due_at",
            sort_order=1
        )
        
        stats = {
            "total_records": len(all_records),
            "pending_approvals": len(pending_approvals),
            "upcoming_reminders": len(user_reminders),
            "records_by_type": {},
            "recent_records": []
        }
        
        for record in all_records:
            rec_type = record.get("record_type", "unknown")
            stats["records_by_type"][rec_type] = stats["records_by_type"].get(rec_type, 0) + 1
        
        sorted_records = sorted(all_records, key=lambda x: x["created_at"], reverse=True)[:10]
        stats["recent_records"] = sorted_records
        
        await log_audit_event(
            user_id=str(current_user_id),
            event_type="VIEW_HEALTH_DASHBOARD",
            event_details={
                "resource_type": "health_dashboard",
                "total_records": stats["total_records"],
                "pending_approvals": stats["pending_approvals"],
                "upcoming_reminders": stats["upcoming_reminders"]
            }
        )
        
        return {
            "statistics": stats,
            "pending_approvals": pending_approvals,
            "upcoming_reminders": user_reminders
        }
