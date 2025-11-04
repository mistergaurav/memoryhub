"""Family features endpoints module."""
from fastapi import APIRouter

# Import from migrated feature modules (new structure)
from .albums import router as albums_router
from .calendar import router as calendar_router
from .milestones import router as milestones_router
from .recipes import router as recipes_router
from .timeline import router as timeline_router
from .traditions import router as traditions_router
from .genealogy import router as genealogy_router
from .letters import router as letters_router
from .parental_controls import router as parental_router

# Import from core modules (refactored family.py)
from .core import (
    relationships_router,
    circles_router,
    invitations_router,
    members_router,
    dashboard_router
)

router = APIRouter()
# Include core family routers (replacing old family_router)
router.include_router(relationships_router, tags=["family"])
router.include_router(circles_router, tags=["family"])
router.include_router(invitations_router, tags=["family"])
router.include_router(members_router, tags=["family"])
router.include_router(dashboard_router, tags=["family"])
router.include_router(albums_router, prefix="/albums", tags=["family-albums"])
router.include_router(calendar_router, prefix="/calendar", tags=["family-calendar"])
router.include_router(milestones_router, prefix="/milestones", tags=["family-milestones"])
router.include_router(recipes_router, prefix="/recipes", tags=["family-recipes"])
router.include_router(timeline_router, prefix="/timeline", tags=["family-timeline"])
router.include_router(traditions_router, prefix="/traditions", tags=["family-traditions"])
router.include_router(genealogy_router, prefix="/genealogy", tags=["genealogy"])
router.include_router(letters_router, prefix="/letters", tags=["legacy-letters"])
router.include_router(parental_router, prefix="/parental-controls", tags=["parental-controls"])

__all__ = ["router"]
