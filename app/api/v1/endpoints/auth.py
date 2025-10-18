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

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate):
    if await get_user_by_email(user.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    hashed_password = get_password_hash(user.password)
    user_dict = user.dict(exclude={"password"})
    user_dict["hashed_password"] = hashed_password
    
    result = await get_collection("users").insert_one(user_dict)
    return {"id": str(result.inserted_id)}

# Alias endpoints for better API compatibility
@router.post("/signup", status_code=status.HTTP_201_CREATED)
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