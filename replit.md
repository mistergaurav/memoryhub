# Overview

The Memory Hub is a full-stack digital legacy platform designed to help families preserve and share memories, files, and personal content. It features a FastAPI backend, a Flutter web frontend, and MongoDB for data storage. The platform offers a comprehensive suite of features for digital remembrance and legacy building, including personal journaling, secure file storage, a customizable dashboard, robust user management, advanced social functionalities, content organization, advanced search, analytics, privacy controls, voice notes, custom categories, emoji reactions, memory templates, two-factor authentication, password reset, geolocation-based features, scheduled posts, and deep genealogy integration. The platform emphasizes GDPR compliance and utilizes a modern Material 3 design system.

# Recent Changes

## Enhanced Relationship Management System (November 20, 2025)

The family circle feature has been transformed into a flexible relationship management system, enabling users to create and manage diverse relationship categories with rich person profile information.

### Key Enhancements:
- **11+ Relationship Categories**: Extended from 2 basic family types to 11+ categories including boyfriend, girlfriend, ex, best friend, close friends, family member, work colleague, acquaintance, mentor, mentee, and custom categories
- **Rich Person Profiles**: Each circle member now supports detailed profiles with display name, custom relationship labels, avatar, email, and personal notes
- **Enhanced API Endpoints**: 
  - `POST /api/v1/family/core/circles/{circle_id}/profiles` - Add person to circle
  - `PUT /api/v1/family/core/circles/{circle_id}/profiles/{user_id}` - Update person profile
  - `DELETE /api/v1/family/core/circles/{circle_id}/profiles/{user_id}` - Remove person from circle
  - `GET /api/v1/family/core/circles/by-category/{category}` - Filter circles by relationship type
- **Backward Compatibility**: Maintains existing `member_ids` field alongside new `member_profiles` for seamless migration
- **Comprehensive Testing**: 10 end-to-end tests validating all CRUD operations, category filtering, and sharing integration

### Technical Implementation:
- Enhanced `CircleMemberProfile` model with user_id, display_name, relationship_label, avatar_url, email, and notes fields
- Updated repository layer with atomic profile management operations
- All sharing features (albums, memories, health records, etc.) automatically compatible with enhanced circles
- Backend configured on port 8000 for API services

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Backend Architecture

**Framework**: FastAPI, utilizing async/await.
**API Structure**: RESTful APIs with versioned endpoints (`/api/v1/`), organized into modular feature modules. Authentication is JWT-based (access/refresh tokens, OAuth2 password bearer).
**Modular Organization**: Backend is structured into highly maintainable, single-responsibility modules for family core, genealogy, and various repositories.
**Authentication & Security**: Bcrypt for password hashing, JWT for token management, and role-based access control.
**Data Models**: Pydantic v2 for request/response validation, custom ObjectId handling, Enum-based privacy levels, and validator decorators. Comprehensive audit logging for GDPR compliance is integrated.

## Frontend Architecture

**Framework**: Flutter, enabling cross-platform web deployment.
**Build System**: Flutter web compiles to JavaScript using the CanvasKit renderer, with service worker integration.
**Deployment**: Single-port architecture where the FastAPI backend (port 5000) serves both API endpoints and Flutter static files, enabling relative API URLs and eliminating CORS complexity.
**State Management**: Provider-based state management with SharedPreferences persistence.
**API Client Optimization**: Centralized API client with built-in caching (5-minute TTL), exponential backoff retry logic, comprehensive error handling, cache invalidation on mutations, and automatic token refresh on 401 errors.

## Data Storage

**Database**: MongoDB, accessed via the Motor async driver, with comprehensive collections for all platform features.
**File Storage**: Cloudflare R2 object storage for secure, scalable cloud-based file storage with S3-compatible API, including presigned URL generation and metadata management. Legacy local filesystem storage is a fallback.
**Indexing Strategy**: Automated database indexing system creates over 30 indexes across 10 collections for performance optimization and GDPR audit logging.

## System Design Choices

**CORS Configuration**: Regex-based origin matching for local development using `allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"` to support any localhost port (e.g., Windows Flutter development on random ports like 61364). Global OPTIONS handler mirrors this logic for proper preflight request handling. Production origins use a static allowlist.
**UI/UX Decisions**: Modern Material 3 design system with design tokens, light/dark theme support, reusable component library, vibrant gradient color schemes, Google Fonts (Inter), and glassmorphic effects. Specific features like health records have professional, color-coded interfaces with animations and filtering.
**Feature Specifications**:
- **Admin Panel**: Dashboard with statistics, user management, and activity tracking.
- **Social Features**: User search, follow/unfollow, enhanced profiles, comments, notifications, activity feeds, ephemeral "Stories," and a social Hub dashboard.
- **Enhanced Configuration**: Platform-aware API configuration with robust error handling and CORS support.
- **2FA**: TOTP-based authentication with QR code generation and backup codes.
- **Password Reset**: Secure token-based system with email verification.
- **Privacy & Security**: Granular privacy settings, user blocking, and visibility controls.
- **Geolocation**: Saving favorite places, attaching memories to locations, and browsing nearby places.
- **Scheduled Posts**: Scheduling memories, stories, and updates.
- **Sharing System**: Universal content sharing with QR codes, password protection, expiration dates, max uses tracking, and access analytics.
- **GDPR Compliance**: Full compliance including data portability, consent management, right to erasure, and transparency. Includes comprehensive audit logging.
- **Family Features**: Collaborative photo albums, aggregated family timeline, shared event calendar, milestone tracking, digital cookbook, time-locked legacy letters, documentation of family traditions, parental controls, visual genealogy tree (with invitation system), medical history tracking, and secure document vault.
- **Health Record Approval Workflow**: Comprehensive user assignment system with approval workflows for health records, allowing users to specify a subject (self, other user, family member, friend circle member) before creation. Features include user search/autocomplete, automatic approval for self-records, pending approval for others, approve/reject endpoints, shared dashboards, and notification integration.
- **Modular Settings**: Redesigned settings with category cards and dedicated detail screens (Privacy, Security, Content, Account).

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
- `openai`: For Whisper integration (voice notes transcription).
- `boto3`: AWS SDK for Python, used for S3-compatible Cloudflare R2 object storage integration.

## Frontend Dart Packages

- `http`: HTTP client for API communication.
- `provider`: State management.
- `shared_preferences`: Local storage.
- `file_picker`, `image_picker`: File and image selection.
- `intl`: Internationalization support.
- `cupertino_icons`: iOS-style icons.
- `table_calendar`: Calendar widget.
- `shimmer`: Loading state animations.
- `jwt_decode`: JWT token parsing and user ID extraction.

## Third-Party Services

- **Email Service Providers**: Resend, SendGrid, SMTP (supported via an email service layer).
- **Cloudflare R2**: Object storage service providing S3-compatible API.