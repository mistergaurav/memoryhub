from fastapi import APIRouter, HTTPException, Depends
from typing import Optional
from datetime import datetime, timedelta
from bson import ObjectId
from pydantic import BaseModel, EmailStr
from app.db.mongodb import get_database
from app.core.hashing import get_password_hash
from app.models.user import UserInDB
from app.core.security import get_current_user
import secrets

router = APIRouter()

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str

@router.post("/request")
async def request_password_reset(data: PasswordResetRequest):
    """Request a password reset"""
    db = get_database()
    
    user = await db.users.find_one({"email": data.email})
    if not user:
        # Don't reveal if email exists
        return {"message": "If the email exists, a reset link will be sent"}
    
    # Generate reset token
    reset_token = secrets.token_urlsafe(32)
    reset_expires = datetime.utcnow() + timedelta(hours=1)
    
    # Store reset token
    await db.password_resets.insert_one({
        "user_id": str(user["_id"]),
        "email": data.email,
        "token": reset_token,
        "expires_at": reset_expires,
        "used": False,
        "created_at": datetime.utcnow()
    })
    
    # In production, send email with reset link
    # Email service integration would send the reset_token via email
    # reset_link = f"https://memoryhub.com/reset-password?token={reset_token}"
    
    return {
        "message": "If the email exists, a reset link has been sent to your email address"
    }

@router.post("/verify-token")
async def verify_reset_token(token: str):
    """Verify if reset token is valid"""
    db = get_database()
    
    reset = await db.password_resets.find_one({
        "token": token,
        "used": False,
        "expires_at": {"$gt": datetime.utcnow()}
    })
    
    if not reset:
        raise HTTPException(status_code=400, detail="Invalid or expired token")
    
    return {"message": "Token is valid", "email": reset["email"]}

@router.post("/confirm")
async def confirm_password_reset(data: PasswordResetConfirm):
    """Reset password with token"""
    db = get_database()
    
    # Find valid reset request
    reset = await db.password_resets.find_one({
        "token": data.token,
        "used": False,
        "expires_at": {"$gt": datetime.utcnow()}
    })
    
    if not reset:
        raise HTTPException(status_code=400, detail="Invalid or expired token")
    
    # Update user password
    hashed_password = get_password_hash(data.new_password)
    await db.users.update_one(
        {"_id": ObjectId(reset["user_id"])},
        {"$set": {"hashed_password": hashed_password}}
    )
    
    # Mark token as used
    await db.password_resets.update_one(
        {"_id": reset["_id"]},
        {"$set": {"used": True, "used_at": datetime.utcnow()}}
    )
    
    return {"message": "Password reset successfully"}

@router.get("/history")
async def get_reset_history(
    email: str,
    current_user: UserInDB = Depends(get_current_user)
):
    """Get reset history for an email (admin only)"""
    db = get_database()
    
    # Check if user is admin
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    resets = await db.password_resets.find({
        "email": email
    }).sort("created_at", -1).limit(10).to_list(10)
    
    for reset in resets:
        reset["_id"] = str(reset["_id"])
    
    return resets

# Alias endpoints for better API compatibility
@router.post("/verify")
async def verify_alias(token: str):
    """Alias for /verify-token endpoint"""
    return await verify_reset_token(token)

@router.post("/reset")
async def reset_alias(data: PasswordResetConfirm):
    """Alias for /confirm endpoint"""
    return await confirm_password_reset(data)
