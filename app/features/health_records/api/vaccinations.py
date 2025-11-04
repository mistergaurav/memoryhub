from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional
from bson import ObjectId
from pymongo.errors import PyMongoError
import logging

from ..schemas.health_records import (
    VaccinationRecordCreate,
    VaccinationRecordResponse,
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.repositories.base_repository import BaseRepository
from app.repositories.family_repository import FamilyMembersRepository
from app.models.responses import create_success_response, create_paginated_response
from app.utils.audit_logger import log_audit_event

logger = logging.getLogger(__name__)

router = APIRouter()

vaccination_repo = BaseRepository("vaccination_records")
health_records_repo = BaseRepository("health_records")
family_members_repo = FamilyMembersRepository()


def vaccination_to_response(vacc_doc: dict, member_name: Optional[str] = None) -> VaccinationRecordResponse:
    """Convert MongoDB vaccination record document to response model"""
    if not vacc_doc:
        raise ValueError("Vaccination document is None or empty")
    
    try:
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
    except KeyError as e:
        logger.error(f"Missing required field in vaccination document: {str(e)}")
        raise ValueError(f"Invalid vaccination document: missing field {str(e)}")


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
async def create_vaccination_record(
    vaccination: VaccinationRecordCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a vaccination record"""
    try:
        try:
            member_oid = vaccination_repo.validate_object_id(vaccination.family_member_id, "family_member_id")
        except ValueError as e:
            raise ValueError(f"Invalid family_member_id: {str(e)}")
        
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
        
        if not vaccination_doc:
            raise ValueError("Failed to create vaccination record")
        
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
    except ValueError as e:
        logger.error(f"Validation error creating vaccination record: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error creating vaccination record: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error creating vaccination record: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.get("/")
async def list_vaccination_records(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all vaccination records with pagination"""
    try:
        try:
            user_oid = ObjectId(current_user.id)
        except Exception:
            raise ValueError(f"Invalid user ID format: {current_user.id}")
        
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
            if vacc_doc:
                member_name = await get_member_name(vacc_doc.get("family_member_id"))
                vaccination_responses.append(vaccination_to_response(vacc_doc, member_name))
        
        return create_paginated_response(
            items=vaccination_responses,
            total=total,
            page=page,
            page_size=page_size,
            message="Vaccination records retrieved successfully"
        )
    except ValueError as e:
        logger.error(f"Validation error listing vaccination records: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error listing vaccination records: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error listing vaccination records: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")


@router.get("/member/{member_id}/summary")
async def get_health_summary(
    member_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get health summary for a family member"""
    try:
        if not member_id:
            raise ValueError("Member ID is required")
        
        try:
            member_oid = vaccination_repo.validate_object_id(member_id, "member_id")
        except ValueError as e:
            raise ValueError(f"Invalid member_id: {str(e)}")
        
        try:
            user_oid = ObjectId(current_user.id)
        except Exception:
            raise ValueError(f"Invalid user ID format: {current_user.id}")
        
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
            if record_doc and "_id" in record_doc:
                health_records_summary.append({
                    "id": str(record_doc["_id"]),
                    "record_type": record_doc.get("record_type", "unknown"),
                    "title": record_doc.get("title", ""),
                    "date": record_doc.get("date"),
                    "severity": record_doc.get("severity")
                })
        
        vaccinations_summary = []
        for vacc_doc in vaccinations[:5]:
            if vacc_doc and "_id" in vacc_doc:
                vaccinations_summary.append({
                    "id": str(vacc_doc["_id"]),
                    "vaccine_name": vacc_doc.get("vaccine_name", ""),
                    "date_administered": vacc_doc.get("date_administered"),
                    "next_dose_date": vacc_doc.get("next_dose_date")
                })
        
        member_name = await family_members_repo.get_member_name(member_id)
        
        records_by_type = {}
        for record in health_records:
            if record and "record_type" in record:
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
    except ValueError as e:
        logger.error(f"Validation error getting health summary for member {member_id}: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except PyMongoError as e:
        logger.error(f"Database error getting health summary for member {member_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")
    except Exception as e:
        logger.error(f"Error getting health summary for member {member_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred. Please contact support.")
