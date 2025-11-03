from fastapi import APIRouter
from .records import router as records_router
from .vaccinations import router as vaccinations_router
from .reminders import router as reminders_router

router = APIRouter()

router.include_router(records_router, prefix="/health-records", tags=["Health Records"])
router.include_router(vaccinations_router, prefix="/health-records/vaccinations", tags=["Vaccinations"])
router.include_router(reminders_router, prefix="/health-records/reminders", tags=["Health Reminders"])

__all__ = ["router"]
