#!/usr/bin/env python3
"""
Test script for Family Calendar endpoints
Verifies all calendar API endpoints are working correctly
"""

import requests
import json
from datetime import datetime, timedelta

BASE_URL = "http://localhost:5000/api/v1"
TOKEN = "test_token"  # Replace with actual token

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

def test_create_event():
    """Test POST /family-calendar/events"""
    print("\n1. Testing CREATE event...")
    event_data = {
        "title": "Family Dinner",
        "description": "Monthly family dinner gathering",
        "event_type": "gathering",
        "event_date": (datetime.now() + timedelta(days=7)).isoformat(),
        "end_date": None,
        "location": "Home",
        "recurrence": "monthly",
        "family_circle_ids": [],
        "attendee_ids": [],
        "reminder_minutes": 60,
        "auto_generated": False
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/family-calendar/events",
            headers=headers,
            json=event_data
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 201:
            result = response.json()
            event_id = result.get('data', {}).get('event', {}).get('id')
            print(f"   ✓ Event created successfully! ID: {event_id}")
            return event_id
        else:
            print(f"   ✗ Failed: {response.text}")
            return None
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return None

def test_list_events():
    """Test GET /family-calendar/events"""
    print("\n2. Testing LIST events...")
    start_date = datetime.now().replace(day=1)
    end_date = (start_date + timedelta(days=31)).replace(day=1)
    
    try:
        response = requests.get(
            f"{BASE_URL}/family-calendar/events",
            headers=headers,
            params={
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat()
            }
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            count = len(result.get('items', []))
            print(f"   ✓ Found {count} events")
            return True
        else:
            print(f"   ✗ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False

def test_get_event(event_id):
    """Test GET /family-calendar/events/{id}"""
    print("\n3. Testing GET event details...")
    if not event_id:
        print("   ⊘ Skipped (no event ID)")
        return False
    
    try:
        response = requests.get(
            f"{BASE_URL}/family-calendar/events/{event_id}",
            headers=headers
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            title = result.get('data', {}).get('title', 'Unknown')
            print(f"   ✓ Event retrieved: {title}")
            return True
        else:
            print(f"   ✗ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False

def test_update_event(event_id):
    """Test PUT /family-calendar/events/{id}"""
    print("\n4. Testing UPDATE event...")
    if not event_id:
        print("   ⊘ Skipped (no event ID)")
        return False
    
    update_data = {
        "title": "Updated Family Dinner",
        "description": "Updated description",
        "location": "Restaurant"
    }
    
    try:
        response = requests.put(
            f"{BASE_URL}/family-calendar/events/{event_id}",
            headers=headers,
            json=update_data
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            print("   ✓ Event updated successfully")
            return True
        else:
            print(f"   ✗ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False

def test_get_birthdays():
    """Test GET /family-calendar/birthdays"""
    print("\n5. Testing GET upcoming birthdays...")
    try:
        response = requests.get(
            f"{BASE_URL}/family-calendar/birthdays",
            headers=headers,
            params={"days_ahead": 30}
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            count = len(result.get('data', []))
            print(f"   ✓ Found {count} upcoming birthdays")
            return True
        else:
            print(f"   ✗ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False

def test_detect_conflicts(event_id):
    """Test POST /family-calendar/events/{id}/conflicts"""
    print("\n6. Testing conflict detection...")
    if not event_id:
        print("   ⊘ Skipped (no event ID)")
        return False
    
    try:
        response = requests.post(
            f"{BASE_URL}/family-calendar/events/{event_id}/conflicts",
            headers=headers
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            count = result.get('data', {}).get('count', 0)
            print(f"   ✓ Found {count} conflicting events")
            return True
        else:
            print(f"   ✗ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False

def test_delete_event(event_id):
    """Test DELETE /family-calendar/events/{id}"""
    print("\n7. Testing DELETE event...")
    if not event_id:
        print("   ⊘ Skipped (no event ID)")
        return False
    
    try:
        response = requests.delete(
            f"{BASE_URL}/family-calendar/events/{event_id}",
            headers=headers
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            print("   ✓ Event deleted successfully")
            return True
        else:
            print(f"   ✗ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ✗ Error: {e}")
        return False

def main():
    print("=" * 50)
    print("FAMILY CALENDAR API ENDPOINT TESTS")
    print("=" * 50)
    
    # Run tests in sequence
    event_id = test_create_event()
    test_list_events()
    test_get_event(event_id)
    test_update_event(event_id)
    test_get_birthdays()
    test_detect_conflicts(event_id)
    test_delete_event(event_id)
    
    print("\n" + "=" * 50)
    print("TESTS COMPLETED")
    print("=" * 50)
    print("\nNote: Replace TOKEN with a valid authentication token to run tests")

if __name__ == "__main__":
    main()
