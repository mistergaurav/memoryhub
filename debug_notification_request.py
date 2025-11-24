import asyncio
import httpx
from app.core.security import create_access_token
from bson import ObjectId

async def test_notification_details():
    # User ID: 6917aaa5227d97fd8eb15139, Email: nothing@has.com
    user_email = "nothing@has.com"
    notification_id = "69217b1d49708de0b6d670e2"
    
    # Generate token
    access_token = create_access_token(data={"sub": user_email})
    headers = {"Authorization": f"Bearer {access_token}"}
    
    url = f"http://localhost:5000/api/v1/notifications/{notification_id}/details"
    
    print(f"Testing URL: {url}")
    print(f"User Email: {user_email}")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, headers=headers)
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.text}")
        except Exception as e:
            print(f"Error: {repr(e)}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_notification_details())
