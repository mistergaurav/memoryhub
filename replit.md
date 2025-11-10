# Overview

The Memory Hub is a full-stack digital legacy platform designed to help families preserve and share memories, files, and personal content. It features a FastAPI backend, a Flutter web frontend, and MongoDB for data storage. The platform offers a comprehensive suite of features including personal journaling, secure file storage, a customizable dashboard, robust user management, and advanced social functionalities. Recent expansions include content organization, advanced search, analytics, privacy controls, voice notes, custom categories, emoji reactions, memory templates, two-factor authentication, password reset, geolocation-based features, scheduled posts, and a full suite of family-oriented features including deep genealogy integration. The platform aims to create a rich, secure, and collaborative environment for digital remembrance and legacy building, with a strong focus on GDPR compliance and a modern Material 3 design system.

# User Preferences

Preferred communication style: Simple, everyday language.

# Recent Updates (November 2025)

**Critical Bug Fixes & Signup Flow Improvements (November 10, 2025):**
- **User Search Enhancement**: Fixed `/api/v1/users/search` endpoint to return proper "No users found" messaging when search returns empty results. Search is now scoped to connected users only (prevents user enumeration attacks).
- **Activity Endpoint Routing**: Verified and fixed activity feed routing at `/api/v1/activity` to properly route to `/api/v1/social/hub/activity`, ensuring frontend can fetch activity feeds correctly.
- **Health Records Dashboard Fix**: Resolved 500 errors in `get_health_dashboard()` by adding defensive None checks and proper ObjectId validation to prevent crashes when records have missing or invalid data.
- **Health Record Detail Fix**: Fixed 400 errors when viewing health record details by improving ObjectId validation to return proper 404 responses for invalid IDs instead of validation errors.
- **Type Safety Improvements**: Fixed 19 LSP type errors in `health_record_service.py` by adding proper None guards, type annotations, and defensive programming patterns to handle potentially None values from database operations.
- **Improved Signup Flow**: Completely redesigned user registration experience for better UX:
  - **Backend**: Modified `/auth/register` endpoint to return JWT tokens immediately (RegisterResponse with access_token, refresh_token, user info, and email_verified flag)
  - **Frontend**: Removed confirm password field from signup form, reducing friction
  - **Auto-Login**: Users are automatically logged in after signup with tokens saved to SharedPreferences
  - **Dashboard Redirect**: New users are redirected directly to dashboard instead of login screen
  - **Security Maintained**: All password hashing, validation, and security measures preserved; email verification still sent but doesn't block initial access

**Genealogy Relationship System Overhaul (November 5, 2025):**
- **Bidirectional Relationship Creation**: Implemented automatic bidirectional handling for all genealogy relationships. When a parent-child relationship is created, the system now automatically creates both parent→child and child→parent records. Spouse and sibling relationships are created symmetrically in both directions.
- **Duplicate Prevention**: Added comprehensive validation to prevent duplicate and inverse relationships. System checks for existing relationships in both directions before creating new ones.
- **Relationship Type Helpers**: Added utility functions `get_inverse_relationship_type()` and `is_symmetric_relationship()` for proper relationship type handling across parent/child, grandparent/grandchild, aunt_uncle/niece_nephew, spouse, sibling, and cousin types.
- **Enhanced Repository Methods**: Added `find_existing_relationship()` and `find_any_relationship_between()` methods to GenealogyRelationshipRepository for efficient duplicate detection.

**Tree Membership & Access Control (November 5, 2025):**
- **Invitation Acceptance Fix**: When users accept genealogy tree invitations, the system now properly creates tree membership records with "member" role and transactional integrity.
- **Automatic Owner Assignment**: Tree creators automatically receive "owner" role when creating their first person in their genealogy tree.
- **Access Validation**: Enhanced `ensure_tree_access()` function validates tree access through membership records, ensuring only authorized users can view/modify trees.

**Family Circles Feature (November 5, 2025):**
- **Backend Implementation**: Complete CRUD API at `/api/v1/family/core/circles` with create, read, update, delete operations. Member management endpoints for adding/removing circle members.
- **Flutter Models**: `FamilyCircle`, `CircleMember`, `FamilyCircleCreate`, and `FamilyCircleUpdate` models with proper JSON serialization.
- **Flutter Service**: `FamilyCirclesService` extending FamilyApiClient with caching, retry logic, and comprehensive error handling (ApiException, NetworkException, AuthException).
- **Flutter Screens**: 
  - `FamilyCirclesScreen`: Grid layout with responsive columns, pull-to-refresh, infinite scroll pagination, loading shimmer effects, and empty/error states.
  - `FamilyCircleDetailScreen`: SliverAppBar with gradient, member list with avatars, owner-only actions (edit/delete circle, remove members), add member functionality.
  - `CreateFamilyCircleDialog`: Form-based dialog for creating/editing circles with circle type selection (Immediate Family, Extended Family, Close Friends, Work Friends, Custom) and color picker.
- **Dashboard Integration**: Replaced "Coming Soon" snackbar on family dashboard with proper navigation to Family Circles screen.
- **Design Consistency**: All components use MemoryHub design system (MemoryHubColors, MemoryHubSpacing, MemoryHubBorderRadius) and follow existing UI patterns.

**Previous Bug Fixes:**
- **Tree Service Data Parsing**: Fixed root cause of "Failed to load genealogy tree" error. Backend returns `{nodes: [...], relationships: [...], stats: {...}}` but frontend was treating it as a direct list. Updated `GenealogyTreeService.getTreeNodes()` to properly unwrap the response with defensive null checks and descriptive error messages.
- **JSON Parser Type Safety**: Added `_parseStringList()` helper to `GenealogyPerson` and `GenealogyTreeNode` models to safely handle backend responses that can be `List<String>` or `List<Map>`. This prevents type casting crashes.
- **PersonCard Layout Overflow**: Fixed 21px RenderFlex overflow in genealogy grid view by changing `mainAxisAlignment: spaceBetween` to `mainAxisSize: min` and removing problematic `Spacer` widget.
- **Defensive Programming**: All list access now includes bounds checking and null guards. Empty list handling prevents `RangeError` exceptions throughout genealogy, relationship, and family circle features.

# System Architecture

## Backend Architecture

**Framework**: FastAPI, utilizing async/await for concurrency.
**API Structure**: RESTful APIs with versioned endpoints (`/api/v1/`), organized into modular feature modules. Authentication is JWT-based with access/refresh tokens and OAuth2 password bearer.
**Modular Organization**: Backend refactored into highly maintainable modular structure:
- **Family Core Endpoints** (`app/api/v1/endpoints/family/core/`): 6 modules (dashboard, relationships, circles, invitations, members, utils), all under 300 lines
- **Genealogy Endpoints** (`app/api/v1/endpoints/family/genealogy/`): 7 modules (persons, relationships, tree, invitations, search, utils, permissions), all under 500 lines
- **Repository Layer** (`app/repositories/family/`): 21 single-responsibility repositories for core features, genealogy, family features, and health records
**Authentication & Security**: Bcrypt for password hashing, JWT for token management, and role-based access control (USER/ADMIN).
**Data Models**: Pydantic v2 for request/response validation, custom ObjectId handling, Enum-based privacy levels, and validator decorators. Comprehensive audit logging for GDPR compliance is integrated across all family modules.

## Frontend Architecture

**Framework**: Flutter, enabling cross-platform web deployment.
**Build System**: Flutter web compiles to JavaScript using the CanvasKit renderer, with service worker integration for offline capabilities.
**Deployment**: Single-port architecture - FastAPI backend (port 5000) serves both API endpoints (`/api/v1/*`) and Flutter static files. This consolidation enables relative API URLs in the frontend and eliminates CORS complexity.
**State Management**: Provider-based state management with SharedPreferences persistence for theme/user session data.
**API Client Optimization**: Centralized API client (`memory_hub_app/lib/services/family/api_client.dart`) with built-in caching (5-minute TTL), exponential backoff retry logic (3 retries max), comprehensive error handling, cache invalidation on mutations, and automatic token refresh on 401 errors. Uses relative URLs (`/api/v1/*`) for seamless same-origin requests.

## Data Storage

**Database**: MongoDB, accessed via the Motor async driver.
**Collections**: A comprehensive schema supports all platform features including users, memories, files, social interactions, and detailed family-related data (e.g., `family_albums`, `genealogy_persons`, `health_records`).
**File Storage**: Cloudflare R2 object storage for secure, scalable cloud-based file storage with S3-compatible API. Features include presigned URL generation for secure access, file metadata management, and organized storage structure. Legacy local filesystem storage in `uploads/` directory remains available as fallback.
**Indexing Strategy**: Automated database indexing system creates over 30 indexes across 10 collections for performance optimization and GDPR audit logging.

## System Design Choices

**UI/UX Decisions**: Modern Material 3 design system with design tokens (colors, typography, spacing), light/dark theme support, reusable component library, and vibrant gradient color schemes (Indigo, Purple, Pink) with Google Fonts (Inter). Features glassmorphic effects for modern aesthetics. Health records feature a professional medical-themed interface with color-coded record types (Medical Blue #2563EB, Teal Green #14B8A6, Success Green #10B981), smooth animations, grid/list view toggle, and advanced filtering capabilities.
**Feature Specifications**:
- **Admin Panel**: Dashboard with statistics, user management, and activity tracking.
- **Social Features**: User search, follow/unfollow, enhanced profiles with hero header/gradient backgrounds/@username display/animated stats cards/tabbed navigation, consistent avatar rendering, comments, notifications, activity feeds with mixed content cards/infinite scroll/engagement buttons, ephemeral "Stories," Hub dashboard with stats/quick actions/filter chips/optimistic updates, full backend integration with token refresh handling and pagination.
- **Enhanced Configuration**: Platform-aware API configuration with robust error handling and CORS support.
- **2FA**: TOTP-based authentication with QR code generation and backup codes.
- **Password Reset**: Secure token-based system with email verification.
- **Privacy & Security**: Granular privacy settings, user blocking, and visibility controls.
- **Geolocation**: Saving favorite places, attaching memories to locations, and browsing nearby places.
- **Scheduled Posts**: Scheduling memories, stories, and updates for future publication.
- **Sharing System**: Universal sharing for all content types with QR codes, password protection, expiration dates, max uses tracking, and access analytics. Security-hardened with 32-character tokens and exact-match validation.
- **GDPR Compliance**: Full compliance including data portability (JSON/ZIP export), consent management, right to erasure (30-day grace period), and transparency in data processing. Includes comprehensive audit logging.
- **Family Features**: Collaborative photo albums, aggregated family timeline, shared event calendar, milestone tracking, digital cookbook, time-locked legacy letters, documentation of family traditions, parental controls, visual genealogy tree (5-step wizard with invitation system), medical history tracking (hereditary conditions), and secure document vault.
- **Health Record Approval Workflow**: Comprehensive user assignment system with approval workflows for health records. UX follows a "who-first" flow with 4 subject categories (Myself, Another user, A family member, Someone in my friend circle), allowing users to select WHO the record is for before specifying relationship details. Features include: user search/autocomplete for selecting family and circle members, automatic approval for self-records and pending approval for records created for others, approve/reject endpoints with access control, shared health dashboards showing records created by others, notification system integration (4 new notification types: HEALTH_RECORD_ASSIGNMENT, HEALTH_REMINDER_ASSIGNMENT, HEALTH_RECORD_APPROVED, HEALTH_RECORD_REJECTED), reminder assignments to specific users, and approval status badges in the UI (pending, approved, rejected). Backend schema properly maps to different ID fields (subject_user_id, subject_family_member_id, subject_friend_circle_id) based on subject category.
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

- **Email Service Providers**: Resend, SendGrid, SMTP (support for various providers through an email service layer).
- **Cloudflare R2**: Object storage service providing S3-compatible API for secure, scalable cloud file storage. Configured via environment variables (R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ENDPOINT_URL, R2_BUCKET_NAME) managed through Replit's secrets system.