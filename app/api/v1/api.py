from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, users, memories, vault, hub, social, comments,
    notifications, collections, activity, search, tags,
    analytics, sharing, reminders, export, admin, stories,
    voice_notes, categories, reactions, memory_templates,
    two_factor, password_reset
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
api_router.include_router(stories.router, prefix="/stories", tags=["stories"])
api_router.include_router(voice_notes.router, prefix="/voice-notes", tags=["voice-notes"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])
api_router.include_router(reactions.router, prefix="/reactions", tags=["reactions"])
api_router.include_router(memory_templates.router, prefix="/memory-templates", tags=["memory-templates"])
api_router.include_router(two_factor.router, prefix="/2fa", tags=["2fa"])
api_router.include_router(password_reset.router, prefix="/password-reset", tags=["password-reset"])