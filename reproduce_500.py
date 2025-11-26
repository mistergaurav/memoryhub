import asyncio
from bson import ObjectId
from app.api.v1.endpoints.family.genealogy.persons import create_genealogy_person
from app.models.family.genealogy import GenealogyPersonCreate, RelationshipSpec, RelationshipType, PersonSource
from app.models.user import UserInDB

# Mock User
mock_user = UserInDB(
    id=str(ObjectId()),
    username="test_user",
    email="test@example.com",
    hashed_password="hash",
    full_name="Test User",
    is_active=True,
    is_superuser=False
)

async def reproduce_error():
    print("Attempting to reproduce 500 error...")
    
    # Mock Payload based on frontend
    # User selects "Me" (self) as parent
    # This implies we need a valid person ID for "Me"
    # For reproduction, we'll assume "Me" exists or use a dummy ID
    
    dummy_related_id = str(ObjectId())
    
    payload = GenealogyPersonCreate(
        first_name="New",
        last_name="Person",
        gender="male",
        is_alive=True,
        source=PersonSource.MANUAL,
        relationships=[
            RelationshipSpec(
                person_id=dummy_related_id,
                relationship_type=RelationshipType.PARENT,
                is_biological=True
            )
        ],
        pending_invite_email="invite@example.com" # Simulating "switch on for notification"
    )
    
    try:
        # We can't easily call the endpoint directly without a full app context (DB connection)
        # So this script is more of a template for what we'd run if we had a test harness.
        # Instead, I will rely on code analysis of the specific area I suspect.
        pass
    except Exception as e:
        print(f"Caught exception: {e}")

if __name__ == "__main__":
    print("Reproduction script created. Proceeding with code analysis.")
