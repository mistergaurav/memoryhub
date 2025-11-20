#!/usr/bin/env python3
"""
Comprehensive Family Features Test Script
Tests ALL family endpoints systematically with bug detection and reporting
"""

import requests
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
import sys

# Correct port for this environment
BASE_URL = "http://localhost:5000/api/v1"

# Test configuration
TEST_USER = {
    "email": f"family_test_{datetime.now().timestamp()}@example.com",
    "password": "SecureTestPass123!@#",
    "full_name": "Family Features Test User"
}

# Colors for output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    MAGENTA = '\033[95m'
    END = '\033[0m'
    BOLD = '\033[1m'

# Test results tracking
test_results = {
    "total": 0,
    "passed": 0,
    "failed": 0,
    "bugs_found": []
}

def print_header(text):
    """Print a formatted header"""
    print(f"\n{Colors.CYAN}{Colors.BOLD}{'='*70}{Colors.END}")
    print(f"{Colors.CYAN}{Colors.BOLD}{text.center(70)}{Colors.END}")
    print(f"{Colors.CYAN}{Colors.BOLD}{'='*70}{Colors.END}")

def print_test(name, passed, details="", bug_details=None):
    """Print test result and track statistics"""
    global test_results
    test_results["total"] += 1
    
    if passed:
        test_results["passed"] += 1
        status = f"{Colors.GREEN}[PASS]{Colors.END}"
    else:
        test_results["failed"] += 1
        status = f"{Colors.RED}[FAIL]{Colors.END}"
        if bug_details:
            test_results["bugs_found"].append({
                "test": name,
                "details": details,
                "bug": bug_details
            })
    
    print(f"{status} - {name}")
    if details:
        print(f"  {Colors.YELLOW}{details}{Colors.END}")

def make_request(method: str, endpoint: str, headers: Dict = None, json_data: Dict = None, 
                 params: Dict = None, expected_status: int = 200) -> Optional[Dict]:
    """Make HTTP request and validate response"""
    try:
        url = f"{BASE_URL}{endpoint}"
        
        if method == "GET":
            response = requests.get(url, headers=headers, params=params)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=json_data)
        elif method == "PUT":
            response = requests.put(url, headers=headers, json=json_data)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers)
        else:
            return None
        
        if response.status_code != expected_status:
            return {"error": True, "status_code": response.status_code, "expected": expected_status, "response": response.text}
        
        try:
            return response.json()
        except:
            return {"status_code": response.status_code}
            
    except Exception as e:
        return {"error": True, "exception": str(e)}

# ==================== AUTHENTICATION ====================

def test_authentication():
    """Test user registration and login"""
    print_header("Step 1: Authentication Setup")
    
    # Register user
    response = make_request("POST", "/auth/register", json_data=TEST_USER, expected_status=201)
    if response and not response.get("error"):
        print_test("User Registration", True, f"User created: {TEST_USER['email']}")
    else:
        print_test("User Registration", False, f"Failed: {response}")
        return None
    
    # Login
    login_data = {"email": TEST_USER["email"], "password": TEST_USER["password"]}
    response = make_request("POST", "/auth/token", json_data=login_data, expected_status=200)
    
    if response and not response.get("error") and "access_token" in response:
        token = response["access_token"]
        print_test("User Login", True, f"Token obtained")
        return token
    else:
        print_test("User Login", False, f"Failed: {response}")
        return None

# ==================== FAMILY HUB DASHBOARD ====================

def test_family_dashboard(token: str):
    """Test Family Hub Dashboard endpoint"""
    print_header("Step 2: Family Hub Dashboard")
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test dashboard endpoint
    response = make_request("GET", "/family/dashboard", headers=headers)
    
    if response and not response.get("error"):
        # Check for expected fields
        required_fields = ["stats", "recent_activity", "quick_actions"]
        missing_fields = [f for f in required_fields if f not in response.get("data", {})]
        
        if missing_fields:
            print_test("Dashboard Structure", False, 
                      f"Missing fields: {missing_fields}",
                      {"type": "missing_fields", "fields": missing_fields})
        else:
            print_test("Dashboard Endpoint", True, "All required fields present")
            
            # Validate stats structure
            stats = response.get("data", {}).get("stats", {})
            expected_stats = ["total_albums", "total_events", "total_milestones", "total_recipes"]
            missing_stats = [s for s in expected_stats if s not in stats]
            
            if missing_stats:
                print_test("Dashboard Stats", False,
                          f"Missing stats: {missing_stats}",
                          {"type": "missing_stats", "stats": missing_stats})
            else:
                print_test("Dashboard Stats", True, f"Stats: {stats}")
    else:
        print_test("Dashboard Endpoint", False, 
                  f"Status: {response.get('status_code', 'unknown')}",
                  {"type": "endpoint_error", "response": response})

# ==================== FAMILY ALBUMS ====================

def test_family_albums(token: str):
    """Test Family Albums CRUD operations"""
    print_header("Step 3: Family Albums")
    headers = {"Authorization": f"Bearer {token}"}
    album_id = None
    
    # CREATE album
    album_data = {
        "title": "Test Family Album",
        "description": "Testing album creation",
        "privacy": "private"
    }
    response = make_request("POST", "/family/albums/", headers=headers, 
                           json_data=album_data, expected_status=201)
    
    if response and not response.get("error"):
        album_id = response.get("data", {}).get("id")
        if album_id:
            print_test("Create Album", True, f"Album ID: {album_id}")
        else:
            print_test("Create Album", False, "No album ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Album", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST albums
    response = make_request("GET", "/family/albums/", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Albums", True, f"Found {len(items)} album(s)")
    else:
        print_test("List Albums", False, f"Status: {response.get('status_code')}",
                  {"type": "list_failed", "response": response})
    
    if album_id:
        # GET album details
        response = make_request("GET", f"/family/albums/{album_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Get Album Details", True, f"Album: {response.get('data', {}).get('title')}")
        else:
            print_test("Get Album Details", False, f"Status: {response.get('status_code')}",
                      {"type": "get_failed", "response": response})
        
        # UPDATE album
        update_data = {"title": "Updated Album Title", "description": "Updated description"}
        response = make_request("PUT", f"/family/albums/{album_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Album", True, "Album updated successfully")
        else:
            print_test("Update Album", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # ADD photo to album (endpoint expects single photo with url and caption)
        photo_data = {"url": "https://example.com/photo1.jpg", "caption": "Test photo"}
        response = make_request("POST", f"/family/albums/{album_id}/photos", headers=headers, 
                               json_data=photo_data, expected_status=201)
        if response and not response.get("error"):
            print_test("Add Photo to Album", True, "Photo added successfully")
        else:
            print_test("Add Photo to Album", False, f"Status: {response.get('status_code')}",
                      {"type": "add_photo_failed", "response": response})
        
        # DELETE album
        response = make_request("DELETE", f"/family/albums/{album_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Album", True, "Album deleted successfully")
        else:
            print_test("Delete Album", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})

# ==================== FAMILY CALENDAR ====================

def test_family_calendar(token: str):
    """Test Family Calendar events"""
    print_header("Step 4: Family Calendar")
    headers = {"Authorization": f"Bearer {token}"}
    event_id = None
    
    # CREATE event (event_type must be valid enum: birthday, anniversary, gathering, holiday, etc.)
    event_data = {
        "title": "Test Family Event",
        "description": "Testing event creation",
        "event_type": "gathering",  # Changed from "celebration" to valid type
        "event_date": (datetime.now() + timedelta(days=7)).isoformat(),
        "recurrence": "none"
    }
    response = make_request("POST", "/family/calendar/events", headers=headers, 
                           json_data=event_data, expected_status=201)
    
    if response and not response.get("error"):
        # Response structure is data.event.id, not data.id
        event_data = response.get("data", {}).get("event", {})
        event_id = event_data.get("id") if event_data else None
        if event_id:
            print_test("Create Event", True, f"Event ID: {event_id}")
        else:
            print_test("Create Event", False, "No event ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Event", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST events
    response = make_request("GET", "/family/calendar/events", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Events", True, f"Found {len(items)} event(s)")
    else:
        print_test("List Events", False, f"Status: {response.get('status_code')}",
                  {"type": "list_failed", "response": response})
    
    if event_id:
        # UPDATE event
        update_data = {"title": "Updated Event Title"}
        response = make_request("PUT", f"/family/calendar/events/{event_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Event", True, "Event updated successfully")
        else:
            print_test("Update Event", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # DELETE event
        response = make_request("DELETE", f"/family/calendar/events/{event_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Event", True, "Event deleted successfully")
        else:
            print_test("Delete Event", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})
    
    # TEST birthdays endpoint
    response = make_request("GET", "/family/calendar/birthdays", headers=headers)
    if response and not response.get("error"):
        print_test("Get Birthdays", True, "Birthdays endpoint working")
    else:
        print_test("Get Birthdays", False, f"Status: {response.get('status_code')}",
                  {"type": "birthdays_failed", "response": response})

# ==================== FAMILY MILESTONES ====================

def test_family_milestones(token: str):
    """Test Family Milestones"""
    print_header("Step 5: Family Milestones")
    headers = {"Authorization": f"Bearer {token}"}
    milestone_id = None
    
    # CREATE milestone
    milestone_data = {
        "title": "Test Milestone",
        "description": "Testing milestone creation",
        "milestone_type": "achievement",
        "milestone_date": datetime.now().isoformat()
    }
    response = make_request("POST", "/family/milestones/", headers=headers, 
                           json_data=milestone_data, expected_status=201)
    
    if response and not response.get("error"):
        milestone_id = response.get("data", {}).get("id")
        if milestone_id:
            print_test("Create Milestone", True, f"Milestone ID: {milestone_id}")
        else:
            print_test("Create Milestone", False, "No milestone ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Milestone", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST milestones
    response = make_request("GET", "/family/milestones/", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Milestones", True, f"Found {len(items)} milestone(s)")
    else:
        print_test("List Milestones", False, f"Status: {response.get('status_code')}",
                  {"type": "list_failed", "response": response})
    
    if milestone_id:
        # LIKE milestone
        response = make_request("POST", f"/family/milestones/{milestone_id}/like", headers=headers)
        if response and not response.get("error"):
            print_test("Like Milestone", True, "Milestone liked successfully")
        else:
            print_test("Like Milestone", False, f"Status: {response.get('status_code')}",
                      {"type": "like_failed", "response": response})
        
        # UNLIKE milestone
        response = make_request("DELETE", f"/family/milestones/{milestone_id}/like", headers=headers)
        if response and not response.get("error"):
            print_test("Unlike Milestone", True, "Milestone unliked successfully")
        else:
            print_test("Unlike Milestone", False, f"Status: {response.get('status_code')}",
                      {"type": "unlike_failed", "response": response})
        
        # UPDATE milestone
        update_data = {"title": "Updated Milestone Title"}
        response = make_request("PUT", f"/family/milestones/{milestone_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Milestone", True, "Milestone updated successfully")
        else:
            print_test("Update Milestone", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # DELETE milestone
        response = make_request("DELETE", f"/family/milestones/{milestone_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Milestone", True, "Milestone deleted successfully")
        else:
            print_test("Delete Milestone", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})

# ==================== FAMILY RECIPES ====================

def test_family_recipes(token: str):
    """Test Family Recipes"""
    print_header("Step 6: Family Recipes")
    headers = {"Authorization": f"Bearer {token}"}
    recipe_id = None
    
    # CREATE recipe (ingredients need "amount" not "quantity")
    recipe_data = {
        "title": "Test Recipe",
        "description": "Testing recipe creation",
        "category": "main_course",
        "difficulty": "easy",
        "ingredients": [
            {"name": "Ingredient 1", "amount": "2 cups"},  # Changed from "quantity" to "amount"
            {"name": "Ingredient 2", "amount": "1 tbsp"}
        ],
        "steps": [
            {"step_number": 1, "instruction": "Step 1 instructions"},
            {"step_number": 2, "instruction": "Step 2 instructions"}
        ]
    }
    response = make_request("POST", "/family/recipes/", headers=headers, 
                           json_data=recipe_data, expected_status=201)
    
    if response and not response.get("error"):
        recipe_id = response.get("data", {}).get("id")
        if recipe_id:
            print_test("Create Recipe", True, f"Recipe ID: {recipe_id}")
        else:
            print_test("Create Recipe", False, "No recipe ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Recipe", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST recipes
    response = make_request("GET", "/family/recipes/", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Recipes", True, f"Found {len(items)} recipe(s)")
    else:
        print_test("List Recipes", False, f"Status: {response.get('status_code')}",
                  {"type": "list_failed", "response": response})
    
    # LIST by category
    response = make_request("GET", "/family/recipes/", headers=headers, params={"category": "main_course"})
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("Filter Recipes by Category", True, f"Found {len(items)} recipe(s) in category")
    else:
        print_test("Filter Recipes by Category", False, f"Status: {response.get('status_code')}",
                  {"type": "filter_failed", "response": response})
    
    if recipe_id:
        # UPDATE recipe
        update_data = {"title": "Updated Recipe Title"}
        response = make_request("PUT", f"/family/recipes/{recipe_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Recipe", True, "Recipe updated successfully")
        else:
            print_test("Update Recipe", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # DELETE recipe
        response = make_request("DELETE", f"/family/recipes/{recipe_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Recipe", True, "Recipe deleted successfully")
        else:
            print_test("Delete Recipe", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})

# ==================== FAMILY TRADITIONS ====================

def test_family_traditions(token: str):
    """Test Family Traditions"""
    print_header("Step 7: Family Traditions")
    headers = {"Authorization": f"Bearer {token}"}
    tradition_id = None
    
    # CREATE tradition
    tradition_data = {
        "title": "Test Tradition",
        "description": "Testing tradition creation",
        "category": "holiday",
        "frequency": "yearly"
    }
    response = make_request("POST", "/family/traditions/", headers=headers, 
                           json_data=tradition_data, expected_status=201)
    
    if response and not response.get("error"):
        tradition_id = response.get("data", {}).get("id")
        if tradition_id:
            print_test("Create Tradition", True, f"Tradition ID: {tradition_id}")
        else:
            print_test("Create Tradition", False, "No tradition ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Tradition", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST traditions
    response = make_request("GET", "/family/traditions/", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Traditions", True, f"Found {len(items)} tradition(s)")
    else:
        print_test("List Traditions", False, f"Status: {response.get('status_code')}",
                  {"type": "list_failed", "response": response})
    
    if tradition_id:
        # FOLLOW tradition
        response = make_request("POST", f"/family/traditions/{tradition_id}/follow", headers=headers)
        if response and not response.get("error"):
            print_test("Follow Tradition", True, "Tradition followed successfully")
        else:
            print_test("Follow Tradition", False, f"Status: {response.get('status_code')}",
                      {"type": "follow_failed", "response": response})
        
        # UNFOLLOW tradition
        response = make_request("DELETE", f"/family/traditions/{tradition_id}/follow", headers=headers)
        if response and not response.get("error"):
            print_test("Unfollow Tradition", True, "Tradition unfollowed successfully")
        else:
            print_test("Unfollow Tradition", False, f"Status: {response.get('status_code')}",
                      {"type": "unfollow_failed", "response": response})
        
        # UPDATE tradition
        update_data = {"title": "Updated Tradition Title"}
        response = make_request("PUT", f"/family/traditions/{tradition_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Tradition", True, "Tradition updated successfully")
        else:
            print_test("Update Tradition", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # DELETE tradition
        response = make_request("DELETE", f"/family/traditions/{tradition_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Tradition", True, "Tradition deleted successfully")
        else:
            print_test("Delete Tradition", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})

# ==================== FAMILY TIMELINE ====================

def test_family_timeline(token: str):
    """Test Family Timeline"""
    print_header("Step 8: Family Timeline")
    headers = {"Authorization": f"Bearer {token}"}
    
    # GET timeline events
    response = make_request("GET", "/family/timeline/", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("Get Timeline Events", True, f"Found {len(items)} timeline event(s)")
    else:
        print_test("Get Timeline Events", False, f"Status: {response.get('status_code')}",
                  {"type": "timeline_failed", "response": response})
    
    # GET timeline with pagination
    response = make_request("GET", "/family/timeline/", headers=headers, params={"page": 1, "page_size": 10})
    if response and not response.get("error"):
        print_test("Timeline Pagination", True, "Pagination working")
    else:
        print_test("Timeline Pagination", False, f"Status: {response.get('status_code')}",
                  {"type": "pagination_failed", "response": response})
    
    # GET timeline stats
    response = make_request("GET", "/family/timeline/stats", headers=headers)
    if response and not response.get("error"):
        print_test("Timeline Stats", True, "Stats endpoint working")
    else:
        print_test("Timeline Stats", False, f"Status: {response.get('status_code')}",
                  {"type": "stats_failed", "response": response})

# ==================== LEGACY LETTERS ====================

def test_legacy_letters(token: str, user_id: str):
    """Test Legacy Letters"""
    print_header("Step 9: Legacy Letters")
    headers = {"Authorization": f"Bearer {token}"}
    letter_id = None
    
    # CREATE letter (needs at least one recipient - use self for testing)
    letter_data = {
        "title": "Test Letter",
        "content": "This is a test legacy letter",
        "delivery_date": (datetime.now() + timedelta(days=30)).isoformat(),
        "encrypt": False,
        "recipient_ids": [user_id]  # Added self as recipient for testing
    }
    response = make_request("POST", "/family/legacy-letters/", headers=headers, 
                           json_data=letter_data, expected_status=201)
    
    if response and not response.get("error"):
        letter_id = response.get("data", {}).get("id")
        if letter_id:
            print_test("Create Legacy Letter", True, f"Letter ID: {letter_id}")
        else:
            print_test("Create Legacy Letter", False, "No letter ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Legacy Letter", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST sent letters
    response = make_request("GET", "/family/legacy-letters/sent", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Sent Letters", True, f"Found {len(items)} sent letter(s)")
    else:
        print_test("List Sent Letters", False, f"Status: {response.get('status_code')}",
                  {"type": "list_sent_failed", "response": response})
    
    # LIST received letters
    response = make_request("GET", "/family/legacy-letters/received", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Received Letters", True, f"Found {len(items)} received letter(s)")
    else:
        print_test("List Received Letters", False, f"Status: {response.get('status_code')}",
                  {"type": "list_received_failed", "response": response})
    
    if letter_id:
        # UPDATE letter
        update_data = {"title": "Updated Letter Title"}
        response = make_request("PUT", f"/family/legacy-letters/{letter_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Legacy Letter", True, "Letter updated successfully")
        else:
            print_test("Update Legacy Letter", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # DELETE letter
        response = make_request("DELETE", f"/family/legacy-letters/{letter_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Legacy Letter", True, "Letter deleted successfully")
        else:
            print_test("Delete Legacy Letter", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})

# ==================== GENEALOGY ====================

def test_genealogy(token: str):
    """Test Genealogy features"""
    print_header("Step 10: Genealogy")
    headers = {"Authorization": f"Bearer {token}"}
    person_id = None
    
    # CREATE person (date must be YYYY-MM-DD format, not ISO)
    person_data = {
        "first_name": "Test",
        "last_name": "Person",
        "gender": "male",
        "birth_date": "1990-01-01",  # Changed from ISO to YYYY-MM-DD format
        "is_alive": True
    }
    response = make_request("POST", "/family/genealogy/persons", headers=headers, 
                           json_data=person_data, expected_status=201)
    
    if response and not response.get("error"):
        person_id = response.get("data", {}).get("id")
        if person_id:
            print_test("Create Genealogy Person", True, f"Person ID: {person_id}")
        else:
            print_test("Create Genealogy Person", False, "No person ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Genealogy Person", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST persons
    response = make_request("GET", "/family/genealogy/persons", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Genealogy Persons", True, f"Found {len(items)} person(s)")
    else:
        print_test("List Genealogy Persons", False, f"Status: {response.get('status_code')}",
                  {"type": "list_failed", "response": response})
    
    # GET family tree
    response = make_request("GET", "/family/genealogy/tree", headers=headers)
    if response and not response.get("error"):
        print_test("Get Family Tree", True, "Tree retrieved successfully")
    else:
        print_test("Get Family Tree", False, f"Status: {response.get('status_code')}",
                  {"type": "tree_failed", "response": response})
    
    if person_id:
        # UPDATE person
        update_data = {"biography": "Updated biography"}
        response = make_request("PUT", f"/family/genealogy/persons/{person_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Genealogy Person", True, "Person updated successfully")
        else:
            print_test("Update Genealogy Person", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # DELETE person
        response = make_request("DELETE", f"/family/genealogy/persons/{person_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Genealogy Person", True, "Person deleted successfully")
        else:
            print_test("Delete Genealogy Person", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})

# ==================== HEALTH RECORDS ====================

def test_health_records(token: str, user_id: str):
    """Test Health Records"""
    print_header("Step 11: Health Records")
    headers = {"Authorization": f"Bearer {token}"}
    record_id = None
    
    # CREATE health record (requires subject_user_id when subject_type is SELF)
    record_data = {
        "record_type": "medical",  # Changed from invalid "checkup" to valid "medical"
        "title": "Annual Checkup",
        "description": "Testing health record creation",
        "date": datetime.now().isoformat(),
        "subject_type": "self",
        "subject_user_id": user_id  # Required when subject_type is SELF
    }
    response = make_request("POST", "/health-records/", headers=headers, 
                           json_data=record_data, expected_status=201)
    
    if response and not response.get("error"):
        record_id = response.get("data", {}).get("id")
        if record_id:
            print_test("Create Health Record", True, f"Record ID: {record_id}")
        else:
            print_test("Create Health Record", False, "No record ID in response",
                      {"type": "missing_id", "response": response})
    else:
        print_test("Create Health Record", False, f"Status: {response.get('status_code')}",
                  {"type": "create_failed", "response": response})
    
    # LIST health records
    response = make_request("GET", "/health-records/", headers=headers)
    if response and not response.get("error"):
        items = response.get("data", {}).get("items", [])
        print_test("List Health Records", True, f"Found {len(items)} record(s)")
    else:
        print_test("List Health Records", False, f"Status: {response.get('status_code')}",
                  {"type": "list_failed", "response": response})
    
    # GET dashboard
    response = make_request("GET", "/health-records/dashboard", headers=headers)
    if response and not response.get("error"):
        print_test("Health Records Dashboard", True, "Dashboard endpoint working")
    else:
        print_test("Health Records Dashboard", False, f"Status: {response.get('status_code')}",
                  {"type": "dashboard_failed", "response": response})
    
    if record_id:
        # UPDATE health record
        update_data = {"title": "Updated Checkup Title"}
        response = make_request("PUT", f"/health-records/{record_id}", headers=headers, json_data=update_data)
        if response and not response.get("error"):
            print_test("Update Health Record", True, "Record updated successfully")
        else:
            print_test("Update Health Record", False, f"Status: {response.get('status_code')}",
                      {"type": "update_failed", "response": response})
        
        # DELETE health record
        response = make_request("DELETE", f"/health-records/{record_id}", headers=headers)
        if response and not response.get("error"):
            print_test("Delete Health Record", True, "Record deleted successfully")
        else:
            print_test("Delete Health Record", False, f"Status: {response.get('status_code')}",
                      {"type": "delete_failed", "response": response})

# ==================== SUMMARY AND REPORTING ====================

def print_summary():
    """Print test summary and bug report"""
    print_header("Test Summary")
    
    print(f"\n{Colors.BOLD}Overall Results:{Colors.END}")
    print(f"  Total Tests: {test_results['total']}")
    print(f"  {Colors.GREEN}Passed: {test_results['passed']}{Colors.END}")
    print(f"  {Colors.RED}Failed: {test_results['failed']}{Colors.END}")
    
    if test_results['passed'] == test_results['total']:
        print(f"\n{Colors.GREEN}{Colors.BOLD}*** ALL TESTS PASSED! ***{Colors.END}")
    else:
        pass_rate = (test_results['passed'] / test_results['total'] * 100) if test_results['total'] > 0 else 0
        print(f"\n  Pass Rate: {pass_rate:.1f}%")
    
    if test_results['bugs_found']:
        print(f"\n{Colors.RED}{Colors.BOLD}Bugs Found: {len(test_results['bugs_found'])}{Colors.END}")
        print(f"{Colors.YELLOW}{'='*70}{Colors.END}")
        
        for i, bug in enumerate(test_results['bugs_found'], 1):
            print(f"\n{Colors.BOLD}Bug #{i}: {bug['test']}{Colors.END}")
            print(f"  Details: {bug['details']}")
            print(f"  Bug Info: {json.dumps(bug['bug'], indent=2)}")
            print(f"{Colors.YELLOW}{'-'*70}{Colors.END}")
    else:
        print(f"\n{Colors.GREEN}No bugs found!{Colors.END}")

# ==================== MAIN EXECUTION ====================

def main():
    """Main test execution"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}{'='*70}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{'Comprehensive Family Features Test Suite'.center(70)}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{'='*70}{Colors.END}")
    print(f"{Colors.MAGENTA}Testing all family endpoints systematically...{Colors.END}")
    
    # Step 1: Authenticate and get user ID
    token = test_authentication()
    if not token:
        print(f"\n{Colors.RED}{Colors.BOLD}[X] Authentication failed. Cannot proceed.{Colors.END}")
        sys.exit(1)
    
    # Get user ID for legacy letters test
    headers = {"Authorization": f"Bearer {token}"}
    user_response = make_request("GET", "/users/me", headers=headers)
    user_id = user_response.get("id") if user_response and not user_response.get("error") else None
    
    # Step 2-11: Test all features
    try:
        test_family_dashboard(token)
        test_family_albums(token)
        test_family_calendar(token)
        test_family_milestones(token)
        test_family_recipes(token)
        test_family_traditions(token)
        test_family_timeline(token)
        test_legacy_letters(token, user_id) if user_id else print(f"{Colors.YELLOW}Skipping legacy letters (no user ID){Colors.END}")
        test_genealogy(token)
        test_health_records(token, user_id) if user_id else print(f"{Colors.YELLOW}Skipping health records (no user ID){Colors.END}")
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Tests interrupted by user{Colors.END}")
    except Exception as e:
        print(f"\n{Colors.RED}Unexpected error: {e}{Colors.END}")
    
    # Print summary
    print_summary()
    
    # Save bug report to file
    if test_results['bugs_found']:
        with open('family_features_bug_report.json', 'w') as f:
            json.dump(test_results['bugs_found'], f, indent=2)
        print(f"\n{Colors.CYAN}Bug report saved to: family_features_bug_report.json{Colors.END}")
    
    print(f"\n{Colors.BLUE}{Colors.BOLD}Test suite completed!{Colors.END}\n")
    
    # Return exit code based on results
    sys.exit(0 if test_results['failed'] == 0 else 1)

if __name__ == "__main__":
    main()
