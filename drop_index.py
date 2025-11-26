import asyncio
from app.db.mongodb import db, connect_to_mongo, close_mongo_connection

async def drop_index():
    await connect_to_mongo()
    try:
        print("Dropping index linked_user_id_1 on genealogy_persons...")
        await db.client.memory_hub.genealogy_persons.drop_index("linked_user_id_1")
        print("Index dropped successfully.")
    except Exception as e:
        print(f"Error dropping index: {e}")
    finally:
        await close_mongo_connection()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(drop_index())
