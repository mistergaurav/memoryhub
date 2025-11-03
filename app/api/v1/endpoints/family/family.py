"""
Family endpoints facade.

This module maintains backward compatibility by combining all core family routers
into a single router. The actual endpoint implementations have been split into
focused modules in the core/ directory for better maintainability.
"""
from fastapi import APIRouter

# Import all core routers
from .core import (
    relationships_router,
    circles_router,
    invitations_router,
    members_router,
    dashboard_router
)

# Create a combined router
router = APIRouter()

# Include all core routers
router.include_router(relationships_router)
router.include_router(circles_router)
router.include_router(invitations_router)
router.include_router(members_router)
router.include_router(dashboard_router)

__all__ = ["router"]
