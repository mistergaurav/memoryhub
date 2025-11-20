from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from contextlib import asynccontextmanager
from app.api.v1.api import api_router
from app.core.config import settings
from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.utils.db_indexes import create_all_indexes
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await connect_to_mongo()
    # Initialize database indexes for optimal performance
    try:
        await create_all_indexes()
    except Exception as e:
        print(f"Warning: Failed to create indexes: {e}")
    yield
    # Shutdown
    await close_mongo_connection()

app = FastAPI(
    title="The Memory Hub API",
    description="API for The Memory Hub - Your Family's Digital Legacy",
    version="1.0.0",
    lifespan=lifespan,
)

# Build allowed origins list for CORS
# Keep a short list of static origins for production/Replit
allowed_origins = [
    "http://localhost:5000",
    "https://localhost:5000",
]

# Add Replit preview domain if available
replit_domain = os.getenv("REPLIT_DOMAINS")
if replit_domain:
    allowed_origins.extend([
        f"https://{replit_domain}",
        f"http://{replit_domain}",
    ])

# Import re for regex pattern matching
import re

# Helper function to check if origin matches localhost pattern
def is_localhost_origin(origin: str) -> bool:
    """Check if origin is localhost or 127.0.0.1 with any port"""
    if not origin:
        return False
    # Match http://localhost or http://localhost:port or http://127.0.0.1 or http://127.0.0.1:port
    # Also match https variants
    pattern = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"
    return bool(re.match(pattern, origin))

# Global OPTIONS handler for CORS preflight requests MUST be added BEFORE including routers
# This catches all OPTIONS requests before they reach endpoint validators that would fail on missing body
from fastapi import Response, Request

@app.options("/{path:path}", include_in_schema=False)
async def global_options_handler(path: str, request: Request):
    """
    Handle CORS preflight OPTIONS requests globally.
    
    This is necessary because OPTIONS preflight requests don't include request bodies,
    but FastAPI endpoint validators expect bodies for POST requests. This handler
    intercepts all OPTIONS requests before they reach route-specific handlers that
    would fail validation with 400 Bad Request.
    
    IMPORTANT: We echo the request origin instead of using "*" because browsers
    reject credentialed requests (Access-Control-Allow-Credentials: true) when
    Access-Control-Allow-Origin is set to "*". This is a security requirement.
    """
    origin = request.headers.get("origin", "")
    
    # Check if origin is in allowed_origins or matches localhost pattern
    if origin in allowed_origins or is_localhost_origin(origin):
        allowed_origin = origin
    else:
        allowed_origin = allowed_origins[0]
    
    return Response(
        status_code=200,
        headers={
            "Access-Control-Allow-Origin": allowed_origin,
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH, OPTIONS",
            "Access-Control-Allow-Headers": "Authorization, Content-Type, Accept, Origin, User-Agent, DNT, Cache-Control, X-Mx-ReqToken, Keep-Alive, X-Requested-With, If-Modified-Since",
            "Access-Control-Max-Age": "86400",
            "Access-Control-Allow-Credentials": "true",
        }
    )

# CORS middleware with regex-based origin matching for localhost
# This allows any localhost port for local development while being secure for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Include API routers
app.include_router(api_router, prefix="/api/v1")

# Include WebSocket router
from app.api.v1.endpoints.social.notifications_ws import router as ws_router
app.include_router(ws_router, prefix="/api/v1", tags=["websocket"])

# Serve uploaded media files
from app.api.v1.endpoints.media import router as media_router
app.include_router(media_router, tags=["media"])

# Create uploads directory if it doesn't exist
uploads_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
for subdir in ["audio", "images", "videos", "documents", "other"]:
    os.makedirs(os.path.join(uploads_dir, subdir), exist_ok=True)

# Serve Flutter web app
flutter_build_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "memory_hub_app", "build", "web")
if os.path.exists(flutter_build_path):
    assets_path = os.path.join(flutter_build_path, "assets")
    if os.path.exists(assets_path):
        app.mount("/assets", StaticFiles(directory=assets_path), name="assets")
    
    icons_path = os.path.join(flutter_build_path, "icons")
    if os.path.exists(icons_path):
        app.mount("/icons", StaticFiles(directory=icons_path), name="icons")
    
    canvaskit_path = os.path.join(flutter_build_path, "canvaskit")
    if os.path.exists(canvaskit_path):
        app.mount("/canvaskit", StaticFiles(directory=canvaskit_path), name="canvaskit")
    
    @app.get("/{full_path:path}")
    async def serve_flutter_app(full_path: str):
        # Don't serve Flutter app for API routes - raise 404 to let FastAPI handle them
        if full_path.startswith("api") or full_path.startswith("docs") or full_path.startswith("redoc") or full_path.startswith("media"):
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="Not found")
        
        file_path = os.path.join(flutter_build_path, full_path)
        if os.path.isfile(file_path):
            response = FileResponse(file_path)
            # Disable caching for Flutter app files to ensure updates are immediately visible
            response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
            response.headers["Pragma"] = "no-cache"
            response.headers["Expires"] = "0"
            return response
        else:
            response = FileResponse(os.path.join(flutter_build_path, "index.html"))
            response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
            response.headers["Pragma"] = "no-cache"
            response.headers["Expires"] = "0"
            return response
else:
    @app.get("/")
    async def root():
        return {
            "message": "Welcome to The Memory Hub API",
            "docs": "/docs",
            "redoc": "/redoc"
        }
