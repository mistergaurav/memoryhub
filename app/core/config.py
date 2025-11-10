from pydantic_settings import BaseSettings
from typing import Optional
import secrets
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "The Memory Hub"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Security - Fixed key for development to prevent token invalidation on restart
    # Override with SECRET_KEY environment variable in production
    SECRET_KEY: str = "ruVHU-4Pol1dzKCpfrH51mExSE9ab38u5jyo5gPg9cU"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # Database
    MONGODB_URL: str = "mongodb://localhost:27017"
    DB_NAME: str = "memory_hub"
    
    # File Storage
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10 MB
    ALLOWED_FILE_EXTENSIONS: list = [".jpg", ".jpeg", ".png", ".gif", ".pdf", ".doc", ".docx", ".txt"]
    
    # Google OAuth Settings
    GOOGLE_CLIENT_ID: Optional[str] = None
    GOOGLE_CLIENT_SECRET: Optional[str] = None
    GOOGLE_AUTH_URL: str = "https://accounts.google.com/o/oauth2/v2/auth"
    GOOGLE_TOKEN_URL: str = "https://oauth2.googleapis.com/token"
    GOOGLE_USER_INFO_URL: str = "https://www.googleapis.com/oauth2/v2/userinfo"
    
    @property
    def GOOGLE_REDIRECT_URI(self) -> str:
        """Generate redirect URI based on environment"""
        replit_domain = os.getenv("REPL_SLUG")
        if replit_domain:
            return f"https://{replit_domain}.replit.dev/api/v1/auth/google/callback"
        return "http://localhost:5000/api/v1/auth/google/callback"
    
    def is_google_oauth_configured(self) -> bool:
        """Check if Google OAuth is properly configured"""
        return bool(self.GOOGLE_CLIENT_ID and self.GOOGLE_CLIENT_SECRET)
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()