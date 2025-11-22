import requests
import json

BASE_URL = "http://127.0.0.1:8000/api/v1"
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJrdW1hckBhYmMuY29tIiwiZXhwIjoxNzY0MjkxNjc1LCJ0eXBlIjoiYWNjZXNzIn0.nGdWkGVuJPGdRj9VBh6TJwcjUrL96d44-4PdXOpxeGc"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

def test_get_settings():
    print("Testing GET /notifications/settings...")
    try:
        response = requests.get(f"{BASE_URL}/notifications/settings", headers=headers)
        if response.status_code == 200:
            print("SUCCESS: Retrieved settings")
            print(json.dumps(response.json(), indent=2))
        else:
            print(f"FAILURE: Status {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"ERROR: {e}")

def test_update_settings():
    print("\nTesting PUT /notifications/settings...")
    try:
        new_settings = {"email_notifications": False, "push_notifications": True}
        response = requests.put(f"{BASE_URL}/notifications/settings", headers=headers, json=new_settings)
        if response.status_code == 200:
            print("SUCCESS: Updated settings")
            print(json.dumps(response.json(), indent=2))
        else:
            print(f"FAILURE: Status {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_get_settings()
    test_update_settings()
