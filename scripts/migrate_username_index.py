"""
MongoDB Index Migration Script - Fix Username Index Conflict

This script safely migrates the users collection indexes by:
1. Inspecting existing indexes
2. Dropping conflicting non-unique username index if it exists
3. Creating properly configured unique sparse index with explicit naming
4. Ensuring idempotency for safe re-runs

Usage: python scripts/migrate_username_index.py
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.mongodb import get_collection, connect_to_mongo, close_mongo_connection


async def migrate_username_index():
    """Safely migrate username index to fix conflicts"""
    print("=" * 70)
    print("MongoDB Index Migration - Username Index Fix")
    print("=" * 70)
    
    users_collection = get_collection("users")
    
    # Step 1: Inspect existing indexes
    print("\n[1/4] Inspecting existing indexes on 'users' collection...")
    existing_indexes = await users_collection.index_information()
    
    print(f"Found {len(existing_indexes)} existing indexes:")
    for idx_name, idx_info in existing_indexes.items():
        unique_flag = idx_info.get('unique', False)
        sparse_flag = idx_info.get('sparse', False)
        key_spec = idx_info.get('key', [])
        print(f"  - {idx_name}: keys={key_spec}, unique={unique_flag}, sparse={sparse_flag}")
    
    # Step 2: Check if problematic index exists
    print("\n[2/4] Checking for conflicting username index...")
    username_idx_found = None
    username_idx_correct = False
    
    for idx_name, idx_info in existing_indexes.items():
        key_spec = idx_info.get('key', [])
        # Check if this is a username index
        if len(key_spec) == 1 and key_spec[0][0] == 'username':
            username_idx_found = idx_name
            is_unique = idx_info.get('unique', False)
            is_sparse = idx_info.get('sparse', False)
            
            # Check if it has the correct properties
            if is_unique and is_sparse:
                username_idx_correct = True
                print(f"  ✓ Found correct username index: '{idx_name}' (unique + sparse)")
            else:
                print(f"  ✗ Found incorrect username index: '{idx_name}' (unique={is_unique}, sparse={is_sparse})")
    
    if username_idx_correct:
        print("\n✅ Username index is already correctly configured!")
        print("   No migration needed.")
        return True
    
    # Step 3: Drop incorrect index if it exists
    if username_idx_found and not username_idx_correct:
        print(f"\n[3/4] Dropping incorrect index '{username_idx_found}'...")
        try:
            await users_collection.drop_index(username_idx_found)
            print(f"  ✓ Successfully dropped index '{username_idx_found}'")
        except Exception as e:
            print(f"  ✗ Error dropping index: {e}")
            return False
    else:
        print("\n[3/4] No incorrect index to drop.")
    
    # Step 4: Create correct username index with explicit name
    print("\n[4/4] Creating correct username index...")
    try:
        # Use explicit name to avoid conflicts
        await users_collection.create_index(
            "username",
            unique=True,
            sparse=True,
            name="username_unique_sparse"
        )
        print("  ✓ Successfully created index 'username_unique_sparse' (unique + sparse)")
    except Exception as e:
        # Check if it's because the index already exists
        if "already exists" in str(e).lower():
            print("  ℹ Index already exists with correct configuration")
        else:
            print(f"  ✗ Error creating index: {e}")
            return False
    
    # Step 5: Verify final state
    print("\n[5/5] Verifying final index configuration...")
    final_indexes = await users_collection.index_information()
    
    username_final_check = False
    for idx_name, idx_info in final_indexes.items():
        key_spec = idx_info.get('key', [])
        if len(key_spec) == 1 and key_spec[0][0] == 'username':
            is_unique = idx_info.get('unique', False)
            is_sparse = idx_info.get('sparse', False)
            print(f"  Final username index: '{idx_name}' (unique={is_unique}, sparse={is_sparse})")
            if is_unique and is_sparse:
                username_final_check = True
    
    print("\n" + "=" * 70)
    if username_final_check:
        print("✅ MIGRATION COMPLETED SUCCESSFULLY!")
        print("   Username index is now correctly configured.")
    else:
        print("❌ MIGRATION FAILED!")
        print("   Please review the errors above.")
    print("=" * 70)
    
    return username_final_check


async def update_index_creation_code():
    """Update the create_all_indexes function to use explicit index names and be idempotent"""
    print("\n📝 Recommendation for app/utils/db_indexes.py:")
    print("   Update line 13 to use explicit index name:")
    print("   await get_collection('users').create_index('username', unique=True, sparse=True, name='username_unique_sparse')")
    print("\n   This prevents future conflicts and makes index creation idempotent.")


async def main():
    """Run the migration"""
    try:
        # Connect to MongoDB
        print("🔌 Connecting to MongoDB...")
        await connect_to_mongo()
        print("✓ Connected to MongoDB\n")
        
        success = await migrate_username_index()
        await update_index_creation_code()
        
        # Close MongoDB connection
        await close_mongo_connection()
        
        if success:
            print("\n🎉 You can now restart your backend workflow without index warnings!")
            sys.exit(0)
        else:
            print("\n⚠️  Migration encountered issues. Please review and try again.")
            sys.exit(1)
    except Exception as e:
        print(f"\n❌ Migration failed with error: {e}")
        import traceback
        traceback.print_exc()
        try:
            await close_mongo_connection()
        except:
            pass
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
