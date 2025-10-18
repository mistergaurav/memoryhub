from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, users, memories, vault, hub, social, comments,
    notifications, collections, activity, search, tags,
    analytics, sharing, reminders, export, admin, stories,
    voice_notes, categories, reactions, memory_templates,
    two_factor, password_reset, privacy, places, scheduled_posts, gdpr, family,
    family_albums, family_calendar, family_milestones, family_recipes,
    legacy_letters, family_traditions, parental_controls, family_timeline,
    genealogy, health_records, document_vault
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
api_router.include_router(privacy.router, prefix="/privacy", tags=["privacy"])
api_router.include_router(places.router, prefix="/places", tags=["places"])
api_router.include_router(scheduled_posts.router, prefix="/scheduled-posts", tags=["scheduled-posts"])
api_router.include_router(gdpr.router, prefix="/gdpr", tags=["gdpr"])
api_router.include_router(family.router, prefix="/family", tags=["family"])
api_router.include_router(family_albums.router, prefix="/family-albums", tags=["family-albums"])
api_router.include_router(family_calendar.router, prefix="/family-calendar", tags=["family-calendar"])
api_router.include_router(family_milestones.router, prefix="/family-milestones", tags=["family-milestones"])
api_router.include_router(family_recipes.router, prefix="/family-recipes", tags=["family-recipes"])
api_router.include_router(legacy_letters.router, prefix="/legacy-letters", tags=["legacy-letters"])
api_router.include_router(family_traditions.router, prefix="/family-traditions", tags=["family-traditions"])
api_router.include_router(parental_controls.router, prefix="/parental-controls", tags=["parental-controls"])
api_router.include_router(family_timeline.router, prefix="/family-timeline", tags=["family-timeline"])
api_router.include_router(genealogy.router, prefix="/genealogy", tags=["genealogy"])
api_router.include_router(health_records.router, prefix="/health-records", tags=["health-records"])
api_router.include_router(document_vault.router, prefix="/document-vault", tags=["document-vault"])
