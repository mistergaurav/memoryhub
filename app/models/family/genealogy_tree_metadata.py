"""Genealogy tree metadata model."""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class TreePrivacyLevel(str, Enum):
    """Privacy level for family trees"""
    PUBLIC = "public"  # Visible to anyone
    PRIVATE = "private"  # Only visible to members
    FAMILY_ONLY = "family_only"  # Only visible to linked family members


class GenealogyTreeCreate(BaseModel):
    """Request model for creating a new genealogy tree"""
    name: str = Field(..., min_length=1, max_length=200, description="Tree name")
    description: Optional[str] = Field(None, max_length=1000, description="Tree description")
    privacy_level: TreePrivacyLevel = TreePrivacyLevel.PRIVATE
    settings: Optional[dict] = Field(default_factory=dict, description="Display and customization settings")


class GenealogyTreeUpdate(BaseModel):
    """Request model for updating tree metadata"""
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    privacy_level: Optional[TreePrivacyLevel] = None
    settings: Optional[dict] = None


class GenealogyTreeResponse(BaseModel):
    """Response model for genealogy tree metadata"""
    id: str
    owner_id: str
    name: str
    description: Optional[str] = None
    privacy_level: TreePrivacyLevel
    person_count: int = 0
    relationship_count: int = 0
    member_count: int = 0
    settings: dict = {}
    created_at: datetime
    updated_at: datetime
    last_modified_by: Optional[str] = None


class TreeStats(BaseModel):
    """Statistics for a genealogy tree"""
    total_persons: int
    living_persons: int
    deceased_persons: int
    total_relationships: int
    generations: int
    oldest_birth_year: Optional[int] = None
    newest_birth_year: Optional[int] = None
