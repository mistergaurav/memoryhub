import asyncio
from bson import ObjectId
from app.db.mongodb import connect_to_mongo, close_mongo_connection, get_collection
from app.core.config import settings

async def check_notification():
    await connect_to_mongo()
    
    notification_id = "69217b1d49708de0b6d670e2"
    
    try:
        # 1. Check if notification exists at all
        notif = await get_collection("notifications").find_one({"_id": ObjectId(notification_id)})
        
        if notif:
            print(f"Notification FOUND: {notif['_id']}")
            print(f"User ID: {notif['user_id']}")
            print(f"Type: {notif['type']}")
            
            # 2. Check if health record exists
            if "health_record_id" in notif:
                hr = await get_collection("health_records").find_one({"_id": notif["health_record_id"]})
                print(f"Health Record: {'FOUND' if hr else 'NOT FOUND'} ({notif['health_record_id']})")
            else:
                print("No health_record_id in notification")
                
        else:
            print(f"Notification NOT FOUND with ID: {notification_id}")
            
            # List all notifications to see if ID is close or if there are any
            print("\nListing recent notifications:")
            cursor = get_collection("notifications").find().limit(5)
            async for n in cursor:
                print(f"- {n['_id']} (User: {n['user_id']})")
                
    except Exception as e:
        print(f"Error: {e}")
    
    await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(check_notification())
