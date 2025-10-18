from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.document_vault import (
    DocumentVaultCreate, DocumentVaultUpdate, DocumentVaultResponse,
    DocumentAccessLogResponse, DocumentType
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


@router.post("/", response_model=DocumentVaultResponse, status_code=status.HTTP_201_CREATED)
async def create_document(
    document: DocumentVaultCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create/upload a document"""
    try:
        member_oid = None
        if document.family_member_id:
            member_oid = safe_object_id(document.family_member_id)
            if not member_oid:
                raise HTTPException(status_code=400, detail="Invalid family member ID")
        
        document_data = {
            "family_id": ObjectId(current_user.id),
            "document_type": document.document_type,
            "title": document.title,
            "description": document.description,
            "file_url": document.file_url,
            "file_name": document.file_name,
            "file_size": document.file_size,
            "mime_type": document.mime_type,
            "family_member_id": member_oid,
            "expiration_date": document.expiration_date,
            "document_number": document.document_number,
            "issuing_authority": document.issuing_authority,
            "tags": document.tags,
            "notes": document.notes,
            "is_encrypted": document.is_encrypted,
            "access_level": document.access_level,
            "created_by": ObjectId(current_user.id),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "last_accessed_at": None
        }
        
        result = await get_collection("document_vault").insert_one(document_data)
        document_doc = await get_collection("document_vault").find_one({"_id": result.inserted_id})
        
        member_name = None
        if member_oid:
            member = await get_collection("family_members").find_one({"_id": member_oid})
            member_name = member.get("name") if member else None
        
        return DocumentVaultResponse(
            id=str(document_doc["_id"]),
            family_id=str(document_doc["family_id"]),
            document_type=document_doc["document_type"],
            title=document_doc["title"],
            description=document_doc.get("description"),
            file_url=document_doc["file_url"],
            file_name=document_doc["file_name"],
            file_size=document_doc["file_size"],
            mime_type=document_doc["mime_type"],
            family_member_id=str(document_doc["family_member_id"]) if document_doc.get("family_member_id") else None,
            family_member_name=member_name,
            expiration_date=document_doc.get("expiration_date"),
            document_number=document_doc.get("document_number"),
            issuing_authority=document_doc.get("issuing_authority"),
            tags=document_doc.get("tags", []),
            notes=document_doc.get("notes"),
            is_encrypted=document_doc["is_encrypted"],
            access_level=document_doc["access_level"],
            created_at=document_doc["created_at"],
            updated_at=document_doc["updated_at"],
            created_by=str(document_doc["created_by"]),
            last_accessed_at=document_doc.get("last_accessed_at")
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create document: {str(e)}")


@router.get("/", response_model=List[DocumentVaultResponse])
async def list_documents(
    document_type: Optional[DocumentType] = Query(None),
    current_user: UserInDB = Depends(get_current_user)
):
    """List all documents with optional filtering"""
    try:
        user_oid = ObjectId(current_user.id)
        
        query = {"family_id": user_oid}
        
        if document_type:
            query["document_type"] = document_type
        
        documents_cursor = get_collection("document_vault").find(query).sort("updated_at", -1)
        
        documents = []
        async for doc in documents_cursor:
            member_name = None
            if doc.get("family_member_id"):
                member = await get_collection("family_members").find_one({"_id": doc["family_member_id"]})
                member_name = member.get("name") if member else None
            
            documents.append(DocumentVaultResponse(
                id=str(doc["_id"]),
                family_id=str(doc["family_id"]),
                document_type=doc["document_type"],
                title=doc["title"],
                description=doc.get("description"),
                file_url=doc["file_url"],
                file_name=doc["file_name"],
                file_size=doc["file_size"],
                mime_type=doc["mime_type"],
                family_member_id=str(doc["family_member_id"]) if doc.get("family_member_id") else None,
                family_member_name=member_name,
                expiration_date=doc.get("expiration_date"),
                document_number=doc.get("document_number"),
                issuing_authority=doc.get("issuing_authority"),
                tags=doc.get("tags", []),
                notes=doc.get("notes"),
                is_encrypted=doc["is_encrypted"],
                access_level=doc["access_level"],
                created_at=doc["created_at"],
                updated_at=doc["updated_at"],
                created_by=str(doc["created_by"]),
                last_accessed_at=doc.get("last_accessed_at")
            ))
        
        return documents
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list documents: {str(e)}")


@router.get("/{document_id}", response_model=DocumentVaultResponse)
async def get_document(
    document_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific document"""
    try:
        document_oid = safe_object_id(document_id)
        if not document_oid:
            raise HTTPException(status_code=400, detail="Invalid document ID")
        
        document_doc = await get_collection("document_vault").find_one({"_id": document_oid})
        if not document_doc:
            raise HTTPException(status_code=404, detail="Document not found")
        
        if str(document_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to view this document")
        
        await get_collection("document_vault").update_one(
            {"_id": document_oid},
            {"$set": {"last_accessed_at": datetime.utcnow()}}
        )
        
        member_name = None
        if document_doc.get("family_member_id"):
            member = await get_collection("family_members").find_one({"_id": document_doc["family_member_id"]})
            member_name = member.get("name") if member else None
        
        return DocumentVaultResponse(
            id=str(document_doc["_id"]),
            family_id=str(document_doc["family_id"]),
            document_type=document_doc["document_type"],
            title=document_doc["title"],
            description=document_doc.get("description"),
            file_url=document_doc["file_url"],
            file_name=document_doc["file_name"],
            file_size=document_doc["file_size"],
            mime_type=document_doc["mime_type"],
            family_member_id=str(document_doc["family_member_id"]) if document_doc.get("family_member_id") else None,
            family_member_name=member_name,
            expiration_date=document_doc.get("expiration_date"),
            document_number=document_doc.get("document_number"),
            issuing_authority=document_doc.get("issuing_authority"),
            tags=document_doc.get("tags", []),
            notes=document_doc.get("notes"),
            is_encrypted=document_doc["is_encrypted"],
            access_level=document_doc["access_level"],
            created_at=document_doc["created_at"],
            updated_at=document_doc["updated_at"],
            created_by=str(document_doc["created_by"]),
            last_accessed_at=datetime.utcnow()
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get document: {str(e)}")


@router.put("/{document_id}", response_model=DocumentVaultResponse)
async def update_document(
    document_id: str,
    document_update: DocumentVaultUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update document metadata"""
    try:
        document_oid = safe_object_id(document_id)
        if not document_oid:
            raise HTTPException(status_code=400, detail="Invalid document ID")
        
        document_doc = await get_collection("document_vault").find_one({"_id": document_oid})
        if not document_doc:
            raise HTTPException(status_code=404, detail="Document not found")
        
        if str(document_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this document")
        
        update_data = {k: v for k, v in document_update.dict(exclude_unset=True).items() if v is not None}
        
        if "family_member_id" in update_data and update_data["family_member_id"]:
            member_oid = safe_object_id(update_data["family_member_id"])
            if not member_oid:
                raise HTTPException(status_code=400, detail="Invalid family member ID")
            update_data["family_member_id"] = member_oid
        
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("document_vault").update_one(
            {"_id": document_oid},
            {"$set": update_data}
        )
        
        updated_document = await get_collection("document_vault").find_one({"_id": document_oid})
        
        member_name = None
        if updated_document.get("family_member_id"):
            member = await get_collection("family_members").find_one({"_id": updated_document["family_member_id"]})
            member_name = member.get("name") if member else None
        
        return DocumentVaultResponse(
            id=str(updated_document["_id"]),
            family_id=str(updated_document["family_id"]),
            document_type=updated_document["document_type"],
            title=updated_document["title"],
            description=updated_document.get("description"),
            file_url=updated_document["file_url"],
            file_name=updated_document["file_name"],
            file_size=updated_document["file_size"],
            mime_type=updated_document["mime_type"],
            family_member_id=str(updated_document["family_member_id"]) if updated_document.get("family_member_id") else None,
            family_member_name=member_name,
            expiration_date=updated_document.get("expiration_date"),
            document_number=updated_document.get("document_number"),
            issuing_authority=updated_document.get("issuing_authority"),
            tags=updated_document.get("tags", []),
            notes=updated_document.get("notes"),
            is_encrypted=updated_document["is_encrypted"],
            access_level=updated_document["access_level"],
            created_at=updated_document["created_at"],
            updated_at=updated_document["updated_at"],
            created_by=str(updated_document["created_by"]),
            last_accessed_at=updated_document.get("last_accessed_at")
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update document: {str(e)}")


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a document"""
    try:
        document_oid = safe_object_id(document_id)
        if not document_oid:
            raise HTTPException(status_code=400, detail="Invalid document ID")
        
        document_doc = await get_collection("document_vault").find_one({"_id": document_oid})
        if not document_doc:
            raise HTTPException(status_code=404, detail="Document not found")
        
        if str(document_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this document")
        
        await get_collection("document_vault").delete_one({"_id": document_oid})
        
        await get_collection("document_access_logs").delete_many({"document_id": document_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete document: {str(e)}")


@router.get("/{document_id}/access-log", response_model=List[DocumentAccessLogResponse])
async def get_document_access_log(
    document_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get access log for a document"""
    try:
        document_oid = safe_object_id(document_id)
        if not document_oid:
            raise HTTPException(status_code=400, detail="Invalid document ID")
        
        document_doc = await get_collection("document_vault").find_one({"_id": document_oid})
        if not document_doc:
            raise HTTPException(status_code=404, detail="Document not found")
        
        if str(document_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to view access log")
        
        logs_cursor = get_collection("document_access_logs").find({
            "document_id": document_oid
        }).sort("timestamp", -1)
        
        logs = []
        async for log_doc in logs_cursor:
            user = await get_collection("users").find_one({"_id": log_doc["user_id"]})
            user_name = user.get("full_name") if user else "Unknown User"
            
            logs.append(DocumentAccessLogResponse(
                id=str(log_doc["_id"]),
                document_id=str(log_doc["document_id"]),
                user_id=str(log_doc["user_id"]),
                user_name=user_name,
                action=log_doc["action"],
                timestamp=log_doc["timestamp"],
                ip_address=log_doc.get("ip_address")
            ))
        
        return logs
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get access log: {str(e)}")


@router.post("/{document_id}/log-access", status_code=status.HTTP_201_CREATED)
async def log_document_access(
    document_id: str,
    action: str,
    ip_address: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """Log document access"""
    try:
        document_oid = safe_object_id(document_id)
        if not document_oid:
            raise HTTPException(status_code=400, detail="Invalid document ID")
        
        document_doc = await get_collection("document_vault").find_one({"_id": document_oid})
        if not document_doc:
            raise HTTPException(status_code=404, detail="Document not found")
        
        if str(document_doc["family_id"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to log access")
        
        log_data = {
            "document_id": document_oid,
            "user_id": ObjectId(current_user.id),
            "action": action,
            "timestamp": datetime.utcnow(),
            "ip_address": ip_address
        }
        
        await get_collection("document_access_logs").insert_one(log_data)
        
        return {"message": "Access logged successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log access: {str(e)}")
