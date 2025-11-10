from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId


class RecipeCategory(str, Enum):
    APPETIZER = "appetizer"
    MAIN_COURSE = "main_course"
    DESSERT = "dessert"
    BEVERAGE = "beverage"
    SNACK = "snack"
    BREAKFAST = "breakfast"
    SALAD = "salad"
    SOUP = "soup"
    SAUCE = "sauce"
    BAKING = "baking"
    OTHER = "other"


class RecipeDifficulty(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class RecipeIngredient(BaseModel):
    name: str
    amount: str
    unit: Optional[str] = None


class RecipeStep(BaseModel):
    step_number: int
    instruction: str
    photo: Optional[str] = None


class FamilyRecipeBase(BaseModel):
    title: str
    description: Optional[str] = None
    category: RecipeCategory
    difficulty: RecipeDifficulty = RecipeDifficulty.MEDIUM
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    servings: Optional[int] = None


class FamilyRecipeCreate(FamilyRecipeBase):
    ingredients: List[RecipeIngredient]
    steps: List[RecipeStep]
    photos: List[str] = Field(default_factory=list)
    family_notes: Optional[str] = None
    origin_story: Optional[str] = None  # Who created it, history
    family_circle_ids: List[str] = Field(default_factory=list)


class FamilyRecipeUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[RecipeCategory] = None
    difficulty: Optional[RecipeDifficulty] = None
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    servings: Optional[int] = None
    ingredients: Optional[List[RecipeIngredient]] = None
    steps: Optional[List[RecipeStep]] = None
    photos: Optional[List[str]] = None
    family_notes: Optional[str] = None
    origin_story: Optional[str] = None
    family_circle_ids: Optional[List[str]] = None


class FamilyRecipeInDB(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    title: str
    description: Optional[str] = None
    category: RecipeCategory
    difficulty: RecipeDifficulty
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    servings: Optional[int] = None
    ingredients: List[RecipeIngredient]
    steps: List[RecipeStep]
    photos: List[str] = Field(default_factory=list)
    family_notes: Optional[str] = None
    origin_story: Optional[str] = None
    created_by: PyObjectId
    family_circle_ids: List[PyObjectId] = Field(default_factory=list)
    ratings: List[dict] = Field(default_factory=list)  # {user_id, rating}
    times_made: int = 0
    favorites: List[PyObjectId] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {ObjectId: str}
        populate_by_name = True
        arbitrary_types_allowed = True


class FamilyRecipeResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    category: RecipeCategory
    difficulty: RecipeDifficulty
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    servings: Optional[int] = None
    ingredients: List[RecipeIngredient]
    steps: List[RecipeStep]
    photos: List[str]
    family_notes: Optional[str] = None
    origin_story: Optional[str] = None
    created_by: str
    created_by_name: Optional[str] = None
    family_circle_ids: List[str]
    average_rating: float = 0.0
    times_made: int = 0
    favorites_count: int = 0
    created_at: datetime
    updated_at: datetime


class RecipeRatingCreate(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: Optional[str] = None
