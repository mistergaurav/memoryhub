#!/usr/bin/env python3
"""
Memory Hub - Frontend-Backend Integration Test Suite
Tests the entire user journey from registration to using all features
"""

import requests
import json
import time
from datetime import datetime

BASE_URL = "http://localhost:8000/api/v1"

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text:^60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}\n")

def print_test(name, passed, details=""):
    status = f"{Colors.GREEN}✓ PASS{Colors.END}" if passed else f"{Colors.RED}✗ FAIL{Colors.END}"
    print(f"{status} - {name}")
    if details and not passed:
        print(f"  {Colors.YELLOW}Details: {details}{Colors.END}")

class IntegrationTester:
    def __init__(self):
        self.token = None
        self.user_id = None
        self.memory_id = None
        self.collection_id = None
        self.passed = 0
        self.failed = 0
        self.email = f"testuser_{int(time.time())}@example.com"
        self.password = "SecurePass123!"
    
    def test(self, name, test_func):
        try:
            test_func()
            self.passed += 1
            print_test(name, True)
            return True
        except Exception as e:
            self.failed += 1
            print_test(name, False, str(e))
            return False
    
    def register_and_login(self):
        """Test user registration and login flow"""
        print_header("User Authentication Flow")
        
        # Register
        def register():
            response = requests.post(f"{BASE_URL}/auth/register", json={
                "email": self.email,
                "password": self.password,
                "full_name": "Integration Test User"
            })
            assert response.status_code == 201, f"Status: {response.status_code}"
        
        self.test("User Registration", register)
        
        # Login
        def login():
            response = requests.post(
                f"{BASE_URL}/auth/token",
                json={
                    "email": self.email,
                    "password": self.password
                }
            )
            assert response.status_code == 200, f"Status: {response.status_code}, Body: {response.text}"
            data = response.json()
            self.token = data["access_token"]
            assert self.token, "No token received"
        
        self.test("User Login", login)
    
    def test_memories_flow(self):
        """Test creating, viewing, and managing memories"""
        print_header("Memories Management Flow")
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        # Create memory
        def create_memory():
            response = requests.post(
                f"{BASE_URL}/memories/",
                data={
                    "title": "My First Memory",
                    "content": "This is a beautiful memory from the integration test",
                    "tags": json.dumps(["test", "integration", "memory"])
                },
                headers=headers
            )
            assert response.status_code == 200, f"Status: {response.status_code}, Body: {response.text}"
            data = response.json()
            # Handle both 'id' and '_id' fields
            self.memory_id = data.get("id") or str(data.get("_id"))
            assert self.memory_id, f"No ID in response: {data}"
        
        self.test("Create Memory", create_memory)
        
        # Search memories
        def search_memories():
            response = requests.get(
                f"{BASE_URL}/memories/search/",
                params={"q": "beautiful"},
                headers=headers
            )
            assert response.status_code == 200, f"Status: {response.status_code}"
            data = response.json()
            assert len(data) > 0, "No memories found"
        
        self.test("Search Memories", search_memories)
        
        # Get specific memory
        def get_memory():
            response = requests.get(
                f"{BASE_URL}/memories/{self.memory_id}",
                headers=headers
            )
            assert response.status_code == 200, f"Status: {response.status_code}"
            data = response.json()
            assert data["title"] == "My First Memory"
        
        self.test("Get Memory Details", get_memory)
    
    def test_collections_flow(self):
        """Test collections management"""
        print_header("Collections Management Flow")
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        # Create collection
        def create_collection():
            response = requests.post(
                f"{BASE_URL}/collections/",
                json={
                    "name": "Vacation Memories",
                    "description": "All my vacation photos and memories",
                    "privacy": "private"
                },
                headers=headers
            )
            assert response.status_code == 201, f"Status: {response.status_code}"
            data = response.json()
            self.collection_id = data["id"]
        
        self.test("Create Collection", create_collection)
        
        # List collections
        def list_collections():
            response = requests.get(f"{BASE_URL}/collections/", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
            data = response.json()
            assert len(data) > 0, "No collections found"
        
        self.test("List Collections", list_collections)
        
        # Get collection
        def get_collection():
            response = requests.get(
                f"{BASE_URL}/collections/{self.collection_id}",
                headers=headers
            )
            assert response.status_code == 200, f"Status: {response.status_code}"
            data = response.json()
            assert data["name"] == "Vacation Memories"
        
        self.test("Get Collection Details", get_collection)
    
    def test_social_flow(self):
        """Test social features"""
        print_header("Social Features Flow")
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        # Search users
        def search_users():
            response = requests.get(
                f"{BASE_URL}/social/users/search",
                params={"query": "test"},
                headers=headers
            )
            assert response.status_code == 200, f"Status: {response.status_code}"
        
        self.test("Search Users", search_users)
        
        # Get followers
        def get_followers():
            response = requests.get(f"{BASE_URL}/social/followers", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
        
        self.test("Get Followers", get_followers)
        
        # Get following
        def get_following():
            response = requests.get(f"{BASE_URL}/social/following", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
        
        self.test("Get Following", get_following)
    
    def test_dashboard_flow(self):
        """Test dashboard and hub features"""
        print_header("Dashboard & Hub Flow")
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        # Get dashboard
        def get_dashboard():
            response = requests.get(f"{BASE_URL}/hub/dashboard", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
            data = response.json()
            assert "stats" in data, "No stats in dashboard"
        
        self.test("Get Dashboard", get_dashboard)
        
        # Get hub stats
        def get_hub_stats():
            response = requests.get(f"{BASE_URL}/hub/stats", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
        
        self.test("Get Hub Stats", get_hub_stats)
    
    def test_analytics_flow(self):
        """Test analytics features"""
        print_header("Analytics & Insights Flow")
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        # Get analytics overview
        def get_analytics():
            response = requests.get(f"{BASE_URL}/analytics/overview", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
        
        self.test("Get Analytics Overview", get_analytics)
        
        # Get activity chart
        def get_activity_chart():
            response = requests.get(f"{BASE_URL}/analytics/activity-chart", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
        
        self.test("Get Activity Chart", get_activity_chart)
    
    def test_notifications_flow(self):
        """Test notifications"""
        print_header("Notifications Flow")
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        def get_notifications():
            response = requests.get(f"{BASE_URL}/notifications/", headers=headers)
            assert response.status_code == 200, f"Status: {response.status_code}"
        
        self.test("Get Notifications", get_notifications)
    
    def run_all_tests(self):
        """Run complete integration test suite"""
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}Memory Hub - Integration Test Suite{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}Testing Frontend-Backend Communication{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}")
        
        self.register_and_login()
        self.test_memories_flow()
        self.test_collections_flow()
        self.test_social_flow()
        self.test_dashboard_flow()
        self.test_analytics_flow()
        self.test_notifications_flow()
        
        # Summary
        total = self.passed + self.failed
        success_rate = (self.passed / total * 100) if total > 0 else 0
        
        print(f"\n{Colors.BOLD}{'='*60}{Colors.END}")
        print(f"{Colors.BOLD}Test Suite Complete{Colors.END}")
        print(f"{Colors.BOLD}{'='*60}{Colors.END}")
        print(f"Total Tests: {total}")
        print(f"{Colors.GREEN}Passed: {self.passed}{Colors.END}")
        print(f"{Colors.RED}Failed: {self.failed}{Colors.END}")
        print(f"Success Rate: {success_rate:.1f}%")
        print(f"{'='*60}\n")
        
        return self.failed == 0

if __name__ == "__main__":
    tester = IntegrationTester()
    success = tester.run_all_tests()
    exit(0 if success else 1)
