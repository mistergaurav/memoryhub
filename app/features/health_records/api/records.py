from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, Dict, Any, List
from bson import ObjectId
from pymongo.errors import PyMongoError
import logging

from ..schemas.health_records import (
    HealthRecordCreate,
    HealthRecordUpdate,
    HealthRecordResponse,
    RecordType,
    ApprovalStatus,
    HealthRecordApprovalRequest,
)
from ..services.health_record_service import HealthRecordService
from ..repositories.health_records_repository import HealthRecordsRepository
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.family_repository import FamilyMembersRepository
from app.models.responses import create_success_response, create_paginated_response

logger = logging.getLogger(__name__)

router = APIRouter()

health_record_service = HealthRecordService()
health_records_repo = HealthRecordsRepository()
family_members_repo = FamilyMembersRepository()


def health_record_to_response(record_doc: dict, member_name: Optional[str] = None) -> HealthRecordResponse:
    """Convert MongoDB health record document to response model"""
    if not record_doc:
        raise ValueError("Record document is None or empty")
    
    try:
        return HealthRecordResponse(
            id=str(record_doc["_id"]),
            family_id=str(record_doc["family_id"]),
            subject_type=record_doc.get("subject_type", "self"),
            subject_user_id=str(record_doc["subject_user_id"]) if record_doc.get("subject_user_id") else None,
            subject_family_member_id=str(record_doc["subject_family_member_id"]) if record_doc.get("subject_family_member_id") else None,
            subject_friend_circle_id=str(record_doc["subject_friend_circle_id"]) if record_doc.get("subject_friend_circle_id") else None,
            assigned_user_ids=[str(uid) for uid in record_doc.get("assigned_user_ids", [])],
            family_member_id=str(record_doc.get("family_member_id", "")),
            family_member_name=member_name,
            record_type=record_doc["record_type"],
            title=record_doc["title"],
            description=record_doc.get("description"),
            date=record_doc["date"],
            provider=record_doc.get("provider"),
            location=record_doc.get("location"),
            severity=record_doc.get("severity"),
            attachments=record_doc.get("attachments", []),
            notes=record_doc.get("notes"),
            medications=record_doc.get("medications", []),
            is_confidential=record_doc.get("is_confidential", False),
            is_hereditary=record_doc.get("is_hereditary", False),
            inheritance_pattern=record_doc.get("inheritance_pattern"),
            age_of_onset=record_doc.get("age_of_onset"),
            affected_relatives=record_doc.get("affected_relatives", []),
            genetic_test_results=record_doc.get("genetic_test_results"),
            approval_status=record_doc.get("approval_status", ApprovalStatus.APPROVED),
            approved_at=record_doc.get("approved_at"),
            approved_by=record_doc.get("approved_by"),
            rejection_reason=record_doc.get("rejection_reason"),
            visibility_scope=record_doc.get("visibility_scope", "private"),
            created_at=record_doc["created_at"],
            updated_at=record_doc["updated_at"],
            created_by=str(record_doc["created_by"])
        )
    except KeyError as e:
        logger.error(f"Missing required field in record document: {str(e)}")
        raise ValueError(f"Invalid record document: missing field {str(e)}")


async def get_member_name(member_id: Optional[ObjectId]) -> Optional[str]:
    """Get family member name by ID"""
    if not member_id:
        return None
    try:
        return await family_members_repo.get_member_name(str(member_id))
    except Exception as e:
        logger.error(f"Error getting member name for {member_id}: {str(e)}")
        return None


@router.post("/", status_code=status.HTTP_201_CREATED)
@router.post("", status_code=status.HTTP_201_CREATED)
async def create_health_record(
    record: HealthRecordCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new health record with support for self, family, and friend subjects"""
    try:
        if record.family_member_id:
            try:
                ObjectId(record.family_member_id)
            except Exception:
                raise ValueError(f"Invalid family_member_id format: {record.family_member_id}")
        
        record_doc = await health_record_service.create_health_record(
            record,
            str(current_user.id),
            current_user.full_name
        )
        
        if not record_doc:
            raise ValueError("Failed to create health record")
        
        member_name = None
        if record.family_member_id:
            member_name = await get_member_name(ObjectId(record.family_member_id))
        
        return create_success_response(
            message="Health record created successfully",
            data=health_record_to_response(record_doc, member_name)
        )
    except HTTPException:
        # Re-raise HTTPException as-is (don't wrap as 500)
        raise
    except ValueError as e:
        logger.error(f"Validation error creating health record: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error creating health record: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error creating health record: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.get("/")
@router.get("")
async def list_health_records(
    family_member_id: Optional[str] = Query(None),
    record_type: Optional[RecordType] = Query(None),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all health records with optional filtering and pagination"""
    try:
        try:
            user_oid = ObjectId(current_user.id)
        except Exception:
            raise ValueError(f"Invalid user ID format: {current_user.id}")
        
        # Build visibility-aware query
        # Get user's family circles for visibility filtering
        from app.repositories.family_repository import FamilyRepository
        family_repo = FamilyRepository()
        try:
            user_circles = await family_repo.find_by_member(str(current_user.id), limit=100)
            user_circle_ids = [circle["_id"] for circle in user_circles if circle and "_id" in circle]
        except Exception:
            user_circle_ids = []
        
        # Build query with visibility scope filtering
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
        
        query: Dict[str, Any] = {
            "approval_status": "approved",
            "$or": query_conditions
        }
        
        if family_member_id:
            try:
                member_oid = health_records_repo.validate_object_id(family_member_id, "family_member_id")
                query["family_member_id"] = member_oid
            except ValueError as e:
                raise ValueError(f"Invalid family_member_id: {str(e)}")
        
        if record_type:
            query["record_type"] = record_type
        
        skip = (page - 1) * page_size
        records = await health_records_repo.find_many(
            filter_dict=query,
            skip=skip,
            limit=page_size,
            sort_by="date",
            sort_order=-1
        )
        
        total = await health_records_repo.count(query)
        
        record_responses = []
        for record_doc in records:
            if record_doc:
                member_id = record_doc.get("family_member_id")
                member_name = await get_member_name(member_id) if member_id else None
                record_responses.append(health_record_to_response(record_doc, member_name))
        
        return create_paginated_response(
            items=record_responses,
            total=total,
            page=page,
            page_size=page_size,
            message="Health records retrieved successfully"
        )
    except ValueError as e:
        logger.error(f"Validation error listing health records: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error listing health records: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error listing health records: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.get("/dashboard")
async def get_health_dashboard(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get comprehensive health dashboard with all accessible records and stats"""
    try:
        dashboard_data = await health_record_service.get_health_dashboard(str(current_user.id))
        
        if not dashboard_data:
            raise ValueError("Failed to retrieve dashboard data")
        
        recent_records = []
        for record_doc in dashboard_data.get("statistics", {}).get("recent_records", []):
            if isinstance(record_doc, dict):
                try:
                    member_id = record_doc.get("family_member_id")
                    member_name = None
                    if member_id:
                        member_name = await get_member_name(member_id)
                    recent_records.append(health_record_to_response(record_doc, member_name))
                except Exception as e:
                    logger.error(f"Error processing recent record: {str(e)}")
                    continue
        
        pending_approvals = []
        for r in dashboard_data.get("pending_approvals", []):
            if r:
                try:
                    pending_approvals.append(health_record_to_response(r))
                except Exception as e:
                    logger.error(f"Error processing pending approval: {str(e)}")
                    continue
        
        stats = dashboard_data.get("statistics", {})
        stats["recent_records"] = recent_records
        
        reminders = []
        for reminder in dashboard_data.get("upcoming_reminders", []):
            if reminder:
                try:
                    reminder_formatted = {
                        "id": str(reminder.get("_id", "")),
                        "title": reminder.get("title", ""),
                        "due_at": reminder.get("due_at"),
                        "status": reminder.get("status", "pending"),
                        "record_id": str(reminder.get("record_id", "")) if reminder.get("record_id") else None
                    }
                    reminders.append(reminder_formatted)
                except Exception as e:
                    logger.error(f"Error processing reminder: {str(e)}")
                    continue
        
        return create_success_response(
            message="Health dashboard retrieved successfully",
            data={
                "statistics": stats,
                "pending_approvals": pending_approvals,
                "upcoming_reminders": reminders
            }
        )
    except ValueError as e:
        logger.error(f"Validation error getting dashboard: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error getting dashboard: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error getting health dashboard: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.get("/{record_id}")
async def get_health_record(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific health record"""
    try:
        if not record_id:
            raise HTTPException(status_code=404, detail="Health record not found")
        
        try:
            record_doc = await health_records_repo.find_by_id(
                record_id,
                raise_404=True,
                error_message="Health record not found"
            )
        except HTTPException as e:
            if e.status_code == 400:
                raise HTTPException(status_code=404, detail="Health record not found")
            raise
        
        if not record_doc:
            raise HTTPException(status_code=404, detail="Health record not found")
        
        has_access = await health_record_service.check_user_has_access(record_doc, str(current_user.id))
        if not has_access:
            raise HTTPException(status_code=403, detail="Not authorized to view this record")
        
        member_id = record_doc.get("family_member_id")
        member_name = await get_member_name(member_id) if member_id else None
        
        return create_success_response(
            message="Health record retrieved successfully",
            data=health_record_to_response(record_doc, member_name)
        )
    except HTTPException:
        raise
    except PyMongoError as e:
        logger.error(f"Database error getting health record {record_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error getting health record {record_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.put("/{record_id}")
async def update_health_record(
    record_id: str,
    record_update: HealthRecordUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a health record"""
    try:
        if not record_id:
            raise ValueError("Record ID is required")
        
        updated_record = await health_record_service.update_health_record(
            record_id,
            record_update,
            str(current_user.id)
        )
        
        if not updated_record:
            raise ValueError("Failed to update health record")
        
        member_id = updated_record.get("family_member_id")
        member_name = await get_member_name(member_id) if member_id else None
        
        return create_success_response(
            message="Health record updated successfully",
            data=health_record_to_response(updated_record, member_name)
        )
    except ValueError as e:
        logger.error(f"Validation error updating health record {record_id}: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error updating health record {record_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error updating health record {record_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.delete("/{record_id}", status_code=status.HTTP_200_OK)
async def delete_health_record(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a health record"""
    try:
        if not record_id:
            raise ValueError("Record ID is required")
        
        await health_record_service.delete_health_record(record_id, str(current_user.id))
        return create_success_response(message="Health record deleted successfully")
    except ValueError as e:
        logger.error(f"Validation error deleting health record {record_id}: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error deleting health record {record_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error deleting health record {record_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.post("/{record_id}/approve", status_code=status.HTTP_200_OK)
async def approve_health_record(
    record_id: str,
    approval_request: HealthRecordApprovalRequest,
    current_user: UserInDB = Depends(get_current_user)
):
    """Approve a health record that was created for you with visibility selection"""
    try:
        if not record_id:
            raise ValueError("Record ID is required")
        
        updated_record = await health_record_service.approve_health_record(
            record_id,
            str(current_user.id),
            current_user.full_name,
            approval_request.visibility_scope
        )
        
        if not updated_record:
            raise ValueError("Failed to approve health record")
        
        member_id = updated_record.get("family_member_id")
        member_name = await get_member_name(member_id) if member_id else None
        
        return create_success_response(
            message="Health record approved successfully",
            data=health_record_to_response(updated_record, member_name)
        )
    except ValueError as e:
        logger.error(f"Validation error approving health record {record_id}: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error approving health record {record_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error approving health record {record_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.post("/{record_id}/reject", status_code=status.HTTP_200_OK)
async def reject_health_record(
    record_id: str,
    rejection_reason: Optional[str] = Query(None, max_length=500),
    current_user: UserInDB = Depends(get_current_user)
):
    """Reject a health record that was created for you"""
    try:
        if not record_id:
            raise ValueError("Record ID is required")
        
        updated_record = await health_record_service.reject_health_record(
            record_id,
            str(current_user.id),
            current_user.full_name,
            rejection_reason
        )
        
        if not updated_record:
            raise ValueError("Failed to reject health record")
        
        member_id = updated_record.get("family_member_id")
        member_name = await get_member_name(member_id) if member_id else None
        
        return create_success_response(
            message="Health record rejected successfully",
            data=health_record_to_response(updated_record, member_name)
        )
    except ValueError as e:
        logger.error(f"Validation error rejecting health record {record_id}: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error rejecting health record {record_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error rejecting health record {record_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")
