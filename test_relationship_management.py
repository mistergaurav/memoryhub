"""
Comprehensive test suite for the enhanced relationship management system.
Tests custom relationship categories, person profiles, and sharing integration.
"""
import pytest
import httpx
import asyncio
from datetime import datetime

BASE_URL = "http://localhost:8000/api/v1"

# Test users for the relationship management system
test_users = []
auth_tokens = {}


async def create_test_user(client: httpx.AsyncClient, username: str, email: str, password: str):
    """Create a test user and return their auth token"""
    unique_suffix = str(int(datetime.now().timestamp() * 1000))
    user_data = {
        "email": email,
        "password": password,
        "full_name": username,
        "username": f"{username.lower().replace(' ', '_')}_{unique_suffix}"
    }
    
    response = await client.post(f"{BASE_URL}/auth/register", json=user_data)
    assert response.status_code in [200, 201], f"User creation failed: {response.text}"
    
    register_data = response.json()
    token = register_data["access_token"]
    user_id = register_data["user"]["id"]
    
    return {"user_id": user_id, "token": token, "name": username}


@pytest.mark.asyncio
async def test_01_create_test_users():
    """Create test users for relationship management tests"""
    global test_users, auth_tokens
    
    async with httpx.AsyncClient() as client:
        # Create main user
        user1 = await create_test_user(
            client,
            "Alice Johnson",
            f"alice_rel_{datetime.now().timestamp()}@test.com",
            "password123"
        )
        test_users.append(user1)
        auth_tokens[user1["user_id"]] = user1["token"]
        
        # Create relationship connections
        user2 = await create_test_user(
            client,
            "Aman Jha",
            f"aman_rel_{datetime.now().timestamp()}@test.com",
            "password123"
        )
        test_users.append(user2)
        auth_tokens[user2["user_id"]] = user2["token"]
        
        user3 = await create_test_user(
            client,
            "Priya Sharma",
            f"priya_rel_{datetime.now().timestamp()}@test.com",
            "password123"
        )
        test_users.append(user3)
        auth_tokens[user3["user_id"]] = user3["token"]
        
        user4 = await create_test_user(
            client,
            "Rahul Singh",
            f"rahul_rel_{datetime.now().timestamp()}@test.com",
            "password123"
        )
        test_users.append(user4)
        auth_tokens[user4["user_id"]] = user4["token"]
    
    print(f"\n✅ Created {len(test_users)} test users for relationship management")
    for user in test_users:
        print(f"   - {user['name']} (ID: {user['user_id']})")


@pytest.mark.asyncio
async def test_02_create_custom_relationship_circles():
    """Test creating circles with custom relationship categories"""
    user = test_users[0]  # Alice
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        # Create a "Best Friend" circle
        circle_data = {
            "name": "My Best Friends",
            "description": "People I trust the most",
            "circle_type": "best_friend",
            "color": "#FF6B6B",
            "member_ids": [],
            "member_profiles": [
                {
                    "user_id": test_users[1]["user_id"],
                    "display_name": "Aman Jha",
                    "relationship_label": "Best Friend Since College",
                    "notes": "Met in 2018, always there for me"
                }
            ]
        }
        
        response = await client.post(
            f"{BASE_URL}/family/core/circles",
            json=circle_data,
            headers=headers
        )
        
        assert response.status_code in [200, 201], f"Failed to create circle: {response.text}"
        circle = response.json()["data"]
        
        assert circle["name"] == "My Best Friends"
        assert circle["circle_type"] == "best_friend"
        assert len(circle["member_profiles"]) == 1
        assert circle["member_profiles"][0]["display_name"] == "Aman Jha"
        assert circle["member_profiles"][0]["relationship_label"] == "Best Friend Since College"
        
        print(f"\n✅ Created 'Best Friend' circle: {circle['id']}")
        print(f"   - Members: {len(circle['member_profiles'])} person profiles")
        
        # Store for later tests
        test_users[0]["best_friend_circle_id"] = circle["id"]


@pytest.mark.asyncio
async def test_03_create_boyfriend_circle():
    """Test creating a boyfriend relationship circle"""
    user = test_users[0]  # Alice
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        circle_data = {
            "name": "My Boyfriend",
            "description": "Special someone",
            "circle_type": "boyfriend",
            "color": "#FF1493",
            "member_profiles": [
                {
                    "user_id": test_users[2]["user_id"],
                    "display_name": "Rahul Singh",
                    "relationship_label": "Boyfriend",
                    "notes": "Together since June 2024"
                }
            ]
        }
        
        response = await client.post(
            f"{BASE_URL}/family/core/circles",
            json=circle_data,
            headers=headers
        )
        
        assert response.status_code in [200, 201], f"Failed to create circle: {response.text}"
        circle = response.json()["data"]
        
        assert circle["circle_type"] == "boyfriend"
        assert circle["member_profiles"][0]["display_name"] == "Rahul Singh"
        
        print(f"\n✅ Created 'Boyfriend' circle: {circle['id']}")
        test_users[0]["boyfriend_circle_id"] = circle["id"]


@pytest.mark.asyncio
async def test_04_create_close_friends_circle():
    """Test creating a close friends circle with multiple people"""
    user = test_users[0]  # Alice
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        circle_data = {
            "name": "Close Friends",
            "description": "My inner circle",
            "circle_type": "close_friends",
            "color": "#4ECDC4",
            "member_profiles": [
                {
                    "user_id": test_users[1]["user_id"],
                    "display_name": "Aman Jha",
                    "relationship_label": "Close Friend",
                    "notes": "Always supportive"
                },
                {
                    "user_id": test_users[2]["user_id"],
                    "display_name": "Priya Sharma",
                    "relationship_label": "Close Friend",
                    "notes": "Known since school"
                }
            ]
        }
        
        response = await client.post(
            f"{BASE_URL}/family/core/circles",
            json=circle_data,
            headers=headers
        )
        
        assert response.status_code in [200, 201], f"Failed to create circle: {response.text}"
        circle = response.json()["data"]
        
        assert circle["circle_type"] == "close_friends"
        assert len(circle["member_profiles"]) == 2
        
        print(f"\n✅ Created 'Close Friends' circle with 2 people: {circle['id']}")
        test_users[0]["close_friends_circle_id"] = circle["id"]


@pytest.mark.asyncio
async def test_05_add_person_profile_to_circle():
    """Test adding a new person profile to an existing circle"""
    user = test_users[0]  # Alice
    circle_id = test_users[0]["close_friends_circle_id"]
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        profile_data = {
            "user_id": test_users[3]["user_id"],
            "display_name": "Rahul Singh",
            "relationship_label": "Close Friend",
            "notes": "Added recently, very cool person"
        }
        
        response = await client.post(
            f"{BASE_URL}/family/core/circles/{circle_id}/profiles",
            json=profile_data,
            headers=headers
        )
        
        assert response.status_code in [200, 201], f"Failed to add profile: {response.text}"
        print(f"\n✅ Added person profile to circle: Rahul Singh")


@pytest.mark.asyncio
async def test_06_update_person_profile():
    """Test updating a person profile within a circle"""
    user = test_users[0]  # Alice
    circle_id = test_users[0]["close_friends_circle_id"]
    profile_user_id = test_users[1]["user_id"]  # Aman
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        update_data = {
            "relationship_label": "Best Friend Forever",
            "notes": "Updated relationship - even closer now!"
        }
        
        response = await client.put(
            f"{BASE_URL}/family/core/circles/{circle_id}/profiles/{profile_user_id}",
            json=update_data,
            headers=headers
        )
        
        assert response.status_code == 200, f"Failed to update profile: {response.text}"
        print(f"\n✅ Updated person profile for Aman Jha")


@pytest.mark.asyncio
async def test_07_filter_circles_by_category():
    """Test filtering circles by relationship category"""
    user = test_users[0]  # Alice
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        # Get all "close_friends" circles
        response = await client.get(
            f"{BASE_URL}/family/core/circles/by-category/close_friends",
            headers=headers
        )
        
        assert response.status_code == 200, f"Failed to filter circles: {response.text}"
        circles = response.json()["data"]
        
        assert len(circles) >= 1
        for circle in circles:
            assert circle["circle_type"] == "close_friends"
        
        print(f"\n✅ Filtered circles by 'close_friends' category: found {len(circles)} circles")
        
        # Get all "boyfriend" circles
        response = await client.get(
            f"{BASE_URL}/family/core/circles/by-category/boyfriend",
            headers=headers
        )
        
        assert response.status_code == 200
        boyfriend_circles = response.json()["data"]
        
        assert len(boyfriend_circles) >= 1
        print(f"✅ Filtered circles by 'boyfriend' category: found {len(boyfriend_circles)} circles")


@pytest.mark.asyncio
async def test_08_list_all_circles():
    """Test listing all circles with person profiles"""
    user = test_users[0]  # Alice
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        response = await client.get(
            f"{BASE_URL}/family/core/circles",
            headers=headers
        )
        
        assert response.status_code == 200, f"Failed to list circles: {response.text}"
        result = response.json()
        circles = result["items"]
        
        assert len(circles) >= 3  # We created at least 3 circles
        
        print(f"\n✅ Listed all circles: {len(circles)} total")
        for circle in circles:
            print(f"   - {circle['name']} ({circle['circle_type']}): {len(circle['member_profiles'])} people")


@pytest.mark.asyncio
async def test_09_remove_person_profile():
    """Test removing a person profile from a circle"""
    user = test_users[0]  # Alice
    circle_id = test_users[0]["close_friends_circle_id"]
    profile_user_id = test_users[3]["user_id"]  # Rahul
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        response = await client.delete(
            f"{BASE_URL}/family/core/circles/{circle_id}/profiles/{profile_user_id}",
            headers=headers
        )
        
        assert response.status_code == 200, f"Failed to remove profile: {response.text}"
        print(f"\n✅ Removed person profile from circle: Rahul Singh")


@pytest.mark.asyncio
async def test_10_custom_category_circle():
    """Test creating a circle with a fully custom category"""
    user = test_users[0]  # Alice
    
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {user['token']}"}
        
        circle_data = {
            "name": "Gym Buddies",
            "description": "People I work out with",
            "circle_type": "custom",
            "custom_category": "gym_buddies",
            "color": "#95E1D3",
            "member_profiles": [
                {
                    "user_id": "custom_gym_friend",
                    "display_name": "Mike Chen",
                    "relationship_label": "Gym Partner",
                    "notes": "Morning workout buddy"
                }
            ]
        }
        
        response = await client.post(
            f"{BASE_URL}/family/core/circles",
            json=circle_data,
            headers=headers
        )
        
        assert response.status_code in [200, 201], f"Failed to create custom circle: {response.text}"
        circle = response.json()["data"]
        
        assert circle["circle_type"] == "custom"
        assert circle["custom_category"] == "gym_buddies"
        
        print(f"\n✅ Created custom category circle: 'Gym Buddies'")


if __name__ == "__main__":
    print("=" * 80)
    print("RELATIONSHIP MANAGEMENT SYSTEM - COMPREHENSIVE TEST SUITE")
    print("=" * 80)
    print("\nTesting enhanced relationship categories and person profiles...")
    print("- Custom relationship types (boyfriend, girlfriend, best friend, etc.)")
    print("- Person profile management within circles")
    print("- Filtering by relationship category")
    print("- Profile CRUD operations")
    print()
    
    pytest.main([__file__, "-v", "-s"])
