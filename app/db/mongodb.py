from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional
from app.core.config import settings

class MongoDB:
    client: Optional[AsyncIOMotorClient] = None

db = MongoDB()

async def connect_to_mongo():
    db.client = AsyncIOMotorClient(settings.MONGODB_URL)
    # Note: Indexes are created by utils/db_indexes.py via create_indexes() function

async def close_mongo_connection():
    if db.client:
        db.client.close()

def get_database():
    if not db.client:
        raise RuntimeError("Database not connected")
    return db.client[settings.DB_NAME]

def get_collection(collection_name: str):
    return get_database()[collection_name]