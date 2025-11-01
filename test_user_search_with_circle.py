#!/usr/bin/env python3
"""
Test user search with family circle relationships
"""
import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

def test_search_with_circles():
    print("=" * 70)
    print("Testing User Search with Family Circle Relationships")
    print("=" * 70)
    
    # Step 1: Create and login two users
    users = [
        {
            "email": "alice@search-test.com",
            "password": "TestPassword123!",
            "full_name": "Alice Johnson",
            "username": "alice_search"
        },
        {
            "email": "bob@search-test.com",
            "password": "TestPassword123!",
            "full_name": "Bob Smith",
            "username": "bob_search"
        }
    ]
    
    tokens = {}
    
    for user in users:
        # Register
        print(f"\nRegistering {user['full_name']}...")
        try:
            resp = requests.post(f"{BASE_URL}/auth/register", json=user)
            if resp.status_code in [201, 400]:
                print(f"  ✓ Registered/Exists")
            else:
                print(f"  ✗ Failed: {resp.text[:100]}")
                continue
        except Exception as e:
            print(f"  ✗ Error: {e}")
            continue
        
        # Login
        print(f"Logging in {user['full_name']}...")
        try:
            resp = requests.post(f"{BASE_URL}/auth/login", json={
                "email": user["email"],
                "password": user["password"]
            })
            if resp.status_code == 200:
                tokens[user["email"]] = resp.json()["access_token"]
                print(f"  ✓ Logged in")
            else:
                print(f"  ✗ Failed: {resp.text[:100]}")
        except Exception as e:
            print(f"  ✗ Error: {e}")
    
    if len(tokens) < 2:
        print("\n⚠ Cannot proceed - need at least 2 users logged in")
        return
    
    alice_token = tokens["alice@search-test.com"]
    bob_token = tokens["bob@search-test.com"]
    
    alice_headers = {"Authorization": f"Bearer {alice_token}"}
    bob_headers = {"Authorization": f"Bearer {bob_token}"}
    
    # Step 2: Create a family circle
    print("\n" + "=" * 70)
    print("Creating Family Circle")
    print("=" * 70)
    
    circle_data = {
        "name": "Search Test Circle",
        "description": "Circle for testing user search",
        "privacy": "private"
    }
    
    print(f"\nCreating circle as Alice...")
    try:
        resp = requests.post(
            f"{BASE_URL}/family/circles",
            json=circle_data,
            headers=alice_headers
        )
        if resp.status_code in [200, 201]:
            circle_id = resp.json().get("data", {}).get("id") or resp.json().get("id")
            print(f"  ✓ Circle created: {circle_id}")
        else:
            print(f"  ⚠ Status {resp.status_code}: {resp.text[:200]}")
            # Try alternate endpoint
            resp2 = requests.post(
                f"{BASE_URL}/family/",
                json={"name": circle_data["name"]},
                headers=alice_headers
            )
            if resp2.status_code in [200, 201]:
                circle_id = resp2.json().get("data", {}).get("id") or resp2.json().get("id")
                print(f"  ✓ Circle created (alternate): {circle_id}")
            else:
                print(f"  ✗ Both endpoints failed")
                circle_id = None
    except Exception as e:
        print(f"  ✗ Error: {e}")
        circle_id = None
    
    # Step 3: Test search BEFORE adding Bob
    print("\n" + "=" * 70)
    print("Testing Search BEFORE Bob joins circle")
    print("=" * 70)
    
    print("\nAlice searching for 'Bob'...")
    try:
        resp = requests.get(
            f"{BASE_URL}/users/search",
            params={"query": "Bob"},
            headers=alice_headers
        )
        if resp.status_code == 200:
            data = resp.json()
            results = data.get("data", {}).get("results", [])
            print(f"  Results found: {len(results)}")
            if len(results) == 0:
                print(f"  ✓ Correct: No results (Bob not in circle yet)")
            else:
                print(f"  ⚠ Unexpected: Found {len(results)} results")
                for r in results:
                    print(f"    - {r.get('full_name')}")
        else:
            print(f"  ✗ Search failed: {resp.status_code}")
    except Exception as e:
        print(f"  ✗ Error: {e}")
    
    # Step 4: Add Bob to circle (if circle was created)
    if circle_id:
        print("\n" + "=" * 70)
        print("Adding Bob to Circle")
        print("=" * 70)
        
        # Get Bob's user ID
        print("\nGetting Bob's profile...")
        try:
            resp = requests.get(f"{BASE_URL}/users/me", headers=bob_headers)
            if resp.status_code == 200:
                bob_user_id = resp.json().get("id") or resp.json().get("data", {}).get("id")
                print(f"  ✓ Bob's user ID: {bob_user_id}")
                
                # Add Bob to circle
                print(f"\nAdding Bob to circle {circle_id}...")
                invite_data = {
                    "user_id": bob_user_id,
                    "role": "member"
                }
                
                resp = requests.post(
                    f"{BASE_URL}/family/circles/{circle_id}/members",
                    json=invite_data,
                    headers=alice_headers
                )
                if resp.status_code in [200, 201]:
                    print(f"  ✓ Bob added to circle")
                else:
                    print(f"  ⚠ Status {resp.status_code}: {resp.text[:200]}")
            else:
                print(f"  ✗ Failed to get Bob's profile: {resp.text[:100]}")
        except Exception as e:
            print(f"  ✗ Error: {e}")
    
    # Step 5: Test search AFTER adding Bob
    print("\n" + "=" * 70)
    print("Testing Search AFTER Bob is in circle")
    print("=" * 70)
    
    print("\nAlice searching for 'Bob'...")
    try:
        resp = requests.get(
            f"{BASE_URL}/users/search",
            params={"query": "Bob"},
            headers=alice_headers
        )
        if resp.status_code == 200:
            data = resp.json()
            results = data.get("data", {}).get("results", [])
            print(f"  Results found: {len(results)}")
            if len(results) > 0:
                print(f"  ✓ Success: Found Bob!")
                for r in results:
                    print(f"    - {r.get('full_name')} ({r.get('email')})")
                    print(f"      Relation: {r.get('relation_type')}, Source: {r.get('source')}")
            else:
                print(f"  ⚠ No results found (circle membership may need time)")
                print(f"  Response: {json.dumps(data, indent=2)}")
        else:
            print(f"  ✗ Search failed: {resp.status_code}")
    except Exception as e:
        print(f"  ✗ Error: {e}")
    
    # Try different search terms
    print("\nTrying different search terms...")
    for query in ["smith", "bob@", "alice"]:
        print(f"\n  Searching for '{query}'...")
        try:
            resp = requests.get(
                f"{BASE_URL}/users/search",
                params={"query": query},
                headers=alice_headers
            )
            if resp.status_code == 200:
                results = resp.json().get("data", {}).get("results", [])
                print(f"    Found {len(results)} results")
                for r in results[:2]:
                    print(f"      - {r.get('full_name')}")
        except Exception as e:
            print(f"    Error: {e}")
    
    print("\n" + "=" * 70)
    print("Test Complete")
    print("=" * 70)
    print("\n💡 KEY INSIGHT:")
    print("   User search only returns users in your family circles.")
    print("   This is a security feature to prevent user enumeration.")
    print("   Users must create/join family circles to search each other.")
    print("=" * 70)

if __name__ == "__main__":
    test_search_with_circles()
