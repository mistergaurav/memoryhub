from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.health_records import (
    HealthRecordCreate, HealthRecordUpdate, HealthRecordResponse,
    VaccinationRecordCreate, VaccinationRecordResponse,
    RecordType
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None


@router.post("/", response_model=HealthRecordResponse, status_code=status.HTTP_201_CREATED)
async def create_health_record(
    record: HealthRecordCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new health record"""
    try:
        member_oid = safe_object_id(record.family_member_id)
        if not member_oid:
            raise HTTPException(status_code=400, detail="Invalid family member ID")
        
        record_data = {
            "family_id": ObjectId(current_user.id),
            "family_member_id": member_oid,
            "record_type": record.record_type,
            "title": record.title,
            "description": record.description,
            "date": record.date,
            "provider": record.provider,
            "location": record.location,
            "severity": record.severity,
            "attachments": record.attachments,
            "notes": record.notes,
            "medications": record.medications,
            "is_confidential": record.is_confidential,
            "created_by": ObjectId(current_user.id),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await get_collection("health_records").insert_one(record_data)
        record_doc = await get_collection("health_records").find_one({"_id": result.inserted_id})
        
        member = await get_collection("family_members").find_one({"_id": member_oid})
        member_name = member.get("name") if member else None
        
        return HealthRecordResponse(
            id=str(record_doc["_id"]),
            family_id=str(record_doc["family_id"]),
            family_member_id=str(record_doc["family_member_id"]),
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
            is_confidential=record_doc["is_confidential"],
            created_at=record_doc["created_at"],
            updated_at=record_doc["updated_at"],
            created_by=str(record_doc["created_by"])
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create health record: {str(e)}")


@router.get("/", response_model=List[HealthRecordResponse])
async def list_health_records(
    family_member_id: Optional[str] = Query(None),
    record_type: Optional[RecordType] = Query(None),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all health records with optional filtering"""
    try:
        user_oid = ObjectId(current_user.id)
        
        query = {"family_id": user_oid}
        
        if family_member_id:
            member_oid = safe_object_id(family_member_id)
            if member_oid:
                query["family_member_id"] = member_oid
        
        if record_type:
            query["record_type"] = record_type
        
        records_cursor = get_collection("health_records").find(query).sort("date", -1)
        
        records = []
        async for record_doc in records_cursor:
            member = await get_collection("family_members").find_one({"_id": record_doc["family_member_id"]})
            member_name = member.get("name") if member else None
            
            records.append(HealthRecordResponse(
                id=str(record_doc["_id"]),
                family_id=str(record_doc["family_id"]),
                family_member_id=str(record_doc["family_member_id"]),
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
                is_confidential=record_doc["is_confidential"],
                created_at=record_doc["created_at"],
                updated_at=record_doc["updated_at"],
                created_by=str(record_doc["created_by"])
            ))
        
        return records
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list health records: {str(e)}")


@router.get("/{record_id}", response_model=HealthRecordResponse)
async def get_health_record(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific health record"""
    try:
        record_oid = safe_object_id(record_id)
        if not record_oid:
            raise HTTPException(status_code=400, detail="Invalid record ID")
        
        record_doc = await get_collection("health_records").find_one({"_id": record_oid})
        if not record_doc:
            raise HTTPException(status_code=404, detail="Health record not found")
        
        if str(record_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to view this record")
        
        member = await get_collection("family_members").find_one({"_id": record_doc["family_member_id"]})
        member_name = member.get("name") if member else None
        
        return HealthRecordResponse(
            id=str(record_doc["_id"]),
            family_id=str(record_doc["family_id"]),
            family_member_id=str(record_doc["family_member_id"]),
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
            is_confidential=record_doc["is_confidential"],
            created_at=record_doc["created_at"],
            updated_at=record_doc["updated_at"],
            created_by=str(record_doc["created_by"])
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get health record: {str(e)}")


@router.put("/{record_id}", response_model=HealthRecordResponse)
async def update_health_record(
    record_id: str,
    record_update: HealthRecordUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a health record"""
    try:
        record_oid = safe_object_id(record_id)
        if not record_oid:
            raise HTTPException(status_code=400, detail="Invalid record ID")
        
        record_doc = await get_collection("health_records").find_one({"_id": record_oid})
        if not record_doc:
            raise HTTPException(status_code=404, detail="Health record not found")
        
        if str(record_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this record")
        
        update_data = {k: v for k, v in record_update.dict(exclude_unset=True).items() if v is not None}
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("health_records").update_one(
            {"_id": record_oid},
            {"$set": update_data}
        )
        
        updated_record = await get_collection("health_records").find_one({"_id": record_oid})
        member = await get_collection("family_members").find_one({"_id": updated_record["family_member_id"]})
        member_name = member.get("name") if member else None
        
        return HealthRecordResponse(
            id=str(updated_record["_id"]),
            family_id=str(updated_record["family_id"]),
            family_member_id=str(updated_record["family_member_id"]),
            family_member_name=member_name,
            record_type=updated_record["record_type"],
            title=updated_record["title"],
            description=updated_record.get("description"),
            date=updated_record["date"],
            provider=updated_record.get("provider"),
            location=updated_record.get("location"),
            severity=updated_record.get("severity"),
            attachments=updated_record.get("attachments", []),
            notes=updated_record.get("notes"),
            medications=updated_record.get("medications", []),
            is_confidential=updated_record["is_confidential"],
            created_at=updated_record["created_at"],
            updated_at=updated_record["updated_at"],
            created_by=str(updated_record["created_by"])
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update health record: {str(e)}")


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_health_record(
    record_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a health record"""
    try:
        record_oid = safe_object_id(record_id)
        if not record_oid:
            raise HTTPException(status_code=400, detail="Invalid record ID")
        
        record_doc = await get_collection("health_records").find_one({"_id": record_oid})
        if not record_doc:
            raise HTTPException(status_code=404, detail="Health record not found")
        
        if str(record_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this record")
        
        await get_collection("health_records").delete_one({"_id": record_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete health record: {str(e)}")


@router.post("/vaccinations", response_model=VaccinationRecordResponse, status_code=status.HTTP_201_CREATED)
async def create_vaccination_record(
    vaccination: VaccinationRecordCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a vaccination record"""
    try:
        member_oid = safe_object_id(vaccination.family_member_id)
        if not member_oid:
            raise HTTPException(status_code=400, detail="Invalid family member ID")
        
        vaccination_data = {
            "family_id": ObjectId(current_user.id),
            "family_member_id": member_oid,
            "vaccine_name": vaccination.vaccine_name,
            "date_administered": vaccination.date_administered,
            "provider": vaccination.provider,
            "lot_number": vaccination.lot_number,
            "next_dose_date": vaccination.next_dose_date,
            "notes": vaccination.notes,
            "created_by": ObjectId(current_user.id),
            "created_at": datetime.utcnow()
        }
        
        result = await get_collection("vaccination_records").insert_one(vaccination_data)
        vaccination_doc = await get_collection("vaccination_records").find_one({"_id": result.inserted_id})
        
        member = await get_collection("family_members").find_one({"_id": member_oid})
        member_name = member.get("name") if member else None
        
        return VaccinationRecordResponse(
            id=str(vaccination_doc["_id"]),
            family_id=str(vaccination_doc["family_id"]),
            family_member_id=str(vaccination_doc["family_member_id"]),
            family_member_name=member_name,
            vaccine_name=vaccination_doc["vaccine_name"],
            date_administered=vaccination_doc["date_administered"],
            provider=vaccination_doc.get("provider"),
            lot_number=vaccination_doc.get("lot_number"),
            next_dose_date=vaccination_doc.get("next_dose_date"),
            notes=vaccination_doc.get("notes"),
            created_at=vaccination_doc["created_at"],
            created_by=str(vaccination_doc["created_by"])
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create vaccination record: {str(e)}")


@router.get("/vaccinations", response_model=List[VaccinationRecordResponse])
async def list_vaccination_records(
    current_user: UserInDB = Depends(get_current_user)
):
    """List all vaccination records"""
    try:
        user_oid = ObjectId(current_user.id)
        
        vaccinations_cursor = get_collection("vaccination_records").find({
            "family_id": user_oid
        }).sort("date_administered", -1)
        
        vaccinations = []
        async for vacc_doc in vaccinations_cursor:
            member = await get_collection("family_members").find_one({"_id": vacc_doc["family_member_id"]})
            member_name = member.get("name") if member else None
            
            vaccinations.append(VaccinationRecordResponse(
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
            ))
        
        return vaccinations
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list vaccination records: {str(e)}")


@router.get("/member/{member_id}/summary")
async def get_health_summary(
    member_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get health summary for a family member"""
    try:
        member_oid = safe_object_id(member_id)
        if not member_oid:
            raise HTTPException(status_code=400, detail="Invalid member ID")
        
        user_oid = ObjectId(current_user.id)
        
        health_records_cursor = get_collection("health_records").find({
            "family_id": user_oid,
            "family_member_id": member_oid
        }).sort("date", -1)
        
        vaccinations_cursor = get_collection("vaccination_records").find({
            "family_id": user_oid,
            "family_member_id": member_oid
        }).sort("date_administered", -1)
        
        health_records = []
        async for record_doc in health_records_cursor:
            health_records.append({
                "id": str(record_doc["_id"]),
                "record_type": record_doc["record_type"],
                "title": record_doc["title"],
                "date": record_doc["date"],
                "severity": record_doc.get("severity")
            })
        
        vaccinations = []
        async for vacc_doc in vaccinations_cursor:
            vaccinations.append({
                "id": str(vacc_doc["_id"]),
                "vaccine_name": vacc_doc["vaccine_name"],
                "date_administered": vacc_doc["date_administered"],
                "next_dose_date": vacc_doc.get("next_dose_date")
            })
        
        member = await get_collection("family_members").find_one({"_id": member_oid})
        
        summary = {
            "member_id": member_id,
            "member_name": member.get("name") if member else None,
            "total_health_records": len(health_records),
            "total_vaccinations": len(vaccinations),
            "recent_health_records": health_records[:5],
            "recent_vaccinations": vaccinations[:5],
            "records_by_type": {}
        }
        
        for record in health_records:
            record_type = record["record_type"]
            summary["records_by_type"][record_type] = summary["records_by_type"].get(record_type, 0) + 1
        
        return summary
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get health summary: {str(e)}")
