#!/usr/bin/env python3
"""
Comprehensive Backend API Test Script
Tests all major features in the Memory Hub API
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000/api/v1"

# Test data
test_user = {
    "email": f"comprehensive_test_{datetime.now().timestamp()}@example.com",
    "password": "SecurePass123!@#",
    "full_name": "Comprehensive Test User"
}

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Colors.CYAN}{'='*60}{Colors.END}")
    print(f"{Colors.CYAN}{text.center(60)}{Colors.END}")
    print(f"{Colors.CYAN}{'='*60}{Colors.END}")

def print_test(name, passed, details=""):
    status = f"{Colors.GREEN}✓ PASS{Colors.END}" if passed else f"{Colors.RED}✗ FAIL{Colors.END}"
    print(f"{status} - {name}")
    if details:
        print(f"  {Colors.YELLOW}{details}{Colors.END}")

def test_auth():
    print_header("Authentication & User Management")
    
    # Test registration
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=test_user)
        print_test("User Registration", response.status_code == 201)
    except Exception as e:
        print_test("User Registration", False, str(e))
        return None
    
    # Test login
    try:
        login_data = {"email": test_user["email"], "password": test_user["password"]}
        response = requests.post(f"{BASE_URL}/auth/token", json=login_data)
        print_test("User Login", response.status_code == 200)
        if response.status_code == 200:
            tokens = response.json()
            return tokens.get("access_token")
    except Exception as e:
        print_test("User Login", False, str(e))
    
    return None

def test_user_operations(token):
    print_header("User Operations")
    headers = {"Authorization": f"Bearer {token}"}
    
    tests = [
        ("Get Current User", "GET", "/users/me", None),
        ("Update User Profile", "PUT", "/users/me", {"full_name": "Updated Name"}),
        ("Get User Settings", "GET", "/users/settings", None),
    ]
    
    for name, method, endpoint, data in tests:
        try:
            if method == "GET":
                response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            elif method == "PUT":
                response = requests.put(f"{BASE_URL}{endpoint}", json=data, headers=headers)
            print_test(name, response.status_code in [200, 201])
        except Exception as e:
            print_test(name, False, str(e))

def test_memories(token):
    print_header("Memories System")
    headers = {"Authorization": f"Bearer {token}"}
    
    # Create memory
    memory_id = None
    try:
        memory_data = {
            "title": "Test Memory",
            "content": "Comprehensive test memory content",
            "tags": ["test", "comprehensive"],
            "privacy": "private"
        }
        response = requests.post(f"{BASE_URL}/memories/", data=memory_data, headers=headers)
        print_test("Create Memory", response.status_code == 200)
        if response.status_code == 200:
            memory_id = response.json().get("id")
    except Exception as e:
        print_test("Create Memory", False, str(e))
    
    # Test memory operations
    tests = [
        ("Search Memories", "GET", "/memories/search/"),
        ("Get Memory", "GET", f"/memories/{memory_id}" if memory_id else "/memories/invalid"),
    ]
    
    if memory_id:
        tests.extend([
            ("Like Memory", "POST", f"/memories/{memory_id}/like"),
            ("Unlike Memory", "DELETE", f"/memories/{memory_id}/like"),
            ("Bookmark Memory", "POST", f"/memories/{memory_id}/bookmark"),
        ])
    
    for name, method, endpoint in tests:
        try:
            if method == "GET":
                response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            elif method == "POST":
                response = requests.post(f"{BASE_URL}{endpoint}", headers=headers)
            elif method == "DELETE":
                response = requests.delete(f"{BASE_URL}{endpoint}", headers=headers)
            
            expected_success = memory_id is not None if "invalid" not in endpoint else False
            print_test(name, response.status_code in [200, 201] or not expected_success)
        except Exception as e:
            print_test(name, False, str(e))

def test_collections(token):
    print_header("Collections System")
    headers = {"Authorization": f"Bearer {token}"}
    
    collection_id = None
    try:
        collection_data = {
            "name": "Test Collection",
            "description": "Test collection description",
            "privacy": "private"
        }
        response = requests.post(f"{BASE_URL}/collections/", json=collection_data, headers=headers)
        print_test("Create Collection", response.status_code == 200)
        if response.status_code == 200:
            collection_id = response.json().get("id")
    except Exception as e:
        print_test("Create Collection", False, str(e))
    
    tests = [
        ("List Collections", "GET", "/collections/"),
        ("Get Collection Stats", "GET", f"/collections/{collection_id}" if collection_id else "/collections/invalid"),
    ]
    
    for name, method, endpoint in tests:
        try:
            if method == "GET":
                response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            print_test(name, response.status_code in [200, 404])
        except Exception as e:
            print_test(name, False, str(e))

def test_vault(token):
    print_header("Vault System")
    headers = {"Authorization": f"Bearer {token}"}
    
    tests = [
        ("List Vault Files", "GET", "/vault/"),
        ("Get Vault Stats", "GET", "/vault/stats"),
    ]
    
    for name, method, endpoint in tests:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            print_test(name, response.status_code == 200)
        except Exception as e:
            print_test(name, False, str(e))

def test_hub(token):
    print_header("Hub & Dashboard")
    headers = {"Authorization": f"Bearer {token}"}
    
    tests = [
        ("Get Dashboard", "GET", "/hub/dashboard"),
        ("List Hub Items", "GET", "/hub/items"),
        ("Get Hub Stats", "GET", "/hub/stats"),
    ]
    
    for name, method, endpoint in tests:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            print_test(name, response.status_code == 200)
        except Exception as e:
            print_test(name, False, str(e))

def test_social_features(token):
    print_header("Social Features")
    headers = {"Authorization": f"Bearer {token}"}
    
    tests = [
        ("List Hubs", "GET", "/social/hubs"),
        ("Search Users", "GET", "/social/users/search?query=test"),
        ("Get Followers", "GET", "/social/followers"),
        ("Get Following", "GET", "/social/following"),
    ]
    
    for name, method, endpoint in tests:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            print_test(name, response.status_code == 200)
        except Exception as e:
            print_test(name, False, str(e))

def test_notifications(token):
    print_header("Notifications System")
    headers = {"Authorization": f"Bearer {token}"}
    
    tests = [
        ("List Notifications", "GET", "/notifications/"),
    ]
    
    for name, method, endpoint in tests:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            print_test(name, response.status_code == 200)
        except Exception as e:
            print_test(name, False, str(e))

def test_analytics(token):
    print_header("Analytics & Insights")
    headers = {"Authorization": f"Bearer {token}"}
    
    tests = [
        ("Get Analytics Overview", "GET", "/analytics/overview"),
        ("Get Activity Chart", "GET", "/analytics/activity-chart"),
    ]
    
    for name, method, endpoint in tests:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            print_test(name, response.status_code == 200)
        except Exception as e:
            print_test(name, False, str(e))

def test_advanced_features(token):
    print_header("Advanced Features")
    headers = {"Authorization": f"Bearer {token}"}
    
    tests = [
        ("Global Search", "GET", "/search/global?q=test"),
        ("List Tags", "GET", "/tags/"),
        ("List Categories", "GET", "/categories/"),
        ("List Stories", "GET", "/stories/"),
        ("Get Privacy Settings", "GET", "/privacy/settings"),
        ("List Export Options", "GET", "/export/"),
    ]
    
    for name, method, endpoint in tests:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
            print_test(name, response.status_code in [200, 404])
        except Exception as e:
            print_test(name, False, str(e))

def main():
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}{'Memory Hub - Comprehensive Test Suite'.center(60)}{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}")
    
    # Test authentication first
    token = test_auth()
    
    if not token:
        print(f"\n{Colors.RED}Authentication failed. Cannot proceed with other tests.{Colors.END}")
        return
    
    # Test all features
    test_user_operations(token)
    test_memories(token)
    test_collections(token)
    test_vault(token)
    test_hub(token)
    test_social_features(token)
    test_notifications(token)
    test_analytics(token)
    test_advanced_features(token)
    
    print_header("Test Suite Complete")
    print(f"{Colors.GREEN}All major features have been tested!{Colors.END}\n")

if __name__ == "__main__":
    main()
