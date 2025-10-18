from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.models.family_recipes import (
    FamilyRecipeCreate, FamilyRecipeUpdate, FamilyRecipeResponse,
    RecipeRatingCreate
)
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_collection

router = APIRouter()
def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None

def safe_object_id(id_str):
    try:
        return ObjectId(id_str)
    except:
        return None



@router.post("/", response_model=FamilyRecipeResponse, status_code=status.HTTP_201_CREATED)
async def create_recipe(
    recipe: FamilyRecipeCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new family recipe"""
    try:
        family_circle_oids = [safe_object_id(cid) for cid in recipe.family_circle_ids if safe_object_id(cid)]
        
        recipe_data = {
            "title": recipe.title,
            "description": recipe.description,
            "category": recipe.category,
            "difficulty": recipe.difficulty,
            "prep_time_minutes": recipe.prep_time_minutes,
            "cook_time_minutes": recipe.cook_time_minutes,
            "servings": recipe.servings,
            "ingredients": [ing.dict() for ing in recipe.ingredients],
            "steps": [step.dict() for step in recipe.steps],
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
        
        result = await get_collection("family_recipes").insert_one(recipe_data)
        recipe_doc = await get_collection("family_recipes").find_one({"_id": result.inserted_id})
        
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
            created_by_name=current_user.full_name,
            family_circle_ids=[str(cid) for cid in recipe_doc.get("family_circle_ids", [])],
            average_rating=0.0,
            times_made=recipe_doc.get("times_made", 0),
            favorites_count=len(recipe_doc.get("favorites", [])),
            created_at=recipe_doc["created_at"],
            updated_at=recipe_doc["updated_at"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create recipe: {str(e)}")


@router.get("/", response_model=List[FamilyRecipeResponse])
async def list_recipes(
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """List family recipes"""
    try:
        user_oid = ObjectId(current_user.id)
        
        query = {}
        
        if category:
            query["category"] = category
        if difficulty:
            query["difficulty"] = difficulty
        
        recipes_cursor = get_collection("family_recipes").find(query).sort("created_at", -1)
        
        recipes = []
        async for recipe_doc in recipes_cursor:
            creator = await get_collection("users").find_one({"_id": recipe_doc["created_by"]})
            
            avg_rating = 0.0
            if recipe_doc.get("ratings"):
                total_rating = sum(r.get("rating", 0) for r in recipe_doc["ratings"])
                avg_rating = total_rating / len(recipe_doc["ratings"])
            
            recipes.append(FamilyRecipeResponse(
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
                created_by_name=creator.get("full_name") if creator else None,
                family_circle_ids=[str(cid) for cid in recipe_doc.get("family_circle_ids", [])],
                average_rating=avg_rating,
                times_made=recipe_doc.get("times_made", 0),
                favorites_count=len(recipe_doc.get("favorites", [])),
                created_at=recipe_doc["created_at"],
                updated_at=recipe_doc["updated_at"]
            ))
        
        return recipes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list recipes: {str(e)}")


@router.get("/{recipe_id}", response_model=FamilyRecipeResponse)
async def get_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific recipe"""
    try:
        recipe_oid = safe_object_id(recipe_id)
        if not recipe_oid:
            raise HTTPException(status_code=400, detail="Invalid recipe ID")
        
        recipe_doc = await get_collection("family_recipes").find_one({"_id": recipe_oid})
        if not recipe_doc:
            raise HTTPException(status_code=404, detail="Recipe not found")
        
        creator = await get_collection("users").find_one({"_id": recipe_doc["created_by"]})
        
        avg_rating = 0.0
        if recipe_doc.get("ratings"):
            total_rating = sum(r.get("rating", 0) for r in recipe_doc["ratings"])
            avg_rating = total_rating / len(recipe_doc["ratings"])
        
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
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in recipe_doc.get("family_circle_ids", [])],
            average_rating=avg_rating,
            times_made=recipe_doc.get("times_made", 0),
            favorites_count=len(recipe_doc.get("favorites", [])),
            created_at=recipe_doc["created_at"],
            updated_at=recipe_doc["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get recipe: {str(e)}")


@router.put("/{recipe_id}", response_model=FamilyRecipeResponse)
async def update_recipe(
    recipe_id: str,
    recipe_update: FamilyRecipeUpdate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update a recipe"""
    try:
        recipe_oid = safe_object_id(recipe_id)
        if not recipe_oid:
            raise HTTPException(status_code=400, detail="Invalid recipe ID")
        
        recipe_doc = await get_collection("family_recipes").find_one({"_id": recipe_oid})
        if not recipe_doc:
            raise HTTPException(status_code=404, detail="Recipe not found")
        
        if str(recipe_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this recipe")
        
        update_data = {}
        for key, value in recipe_update.dict(exclude_unset=True).items():
            if value is not None:
                if key == "ingredients":
                    update_data[key] = [ing.dict() for ing in value]
                elif key == "steps":
                    update_data[key] = [step.dict() for step in value]
                elif key == "family_circle_ids":
                    update_data[key] = [safe_object_id(cid) for cid in value if safe_object_id(cid)]
                else:
                    update_data[key] = value
        
        update_data["updated_at"] = datetime.utcnow()
        
        await get_collection("family_recipes").update_one(
            {"_id": recipe_oid},
            {"$set": update_data}
        )
        
        updated_recipe = await get_collection("family_recipes").find_one({"_id": recipe_oid})
        creator = await get_collection("users").find_one({"_id": updated_recipe["created_by"]})
        
        avg_rating = 0.0
        if updated_recipe.get("ratings"):
            total_rating = sum(r.get("rating", 0) for r in updated_recipe["ratings"])
            avg_rating = total_rating / len(updated_recipe["ratings"])
        
        return FamilyRecipeResponse(
            id=str(updated_recipe["_id"]),
            title=updated_recipe["title"],
            description=updated_recipe.get("description"),
            category=updated_recipe["category"],
            difficulty=updated_recipe["difficulty"],
            prep_time_minutes=updated_recipe.get("prep_time_minutes"),
            cook_time_minutes=updated_recipe.get("cook_time_minutes"),
            servings=updated_recipe.get("servings"),
            ingredients=updated_recipe["ingredients"],
            steps=updated_recipe["steps"],
            photos=updated_recipe.get("photos", []),
            family_notes=updated_recipe.get("family_notes"),
            origin_story=updated_recipe.get("origin_story"),
            created_by=str(updated_recipe["created_by"]),
            created_by_name=creator.get("full_name") if creator else None,
            family_circle_ids=[str(cid) for cid in updated_recipe.get("family_circle_ids", [])],
            average_rating=avg_rating,
            times_made=updated_recipe.get("times_made", 0),
            favorites_count=len(updated_recipe.get("favorites", [])),
            created_at=updated_recipe["created_at"],
            updated_at=updated_recipe["updated_at"]
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update recipe: {str(e)}")


@router.delete("/{recipe_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a recipe"""
    try:
        recipe_oid = safe_object_id(recipe_id)
        if not recipe_oid:
            raise HTTPException(status_code=400, detail="Invalid recipe ID")
        
        recipe_doc = await get_collection("family_recipes").find_one({"_id": recipe_oid})
        if not recipe_doc:
            raise HTTPException(status_code=404, detail="Recipe not found")
        
        if str(recipe_doc["created_by"]) != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this recipe")
        
        await get_collection("family_recipes").delete_one({"_id": recipe_oid})
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete recipe: {str(e)}")


@router.post("/{recipe_id}/rate", status_code=status.HTTP_200_OK)
async def rate_recipe(
    recipe_id: str,
    rating_data: RecipeRatingCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Rate a recipe"""
    try:
        recipe_oid = safe_object_id(recipe_id)
        if not recipe_oid:
            raise HTTPException(status_code=400, detail="Invalid recipe ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_recipes").update_one(
            {"_id": recipe_oid},
            {
                "$pull": {"ratings": {"user_id": user_oid}},
            }
        )
        
        await get_collection("family_recipes").update_one(
            {"_id": recipe_oid},
            {
                "$push": {
                    "ratings": {
                        "user_id": user_oid,
                        "rating": rating_data.rating,
                        "comment": rating_data.comment,
                        "created_at": datetime.utcnow()
                    }
                }
            }
        )
        
        return {"message": "Recipe rated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to rate recipe: {str(e)}")


@router.post("/{recipe_id}/favorite", status_code=status.HTTP_200_OK)
async def favorite_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add recipe to favorites"""
    try:
        recipe_oid = safe_object_id(recipe_id)
        if not recipe_oid:
            raise HTTPException(status_code=400, detail="Invalid recipe ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_recipes").update_one(
            {"_id": recipe_oid},
            {"$addToSet": {"favorites": user_oid}}
        )
        
        return {"message": "Recipe added to favorites"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to favorite recipe: {str(e)}")


@router.delete("/{recipe_id}/favorite", status_code=status.HTTP_200_OK)
async def unfavorite_recipe(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove recipe from favorites"""
    try:
        recipe_oid = safe_object_id(recipe_id)
        if not recipe_oid:
            raise HTTPException(status_code=400, detail="Invalid recipe ID")
        
        user_oid = ObjectId(current_user.id)
        
        await get_collection("family_recipes").update_one(
            {"_id": recipe_oid},
            {"$pull": {"favorites": user_oid}}
        )
        
        return {"message": "Recipe removed from favorites"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unfavorite recipe: {str(e)}")


@router.post("/{recipe_id}/made", status_code=status.HTTP_200_OK)
async def mark_recipe_made(
    recipe_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Mark that recipe was made"""
    try:
        recipe_oid = safe_object_id(recipe_id)
        if not recipe_oid:
            raise HTTPException(status_code=400, detail="Invalid recipe ID")
        
        await get_collection("family_recipes").update_one(
            {"_id": recipe_oid},
            {"$inc": {"times_made": 1}}
        )
        
        return {"message": "Recipe marked as made"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to mark recipe as made: {str(e)}")
