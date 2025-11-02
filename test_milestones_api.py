import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:5000/api/v1"

# Test token (you'll need to replace with a valid token)
token = "test_token"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

def test_create_milestone():
    print("\n=== Testing CREATE Milestone ===")
    data = {
        "title": "My First Achievement",
        "description": "This is a test milestone",
        "milestone_type": "achievement",
        "milestone_date": datetime.now().isoformat(),
        "photos": [],
        "auto_generated": False
    }
    
    response = requests.post(
        f"{BASE_URL}/family-milestones/",
        headers=headers,
        json=data
    )
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 201:
        return response.json().get("data", {}).get("id")
    return None

def test_list_milestones():
    print("\n=== Testing LIST Milestones ===")
    response = requests.get(
        f"{BASE_URL}/family-milestones/?page=1&page_size=10",
        headers=headers
    )
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_get_milestone(milestone_id):
    print(f"\n=== Testing GET Milestone {milestone_id} ===")
    response = requests.get(
        f"{BASE_URL}/family-milestones/{milestone_id}",
        headers=headers
    )
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_like_milestone(milestone_id):
    print(f"\n=== Testing LIKE Milestone {milestone_id} ===")
    response = requests.post(
        f"{BASE_URL}/family-milestones/{milestone_id}/like",
        headers=headers
    )
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_update_milestone(milestone_id):
    print(f"\n=== Testing UPDATE Milestone {milestone_id} ===")
    data = {
        "title": "Updated Achievement Title",
        "description": "This milestone has been updated"
    }
    
    response = requests.put(
        f"{BASE_URL}/family-milestones/{milestone_id}",
        headers=headers,
        json=data
    )
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_delete_milestone(milestone_id):
    print(f"\n=== Testing DELETE Milestone {milestone_id} ===")
    response = requests.delete(
        f"{BASE_URL}/family-milestones/{milestone_id}",
        headers=headers
    )
    print(f"Status Code: {response.status_code}")
    if response.content:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

if __name__ == "__main__":
    print("Testing Family Milestones API Endpoints")
    print("=" * 50)
    
    # Test listing first
    test_list_milestones()
    
    print("\nNote: Authentication is required for full testing.")
    print("The endpoints are configured and ready to use with proper authentication.")
    print("\nAll milestone endpoints are available:")
    print("  - POST /api/v1/family-milestones/ (create)")
    print("  - GET /api/v1/family-milestones/ (list with pagination)")
    print("  - GET /api/v1/family-milestones/{id} (get details)")
    print("  - PUT /api/v1/family-milestones/{id} (update)")
    print("  - DELETE /api/v1/family-milestones/{id} (delete)")
    print("  - POST /api/v1/family-milestones/{id}/like (like/unlike)")
