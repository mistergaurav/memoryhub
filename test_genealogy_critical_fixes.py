"""
Test script for genealogy critical fixes.

Tests:
1. Field name compatibility (birth_date vs date_of_birth)
2. Permission system fixes
3. Circular relationship validation
4. Person search functionality
"""

import asyncio
import sys
from datetime import datetime
from bson import ObjectId

# Add parent directory to path
sys.path.insert(0, '.')

from app.db.mongodb import get_database
from app.repositories.family.genealogy_people import GenealogyPersonRepository
from app.repositories.family.genealogy_relationships import GenealogyRelationshipRepository
    try:
        # Test 1: User accessing their own tree (tree_id == user_id)
        tree, role = await ensure_tree_access(tree_id, user_id)
        assert role == "owner", f"User should be owner of their own tree, got: {role}"
        print("✅ Own tree access test PASSED - user is owner")
        
        # Test 2: User accessing different tree without membership
        different_tree_id = ObjectId()
        try:
            await ensure_tree_access(different_tree_id, user_id)
            print("❌ Should have raised permission error")
            return False
        except Exception as e:
            if "access" in str(e).lower() or "forbidden" in str(e).lower():
                print("✅ Permission denial test PASSED - correctly denied access")
            else:
                print(f"❌ Wrong error: {e}")
                return False
        
        return True
    except Exception as e:
        print(f"❌ Permission test FAILED: {e}")
        return False


async def test_circular_relationship_validation():
    """Test circular relationship prevention"""
    print("\n🧪 TEST 3: Circular Relationship Validation")
    print("=" * 60)
    
    person_repo = GenealogyPersonRepository()
    relationship_repo = GenealogyRelationshipRepository()
    
    family_id = ObjectId()
    
    # Create two test persons
    person1_data = {
        "family_id": family_id,
        "first_name": "Alice",
        "last_name": "Test",
        "gender": "female",
        "is_alive": True,
        "created_by": ObjectId(),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    person2_data = {
        "family_id": family_id,
        "first_name": "Bob",
        "last_name": "Test",
        "gender": "male",
        "is_alive": True,
        "created_by": ObjectId(),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    person1 = await person_repo.create(person1_data)
    person2 = await person_repo.create(person2_data)
    
    person1_id = person1["_id"]
    person2_id = person2["_id"]
    
    try:
        # Create parent relationship: Alice is parent of Bob
        rel1_data = {
            "family_id": family_id,
            "person1_id": person1_id,
            "person2_id": person2_id,
            "relationship_type": "parent",
            "created_by": ObjectId(),
            "created_at": datetime.utcnow()
        }
        rel1 = await relationship_repo.create(rel1_data)
        print("✅ Created Alice -> Bob (parent) relationship")
        
        # Try to create inverse circular relationship: Bob is parent of Alice
        # This should be caught by validation
        try:
            await relationship_repo.validate_no_circular_reference(
                person1_id=person2_id,
                person2_id=person1_id,
                relationship_type="parent",
                family_id=family_id
            )
            print("❌ Circular validation should have raised error")
            result = False
        except Exception as e:
            if "circular" in str(e).lower():
                print("✅ Circular reference validation PASSED - correctly prevented")
                result = True
            else:
                print(f"❌ Wrong error: {e}")
                result = False
        
        # Clean up
        await relationship_repo.delete_by_id(str(rel1["_id"]))
        await person_repo.delete_by_id(str(person1_id))
        await person_repo.delete_by_id(str(person2_id))
        
        return result
        
    except Exception as e:
        print(f"❌ Circular relationship test FAILED: {e}")
        # Clean up
        try:
            await person_repo.delete_by_id(str(person1_id))
            await person_repo.delete_by_id(str(person2_id))
        except:
            pass
        return False


async def test_person_search():
    """Test person search functionality"""
    print("\n🧪 TEST 4: Person Search Functionality")
    print("=" * 60)
    
    person_repo = GenealogyPersonRepository()
    family_id = ObjectId()
    
    # Create test persons
    test_persons = [
        {"first_name": "John", "last_name": "Smith"},
        {"first_name": "Jane", "last_name": "Doe"},
        {"first_name": "Johnny", "last_name": "Walker"},
    ]
    
    created_ids = []
    
    try:
        for person_data in test_persons:
            full_data = {
                **person_data,
                "family_id": family_id,
                "gender": "unknown",
                "is_alive": True,
                "created_by": ObjectId(),
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            created = await person_repo.create(full_data)
            created_ids.append(created["_id"])
        
        # Test search by first name
        search_filter = {
            "family_id": family_id,
            "$or": [
                {"first_name": {"$regex": "John", "$options": "i"}},
                {"last_name": {"$regex": "John", "$options": "i"}},
            ]
        }
        results = await person_repo.find_many(filter_dict=search_filter)
        
        # Should find "John" and "Johnny"
        assert len(results) == 2, f"Should find 2 results, got {len(results)}"
        print(f"✅ Search test PASSED - found {len(results)} matching persons")
        
        # Clean up
        for person_id in created_ids:
            await person_repo.delete_by_id(str(person_id))
        
        return True
        
    except Exception as e:
        print(f"❌ Person search test FAILED: {e}")
        # Clean up
        for person_id in created_ids:
            try:
                await person_repo.delete_by_id(str(person_id))
            except:
                pass
        return False
    
    assert fetched["birth_date"] == "1990-01-15", "birth_date should exist"
    assert fetched["is_alive"] == True, "is_alive should exist"
    
    # Clean up
    await person_repo.delete_by_id(str(person_id))
    
    print("✅ Field compatibility test PASSED")
    print("   - birth_date field exists and works")
    print("   - is_alive field exists and works")
    return True


async def test_permission_system():
    """Test permission system fixes"""
    print("\n🧪 TEST 2: Permission System Fixes")
    print("=" * 60)
    
    user_id = ObjectId()
    tree_id = user_id  # User's own tree
    
    try:
        # Test 1: User accessing their own tree (tree_id == user_id)
        tree, role = await ensure_tree_access(tree_id, user_id)
        assert role == "owner", f"User should be owner of their own tree, got: {role}"
        print("✅ Own tree access test PASSED - user is owner")
        
        # Test 2: User accessing different tree without membership
        different_tree_id = ObjectId()
        try:
            await ensure_tree_access(different_tree_id, user_id)
            print("❌ Should have raised permission error")
            return False
        except Exception as e:
            if "access" in str(e).lower() or "forbidden" in str(e).lower():
                print("✅ Permission denial test PASSED - correctly denied access")
            else:
                print(f"❌ Wrong error: {e}")
                return False
        
        return True
    except Exception as e:
        print(f"❌ Permission test FAILED: {e}")
        return False


async def test_circular_relationship_validation():
    """Test circular relationship prevention"""
    print("\n🧪 TEST 3: Circular Relationship Validation")
    print("=" * 60)
    
    person_repo = GenealogyPersonRepository()
    relationship_repo = GenealogyRelationshipRepository()
    
    family_id = ObjectId()
    
    # Create two test persons
    person1_data = {
        "family_id": family_id,
        "first_name": "Alice",
        "last_name": "Test",
        "gender": "female",
        "is_alive": True,
        "created_by": ObjectId(),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    person2_data = {
        "family_id": family_id,
        "first_name": "Bob",
        "last_name": "Test",
        "gender": "male",
        "is_alive": True,
        "created_by": ObjectId(),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    person1 = await person_repo.create(person1_data)
    person2 = await person_repo.create(person2_data)
    
    person1_id = person1["_id"]
    person2_id = person2["_id"]
    
    try:
        # Create parent relationship: Alice is parent of Bob
        rel1_data = {
            "family_id": family_id,
            "person1_id": person1_id,
            "person2_id": person2_id,
            "relationship_type": "parent",
            "created_by": ObjectId(),
            "created_at": datetime.utcnow()
        }
        rel1 = await relationship_repo.create(rel1_data)
        print("✅ Created Alice -> Bob (parent) relationship")
        
        # Try to create inverse circular relationship: Bob is parent of Alice
        # This should be caught by validation
        try:
            await relationship_repo.validate_no_circular_reference(
                person1_id=person2_id,
                person2_id=person1_id,
                relationship_type="parent",
                family_id=family_id
            )
            print("❌ Circular validation should have raised error")
            result = False
        except Exception as e:
            if "circular" in str(e).lower():
                print("✅ Circular reference validation PASSED - correctly prevented")
                result = True
            else:
                print(f"❌ Wrong error: {e}")
                result = False
        
        # Clean up
        await relationship_repo.delete_by_id(str(rel1["_id"]))
        await person_repo.delete_by_id(str(person1_id))
        await person_repo.delete_by_id(str(person2_id))
        
        return result
        
    except Exception as e:
        print(f"❌ Circular relationship test FAILED: {e}")
        # Clean up
        try:
            await person_repo.delete_by_id(str(person1_id))
            await person_repo.delete_by_id(str(person2_id))
        except:
            pass
        return False


async def test_person_search():
    """Test person search functionality"""
    print("\n🧪 TEST 4: Person Search Functionality")
    print("=" * 60)
    
    person_repo = GenealogyPersonRepository()
    family_id = ObjectId()
    
    # Create test persons
    test_persons = [
        {"first_name": "John", "last_name": "Smith"},
        {"first_name": "Jane", "last_name": "Doe"},
        {"first_name": "Johnny", "last_name": "Walker"},
    ]
    
    created_ids = []
    
    try:
        for person_data in test_persons:
            full_data = {
                **person_data,
                "family_id": family_id,
                "gender": "unknown",
                "is_alive": True,
                "created_by": ObjectId(),
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            created = await person_repo.create(full_data)
            created_ids.append(created["_id"])
        
        # Test search by first name
        search_filter = {
            "family_id": family_id,
            "$or": [
                {"first_name": {"$regex": "John", "$options": "i"}},
                {"last_name": {"$regex": "John", "$options": "i"}},
            ]
        }
        results = await person_repo.find_many(filter_dict=search_filter)
        
        # Should find "John" and "Johnny"
        assert len(results) == 2, f"Should find 2 results, got {len(results)}"
        print(f"✅ Search test PASSED - found {len(results)} matching persons")
        
        # Clean up
        for person_id in created_ids:
            await person_repo.delete_by_id(str(person_id))
        
        return True
        
    except Exception as e:
        print(f"❌ Person search test FAILED: {e}")
        # Clean up
        for person_id in created_ids:
            try:
                await person_repo.delete_by_id(str(person_id))
            except:
                pass
        return False


async def main():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("GENEALOGY CRITICAL FIXES - TEST SUITE")
    print("=" * 60)
    
    results = {}
    
    # Run tests
    results['field_compatibility'] = await test_field_name_compatibility()
    results['permissions'] = await test_permission_system()
    results['circular_validation'] = await test_circular_relationship_validation()
    results['search'] = await test_person_search()
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    total = len(results)
    passed = sum(1 for v in results.values() if v)
    
    for test_name, passed_test in results.items():
        status = "[PASSED]" if passed_test else "[FAILED]"
        print(f"{test_name.replace('_', ' ').title()}: {status}")
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("All critical fixes are working correctly!")
        return 0
    else:
        print("Some tests failed - review needed")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
