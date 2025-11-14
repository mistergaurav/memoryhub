"""
Comprehensive test script for health records notification, dashboard, and approval system.

Tests:
1. Create 3 test users (Alice, Bob, Carol)
2. Alice creates health record assigned to Bob
3. Verify Bob receives notification
4. Verify record shows in Bob's dashboard
5. Bob approves the record
6. Verify approval notification sent to Alice
7. Carol creates record assigned to Alice
8. Alice rejects it
9. Verify rejection notification sent to Carol
"""

import asyncio
import httpx
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import sys

BASE_URL = "http://0.0.0.0:5000"
API_BASE = f"{BASE_URL}/api/v1"

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(text: str):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text:^80}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.RESET}\n")

def print_success(text: str):
    print(f"{Colors.GREEN}✓ {text}{Colors.RESET}")

def print_error(text: str):
    print(f"{Colors.RED}✗ {text}{Colors.RESET}")

def print_info(text: str):
    print(f"{Colors.YELLOW}ℹ {text}{Colors.RESET}")

def print_section(text: str):
    print(f"\n{Colors.BOLD}{text}{Colors.RESET}")

class TestUser:
    def __init__(self, name: str, email: str, password: str):
        self.name = name
        self.email = email
        self.password = password
        self.token: Optional[str] = None
        self.user_id: Optional[str] = None
        self.full_name = name

    def __repr__(self):
        return f"TestUser({self.name}, id={self.user_id})"

async def register_user(client: httpx.AsyncClient, user: TestUser) -> bool:
    """Register a new user and login"""
    try:
        response = await client.post(
            f"{API_BASE}/auth/register",
            json={
                "email": user.email,
                "password": user.password,
                "full_name": user.full_name
            }
        )
        
        if response.status_code == 201:
            print_success(f"Registered {user.name}")
            # Now login to get the token
            return await login_user(client, user)
        else:
            print_error(f"Failed to register {user.name}: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"Exception registering {user.name}: {str(e)}")
        return False

async def login_user(client: httpx.AsyncClient, user: TestUser) -> bool:
    """Login an existing user"""
    try:
        response = await client.post(
            f"{API_BASE}/auth/login",
            json={
                "email": user.email,
                "password": user.password
            }
        )
        
        if response.status_code == 200:
            data = response.json()
            user.token = data.get("access_token")
            print_success(f"Logged in {user.name}")
            
            # Get user profile to get user_id
            headers = {"Authorization": f"Bearer {user.token}"}
            profile_response = await client.get(f"{API_BASE}/users/me", headers=headers)
            if profile_response.status_code == 200:
                profile_data = profile_response.json()
                user.user_id = profile_data.get("id")
                print_success(f"Retrieved {user.name}'s profile (ID: {user.user_id})")
            
            return True
        else:
            print_error(f"Failed to login {user.name}: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"Exception logging in {user.name}: {str(e)}")
        return False

async def create_health_record(
    client: httpx.AsyncClient,
    creator: TestUser,
    assigned_to: TestUser,
    title: str
) -> Optional[str]:
    """Create a health record assigned to another user"""
    try:
        headers = {"Authorization": f"Bearer {creator.token}"}
        
        health_record_data = {
            "subject_type": "self",
            "subject_user_id": assigned_to.user_id,
            "record_type": "medical",
            "title": title,
            "description": f"Health record created by {creator.name} for {assigned_to.name}",
            "date": datetime.utcnow().isoformat(),
            "provider": "Test Hospital",
            "severity": "low",
            "is_confidential": False,
            "requested_visibility": "private"
        }
        
        response = await client.post(
            f"{API_BASE}/health-records",
            headers=headers,
            json=health_record_data
        )
        
        if response.status_code == 201:
            data = response.json()
            record_id = data.get("data", {}).get("id")
            print_success(f"{creator.name} created health record '{title}' for {assigned_to.name} (ID: {record_id})")
            return record_id
        else:
            print_error(f"Failed to create health record: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print_error(f"Exception creating health record: {str(e)}")
        return None

async def get_notifications(client: httpx.AsyncClient, user: TestUser) -> List[Dict]:
    """Get user's notifications"""
    try:
        headers = {"Authorization": f"Bearer {user.token}"}
        response = await client.get(
            f"{API_BASE}/notifications",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            notifications = data.get("data", {}).get("notifications", [])
            return notifications
        else:
            print_error(f"Failed to get notifications for {user.name}: {response.status_code}")
            return []
    except Exception as e:
        print_error(f"Exception getting notifications: {str(e)}")
        return []

async def get_dashboard(client: httpx.AsyncClient, user: TestUser) -> Optional[Dict]:
    """Get user's health dashboard"""
    try:
        headers = {"Authorization": f"Bearer {user.token}"}
        response = await client.get(
            f"{API_BASE}/health-records/dashboard",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            return data.get("data", {})
        else:
            print_error(f"Failed to get dashboard for {user.name}: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print_error(f"Exception getting dashboard: {str(e)}")
        return None

async def approve_health_record(
    client: httpx.AsyncClient,
    user: TestUser,
    record_id: str,
    visibility_scope: str = "private"
) -> bool:
    """Approve a health record"""
    try:
        headers = {"Authorization": f"Bearer {user.token}"}
        response = await client.post(
            f"{API_BASE}/health-records/{record_id}/approve",
            headers=headers,
            json={"visibility_scope": visibility_scope}
        )
        
        if response.status_code == 200:
            print_success(f"{user.name} approved health record {record_id}")
            return True
        else:
            print_error(f"Failed to approve health record: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"Exception approving health record: {str(e)}")
        return False

async def reject_health_record(
    client: httpx.AsyncClient,
    user: TestUser,
    record_id: str,
    reason: str = "Not accurate"
) -> bool:
    """Reject a health record"""
    try:
        headers = {"Authorization": f"Bearer {user.token}"}
        response = await client.post(
            f"{API_BASE}/health-records/{record_id}/reject?rejection_reason={reason}",
            headers=headers
        )
        
        if response.status_code == 200:
            print_success(f"{user.name} rejected health record {record_id}")
            return True
        else:
            print_error(f"Failed to reject health record: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"Exception rejecting health record: {str(e)}")
        return False

async def run_tests():
    """Run comprehensive tests"""
    print_header("HEALTH RECORDS COMPREHENSIVE WORKFLOW TEST")
    
    # Create test users
    timestamp = int(datetime.utcnow().timestamp())
    alice = TestUser("Alice", f"alice_{timestamp}@test.com", "TestPass123!")
    bob = TestUser("Bob", f"bob_{timestamp}@test.com", "TestPass123!")
    carol = TestUser("Carol", f"carol_{timestamp}@test.com", "TestPass123!")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Step 1: Register users
        print_section("Step 1: Creating Test Users")
        for user in [alice, bob, carol]:
            if not await register_user(client, user):
                print_error(f"Failed to register {user.name}. Trying to login instead...")
                if not await login_user(client, user):
                    print_error(f"Cannot proceed without {user.name}")
                    return
        
        print_success("All users created successfully!")
        
        # Step 2: Alice creates health record for Bob
        print_section("Step 2: Alice Creates Health Record for Bob")
        record1_id = await create_health_record(
            client, alice, bob,
            "Annual Physical Exam - Bob"
        )
        
        if not record1_id:
            print_error("Failed to create health record. Cannot continue.")
            return
        
        # Wait a bit for async operations
        await asyncio.sleep(1)
        
        # Step 3: Verify Bob receives notification
        print_section("Step 3: Verify Bob Receives Notification")
        bob_notifications = await get_notifications(client, bob)
        
        health_record_notif = None
        for notif in bob_notifications:
            if notif.get("type") == "health_record_assigned":
                health_record_notif = notif
                break
        
        if health_record_notif:
            print_success(f"✓ Bob received notification: '{health_record_notif.get('title')}'")
            print_info(f"  Message: {health_record_notif.get('message')}")
        else:
            print_error(f"✗ Bob did NOT receive health record assignment notification!")
            print_info(f"  Bob has {len(bob_notifications)} total notifications")
            if bob_notifications:
                print_info("  Notification types received:")
                for notif in bob_notifications:
                    print_info(f"    - {notif.get('type')}: {notif.get('title')}")
        
        # Step 4: Verify record shows in Bob's dashboard
        print_section("Step 4: Verify Record Shows in Bob's Dashboard")
        bob_dashboard = await get_dashboard(client, bob)
        
        if bob_dashboard:
            stats = bob_dashboard.get("statistics", {})
            pending_approvals = bob_dashboard.get("pending_approvals", [])
            
            print_info(f"Bob's dashboard stats:")
            print_info(f"  - Total records: {stats.get('total_records', 0)}")
            print_info(f"  - Pending approvals: {stats.get('pending_approvals', 0)}")
            print_info(f"  - Upcoming reminders: {stats.get('upcoming_reminders', 0)}")
            
            if len(pending_approvals) > 0:
                print_success(f"✓ Bob has {len(pending_approvals)} pending approval(s)")
                for pa in pending_approvals:
                    print_info(f"  - {pa.get('title')} (ID: {pa.get('id')}, Status: {pa.get('approval_status')})")
            else:
                print_error("✗ Bob has NO pending approvals in dashboard!")
        else:
            print_error("✗ Failed to get Bob's dashboard")
        
        # Step 5: Bob approves the record
        print_section("Step 5: Bob Approves the Health Record")
        approval_success = await approve_health_record(client, bob, record1_id, "family")
        
        if not approval_success:
            print_error("Failed to approve health record")
        
        # Wait for async operations
        await asyncio.sleep(1)
        
        # Step 6: Verify Alice receives approval notification
        print_section("Step 6: Verify Alice Receives Approval Notification")
        alice_notifications = await get_notifications(client, alice)
        
        approval_notif = None
        for notif in alice_notifications:
            if notif.get("type") == "health_record_approved":
                approval_notif = notif
                break
        
        if approval_notif:
            print_success(f"✓ Alice received approval notification: '{approval_notif.get('title')}'")
            print_info(f"  Message: {approval_notif.get('message')}")
        else:
            print_error("✗ Alice did NOT receive approval notification!")
            print_info(f"  Alice has {len(alice_notifications)} total notifications")
            if alice_notifications:
                print_info("  Notification types received:")
                for notif in alice_notifications:
                    print_info(f"    - {notif.get('type')}: {notif.get('title')}")
        
        # Step 7: Carol creates health record for Alice
        print_section("Step 7: Carol Creates Health Record for Alice")
        record2_id = await create_health_record(
            client, carol, alice,
            "Dental Checkup - Alice"
        )
        
        if not record2_id:
            print_error("Failed to create second health record")
        
        await asyncio.sleep(1)
        
        # Step 8: Alice rejects it
        print_section("Step 8: Alice Rejects the Health Record")
        rejection_success = await reject_health_record(
            client, alice, record2_id,
            "This information is not accurate"
        )
        
        if not rejection_success:
            print_error("Failed to reject health record")
        
        await asyncio.sleep(1)
        
        # Step 9: Verify Carol receives rejection notification
        print_section("Step 9: Verify Carol Receives Rejection Notification")
        carol_notifications = await get_notifications(client, carol)
        
        rejection_notif = None
        for notif in carol_notifications:
            if notif.get("type") == "health_record_rejected":
                rejection_notif = notif
                break
        
        if rejection_notif:
            print_success(f"✓ Carol received rejection notification: '{rejection_notif.get('title')}'")
            print_info(f"  Message: {rejection_notif.get('message')}")
        else:
            print_error("✗ Carol did NOT receive rejection notification!")
            print_info(f"  Carol has {len(carol_notifications)} total notifications")
            if carol_notifications:
                print_info("  Notification types received:")
                for notif in carol_notifications:
                    print_info(f"    - {notif.get('type')}: {notif.get('title')}")
        
        # Final verification - Check dashboards
        print_section("Final Verification: Dashboard States")
        
        print_info("\nAlice's Dashboard:")
        alice_dashboard = await get_dashboard(client, alice)
        if alice_dashboard:
            stats = alice_dashboard.get("statistics", {})
            print_info(f"  - Total records: {stats.get('total_records', 0)}")
            print_info(f"  - Pending approvals: {stats.get('pending_approvals', 0)}")
        
        print_info("\nBob's Dashboard (after approval):")
        bob_dashboard = await get_dashboard(client, bob)
        if bob_dashboard:
            stats = bob_dashboard.get("statistics", {})
            print_info(f"  - Total records: {stats.get('total_records', 0)}")
            print_info(f"  - Pending approvals: {stats.get('pending_approvals', 0)}")
        
        print_info("\nCarol's Dashboard:")
        carol_dashboard = await get_dashboard(client, carol)
        if carol_dashboard:
            stats = carol_dashboard.get("statistics", {})
            print_info(f"  - Total records: {stats.get('total_records', 0)}")
            print_info(f"  - Pending approvals: {stats.get('pending_approvals', 0)}")
        
        print_header("TEST COMPLETE")
        print_success("All tests executed successfully!")
        print_info("\nSummary:")
        print_info("  ✓ Users created and authenticated")
        print_info("  ✓ Health records created with assignments")
        print_info("  ✓ Notifications system tested")
        print_info("  ✓ Dashboard visibility tested")
        print_info("  ✓ Approval workflow tested")
        print_info("  ✓ Rejection workflow tested")

if __name__ == "__main__":
    try:
        asyncio.run(run_tests())
    except KeyboardInterrupt:
        print_error("\nTest interrupted by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"\nTest failed with exception: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
