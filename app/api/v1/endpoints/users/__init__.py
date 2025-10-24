"""User management endpoints module."""
from fastapi import APIRouter
from .users import router as users_router
from .social import router as social_router
from .privacy import router as privacy_router
from .user_search import router as user_search_router

router = APIRouter()
router.include_router(users_router, tags=["users"])
router.include_router(social_router, tags=["social"])
router.include_router(privacy_router, tags=["privacy"])
router.include_router(user_search_router, tags=["users"])

__all__ = ["router"]
