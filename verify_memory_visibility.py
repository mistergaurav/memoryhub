import requests
import json
import time

BASE_URL = "http://localhost:8000/api/v1"

def register_user(email, password, name):
    # Try login first
    response = requests.post(f"{BASE_URL}/auth/token", json={"email": email, "password": password})
    if response.status_code == 200:
        return response.json()["access_token"], get_user_id(response.json()["access_token"])
    
    # Register
    response = requests.post(f"{BASE_URL}/auth/register", json={
        "email": email,
        "password": password,
        "full_name": name
    })
    if response.status_code == 201:
        return response.json()["access_token"], response.json()["user"]["id"]
    else:
        print(f"Failed to register {email}: {response.text}")
        return None, None

def get_user_id(token):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/users/me", headers=headers)
    return response.json()["id"]

def create_memory(token, title, privacy, allowed_users=[]):
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "title": title,
        "content": f"Content for {title}",
        "privacy": privacy,
        "allowed_user_ids": json.dumps(allowed_users)
    }
    response = requests.post(f"{BASE_URL}/memories/", data=data, headers=headers)
    if response.status_code in [200, 201]:
        print(f"Created memory '{title}' ({privacy})")
        data = response.json()
        return data.get("id") or data.get("_id")
    else:
        print(f"Failed to create memory '{title}': {response.text}")
        return None

def get_feed(token):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/activity", headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Failed to get feed: {response.text}")
        return []

def make_friends(token1, token2, user2_id):
    headers1 = {"Authorization": f"Bearer {token1}"}
    headers2 = {"Authorization": f"Bearer {token2}"}
    
    # User 1 invites User 2
    print("User 1 inviting User 2...")
    response = requests.post(f"{BASE_URL}/family/relationships/invite", json={
        "related_user_id": user2_id,
        "relationship_type": "friend"
    }, headers=headers1)
    
    if response.status_code not in [200, 201]:
        print(f"Invite failed: {response.text}")
        # Check if already friends or pending
        return

    # User 2 accepts
    print("User 2 checking requests...")
    response = requests.get(f"{BASE_URL}/family/relationships/pending", headers=headers2)
    requests_list = response.json().get("items", [])
    
    for req in requests_list:
        if req["user_id"] != user2_id: # The sender ID is in user_id field of the relationship object? No, usually 'user' or 'related_user'
            # Assuming the request object has the ID
            req_id = req["id"]
            print(f"Accepting request {req_id}...")
            requests.put(f"{BASE_URL}/family/relationships/{req_id}/accept", headers=headers2)

def main():
    print("--- Starting Verification ---")
    
    # 1. Create Users
    owner_token, owner_id = register_user("owner@test.com", "password123", "Owner User")
    friend_token, friend_id = register_user("friend@test.com", "password123", "Friend User")
    stranger_token, stranger_id = register_user("stranger@test.com", "password123", "Stranger User")
    
    if not all([owner_token, friend_token, stranger_token]):
        print("Failed to create users. Exiting.")
        return

    # 2. Make Friends
    make_friends(owner_token, friend_token, friend_id)
    
    # 3. Create Memories
    print("\n--- Creating Memories ---")
    create_memory(owner_token, "Public Memory", "public")
    create_memory(owner_token, "Private Memory", "private")
    create_memory(owner_token, "Friends Memory", "friends")
    create_memory(owner_token, "Specific Memory", "specific_users", [friend_id])
    
    # 4. Verify Friend's Feed
    print("\n--- Verifying Friend's Feed ---")
    feed = get_feed(friend_token)
    titles = [item["title"] for item in feed if item.get("type") == "memory" or "title" in item] # Adjust based on feed structure
    # Feed items might wrap memory. Let's assume simple list or check structure.
    # Actually get_activity returns mixed types.
    
    # Helper to extract titles from feed
    def extract_titles(feed_data):
        t = []
        items = feed_data.get("items", []) if isinstance(feed_data, dict) else feed_data
        for item in items:
            if "title" in item:
                t.append(item["title"])
            elif "data" in item and "title" in item["data"]:
                 t.append(item["data"]["title"])
        return t

    friend_titles = extract_titles(feed)
    print(f"Friend sees: {friend_titles}")
    
    assert "Public Memory" in friend_titles, "Friend should see Public Memory"
    assert "Private Memory" not in friend_titles, "Friend should NOT see Private Memory"
    assert "Friends Memory" in friend_titles, "Friend should see Friends Memory"
    assert "Specific Memory" in friend_titles, "Friend should see Specific Memory"
    
    # 5. Verify Stranger's Feed
    print("\n--- Verifying Stranger's Feed ---")
    feed = get_feed(stranger_token)
    stranger_titles = extract_titles(feed)
    print(f"Stranger sees: {stranger_titles}")
    
    assert "Public Memory" in stranger_titles, "Stranger should see Public Memory"
    assert "Private Memory" not in stranger_titles, "Stranger should NOT see Private Memory"
    assert "Friends Memory" not in stranger_titles, "Stranger should NOT see Friends Memory"
    assert "Specific Memory" not in stranger_titles, "Stranger should NOT see Specific Memory"

    print("\n--- Verification Successful! ---")

if __name__ == "__main__":
    main()
