"""Family Timeline feature."""
from fastapi import APIRouter
from .endpoints import router as legacy_router
from . import milestones, comments, reactions

router = APIRouter()

# Include legacy timeline endpoint (for backward compatibility)
router.include_router(legacy_router, tags=["family-timeline"])

# Include new timeline endpoints
router.include_router(milestones.router, tags=["timeline-milestones"])
router.include_router(comments.router, tags=["timeline-comments"])
router.include_router(reactions.router, tags=["timeline-reactions"])

__all__ = ["router"]
