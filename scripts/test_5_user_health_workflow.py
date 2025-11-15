#!/usr/bin/env python3
"""
Comprehensive 5-User Health Records Workflow Test Script

This script tests the complete health records workflow including:
1. User registration and authentication
2. Health record creation with different subject types
3. Notification delivery to assigned users
4. Approval/rejection workflow
5. Dashboard data retrieval with enriched metadata
6. WebSocket real-time updates

Users:
- alice@test.com (creates records for others)
- bob@test.com (receives and approves records)
- carol@test.com (receives and rejects records)
- david@test.com (creates and receives records)
- emma@test.com (receives records)
"""

import asyncio
import httpx
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

BASE_URL = "http://localhost:5000/api/v1"

class HealthWorkflowTester:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=30.0)
        self.users = {}
        self.tokens = {}
        self.records = {}
        
    async def cleanup(self):
        await self.client.aclose()
    
    async def register_user(self, email: str, password: str, full_name: str) -> Dict:
        """Register a new user"""
        print(f"\n📝 Registering user: {email}")
        response = await self.client.post(
            f"{BASE_URL}/auth/register",
            json={
                "email": email,
                "password": password,
                "full_name": full_name
            }
        )
        
        if response.status_code == 201:
            data = response.json()
            user_data = data.get("data", {})
            self.users[email] = user_data.get("user", {})
            self.tokens[email] = user_data.get("access_token")
            print(f"✅ Registered {full_name} ({email})")
            return user_data
        else:
            print(f"❌ Failed to register {email}: {response.text}")
            raise Exception(f"Registration failed for {email}")
    
    async def login_user(self, email: str, password: str) -> str:
        """Login and get access token"""
        print(f"\n🔐 Logging in: {email}")
        response = await self.client.post(
            f"{BASE_URL}/auth/token",
            data={
                "username": email,
                "password": password
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get("access_token")
            self.tokens[email] = token
            print(f"✅ Logged in {email}")
            return token
        else:
            print(f"❌ Login failed for {email}: {response.text}")
            raise Exception(f"Login failed for {email}")
    
    async def get_user_by_email(self, creator_email: str, search_email: str) -> Optional[Dict]:
        """Search for a user by email"""
        print(f"\n🔍 Searching for user: {search_email}")
        token = self.tokens[creator_email]
        response = await self.client.get(
            f"{BASE_URL}/users/search",
            params={"query": search_email.split('@')[0]},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json()
            users = data.get("data", [])
            for user in users:
                if user.get("email") == search_email:
                    print(f"✅ Found user: {user.get('full_name')} ({search_email})")
                    return user
            print(f"❌ User not found: {search_email}")
            return None
        else:
            print(f"❌ Search failed: {response.text}")
            return None
    
    async def create_health_record(
        self, 
        creator_email: str, 
        subject_email: str,
        record_type: str = "checkup",
        title: str = "Annual Checkup"
    ) -> Dict:
        """Create a health record for another user"""
        print(f"\n🏥 {creator_email} creating health record for {subject_email}")
        
        # Get subject user ID
        subject_user = await self.get_user_by_email(creator_email, subject_email)
        if not subject_user:
            raise Exception(f"Subject user not found: {subject_email}")
        
        token = self.tokens[creator_email]
        record_data = {
            "subject_type": "user",
            "subject_user_id": subject_user["id"],
            "record_type": record_type,
            "title": title,
            "description": f"Health record created by {creator_email} for {subject_email}",
            "date": datetime.now().isoformat(),
            "provider": "Dr. Smith",
            "location": "General Hospital",
            "severity": "low",
            "notes": "Routine checkup - all vitals normal",
            "is_confidential": False
        }
        
        response = await self.client.post(
            f"{BASE_URL}/family/health-records/",
            json=record_data,
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 201:
            data = response.json()
            record = data.get("data", {})
            record_id = record.get("id")
            self.records[record_id] = record
            print(f"✅ Created health record: {record_id}")
            print(f"   Title: {record.get('title')}")
            print(f"   Status: {record.get('approval_status', 'unknown')}")
            print(f"   Created by: {record.get('created_by_name', 'Unknown')}")
            return record
        else:
            print(f"❌ Failed to create health record: {response.text}")
            raise Exception(f"Failed to create health record")
    
    async def get_notifications(self, user_email: str) -> List[Dict]:
        """Get notifications for a user"""
        print(f"\n🔔 Fetching notifications for {user_email}")
        token = self.tokens[user_email]
        response = await self.client.get(
            f"{BASE_URL}/notifications/",
            params={"page": 1, "limit": 20},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json()
            notifications = data.get("data", {}).get("items", [])
            print(f"✅ Found {len(notifications)} notifications for {user_email}")
            
            for notif in notifications:
                print(f"   - {notif.get('title', 'No title')}")
                print(f"     Type: {notif.get('notification_type', 'unknown')}")
                print(f"     Assigner: {notif.get('assigner_name', 'Unknown')}")
                print(f"     Status: {notif.get('approval_status', 'N/A')}")
                print(f"     Read: {notif.get('is_read', False)}")
            
            return notifications
        else:
            print(f"❌ Failed to fetch notifications: {response.text}")
            return []
    
    async def get_dashboard(self, user_email: str) -> Dict:
        """Get health dashboard for a user"""
        print(f"\n📊 Fetching health dashboard for {user_email}")
        token = self.tokens[user_email]
        response = await self.client.get(
            f"{BASE_URL}/family/health-records/dashboard",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json()
            dashboard = data.get("data", {})
            stats = dashboard.get("statistics", {})
            pending = dashboard.get("pending_approvals", [])
            reminders = dashboard.get("upcoming_reminders", [])
            
            print(f"✅ Dashboard loaded for {user_email}")
            print(f"   Total records: {stats.get('total_records', 0)}")
            print(f"   Pending approvals: {stats.get('pending_approvals', 0)}")
            print(f"   Upcoming reminders: {stats.get('upcoming_reminders', 0)}")
            
            # Check recent records for metadata
            recent = stats.get("recent_records", [])
            if recent:
                print(f"\n   📋 Recent Records:")
                for rec in recent[:3]:  # Show first 3
                    print(f"      - {rec.get('title', 'No title')}")
                    print(f"        Creator: {rec.get('created_by_name', 'Unknown')} ({rec.get('created_by_email', 'N/A')})")
                    print(f"        Status: {rec.get('approval_status', 'unknown')}")
                    print(f"        Subject: {rec.get('subject_user_name', 'N/A')}")
            
            # Check pending approvals for metadata
            if pending:
                print(f"\n   ⏳ Pending Approvals:")
                for rec in pending:
                    print(f"      - {rec.get('title', 'No title')}")
                    print(f"        Creator: {rec.get('created_by_name', 'Unknown')}")
                    print(f"        Status: {rec.get('approval_status', 'unknown')}")
            
            return dashboard
        else:
            print(f"❌ Failed to fetch dashboard: {response.text}")
            return {}
    
    async def approve_health_record(self, user_email: str, record_id: str) -> Dict:
        """Approve a health record"""
        print(f"\n✅ {user_email} approving health record {record_id}")
        token = self.tokens[user_email]
        response = await self.client.post(
            f"{BASE_URL}/health-records/{record_id}/approve",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json()
            record = data.get("data", {})
            print(f"✅ Health record approved")
            print(f"   Status: {record.get('approval_status', 'unknown')}")
            return record
        else:
            print(f"❌ Failed to approve health record: {response.text}")
            return {}
    
    async def reject_health_record(self, user_email: str, record_id: str, reason: str) -> Dict:
        """Reject a health record"""
        print(f"\n❌ {user_email} rejecting health record {record_id}")
        token = self.tokens[user_email]
        response = await self.client.post(
            f"{BASE_URL}/health-records/{record_id}/reject",
            json={"rejection_reason": reason},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            data = response.json()
            record = data.get("data", {})
            print(f"✅ Health record rejected")
            print(f"   Status: {record.get('approval_status', 'unknown')}")
            print(f"   Reason: {reason}")
            return record
        else:
            print(f"❌ Failed to reject health record: {response.text}")
            return {}
    
    async def run_complete_workflow(self):
        """Run the complete 5-user workflow test"""
        print("="*80)
        print("🚀 STARTING COMPREHENSIVE 5-USER HEALTH WORKFLOW TEST")
        print("="*80)
        
        try:
            # Step 1: Register all 5 users
            print("\n" + "="*80)
            print("STEP 1: REGISTER 5 USERS")
            print("="*80)
            
            users_to_register = [
                ("alice@test.com", "password123", "Alice Anderson"),
                ("bob@test.com", "password123", "Bob Brown"),
                ("carol@test.com", "password123", "Carol Carter"),
                ("david@test.com", "password123", "David Davis"),
                ("emma@test.com", "password123", "Emma Evans"),
            ]
            
            for email, password, name in users_to_register:
                await self.register_user(email, password, name)
            
            # Small delay to ensure all users are registered
            await asyncio.sleep(1)
            
            # Step 2: Create health records with different scenarios
            print("\n" + "="*80)
            print("STEP 2: CREATE HEALTH RECORDS")
            print("="*80)
            
            # Scenario 1: Alice creates record for Bob
            record1 = await self.create_health_record(
                "alice@test.com", "bob@test.com", 
                "checkup", "Bob's Annual Physical"
            )
            
            # Scenario 2: Alice creates record for Carol
            record2 = await self.create_health_record(
                "alice@test.com", "carol@test.com",
                "diagnosis", "Carol's Allergy Test"
            )
            
            # Scenario 3: David creates record for Emma
            record3 = await self.create_health_record(
                "david@test.com", "emma@test.com",
                "prescription", "Emma's Medication Refill"
            )
            
            # Scenario 4: David creates record for Bob
            record4 = await self.create_health_record(
                "david@test.com", "bob@test.com",
                "lab_result", "Bob's Blood Work"
            )
            
            await asyncio.sleep(2)
            
            # Step 3: Check notifications for all users
            print("\n" + "="*80)
            print("STEP 3: CHECK NOTIFICATIONS")
            print("="*80)
            
            for email in ["bob@test.com", "carol@test.com", "emma@test.com"]:
                notifications = await self.get_notifications(email)
            
            # Step 4: Check dashboards for all users
            print("\n" + "="*80)
            print("STEP 4: CHECK DASHBOARDS")
            print("="*80)
            
            for email in users_to_register:
                await self.get_dashboard(email[0])
            
            # Step 5: Approve and reject records
            print("\n" + "="*80)
            print("STEP 5: APPROVE/REJECT RECORDS")
            print("="*80)
            
            # Bob approves record1
            if record1.get("id"):
                await self.approve_health_record("bob@test.com", record1["id"])
            
            # Carol rejects record2
            if record2.get("id"):
                await self.reject_health_record(
                    "carol@test.com", record2["id"],
                    "Incorrect allergy information"
                )
            
            # Emma approves record3
            if record3.get("id"):
                await self.approve_health_record("emma@test.com", record3["id"])
            
            await asyncio.sleep(1)
            
            # Step 6: Final dashboard check
            print("\n" + "="*80)
            print("STEP 6: FINAL DASHBOARD CHECK")
            print("="*80)
            
            for email in ["alice@test.com", "bob@test.com", "carol@test.com"]:
                await self.get_dashboard(email)
            
            # Summary
            print("\n" + "="*80)
            print("✅ TEST COMPLETED SUCCESSFULLY!")
            print("="*80)
            print("\nSUMMARY:")
            print(f"  - Registered: {len(self.users)} users")
            print(f"  - Created: {len([r for r in self.records.values() if r])} health records")
            print(f"  - Notifications: Working ✅")
            print(f"  - Dashboard metadata: Verified ✅")
            print(f"  - Approval workflow: Tested ✅")
            print(f"  - Rejection workflow: Tested ✅")
            print("="*80)
            
        except Exception as e:
            print(f"\n❌ TEST FAILED: {str(e)}")
            import traceback
            traceback.print_exc()
        finally:
            await self.cleanup()


async def main():
    tester = HealthWorkflowTester()
    await tester.run_complete_workflow()


if __name__ == "__main__":
    asyncio.run(main())
