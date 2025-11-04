#!/usr/bin/env python3
"""
Script to create multiple test users for testing purposes.
Creates users with realistic data and returns their credentials.
"""
import asyncio
import sys
import os
from datetime import datetime, timedelta
from bson import ObjectId

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.db.mongodb import get_collection, connect_to_mongo, close_mongo_connection
from app.core.hashing import get_password_hash


async def create_test_user(email: str, full_name: str, password: str = "TestPass123!"):
    """Create a test user with the given details"""
    users_collection = get_collection("users")
    
    # Check if user already exists
    existing = await users_collection.find_one({"email": email})
    if existing:
        print(f"✓ User {email} already exists (ID: {existing['_id']})")
        return str(existing["_id"])
    
    user_doc = {
        "email": email,
        "username": email.split('@')[0],
        "full_name": full_name,
        "hashed_password": get_password_hash(password),
        "avatar_url": None,
        "bio": f"Test user account for {full_name}",
        "is_active": True,
        "role": "user",
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "city": "San Francisco",
        "country": "USA",
        "website": None,
        "email_verified": True,
        "twofa_enabled": False,
    }
    
    result = await users_collection.insert_one(user_doc)
    user_id = str(result.inserted_id)
    print(f"✓ Created user: {email} (ID: {user_id})")
    return user_id


async def create_family_circle(owner_id: str, name: str):
    """Create a family circle for the user"""
    circles_collection = get_collection("family_circles")
    
    # Check if circle already exists
    existing = await circles_collection.find_one({"owner_id": ObjectId(owner_id), "name": name})
    if existing:
        print(f"  ✓ Family circle '{name}' already exists")
        return str(existing["_id"])
    
    circle_doc = {
        "owner_id": ObjectId(owner_id),
        "name": name,
        "description": f"Family circle for {name}",
        "privacy": "private",
        "members": [ObjectId(owner_id)],
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    }
    
    result = await circles_collection.insert_one(circle_doc)
    print(f"  ✓ Created family circle: {name}")
    return str(result.inserted_id)


async def create_health_record(user_id: str, family_id: str):
    """Create a sample health record for the user"""
    records_collection = get_collection("health_records")
    
    record_doc = {
        "family_id": ObjectId(family_id),
        "subject_type": "self",
        "subject_user_id": ObjectId(user_id),
        "subject_family_member_id": None,
        "subject_friend_circle_id": None,
        "assigned_user_ids": [ObjectId(user_id)],
        "record_type": "diagnosis",
        "title": "Annual Checkup 2025",
        "description": "Routine annual physical examination",
        "date": datetime.utcnow(),
        "provider": "Dr. Jane Smith",
        "location": "General Hospital",
        "severity": "low",
        "attachments": [],
        "notes": "All vitals normal. Continue current medications.",
        "medications": ["Vitamin D 1000 IU daily"],
        "is_confidential": False,
        "is_hereditary": False,
        "approval_status": "approved",
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "created_by": ObjectId(user_id),
    }
    
    result = await records_collection.insert_one(record_doc)
    print(f"  ✓ Created sample health record")
    return str(result.inserted_id)


async def main():
    """Create multiple test users with associated data"""
    print("=" * 60)
    print("Creating Test Users for Memory Hub")
    print("=" * 60)
    print()
    
    # Connect to database
    print("Connecting to MongoDB...")
    await connect_to_mongo()
    print("✓ Connected to database\n")
    
    test_users = [
        {
            "email": "john.doe@example.com",
            "full_name": "John Doe",
            "password": "TestPass123!",
        },
        {
            "email": "jane.smith@example.com",
            "full_name": "Jane Smith",
            "password": "TestPass123!",
        },
        {
            "email": "bob.wilson@example.com",
            "full_name": "Bob Wilson",
            "password": "TestPass123!",
        },
        {
            "email": "alice.johnson@example.com",
            "full_name": "Alice Johnson",
            "password": "TestPass123!",
        },
        {
            "email": "charlie.brown@example.com",
            "full_name": "Charlie Brown",
            "password": "TestPass123!",
        },
    ]
    
    created_users = []
    
    for user_data in test_users:
        print(f"Processing {user_data['email']}...")
        user_id = await create_test_user(
            user_data["email"],
            user_data["full_name"],
            user_data["password"]
        )
        
        # Create family circle
        circle_id = await create_family_circle(user_id, f"{user_data['full_name']}'s Family")
        
        # Create sample health record (use circle_id for family_id)
        await create_health_record(user_id, circle_id)
        
        created_users.append({
            "id": user_id,
            "email": user_data["email"],
            "password": user_data["password"],
            "full_name": user_data["full_name"],
            "circle_id": circle_id,
        })
        print()
    
    print("=" * 60)
    print("Test Users Created Successfully!")
    print("=" * 60)
    print("\nTest Credentials (all users have same password):")
    print("-" * 60)
    for user in created_users:
        print(f"Email: {user['email']:30} | Password: {user['password']}")
        print(f"  User ID: {user['id']}")
        print(f"  Circle ID: {user['circle_id']}")
        print()
    
    print("\nYou can now use these credentials to test:")
    print("  - Login and authentication")
    print("  - Profile loading")
    print("  - Health records management")
    print("  - Family circle features")
    print()
    
    # Test login for first user
    print("Testing API authentication with first user...")
    import httpx
    try:
        async with httpx.AsyncClient() as client:
            # Test login
            login_data = {
                "username": test_users[0]["email"],
                "password": test_users[0]["password"]
            }
            response = await client.post(
                "http://localhost:5000/api/v1/auth/login",
                data=login_data
            )
            
            if response.status_code == 200:
                tokens = response.json()
                access_token = tokens.get("access_token")
                print(f"✓ Login successful!")
                print(f"  Access Token: {access_token[:50]}...")
                
                # Test /users/me endpoint
                headers = {"Authorization": f"Bearer {access_token}"}
                me_response = await client.get(
                    "http://localhost:5000/api/v1/users/me",
                    headers=headers
                )
                
                if me_response.status_code == 200:
                    user_profile = me_response.json()
                    print(f"✓ /users/me endpoint working!")
                    print(f"  Profile data keys: {list(user_profile.keys())}")
                    print(f"  User: {user_profile.get('full_name')} ({user_profile.get('email')})")
                    print(f"  Stats: {user_profile.get('stats')}")
                else:
                    print(f"✗ /users/me failed: {me_response.status_code}")
                    print(f"  Response: {me_response.text}")
            else:
                print(f"✗ Login failed: {response.status_code}")
                print(f"  Response: {response.text}")
    except Exception as e:
        print(f"✗ API test error: {str(e)}")
    
    print("\n" + "=" * 60)
    print("Setup Complete!")
    print("=" * 60)
    
    # Close database connection
    await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(main())
