# Overview

The Memory Hub is a full-stack digital legacy platform that enables families to preserve and share memories, files, and personal content. The application consists of a FastAPI backend (Python) serving both REST APIs and a Flutter web frontend, with MongoDB as the database layer.

The platform provides 14+ comprehensive features:

## Core Features
1. **Memories** - Personal diary/journal entries with media attachments, tags, location, and mood tracking
2. **Vault** - Secure file storage with organization, privacy controls, and metadata management
3. **Hub** - Customizable dashboard aggregating memories, files, notes, links, and tasks
4. **User Management** - Authentication, profiles, and social relationships

## New Enhanced Features (Latest Release)
5. **Comments System** - Comment on memories, hub items, and files with likes
6. **Notifications** - Real-time notifications for likes, follows, comments, and invitations
7. **Activity Feed** - Social feed showing activities from followed users
8. **Collections/Albums** - Group memories into themed collections
9. **Advanced Search** - Full-text search across all content types with filters
10. **Tags Management** - Browse, organize, and manage tags across all content
11. **Analytics Dashboard** - Detailed statistics, charts, and activity trends
12. **File Sharing** - Generate shareable links with expiration for files
13. **Memory Reminders** - Date-based reminder system for important dates
14. **Export/Backup** - Export memories as JSON and files as ZIP archives

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Backend Architecture

**Framework**: FastAPI with async/await patterns for handling concurrent requests efficiently

**API Structure**: 
- RESTful API design with versioned endpoints (`/api/v1/`)
- Modular routing system with 16 feature modules:
  - Core: auth, users, memories, vault, hub, social
  - Enhanced: comments, notifications, collections, activity, search, tags, analytics, sharing, reminders, export
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
- `comments` - Comments on memories, hub items, and files
- `comment_likes` - Likes on comments
- `notifications` - User notifications for various activities
- `collections` - Memory collections/albums
- `collection_memories` - Many-to-many relationship for collections
- `hubs` - Collaborative hubs
- `hub_members` - Hub membership tracking
- `share_links` - Shareable file links with expiration
- `reminders` - Date-based reminders for users

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

## API Configuration

**Platform-Specific URL Handling**: 
- Web builds use relative URLs (`/api/v1`) to leverage same-origin API calls
- Mobile builds use absolute URLs with Replit domain prefix for cross-platform compatibility
- Asset URLs (avatars, files) intelligently handle both absolute and relative paths
- Hard-coded Replit domain: `https://f1f703b2-5ae2-4384-84cb-cc0d43774e0d-00-1xb1vbt5sy6oi.janeway.replit.dev`

**Note**: When deploying to a different domain, update the `_replitDomain` constant in `memory_hub_app/lib/config/api_config.dart`

## Recent Changes

### October 2025 - Social Features Enhancement
- ✅ **User Search**: Find and connect with other users through comprehensive search functionality
- ✅ **Follow/Unfollow System**: Follow users to see their activities in your feed with one-click follow/unfollow
- ✅ **Enhanced Profile Editing**: Improved edit profile screen with visible Save button and better form handling
- ✅ **Lifecycle Safety**: All async operations properly handle widget lifecycle with mounted checks to prevent crashes
- ✅ **Avatar Integration**: Consistent avatar rendering across all social features using ApiConfig
- ✅ **User Profiles**: View other users' profiles with follower/following counts and social stats

### October 2025 - Production Enhancement Release
- ✅ **Settings Screen**: Comprehensive user settings with notifications, theme, privacy controls, and data management
- ✅ **API Configuration**: Platform-aware URL handling for web, Android, and iOS compatibility
- ✅ **Error Handling**: Robust JSON parsing with fallback error handling in auth service
- ✅ **Flutter Web Build**: Optimized production build with tree-shaken assets
- ✅ **Avatar Support**: Cross-platform avatar rendering with proper URL handling
- ✅ **CORS Support**: Full cross-origin support for web browser access

### December 2025 - Major Feature Release v2.0
- ✅ **Comments System**: Users can now comment on memories, hub items, and files with like functionality
- ✅ **Notifications**: Real-time notification system for all user activities with unread count
- ✅ **Activity Feed**: Social feed showing activities from followed users
- ✅ **Collections**: Memory collections/albums for organizing related memories
- ✅ **Advanced Search**: Full-text search across memories, files, hub items, and collections
- ✅ **Tags Management**: Comprehensive tag browsing, renaming, and deletion across all content
- ✅ **Analytics Dashboard**: Rich analytics with charts, trends, and statistics
- ✅ **File Sharing**: Secure file sharing with expiring shareable links
- ✅ **Memory Reminders**: Reminder system for anniversaries and important dates
- ✅ **Export/Backup**: Full backup functionality with JSON/ZIP export options
- ✅ **Enhanced UI**: Modern Material 3 design with new Flutter screens for all features
- ✅ **Admin Panel**: Complete admin dashboard with user management, statistics, and developer tools
- ✅ **Production-Ready**: API base URL configuration for mobile/web deployment
- ✅ **17 API Modules**: Comprehensive backend with 17 feature modules including admin

## Admin Panel Features

The admin panel provides developers with complete control over the platform:

**Dashboard Statistics**:
- Total users count
- Active users (24-hour tracking)
- New users (7-day tracking)
- Content statistics (memories, files, collections, hubs)
- Storage usage monitoring (GB tracking)

**User Management**:
- Search and filter users
- Pagination support (20 users per page)
- Activate/deactivate user accounts
- Change user roles (user/admin)
- Delete users and all their data
- View user statistics (memories count, files count)

**Activity Tracking**:
- User registration trends over time
- Content creation statistics
- Platform usage analytics
- Popular tags across the platform

