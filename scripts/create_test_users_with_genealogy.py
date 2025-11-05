#!/usr/bin/env python3
"""
Enhanced script to create test users with complete genealogy trees.
Creates users with realistic family tree data including persons and relationships.
"""
import asyncio
import sys
import os
from datetime import datetime, timedelta
from bson import ObjectId
from typing import List, Dict

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


async def create_genealogy_person(tree_id: str, first_name: str, last_name: str, 
                                   gender: str, birth_year: int = None, is_alive: bool = True):
    """Create a person in the genealogy tree"""
    persons_collection = get_collection("genealogy_persons")
    
    # Calculate birth date
    birth_date = None
    death_date = None
    if birth_year:
        birth_date = datetime(birth_year, 1, 1).isoformat()
        if not is_alive:
            death_date = datetime(birth_year + 75, 1, 1).isoformat()
    
    person_doc = {
        "tree_id": ObjectId(tree_id),
        "family_id": ObjectId(tree_id),
        "first_name": first_name,
        "last_name": last_name,
        "maiden_name": None,
        "gender": gender,
        "birth_date": birth_date,
        "birth_place": "California, USA",
        "death_date": death_date,
        "death_place": None if is_alive else "California, USA",
        "is_alive": is_alive,
        "biography": f"{first_name} {last_name} - Family member",
        "photo_url": None,
        "occupation": "Software Engineer" if is_alive else "Retired",
        "notes": None,
        "linked_user_id": None,
        "source": "manual",
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "created_by": ObjectId(tree_id),
    }
    
    result = await persons_collection.insert_one(person_doc)
    return str(result.inserted_id)


async def create_relationship(tree_id: str, person1_id: str, person2_id: str, 
                              rel_type: str):
    """Create a relationship between two persons"""
    relationships_collection = get_collection("genealogy_relationships")
    
    rel_doc = {
        "tree_id": ObjectId(tree_id),
        "family_id": ObjectId(tree_id),
        "person1_id": person1_id,
        "person2_id": person2_id,
        "relationship_type": rel_type,
        "start_date": None,
        "end_date": None,
        "notes": None,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "created_by": ObjectId(tree_id),
    }
    
    result = await relationships_collection.insert_one(rel_doc)
    return str(result.inserted_id)


async def create_tree_membership(tree_id: str, user_id: str, role: str = "owner"):
    """Grant user access to tree"""
    memberships_collection = get_collection("genealogy_tree_memberships")
    
    # Check if already exists
    existing = await memberships_collection.find_one({
        "tree_id": ObjectId(tree_id),
        "user_id": ObjectId(user_id)
    })
    if existing:
        return
    
    membership_doc = {
        "tree_id": ObjectId(tree_id),
        "user_id": ObjectId(user_id),
        "role": role,
        "joined_at": datetime.utcnow(),
        "invited_by": ObjectId(user_id),
    }
    
    await memberships_collection.insert_one(membership_doc)


async def create_complete_family_tree(user_id: str, user_full_name: str):
    """Create a complete multi-generation family tree for the user"""
    print(f"  Creating genealogy tree for {user_full_name}...")
    
    tree_id = user_id  # In this system, tree_id equals user_id
    first_name, last_name = user_full_name.split(' ', 1)
    
    # Create tree membership
    await create_tree_membership(tree_id, user_id)
    
    # 1. Create the user as a person in the tree
    user_person_id = await create_genealogy_person(
        tree_id, first_name, last_name, "male", 1990, True
    )
    print(f"    ✓ Created self: {first_name} {last_name}")
    
    # 2. Create spouse
    spouse_id = await create_genealogy_person(
        tree_id, "Sarah" if first_name != "Sarah" else "Emma", last_name, "female", 1992, True
    )
    await create_relationship(tree_id, user_person_id, spouse_id, "spouse")
    print(f"    ✓ Created spouse and relationship")
    
    # 3. Create children
    child1_id = await create_genealogy_person(
        tree_id, "Emily", last_name, "female", 2018, True
    )
    await create_relationship(tree_id, user_person_id, child1_id, "parent")
    await create_relationship(tree_id, spouse_id, child1_id, "parent")
    
    child2_id = await create_genealogy_person(
        tree_id, "Michael", last_name, "male", 2020, True
    )
    await create_relationship(tree_id, user_person_id, child2_id, "parent")
    await create_relationship(tree_id, spouse_id, child2_id, "parent")
    print(f"    ✓ Created 2 children with relationships")
    
    # 4. Create parents
    father_id = await create_genealogy_person(
        tree_id, "Robert", last_name, "male", 1960, True
    )
    mother_id = await create_genealogy_person(
        tree_id, "Mary", f"{last_name}-Smith", "female", 1962, True
    )
    await create_relationship(tree_id, father_id, user_person_id, "parent")
    await create_relationship(tree_id, mother_id, user_person_id, "parent")
    await create_relationship(tree_id, father_id, mother_id, "spouse")
    print(f"    ✓ Created parents with relationships")
    
    # 5. Create sibling
    sibling_id = await create_genealogy_person(
        tree_id, "Jennifer", last_name, "female", 1988, True
    )
    await create_relationship(tree_id, father_id, sibling_id, "parent")
    await create_relationship(tree_id, mother_id, sibling_id, "parent")
    await create_relationship(tree_id, user_person_id, sibling_id, "sibling")
    print(f"    ✓ Created sibling with relationships")
    
    # 6. Create grandparents (paternal)
    paternal_grandfather_id = await create_genealogy_person(
        tree_id, "William", last_name, "male", 1935, False
    )
    paternal_grandmother_id = await create_genealogy_person(
        tree_id, "Margaret", f"{last_name}-Johnson", "female", 1938, False
    )
    await create_relationship(tree_id, paternal_grandfather_id, father_id, "parent")
    await create_relationship(tree_id, paternal_grandmother_id, father_id, "parent")
    await create_relationship(tree_id, paternal_grandfather_id, paternal_grandmother_id, "spouse")
    print(f"    ✓ Created paternal grandparents with relationships")
    
    # 7. Create grandparents (maternal)
    maternal_grandfather_id = await create_genealogy_person(
        tree_id, "James", "Smith", "male", 1937, False
    )
    maternal_grandmother_id = await create_genealogy_person(
        tree_id, "Elizabeth", "Smith-Davis", "female", 1940, True
    )
    await create_relationship(tree_id, maternal_grandfather_id, mother_id, "parent")
    await create_relationship(tree_id, maternal_grandmother_id, mother_id, "parent")
    await create_relationship(tree_id, maternal_grandfather_id, maternal_grandmother_id, "spouse")
    print(f"    ✓ Created maternal grandparents with relationships")
    
    print(f"  ✓ Complete family tree created (11 persons, 18 relationships)")
    return tree_id


async def main():
    """Create multiple test users with complete genealogy trees"""
    print("=" * 70)
    print("Creating Test Users with Genealogy Trees for Memory Hub")
    print("=" * 70)
    print()
    
    # Connect to database
    print("Connecting to MongoDB...")
    await connect_to_mongo()
    print("✓ Connected to database\n")
    
    test_users = [
        {"email": "john.doe@example.com", "full_name": "John Doe", "password": "TestPass123!"},
        {"email": "jane.smith@example.com", "full_name": "Jane Smith", "password": "TestPass123!"},
        {"email": "bob.wilson@example.com", "full_name": "Bob Wilson", "password": "TestPass123!"},
    ]
    
    created_users = []
    
    for user_data in test_users:
        print(f"Processing {user_data['email']}...")
        user_id = await create_test_user(
            user_data["email"],
            user_data["full_name"],
            user_data["password"]
        )
        
        # Create complete family tree
        tree_id = await create_complete_family_tree(user_id, user_data["full_name"])
        
        created_users.append({
            "id": user_id,
            "email": user_data["email"],
            "password": user_data["password"],
            "full_name": user_data["full_name"],
            "tree_id": tree_id,
        })
        print()
    
    print("=" * 70)
    print("Test Users with Genealogy Trees Created Successfully!")
    print("=" * 70)
    print("\nTest Credentials:")
    print("-" * 70)
    for user in created_users:
        print(f"Email: {user['email']:35} | Password: {user['password']}")
        print(f"  User ID: {user['id']}")
        print(f"  Tree ID: {user['tree_id']}")
        print()
    
    # Test genealogy tree API
    print("\nTesting Genealogy Tree API with first user...")
    import httpx
    try:
        async with httpx.AsyncClient() as client:
            # Login
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
                
                # Test genealogy tree endpoint
                headers = {"Authorization": f"Bearer {access_token}"}
                tree_response = await client.get(
                    "http://localhost:5000/api/v1/family/genealogy/tree",
                    headers=headers
                )
                
                if tree_response.status_code == 200:
                    tree_data = tree_response.json()
                    print(f"✓ Genealogy tree endpoint working!")
                    print(f"  Response structure: {list(tree_data.keys())}")
                    if 'data' in tree_data and isinstance(tree_data['data'], list):
                        print(f"  Total persons in tree: {len(tree_data['data'])}")
                        if tree_data['data']:
                            sample_node = tree_data['data'][0]
                            print(f"  Sample node structure: {list(sample_node.keys())}")
                else:
                    print(f"✗ Genealogy tree failed: {tree_response.status_code}")
                    print(f"  Response: {tree_response.text[:200]}")
            else:
                print(f"✗ Login failed: {response.status_code}")
    except Exception as e:
        print(f"✗ API test error: {str(e)}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "=" * 70)
    print("Setup Complete! You can now test:")
    print("  - Login with any test user")
    print("  - Navigate to Family → Genealogy Tree")
    print("  - View the complete multi-generation family tree")
    print("  - Test relationships, person cards, and tree visualization")
    print("=" * 70)
    
    # Close database connection
    await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(main())
