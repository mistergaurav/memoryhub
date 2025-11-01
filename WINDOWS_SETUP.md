# Memory Hub - Windows Localhost Setup Guide

This guide explains how to run Memory Hub on your Windows machine for local development.

## Prerequisites

- **Python 3.11+** installed
- **MongoDB** installed and running on port 27017
- **Flutter SDK** installed (for desktop builds)

## Quick Start

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Start MongoDB

Make sure MongoDB is running on `localhost:27017`

```bash
mongod --dbpath /path/to/your/data/directory
```

### 3. Start the Backend Server

The backend runs on **port 5000** and serves both the API and the web app:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
```

### 4. Access the Application

Open your browser and navigate to:

```
http://localhost:5000
```

The backend serves:
- **Web App**: `http://localhost:5000/` (Flutter web build)
- **API Docs**: `http://localhost:5000/docs` (Swagger UI)
- **API Endpoints**: `http://localhost:5000/api/v1/*`

## Building Flutter Desktop App for Windows

If you want to build a native Windows desktop app:

### 1. Configure Backend URL

```bash
cd memory_hub_app
flutter build windows --dart-define=BACKEND_URL=http://localhost:5000/api/v1
```

### 2. Run the Desktop App

```bash
flutter run -d windows --dart-define=BACKEND_URL=http://localhost:5000/api/v1
```

## Important Notes

### Port Configuration

- **Backend**: Runs on port **5000** (not 8000)
- **MongoDB**: Runs on port **27017**
- The Flutter app is configured to connect to `localhost:5000` for both web and desktop builds

### API Configuration

The Flutter app automatically detects the environment:

- **Web (localhost)**: Uses `http://localhost:5000/api/v1`
- **Desktop**: Uses `http://localhost:5000/api/v1` (can be overridden with `BACKEND_URL`)
- **Replit**: Uses relative URLs `/api/v1` (same-origin)

### Environment Variables (Optional)

For custom backend URLs, you can set:

```bash
# For desktop builds
flutter build windows --dart-define=BACKEND_URL=https://your-backend.com/api/v1

# For connecting to Replit backend from Windows
flutter build windows --dart-define=BACKEND_URL=https://your-replit-app.replit.dev/api/v1
```

## Troubleshooting

### 404 Errors

If you're getting 404 errors:

1. Make sure the backend is running on **port 5000**
2. Check that MongoDB is running on port 27017
3. Verify the Flutter web build exists at `memory_hub_app/build/web`

### Rebuilding Flutter Web App

If you made changes to the Flutter code:

```bash
cd memory_hub_app
flutter build web --release
```

Then restart the backend server to serve the new build.

### Port Already in Use

If port 5000 is already in use, you can:

1. Find and stop the process using port 5000
2. Or run the backend on a different port and update the Flutter config

## Development Workflow

1. **Start MongoDB**: `mongod`
2. **Start Backend**: `uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload`
3. **Open Browser**: Navigate to `http://localhost:5000`
4. **Make Changes**: Edit code in `memory_hub_app/lib/` for Flutter or `app/` for backend
5. **Rebuild Flutter** (if needed): `cd memory_hub_app && flutter build web --release`
6. **Backend Auto-Reloads**: Thanks to `--reload` flag

## API Documentation

Once the backend is running, visit:

- Swagger UI: `http://localhost:5000/docs`
- ReDoc: `http://localhost:5000/redoc`

## Support

For issues or questions, check the main README.md or consult the project documentation.
