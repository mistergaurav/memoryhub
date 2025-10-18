"""Collections and vault endpoints module."""
from fastapi import APIRouter
from .collections import router as collections_router
from .vault import router as vault_router
from .document_vault import router as document_vault_router

router = APIRouter()
router.include_router(collections_router, tags=["collections"])
router.include_router(vault_router, tags=["vault"])
router.include_router(document_vault_router, tags=["document-vault"])

__all__ = ["router"]
