"""Content management endpoints module."""
from fastapi import APIRouter
from .comments import router as comments_router
from .reactions import router as reactions_router
from .stories import router as stories_router
from .voice_notes import router as voice_notes_router

router = APIRouter()
router.include_router(comments_router, tags=["comments"])
router.include_router(reactions_router, tags=["reactions"])
router.include_router(stories_router, tags=["stories"])
router.include_router(voice_notes_router, tags=["voice-notes"])

__all__ = ["router"]
