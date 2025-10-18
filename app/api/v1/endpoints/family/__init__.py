"""Family features endpoints module."""
from fastapi import APIRouter
from .family import router as family_router
from .family_albums import router as albums_router
from .family_calendar import router as calendar_router
from .family_milestones import router as milestones_router
from .family_recipes import router as recipes_router
from .family_timeline import router as timeline_router
from .family_traditions import router as traditions_router
from .genealogy import router as genealogy_router
from .health_records import router as health_router
from .legacy_letters import router as letters_router
from .parental_controls import router as parental_router

router = APIRouter()
router.include_router(family_router, tags=["family"])
router.include_router(albums_router, tags=["family-albums"])
router.include_router(calendar_router, tags=["family-calendar"])
router.include_router(milestones_router, tags=["family-milestones"])
router.include_router(recipes_router, tags=["family-recipes"])
router.include_router(timeline_router, tags=["family-timeline"])
router.include_router(traditions_router, tags=["family-traditions"])
router.include_router(genealogy_router, tags=["genealogy"])
router.include_router(health_router, tags=["health-records"])
router.include_router(letters_router, tags=["legacy-letters"])
router.include_router(parental_router, tags=["parental-controls"])

__all__ = ["router"]
