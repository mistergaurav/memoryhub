"""Admin and system endpoints module."""
from fastapi import APIRouter
from .admin import router as admin_router
from .export import router as export_router
from .gdpr import router as gdpr_router

router = APIRouter()
router.include_router(admin_router, tags=["admin"])
router.include_router(export_router, tags=["export"])
router.include_router(gdpr_router, tags=["gdpr"])

__all__ = ["router"]
