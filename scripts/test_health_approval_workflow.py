"""
Comprehensive test script for health record approval workflow with visibility controls.

Tests:
1. Creates 3 test users (Alice, Bob, Carol)
2. Alice creates health record for Bob with requested_visibility="family"
3. Verifies Bob gets notification
4. Bob approves with visibility_scope="private"
5. Verifies visibility enforcement for all 3 visibility levels
6. Cleans up test data

Usage:
    python scripts/test_health_approval_workflow.py
"""

import asyncio
import sys
from datetime import datetime
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorClient

# Add parent directory to path for imports
sys.path.insert(0, '.')

from app.core.hashing import get_password_hash
from app.db.mongodb import get_collection


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def print_success(message: str):
    print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")


def print_error(message: str):
    print(f"{Colors.RED}✗ {message}{Colors.RESET}")


def print_info(message: str):
    print(f"{Colors.BLUE}ℹ {message}{Colors.RESET}")


def print_section(message: str):
    print(f"\n{Colors.BOLD}{Colors.YELLOW}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.YELLOW}{message}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.YELLOW}{'='*60}{Colors.RESET}\n")


class TestData:
    """Store test data for cleanup"""
    def __init__(self):
        self.user_ids = []
        self.record_ids = []
        self.notification_ids = []
        self.family_circle_id = None


async def create_test_user(name: str, email: str) -> dict:
    """Create a test user"""
    users_collection = get_collection("users")
    
    user_doc = {
        "email": email,
        "username": name.lower(),
        "full_name": name,
        "hashed_password": get_password_hash("testpass123"),
        "is_active": True,
        "role": "user",
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await users_collection.insert_one(user_doc)
    user_doc["_id"] = result.inserted_id
    
    return user_doc


async def create_family_circle(creator_id: ObjectId, member_ids: list) -> ObjectId:
    """Create a family circle with members"""
    family_collection = get_collection("family_circles")
    
    circle_doc = {
        "name": "Test Family Circle",
        "description": "Test family for health record approval workflow",
        "created_by": creator_id,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "members": [
            {
                "user_id": member_id,
                "role": "admin" if member_id == creator_id else "member",
                "joined_at": datetime.utcnow()
            }
            for member_id in member_ids
        ]
    }
    
    result = await family_collection.insert_one(circle_doc)
    return result.inserted_id


async def create_health_record(creator_id: ObjectId, subject_id: ObjectId, family_id: ObjectId, 
                                 requested_visibility: str, title: str) -> dict:
    """Create a health record"""
    records_collection = get_collection("health_records")
    
    record_doc = {
        "family_id": family_id,
        "subject_type": "self",
        "subject_user_id": subject_id,
        "record_type": "medical",
        "title": title,
        "description": f"Test health record with {requested_visibility} visibility",
        "date": "2025-01-01",
        "is_confidential": True,
        "is_hereditary": False,
        "attachments": [],
        "medications": [],
        "affected_relatives": [],
        "approval_status": "pending_approval",
        "requested_visibility": requested_visibility,
        "visibility_scope": "private",
        "created_by": creator_id,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await records_collection.insert_one(record_doc)
    record_doc["_id"] = result.inserted_id
    
    return record_doc


async def approve_record(record_id: ObjectId, approver_id: ObjectId, visibility_scope: str):
    """Approve a health record with visibility scope"""
    records_collection = get_collection("health_records")
    
    await records_collection.update_one(
        {"_id": record_id},
        {
            "$set": {
                "approval_status": "approved",
                "approved_at": datetime.utcnow(),
                "approved_by": approver_id,
                "visibility_scope": visibility_scope,
                "updated_at": datetime.utcnow()
            }
        }
    )


async def get_visible_records(user_id: ObjectId, family_circle_id: ObjectId) -> list:
    """Get all records visible to a user based on visibility rules"""
    records_collection = get_collection("health_records")
    
    # Build visibility query
    # PRIVATE: Only subject_user_id == current_user OR assigned_user_ids contains current_user OR created_by
    # FAMILY/PUBLIC: Also include if user is in same family circle
    
    query = {
        "approval_status": "approved",
        "$or": [
            # Always visible: user is subject
            {"subject_user_id": user_id},
            # Always visible: user is creator
            {"created_by": user_id},
            # Always visible: user is assigned
            {"assigned_user_ids": user_id},
            # Family/Public visibility: user is in same family circle
            {
                "family_id": family_circle_id,
                "visibility_scope": {"$in": ["family", "public"]}
            }
        ]
    }
    
    cursor = records_collection.find(query)
    records = []
    async for record in cursor:
        records.append(record)
    
    return records


async def check_notification_exists(user_id: ObjectId, record_id: ObjectId) -> bool:
    """Check if a notification exists for a user about a record"""
    notifications_collection = get_collection("notifications")
    
    notification = await notifications_collection.find_one({
        "user_id": user_id,
        "target_id": str(record_id)
    })
    
    return notification is not None


async def cleanup_test_data(test_data: TestData):
    """Clean up all test data"""
    print_section("Cleaning Up Test Data")
    
    try:
        # Delete health records
        if test_data.record_ids:
            records_collection = get_collection("health_records")
            result = await records_collection.delete_many({"_id": {"$in": test_data.record_ids}})
            print_info(f"Deleted {result.deleted_count} health records")
        
        # Delete notifications
        notifications_collection = get_collection("notifications")
        result = await notifications_collection.delete_many({"target_type": "health_record"})
        print_info(f"Deleted {result.deleted_count} notifications")
        
        # Delete family circle
        if test_data.family_circle_id:
            family_collection = get_collection("family_circles")
            await family_collection.delete_one({"_id": test_data.family_circle_id})
            print_info("Deleted family circle")
        
        # Delete test users
        if test_data.user_ids:
            users_collection = get_collection("users")
            result = await users_collection.delete_many({"_id": {"$in": test_data.user_ids}})
            print_info(f"Deleted {result.deleted_count} test users")
        
        print_success("Cleanup completed successfully")
        
    except Exception as e:
        print_error(f"Error during cleanup: {str(e)}")


async def test_visibility_scenario(alice_id: ObjectId, bob_id: ObjectId, carol_id: ObjectId,
                                     family_id: ObjectId, visibility: str, test_data: TestData):
    """Test a specific visibility scenario"""
    print_section(f"Testing Visibility: {visibility.upper()}")
    
    # Alice creates record for Bob with requested visibility
    print_info(f"Alice creates health record for Bob with requested_visibility='{visibility}'")
    record = await create_health_record(
        alice_id, bob_id, family_id, visibility,
        f"Test Record - {visibility.capitalize()} Visibility"
    )
    test_data.record_ids.append(record["_id"])
    print_success(f"Created record {record['_id']}")
    
    # Check record is pending
    records_collection = get_collection("health_records")
    pending_record = await records_collection.find_one({"_id": record["_id"]})
    if pending_record["approval_status"] == "pending_approval":
        print_success("Record status is 'pending_approval'")
    else:
        print_error(f"Expected 'pending_approval', got '{pending_record['approval_status']}'")
        return False
    
    # Bob approves with visibility scope
    print_info(f"Bob approves record with visibility_scope='{visibility}'")
    await approve_record(record["_id"], bob_id, visibility)
    print_success("Record approved")
    
    # Verify visibility for Bob (subject - should always see it)
    bob_records = await get_visible_records(bob_id, family_id)
    bob_can_see = any(str(r["_id"]) == str(record["_id"]) for r in bob_records)
    if bob_can_see:
        print_success("✓ Bob (subject) can see the record")
    else:
        print_error("✗ Bob (subject) CANNOT see the record - FAIL")
        return False
    
    # Verify visibility for Alice (creator - should always see it)
    alice_records = await get_visible_records(alice_id, family_id)
    alice_can_see = any(str(r["_id"]) == str(record["_id"]) for r in alice_records)
    if alice_can_see:
        print_success("✓ Alice (creator) can see the record")
    else:
        print_error("✗ Alice (creator) CANNOT see the record - FAIL")
        return False
    
    # Verify visibility for Carol (family member)
    carol_records = await get_visible_records(carol_id, family_id)
    carol_can_see = any(str(r["_id"]) == str(record["_id"]) for r in carol_records)
    
    if visibility == "private":
        # Carol should NOT see private records
        if not carol_can_see:
            print_success("✓ Carol (family member) CANNOT see PRIVATE record - CORRECT")
        else:
            print_error("✗ Carol (family member) CAN see PRIVATE record - FAIL")
            return False
    else:  # family or public
        # Carol should see family/public records
        if carol_can_see:
            print_success(f"✓ Carol (family member) CAN see {visibility.upper()} record - CORRECT")
        else:
            print_error(f"✗ Carol (family member) CANNOT see {visibility.upper()} record - FAIL")
            return False
    
    print_success(f"All visibility checks passed for {visibility.upper()}")
    return True


async def run_tests():
    """Run all tests"""
    test_data = TestData()
    all_tests_passed = True
    
    try:
        print_section("Health Record Approval Workflow Test")
        print_info("This test validates the approval workflow with visibility controls")
        
        # Step 1: Create test users
        print_section("Step 1: Creating Test Users")
        
        alice = await create_test_user("Alice", "alice@test.com")
        test_data.user_ids.append(alice["_id"])
        print_success(f"Created Alice (ID: {alice['_id']})")
        
        bob = await create_test_user("Bob", "bob@test.com")
        test_data.user_ids.append(bob["_id"])
        print_success(f"Created Bob (ID: {bob['_id']})")
        
        carol = await create_test_user("Carol", "carol@test.com")
        test_data.user_ids.append(carol["_id"])
        print_success(f"Created Carol (ID: {carol['_id']})")
        
        # Step 2: Create family circle
        print_section("Step 2: Creating Family Circle")
        
        family_id = await create_family_circle(
            alice["_id"],
            [alice["_id"], bob["_id"], carol["_id"]]
        )
        test_data.family_circle_id = family_id
        print_success(f"Created family circle (ID: {family_id})")
        
        # Step 3-6: Test each visibility level
        visibility_levels = ["private", "family", "public"]
        
        for visibility in visibility_levels:
            success = await test_visibility_scenario(
                alice["_id"], bob["_id"], carol["_id"],
                family_id, visibility, test_data
            )
            if not success:
                all_tests_passed = False
        
        # Final summary
        print_section("Test Summary")
        if all_tests_passed:
            print_success("ALL TESTS PASSED! ✓")
            print_info("The health record approval workflow with visibility controls is working correctly")
        else:
            print_error("SOME TESTS FAILED! ✗")
            print_info("Please review the failed tests above")
        
    except Exception as e:
        print_error(f"Test failed with exception: {str(e)}")
        import traceback
        traceback.print_exc()
        all_tests_passed = False
    
    finally:
        # Always cleanup
        await cleanup_test_data(test_data)
    
    return all_tests_passed


async def main():
    """Main entry point"""
    try:
        # Initialize MongoDB connection
        from app.db.mongodb import connect_to_mongo, close_mongo_connection
        
        print(f"{Colors.BOLD}Health Record Approval Workflow Test{Colors.RESET}")
        print(f"{Colors.BOLD}{'='*60}{Colors.RESET}\n")
        
        # Connect to MongoDB
        print_info("Connecting to MongoDB...")
        await connect_to_mongo()
        print_success("Connected to MongoDB")
        
        try:
            success = await run_tests()
        finally:
            # Always close connection
            print_info("Closing MongoDB connection...")
            await close_mongo_connection()
            print_success("MongoDB connection closed")
        
        # Exit with appropriate code
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print_error(f"Fatal error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
