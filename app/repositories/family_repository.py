"""
Backward-compatible facade for family repositories.

This module maintains compatibility with existing imports while the actual
repository implementations have been moved to the app.repositories.family package.

All repository classes are now organized into separate, focused modules for better
maintainability. This file simply re-exports them to avoid breaking existing imports.

Example:
    # Old import (still works):
    from app.repositories.family_repository import UserRepository
    
    # New import (preferred):
    from app.repositories.family import UserRepository

Note: This facade will be maintained for backward compatibility but new code
should import directly from app.repositories.family.
"""

# Re-export all repository classes from the family package
from .family import (
    UserRepository,
    GenealogTreeMembershipRepository,
    FamilyMembersRepository,
    FamilyRepository,
    FamilyRelationshipRepository,
    FamilyInvitationRepository,
    GenealogyPersonRepository,
    GenealogyRelationshipRepository,
    FamilyTimelineRepository,
    GenealogyTreeRepository,
    FamilyAlbumsRepository,
    FamilyCalendarRepository,
    FamilyMilestonesRepository,
    FamilyRecipesRepository,
    FamilyTraditionsRepository,
    LegacyLettersRepository,
    HubItemsRepository,
    NotificationRepository,
    GenealogyInviteLinksRepository,
    MemoryRepository,
)

__all__ = [
    "UserRepository",
    "GenealogTreeMembershipRepository",
    "FamilyMembersRepository",
    "FamilyRepository",
    "FamilyRelationshipRepository",
    "FamilyInvitationRepository",
    "GenealogyPersonRepository",
    "GenealogyRelationshipRepository",
    "FamilyTimelineRepository",
    "GenealogyTreeRepository",
    "FamilyAlbumsRepository",
    "FamilyCalendarRepository",
    "FamilyMilestonesRepository",
    "FamilyRecipesRepository",
    "FamilyTraditionsRepository",
    "LegacyLettersRepository",
    "HubItemsRepository",
    "NotificationRepository",
    "GenealogyInviteLinksRepository",
    "MemoryRepository",
]
