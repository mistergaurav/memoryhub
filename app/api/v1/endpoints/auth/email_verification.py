"""
Email Verification endpoints
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime
from bson import ObjectId
from app.db.mongodb import get_collection

router = APIRouter()


class VerifyEmailRequest(BaseModel):
    token: str


@router.post("/verify-email")
async def verify_email(data: VerifyEmailRequest):
    """Verify user's email address"""
    verification = await get_collection("email_verifications").find_one({
        "token": data.token,
        "verified": False,
        "expires_at": {"$gt": datetime.utcnow()}
    })
    
    if not verification:
        raise HTTPException(
            status_code=400, 
            detail="Invalid or expired verification token"
        )
    
    # Mark email as verified
    await get_collection("users").update_one(
        {"_id": ObjectId(verification["user_id"])},
        {"$set": {"email_verified": True, "verified_at": datetime.utcnow()}}
    )
    
    # Mark verification as used
    await get_collection("email_verifications").update_one(
        {"_id": verification["_id"]},
        {"$set": {"verified": True, "verified_at": datetime.utcnow()}}
    )
    
    # Send welcome email
    from app.services import get_email_service
    email_service = get_email_service()
    
    if email_service.is_configured():
        user = await get_collection("users").find_one({"_id": ObjectId(verification["user_id"])})
        if user:
            await email_service.send_welcome_email(
                to_email=verification["email"],
                user_name=user.get("full_name", "")
            )
    
    return {
        "message": "Email verified successfully! You can now log in.",
        "verified": True
    }


@router.post("/resend-verification")
async def resend_verification(email: str):
    """Resend verification email"""
    user = await get_collection("users").find_one({"email": email})
    
    if not user:
        # Don't reveal if email exists
        return {"message": "If the email exists and is unverified, a new verification link will be sent"}
    
    if user.get("email_verified"):
        return {"message": "Email already verified"}
    
    # Check for existing valid verification
    existing = await get_collection("email_verifications").find_one({
        "user_id": str(user["_id"]),
        "verified": False,
        "expires_at": {"$gt": datetime.utcnow()}
    })
    
    if existing:
        # Reuse existing token
        verification_token = existing["token"]
    else:
        # Create new verification
        import secrets
        from datetime import timedelta
        
        verification_token = secrets.token_urlsafe(32)
        await get_collection("email_verifications").insert_one({
            "user_id": str(user["_id"]),
            "email": email,
            "token": verification_token,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(days=1),
            "verified": False
        })
    
    # Send verification email
    from app.services import get_email_service
    email_service = get_email_service()
    
    if email_service.is_configured():
        await email_service.send_verification_email(
            to_email=email,
            verification_token=verification_token,
            user_name=user.get("full_name")
        )
    
    return {"message": "If the email exists and is unverified, a new verification link has been sent"}
