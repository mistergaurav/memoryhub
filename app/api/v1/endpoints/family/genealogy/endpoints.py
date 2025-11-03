"""
Genealogy endpoints facade.

This module maintains backward compatibility by combining all genealogy routers
into a single router. The actual endpoint implementations have been split into
focused modules for better maintainability.
"""
from fastapi import APIRouter

# Import all genealogy routers
from .persons import router as persons_router
from .search import router as search_router
from .relationships_genealogy import router as relationships_router
from .tree import router as tree_router
from .invitations_genealogy import router as invitations_router

# Create a combined router
router = APIRouter()

# Include all genealogy routers
router.include_router(persons_router)
router.include_router(search_router)
router.include_router(relationships_router)
router.include_router(tree_router)
router.include_router(invitations_router)

__all__ = ["router"]
