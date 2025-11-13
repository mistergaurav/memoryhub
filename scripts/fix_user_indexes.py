#!/usr/bin/env python3
"""
Script to fix MongoDB user collection indexes.
Drops conflicting indexes and recreates them properly including the text search index.
"""
import asyncio
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings
from app.db.mongodb import get_collection, connect_to_mongo, close_mongo_connection


async def fix_user_indexes():
    """Drop conflicting indexes and recreate all user indexes properly"""
    print("🔧 Fixing user collection indexes...")
    
    try:
        users_collection = get_collection("users")
        
        # Get existing indexes
        existing_indexes = await users_collection.index_information()
        print(f"\n📋 Existing indexes: {list(existing_indexes.keys())}")
        
        # Drop conflicting email_1 index if it exists
        if "email_1" in existing_indexes:
            print("🗑️  Dropping conflicting 'email_1' index...")
            await users_collection.drop_index("email_1")
            print("✅ Dropped email_1 index")
        
        # Drop old username index if it exists
        if "username_1" in existing_indexes:
            print("🗑️  Dropping old 'username_1' index...")
            await users_collection.drop_index("username_1")
            print("✅ Dropped username_1 index")
        
        # Create new indexes with proper names
        print("\n📝 Creating indexes...")
        
        # 1. Email unique index
        try:
            await users_collection.create_index(
                "email",
                unique=True,
                name="email_unique"
            )
            print("✅ Created 'email_unique' index")
        except Exception as e:
            print(f"⚠️  Email index: {str(e)}")
        
        # 2. Username unique sparse index
        try:
            await users_collection.create_index(
                "username",
                unique=True,
                sparse=True,
                name="username_unique_sparse"
            )
            print("✅ Created 'username_unique_sparse' index")
        except Exception as e:
            print(f"⚠️  Username index: {str(e)}")
        
        # 3. Created_at index
        try:
            await users_collection.create_index(
                "created_at",
                name="created_at_1"
            )
            print("✅ Created 'created_at_1' index")
        except Exception as e:
            print(f"⚠️  Created_at index: {str(e)}")
        
        # 4. TEXT SEARCH INDEX - This is the critical one for /api/v1/users/search
        try:
            await users_collection.create_index(
                [("full_name", "text"), ("email", "text"), ("username", "text")],
                name="users_text_search"
            )
            print("✅ Created 'users_text_search' TEXT INDEX (CRITICAL FOR SEARCH)")
        except Exception as e:
            print(f"⚠️  Text search index: {str(e)}")
        
        # Verify all indexes were created
        final_indexes = await users_collection.index_information()
        print(f"\n✨ Final indexes: {list(final_indexes.keys())}")
        
        # Confirm text index exists
        if "users_text_search" in final_indexes:
            print("\n🎉 SUCCESS! Text search index is now active.")
            print("   The /api/v1/users/search endpoint should now work correctly.")
        else:
            print("\n❌ ERROR: Text search index was not created!")
            return False
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error fixing indexes: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """Main function to connect to DB and run fixes"""
    try:
        # Connect to MongoDB
        print("🔌 Connecting to MongoDB...")
        await connect_to_mongo()
        print("✅ Connected to MongoDB\n")
        
        # Run the fix
        success = await fix_user_indexes()
        
        # Close connection
        await close_mongo_connection()
        return success
    except Exception as e:
        print(f"❌ Fatal error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
