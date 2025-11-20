import asyncio
from app.db.mongodb import get_database
from app.repositories.family.users import UserRepository
from bson import ObjectId

async def main():
    db = await get_database()
    user_repo = UserRepository()
    
    print("--- All Users ---")
    users = await user_repo.find_many({}, limit=100)
    for user in users:
        print(f"ID: {user['_id']}, Username: {user.get('username')}, Email: {user.get('email')}, Name: {user.get('full_name')}")
        
    if not users:
        print("No users found in DB.")
        return

    print("\n--- Testing Search ---")
    # Pick a user to search for (not the first one, to test exclusion if we were excluding the first one)
    if len(users) > 0:
        target_user = users[0]
        query = target_user.get('username') or target_user.get('email') or "test"
        print(f"Searching for: '{query}'")
        
        # Test search without exclusion
        results = await user_repo.search_users(query)
        print(f"Results (no exclusion): {len(results)}")
        for r in results:
            print(f" - Found: {r.get('username')}")

        # Test search with exclusion (exclude the target user)
        results_excluded = await user_repo.search_users(query, exclude_user_id=str(target_user['_id']))
        print(f"Results (excluding {target_user['_id']}): {len(results_excluded)}")
        for r in results_excluded:
            print(f" - Found: {r.get('username')}")

if __name__ == "__main__":
    asyncio.run(main())
