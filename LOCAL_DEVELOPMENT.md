# Local Development Guide

This guide will help you run The Memory Hub application on your local machine.

## Prerequisites

- **Python 3.11+** installed
- **Flutter 3.0+** installed
- **MongoDB** running on `localhost:27017`

## Step 1: Start MongoDB

Make sure MongoDB is running locally on the default port 27017:

```bash
# On Ubuntu/Debian
sudo systemctl start mongod

# On macOS with Homebrew
brew services start mongodb-community

# Or run manually
mongod --dbpath /path/to/your/data --bind_ip localhost --port 27017
```

## Step 2: Start the Backend (FastAPI)

1. Navigate to the project root directory
2. Install Python dependencies (if not already installed):
   ```bash
   pip install -r requirements.txt
   ```

3. Start the backend server on port 5000:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
   ```

The backend should now be running at `http://localhost:5000`

**Important:** The backend MUST run on port 5000 for the Flutter app to connect to it.

## Step 3: Run the Flutter App

Open a **new terminal window** and run:

```bash
cd memory_hub_app

# Get Flutter dependencies
flutter pub get

# Run the app in Chrome (recommended for development)
flutter run -d chrome
```

The Flutter development server will automatically start on an available port (usually 8080).

## CORS Configuration

The backend has been configured to accept requests from common Flutter development ports:
- Port 3000, 3001 (React, Next.js)
- Port 4200 (Angular)
- Port 5173 (Vite)
- Port 8000, 8080, 8081, 8082 (Flutter, Django, general dev servers)
- Port 5500, 5501 (VS Code Live Server)

If Flutter is running on a different port and you get CORS errors:
1. Check what port Flutter is using (it shows in the terminal)
2. Add that port to the `allowed_origins` list in `app/main.py` (line 54)
3. Restart the backend

## Troubleshooting

### Issue: "Failed to connect to backend" or "Network error"

**Solution:**
1. Verify the backend is running on port 5000
2. Check the browser console for CORS errors
3. Make sure MongoDB is running

### Issue: "CORS policy blocked the request"

**Solution:**
1. Check what port Flutter is running on (shown in terminal output)
2. Verify that port is in the allowed origins list in `app/main.py`
3. Restart the backend after making changes

### Issue: "Connection refused on localhost:5000"

**Solution:**
1. Make sure the backend is actually running
2. Check if another service is using port 5000
3. Try accessing `http://localhost:5000/docs` in your browser to verify

## API Documentation

Once the backend is running, you can access:
- **Interactive API Docs (Swagger):** http://localhost:5000/docs
- **Alternative API Docs (ReDoc):** http://localhost:5000/redoc

## Testing Login

1. Open the Flutter app in your browser
2. Register a new account or use existing credentials:
   - Email: star@star.com (if it exists in your local database)
3. Login should work without errors

If login doesn't work:
- Open browser DevTools (F12) → Network tab
- Try to login and check the network request to `/api/v1/auth/login`
- Look for any error responses or CORS issues

## Environment Variables (Optional)

For production deployments, you should set these environment variables:

```bash
# Security
export SECRET_KEY="your-super-secret-key-here"
export ALGORITHM="HS256"

# Database
export MONGODB_URL="mongodb://localhost:27017"
export DB_NAME="memory_hub"
```

For local development, the app uses hardcoded defaults which is fine.

## Next Steps

After verifying everything works locally:
1. Create some test data (memories, health records, family tree persons)
2. Test the features to ensure they're working correctly
3. Check that data persists across backend restarts
