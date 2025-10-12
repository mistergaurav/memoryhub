from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional, Dict, Any
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

class TemplateField(BaseModel):
    name: str
    type: str  # "text", "image", "date", "location", "tags"
    required: bool = False
    placeholder: Optional[str] = None

class TemplateCreate(BaseModel):
    name: str
    description: Optional[str] = None
    category: str
    fields: List[TemplateField]
    is_public: bool = False

@router.post("/")
async def create_template(
    template: TemplateCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Create a new memory template"""
    db = get_database()
    
    template_data = {
        "user_id": str(current_user.id),
        "name": template.name,
        "description": template.description,
        "category": template.category,
        "fields": [field.dict() for field in template.fields],
        "is_public": template.is_public,
        "usage_count": 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.memory_templates.insert_one(template_data)
    template_data["_id"] = str(result.inserted_id)
    
    return template_data

@router.get("/")
async def get_templates(
    category: Optional[str] = None,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get available templates (user's own + public templates)"""
    db = get_database()
    
    query = {
        "$or": [
            {"user_id": str(current_user.id)},
            {"is_public": True}
        ]
    }
    
    if category:
        query["category"] = category
    
    templates = await db.memory_templates.find(query).sort("usage_count", -1).to_list(100)
    
    for template in templates:
        template["_id"] = str(template["_id"])
    
    return templates

@router.get("/{template_id}")
async def get_template(
    template_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get a specific template"""
    db = get_database()
    
    template = await db.memory_templates.find_one({"_id": ObjectId(template_id)})
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    
    template["_id"] = str(template["_id"])
    return template

@router.post("/{template_id}/use")
async def use_template(
    template_id: str,
    data: Dict[str, Any],
    current_user: UserInDB = Depends(get_current_user)
):
    """Use a template to create a memory"""
    db = get_database()
    
    template = await db.memory_templates.find_one({"_id": ObjectId(template_id)})
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    
    # Validate required fields
    for field in template["fields"]:
        if field["required"] and field["name"] not in data:
            raise HTTPException(
                status_code=400,
                detail=f"Required field '{field['name']}' is missing"
            )
    
    # Create memory from template
    memory_data = {
        "user_id": str(current_user.id),
        "template_id": template_id,
        "template_name": template["name"],
        "data": data,
        "created_at": datetime.utcnow()
    }
    
    result = await db.memories.insert_one(memory_data)
    
    # Increment usage count
    await db.memory_templates.update_one(
        {"_id": ObjectId(template_id)},
        {"$inc": {"usage_count": 1}}
    )
    
    memory_data["_id"] = str(result.inserted_id)
    return memory_data

@router.get("/categories/list")
async def get_template_categories(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all template categories"""
    db = get_database()
    
    categories = await db.memory_templates.distinct("category")
    
    return categories

@router.delete("/{template_id}")
async def delete_template(
    template_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Delete a template"""
    db = get_database()
    
    template = await db.memory_templates.find_one({"_id": ObjectId(template_id)})
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    
    if template["user_id"] != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await db.memory_templates.delete_one({"_id": ObjectId(template_id)})
    
    return {"message": "Template deleted"}
