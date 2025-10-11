# Overview

The Memory Hub is a full-stack digital legacy platform that enables families to preserve and share memories, files, and personal content. The application consists of a FastAPI backend (Python) serving both REST APIs and a Flutter web frontend, with MongoDB as the database layer.

The platform provides four core features:
1. **Memories** - Personal diary/journal entries with media attachments, tags, location, and mood tracking
2. **Vault** - Secure file storage with organization, privacy controls, and metadata management
3. **Hub** - Customizable dashboard aggregating memories, files, notes, links, and tasks
4. **User Management** - Authentication, profiles, and social relationships

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Backend Architecture

**Framework**: FastAPI with async/await patterns for handling concurrent requests efficiently

**API Structure**: 
- RESTful API design with versioned endpoints (`/api/v1/`)
- Modular routing system separating concerns (auth, users, memories, vault, hub)
- JWT-based authentication with access/refresh token pattern
- OAuth2 password bearer for token validation
- CORS middleware configured for cross-origin requests

**Authentication & Security**:
- Bcrypt password hashing via passlib
- JWT tokens (jose library) with configurable expiration (7 days access, 30 days refresh)
- Role-based access control (USER/ADMIN roles)
- Secret key generation for token signing

**Data Models**:
- Pydantic v2 for request/response validation and serialization
- Custom ObjectId handling for MongoDB integration
- Enum-based privacy levels (PRIVATE/FRIENDS/PUBLIC)
- Validator decorators for data integrity

## Frontend Architecture

**Framework**: Flutter for cross-platform web, mobile, and desktop support

**Build System**: 
- Flutter web compilation to JavaScript (dart2js)
- CanvasKit renderer for high-fidelity UI
- Service worker integration for offline capability
- Static asset management

**Deployment**: Backend serves compiled Flutter web app alongside APIs from single server

## Data Storage

**Database**: MongoDB with Motor async driver

**Collections**:
- `users` - User accounts with unique email index
- `memories` - Journal entries with media, tags, location data
- `files` - File metadata and storage references
- `hub_items` - Polymorphic content items (memories, files, notes, links, tasks)
- `relationships` - Social connections between users

**File Storage**: 
- Local filesystem storage under `uploads/` directory
- User-specific subdirectories for file organization
- File type validation and MIME type detection
- Configurable size limits (10MB default per file)

**Indexing Strategy**:
- Unique index on user email for authentication
- Support for text search on memories and hub items
- Aggregation pipelines for statistics and filtering

## External Dependencies

**Backend Python Packages**:
- `fastapi` + `uvicorn` - ASGI web framework and server
- `motor` + `pymongo` - Async MongoDB driver
- `pydantic` + `pydantic-settings` - Data validation and configuration
- `python-jose[cryptography]` - JWT token handling
- `passlib[bcrypt]` - Password hashing
- `python-multipart` - File upload handling
- `python-magic` + `pillow` - File type detection and image processing
- `python-dotenv` - Environment variable management

**Frontend Dart Packages**:
- `http` - HTTP client for API calls
- `provider` - State management
- `shared_preferences` - Local storage
- `file_picker` + `image_picker` - File/image selection
- `intl` - Internationalization support
- `cupertino_icons` - iOS-style icons

**Development Tools**:
- `pytest` + `httpx` - Testing framework and async HTTP client
- `flutter_lints` - Dart linting rules

**Third-Party Services**: Currently designed for local deployment with no external API dependencies (weather, location services referenced in models but not implemented)