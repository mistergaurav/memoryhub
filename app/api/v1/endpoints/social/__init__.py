"""Social features endpoints module."""
from fastapi import APIRouter
from .hub import router as hub_router
from .activity import router as activity_router
from .notifications import router as notifications_router

router = APIRouter()
router.include_router(hub_router, tags=["hub"])
router.include_router(activity_router, tags=["activity"])
router.include_router(notifications_router, tags=["notifications"])

__all__ = ["router"]
