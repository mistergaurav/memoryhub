import asyncio
from app.db.mongodb import db, connect_to_mongo, close_mongo_connection
from pprint import pprint

async def check_notifications():
    await connect_to_mongo()
    try:
        print("Checking notifications...")
        cursor = db.client.memory_hub.notifications.find().sort("created_at", -1).limit(10)
        notifications = await cursor.to_list(length=10)
        
        if not notifications:
            print("No notifications found.")
        else:
            print(f"Found {len(notifications)} notifications:")
            for n in notifications:
                print(f"\nType: {n.get('type')}")
                print(f"User ID: {n.get('user_id')}")
                print(f"Title: {n.get('title')}")
                print(f"Message: {n.get('message')}")
                print(f"Created At: {n.get('created_at')}")
                
    except Exception as e:
        print(f"Error checking notifications: {e}")
    finally:
        await close_mongo_connection()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(check_notifications())
