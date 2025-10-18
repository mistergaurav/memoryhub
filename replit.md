# Overview

The Memory Hub is a full-stack digital legacy platform designed to help families preserve and share memories, files, and personal content. It features a FastAPI backend, a Flutter web frontend, and MongoDB for data storage. The platform offers a comprehensive suite of features including personal journaling, secure file storage, a customizable dashboard, robust user management, and advanced social functionalities like comments, notifications, activity feeds, and ephemeral "Stories." Recent expansions include content organization through collections, advanced search, analytics, privacy controls, voice notes, custom categories, emoji reactions, memory templates, two-factor authentication, password reset, geolocation-based features, scheduled posts, and a full suite of family-oriented features. The platform aims to create a rich, secure, and collaborative environment for digital remembrance and legacy building.

## Recent Changes (October 2025)

**Complete UI Navigation Integration**: All 70+ Flutter screens are now fully integrated with comprehensive navigation from Dashboard and Settings screens, ensuring all 40+ backend API endpoints are discoverable through the primary user interface surfaces. Dashboard features 6 quick actions and 20 feature links (including social hubs, collections, activity feed, and all family features). Settings provides 50+ organized links across 10 sections (Security, Privacy, GDPR, Content Creation, Organization, Social & Community, Sharing, Family Hub, Data Storage, About).

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Backend Architecture

**Framework**: FastAPI, utilizing async/await for concurrency.
**API Structure**: RESTful APIs with versioned endpoints (`/api/v1/`), organized into modular feature modules covering core functionalities, social features, sharing, GDPR compliance, and comprehensive family features. Authentication is JWT-based with access/refresh tokens and OAuth2 password bearer.
**Authentication & Security**: Bcrypt for password hashing, JWT for token management, and role-based access control (USER/ADMIN).
**Data Models**: Pydantic v2 for request/response validation, custom ObjectId handling, Enum-based privacy levels, and validator decorators.

## Frontend Architecture

**Framework**: Flutter, enabling cross-platform web, mobile, and desktop deployment.
**Build System**: Flutter web compiles to JavaScript using the CanvasKit renderer, with service worker integration for offline capabilities.
**Deployment**: The backend serves the compiled Flutter web application alongside its APIs.

## Data Storage

**Database**: MongoDB, accessed via the Motor async driver.
**Collections**: A comprehensive schema supports all platform features including users, memories, files, social interactions, and detailed family-related data (e.g., `family_albums`, `genealogy_persons`, `health_records`).
**File Storage**: Local filesystem storage within the `uploads/` directory, organized by user, with file type validation and configurable size limits.
**Indexing Strategy**: Automated database indexing system creates over 30 indexes across 10 collections for performance optimization and GDPR audit logging.

## System Design Choices

**UI/UX Decisions**: Modern Material 3 design and vibrant color schemes (purple, pink, cyan) are utilized for a consistent and enhanced user interface.
**Feature Specifications**:
- **Admin Panel**: Dashboard with statistics, user management, and activity tracking.
- **Social Features**: User search, follow/unfollow, enhanced profiles, and consistent avatar rendering.
- **Enhanced Configuration**: Platform-aware API configuration with robust error handling and CORS support.
- **2FA**: TOTP-based authentication with QR code generation and backup codes.
- **Password Reset**: Secure token-based system with email verification.
- **Privacy & Security**: Granular privacy settings, user blocking, and visibility controls.
- **Geolocation**: Saving favorite places, attaching memories to locations, and browsing nearby places.
- **Scheduled Posts**: Scheduling memories, stories, and updates for future publication.
- **Sharing System**: Universal sharing for all content types with QR codes, password protection, expiration dates, max uses tracking, and access analytics. Security-hardened with 32-character tokens and exact-match validation.
- **GDPR Compliance**: Full compliance with EU GDPR regulations including data portability (JSON/ZIP export), consent management, right to erasure (30-day grace period), and transparency in data processing. Includes comprehensive audit logging.
- **Family Features**: Collaborative photo albums, aggregated family timeline, shared event calendar, milestone tracking, digital cookbook, time-locked legacy letters, documentation of family traditions, parental controls, visual genealogy tree, medical history tracking, and secure document vault.

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
- `requests`: HTTP client.

## Frontend Dart Packages

- `http`: HTTP client for API communication.
- `provider`: State management.
- `shared_preferences`: Local storage.
- `file_picker`, `image_picker`: File and image selection.
- `intl`: Internationalization support.
- `cupertino_icons`: iOS-style icons.
- `table_calendar`: Calendar widget.
- `shimmer`: Loading state animations.

## Development Tools

- `pytest`, `httpx`: Testing framework and async HTTP client.
- `flutter_lints`: Dart linting rules.

## Third-Party Services

- None explicitly integrated; the architecture is designed for local deployment.