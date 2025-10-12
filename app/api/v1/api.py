from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, users, memories, vault, hub, social, comments,
    notifications, collections, activity, search, tags,
    analytics, sharing, reminders, export, admin
)

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(memories.router, prefix="/memories", tags=["memories"])
api_router.include_router(vault.router, prefix="/vault", tags=["vault"])
api_router.include_router(hub.router, prefix="/hub", tags=["hub"])
api_router.include_router(social.router, prefix="/social", tags=["social"])
api_router.include_router(comments.router, prefix="/comments", tags=["comments"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(collections.router, prefix="/collections", tags=["collections"])
api_router.include_router(activity.router, prefix="/activity", tags=["activity"])
api_router.include_router(search.router, prefix="/search", tags=["search"])
api_router.include_router(tags.router, prefix="/tags", tags=["tags"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
api_router.include_router(sharing.router, prefix="/sharing", tags=["sharing"])
api_router.include_router(reminders.router, prefix="/reminders", tags=["reminders"])
api_router.include_router(export.router, prefix="/export", tags=["export"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])