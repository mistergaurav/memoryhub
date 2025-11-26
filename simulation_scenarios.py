import requests
import json
import time
import sys

BASE_URL = "http://localhost:8000/api/v1"

def print_step(msg):
    print(f"\n{'='*50}\n{msg}\n{'='*50}")

def register_user(username, email, password, full_name):
    url = f"{BASE_URL}/auth/register"
    data = {
        "username": username,
        "email": email,
        "password": password,
        "full_name": full_name
    }
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"Registered {username}")
            return response.json()
        elif response.status_code == 400 and "already exists" in response.text:
            print(f"User {username} already exists, logging in...")
            return login_user(username, password)
        else:
            print(f"Failed to register {username}: {response.text}")
            return None
    except Exception as e:
        print(f"Error registering {username}: {e}")
        return None

def wait_for_server(timeout=60):
    start_time = time.time()
    print("Waiting for server to be ready...")
    while time.time() - start_time < timeout:
        try:
            # Try to hit the docs endpoint or root
            response = requests.get(f"{BASE_URL.replace('/api/v1', '')}/docs")
            if response.status_code == 200:
                print("Server is ready!")
                return True
        except requests.exceptions.ConnectionError:
            pass
        time.sleep(1)
    print("Server timed out.")
    return False

def login_user(email, password):
    url = f"{BASE_URL}/auth/token"
    data = {
        "email": email,
        "password": password
    }
    try:
        response = requests.post(url, json=data) # Endpoint expects JSON LoginRequest
        if response.status_code == 200:
            print(f"Logged in {email}")
            return response.json()
        else:
            print(f"Failed to login {email}: {response.text}")
            return None
    except Exception as e:
        print(f"Error logging in {email}: {e}")
        return None

def add_person(token, first_name, last_name, gender, relationships=None, linked_user_id=None, pending_invite_email=None):
    url = f"{BASE_URL}/family/genealogy/persons"
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "first_name": first_name,
        "last_name": last_name,
        "gender": gender,
        "is_alive": True,
        "source": "manual",
        "relationships": relationships or [],
        "linked_user_id": linked_user_id,
        "pending_invite_email": pending_invite_email
    }
    
    # Remove None values
    data = {k: v for k, v in data.items() if v is not None}
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code in [200, 201]:
            print(f"Added person {first_name} {last_name}")
            return response.json()["data"]
        elif response.status_code == 400 and "already linked" in response.text:
            print(f"Person {first_name} {last_name} already exists/linked. Ignoring.")
            return {"id": "dummy_id_for_simulation"} # We might need real ID, but for now just don't crash
        else:
            print(f"Failed to add person {first_name} {last_name}: {response.text}")
            return None
    except Exception as e:
        print(f"Error adding person: {e}")
        return None

def approve_person(token, person_id):
    url = f"{BASE_URL}/family/genealogy/persons/{person_id}/approve"
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.post(url, headers=headers)
        if response.status_code == 200:
            print(f"Approved person {person_id}")
            return response.json()["data"]
        else:
            print(f"Failed to approve person {person_id}: {response.text}")
            return None
    except Exception as e:
        print(f"Error approving person: {e}")
        return None

def get_tree(token, tree_id):
    url = f"{BASE_URL}/family/genealogy/tree/{tree_id}"
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()["data"]
        else:
            print(f"Failed to get tree {tree_id}: {response.text}")
            return {}
    except Exception as e:
        print(f"Error getting tree: {e}")
        return {}

def run_simulation():
    print_step("Starting Genealogy Simulation")
    
    if not wait_for_server():
        return

    # 1. Create 5 Users
    users = {}
    import random
    import string
    suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    
    user_creds = [
        (f"user_a_{suffix}", f"usera_{suffix}@example.com", "password123", "User A"),
        (f"user_b_{suffix}", f"userb_{suffix}@example.com", "password123", "User B"),
        (f"user_c_{suffix}", f"userc_{suffix}@example.com", "password123", "User C"),
        (f"user_d_{suffix}", f"userd_{suffix}@example.com", "password123", "User D"),
        (f"user_e_{suffix}", f"usere_{suffix}@example.com", "password123", "User E"),
    ]
    
    for uname, email, pwd, fname in user_creds:
        reg = register_user(uname, email, pwd, fname)
        if reg or True: # Proceed even if registration fails (might exist)
            # If registered, we might need to login to get token if register doesn't return it
            # Assuming register returns user info but not token, or maybe it does.
            # Let's explicitly login to be safe.
            token_data = login_user(email, pwd)
            if token_data:
                # We need the user ID. Login usually returns access_token.
                # We can get user info from /users/me
                headers = {"Authorization": f"Bearer {token_data['access_token']}"}
                me_res = requests.get(f"{BASE_URL}/users/me", headers=headers)
                if me_res.status_code == 200:
                    user_id = me_res.json()["id"]
                    users[uname] = {
                        "id": user_id,
                        "token": token_data["access_token"],
                        "name": fname
                    }
                else:
                    print(f"Could not get user info for {uname}")

    if len(users) < 5:
        print("Failed to create/login all users. Aborting.")
        return

    print(f"Users created: {list(users.keys())}")

    # Resolve users
    user_a_key = next(k for k in users if k.startswith("user_a"))
    user_b_key = next(k for k in users if k.startswith("user_b"))
    user_c_key = next(k for k in users if k.startswith("user_c"))
    user_d_key = next(k for k in users if k.startswith("user_d"))
    user_e_key = next(k for k in users if k.startswith("user_e"))
    
    user_a = users[user_a_key]
    user_b = users[user_b_key]
    user_c = users[user_c_key]
    user_d = users[user_d_key]
    user_e = users[user_e_key]

    # Helper to get "Self" person ID
    def get_self_person_id(user_data):
        u = user_data
        # Search for person linked to this user in their own tree
        # We can search by name or just list all and find linked_user_id
        url = f"{BASE_URL}/family/genealogy/persons"
        headers = {"Authorization": f"Bearer {u['token']}"}
        res = requests.get(url, headers=headers)
        if res.status_code == 200:
            persons = res.json()["items"]
            for p in persons:
                if p.get("linked_user_id") == u["id"]:
                    return p["id"]
        # If not found, create "Me"
        print(f"Creating 'Self' person for {u['name']}")
        data = {
            "first_name": u["name"].split()[0],
            "last_name": u["name"].split()[1] if len(u["name"].split()) > 1 else "Self",
            "gender": "male", # Assumption
            "is_alive": True,
            "source": "platform_user",
            "linked_user_id": u["id"]
        }
        res = requests.post(url, json=data, headers=headers)
        if res.status_code in [200, 201]:
            return res.json()["data"]["id"]
        return None

    # Scenario 1: User A adds User B as Father (Biological)
    print_step("Scenario 1: User A adds User B as Father (Biological)")
    
    user_a_person_id = get_self_person_id(user_a)
    print(f"User A Person ID: {user_a_person_id}")
    
    if not user_a_person_id:
        print("Failed to get User A person ID")
        return

    # Now A adds B as Father
    # Relationship: B is PARENT of A
    relationships = [{
        "person_id": user_a_person_id, # Relative is A
        "relationship_type": "parent", # B is PARENT of A
        "is_biological": True
    }]
    
    b_person_in_a_tree = add_person(
        user_a["token"], 
        "User", "B", "male", 
        relationships=relationships,
        linked_user_id=user_b["id"],
        pending_invite_email=f"userb_{user_b_key.split('_')[-1]}@example.com"
    )
    
    if b_person_in_a_tree:
        print("User A added User B request sent.")
        
        print_step("User B approves the request")
        approve_res = approve_person(user_b["token"], b_person_in_a_tree["id"])
        
        if approve_res:
            print("User B approved.")
            # Verify Tree Merge
            print("Verifying User B's tree...")
            b_tree = get_tree(user_b["token"], user_b["id"])
            # Check for A
            found_a = False
            for node in b_tree.get("nodes", []):
                p = node["person"]
                if p.get("linked_user_id") == user_a["id"]:
                    print(f"Found User A in User B's tree: {p['first_name']}")
                    found_a = True
                    break
            if found_a:
                print("SUCCESS: Bidirectional link created.")
            else:
                print("FAILURE: User A not found in User B's tree.")

        # Verify Notifications for User B
        print_step("Verifying Notifications for User B")
        notif_url = f"{BASE_URL}/social/notifications?page=1&limit=20"
        headers = {"Authorization": f"Bearer {user_b['token']}"}
        try:
            res = requests.get(notif_url, headers=headers)
            if res.status_code == 200:
                print("SUCCESS: Fetched notifications.")
                items = res.json().get("data", {}).get("notifications", [])
                print(f"Found {len(items)} notifications.")
                for item in items:
                    print(f"- {item.get('type')}: {item.get('title')}")
            else:
                print(f"FAILURE: Failed to fetch notifications: {res.status_code} {res.text}")
        except Exception as e:
            print(f"FAILURE: Error fetching notifications: {e}")

    # Scenario 2: User B adds User C as Father (Biological)
    print_step("Scenario 2: User B adds User C as Father (Biological)")
    
    user_b_person_id = get_self_person_id(user_b) # Should exist now
    
    relationships_bc = [{
        "person_id": user_b_person_id,
        "relationship_type": "parent",
        "is_biological": True
    }]
    
    c_person_in_b_tree = add_person(
        user_b["token"],
        "User", "C", "male",
        relationships=relationships_bc,
        linked_user_id=user_c["id"],
        pending_invite_email=f"userc_{user_c_key.split('_')[-1]}@example.com"
    )
    
    if c_person_in_b_tree:
        print("User B added User C request sent.")
        print("User C approves...")
        approve_person(user_c["token"], c_person_in_b_tree["id"])
        
        # Verify Tree Merge Propagation
        print("Verifying User A's tree for User C (Grandfather)...")
        a_tree = get_tree(user_a["token"], user_a["id"])
        found_c = False
        for node in a_tree.get("nodes", []):
            p = node["person"]
            if p.get("linked_user_id") == user_c["id"]:
                print(f"Found User C in User A's tree: {p['first_name']}")
                found_c = True
                break
        
        if found_c:
            print("SUCCESS: Tree merge propagated to User A.")
        else:
            print("FAILURE: User C not found in User A's tree.")

    # Scenario 3: User A adds User D as Step-Mother
    print_step("Scenario 3: User A adds User D as Step-Mother")
    
    relationships_ad = [{
        "person_id": user_a_person_id,
        "relationship_type": "step_parent",
        "is_biological": False
    }]
    
    d_person_in_a_tree = add_person(
        user_a["token"],
        "User", "D", "female",
        relationships=relationships_ad,
        linked_user_id=user_d["id"],
        pending_invite_email=f"userd_{user_d_key.split('_')[-1]}@example.com"
    )
    
    if d_person_in_a_tree:
        print("User A added User D (Step-Mother).")
        print("SUCCESS: Step-parent added.")

    # Scenario 4: User E adds User A as Spouse
    print_step("Scenario 4: User E adds User A as Spouse")
    
    user_e_person_id = get_self_person_id(user_e)
    
    relationships_ea = [{
        "person_id": user_e_person_id,
        "relationship_type": "spouse",
        "is_biological": False # Spouses are not biological
    }]
    
    a_person_in_e_tree = add_person(
        user_e["token"],
        "User", "A", "male",
        relationships=relationships_ea,
        linked_user_id=user_a["id"],
        pending_invite_email=f"usera_{user_a_key.split('_')[-1]}@example.com"
    )
    
    if a_person_in_e_tree:
        print("User E added User A (Spouse).")
        print("User A approves...")
        approve_person(user_a["token"], a_person_in_e_tree["id"])
        
        # Verify Bidirectional
        print("Verifying User A's tree for User E (Spouse)...")
        a_tree_2 = get_tree(user_a["token"], user_a["id"])
        found_e = False
        for node in a_tree_2.get("nodes", []):
            p = node["person"]
            if p.get("linked_user_id") == user_e["id"]:
                print(f"Found User E in User A's tree: {p['first_name']}")
                found_e = True
                break
        
        if found_e:
            print("SUCCESS: Spouse link verified.")
        else:
            print("FAILURE: User E not found in User A's tree.")

if __name__ == "__main__":
    run_simulation()
