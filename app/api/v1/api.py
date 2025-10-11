from fastapi import APIRouter
from app.api.v1.endpoints import auth, users, memories, vault, hub, social

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(memories.router, prefix="/memories", tags=["memories"])
api_router.include_router(vault.router, prefix="/vault", tags=["vault"])
api_router.include_router(hub.router, prefix="/hub", tags=["hub"])
api_router.include_router(social.router, prefix="/social", tags=["social"])