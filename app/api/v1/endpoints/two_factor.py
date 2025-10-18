from fastapi import APIRouter, Depends, HTTPException
from typing import Optional
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
import pyotp
import qrcode
import io
import base64
from app.models.user import UserInDB
from app.core.security import get_current_user
from app.db.mongodb import get_database

router = APIRouter()

# Alias endpoint for setup
@router.post("/setup")
async def setup_2fa_alias(current_user: UserInDB = Depends(get_current_user)):
    """Alias for /enable endpoint"""
    return await enable_2fa(current_user)

class TwoFactorEnable(BaseModel):
    code: str

class TwoFactorVerify(BaseModel):
    code: str

@router.post("/enable")
async def enable_2fa(
    current_user: UserInDB = Depends(get_current_user)
):
    """Generate 2FA secret and QR code"""
    db = get_database()
    
    # Generate secret
    secret = pyotp.random_base32()
    
    # Create provisioning URI
    totp = pyotp.TOTP(secret)
    provisioning_uri = totp.provisioning_uri(
        name=current_user.email,
        issuer_name="Memory Hub"
    )
    
    # Generate QR code
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(provisioning_uri)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    qr_code_base64 = base64.b64encode(buffer.getvalue()).decode()
    
    # Store secret temporarily
    await db.users.update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": {
            "two_factor_temp_secret": secret,
            "two_factor_enabled": False
        }}
    )
    
    return {
        "secret": secret,
        "qr_code": f"data:image/png;base64,{qr_code_base64}",
        "provisioning_uri": provisioning_uri
    }

@router.post("/verify-enable")
async def verify_and_enable_2fa(
    data: TwoFactorEnable,
    current_user: UserInDB = Depends(get_current_user)
):
    """Verify code and enable 2FA"""
    db = get_database()
    
    user_doc = await db.users.find_one({"_id": ObjectId(current_user.id)})
    temp_secret = user_doc.get("two_factor_temp_secret")
    
    if not temp_secret:
        raise HTTPException(status_code=400, detail="2FA setup not initiated")
    
    # Verify code
    totp = pyotp.TOTP(temp_secret)
    if not totp.verify(data.code):
        raise HTTPException(status_code=400, detail="Invalid code")
    
    # Enable 2FA
    await db.users.update_one(
        {"_id": ObjectId(current_user.id)},
        {
            "$set": {
                "two_factor_secret": temp_secret,
                "two_factor_enabled": True
            },
            "$unset": {"two_factor_temp_secret": ""}
        }
    )
    
    return {"message": "2FA enabled successfully"}

@router.post("/verify")
async def verify_2fa(
    data: TwoFactorVerify,
    current_user: UserInDB = Depends(get_current_user)
):
    """Verify 2FA code"""
    db = get_database()
    
    user_doc = await db.users.find_one({"_id": ObjectId(current_user.id)})
    
    if not user_doc.get("two_factor_enabled"):
        raise HTTPException(status_code=400, detail="2FA not enabled")
    
    secret = user_doc.get("two_factor_secret")
    totp = pyotp.TOTP(secret)
    
    if not totp.verify(data.code):
        raise HTTPException(status_code=400, detail="Invalid code")
    
    return {"message": "Code verified"}

@router.post("/disable")
async def disable_2fa(
    data: TwoFactorVerify,
    current_user: UserInDB = Depends(get_current_user)
):
    """Disable 2FA"""
    db = get_database()
    
    user_doc = await db.users.find_one({"_id": ObjectId(current_user.id)})
    
    if not user_doc.get("two_factor_enabled"):
        raise HTTPException(status_code=400, detail="2FA not enabled")
    
    # Verify code before disabling
    secret = user_doc.get("two_factor_secret")
    totp = pyotp.TOTP(secret)
    
    if not totp.verify(data.code):
        raise HTTPException(status_code=400, detail="Invalid code")
    
    # Disable 2FA
    await db.users.update_one(
        {"_id": ObjectId(current_user.id)},
        {
            "$set": {"two_factor_enabled": False},
            "$unset": {"two_factor_secret": ""}
        }
    )
    
    return {"message": "2FA disabled successfully"}

@router.get("/status")
async def get_2fa_status(
    current_user: UserInDB = Depends(get_current_user)
):
    """Check if 2FA is enabled"""
    db = get_database()
    
    user_doc = await db.users.find_one({"_id": ObjectId(current_user.id)})
    
    return {
        "enabled": user_doc.get("two_factor_enabled", False)
    }
