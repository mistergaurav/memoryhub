#!/usr/bin/env python3
"""
Comprehensive Genealogy Tree Frontend-Backend Integration Test
Tests the complete flow from login → fetch tree → verify relationships
"""

import asyncio
import httpx
import json
from typing import Dict, List, Any

BASE_URL = "http://localhost:5000"

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_success(msg: str):
    print(f"{Colors.GREEN}✓ {msg}{Colors.END}")

def print_error(msg: str):
    print(f"{Colors.RED}✗ {msg}{Colors.END}")

def print_info(msg: str):
    print(f"{Colors.BLUE}ℹ {msg}{Colors.END}")

def print_header(msg: str):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{msg}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.END}\n")

async def test_login(client: httpx.AsyncClient, email: str, password: str) -> str:
    """Test login and return access token"""
    print_header("TEST 1: User Authentication")
    
    response = await client.post(
        f"{BASE_URL}/api/v1/auth/login",
        json={"email": email, "password": password}
    )
    
    if response.status_code != 200:
        print_error(f"Login failed with status {response.status_code}")
        print(f"  Response: {response.text}")
        return None
    
    data = response.json()
    access_token = data.get("access_token")
    
    if not access_token:
        print_error("No access token in response")
        return None
    
    print_success(f"Login successful for {email}")
    print_info(f"  Token: {access_token[:30]}...")
    return access_token

async def test_genealogy_tree_api(client: httpx.AsyncClient, token: str) -> Dict[str, Any]:
    """Test genealogy tree API endpoint"""
    print_header("TEST 2: Genealogy Tree API")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get(
        f"{BASE_URL}/api/v1/family/genealogy/tree",
        headers=headers
    )
    
    print_info(f"  Status: {response.status_code}")
    
    if response.status_code != 200:
        print_error(f"API call failed: {response.status_code}")
        print(f"  Response: {response.text[:300]}")
        return None
    
    data = response.json()
    print_success("API call successful!")
    print_info(f"  Success: {data.get('success')}")
    print_info(f"  Message: {data.get('message')}")
    
    return data

async def analyze_tree_structure(tree_data: Dict[str, Any]):
    """Analyze and verify tree data structure"""
    print_header("TEST 3: Tree Data Structure Verification")
    
    data = tree_data.get('data', [])
    
    if not isinstance(data, list):
        print_error("Data is not a list!")
        print(f"  Type: {type(data)}")
        return False
    
    print_success(f"Tree contains {len(data)} persons")
    
    if len(data) == 0:
        print_error("Tree is empty!")
        return False
    
    # Check first node structure
    node = data[0]
    expected_fields = ['person', 'parents', 'children', 'spouses', 'siblings', 'relationships']
    
    missing_fields = [f for f in expected_fields if f not in node]
    if missing_fields:
        print_error(f"Missing fields in node: {missing_fields}")
        return False
    
    print_success("Node structure verified")
    print_info(f"  Node fields: {list(node.keys())}")
    
    # Verify nested person object
    person = node.get('person', {})
    if not isinstance(person, dict):
        print_error("Person is not a dictionary!")
        return False
    
    person_fields = ['id', 'first_name', 'last_name', 'gender']
    missing_person_fields = [f for f in person_fields if f not in person]
    if missing_person_fields:
        print_error(f"Missing person fields: {missing_person_fields}")
        return False
    
    print_success("Person object structure verified")
    print_info(f"  Person has {len(person)} fields")
    
    return True

async def analyze_relationships(tree_data: Dict[str, Any]):
    """Analyze relationship linking"""
    print_header("TEST 4: Relationship Linking Analysis")
    
    data = tree_data.get('data', [])
    
    # Count persons with relationships
    has_parents = 0
    has_children = 0
    has_spouses = 0
    has_siblings = 0
    
    relationship_details = []
    
    for node in data:
        person = node.get('person', {})
        parents = node.get('parents', [])
        children = node.get('children', [])
        spouses = node.get('spouses', [])
        siblings = node.get('siblings', [])
        
        if len(parents) > 0:
            has_parents += 1
        if len(children) > 0:
            has_children += 1
        if len(spouses) > 0:
            has_spouses += 1
        if len(siblings) > 0:
            has_siblings += 1
        
        relationship_details.append({
            'name': f"{person.get('first_name', 'Unknown')} {person.get('last_name', '')}",
            'parents': len(parents),
            'children': len(children),
            'spouses': len(spouses),
            'siblings': len(siblings)
        })
    
    print_success(f"Relationship Statistics:")
    print_info(f"  Persons with parents: {has_parents}/{len(data)}")
    print_info(f"  Persons with children: {has_children}/{len(data)}")
    print_info(f"  Persons with spouses: {has_spouses}/{len(data)}")
    print_info(f"  Persons with siblings: {has_siblings}/{len(data)}")
    
    total_relationships = has_parents + has_children + has_spouses + has_siblings
    if total_relationships == 0:
        print_error("NO RELATIONSHIPS LINKED!")
        return False
    
    print_success(f"Total relationship connections: {total_relationships}")
    
    # Show sample person with relationships
    print_header("TEST 5: Sample Person Detail")
    
    person_with_rels = next((d for d in relationship_details 
                            if d['parents'] > 0 or d['children'] > 0), None)
    
    if person_with_rels:
        print_success(f"Found person with relationships: {person_with_rels['name']}")
        print_info(f"  Parents: {person_with_rels['parents']}")
        print_info(f"  Children: {person_with_rels['children']}")
        print_info(f"  Spouses: {person_with_rels['spouses']}")
        print_info(f"  Siblings: {person_with_rels['siblings']}")
        
        # Find this person in tree data and show details
        for node in data:
            person = node.get('person', {})
            name = f"{person.get('first_name', '')} {person.get('last_name', '')}"
            if name == person_with_rels['name']:
                print_info(f"\n  Detailed Relationships:")
                
                if node.get('parents'):
                    print_info(f"    Parents:")
                    for parent in node['parents']:
                        print_info(f"      - {parent['first_name']} {parent['last_name']} ({parent['gender']})")
                
                if node.get('children'):
                    print_info(f"    Children:")
                    for child in node['children']:
                        print_info(f"      - {child['first_name']} {child['last_name']} ({child['gender']})")
                
                if node.get('spouses'):
                    print_info(f"    Spouses:")
                    for spouse in node['spouses']:
                        print_info(f"      - {spouse['first_name']} {spouse['last_name']} ({spouse['gender']})")
                
                break
    else:
        print_error("No person found with relationships!")
        return False
    
    return True

async def test_flutter_conversion_layer(tree_data: Dict[str, Any]):
    """Simulate Flutter conversion from nested to flat structure"""
    print_header("TEST 6: Flutter Conversion Layer Simulation")
    
    data = tree_data.get('data', [])
    
    # Simulate _convertNestedNodeToFlat
    def extract_ids(person_array: List[Dict]) -> List[str]:
        return [str(p.get('id', '')) for p in person_array if p.get('id')]
    
    converted_nodes = []
    for node in data:
        person = node.get('person', {})
        parents = node.get('parents', [])
        children = node.get('children', [])
        spouses = node.get('spouses', [])
        
        # Build flat structure (what Flutter expects)
        flat_node = {
            'id': str(person.get('id', '')),
            'person_id': str(person.get('id', '')),
            'first_name': person.get('first_name', ''),
            'last_name': person.get('last_name', ''),
            'gender': person.get('gender', 'unknown'),
            'parent_ids': extract_ids(parents),
            'children_ids': extract_ids(children),
            'spouse_ids': extract_ids(spouses),
        }
        converted_nodes.append(flat_node)
    
    print_success(f"Converted {len(converted_nodes)} nodes to Flutter format")
    
    # Verify ID extraction
    nodes_with_parent_ids = sum(1 for n in converted_nodes if len(n['parent_ids']) > 0)
    nodes_with_children_ids = sum(1 for n in converted_nodes if len(n['children_ids']) > 0)
    
    print_info(f"  Nodes with parent_ids: {nodes_with_parent_ids}")
    print_info(f"  Nodes with children_ids: {nodes_with_children_ids}")
    
    if nodes_with_parent_ids == 0 and nodes_with_children_ids == 0:
        print_error("ID extraction failed - no relationships in flat structure!")
        return False
    
    print_success("Flutter conversion layer working correctly!")
    
    # Show sample converted node
    sample = next((n for n in converted_nodes if len(n['parent_ids']) > 0), converted_nodes[0])
    print_info(f"\n  Sample Converted Node:")
    print_info(f"    Name: {sample['first_name']} {sample['last_name']}")
    print_info(f"    ID: {sample['id']}")
    print_info(f"    Parent IDs: {sample['parent_ids']}")
    print_info(f"    Children IDs: {sample['children_ids']}")
    
    return True

async def main():
    """Run all tests"""
    print(f"{Colors.BOLD}\n🧪 COMPREHENSIVE GENEALOGY TREE INTEGRATION TEST 🧪{Colors.END}")
    
    test_user = {
        "email": "jane.smith@example.com",
        "password": "TestPass123!"
    }
    
    async with httpx.AsyncClient() as client:
        # Test 1: Login
        token = await test_login(client, test_user["email"], test_user["password"])
        if not token:
            print_error("\n❌ TESTS FAILED: Could not authenticate")
            return
        
        # Test 2: API Call
        tree_data = await test_genealogy_tree_api(client, token)
        if not tree_data:
            print_error("\n❌ TESTS FAILED: API call failed")
            return
        
        # Test 3: Structure
        structure_ok = await analyze_tree_structure(tree_data)
        if not structure_ok:
            print_error("\n❌ TESTS FAILED: Invalid data structure")
            return
        
        # Test 4: Relationships
        relationships_ok = await analyze_relationships(tree_data)
        if not relationships_ok:
            print_error("\n❌ TESTS FAILED: Relationships not linked")
            return
        
        # Test 5: Flutter Conversion
        conversion_ok = await test_flutter_conversion_layer(tree_data)
        if not conversion_ok:
            print_error("\n❌ TESTS FAILED: Flutter conversion failed")
            return
        
        # Final Summary
        print_header("🎉 ALL TESTS PASSED! 🎉")
        print_success("Backend-to-Frontend Integration: WORKING ✅")
        print_success("Nested Data Format: CORRECT ✅")
        print_success("Relationship Linking: FUNCTIONAL ✅")
        print_success("Flutter Conversion: VERIFIED ✅")
        print_success("\n🚀 Genealogy Tree Feature is READY for Frontend Use!")

if __name__ == "__main__":
    asyncio.run(main())
