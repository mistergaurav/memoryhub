import asyncio
from app.db.mongodb import connect_to_mongo, close_mongo_connection, get_collection

async def check_users():
    await connect_to_mongo()
    
    print("\nListing all users:")
    cursor = get_collection("users").find()
    async for u in cursor:
        print(f"- ID: {u['_id']}, Email: {u.get('email')}, Name: {u.get('full_name')}")
    
    await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(check_users())
