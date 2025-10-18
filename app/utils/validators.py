"""
Centralized validation utilities for the Memory Hub application.
Provides common validation functions used across all endpoints.
"""
from typing import Optional, List
from bson import ObjectId
from fastapi import HTTPException

def safe_object_id(id_str: str) -> Optional[ObjectId]:
    """
    Safely convert string to MongoDB ObjectId.
    
    Args:
        id_str: String representation of ObjectId
        
    Returns:
        ObjectId if valid, None otherwise
    """
    try:
        return ObjectId(id_str)
    except Exception:
        return None


def validate_object_id(id_str: str, field_name: str = "ID") -> ObjectId:
    """
    Validate and convert string to ObjectId, raise HTTPException if invalid.
    
    Args:
        id_str: String representation of ObjectId
        field_name: Name of the field for error message
        
    Returns:
        Valid ObjectId
        
    Raises:
        HTTPException: If ID is invalid
    """
    obj_id = safe_object_id(id_str)
    if not obj_id:
        raise HTTPException(status_code=400, detail=f"Invalid {field_name}")
    return obj_id


def validate_object_ids(id_list: List[str], field_name: str = "IDs") -> List[ObjectId]:
    """
    Validate and convert list of strings to ObjectIds.
    Raises HTTPException if any ID in the list is invalid.
    
    Args:
        id_list: List of string representations of ObjectIds
        field_name: Name of the field for error message
        
    Returns:
        List of valid ObjectIds
        
    Raises:
        HTTPException: If any ID in the list is invalid
    """
    valid_ids = []
    invalid_ids = []
    
    for idx, id_str in enumerate(id_list):
        obj_id = safe_object_id(id_str)
        if obj_id:
            valid_ids.append(obj_id)
        else:
            invalid_ids.append(f"{field_name}[{idx}]='{id_str}'")
    
    if invalid_ids:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid {field_name}: {', '.join(invalid_ids)}"
        )
    
    return valid_ids


async def validate_document_exists(collection_name: str, doc_id: ObjectId, error_message: str = "Document not found"):
    """
    Check if a document exists in a collection.
    
    Args:
        collection_name: Name of the MongoDB collection
        doc_id: ObjectId of the document
        error_message: Custom error message
        
    Raises:
        HTTPException: If document doesn't exist
    """
    from app.db.mongodb import get_collection
    doc = await get_collection(collection_name).find_one({"_id": doc_id})
    if not doc:
        raise HTTPException(status_code=404, detail=error_message)
    return doc


async def validate_user_owns_resource(resource_doc: dict, user_id: str, owner_field: str = "owner_id"):
    """
    Validate that a user owns a resource.
    
    Args:
        resource_doc: The resource document from database
        user_id: String representation of user's ObjectId
        owner_field: Name of the owner field in the document
        
    Raises:
        HTTPException: If user doesn't own the resource
    """
    owner_id = resource_doc.get(owner_field)
    if not owner_id or str(owner_id) != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to access this resource")


async def validate_user_has_access(resource_doc: dict, user_id: str, access_fields: List[str]):
    """
    Validate that a user has access to a resource through multiple possible fields.
    
    Args:
        resource_doc: The resource document from database
        user_id: String representation of user's ObjectId
        access_fields: List of fields that grant access (e.g., ["owner_id", "member_ids"])
        
    Raises:
        HTTPException: If user doesn't have access
    """
    user_obj_id = ObjectId(user_id)
    
    for field in access_fields:
        value = resource_doc.get(field)
        if value:
            if isinstance(value, ObjectId) and value == user_obj_id:
                return True
            elif isinstance(value, list) and user_obj_id in value:
                return True
            elif str(value) == user_id:
                return True
    
    raise HTTPException(status_code=403, detail="Not authorized to access this resource")


def validate_privacy_level(privacy: str) -> str:
    """
    Validate privacy level.
    
    Args:
        privacy: Privacy level string
        
    Returns:
        Validated privacy level
        
    Raises:
        HTTPException: If privacy level is invalid
    """
    valid_levels = ["public", "private", "friends", "family"]
    if privacy not in valid_levels:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid privacy level. Must be one of: {', '.join(valid_levels)}"
        )
    return privacy
