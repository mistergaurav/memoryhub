"""Feature endpoints module (search, analytics, sharing, etc.)."""
from fastapi import APIRouter
from .search import router as search_router
from .analytics import router as analytics_router
from .sharing import router as sharing_router
from .reminders import router as reminders_router
from .scheduled_posts import router as scheduled_posts_router
from .places import router as places_router

router = APIRouter()
router.include_router(search_router, tags=["search"])
router.include_router(analytics_router, tags=["analytics"])
router.include_router(sharing_router, tags=["sharing"])
router.include_router(reminders_router, tags=["reminders"])
router.include_router(scheduled_posts_router, tags=["scheduled-posts"])
router.include_router(places_router, tags=["places"])

__all__ = ["router"]
