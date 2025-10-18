"""
Startup script for initializing database indexes and other setup tasks.
Run this during application startup to ensure optimal database performance.
"""
import asyncio
from app.utils.db_indexes import create_all_indexes


async def initialize_database():
    """Initialize database with all necessary indexes"""
    try:
        print("🔧 Initializing database indexes...")
        await create_all_indexes()
        print("✅ Database initialization complete")
    except Exception as e:
        print(f"⚠️  Database initialization failed: {str(e)}")
        print("Application will continue, but performance may be affected")


def startup():
    """Run all startup tasks"""
    asyncio.run(initialize_database())


if __name__ == "__main__":
    startup()
