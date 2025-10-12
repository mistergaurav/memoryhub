# Overview

The Memory Hub is a full-stack digital legacy platform designed to help families preserve and share memories, files, and personal content. It features a FastAPI backend (Python 3.9.21, port 8000), a Flutter web frontend (port 5000), and MongoDB for data storage (port 27017). The platform offers a comprehensive suite of features including personal journaling (Memories), secure file storage (Vault), a customizable dashboard (Hub), and robust user management. Recent enhancements (V2.0 and V3.0) have introduced social features like comments, notifications, and activity feeds, content organization through collections, advanced search, analytics, and privacy controls. The latest additions include ephemeral "Stories," voice notes, custom categories, emoji reactions, memory templates, two-factor authentication, password reset, geolocation-based features, and scheduled posts, aiming to create a rich and secure environment for digital remembrance.

# User Preferences

Preferred communication style: Simple, everyday language.

# Recent Changes

**October 12, 2025 - Replit Environment Configuration Fix:**
- Fixed critical API configuration to work with Replit's port-specific subdomain system
- Implemented intelligent hostname rewriting for both port-prefixed (5000-slug.repl.co → 8000-slug.repl.co) and non-port-prefixed (slug.repl.co → 8000-slug.repl.co) Replit domains
- Removed dependency on dart:html, now using Uri.base with proper null safety for cross-platform compatibility
- Applied consistent logic across all API endpoints (HTTP, WebSocket, and asset URLs)
- Fixed memory tags JSON encoding in both frontend and backend
- Enhanced UI with vibrant Material 3 color scheme (purple #7C3AED, pink #EC4899, cyan #06B6D4)
- All workflows running successfully: Backend (8000), Frontend (5000), MongoDB (27017)
- Production-ready for all Replit deployment scenarios

# System Architecture

## Backend Architecture

**Framework**: FastAPI, utilizing async/await for concurrency.

**API Structure**: RESTful APIs with versioned endpoints (`/api/v1/`), organized into 27 modular feature modules covering core functionalities (auth, users, memories, vault, hub, social) and enhanced features (comments, notifications, stories, 2FA, etc.). Authentication is JWT-based with access/refresh tokens and OAuth2 password bearer. CORS middleware is configured.

**Authentication & Security**: Employs Bcrypt for password hashing, JWT for token management (7-day access, 30-day refresh), and role-based access control (USER/ADMIN).

**Data Models**: Pydantic v2 for request/response validation. Custom ObjectId handling for MongoDB, Enum-based privacy levels, and validator decorators ensure data integrity.

## Frontend Architecture

**Framework**: Flutter, enabling cross-platform web, mobile, and desktop deployment.

**Build System**: Flutter web compiles to JavaScript (dart2js) using the CanvasKit renderer for high-fidelity UI, with service worker integration for offline capabilities and static asset management.

**Deployment**: The backend serves the compiled Flutter web application alongside its APIs from a single server.

## Data Storage

**Database**: MongoDB, accessed via the Motor async driver.

**Collections**: A comprehensive schema includes `users`, `memories`, `files`, `hub_items`, `relationships`, `comments`, `notifications`, `collections`, `stories`, `voice_notes`, `categories`, `reactions`, `memory_templates`, `password_resets`, `places`, and `scheduled_posts`, among others, designed to support all platform features.

**File Storage**: Local filesystem storage within the `uploads/` directory, organized by user. Includes file type validation, MIME type detection, and configurable size limits (10MB default per file).

**Indexing Strategy**: Unique index on user email, support for text search across content types, and aggregation pipelines for analytics.

## System Design Choices

**UI/UX Decisions**: Modern Material 3 design utilized for new Flutter screens, ensuring a consistent and enhanced user interface across the platform.

**Feature Specifications**:
- **Admin Panel**: Provides a dashboard with statistics (user counts, storage usage), user management (search, filter, activate/deactivate, role change, delete), and activity tracking (registration trends, content creation).
- **Social Features**: User search, follow/unfollow system, enhanced profile editing, consistent avatar rendering, and user profiles with social stats.
- **Enhanced Configuration**: Platform-aware API configuration for web, Android, and iOS, with robust error handling for JSON parsing and CORS support.
- **2FA**: TOTP-based authentication with QR code generation and backup codes.
- **Password Reset**: Secure token-based system with email verification (placeholder).
- **Privacy & Security**: Granular privacy settings, user blocking, and visibility controls.
- **Geolocation**: Saving favorite places, attaching memories to locations, and browsing nearby places.
- **Scheduled Posts**: Scheduling memories, stories, and updates for future publication.

# External Dependencies

## Backend Python Packages

- `fastapi`, `uvicorn`: Web framework and server.
- `motor`, `pymongo`: Async MongoDB driver.
- `pydantic`, `pydantic-settings`: Data validation and configuration.
- `python-jose[cryptography]`: JWT token handling.
- `passlib[bcrypt]`: Password hashing.
- `python-multipart`: File upload handling.
- `python-magic`, `pillow`: File type detection and image processing.
- `python-dotenv`: Environment variable management.
- `pyotp`, `qrcode`: Two-factor authentication and QR code generation.
- `requests`: HTTP client for potential external API calls (currently minimal).

## Frontend Dart Packages

- `http`: HTTP client for API communication.
- `provider`: State management.
- `shared_preferences`: Local storage.
- `file_picker`, `image_picker`: File and image selection.
- `intl`: Internationalization support.
- `cupertino_icons`: iOS-style icons.

## Development Tools

- `pytest`, `httpx`: Testing framework and async HTTP client.
- `flutter_lints`: Dart linting rules.

## Third-Party Services

- The architecture is designed for local deployment with no active third-party API integrations (e.g., weather, specific location services) beyond the core tools listed.