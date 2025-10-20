import random
import string
from app.db.mongodb import get_collection

async def generate_unique_username() -> str:
    """
    Generate a unique random username that doesn't exist in the database.
    Format: user_[8 random characters combining letters and numbers]
    Example: user_a7k9m2x1
    """
    users_collection = get_collection("users")
    max_attempts = 10
    
    for _ in range(max_attempts):
        random_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
        username = f"user_{random_suffix}"
        
        existing_user = await users_collection.find_one({"username": username})
        if not existing_user:
            return username
    
    timestamp_suffix = str(int(random.random() * 1000000000))
    username = f"user_{timestamp_suffix}"
    return username


async def is_username_available(username: str, current_user_id: str = None) -> bool:
    """
    Check if a username is available for use.
    
    Args:
        username: The username to check
        current_user_id: If provided, allows the current user to keep their own username
    
    Returns:
        bool: True if username is available, False otherwise
    """
    if not username or len(username.strip()) == 0:
        return False
    
    username = username.strip()
    
    if len(username) < 3:
        return False
    
    if len(username) > 30:
        return False
    
    if not all(c.isalnum() or c in '_-' for c in username):
        return False
    
    users_collection = get_collection("users")
    query = {"username": username}
    
    existing_user = await users_collection.find_one(query)
    
    if not existing_user:
        return True
    
    if current_user_id and str(existing_user.get("_id")) == current_user_id:
        return True
    
    return False
