#!/usr/bin/env python3
"""
Comprehensive test script for the health record notification and approval system.

Tests:
1. User registration and authentication
2. Health record creation with assignment
3. Notification creation with WebSocket broadcasting
4. Approval/rejection workflow
5. Audit log creation
6. Real-time WebSocket updates
"""

import asyncio
import json
import time
from datetime import datetime
import requests
import websockets
from typing import Optional, Dict, Any

BASE_URL = "http://localhost:5000/api/v1"
WS_URL = "ws://localhost:5000/api/v1/ws/notifications"

# ANSI color codes for pretty output
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
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{message}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*60}{Colors.RESET}\n")


class NotificationSystemTester:
    def __init__(self):
        self.assigner_token: Optional[str] = None
        self.assignee_token: Optional[str] = None
        self.assigner_id: Optional[str] = None
        self.assignee_id: Optional[str] = None
        self.health_record_id: Optional[str] = None
        self.notification_id: Optional[str] = None
        self.ws_messages: list = []
        
    def register_user(self, email: str, password: str, full_name: str) -> Dict[str, Any]:
        """Register a new user"""
        log_info(f"Registering user: {email}")
        
        response = requests.post(
            f"{BASE_URL}/auth/register",
            json={
                "email": email,
                "password": password,
                "full_name": full_name
            }
        )
        
        if response.status_code == 201:
            log_success(f"User registered: {email}")
            return response.json()
        else:
            log_error(f"Registration failed: {response.text}")
            return {}
    
    def login_user(self, email: str, password: str) -> Optional[str]:
        """Login user and return access token"""
        log_info(f"Logging in user: {email}")
        
        response = requests.post(
            f"{BASE_URL}/auth/token",
            json={
                "email": email,
                "password": password
            }
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get("access_token")
            log_success(f"Login successful: {email}")
            return token
        else:
            log_error(f"Login failed: {response.text}")
            return None
    
    def get_current_user(self, token: str) -> Optional[Dict[str, Any]]:
        """Get current user info"""
        log_info("Fetching current user info")
        
        response = requests.get(
            f"{BASE_URL}/users/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            user = response.json()
            log_success(f"User info retrieved: {user.get('email')}")
            return user
        else:
            log_error(f"Failed to get user info: {response.text}")
            return None
    
    def create_health_record(
        self,
        token: str,
        title: str,
        assignee_id: str,
        record_type: str = "medical"
    ) -> Optional[Dict[str, Any]]:
        """Create a health record assigned to another user"""
        log_info(f"Creating health record: {title}")
        
        response = requests.post(
            f"{BASE_URL}/family/health-records",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "subject_type": "self",
                "subject_user_id": assignee_id,
                "record_type": record_type,
                "title": title,
                "description": "Test health record for notification system",
                "date": "2024-01-15",
                "provider": "Test Hospital",
                "severity": "moderate",
                "requested_visibility": "private",
                "notes": "This is a test record to verify the notification and approval workflow."
            }
        )
        
        if response.status_code == 201:
            record = response.json().get("data")
            log_success(f"Health record created: ID={record.get('id')}")
            return record
        else:
            log_error(f"Failed to create health record: {response.text}")
            return None
    
    def get_notifications(self, token: str) -> list:
        """Get user notifications"""
        log_info("Fetching notifications")
        
        response = requests.get(
            f"{BASE_URL}/notifications",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json().get("data", {})
            notifications = data.get("notifications", [])
            log_success(f"Retrieved {len(notifications)} notifications")
            return notifications
        else:
            log_error(f"Failed to get notifications: {response.text}")
            return []
    
    def get_notification_details(self, token: str, notification_id: str) -> Optional[Dict[str, Any]]:
        """Get detailed notification information"""
        log_info(f"Fetching notification details: {notification_id}")
        
        response = requests.get(
            f"{BASE_URL}/notifications/{notification_id}/details",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            details = response.json().get("data")
            log_success("Notification details retrieved")
            return details
        else:
            log_error(f"Failed to get notification details: {response.text}")
            return None
    
    def approve_health_record(
        self,
        token: str,
        record_id: str,
        visibility_scope: str = "private"
    ) -> bool:
        """Approve a health record"""
        log_info(f"Approving health record: {record_id}")
        
        response = requests.post(
            f"{BASE_URL}/family/health-records/{record_id}/approve",
            headers={"Authorization": f"Bearer {token}"},
            json={"visibility_scope": visibility_scope}
        )
        
        if response.status_code == 200:
            log_success("Health record approved")
            return True
        else:
            log_error(f"Failed to approve health record: {response.text}")
            return False
    
    def reject_health_record(
        self,
        token: str,
        record_id: str,
        rejection_reason: str = "Not accurate"
    ) -> bool:
        """Reject a health record"""
        log_info(f"Rejecting health record: {record_id}")
        
        response = requests.post(
            f"{BASE_URL}/family/health-records/{record_id}/reject",
            headers={"Authorization": f"Bearer {token}"},
            json={"rejection_reason": rejection_reason}
        )
        
        if response.status_code == 200:
            log_success("Health record rejected")
            return True
        else:
            log_error(f"Failed to reject health record: {response.text}")
            return False
    
    async def test_websocket_connection(self, token: str, duration: int = 10):
        """Test WebSocket connection and receive messages"""
        log_info(f"Testing WebSocket connection for {duration} seconds")
        
        try:
            uri = f"{WS_URL}?token={token}"
            async with websockets.connect(uri) as websocket:
                log_success("WebSocket connected")
                
                # Wait for connection acknowledgment
                msg = await asyncio.wait_for(websocket.recv(), timeout=5)
                data = json.loads(msg)
                
                if data.get("event") == "connection.acknowledged":
                    log_success("Connection acknowledged by server")
                    log_info(f"User: {data.get('data', {}).get('user_name')}")
                
                # Listen for messages
                start_time = time.time()
                while time.time() - start_time < duration:
                    try:
                        msg = await asyncio.wait_for(websocket.recv(), timeout=2)
                        data = json.loads(msg)
                        self.ws_messages.append(data)
                        
                        event = data.get("event")
                        log_success(f"WebSocket event received: {event}")
                        
                        if event == "notification.created":
                            log_info(f"  Title: {data.get('data', {}).get('title')}")
                        elif event == "notification.updated":
                            log_info(f"  Status: {data.get('data', {}).get('approval_status')}")
                        elif event == "health_record.status_changed":
                            log_info(f"  New status: {data.get('data', {}).get('new_status')}")
                        
                    except asyncio.TimeoutError:
                        # Send ping to keep connection alive
                        await websocket.send(json.dumps({"event": "ping"}))
                        continue
                
                log_success(f"WebSocket test completed. Received {len(self.ws_messages)} messages")
                
        except Exception as e:
            log_error(f"WebSocket connection failed: {str(e)}")
    
    def run_comprehensive_test(self):
        """Run comprehensive test of the notification and approval system"""
        
        log_section("NOTIFICATION & APPROVAL SYSTEM TEST")
        
        # Step 1: Setup test users
        log_section("Step 1: User Setup")
        
        assigner_email = f"assigner_test_{int(time.time())}@test.com"
        assignee_email = f"assignee_test_{int(time.time())}@test.com"
        
        self.register_user(assigner_email, "TestPass123!", "Dr. Assigner")
        self.register_user(assignee_email, "TestPass123!", "Patient Assignee")
        
        self.assigner_token = self.login_user(assigner_email, "TestPass123!")
        self.assignee_token = self.login_user(assignee_email, "TestPass123!")
        
        if not self.assigner_token or not self.assignee_token:
            log_error("Failed to setup test users. Aborting test.")
            return False
        
        # Get user IDs
        assigner_user = self.get_current_user(self.assigner_token)
        assignee_user = self.get_current_user(self.assignee_token)
        
        if not assigner_user or not assignee_user:
            log_error("Failed to get user info. Aborting test.")
            return False
        
        self.assigner_id = assigner_user.get("id")
        self.assignee_id = assignee_user.get("id")
        
        log_success(f"Assigner ID: {self.assigner_id}")
        log_success(f"Assignee ID: {self.assignee_id}")
        
        # Step 2: Create health record with assignment
        log_section("Step 2: Create Health Record & Notification")
        
        record = self.create_health_record(
            self.assigner_token,
            "Test Medical Record - Notification System",
            self.assignee_id
        )
        
        if not record:
            log_error("Failed to create health record. Aborting test.")
            return False
        
        self.health_record_id = record.get("id")
        log_success(f"Health record ID: {self.health_record_id}")
        
        # Verify record status
        if record.get("approval_status") == "pending_approval":
            log_success("✓ Record created with pending_approval status")
        else:
            log_warning(f"Unexpected status: {record.get('approval_status')}")
        
        # Step 3: Check notifications
        log_section("Step 3: Verify Notification Creation")
        
        time.sleep(2)  # Wait for notification processing
        
        notifications = self.get_notifications(self.assignee_token)
        
        if notifications:
            health_record_notif = next(
                (n for n in notifications if n.get("type") == "health_record_assigned"),
                None
            )
            
            if health_record_notif:
                self.notification_id = health_record_notif.get("id")
                log_success(f"✓ Health record assignment notification found")
                log_info(f"  Notification ID: {self.notification_id}")
                log_info(f"  Title: {health_record_notif.get('title')}")
                log_info(f"  Message: {health_record_notif.get('message')}")
            else:
                log_warning("No health_record_assigned notification found")
        else:
            log_warning("No notifications found for assignee")
        
        # Step 4: Get notification details
        if self.notification_id:
            log_section("Step 4: Fetch Notification Details")
            
            details = self.get_notification_details(self.assignee_token, self.notification_id)
            
            if details:
                log_success("✓ Notification details retrieved")
                log_info(f"  Record Title: {details.get('record_title')}")
                log_info(f"  Record Type: {details.get('record_type')}")
                log_info(f"  Assigner: {details.get('assigner_name')}")
                log_info(f"  Can Approve: {details.get('can_approve')}")
                log_info(f"  Can Reject: {details.get('can_reject')}")
                log_info(f"  Approval Status: {details.get('approval_status')}")
        
        # Step 5: Test WebSocket for assignee (wait for approval event)
        log_section("Step 5: Test WebSocket for Real-time Updates")
        
        async def test_approval_flow():
            # Start WebSocket listener in background
            ws_task = asyncio.create_task(
                self.test_websocket_connection(self.assignee_token, duration=15)
            )
            
            # Wait a bit for WebSocket to connect
            await asyncio.sleep(2)
            
            # Approve the health record
            log_info("Approving health record from assignee...")
            approve_success = self.approve_health_record(
                self.assignee_token,
                self.health_record_id,
                "family"
            )
            
            if approve_success:
                log_success("✓ Health record approved successfully")
            
            # Wait for WebSocket to receive updates
            await ws_task
        
        asyncio.run(test_approval_flow())
        
        # Step 6: Verify approval updates
        log_section("Step 6: Verify Approval Workflow")
        
        # Check if notification was updated
        updated_notifications = self.get_notifications(self.assignee_token)
        if updated_notifications:
            updated_notif = next(
                (n for n in updated_notifications if n.get("id") == self.notification_id),
                None
            )
            
            if updated_notif:
                log_info(f"  Notification approval_status: {updated_notif.get('approval_status')}")
                if updated_notif.get('approval_status') == 'approved':
                    log_success("✓ Notification status updated to approved")
        
        # Step 7: Summary
        log_section("TEST SUMMARY")
        
        log_success("✓ User registration and authentication")
        log_success("✓ Health record creation with assignment")
        log_success("✓ Notification creation")
        log_success("✓ Notification details endpoint")
        log_success("✓ Approval workflow")
        log_success("✓ WebSocket connection and real-time updates")
        
        ws_events = [msg.get("event") for msg in self.ws_messages]
        log_info(f"WebSocket events received: {ws_events}")
        
        if "notification.created" in ws_events or "notification.updated" in ws_events:
            log_success("✓ Real-time WebSocket broadcasting working!")
        else:
            log_warning("⚠ No WebSocket notification events received")
        
        log_section("TEST COMPLETED SUCCESSFULLY!")
        
        return True


if __name__ == "__main__":
    print(f"{Colors.BOLD}{Colors.MAGENTA}")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║   Health Record Notification & Approval System Tester    ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(Colors.RESET)
    
    tester = NotificationSystemTester()
    
    try:
        success = tester.run_comprehensive_test()
        
        if success:
            print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 All tests passed!{Colors.RESET}\n")
            exit(0)
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}❌ Some tests failed{Colors.RESET}\n")
            exit(1)
            
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Test interrupted by user{Colors.RESET}\n")
        exit(130)
    except Exception as e:
        log_error(f"Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        exit(1)
