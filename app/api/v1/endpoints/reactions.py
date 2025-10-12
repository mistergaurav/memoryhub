from fastapi import APIRouter, Depends, HTTPException
from typing import List
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

class ReactionCreate(BaseModel):
    target_type: str  # "memory", "comment", "story"
    target_id: str
    emoji: str

@router.post("/")
async def add_reaction(
    reaction: ReactionCreate,
    current_user: UserInDB = Depends(get_current_user)
):
    """Add a reaction to a memory, comment, or story"""
    db = get_database()
    
    # Check if reaction already exists
    existing = await db.reactions.find_one({
        "user_id": str(current_user.id),
        "target_type": reaction.target_type,
        "target_id": reaction.target_id
    })
    
    if existing:
        # Update existing reaction
        await db.reactions.update_one(
            {"_id": existing["_id"]},
            {"$set": {"emoji": reaction.emoji, "updated_at": datetime.utcnow()}}
        )
        reaction_data = existing
        reaction_data["emoji"] = reaction.emoji
    else:
        # Create new reaction
        reaction_data = {
            "user_id": str(current_user.id),
            "target_type": reaction.target_type,
            "target_id": reaction.target_id,
            "emoji": reaction.emoji,
            "created_at": datetime.utcnow()
        }
        result = await db.reactions.insert_one(reaction_data)
        reaction_data["_id"] = str(result.inserted_id)
    
    return reaction_data

@router.get("/{target_type}/{target_id}")
async def get_reactions(
    target_type: str,
    target_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get all reactions for a target"""
    db = get_database()
    
    reactions = await db.reactions.find({
        "target_type": target_type,
        "target_id": target_id
    }).to_list(1000)
    
    # Group reactions by emoji
    reaction_summary = {}
    for reaction in reactions:
        emoji = reaction["emoji"]
        if emoji not in reaction_summary:
            reaction_summary[emoji] = {
                "emoji": emoji,
                "count": 0,
                "users": [],
                "reacted_by_current_user": False
            }
        reaction_summary[emoji]["count"] += 1
        reaction_summary[emoji]["users"].append(str(reaction["user_id"]))
        if str(reaction["user_id"]) == str(current_user.id):
            reaction_summary[emoji]["reacted_by_current_user"] = True
    
    return list(reaction_summary.values())

@router.delete("/{target_type}/{target_id}")
async def remove_reaction(
    target_type: str,
    target_id: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Remove user's reaction from a target"""
    db = get_database()
    
    result = await db.reactions.delete_one({
        "user_id": str(current_user.id),
        "target_type": target_type,
        "target_id": target_id
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Reaction not found")
    
    return {"message": "Reaction removed"}

@router.get("/user/stats")
async def get_user_reaction_stats(
    current_user: UserInDB = Depends(get_current_user)
):
    """Get statistics about user's reactions"""
    db = get_database()
    
    reactions = await db.reactions.find({
        "user_id": str(current_user.id)
    }).to_list(10000)
    
    emoji_counts = {}
    for reaction in reactions:
        emoji = reaction["emoji"]
        emoji_counts[emoji] = emoji_counts.get(emoji, 0) + 1
    
    return {
        "total_reactions": len(reactions),
        "emoji_breakdown": emoji_counts,
        "most_used_emoji": max(emoji_counts.items(), key=lambda x: x[1])[0] if emoji_counts else None
    }
