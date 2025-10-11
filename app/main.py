from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from app.api.v1.api import api_router
from app.core.config import settings
from app.db.mongodb import connect_to_mongo, close_mongo_connection
import os

app = FastAPI(
    title="The Memory Hub API",
    description="API for The Memory Hub - Your Family's Digital Legacy",
    version="1.0.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connection events
@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()

@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

# Include API routers
app.include_router(api_router, prefix="/api/v1")

# Serve Flutter web app
flutter_build_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "memory_hub_app", "build", "web")
if os.path.exists(flutter_build_path):
    app.mount("/assets", StaticFiles(directory=os.path.join(flutter_build_path, "assets")), name="assets")
    app.mount("/icons", StaticFiles(directory=os.path.join(flutter_build_path, "icons")), name="icons")
    app.mount("/canvaskit", StaticFiles(directory=os.path.join(flutter_build_path, "canvaskit")), name="canvaskit")
    
    @app.get("/{full_path:path}")
    async def serve_flutter_app(full_path: str):
        if full_path.startswith("api/") or full_path.startswith("docs") or full_path.startswith("redoc"):
            return {"error": "Not found"}
        
        file_path = os.path.join(flutter_build_path, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        else:
            return FileResponse(os.path.join(flutter_build_path, "index.html"))
else:
    @app.get("/")
    async def root():
        return {
            "message": "Welcome to The Memory Hub API",
            "docs": "/docs",
            "redoc": "/redoc"
        }