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

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(api_router, prefix="/api/v1")

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
    app.mount("/assets", StaticFiles(directory=os.path.join(flutter_build_path, "assets")), name="assets")
    app.mount("/icons", StaticFiles(directory=os.path.join(flutter_build_path, "icons")), name="icons")
    app.mount("/canvaskit", StaticFiles(directory=os.path.join(flutter_build_path, "canvaskit")), name="canvaskit")
    
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
