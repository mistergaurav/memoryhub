"""Memory management endpoints module."""
from fastapi import APIRouter
from .memories import router as memories_router
from .memory_templates import router as templates_router
from .tags import router as tags_router
from .categories import router as categories_router

router = APIRouter()
router.include_router(memories_router, tags=["memories"])
router.include_router(templates_router, tags=["templates"])
router.include_router(tags_router, tags=["tags"])
router.include_router(categories_router, tags=["categories"])

__all__ = ["router"]
