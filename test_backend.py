#!/usr/bin/env python3
"""
Backend API Test Script
Tests all available endpoints in the Memory Hub API
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000/api/v1"

# Test data
test_user = {
    "email": f"test_{datetime.now().timestamp()}@example.com",
    "password": "Test123!@#",
    "full_name": "Test User"
}

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    END = '\033[0m'

def print_test(name, passed, details=""):
    status = f"{Colors.GREEN}✓ PASS{Colors.END}" if passed else f"{Colors.RED}✗ FAIL{Colors.END}"
    print(f"{status} - {name}")
    if details:
        print(f"  {Colors.YELLOW}{details}{Colors.END}")

def test_auth():
    print(f"\n{Colors.BLUE}=== Testing Authentication ==={Colors.END}")
    
    # Test registration
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=test_user)
        print_test("User Registration", response.status_code == 201, 
                  f"Status: {response.status_code}, Response: {response.text[:100]}")
    except Exception as e:
        print_test("User Registration", False, str(e))
        return None
    
    # Test login
    try:
        login_data = {
            "email": test_user["email"],
            "password": test_user["password"]
        }
        response = requests.post(f"{BASE_URL}/auth/token", json=login_data)
        print_test("User Login", response.status_code == 200,
                  f"Status: {response.status_code}")
        
        if response.status_code == 200:
            tokens = response.json()
            return tokens.get("access_token")
    except Exception as e:
        print_test("User Login", False, str(e))
    
    return None

def test_users(token):
    print(f"\n{Colors.BLUE}=== Testing User Endpoints ==={Colors.END}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test get current user
    try:
        response = requests.get(f"{BASE_URL}/users/me", headers=headers)
        print_test("Get Current User", response.status_code == 200,
                  f"Status: {response.status_code}")
    except Exception as e:
        print_test("Get Current User", False, str(e))
    
    # Test update user
    try:
        update_data = {"full_name": "Updated Test User"}
        response = requests.put(f"{BASE_URL}/users/me", json=update_data, headers=headers)
        print_test("Update User Profile", response.status_code == 200,
                  f"Status: {response.status_code}")
    except Exception as e:
        print_test("Update User Profile", False, str(e))

def test_memories(token):
    print(f"\n{Colors.BLUE}=== Testing Memories Endpoints ==={Colors.END}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test create memory
    try:
        memory_data = {
            "title": "Test Memory",
            "content": "This is a test memory content",
            "tags": ["test", "automated"],
            "privacy": "private"
        }
        response = requests.post(f"{BASE_URL}/memories/", data=memory_data, headers=headers)
        print_test("Create Memory", response.status_code == 200,
                  f"Status: {response.status_code}")
        
        memory_id = None
        if response.status_code == 200:
            memory_id = response.json().get("id")
            
        # Test search memories
        response = requests.get(f"{BASE_URL}/memories/search/", headers=headers)
        print_test("Search Memories", response.status_code == 200,
                  f"Status: {response.status_code}, Found: {len(response.json()) if response.status_code == 200 else 0} memories")
        
        # Test like memory
        if memory_id:
            response = requests.post(f"{BASE_URL}/memories/{memory_id}/like", headers=headers)
            print_test("Like Memory", response.status_code == 200,
                      f"Status: {response.status_code}")
                      
    except Exception as e:
        print_test("Memories Tests", False, str(e))

def test_vault(token):
    print(f"\n{Colors.BLUE}=== Testing Vault Endpoints ==={Colors.END}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test list files
    try:
        response = requests.get(f"{BASE_URL}/vault/", headers=headers)
        print_test("List Vault Files", response.status_code == 200,
                  f"Status: {response.status_code}")
    except Exception as e:
        print_test("List Vault Files", False, str(e))
    
    # Test get vault stats
    try:
        response = requests.get(f"{BASE_URL}/vault/stats", headers=headers)
        print_test("Get Vault Stats", response.status_code == 200,
                  f"Status: {response.status_code}")
    except Exception as e:
        print_test("Get Vault Stats", False, str(e))

def test_hub(token):
    print(f"\n{Colors.BLUE}=== Testing Hub Endpoints ==={Colors.END}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test get dashboard
    try:
        response = requests.get(f"{BASE_URL}/hub/dashboard", headers=headers)
        print_test("Get Hub Dashboard", response.status_code == 200,
                  f"Status: {response.status_code}")
    except Exception as e:
        print_test("Get Hub Dashboard", False, str(e))
    
    # Test list hub items
    try:
        response = requests.get(f"{BASE_URL}/hub/items", headers=headers)
        print_test("List Hub Items", response.status_code == 200,
                  f"Status: {response.status_code}")
    except Exception as e:
        print_test("List Hub Items", False, str(e))
    
    # Test hub stats
    try:
        response = requests.get(f"{BASE_URL}/hub/stats", headers=headers)
        print_test("Get Hub Stats", response.status_code == 200,
                  f"Status: {response.status_code}")
    except Exception as e:
        print_test("Get Hub Stats", False, str(e))

def main():
    print(f"\n{Colors.BLUE}{'='*50}{Colors.END}")
    print(f"{Colors.BLUE}Memory Hub API Test Suite{Colors.END}")
    print(f"{Colors.BLUE}{'='*50}{Colors.END}")
    
    # Test authentication first
    token = test_auth()
    
    if not token:
        print(f"\n{Colors.RED}Authentication failed. Cannot proceed with other tests.{Colors.END}")
        return
    
    # Test all other endpoints
    test_users(token)
    test_memories(token)
    test_vault(token)
    test_hub(token)
    
    print(f"\n{Colors.BLUE}{'='*50}{Colors.END}")
    print(f"{Colors.GREEN}Testing Complete!{Colors.END}")
    print(f"{Colors.BLUE}{'='*50}{Colors.END}\n")

if __name__ == "__main__":
    main()
