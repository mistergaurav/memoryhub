from pydantic_settings import BaseSettings
from typing import Optional
import secrets

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
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()