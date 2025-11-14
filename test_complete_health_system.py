"""
Comprehensive test script for Health Records System
Tests: Notifications, WebSocket, Health Dashboard, Approval System with 5+ users

This script tests:
1. User registration and authentication
2. Health record creation with different visibility levels
3. Approval and rejection workflows
4. Real-time WebSocket broadcasting
5. Notification system with complete metadata
6. Health dashboard data
7. Multi-user scenarios
"""

import asyncio
import httpx
import websockets
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import sys

# Configuration
BASE_URL = "http://localhost:5000"
WS_URL = "ws://localhost:5000"
API_V1 = f"{BASE_URL}/api/v1"

# Test users
TEST_USERS = [
    {"email": "alice@test.com", "password": "TestPass123!", "full_name": "Alice Johnson"},
    {"email": "bob@test.com", "password": "TestPass123!", "full_name": "Bob Smith"},
    {"email": "carol@test.com", "password": "TestPass123!", "full_name": "Carol Williams"},
    {"email": "david@test.com", "password": "TestPass123!", "full_name": "David Brown"},
    {"email": "emma@test.com", "password": "TestPass123!", "full_name": "Emma Davis"},
    {"email": "frank@test.com", "password": "TestPass123!", "full_name": "Frank Miller"},
]

# Global state
users_data: Dict[str, dict] = {}
health_records: List[dict] = []
ws_messages: List[dict] = []


# Helper function to unwrap standardized API responses
def unwrap_response(response_data: dict) -> any:
    """Extract data from StandardResponse wrapper"""
    if isinstance(response_data, dict) and "data" in response_data:
        return response_data["data"]
    return response_data


class Colors:
    """Console colors for better output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


def print_success(msg: str):
    print(f"{Colors.GREEN}✓ {msg}{Colors.ENDC}")


def print_error(msg: str):
    print(f"{Colors.RED}✗ {msg}{Colors.ENDC}")


def print_info(msg: str):
    print(f"{Colors.BLUE}ℹ {msg}{Colors.ENDC}")


def print_warning(msg: str):
    print(f"{Colors.YELLOW}⚠ {msg}{Colors.ENDC}")


def print_header(msg: str):
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{msg.center(70)}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.ENDC}\n")


async def register_user(client: httpx.AsyncClient, user_data: dict) -> Optional[dict]:
    """Register a new user"""
    try:
        response = await client.post(
            f"{API_V1}/auth/register",
            json=user_data
        )
        if response.status_code == 201:
            data = response.json()
            print_success(f"Registered user: {user_data['email']}")
            return data
        elif response.status_code == 400 and "already registered" in response.text.lower():
            print_warning(f"User already exists: {user_data['email']}")
            # Try to login instead
            return await login_user(client, user_data["email"], user_data["password"])
        else:
            print_error(f"Failed to register {user_data['email']}: {response.text}")
            return None
    except Exception as e:
        print_error(f"Error registering {user_data['email']}: {str(e)}")
        return None


async def get_current_user(client: httpx.AsyncClient, token: str) -> Optional[dict]:
    """Get current user information"""
    try:
        response = await client.get(
            f"{API_V1}/users/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            return response.json()
        return None
    except:
        return None


async def login_user(client: httpx.AsyncClient, email: str, password: str) -> Optional[dict]:
    """Login a user"""
    try:
        response = await client.post(
            f"{API_V1}/auth/login",
            json={
                "email": email,
                "password": password
            }
        )
        if response.status_code == 200:
            data = response.json()
            
            # Get user info using the token
            user_info = await get_current_user(client, data.get("access_token"))
            if user_info:
                data["user"] = user_info
            
            print_success(f"Logged in user: {email}")
            return data
        else:
            print_error(f"Failed to login {email}: {response.text}")
            return None
    except Exception as e:
        print_error(f"Error logging in {email}: {str(e)}")
        return None


async def create_family_circle(client: httpx.AsyncClient, token: str, name: str, user_email: str) -> Optional[str]:
    """Create a family circle"""
    try:
        response = await client.post(
            f"{API_V1}/family/core/circles",
            headers={"Authorization": f"Bearer {token}"},
            json={"name": name, "description": f"Family circle for {name}"}
        )
        if response.status_code == 201:
            data = response.json()
            # Check various possible response structures
            if isinstance(data, dict):
                family_id = data.get("_id") or data.get("id") or data.get("data", {}).get("id") or data.get("data", {}).get("_id")
            else:
                family_id = None
            
            if family_id:
                print_success(f"Created family circle '{name}' for {user_email}: {family_id}")
            else:
                print_warning(f"Created family circle '{name}' but no ID found in response: {data}")
            return family_id
        else:
            print_error(f"Failed to create family circle: {response.text}")
            return None
    except Exception as e:
        print_error(f"Error creating family circle: {str(e)}")
        return None


async def create_health_record(client: httpx.AsyncClient, token: str, family_id: str, 
                               record_data: dict, user_email: str) -> Optional[dict]:
    """Create a health record"""
    try:
        response = await client.post(
            f"{API_V1}/health-records",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "family_id": family_id,
                **record_data
            }
        )
        if response.status_code == 201:
            data = response.json()
            # Unwrap the standardized response to get the actual record
            record = unwrap_response(data)
            print_success(f"Created health record for {user_email}: {record_data['record_type']}")
            # Return just the unwrapped record directly (it's already in the right format)
            return record
        else:
            print_error(f"Failed to create health record: {response.text}")
            return None
    except Exception as e:
        print_error(f"Error creating health record: {str(e)}")
        return None


async def approve_health_record(client: httpx.AsyncClient, token: str, record_id: str, 
                                user_email: str, visibility_scope: str = "family") -> bool:
    """Approve a health record"""
    try:
        response = await client.post(
            f"{API_V1}/health-records/{record_id}/approve",
            headers={"Authorization": f"Bearer {token}"},
            json={"visibility_scope": visibility_scope}
        )
        if response.status_code == 200:
            print_success(f"{user_email} approved health record {record_id}")
            return True
        else:
            print_error(f"Failed to approve health record: {response.text}")
            return False
    except Exception as e:
        print_error(f"Error approving health record: {str(e)}")
        return False


async def reject_health_record(client: httpx.AsyncClient, token: str, record_id: str,
                               reason: str, user_email: str) -> bool:
    """Reject a health record"""
    try:
        response = await client.post(
            f"{API_V1}/health-records/{record_id}/reject?rejection_reason={reason}",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            print_success(f"{user_email} rejected health record {record_id}")
            return True
        else:
            print_error(f"Failed to reject health record: {response.text}")
            return False
    except Exception as e:
        print_error(f"Error rejecting health record: {str(e)}")
        return False


async def get_health_dashboard(client: httpx.AsyncClient, token: str, family_id: str,
                               user_email: str) -> Optional[dict]:
    """Get health dashboard data"""
    try:
        response = await client.get(
            f"{API_V1}/health-records/dashboard",
            headers={"Authorization": f"Bearer {token}"},
            params={"family_id": family_id}
        )
        if response.status_code == 200:
            data = response.json()
            print_success(f"Retrieved health dashboard for {user_email}")
            return data
        else:
            print_error(f"Failed to get health dashboard: {response.text}")
            return None
    except Exception as e:
        print_error(f"Error getting health dashboard: {str(e)}")
        return None


async def get_notifications(client: httpx.AsyncClient, token: str, user_email: str) -> List[dict]:
    """Get user notifications"""
    try:
        response = await client.get(
            f"{API_V1}/notifications",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            response_data = response.json()
            # Unwrap the standardized response
            data = unwrap_response(response_data)
            # Extract the notifications list from the data
            if isinstance(data, dict):
                notifications = data.get("notifications", [])
            elif isinstance(data, list):
                notifications = data
            else:
                notifications = []
            
            print_success(f"Retrieved {len(notifications)} notifications for {user_email}")
            return notifications
        else:
            print_error(f"Failed to get notifications: {response.text}")
            return []
    except Exception as e:
        print_error(f"Error getting notifications: {str(e)}")
        return []


async def listen_to_websocket(token: str, user_email: str, duration: int = 5):
    """Listen to WebSocket for a specified duration"""
    global ws_messages
    uri = f"{WS_URL}/api/v1/ws/notifications?token={token}"
    
    try:
        async with websockets.connect(uri) as websocket:
            print_success(f"WebSocket connected for {user_email}")
            
            # Set a timeout for listening
            start_time = datetime.now()
            while (datetime.now() - start_time).seconds < duration:
                try:
                    message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                    data = json.loads(message)
                    ws_messages.append({
                        "user": user_email,
                        "message": data,
                        "timestamp": datetime.now().isoformat()
                    })
                    print_info(f"WebSocket message for {user_email}: {data.get('event')}")
                except asyncio.TimeoutError:
                    # Send ping to keep alive
                    await websocket.send(json.dumps({"event": "ping"}))
                    continue
                except Exception as e:
                    break
                    
    except Exception as e:
        print_error(f"WebSocket error for {user_email}: {str(e)}")


async def setup_users_and_families():
    """Setup all test users and families"""
    print_header("STEP 1: User Registration and Authentication")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for user in TEST_USERS:
            # Register user
            result = await register_user(client, user)
            if not result:
                print_error(f"Failed to setup user {user['email']}")
                continue
            
            # Extract user ID from response structure
            user_data_from_response = result.get("user", {})
            user_id = (user_data_from_response.get("id") or 
                      user_data_from_response.get("_id") or
                      result.get("id") or
                      result.get("_id"))
            
            if not user_id:
                print_warning(f"Could not extract user ID for {user['email']}")
            
            users_data[user["email"]] = {
                "user_info": user,
                "token": result.get("access_token"),
                "user_id": str(user_id) if user_id else None,
                "family_id": None
            }
        
        print_info(f"\nTotal users registered: {len(users_data)}")
        
        # Create family circles
        print_header("STEP 2: Create Family Circles")
        
        for email, data in users_data.items():
            family_name = f"{data['user_info']['full_name']}'s Family"
            family_id = await create_family_circle(
                client, 
                data["token"], 
                family_name,
                email
            )
            users_data[email]["family_id"] = family_id


async def test_health_records_creation():
    """Test health record creation with different visibility levels"""
    print_header("STEP 3: Create Health Records")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Alice creates a private record
        alice_data = users_data["alice@test.com"]
        bob_user_id = users_data["bob@test.com"]["user_id"]
        record1 = await create_health_record(
            client,
            alice_data["token"],
            alice_data["family_id"],
            {
                "record_type": "medical",
                "title": "Annual Physical Exam",
                "description": "Yearly health checkup",
                "date": (datetime.now() - timedelta(days=10)).isoformat(),
                "visibility_scope": "private",
                "subject_type": "self",
                "subject_user_id": alice_data["user_id"],
                "assigned_user_ids": [bob_user_id] if bob_user_id else []
            },
            "alice@test.com"
        )
        if record1:
            health_records.append({"record": record1, "creator": "alice@test.com"})
        
        # Bob creates a family record
        bob_data = users_data["bob@test.com"]
        carol_user_id = users_data["carol@test.com"]["user_id"]
        record2 = await create_health_record(
            client,
            bob_data["token"],
            bob_data["family_id"],
            {
                "record_type": "vaccination",
                "title": "COVID-19 Booster",
                "description": "Latest COVID vaccination",
                "date": (datetime.now() - timedelta(days=5)).isoformat(),
                "visibility_scope": "family",
                "subject_type": "self",
                "subject_user_id": bob_data["user_id"],
                "assigned_user_ids": [carol_user_id] if carol_user_id else []
            },
            "bob@test.com"
        )
        if record2:
            health_records.append({"record": record2, "creator": "bob@test.com"})
        
        # Carol creates a public record
        carol_data = users_data["carol@test.com"]
        david_user_id = users_data["david@test.com"]["user_id"]
        record3 = await create_health_record(
            client,
            carol_data["token"],
            carol_data["family_id"],
            {
                "record_type": "lab_result",
                "title": "Blood Test Results",
                "description": "Annual blood work",
                "date": (datetime.now() - timedelta(days=3)).isoformat(),
                "visibility_scope": "public",
                "subject_type": "self",
                "subject_user_id": carol_data["user_id"],
                "assigned_user_ids": [david_user_id] if david_user_id else []
            },
            "carol@test.com"
        )
        if record3:
            health_records.append({"record": record3, "creator": "carol@test.com"})
        
        # David creates another record
        david_data = users_data["david@test.com"]
        emma_user_id = users_data["emma@test.com"]["user_id"]
        record4 = await create_health_record(
            client,
            david_data["token"],
            david_data["family_id"],
            {
                "record_type": "medication",
                "title": "Allergy Medication",
                "description": "Seasonal allergy prescription",
                "date": (datetime.now() - timedelta(days=1)).isoformat(),
                "visibility_scope": "family",
                "subject_type": "self",
                "subject_user_id": david_data["user_id"],
                "assigned_user_ids": [emma_user_id] if emma_user_id else []
            },
            "david@test.com"
        )
        if record4:
            health_records.append({"record": record4, "creator": "david@test.com"})
        
        print_info(f"\nTotal health records created: {len(health_records)}")


async def test_approval_rejection_workflows():
    """Test approval and rejection of health records"""
    print_header("STEP 4: Test Approval and Rejection Workflows")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Bob approves Alice's record
        if len(health_records) > 0:
            record_id = health_records[0]["record"].get("id") or health_records[0]["record"].get("_id")
            await approve_health_record(
                client,
                users_data["bob@test.com"]["token"],
                record_id,
                "bob@test.com"
            )
        
        # Carol approves Bob's record
        if len(health_records) > 1:
            record_id = health_records[1]["record"].get("id") or health_records[1]["record"].get("_id")
            await approve_health_record(
                client,
                users_data["carol@test.com"]["token"],
                record_id,
                "carol@test.com"
            )
        
        # David rejects Carol's record
        if len(health_records) > 2:
            record_id = health_records[2]["record"].get("id") or health_records[2]["record"].get("_id")
            await reject_health_record(
                client,
                users_data["david@test.com"]["token"],
                record_id,
                "Incomplete information provided",
                "david@test.com"
            )
        
        # Emma approves David's record
        if len(health_records) > 3:
            record_id = health_records[3]["record"].get("id") or health_records[3]["record"].get("_id")
            await approve_health_record(
                client,
                users_data["emma@test.com"]["token"],
                record_id,
                "emma@test.com"
            )


async def test_websocket_broadcasting():
    """Test real-time WebSocket broadcasting"""
    print_header("STEP 5: Test WebSocket Broadcasting")
    
    print_info("Starting WebSocket listeners for all users...")
    
    # Start WebSocket listeners for all users
    ws_tasks = []
    for email, data in users_data.items():
        if data["token"]:
            task = asyncio.create_task(
                listen_to_websocket(data["token"], email, duration=3)
            )
            ws_tasks.append(task)
    
    # Wait a moment for connections to establish
    await asyncio.sleep(1)
    
    # Perform some actions that should trigger WebSocket messages
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Frank creates a new record (should trigger notifications)
        frank_data = users_data["frank@test.com"]
        alice_user_id = users_data["alice@test.com"]["user_id"]
        new_record = await create_health_record(
            client,
            frank_data["token"],
            frank_data["family_id"],
            {
                "record_type": "procedure",
                "title": "Minor Surgery",
                "description": "Successful minor procedure",
                "date": datetime.now().isoformat(),
                "visibility_scope": "family",
                "subject_type": "self",
                "subject_user_id": frank_data["user_id"],
                "assigned_user_ids": [alice_user_id] if alice_user_id else []
            },
            "frank@test.com"
        )
        
        if new_record:
            # Wait a moment for WebSocket messages
            await asyncio.sleep(1)
            
            # Alice approves Frank's record (should trigger more WebSocket messages)
            record_id = new_record.get("id") or new_record.get("_id")
            if record_id:
                await approve_health_record(
                    client,
                    users_data["alice@test.com"]["token"],
                    record_id,
                    "alice@test.com"
                )
    
    # Wait for WebSocket listeners to finish
    await asyncio.sleep(2)
    
    # Cancel all WebSocket tasks
    for task in ws_tasks:
        task.cancel()
    
    print_info(f"\nTotal WebSocket messages received: {len(ws_messages)}")
    
    # Display some WebSocket messages
    if ws_messages:
        print_info("\nSample WebSocket messages:")
        for i, msg in enumerate(ws_messages[:5]):
            print(f"  {i+1}. User: {msg['user']}, Event: {msg['message'].get('event')}")


async def test_notifications():
    """Test notification system"""
    print_header("STEP 6: Test Notification System")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for email, data in users_data.items():
            notifications = await get_notifications(
                client,
                data["token"],
                email
            )
            
            # Check notification metadata
            if notifications and len(notifications) > 0:
                print_info(f"\nNotifications for {email}:")
                for notif in (notifications[:3] if len(notifications) >= 3 else notifications):  # Show first 3
                    print(f"  - Type: {notif.get('type')}, "
                          f"Status: {notif.get('approval_status', 'N/A')}, "
                          f"Has metadata: {bool(notif.get('metadata'))}")
                    
                    # Verify critical metadata fields
                    metadata = notif.get("metadata", {})
                    if metadata:
                        required_fields = ["health_record_id", "assigner_name"]
                        missing = [f for f in required_fields if f not in metadata]
                        if missing:
                            print_warning(f"    Missing metadata fields: {missing}")
                        else:
                            print_success(f"    All critical metadata present")


async def test_health_dashboards():
    """Test health dashboard for all users"""
    print_header("STEP 7: Test Health Dashboards")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for email, data in users_data.items():
            if data["family_id"]:
                dashboard = await get_health_dashboard(
                    client,
                    data["token"],
                    data["family_id"],
                    email
                )
                
                if dashboard:
                    print_info(f"\nDashboard for {email}:")
                    print(f"  - Total records: {dashboard.get('total_records', 0)}")
                    print(f"  - Pending approvals: {dashboard.get('pending_approvals', 0)}")
                    print(f"  - Recent activity: {len(dashboard.get('recent_activity', []))}")


async def generate_test_report():
    """Generate comprehensive test report"""
    print_header("TEST RESULTS SUMMARY")
    
    print(f"{Colors.BOLD}Users Created:{Colors.ENDC} {len(users_data)}")
    print(f"{Colors.BOLD}Health Records Created:{Colors.ENDC} {len(health_records)}")
    print(f"{Colors.BOLD}WebSocket Messages Received:{Colors.ENDC} {len(ws_messages)}")
    
    # Count WebSocket message types
    event_counts = {}
    for msg in ws_messages:
        event = msg["message"].get("event", "unknown")
        event_counts[event] = event_counts.get(event, 0) + 1
    
    if event_counts:
        print(f"\n{Colors.BOLD}WebSocket Events:{Colors.ENDC}")
        for event, count in event_counts.items():
            print(f"  - {event}: {count}")
    
    # Success criteria
    print(f"\n{Colors.BOLD}Success Criteria:{Colors.ENDC}")
    
    checks = [
        (len(users_data) >= 5, f"5+ users created ({len(users_data)} created)"),
        (len(health_records) >= 4, f"Multiple health records created ({len(health_records)} created)"),
        (len(ws_messages) > 0, f"WebSocket broadcasting working ({len(ws_messages)} messages received)"),
        (any("notification.created" in msg["message"].get("event", "") for msg in ws_messages),
         "Notification events received via WebSocket"),
        (any("health_record" in msg["message"].get("event", "") for msg in ws_messages),
         "Health record events received via WebSocket"),
    ]
    
    all_passed = True
    for passed, description in checks:
        if passed:
            print_success(description)
        else:
            print_error(description)
            all_passed = False
    
    if all_passed:
        print(f"\n{Colors.GREEN}{Colors.BOLD}{'='*70}")
        print(f"ALL TESTS PASSED! 🎉")
        print(f"{'='*70}{Colors.ENDC}\n")
    else:
        print(f"\n{Colors.RED}{Colors.BOLD}{'='*70}")
        print(f"SOME TESTS FAILED")
        print(f"{'='*70}{Colors.ENDC}\n")
    
    return all_passed


async def main():
    """Main test execution"""
    try:
        print_header("COMPREHENSIVE HEALTH SYSTEM TEST")
        print_info("Testing: Notifications, WebSocket, Health Dashboard, Approval System")
        print_info(f"Base URL: {BASE_URL}")
        print_info(f"Test Users: {len(TEST_USERS)}")
        
        # Run all tests
        await setup_users_and_families()
        await test_health_records_creation()
        await test_approval_rejection_workflows()
        await test_websocket_broadcasting()
        await test_notifications()
        await test_health_dashboards()
        
        # Generate report
        success = await generate_test_report()
        
        sys.exit(0 if success else 1)
        
    except KeyboardInterrupt:
        print_warning("\nTest interrupted by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Test failed with error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
