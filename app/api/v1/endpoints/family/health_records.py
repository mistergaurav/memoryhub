from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.family.health_records import (
    HealthRecordCreate, HealthRecordUpdate, HealthRecordResponse,
    VaccinationRecordCreate, VaccinationRecordResponse,
    RecordType, ApprovalStatus
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.family_repository import HealthRecordsRepository, FamilyMembersRepository
from app.repositories.base_repository import BaseRepository
from app.models.responses import create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event

router = APIRouter()

health_records_repo = HealthRecordsRepository()
vaccination_repo = BaseRepository("vaccination_records")
family_members_repo = FamilyMembersRepository()


def health_record_to_response(record_doc: dict, member_name: Optional[str] = None) -> HealthRecordResponse:
    """Convert MongoDB health record document to response model"""
    return HealthRecordResponse(
        id=str(record_doc["_id"]),
        family_id=str(record_doc["family_id"]),
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
        approval_status=record_doc.get("approval_status", ApprovalStatus.APPROVED),
        approved_at=record_doc.get("approved_at"),
        approved_by=record_doc.get("approved_by"),
        rejection_reason=record_doc.get("rejection_reason"),
        created_at=record_doc["created_at"],
        updated_at=record_doc["updated_at"],
        created_by=str(record_doc["created_by"])
    )


def vaccination_to_response(vacc_doc: dict, member_name: Optional[str] = None) -> VaccinationRecordResponse:
    """Convert MongoDB vaccination record document to response model"""
    return VaccinationRecordResponse(
        id=str(vacc_doc["_id"]),
        family_id=str(vacc_doc["family_id"]),
        family_member_id=str(vacc_doc["family_member_id"]),
        family_member_name=member_name,
        vaccine_name=vacc_doc["vaccine_name"],
        date_administered=vacc_doc["date_administered"],
        provider=vacc_doc.get("provider"),
        lot_number=vacc_doc.get("lot_number"),
        next_dose_date=vacc_doc.get("next_dose_date"),
        notes=vacc_doc.get("notes"),
        created_at=vacc_doc["created_at"],
        created_by=str(vacc_doc["created_by"])
    )


async def get_member_name(member_id: Optional[ObjectId]) -> Optional[str]:
    """Get family member name by ID"""
    if not member_id:
        return None
    return await family_members_repo.get_member_name(str(member_id))


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_health_record(
    record: HealthRecordCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new health record with support for self, family, and friend subjects"""
    
    record_data = {
        "family_id": ObjectId(current_user.id),
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
        "created_by": ObjectId(current_user.id)
    }
    
    if record.subject_user_id:
        record_data["subject_user_id"] = health_records_repo.validate_object_id(record.subject_user_id, "subject_user_id")
    
    if record.subject_family_member_id:
        record_data["subject_family_member_id"] = health_records_repo.validate_object_id(record.subject_family_member_id, "subject_family_member_id")
    
    if record.subject_friend_circle_id:
        record_data["subject_friend_circle_id"] = health_records_repo.validate_object_id(record.subject_friend_circle_id, "subject_friend_circle_id")
    
    if record.assigned_user_ids:
        record_data["assigned_user_ids"] = [
            health_records_repo.validate_object_id(user_id, "assigned_user_id")
            for user_id in record.assigned_user_ids
        ]
    
    if record.family_member_id:
        record_data["family_member_id"] = health_records_repo.validate_object_id(record.family_member_id, "family_member_id")
    
    if record.genealogy_person_id:
        record_data["genealogy_person_id"] = health_records_repo.validate_object_id(record.genealogy_person_id, "genealogy_person_id")
    
    # Determine approval status
    if record.subject_user_id and record.subject_user_id != current_user.id:
        # Record is being created for another user - requires approval
        record_data["approval_status"] = "pending_approval"
    else:
        # Record is for self or family member (not another user) - auto-approved
        record_data["approval_status"] = "approved"
        record_data["approved_at"] = datetime.utcnow()
        record_data["approved_by"] = str(current_user.id)
    
    record_doc = await health_records_repo.create(record_data)
    
    member_name = None
    if record.family_member_id:
        member_name = await get_member_name(ObjectId(record.family_member_id))
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_HEALTH_RECORD",
        event_details={
            "resource_type": "health_record",
            "resource_id": str(record_doc["_id"]),
            "record_type": record.record_type,
            "subject_type": record.subject_type,
            "is_confidential": record.is_confidential
        }
    )
    
    return create_success_response(
        message="Health record created successfully",
        data=health_record_to_response(record_doc, member_name)
    )


@router.get("/")
async def list_health_records(
    family_member_id: Optional[str] = Query(None),
    record_type: Optional[RecordType] = Query(None),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all health records with optional filtering and pagination"""
    user_oid = ObjectId(current_user.id)
    
    # Include records where user is the owner OR where user is the subject
    query: Dict[str, Any] = {
        "$or": [
            {"family_id": user_oid},
            {"subject_user_id": user_oid}
        ]
    }
    
    if family_member_id:
        member_oid = health_records_repo.validate_object_id(family_member_id, "family_member_id")
        query["family_member_id"] = member_oid
    
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


@router.get("/{record_id}")
async def get_health_record(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific health record"""
    record_doc = await health_records_repo.find_by_id(
        record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    if not record_doc:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    if str(record_doc["family_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this record")
    
    member_id = record_doc.get("family_member_id")
    member_name = await get_member_name(member_id) if member_id else None
    
    return create_success_response(
        message="Health record retrieved successfully",
        data=health_record_to_response(record_doc, member_name)
    )


@router.put("/{record_id}")
async def update_health_record(
    record_id: str,
    record_update: HealthRecordUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a health record"""
    record_doc = await health_records_repo.find_by_id(
        record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    if not record_doc:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    if str(record_doc["family_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this record")
    
    update_data = {k: v for k, v in record_update.dict(exclude_unset=True).items() if v is not None}
    
    updated_record = await health_records_repo.update_by_id(record_id, update_data)
    
    if not updated_record:
        raise HTTPException(status_code=404, detail="Failed to update health record")
    
    member_id = updated_record.get("family_member_id")
    member_name = await get_member_name(member_id) if member_id else None
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="UPDATE_HEALTH_RECORD",
        event_details={
            "resource_type": "health_record",
            "resource_id": record_id,
            "updates": list(update_data.keys())
        }
    )
    
    return create_success_response(
        message="Health record updated successfully",
        data=health_record_to_response(updated_record, member_name)
    )


@router.delete("/{record_id}", status_code=status.HTTP_200_OK)
async def delete_health_record(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a health record"""
    record_doc = await health_records_repo.find_by_id(
        record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    if not record_doc:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    if str(record_doc["family_id"]) != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this record")
    
    await health_records_repo.delete_by_id(record_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="DELETE_HEALTH_RECORD",
        event_details={
            "resource_type": "health_record",
            "resource_id": record_id,
            "record_type": record_doc.get("record_type")
        }
    )
    
    return create_success_response(message="Health record deleted successfully")


@router.post("/{record_id}/approve", status_code=status.HTTP_200_OK)
async def approve_health_record(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Approve a health record that was created for you"""
    # Find the record
    record_doc = await health_records_repo.find_by_id(
        record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    if not record_doc:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    # Verify current_user is the subject_user_id (only assigned user can approve)
    subject_user_id = record_doc.get("subject_user_id")
    if not subject_user_id or str(subject_user_id) != current_user.id:
        raise HTTPException(
            status_code=403, 
            detail="Only the assigned user can approve this health record"
        )
    
    # Check if already approved or rejected
    current_status = record_doc.get("approval_status", "approved")
    if current_status == "approved":
        raise HTTPException(
            status_code=400, 
            detail="Health record is already approved"
        )
    if current_status == "rejected":
        raise HTTPException(
            status_code=400, 
            detail="Health record has been rejected. Cannot approve a rejected record."
        )
    
    # Update approval_status to "approved"
    update_data = {
        "approval_status": "approved",
        "approved_at": datetime.utcnow(),
        "approved_by": str(current_user.id)
    }
    
    updated_record = await health_records_repo.update_by_id(record_id, update_data)
    
    if not updated_record:
        raise HTTPException(status_code=404, detail="Failed to approve health record")
    
    # Log audit event
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="APPROVE_HEALTH_RECORD",
        event_details={
            "resource_type": "health_record",
            "resource_id": record_id,
            "record_type": record_doc.get("record_type"),
            "created_by": str(record_doc.get("created_by"))
        }
    )
    
    member_id = updated_record.get("family_member_id")
    member_name = await get_member_name(member_id) if member_id else None
    
    # Return success response with updated record
    return create_success_response(
        message="Health record approved successfully",
        data=health_record_to_response(updated_record, member_name)
    )


@router.post("/{record_id}/reject", status_code=status.HTTP_200_OK)
async def reject_health_record(
    record_id: str,
    rejection_reason: Optional[str] = Query(None, max_length=500),
    current_user: UserInDB = Depends(get_current_user)
):
    """Reject a health record that was created for you"""
    # Find the record
    record_doc = await health_records_repo.find_by_id(
        record_id,
        raise_404=True,
        error_message="Health record not found"
    )
    
    if not record_doc:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    # Verify current_user is the subject_user_id
    subject_user_id = record_doc.get("subject_user_id")
    if not subject_user_id or str(subject_user_id) != current_user.id:
        raise HTTPException(
            status_code=403, 
            detail="Only the assigned user can reject this health record"
        )
    
    # Check if already approved or rejected
    current_status = record_doc.get("approval_status", "approved")
    if current_status == "approved":
        raise HTTPException(
            status_code=400, 
            detail="Health record is already approved. Cannot reject an approved record."
        )
    if current_status == "rejected":
        raise HTTPException(
            status_code=400, 
            detail="Health record is already rejected"
        )
    
    # Update approval_status to "rejected"
    update_data = {
        "approval_status": "rejected"
    }
    
    # Set rejection_reason if provided
    if rejection_reason:
        update_data["rejection_reason"] = rejection_reason
    
    updated_record = await health_records_repo.update_by_id(record_id, update_data)
    
    if not updated_record:
        raise HTTPException(status_code=404, detail="Failed to reject health record")
    
    # Log audit event
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="REJECT_HEALTH_RECORD",
        event_details={
            "resource_type": "health_record",
            "resource_id": record_id,
            "record_type": record_doc.get("record_type"),
            "created_by": str(record_doc.get("created_by")),
            "rejection_reason": rejection_reason
        }
    )
    
    member_id = updated_record.get("family_member_id")
    member_name = await get_member_name(member_id) if member_id else None
    
    # Return success response
    return create_success_response(
        message="Health record rejected successfully",
        data=health_record_to_response(updated_record, member_name)
    )


@router.post("/vaccinations", status_code=status.HTTP_201_CREATED)
async def create_vaccination_record(
    vaccination: VaccinationRecordCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a vaccination record"""
    member_oid = vaccination_repo.validate_object_id(vaccination.family_member_id, "family_member_id")
    
    vaccination_data = {
        "family_id": ObjectId(current_user.id),
        "family_member_id": member_oid,
        "vaccine_name": vaccination.vaccine_name,
        "date_administered": vaccination.date_administered,
        "provider": vaccination.provider,
        "lot_number": vaccination.lot_number,
        "next_dose_date": vaccination.next_dose_date,
        "notes": vaccination.notes,
        "created_by": ObjectId(current_user.id)
    }
    
    vaccination_doc = await vaccination_repo.create(vaccination_data)
    
    member_name = await get_member_name(member_oid)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="CREATE_VACCINATION_RECORD",
        event_details={
            "resource_type": "vaccination_record",
            "resource_id": str(vaccination_doc["_id"]),
            "vaccine_name": vaccination.vaccine_name
        }
    )
    
    return create_success_response(
        message="Vaccination record created successfully",
        data=vaccination_to_response(vaccination_doc, member_name)
    )


@router.get("/vaccinations")
async def list_vaccination_records(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all vaccination records with pagination"""
    user_oid = ObjectId(current_user.id)
    
    skip = (page - 1) * page_size
    vaccinations = await vaccination_repo.find_many(
        filter_dict={"family_id": user_oid},
        skip=skip,
        limit=page_size,
        sort_by="date_administered",
        sort_order=-1
    )
    
    total = await vaccination_repo.count({"family_id": user_oid})
    
    vaccination_responses = []
    for vacc_doc in vaccinations:
        member_name = await get_member_name(vacc_doc.get("family_member_id"))
        vaccination_responses.append(vaccination_to_response(vacc_doc, member_name))
    
    return create_paginated_response(
        items=vaccination_responses,
        total=total,
        page=page,
        page_size=page_size,
        message="Vaccination records retrieved successfully"
    )


@router.get("/member/{member_id}/summary")
async def get_health_summary(
    member_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get health summary for a family member"""
    member_oid = health_records_repo.validate_object_id(member_id, "member_id")
    user_oid = ObjectId(current_user.id)
    
    health_records = await health_records_repo.find_many(
        filter_dict={
            "family_id": user_oid,
            "family_member_id": member_oid
        },
        sort_by="date",
        sort_order=-1,
        limit=1000
    )
    
    vaccinations = await vaccination_repo.find_many(
        filter_dict={
            "family_id": user_oid,
            "family_member_id": member_oid
        },
        sort_by="date_administered",
        sort_order=-1,
        limit=1000
    )
    
    health_records_summary = []
    for record_doc in health_records[:5]:
        health_records_summary.append({
            "id": str(record_doc["_id"]),
            "record_type": record_doc["record_type"],
            "title": record_doc["title"],
            "date": record_doc["date"],
            "severity": record_doc.get("severity")
        })
    
    vaccinations_summary = []
    for vacc_doc in vaccinations[:5]:
        vaccinations_summary.append({
            "id": str(vacc_doc["_id"]),
            "vaccine_name": vacc_doc["vaccine_name"],
            "date_administered": vacc_doc["date_administered"],
            "next_dose_date": vacc_doc.get("next_dose_date")
        })
    
    member_name = await family_members_repo.get_member_name(member_id)
    
    records_by_type = {}
    for record in health_records:
        record_type = record["record_type"]
        records_by_type[record_type] = records_by_type.get(record_type, 0) + 1
    
    summary = {
        "member_id": member_id,
        "member_name": member_name,
        "total_health_records": len(health_records),
        "total_vaccinations": len(vaccinations),
        "recent_health_records": health_records_summary,
        "recent_vaccinations": vaccinations_summary,
        "records_by_type": records_by_type
    }
    
    return create_success_response(
        message="Health summary retrieved successfully",
        data=summary
    )
