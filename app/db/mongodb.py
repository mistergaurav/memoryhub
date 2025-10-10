from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

class MongoDB:
    client: AsyncIOMotorClient = None

db = MongoDB()

async def connect_to_mongo():
    db.client = AsyncIOMotorClient(settings.MONGODB_URL)
    # Create indexes
    await db.client[settings.DB_NAME]["users"].create_index("email", unique=True)

async def close_mongo_connection():
    db.client.close()

def get_database():
    return db.client[settings.DB_NAME]

def get_collection(collection_name: str):
    return get_database()[collection_name]