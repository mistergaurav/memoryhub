"""Main API router with domain-organized endpoints."""
from fastapi import APIRouter
from app.api.v1.endpoints.auth import auth, password_reset, two_factor
from app.api.v1.endpoints.users import users, social as social_users, privacy, user_search
from app.api.v1.endpoints.memories import memories, memory_templates, tags, categories
from app.api.v1.endpoints.content import comments, reactions, stories, voice_notes
from app.api.v1.endpoints.collections import collections, vault, document_vault
from app.api.v1.endpoints import family as family_hub
from app.api.v1.endpoints.social import hub, activity, notifications
from app.api.v1.endpoints.features import search, analytics, sharing, reminders, scheduled_posts, places
from app.api.v1.endpoints.admin import admin, export, gdpr
from app.api.v1.endpoints.media import media

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(password_reset.router, prefix="/password-reset", tags=["password-reset"])
api_router.include_router(two_factor.router, prefix="/2fa", tags=["2fa"])

api_router.include_router(user_search.router, prefix="/users", tags=["users"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(social_users.router, prefix="/social", tags=["social"])
api_router.include_router(privacy.router, prefix="/privacy", tags=["privacy"])

api_router.include_router(memories.router, prefix="/memories", tags=["memories"])
api_router.include_router(memory_templates.router, prefix="/memory-templates", tags=["memory-templates"])
api_router.include_router(tags.router, prefix="/tags", tags=["tags"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])

api_router.include_router(comments.router, prefix="/comments", tags=["comments"])
api_router.include_router(reactions.router, prefix="/reactions", tags=["reactions"])
api_router.include_router(stories.router, prefix="/stories", tags=["stories"])
api_router.include_router(voice_notes.router, prefix="/voice-notes", tags=["voice-notes"])

api_router.include_router(collections.router, prefix="/collections", tags=["collections"])
api_router.include_router(vault.router, prefix="/vault", tags=["vault"])
api_router.include_router(document_vault.router, prefix="/document-vault", tags=["document-vault"])

api_router.include_router(family_hub.router, prefix="/family", tags=["family"])

api_router.include_router(hub.router, prefix="/hub", tags=["hub"])
# Include activity router with special handling for trailing slash compatibility
# FastAPI creates /activity/ with @router.get("/"), so we add a route for /activity (no slash)
from fastapi import APIRouter as Router
activity_no_slash_router = Router()
activity_no_slash_router.add_api_route(
    "",
    activity.get_activity,
    methods=["GET"],
    tags=["activity"],
    response_model=None
)
api_router.include_router(activity_no_slash_router, prefix="/activity", tags=["activity"])
api_router.include_router(activity.router, prefix="/activity", tags=["activity"])

# Include notifications router with special handling for trailing slash compatibility
notifications_no_slash_router = Router()
notifications_no_slash_router.add_api_route(
    "",
    notifications.list_notifications,
    methods=["GET"],
    tags=["notifications"]
)
api_router.include_router(notifications_no_slash_router, prefix="/notifications", tags=["notifications"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])

api_router.include_router(search.router, prefix="/search", tags=["search"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
api_router.include_router(sharing.router, prefix="/sharing", tags=["sharing"])
api_router.include_router(reminders.router, prefix="/reminders", tags=["reminders"])
api_router.include_router(scheduled_posts.router, prefix="/scheduled-posts", tags=["scheduled-posts"])
api_router.include_router(places.router, prefix="/places", tags=["places"])

api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(export.router, prefix="/export", tags=["export"])
api_router.include_router(gdpr.router, prefix="/gdpr", tags=["gdpr"])

api_router.include_router(media.router, prefix="/media", tags=["media"])
