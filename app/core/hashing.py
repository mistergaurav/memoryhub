from passlib.context import CryptContext

# Use only Argon2 for password hashing
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto"
)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash using Argon2."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Generate password hash using Argon2."""
    return pwd_context.hash(password)
