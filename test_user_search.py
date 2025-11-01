#!/usr/bin/env python3
"""
Test script to verify user search functionality works correctly
"""
import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

def test_user_search():
    print("=" * 60)
    print("Testing User Search Functionality")
    print("=" * 60)
    
    # Step 1: Register two test users
    print("\n1. Registering test users...")
    user1_data = {
        "email": "testuser1@example.com",
        "password": "TestPassword123!",
        "full_name": "Test User One",
        "username": "testuser1"
    }
    
    user2_data = {
        "email": "testuser2@example.com",
        "password": "TestPassword123!",
        "full_name": "Test User Two",
        "username": "testuser2"
    }
    
    # Register user 1
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=user1_data)
        if response.status_code == 201:
            print(f"   ✓ User 1 registered: {user1_data['email']}")
        elif response.status_code == 400 and "already registered" in response.text.lower():
            print(f"   ℹ User 1 already exists: {user1_data['email']}")
        else:
            print(f"   ✗ Failed to register user 1: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   ✗ Error registering user 1: {e}")
    
    # Register user 2
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=user2_data)
        if response.status_code == 201:
            print(f"   ✓ User 2 registered: {user2_data['email']}")
        elif response.status_code == 400 and "already registered" in response.text.lower():
            print(f"   ℹ User 2 already exists: {user2_data['email']}")
        else:
            print(f"   ✗ Failed to register user 2: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   ✗ Error registering user 2: {e}")
    
    # Step 2: Login as user 1
    print("\n2. Logging in as user 1...")
    login_data = {
        "email": user1_data["email"],
        "password": user1_data["password"]
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if response.status_code == 200:
            token_data = response.json()
            access_token = token_data.get("access_token")
            print(f"   ✓ Login successful")
            print(f"   Token (first 50 chars): {access_token[:50]}...")
        else:
            print(f"   ✗ Login failed: {response.status_code} - {response.text}")
            return
    except Exception as e:
        print(f"   ✗ Error during login: {e}")
        return
    
    headers = {"Authorization": f"Bearer {access_token}"}
    
    # Step 3: Test user search endpoint
    print("\n3. Testing user search endpoint...")
    
    # Test search with different queries
    test_queries = [
        ("test", "Search for 'test'"),
        ("User", "Search for 'User'"),
        ("two", "Search for 'two'"),
        ("@example", "Search for '@example'"),
    ]
    
    for query, description in test_queries:
        print(f"\n   {description}:")
        try:
            response = requests.get(
                f"{BASE_URL}/users/search",
                params={"query": query},
                headers=headers
            )
            print(f"   Status Code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"   Response Structure: {json.dumps(data, indent=6)[:500]}...")
                
                # Check if data follows expected structure
                if isinstance(data, dict):
                    if "data" in data and "results" in data["data"]:
                        results = data["data"]["results"]
                        print(f"   ✓ Found {len(results)} results in data.results")
                        for idx, result in enumerate(results[:3], 1):
                            print(f"      Result {idx}: {result.get('full_name', 'N/A')} ({result.get('email', 'N/A')})")
                    elif "results" in data:
                        results = data["results"]
                        print(f"   ✓ Found {len(results)} results in results")
                        for idx, result in enumerate(results[:3], 1):
                            print(f"      Result {idx}: {result.get('full_name', 'N/A')} ({result.get('email', 'N/A')})")
                    else:
                        print(f"   ⚠ Unexpected response structure: {list(data.keys())}")
                elif isinstance(data, list):
                    print(f"   ✓ Found {len(data)} results (direct list)")
                    for idx, result in enumerate(data[:3], 1):
                        print(f"      Result {idx}: {result.get('full_name', 'N/A')} ({result.get('email', 'N/A')})")
            else:
                print(f"   ✗ Request failed: {response.text[:200]}")
        except Exception as e:
            print(f"   ✗ Error during search: {e}")
    
    # Step 4: Test search-family-circle endpoint
    print("\n4. Testing search-family-circle endpoint...")
    try:
        response = requests.get(
            f"{BASE_URL}/users/search-family-circle",
            params={"query": "test"},
            headers=headers
        )
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   Response: {json.dumps(data, indent=4)[:500]}...")
        else:
            print(f"   ✗ Request failed: {response.text[:200]}")
    except Exception as e:
        print(f"   ✗ Error: {e}")
    
    print("\n" + "=" * 60)
    print("Test Complete")
    print("=" * 60)

if __name__ == "__main__":
    test_user_search()
