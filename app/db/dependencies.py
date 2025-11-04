"""
Database dependencies module.

This module provides database accessor functions without importing from app.core,
breaking the circular import between app.db.mongodb and app.core.security.
"""
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase, AsyncIOMotorCollection


def get_database() -> AsyncIOMotorDatabase:
    """
    Get the database instance.
    
    This imports from mongodb at runtime to avoid circular imports.
    """
    from app.db.mongodb import db
    from app.core.config import settings
    
    if not db.client:
        raise RuntimeError("Database not connected")
    return db.client[settings.DB_NAME]


def get_collection(collection_name: str) -> AsyncIOMotorCollection:
    """
    Get a collection from the database.
    
    Args:
        collection_name: Name of the collection to retrieve
        
    Returns:
        The requested MongoDB collection
    """
    return get_database()[collection_name]
