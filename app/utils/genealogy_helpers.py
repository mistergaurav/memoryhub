"""Centralized utilities for genealogy feature."""
from typing import Optional
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException


def safe_object_id(id_str: str) -> Optional[ObjectId]:
    """Safely convert string to ObjectId, returning None on failure."""
    if not id_str:
        return None
    try:
        return ObjectId(id_str)
    except Exception:
        return None


def validate_object_id(id_str: str, field_name: str = "ID") -> ObjectId:
    """Validate and convert string to ObjectId, raising HTTPException on failure."""
    oid = safe_object_id(id_str)
    if not oid:
        raise HTTPException(status_code=400, detail=f"Invalid {field_name}")
    return oid


def compute_is_alive(death_date: Optional[str], is_alive_override: Optional[bool]) -> bool:
    """
    Compute is_alive status for a person.
    
    Args:
        death_date: Death date string in YYYY-MM-DD format
        is_alive_override: Explicit override value
    
    Returns:
        True if person is alive, False otherwise
    """
    if is_alive_override is not None:
        return is_alive_override
    return death_date is None or death_date == ""


def format_person_name(first_name: str, last_name: str, maiden_name: Optional[str] = None) -> str:
    """Format full person name including maiden name if present."""
    if maiden_name:
        return f"{first_name} ({maiden_name}) {last_name}"
    return f"{first_name} {last_name}"
