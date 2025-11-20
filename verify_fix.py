import asyncio
from datetime import datetime
from app.models.user import UserCreate, UserRole
from app.api.v1.endpoints.auth.auth import register
from app.db.mongodb import connect_to_mongo, close_mongo_connection, get_collection
from unittest.mock import MagicMock, patch

# Mock dependencies
async def mock_get_user_by_email(email):
    return None

async def mock_is_username_available(username):
    return True

async def mock_generate_unique_username():
    return "testuser"

async def run_verification():
    print("Starting verification...")
    
    # Mock the database connection
    with patch("app.api.v1.endpoints.auth.auth.get_user_by_email", side_effect=mock_get_user_by_email), \
         patch("app.api.v1.endpoints.auth.auth.is_username_available", side_effect=mock_is_username_available), \
         patch("app.api.v1.endpoints.auth.auth.generate_unique_username", side_effect=mock_generate_unique_username), \
         patch("app.api.v1.endpoints.auth.auth.get_collection") as mock_get_collection, \
         patch("app.api.v1.endpoints.auth.auth.get_email_service") as mock_get_email_service:
        
        # Setup mock collection
        mock_collection = MagicMock()
        mock_get_collection.return_value = mock_collection
        
        # Mock insert_one result
        mock_result = MagicMock()
        mock_result.inserted_id = "mock_id"
        mock_collection.insert_one = asyncio.coroutine(lambda x: mock_result)
        
        # Mock email service
        mock_email_service = MagicMock()
        mock_email_service.is_configured.return_value = False
        mock_get_email_service.return_value = mock_email_service

        # Create a user with role="admin"
        user_data = UserCreate(
            email="hacker@example.com",
            password="StrongPassword123!",
            role=UserRole.ADMIN
        )
        
        print(f"Attempting to register with role: {user_data.role}")
        
        # Call register function
        try:
            response = await register(user_data)
            print("Registration successful.")
            
            # Verify what was passed to insert_one
            inserted_user = mock_collection.insert_one.call_args[0][0]
            print(f"Inserted user role: {inserted_user.get('role')}")
            
            if inserted_user.get("role") == "user":
                print("SUCCESS: Role was forced to 'user'.")
            else:
                print(f"FAILURE: Role is '{inserted_user.get('role')}'.")
                
        except Exception as e:
            print(f"Error during registration: {e}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(run_verification())
