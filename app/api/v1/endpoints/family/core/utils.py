"""Shared utility functions for family endpoints."""
from bson import ObjectId
from app.repositories.family_repository import UserRepository

user_repo = UserRepository()


async def get_user_data(user_id: ObjectId) -> dict:
    """Helper function to get user data by ID"""
    user = await user_repo.find_one({"_id": user_id}, raise_404=False)
    if user:
        return {
            "id": str(user["_id"]),
            "name": user.get("full_name"),
            "avatar": user.get("avatar_url"),
            "email": user.get("email")
        }
    return {"id": str(user_id), "name": None, "avatar": None, "email": None}
