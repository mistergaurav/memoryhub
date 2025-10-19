"""Authentication endpoints module."""
from fastapi import APIRouter
from .auth import router as auth_router
from .password_reset import router as password_reset_router
from .two_factor import router as two_factor_router
from .email_verification import router as email_verification_router

router = APIRouter()
router.include_router(auth_router, tags=["auth"])
router.include_router(password_reset_router, tags=["password-reset"])
router.include_router(two_factor_router, tags=["2fa"])
router.include_router(email_verification_router, tags=["email-verification"])

__all__ = ["router"]
