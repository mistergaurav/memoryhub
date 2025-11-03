"""Genealogy endpoints package - refactored into focused modules."""
from .persons import router as persons_router
from .search import router as search_router
from .relationships_genealogy import router as relationships_router
from .tree import router as tree_router
from .invitations_genealogy import router as invitations_router

# Import the main router from endpoints.py (facade)
from .endpoints import router

__all__ = [
    "router",
    "persons_router",
    "search_router",
    "relationships_router",
    "tree_router",
    "invitations_router",
]
