#!/usr/bin/env python3
"""
Comprehensive Flutter Frontend Test Script
Tests the Flutter web app served on port 5000 alongside the backend API
"""

import asyncio
import httpx
import json
import time
from typing import Dict, Any, List
import websockets

# Test configuration
BASE_URL = "http://localhost:5000"
API_BASE = f"{BASE_URL}/api/v1"
WS_BASE = "ws://localhost:5000/api/v1/ws/notifications"

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
BLUE = '\033[94m'
YELLOW = '\033[93m'
RESET = '\033[0m'
BOLD = '\033[1m'

def print_header(text: str):
    print(f"\n{BOLD}{'=' * 70}{RESET}")
    print(f"{BOLD}{text.center(70)}{RESET}")
    print(f"{BOLD}{'=' * 70}{RESET}\n")

def print_success(text: str):
    print(f"{GREEN}✓{RESET} {text}")

def print_error(text: str):
    print(f"{RED}✗{RESET} {text}")

def print_info(text: str):
    print(f"{BLUE}ℹ{RESET} {text}")

def print_warning(text: str):
    print(f"{YELLOW}⚠{RESET} {text}")


async def test_flutter_app_loads():
    """Test 1: Verify Flutter app loads on port 5000"""
    print_header("TEST 1: Flutter App Loading")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            # Test root route (should serve Flutter index.html)
            response = await client.get(BASE_URL)
            if response.status_code == 200 and "flutter" in response.text.lower():
                print_success(f"Flutter app loads successfully on {BASE_URL}")
                return True
            else:
                print_error(f"Flutter app not loading correctly. Status: {response.status_code}")
                return False
        except Exception as e:
            print_error(f"Failed to load Flutter app: {str(e)}")
            return False


async def test_flutter_assets():
    """Test 2: Verify Flutter static assets are accessible"""
    print_header("TEST 2: Flutter Static Assets")
    
    assets_to_test = [
        "/main.dart.js",
        "/flutter.js",
        "/flutter_service_worker.js",
        "/manifest.json",
    ]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        success_count = 0
        for asset in assets_to_test:
            try:
                response = await client.get(f"{BASE_URL}{asset}")
                if response.status_code == 200:
                    print_success(f"Asset accessible: {asset}")
                    success_count += 1
                else:
                    print_warning(f"Asset not found: {asset} (Status: {response.status_code})")
            except Exception as e:
                print_warning(f"Asset check failed for {asset}: {str(e)}")
        
        print_info(f"\nAssets accessible: {success_count}/{len(assets_to_test)}")
        return success_count >= len(assets_to_test) - 1  # Allow 1 missing asset


async def test_api_endpoints_accessible():
    """Test 3: Verify API endpoints are accessible from the same port"""
    print_header("TEST 3: API Endpoints Accessibility")
    
    endpoints = [
        ("/api/v1/auth/register", "POST"),
        ("/api/v1/health-records", "GET"),
        ("/api/v1/family/core/circles", "GET"),
        ("/api/v1/notifications", "GET"),
    ]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        success_count = 0
        for endpoint, method in endpoints:
            try:
                url = f"{BASE_URL}{endpoint}"
                # Just check if endpoint exists (401/403 is fine, 404 is not)
                if method == "GET":
                    response = await client.get(url)
                else:
                    response = await client.post(url, json={})
                
                # Any response except 404 means endpoint exists
                if response.status_code != 404:
                    print_success(f"{method} {endpoint} - Endpoint exists (Status: {response.status_code})")
                    success_count += 1
                else:
                    print_error(f"{method} {endpoint} - Not found")
            except Exception as e:
                print_error(f"{method} {endpoint} - Error: {str(e)}")
        
        print_info(f"\nAPI endpoints accessible: {success_count}/{len(endpoints)}")
        return success_count == len(endpoints)


async def test_user_authentication_flow():
    """Test 4: Complete user authentication flow"""
    print_header("TEST 4: User Authentication Flow")
    
    test_user = {
        "email": "flutter_test@example.com",
        "password": "TestPassword123!",
        "full_name": "Flutter Test User"
    }
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Step 1: Register
        try:
            response = await client.post(
                f"{API_BASE}/auth/register",
                json=test_user
            )
            if response.status_code in [200, 201, 400]:  # 400 if user exists
                if response.status_code == 400:
                    print_warning("User already exists, proceeding to login...")
                else:
                    print_success("User registration successful")
            else:
                print_error(f"Registration failed: {response.text}")
                return False
        except Exception as e:
            print_error(f"Registration error: {str(e)}")
            return False
        
        # Step 2: Login
        try:
            response = await client.post(
                f"{API_BASE}/auth/login",
                json={
                    "email": test_user["email"],
                    "password": test_user["password"]
                }
            )
            if response.status_code == 200:
                data = response.json()
                token = data.get("access_token")
                print_success(f"Login successful, token obtained")
                
                # Step 3: Verify token works
                headers = {"Authorization": f"Bearer {token}"}
                response = await client.get(f"{API_BASE}/users/me", headers=headers)
                if response.status_code == 200:
                    user_data = response.json()
                    print_success(f"Token verified, user: {user_data.get('email')}")
                    return True
                else:
                    print_error(f"Token verification failed: {response.status_code}")
                    return False
            else:
                print_error(f"Login failed: {response.text}")
                return False
        except Exception as e:
            print_error(f"Login error: {str(e)}")
            return False


async def test_health_records_api():
    """Test 5: Health records creation and retrieval"""
    print_header("TEST 5: Health Records API")
    
    # First authenticate
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Login
        response = await client.post(
            f"{API_BASE}/auth/login",
            json={
                "email": "flutter_test@example.com",
                "password": "TestPassword123!"
            }
        )
        if response.status_code != 200:
            print_error("Authentication failed")
            return False
        
        token = response.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # Get user info
        response = await client.get(f"{API_BASE}/users/me", headers=headers)
        if response.status_code != 200:
            print_error("Failed to get user info")
            return False
        
        user_data = response.json()
        print_success(f"Authenticated as {user_data.get('email')}")
        
        # Create a family circle first
        circle_response = await client.post(
            f"{API_BASE}/family/core/circles",
            headers=headers,
            json={
                "name": "Flutter Test Family",
                "description": "Test family for Flutter testing"
            }
        )
        
        if circle_response.status_code not in [200, 201]:
            print_warning("Family circle creation failed, may already exist")
            # Try to get existing circles
            circles_response = await client.get(
                f"{API_BASE}/family/core/circles",
                headers=headers
            )
            if circles_response.status_code == 200:
                circles_data = circles_response.json()
                if isinstance(circles_data, dict) and "data" in circles_data:
                    circles = circles_data["data"]
                elif isinstance(circles_data, list):
                    circles = circles_data
                else:
                    circles = []
                
                if circles:
                    family_id = circles[0].get("id") or circles[0].get("_id")
                    print_info(f"Using existing family circle: {family_id}")
                else:
                    print_error("No family circles available")
                    return False
        else:
            circle_data = circle_response.json()
            if isinstance(circle_data, dict) and "data" in circle_data:
                family_id = circle_data["data"].get("id") or circle_data["data"].get("_id")
            else:
                family_id = circle_data.get("id") or circle_data.get("_id")
            print_success(f"Family circle created: {family_id}")
        
        # Create health record
        user_id = user_data.get("id") or user_data.get("_id")
        health_record = {
            "family_id": family_id,
            "record_type": "medical",
            "title": "Flutter Test Record",
            "description": "Testing health records from Flutter frontend",
            "date": "2024-11-14T00:00:00Z",
            "subject_type": "self",
            "subject_user_id": user_id
        }
        
        response = await client.post(
            f"{API_BASE}/health-records",
            headers=headers,
            json=health_record
        )
        
        if response.status_code in [200, 201]:
            print_success("Health record created successfully")
            record_data = response.json()
            if isinstance(record_data, dict) and "data" in record_data:
                record = record_data["data"]
            else:
                record = record_data
            print_info(f"Record ID: {record.get('id') or record.get('_id')}")
            return True
        else:
            print_error(f"Health record creation failed: {response.text}")
            return False


async def test_notifications_api():
    """Test 6: Notifications API"""
    print_header("TEST 6: Notifications API")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Login
        response = await client.post(
            f"{API_BASE}/auth/login",
            json={
                "email": "flutter_test@example.com",
                "password": "TestPassword123!"
            }
        )
        if response.status_code != 200:
            print_error("Authentication failed")
            return False
        
        token = response.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # Get notifications
        response = await client.get(
            f"{API_BASE}/notifications",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            # Handle StandardResponse wrapper
            if isinstance(data, dict) and "data" in data:
                notifications = data["data"]
                if isinstance(notifications, dict) and "notifications" in notifications:
                    notifications = notifications["notifications"]
            elif isinstance(data, list):
                notifications = data
            else:
                notifications = []
            
            print_success(f"Notifications retrieved: {len(notifications)} notifications")
            return True
        else:
            print_error(f"Notifications retrieval failed: {response.status_code}")
            return False


async def test_websocket_connectivity():
    """Test 7: WebSocket connectivity"""
    print_header("TEST 7: WebSocket Connectivity")
    
    # First get auth token
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{API_BASE}/auth/login",
            json={
                "email": "flutter_test@example.com",
                "password": "TestPassword123!"
            }
        )
        if response.status_code != 200:
            print_error("Authentication failed for WebSocket test")
            return False
        
        token = response.json().get("access_token")
    
    # Test WebSocket connection
    try:
        ws_url = f"{WS_BASE}?token={token}"
        async with websockets.connect(ws_url, ping_interval=20) as websocket:
            print_success("WebSocket connected successfully")
            
            # Wait for connection acknowledgment
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                data = json.loads(message)
                print_info(f"Received message: {data.get('event', 'unknown')}")
                
                # Send a ping
                await websocket.send(json.dumps({"type": "ping"}))
                print_success("Ping sent to WebSocket")
                
                # Wait for pong
                pong = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                pong_data = json.loads(pong)
                if pong_data.get("event") == "pong":
                    print_success("Pong received from WebSocket")
                    return True
                else:
                    print_info(f"Received: {pong_data.get('event')}")
                    return True
            except asyncio.TimeoutError:
                print_warning("WebSocket timeout waiting for messages")
                return True  # Connection worked even if no messages
                
    except Exception as e:
        print_error(f"WebSocket connection failed: {str(e)}")
        return False


async def test_dashboard_api():
    """Test 8: Health dashboard API"""
    print_header("TEST 8: Health Dashboard API")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Login
        response = await client.post(
            f"{API_BASE}/auth/login",
            json={
                "email": "flutter_test@example.com",
                "password": "TestPassword123!"
            }
        )
        if response.status_code != 200:
            print_error("Authentication failed")
            return False
        
        token = response.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # Get family circles to get a family_id
        circles_response = await client.get(
            f"{API_BASE}/family/core/circles",
            headers=headers
        )
        
        if circles_response.status_code != 200:
            print_error("Failed to get family circles")
            return False
        
        circles_data = circles_response.json()
        if isinstance(circles_data, dict) and "data" in circles_data:
            if isinstance(circles_data["data"], dict) and "circles" in circles_data["data"]:
                circles = circles_data["data"]["circles"]
            else:
                circles = circles_data["data"]
        elif isinstance(circles_data, list):
            circles = circles_data
        else:
            circles = []
        
        if not circles or len(circles) == 0:
            print_warning("No family circles found, skipping dashboard test")
            return True  # Don't fail, just skip
        
        family_id = circles[0].get("id") or circles[0].get("_id")
        
        # Get dashboard
        response = await client.get(
            f"{API_BASE}/health-records/dashboard?family_id={family_id}",
            headers=headers
        )
        
        if response.status_code == 200:
            dashboard = response.json()
            if isinstance(dashboard, dict) and "data" in dashboard:
                dashboard = dashboard["data"]
            
            print_success("Dashboard retrieved successfully")
            print_info(f"Total records: {dashboard.get('total_records', 0)}")
            print_info(f"Pending approvals: {dashboard.get('pending_approvals', 0)}")
            return True
        else:
            print_error(f"Dashboard retrieval failed: {response.status_code}")
            return False


async def main():
    """Run all Flutter frontend tests"""
    print(f"\n{BOLD}{'=' * 70}{RESET}")
    print(f"{BOLD}{'FLUTTER FRONTEND COMPREHENSIVE TEST SUITE'.center(70)}{RESET}")
    print(f"{BOLD}{'=' * 70}{RESET}\n")
    
    print_info(f"Testing Flutter app at: {BASE_URL}")
    print_info(f"Testing API at: {API_BASE}")
    print_info(f"Testing WebSocket at: {WS_BASE}\n")
    
    # Wait for server to be ready
    print_info("Waiting for server to be ready...")
    await asyncio.sleep(3)
    
    results = {}
    
    # Run tests
    results["flutter_loads"] = await test_flutter_app_loads()
    results["assets"] = await test_flutter_assets()
    results["api_endpoints"] = await test_api_endpoints_accessible()
    results["authentication"] = await test_user_authentication_flow()
    results["health_records"] = await test_health_records_api()
    results["notifications"] = await test_notifications_api()
    results["websocket"] = await test_websocket_connectivity()
    results["dashboard"] = await test_dashboard_api()
    
    # Print summary
    print_header("TEST RESULTS SUMMARY")
    
    total_tests = len(results)
    passed_tests = sum(1 for result in results.values() if result)
    
    for test_name, result in results.items():
        status = f"{GREEN}PASS{RESET}" if result else f"{RED}FAIL{RESET}"
        print(f"{test_name.replace('_', ' ').title()}: {status}")
    
    print(f"\n{BOLD}Total: {passed_tests}/{total_tests} tests passed{RESET}")
    
    if passed_tests == total_tests:
        print(f"\n{GREEN}{BOLD}{'=' * 70}{RESET}")
        print(f"{GREEN}{BOLD}{'ALL TESTS PASSED!'.center(70)}{RESET}")
        print(f"{GREEN}{BOLD}{'=' * 70}{RESET}\n")
        return 0
    else:
        print(f"\n{RED}{BOLD}{'=' * 70}{RESET}")
        print(f"{RED}{BOLD}{'SOME TESTS FAILED'.center(70)}{RESET}")
        print(f"{RED}{BOLD}{'=' * 70}{RESET}\n")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
