"""Quick test to verify rate limiting works"""
import httpx
import asyncio

async def test_rate_limit():
    print("🧪 Testing rate limiting (100 req/60s)...")
    async with httpx.AsyncClient() as client:
        # Make 105 requests quickly
        for i in range(105):
            try:
                response = await client.get("http://localhost:8000/health")
                if i % 20 == 0:
                    print(f"  Request {i+1}: {response.status_code}")
                if response.status_code == 429:
                    print(f"✅ Rate limit working! Got 429 at request {i+1}")
                    return True
            except Exception as e:
                print(f"  Error at request {i+1}: {e}")
        
        print("❌ No rate limit triggered after 105 requests")
        return False

if __name__ == "__main__":
    asyncio.run(test_rate_limit())
