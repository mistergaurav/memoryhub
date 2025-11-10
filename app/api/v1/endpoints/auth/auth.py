from datetime import timedelta
from typing import Optional
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel
from app.core.security import (
    create_access_token,
    create_refresh_token,
    get_user_by_email,
    refresh_access_token,
)
from app.core.hashing import get_password_hash, verify_password
from app.models.user import UserInDB, UserCreate
from app.core.config import settings
from app.db.mongodb import get_collection

router = APIRouter()

class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class RegisterResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: dict
    email_verified: bool

@router.post("/token", response_model=TokenResponse)
async def login_for_access_token(login_data: LoginRequest):
    user = await get_user_by_email(login_data.email)
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, 
        expires_delta=access_token_expires
    )
    
    refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    refresh_token = create_refresh_token(
        data={"sub": user.email},
        expires_delta=refresh_token_expires
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@router.post("/refresh-token", response_model=TokenResponse)
async def refresh_token(refresh_token: str):
    try:
        tokens = await refresh_access_token(refresh_token)
        return tokens
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )

@router.post("/register", status_code=status.HTTP_201_CREATED, response_model=RegisterResponse)
async def register(user: UserCreate):
    if await get_user_by_email(user.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    from datetime import datetime
    import secrets
    from app.utils.username_generator import generate_unique_username, is_username_available
    
    hashed_password = get_password_hash(user.password)
    user_dict = user.dict(exclude={"password"})
    user_dict["hashed_password"] = hashed_password
    user_dict["email_verified"] = False
    user_dict["created_at"] = datetime.utcnow()
    
    if user_dict.get("username"):
        if not await is_username_available(user_dict["username"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken. Please choose another username."
            )
    else:
        user_dict["username"] = await generate_unique_username()
    
    result = await get_collection("users").insert_one(user_dict)
    user_id = str(result.inserted_id)
    
    # Generate email verification token
    verification_token = secrets.token_urlsafe(32)
    await get_collection("email_verifications").insert_one({
        "user_id": user_id,
        "email": user.email,
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
            to_email=user.email,
            verification_token=verification_token,
            user_name=user.full_name
        )
    else:
        print(f"Email service not configured - verification token: {verification_token}")
    
    # Generate JWT tokens for auto-login
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, 
        expires_delta=access_token_expires
    )
    
    refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    refresh_token = create_refresh_token(
        data={"sub": user.email},
        expires_delta=refresh_token_expires
    )
    
    # Return tokens with user info
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "email": user.email,
            "username": user_dict["username"],
            "full_name": user.full_name,
        },
        "email_verified": False
    }

# Alias endpoints for better API compatibility
@router.post("/signup", status_code=status.HTTP_201_CREATED, response_model=RegisterResponse)
async def signup_alias(user: UserCreate):
    """Alias for /register endpoint"""
    return await register(user)

@router.post("/login", response_model=TokenResponse)
async def login_alias(login_data: LoginRequest):
    """Alias for /token endpoint"""
    return await login_for_access_token(login_data)

@router.post("/refresh", response_model=TokenResponse)
async def refresh_alias(refresh_token_str: str):
    """Alias for /refresh-token endpoint"""
    try:
        tokens = await refresh_access_token(refresh_token_str)
        return tokens
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )

@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout():
    """Logout endpoint (client-side token invalidation)"""
    return {"message": "Logged out successfully"}

# Google OAuth Endpoints
@router.get("/google/login")
async def google_login():
    """Initiate Google OAuth flow"""
    if not settings.is_google_oauth_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google OAuth is not configured. Please add GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET environment variables."
        )
    
    from urllib.parse import urlencode
    params = {
        "client_id": settings.GOOGLE_CLIENT_ID,
        "redirect_uri": settings.GOOGLE_REDIRECT_URI,
        "response_type": "code",
        "scope": "openid email profile",
        "access_type": "offline",
        "prompt": "consent"
    }
    auth_url = f"{settings.GOOGLE_AUTH_URL}?{urlencode(params)}"
    return {"auth_url": auth_url}

@router.get("/google/callback")
async def google_callback(code: str):
    """Handle Google OAuth callback"""
    if not settings.is_google_oauth_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google OAuth is not configured"
        )
    
    import httpx
    from datetime import datetime
    
    # Exchange authorization code for tokens
    async with httpx.AsyncClient() as client:
        token_response = await client.post(
            settings.GOOGLE_TOKEN_URL,
            data={
                "code": code,
                "client_id": settings.GOOGLE_CLIENT_ID,
                "client_secret": settings.GOOGLE_CLIENT_SECRET,
                "redirect_uri": settings.GOOGLE_REDIRECT_URI,
                "grant_type": "authorization_code"
            }
        )
        
        if token_response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to exchange authorization code for token"
            )
        
        token_data = token_response.json()
        google_access_token = token_data.get("access_token")
        
        if not google_access_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No access token received from Google"
            )
        
        # Get user info from Google
        user_info_response = await client.get(
            settings.GOOGLE_USER_INFO_URL,
            headers={"Authorization": f"Bearer {google_access_token}"}
        )
        
        if user_info_response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to get user info from Google"
            )
        
        user_info = user_info_response.json()
    
    email = user_info.get("email")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email not provided by Google"
        )
    
    # Check if user exists
    user = await get_user_by_email(email)
    
    if not user:
        # Create new user
        from app.utils.username_generator import generate_unique_username
        
        name = user_info.get("name", email.split('@')[0])
        avatar_url = user_info.get("picture")
        
        user_dict = {
            "email": email,
            "full_name": name,
            "username": await generate_unique_username(),
            "hashed_password": None,  # OAuth users don't have password
            "avatar_url": avatar_url,
            "email_verified": True,  # Google verifies emails
            "created_at": datetime.utcnow(),
            "is_active": True,
            "role": "user",
        }
        
        result = await get_collection("users").insert_one(user_dict)
        user_id = str(result.inserted_id)
    else:
        # User exists, get their ID
        user_data = await get_collection("users").find_one({"email": email})
        if not user_data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="User data not found after verification"
            )
        user_id = str(user_data["_id"])
        
        # Update avatar if Google provides a new one
        if user_info.get("picture"):
            await get_collection("users").update_one(
                {"email": email},
                {"$set": {"avatar_url": user_info.get("picture")}}
            )
    
    # Generate JWT tokens
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": email}, 
        expires_delta=access_token_expires
    )
    
    refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    refresh_token = create_refresh_token(
        data={"sub": email},
        expires_delta=refresh_token_expires
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "email": email,
            "full_name": user_info.get("name"),
            "avatar_url": user_info.get("picture"),
        }
    }