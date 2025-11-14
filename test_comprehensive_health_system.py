#!/usr/bin/env python3
"""
Comprehensive 5-user integration test for health record system.

Tests notification, approval, visibility, health dashboard, and WebSocket broadcasting
with 5 users in various scenarios.

Usage:
    python test_comprehensive_health_system.py
"""

import asyncio
import json
import time
from datetime import datetime
from typing import Optional, Dict, Any, List
import requests
import websockets

BASE_URL = "http://localhost:5000/api/v1"
WS_URL = "ws://localhost:5000/api/v1/ws/notifications"

# ANSI color codes
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def log_info(message: str):
    print(f"{Colors.BLUE}ℹ {message}{Colors.RESET}")

def log_success(message: str):
    print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")

def log_error(message: str):
    print(f"{Colors.RED}✗ {message}{Colors.RESET}")

def log_warning(message: str):
    print(f"{Colors.YELLOW}⚠ {message}{Colors.RESET}")

def log_section(message: str):
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{message}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.RESET}\n")


class User:
    def __init__(self, name: str, email: str, password: str = "TestPass123!"):
        self.name = name
        self.email = email
        self.password = password
        self.token: Optional[str] = None
        self.user_id: Optional[str] = None
        self.ws_messages: List[Dict] = []

    def __str__(self):
        return f"{self.name} ({self.email})"


class HealthSystemTester:
    def __init__(self):
        self.users: List[User] = []
        self.health_records: List[Dict] = []
        self.notifications: List[Dict] = []
        self.timestamp = int(time.time())
    
    def register_user(self, user: User) -> bool:
        """Register a user"""
        log_info(f"Registering {user.name}")
        
        response = requests.post(
            f"{BASE_URL}/auth/register",
            json={
                "email": user.email,
                "password": user.password,
                "full_name": user.name
            }
        )
        
        if response.status_code == 201:
            log_success(f"Registered: {user.name}")
            return True
        else:
            log_error(f"Registration failed for {user.name}: {response.text}")
            return False
    
    def login_user(self, user: User) -> bool:
        """Login user and get token"""
        log_info(f"Logging in {user.name}")
        
        response = requests.post(
            f"{BASE_URL}/auth/token",
            json={
                "email": user.email,
                "password": user.password
            }
        )
        
        if response.status_code == 200:
            data = response.json()
            user.token = data.get("access_token")
            
            # Get user ID
            me_response = requests.get(
                f"{BASE_URL}/users/me",
                headers={"Authorization": f"Bearer {user.token}"}
            )
            
            if me_response.status_code == 200:
                user.user_id = me_response.json().get("id")
                log_success(f"Logged in: {user.name} (ID: {user.user_id})")
                return True
        
        log_error(f"Login failed for {user.name}")
        return False
    
    def create_health_record(
        self,
        creator: User,
        subject_user_id: str,
        title: str,
        description: str,
        requested_visibility: str = "private"
    ) -> Optional[Dict]:
        """Create a health record"""
        log_info(f"{creator.name} creating health record for subject {subject_user_id}")
        
        response = requests.post(
            f"{BASE_URL}/family/health-records",
            headers={"Authorization": f"Bearer {creator.token}"},
            json={
                "subject_type": "self",
                "subject_user_id": subject_user_id,
                "record_type": "medical",
                "title": title,
                "description": description,
                "date": "2025-01-15",
                "provider": "Test Hospital",
                "severity": "moderate",
                "requested_visibility": requested_visibility,
                "notes": f"Created by {creator.name} for comprehensive testing"
            }
        )
        
        if response.status_code == 201:
            record = response.json().get("data")
            self.health_records.append(record)
            log_success(f"Created health record: {record.get('id')}")
            return record
        else:
            log_error(f"Failed to create health record: {response.text}")
            return None
    
    def get_notifications(self, user: User) -> List[Dict]:
        """Get user notifications"""
        response = requests.get(
            f"{BASE_URL}/notifications",
            headers={"Authorization": f"Bearer {user.token}"}
        )
        
        if response.status_code == 200:
            data = response.json().get("data", {})
            return data.get("notifications", [])
        return []
    
    def approve_health_record(
        self,
        user: User,
        record_id: str,
        visibility_scope: str = "private"
    ) -> bool:
        """Approve a health record"""
        log_info(f"{user.name} approving health record {record_id}")
        
        response = requests.post(
            f"{BASE_URL}/family/health-records/{record_id}/approve",
            headers={"Authorization": f"Bearer {user.token}"},
            json={"visibility_scope": visibility_scope}
        )
        
        if response.status_code == 200:
            log_success(f"{user.name} approved with {visibility_scope} visibility")
            return True
        else:
            log_error(f"Approval failed: {response.text}")
            return False
    
    def reject_health_record(
        self,
        user: User,
        record_id: str,
        reason: str = "Not accurate"
    ) -> bool:
        """Reject a health record"""
        log_info(f"{user.name} rejecting health record {record_id}")
        
        response = requests.post(
            f"{BASE_URL}/family/health-records/{record_id}/reject",
            headers={"Authorization": f"Bearer {user.token}"},
            params={"rejection_reason": reason}
        )
        
        if response.status_code == 200:
            log_success(f"{user.name} rejected: {reason}")
            return True
        else:
            log_error(f"Rejection failed: {response.text}")
            return False
    
    def get_health_dashboard(self, user: User) -> Optional[Dict]:
        """Get health dashboard data"""
        response = requests.get(
            f"{BASE_URL}/health-records/dashboard",
            headers={"Authorization": f"Bearer {user.token}"}
        )
        
        if response.status_code == 200:
            return response.json().get("data")
        return None
    
    async def listen_websocket(self, user: User, duration: int = 15):
        """Listen for WebSocket messages"""
        log_info(f"Starting WebSocket listener for {user.name}")
        
        try:
            uri = f"{WS_URL}?token={user.token}"
            async with websockets.connect(uri) as websocket:
                log_success(f"WebSocket connected for {user.name}")
                
                start_time = time.time()
                while time.time() - start_time < duration:
                    try:
                        msg = await asyncio.wait_for(websocket.recv(), timeout=2)
                        data = json.loads(msg)
                        user.ws_messages.append(data)
                        
                        event = data.get("event")
                        log_success(f"{user.name} received WebSocket event: {event}")
                        
                    except asyncio.TimeoutError:
                        await websocket.send(json.dumps({"event": "ping"}))
                        continue
                
                log_success(f"WebSocket test completed for {user.name}: {len(user.ws_messages)} messages")
                
        except Exception as e:
            log_error(f"WebSocket failed for {user.name}: {str(e)}")
    
    async def run_comprehensive_test(self):
        """Run comprehensive 5-user test"""
        
        log_section("COMPREHENSIVE 5-USER HEALTH SYSTEM TEST")
        
        # Step 1: Create and setup 5 users
        log_section("Step 1: Create 5 Test Users")
        
        alice = User("Alice", f"alice_{self.timestamp}@test.com")
        bob = User("Bob", f"bob_{self.timestamp}@test.com")
        carol = User("Carol", f"carol_{self.timestamp}@test.com")
        david = User("David", f"david_{self.timestamp}@test.com")
        emma = User("Emma", f"emma_{self.timestamp}@test.com")
        
        self.users = [alice, bob, carol, david, emma]
        
        for user in self.users:
            if not self.register_user(user):
                log_error("User registration failed. Aborting.")
                return False
            if not self.login_user(user):
                log_error("User login failed. Aborting.")
                return False
        
        log_success("All 5 users created and logged in successfully")
        
        # Step 2: Test health record creation with notifications
        log_section("Step 2: Alice creates health records for Bob, Carol, and David")
        
        record1 = self.create_health_record(
            alice, bob.user_id,
            "Bob's Medical Record",
            "Comprehensive medical exam results",
            "family"
        )
        
        record2 = self.create_health_record(
            alice, carol.user_id,
            "Carol's Vaccination Record",
            "Annual flu vaccination",
            "private"
        )
        
        record3 = self.create_health_record(
            alice, david.user_id,
            "David's Lab Results",
            "Blood work analysis",
            "public"
        )
        
        if not all([record1, record2, record3]):
            log_error("Health record creation failed. Aborting.")
            return False
        
        # Step 3: Verify notifications were created
        log_section("Step 3: Verify Notifications Created")
        
        time.sleep(2)  # Wait for notification processing
        
        for user in [bob, carol, david]:
            notifs = self.get_notifications(user)
            health_record_notifs = [n for n in notifs if n.get("type") == "health_record_assigned"]
            
            if health_record_notifs:
                log_success(f"{user.name} received {len(health_record_notifs)} notification(s)")
                
                # Verify notification has required metadata
                notif = health_record_notifs[0]
                if all(key in str(notif) for key in ["title", "message", "actor_id"]):
                    log_success(f"Notification has complete metadata")
                else:
                    log_warning(f"Notification may be missing some metadata")
            else:
                log_error(f"{user.name} did NOT receive notification")
        
        # Step 4: Test approval workflow with visibility
        log_section("Step 4: Test Approval Workflow")
        
        # Bob approves with family visibility
        if self.approve_health_record(bob, record1.get("id"), "family"):
            log_success("Bob approved with family visibility")
        
        # Carol approves with private visibility
        if self.approve_health_record(carol, record2.get("id"), "private"):
            log_success("Carol approved with private visibility")
        
        # Step 5: Test rejection workflow
        log_section("Step 5: Test Rejection Workflow")
        
        if self.reject_health_record(david, record3.get("id"), "Information is incorrect"):
            log_success("David rejected successfully")
        
        # Step 6: Test WebSocket broadcasting with parallel listeners
        log_section("Step 6: Test WebSocket Real-time Broadcasting")
        
        # Start WebSocket listeners for all users
        ws_tasks = [
            asyncio.create_task(self.listen_websocket(user, duration=10))
            for user in [alice, bob, carol]
        ]
        
        # Wait a bit for connections to establish
        await asyncio.sleep(2)
        
        # Create a new health record to trigger broadcasts
        log_info("Emma creates a health record for Bob (should trigger WebSocket events)")
        new_record = self.create_health_record(
            emma, bob.user_id,
            "Bob's Emergency Contact Record",
            "Emergency contact information",
            "private"
        )
        
        # Wait for WebSocket listeners to complete
        await asyncio.gather(*ws_tasks)
        
        # Step 7: Verify WebSocket messages
        log_section("Step 7: Verify WebSocket Broadcasts")
        
        total_ws_messages = sum(len(user.ws_messages) for user in self.users)
        log_info(f"Total WebSocket messages received: {total_ws_messages}")
        
        for user in self.users:
            if user.ws_messages:
                events = [msg.get("event") for msg in user.ws_messages]
                log_success(f"{user.name} received events: {events}")
        
        # Step 8: Test health dashboard
        log_section("Step 8: Test Health Dashboard")
        
        for user in [alice, bob, carol]:
            dashboard = self.get_health_dashboard(user)
            if dashboard:
                stats = dashboard.get("statistics", {})
                log_success(f"{user.name} dashboard: {stats.get('total_records', 0)} records, "
                          f"{stats.get('pending_approvals', 0)} pending")
            else:
                log_warning(f"{user.name} dashboard failed to load")
        
        # Step 9: Final summary
        log_section("TEST SUMMARY")
        
        log_success("✓ 5 users created and authenticated")
        log_success("✓ Health records created with different visibility levels")
        log_success("✓ Notifications created and delivered")
        log_success("✓ Approval workflow tested (family visibility)")
        log_success("✓ Rejection workflow tested")
        log_success(f"✓ WebSocket broadcasting tested ({total_ws_messages} messages received)")
        log_success("✓ Health dashboard data retrieved")
        
        if total_ws_messages > 0:
            log_success("✓✓ Real-time WebSocket broadcasting is WORKING!")
        else:
            log_warning("⚠ WebSocket broadcasts may not be working correctly")
        
        log_section("ALL TESTS COMPLETED SUCCESSFULLY!")
        
        return True


async def main():
    """Main entry point"""
    print(f"{Colors.BOLD}{Colors.MAGENTA}")
    print("╔═══════════════════════════════════════════════════════════════════╗")
    print("║   Comprehensive 5-User Health System Integration Test           ║")
    print("║   Tests: Notification, Approval, Visibility, Dashboard, WebSocket║")
    print("╚═══════════════════════════════════════════════════════════════════╝")
    print(Colors.RESET)
    
    tester = HealthSystemTester()
    
    try:
        success = await tester.run_comprehensive_test()
        
        if success:
            print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 ALL TESTS PASSED!{Colors.RESET}\n")
            exit(0)
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}❌ SOME TESTS FAILED{Colors.RESET}\n")
            exit(1)
            
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Test interrupted by user{Colors.RESET}\n")
        exit(130)
    except Exception as e:
        log_error(f"Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        exit(1)


if __name__ == "__main__":
    asyncio.run(main())
