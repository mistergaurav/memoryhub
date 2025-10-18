from passlib.context import CryptContext

# Support both bcrypt (new) and argon2 (legacy) for backward compatibility
pwd_context = CryptContext(
    schemes=["bcrypt", "argon2"],
    deprecated="auto",
    # Prefer bcrypt for new hashes but still verify argon2
    default="bcrypt"
)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash. Supports both bcrypt and argon2 for backward compatibility."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Generate password hash using bcrypt (preferred for new passwords)."""
    return pwd_context.hash(password)