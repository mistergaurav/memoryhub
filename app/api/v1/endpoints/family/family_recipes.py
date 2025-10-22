from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict, Any
from bson import ObjectId
from datetime import datetime

from app.models.family.family_recipes import (
    FamilyRecipeCreate, FamilyRecipeUpdate, FamilyRecipeResponse,
    RecipeRatingCreate
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection
from app.repositories.family_repository import FamilyRecipesRepository
from app.utils.validators import validate_object_ids
from app.utils.audit_logger import log_audit_event
from app.models.responses import create_success_response, create_paginated_response, create_message_response

router = APIRouter()
recipes_repo = FamilyRecipesRepository()


async def get_creator_name(created_by_id: ObjectId) -> Optional[str]:
    """Helper function to get creator name"""
    creator = await get_collection("users").find_one({"_id": created_by_id})
    return creator.get("full_name") if creator else None


def calculate_average_rating(ratings: List[Dict[str, Any]]) -> float:
    """Helper function to calculate average rating"""
    if not ratings:
        return 0.0
    total_rating = sum(r.get("rating", 0) for r in ratings)
    return round(total_rating / len(ratings), 1)


def build_recipe_response(recipe_doc: Dict[str, Any], creator_name: Optional[str] = None) -> FamilyRecipeResponse:
    """Helper function to build recipe response"""
    return FamilyRecipeResponse(
        id=str(recipe_doc["_id"]),
        title=recipe_doc["title"],
        description=recipe_doc.get("description"),
        category=recipe_doc["category"],
        difficulty=recipe_doc["difficulty"],
        prep_time_minutes=recipe_doc.get("prep_time_minutes"),
        cook_time_minutes=recipe_doc.get("cook_time_minutes"),
        servings=recipe_doc.get("servings"),
        ingredients=recipe_doc["ingredients"],
        steps=recipe_doc["steps"],
        photos=recipe_doc.get("photos", []),
        family_notes=recipe_doc.get("family_notes"),
        origin_story=recipe_doc.get("origin_story"),
        created_by=str(recipe_doc["created_by"]),
        created_by_name=creator_name,
        family_circle_ids=[str(cid) for cid in recipe_doc.get("family_circle_ids", [])],
        average_rating=calculate_average_rating(recipe_doc.get("ratings", [])),
        times_made=recipe_doc.get("times_made", 0),
        favorites_count=len(recipe_doc.get("favorites", [])),
        created_at=recipe_doc["created_at"],
        updated_at=recipe_doc["updated_at"]
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_recipe(
    recipe: FamilyRecipeCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Create a new family recipe.
    
    - Validates circle IDs
    - Creates recipe with ingredients and steps
    - Logs creation for audit trail
    """
    family_circle_oids = validate_object_ids(recipe.family_circle_ids, "family_circle_ids") if recipe.family_circle_ids else []
    
    recipe_data = {
        "title": recipe.title,
        "description": recipe.description,
        "category": recipe.category,
        "difficulty": recipe.difficulty,
        "prep_time_minutes": recipe.prep_time_minutes,
        "cook_time_minutes": recipe.cook_time_minutes,
        "servings": recipe.servings,
        "ingredients": [ing.model_dump() for ing in recipe.ingredients],
        "steps": [step.model_dump() for step in recipe.steps],
        "photos": recipe.photos,
        "family_notes": recipe.family_notes,
        "origin_story": recipe.origin_story,
        "created_by": ObjectId(current_user.id),
        "family_circle_ids": family_circle_oids,
        "ratings": [],
        "times_made": 0,
        "favorites": [],
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    recipe_doc = await recipes_repo.create(recipe_data)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="recipe_created",
        event_details={
            "recipe_id": str(recipe_doc["_id"]),
            "title": recipe.title,
            "category": recipe.category
        }
    )
    
    response = build_recipe_response(recipe_doc, current_user.full_name)
    
    return create_success_response(
        message="Recipe created successfully",
        data=response.model_dump()
    )


@router.get("/")
async def list_recipes(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Number of recipes per page"),
    category: Optional[str] = Query(None, description="Filter by category"),
    difficulty: Optional[str] = Query(None, description="Filter by difficulty"),
    current_user: UserInDB = Depends(get_current_user)
):
    """
    List all recipes with pagination and optional filtering.
    
    - Supports pagination with configurable page size
    - Filters by category and difficulty
    - Includes creator information and ratings
    """
    skip = (page - 1) * page_size
    
    recipes = await recipes_repo.find_user_recipes(
        user_id=str(current_user.id),
        category=category,
        difficulty=difficulty,
        skip=skip,
        limit=page_size
    )
    
    total = await recipes_repo.count_user_recipes(
        user_id=str(current_user.id),
        category=category,
        difficulty=difficulty
    )
    
    recipe_responses = []
    for recipe_doc in recipes:
        creator_name = await get_creator_name(recipe_doc["created_by"])
        recipe_responses.append(build_recipe_response(recipe_doc, creator_name))
    
    return create_paginated_response(
        items=[r.model_dump() for r in recipe_responses],
        total=total,
        page=page,
        page_size=page_size,
        message="Recipes retrieved successfully"
    )


@router.get("/{recipe_id}")
async def get_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Get a specific recipe by ID.
    
    - Returns complete recipe details including ingredients and steps
    - Includes ratings and favorites count
    """
    recipe_doc = await recipes_repo.find_by_id(
        recipe_id,
        raise_404=True,
        error_message="Recipe not found"
    )
    assert recipe_doc is not None
    
    creator_name = await get_creator_name(recipe_doc["created_by"])
    response = build_recipe_response(recipe_doc, creator_name)
    
    return create_success_response(
        message="Recipe retrieved successfully",
        data=response.model_dump()
    )


@router.put("/{recipe_id}")
async def update_recipe(
    recipe_id: str,
    recipe_update: FamilyRecipeUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Update a recipe (owner only).
    
    - Only recipe creator can update
    - Validates IDs if provided
    - Logs update for audit trail
    """
    await recipes_repo.check_recipe_ownership(recipe_id, str(current_user.id), raise_error=True)
    
    update_data = {k: v for k, v in recipe_update.model_dump(exclude_unset=True).items() if v is not None}
    
    if "ingredients" in update_data:
        update_data["ingredients"] = [ing.model_dump() for ing in recipe_update.ingredients]
    if "steps" in update_data:
        update_data["steps"] = [step.model_dump() for step in recipe_update.steps]
    if "family_circle_ids" in update_data:
        update_data["family_circle_ids"] = validate_object_ids(update_data["family_circle_ids"], "family_circle_ids")
    
    update_data["updated_at"] = datetime.utcnow()
    
    updated_recipe = await recipes_repo.update_by_id(recipe_id, update_data)
    assert updated_recipe is not None
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="recipe_updated",
        event_details={
            "recipe_id": recipe_id,
            "updated_fields": list(update_data.keys())
        }
    )
    
    creator_name = await get_creator_name(updated_recipe["created_by"])
    response = build_recipe_response(updated_recipe, creator_name)
    
    return create_success_response(
        message="Recipe updated successfully",
        data=response.model_dump()
    )


@router.delete("/{recipe_id}", status_code=status.HTTP_200_OK)
async def delete_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Delete a recipe (owner only).
    
    - Only recipe creator can delete
    - Logs deletion for audit trail (GDPR compliance)
    """
    recipe_doc = await recipes_repo.find_by_id(recipe_id, raise_404=True)
    assert recipe_doc is not None
    
    await recipes_repo.check_recipe_ownership(recipe_id, str(current_user.id), raise_error=True)
    
    await recipes_repo.delete_by_id(recipe_id)
    
    await log_audit_event(
        user_id=str(current_user.id),
        event_type="recipe_deleted",
        event_details={
            "recipe_id": recipe_id,
            "title": recipe_doc.get("title")
        }
    )
    
    return create_message_response("Recipe deleted successfully")


@router.post("/{recipe_id}/rate", status_code=status.HTTP_200_OK)
async def rate_recipe(
    recipe_id: str,
    rating_data: RecipeRatingCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Rate a recipe (1-5 stars with optional comment).
    
    - Updates existing rating if user already rated
    - Validates rating value
    """
    await recipes_repo.find_by_id(recipe_id, raise_404=True, error_message="Recipe not found")
    
    await recipes_repo.add_rating(
        recipe_id=recipe_id,
        user_id=str(current_user.id),
        rating=rating_data.rating,
        comment=rating_data.comment
    )
    
    return create_message_response("Recipe rated successfully")


@router.post("/{recipe_id}/favorite", status_code=status.HTTP_200_OK)
async def favorite_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add recipe to favorites"""
    await recipes_repo.find_by_id(recipe_id, raise_404=True, error_message="Recipe not found")
    
    await recipes_repo.toggle_favorite(
        recipe_id=recipe_id,
        user_id=str(current_user.id),
        add_favorite=True
    )
    
    return create_message_response("Recipe added to favorites")


@router.delete("/{recipe_id}/favorite", status_code=status.HTTP_200_OK)
async def unfavorite_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove recipe from favorites"""
    await recipes_repo.find_by_id(recipe_id, raise_404=True, error_message="Recipe not found")
    
    await recipes_repo.toggle_favorite(
        recipe_id=recipe_id,
        user_id=str(current_user.id),
        add_favorite=False
    )
    
    return create_message_response("Recipe removed from favorites")


@router.post("/{recipe_id}/made", status_code=status.HTTP_200_OK)
async def mark_recipe_made(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """
    Mark that a recipe was made.
    
    - Increments the times_made counter
    - Tracks recipe popularity
    """
    await recipes_repo.find_by_id(recipe_id, raise_404=True, error_message="Recipe not found")
    
    await recipes_repo.increment_times_made(recipe_id)
    
    return create_message_response("Recipe marked as made")
