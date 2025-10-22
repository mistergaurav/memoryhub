"""Rate limiting middleware for API protection."""
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.core.config import settings

# Create rate limiter instance
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[f"{settings.RATE_LIMIT_REQUESTS}/{settings.RATE_LIMIT_PERIOD}seconds"],
    enabled=settings.RATE_LIMIT_ENABLED,
    storage_uri="memory://",
)

__all__ = ["limiter", "RateLimitExceeded", "_rate_limit_exceeded_handler"]
