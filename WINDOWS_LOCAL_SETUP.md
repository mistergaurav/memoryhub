# Windows Local Development Setup Guide

This guide explains how to run the Memory Hub application locally on Windows.

## Prerequisites

1. **Python 3.9+** installed on Windows
2. **Flutter SDK** installed (for mobile/desktop app development)
3. **MongoDB** installed locally or access to MongoDB Atlas
4. **Git** installed

## Backend Setup (FastAPI)

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd memory-hub
```

### 2. Set Up Python Virtual Environment
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows Command Prompt:
venv\Scripts\activate

# On Windows PowerShell:
venv\Scripts\Activate.ps1
```

### 3. Install Python Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables
Create a `.env` file in the root directory:

```env
# MongoDB Configuration
MONGODB_URL=mongodb://localhost:27017
DB_NAME=memory_hub

# Security
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=30

# Server
HOST=0.0.0.0
PORT=5000
```

### 5. Start MongoDB Locally
```bash
# If MongoDB is installed as a service, it should already be running
# Otherwise, start it manually:
mongod --dbpath C:\data\db
```

### 6. Run the Backend Server
```bash
# Make sure virtual environment is activated
uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
```

The API will be available at: `http://localhost:5000`
API Documentation: `http://localhost:5000/docs`

## Flutter App Setup (Mobile/Desktop)

### 1. Navigate to Flutter Project
```bash
cd memory_hub_app
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Configure for Local Development

#### Option A: Using Environment Variable (Recommended)
```bash
# Run with localhost configuration
flutter run --dart-define=USE_LOCALHOST=true
```

#### Option B: Modify api_config.dart
Edit `lib/config/api_config.dart` and set:
```dart
static const bool _useLocalhost = true;
```

### 4. Run the Flutter App

#### For Windows Desktop:
```bash
flutter run -d windows --dart-define=USE_LOCALHOST=true
```

#### For Android Emulator:
```bash
# Note: Use 10.0.2.2 instead of localhost for Android emulator
flutter run -d emulator --dart-define=API_URL=http://10.0.2.2:5000
```

#### For Web:
```bash
flutter run -d chrome
# Web uses the backend proxy, so no special configuration needed
```

## Running Both Backend and Frontend

### Option 1: Two Terminal Windows
Terminal 1 (Backend):
```bash
cd memory-hub
venv\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
```

Terminal 2 (Flutter):
```bash
cd memory-hub\memory_hub_app
flutter run -d windows --dart-define=USE_LOCALHOST=true
```

### Option 2: Using PowerShell Script
Create `run_local.ps1`:
```powershell
# Start backend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd app; ..\venv\Scripts\activate; uvicorn main:app --host 0.0.0.0 --port 5000 --reload"

# Wait for backend to start
Start-Sleep -Seconds 5

# Start Flutter app
cd memory_hub_app
flutter run -d windows --dart-define=USE_LOCALHOST=true
```

Run with:
```bash
powershell -ExecutionPolicy Bypass -File run_local.ps1
```

## Testing the Setup

1. Open browser and go to `http://localhost:5000/docs`
2. You should see the FastAPI Swagger documentation
3. Run the Flutter app - it should connect to your local backend

## Troubleshooting

### Backend Issues:
- **Port already in use**: Change PORT in .env or kill the process using port 5000
  ```bash
  netstat -ano | findstr :5000
  taskkill /PID <process_id> /F
  ```
- **MongoDB connection error**: Ensure MongoDB is running
- **Import errors**: Reinstall requirements `pip install -r requirements.txt`

### Flutter Issues:
- **Connection refused**: Ensure backend is running on port 5000
- **Android emulator**: Use `10.0.2.2` instead of `localhost`
- **CORS errors**: Check backend CORS middleware configuration

## Production Deployment vs Local Development

| Aspect | Local (Windows) | Production (Replit) |
|--------|----------------|---------------------|
| Backend URL | http://localhost:5000 | https://[replit-url] |
| Database | Local MongoDB | Replit MongoDB/Atlas |
| Flutter Config | USE_LOCALHOST=true | Default (Replit URL) |
| Hot Reload | ✅ Yes | ❌ No |

## New Features Added

The application now includes 10+ new features:

1. **Stories** - 24-hour ephemeral content
2. **Voice Notes** - Audio memories with transcription
3. **Categories** - Organize memories by custom categories
4. **Reactions** - Emoji reactions on memories/comments
5. **Memory Templates** - Reusable templates for common memory types
6. **Two-Factor Authentication (2FA)** - Enhanced security
7. **Password Reset** - Self-service password recovery
8. **Privacy Settings** - Granular privacy controls
9. **Places/Geolocation** - Location-based memories
10. **Scheduled Posts** - Schedule memories for future posting

## API Endpoints

All new endpoints are available at:
- Stories: `/api/v1/stories`
- Voice Notes: `/api/v1/voice-notes`
- Categories: `/api/v1/categories`
- Reactions: `/api/v1/reactions`
- Templates: `/api/v1/memory-templates`
- 2FA: `/api/v1/2fa`
- Password Reset: `/api/v1/password-reset`
- Privacy: `/api/v1/privacy`
- Places: `/api/v1/places`
- Scheduled Posts: `/api/v1/scheduled-posts`

View full API documentation at: `http://localhost:5000/docs`

## Support

For issues or questions, please refer to the main README.md or create an issue in the repository.
