# Memory Hub - Configuration Guide

This guide explains how to configure the Memory Hub Flutter app to connect to different backend servers.

## Configuration Options

The app supports multiple ways to configure the backend URL:

### 1. **For Local Development (Default)**
By default, the app connects to `http://localhost:8000` for native builds and automatically detects the backend for web builds.

No configuration needed!

### 2. **For Windows/Desktop Builds Connecting to Remote Backend**

You have two options:

#### Option A: Using Environment Variables (Recommended)

Build the app with the `--dart-define` flag to specify your backend URL:

```bash
# Build for Windows with custom backend
flutter build windows --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1

# Or specify both HTTP and WebSocket URLs
flutter build windows \
  --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1 \
  --dart-define=BACKEND_WS_URL=wss://8000-yourapp.replit.dev/ws

# Build for macOS
flutter build macos --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1

# Build for Linux
flutter build linux --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1
```

#### Option B: Using Default Backend

Set a default backend that will be used for all native builds:

```bash
flutter build windows --dart-define=DEFAULT_BACKEND=https://8000-yourapp.replit.dev
```

### 3. **For Web Builds (Replit)**

Web builds automatically detect the backend URL based on the current hostname:

```bash
# Build for web (auto-detects Replit backend)
flutter build web --release

# Or build for local web development
flutter build web --release
```

**Replit Detection:**
- If running on `*.replit.dev` or `*.repl.co`, the app automatically constructs the backend URL by replacing the port number
- Frontend on `5000-xxx.replit.dev` → Backend on `8000-xxx.replit.dev`
- Frontend on `xxx.replit.dev` → Backend on `8000-xxx.replit.dev`

### 4. **For Development/Testing**

Run in development mode with custom backend:

```bash
# Windows
flutter run -d windows --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1

# Web
flutter run -d chrome --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1

# Android
flutter run -d android --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1
```

## Configuration Examples

### Example 1: Windows Build for Production Replit Backend

```bash
# Replace 'yourapp' with your Replit app name
flutter build windows --release \
  --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1 \
  --dart-define=BACKEND_WS_URL=wss://8000-yourapp.replit.dev/ws
```

### Example 2: Android Build for Replit Backend

```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://8000-yourapp.replit.dev/api/v1
```

### Example 3: Local Development (Default)

```bash
# No configuration needed - uses localhost:8000
flutter run
```

## Troubleshooting

### Issue: App can't connect to backend

**Solution 1:** Verify your backend URL is correct
- Check that the URL includes the protocol (`http://` or `https://`)
- Ensure the port number is correct (8000 for backend)
- Test the URL in a browser first

**Solution 2:** Check the current configuration
The app logs the current environment and URLs on startup. Look for:
```
Current Environment: [environment info]
Base URL: [your backend URL]
```

**Solution 3:** CORS Issues
If you see CORS errors, ensure your backend's CORS configuration allows requests from your frontend domain.

### Issue: WebSocket connection fails

Make sure you're using the correct protocol:
- `ws://` for HTTP backends
- `wss://` for HTTPS backends

### Issue: Assets/images not loading

The app automatically constructs asset URLs based on the backend URL. Ensure your backend is serving static files correctly.

## Getting Your Replit Backend URL

1. Open your Replit project
2. Look at the URL when accessing the backend
3. The format will be one of:
   - `https://8000-xxxxx.replit.dev` (new format)
   - `https://yourapp.repl.co` (older format)
   - `https://xxxxx-xxxxx.replit.dev` (deployment)

## Advanced: Multiple Environments

You can create build scripts for different environments:

**build-prod.bat** (Windows):
```batch
flutter build windows --release ^
  --dart-define=BACKEND_URL=https://8000-prod.replit.dev/api/v1
```

**build-staging.bat** (Windows):
```batch
flutter build windows --release ^
  --dart-define=BACKEND_URL=https://8000-staging.replit.dev/api/v1
```

**build-prod.sh** (Mac/Linux):
```bash
#!/bin/bash
flutter build macos --release \
  --dart-define=BACKEND_URL=https://8000-prod.replit.dev/api/v1
```

## Summary

| Platform | Default Backend | Override Method |
|----------|----------------|-----------------|
| Web (Replit) | Auto-detected from URL | N/A (automatic) |
| Web (Local) | localhost:8000 | N/A (automatic) |
| Windows | localhost:8000 | `--dart-define=BACKEND_URL=...` |
| macOS | localhost:8000 | `--dart-define=BACKEND_URL=...` |
| Linux | localhost:8000 | `--dart-define=BACKEND_URL=...` |
| Android | localhost:8000 | `--dart-define=BACKEND_URL=...` |
| iOS | localhost:8000 | `--dart-define=BACKEND_URL=...` |

---

For more information, see the main README or WINDOWS_LOCAL_SETUP.txt files.
