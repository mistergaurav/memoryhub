# Memory Hub - Production Setup Guide

## Overview
This guide covers the setup of production-ready features that replace mock/placeholder implementations.

## New Production Features

### 1. Email Service 📧
**Location:** `app/services/email_service.py`

Professional email service supporting multiple providers:
- **Resend** (Recommended - Modern email API)
- **SendGrid** (Enterprise-grade email service)
- **SMTP** (Fallback for custom mail servers)

**Features:**
- Password reset emails with secure tokens
- Email verification for new user signups
- Welcome emails after successful verification
- Beautiful HTML email templates with mobile-friendly design
- Automatic fallback if email service is not configured

**Email Templates Include:**
- Professional branding with gradient headers
- Clear call-to-action buttons
- Plain text alternatives for accessibility
- Security notices and expiration warnings

### 2. File Storage Service 📁
**Location:** `app/services/storage_service.py`

Production-ready file handling with:
- **Automatic file categorization** (audio, images, videos, documents)
- **User-based organization** for privacy
- **Unique filename generation** to prevent conflicts
- **File size tracking** for storage analytics
- **Audio duration calculation** (requires ffmpeg)
- **Secure path validation** to prevent directory traversal attacks

**Supported Categories:**
- Audio files (.mp3, .wav, .ogg, .m4a)
- Images (.jpg, .png, .gif, .webp)
- Videos (.mp4, .webm)
- Documents (.pdf, .doc, .docx)

### 3. Voice Notes with Real Transcription 🎤
**Location:** `app/api/v1/endpoints/content/voice_notes.py`

Enhanced voice notes feature:
- **Real audio file storage** with proper validation
- **File size and duration tracking**
- **OpenAI Whisper integration** for automatic transcription
- **Transcription caching** to avoid redundant API calls
- **Graceful fallback** when transcription service is unavailable

**Requirements:**
- Set `OPENAI_API_KEY` environment variable for transcription
- Audio files stored in `uploads/audio/` directory
- Supports all common audio formats

### 4. Email Verification System ✅
**Location:** `app/api/v1/endpoints/auth/email_verification.py`

Complete email verification flow:
- **Secure token generation** (32-byte URL-safe tokens)
- **24-hour token expiration** for security
- **Automatic welcome email** after successful verification
- **Resend verification** endpoint for users who didn't receive email
- **Email verification status** tracked in user profile

**Endpoints:**
- `POST /api/v1/auth/verify-email` - Verify email with token
- `POST /api/v1/auth/resend-verification` - Resend verification email

### 5. Password Reset with Email 🔐
**Location:** `app/api/v1/endpoints/auth/password_reset.py`

Production-ready password reset:
- **Real email sending** with secure reset links
- **1-hour token expiration** for security
- **Token usage tracking** to prevent reuse
- **Secure token storage** in database
- **Admin history endpoint** for security monitoring

### 6. Media File Serving 🖼️
**Location:** `app/api/v1/endpoints/media.py`

Secure file serving with:
- **Path traversal protection** for security
- **Automatic MIME type detection**
- **Support for all media types** (audio, video, images, documents)
- **Direct file streaming** for optimal performance

**URL Pattern:**
`/uploads/{category}/{user_folder}/{filename}`

## Environment Variables

### Required for Production

```bash
# Email Service (Choose ONE)
RESEND_API_KEY=re_...           # Recommended: Resend API key
SENDGRID_API_KEY=SG.....        # Alternative: SendGrid API key

# OR use SMTP
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your@email.com
SMTP_PASSWORD=your-password

# Email Configuration
FROM_EMAIL=noreply@memoryhub.app
FROM_NAME=Memory Hub

# Voice Transcription (Optional)
OPENAI_API_KEY=sk-...           # For voice note transcription

# Application
REPLIT_DEV_DOMAIN=your-repl.repl.co  # Auto-set by Replit
```

## Setup Instructions

### 1. Email Service Setup

**Option A: Resend (Recommended)**
1. Sign up at https://resend.com
2. Create an API key
3. Add to Replit Secrets: `RESEND_API_KEY`
4. Verify domain (for production)

**Option B: SendGrid**
1. Sign up at https://sendgrid.com
2. Create an API key
3. Add to Replit Secrets: `SENDGRID_API_KEY`
4. Verify sender identity

**Option C: SMTP**
1. Get SMTP credentials from your email provider
2. Add all SMTP variables to Replit Secrets
3. Enable "Less secure app access" if using Gmail

### 2. Voice Transcription Setup (Optional)

1. Sign up at https://platform.openai.com
2. Create an API key
3. Add to Replit Secrets: `OPENAI_API_KEY`
4. Transcription will work automatically for all voice notes

### 3. File Storage

File storage is automatic! The system creates these directories:
```
uploads/
├── audio/          # Voice notes and audio files
├── images/         # Photos and images
├── videos/         # Video files
├── documents/      # PDFs and documents
└── other/          # Other file types
```

## Testing the Features

### Test Email Sending
```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "securepass123",
    "full_name": "Test User"
  }'
```

If email is configured, you'll receive a verification email!

### Test Password Reset
```bash
# Request password reset
curl -X POST http://localhost:8000/api/v1/password-reset/request \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### Test Voice Notes
```bash
# Upload a voice note with audio file
curl -X POST http://localhost:8000/api/v1/voice-notes \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "title=My First Voice Note" \
  -F "description=Testing real audio storage" \
  -F "audio_file=@recording.mp3"
```

### Test Transcription
```bash
# Transcribe a voice note
curl -X POST http://localhost:8000/api/v1/voice-notes/{note_id}/transcribe \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Migration from Mock Data

### What Changed

| Feature | Before | After |
|---------|--------|-------|
| Password Reset | Commented out email | ✅ Real email sending |
| Email Verification | Not implemented | ✅ Full verification flow |
| Voice Notes | Mock URLs | ✅ Real file storage |
| Transcription | "Coming soon" | ✅ OpenAI Whisper API |
| File Uploads | Placeholder | ✅ Organized storage |
| Media Serving | Not working | ✅ Secure file serving |

### Backwards Compatibility

All changes are **backwards compatible**:
- Endpoints remain the same
- API responses have same structure
- Additional fields are optional
- Graceful fallbacks when services unavailable

## Performance Considerations

### File Storage
- Files organized by user and category for fast access
- Unique filenames prevent cache conflicts
- Supports thousands of files per user

### Email Sending
- Async email sending doesn't block requests
- Automatic retry on failure (provider-specific)
- Falls back gracefully if email unavailable

### Transcription
- Cached after first transcription
- Only processes new voice notes
- Graceful message when API key not configured

## Security Features

✅ **Secure token generation** (32-byte URL-safe)
✅ **Token expiration** (1h for reset, 24h for verification)
✅ **Path traversal protection** for file serving
✅ **File type validation** for uploads
✅ **One-time use tokens** for password reset
✅ **Email rate limiting** (TODO: Add rate limits)

## Monitoring & Logs

### Check Email Status
```python
from app.services import get_email_service

email_service = get_email_service()
if email_service.is_configured():
    print("✅ Email service is ready!")
else:
    print("⚠️ Email service not configured")
```

### Check File Storage
```python
from app.services import get_storage_service

storage = get_storage_service()
# Storage is always ready, uses local filesystem
```

## Troubleshooting

### Emails Not Sending

1. **Check environment variables**
   ```bash
   echo $RESEND_API_KEY  # or SENDGRID_API_KEY
   ```

2. **Check logs**
   - Email service logs "Email service not configured" if no API key
   - Provider errors appear in backend logs

3. **Verify API key**
   - Test with provider's web console
   - Check key has send permissions

### Voice Transcription Not Working

1. **Check OpenAI API key**
   ```bash
   echo $OPENAI_API_KEY
   ```

2. **Check file exists**
   - Transcription needs actual file in `uploads/audio/`
   - Check file_path in voice note document

3. **Check API limits**
   - OpenAI may have rate limits
   - Check OpenAI dashboard for quota

### Files Not Uploading

1. **Check disk space**
   ```bash
   df -h
   ```

2. **Check directory permissions**
   ```bash
   ls -la uploads/
   ```

3. **Check file size limits**
   - FastAPI default: 16MB
   - Increase in `app/core/config.py` if needed

## Next Steps

### Recommended Improvements

1. **Add Rate Limiting**
   - Prevent email spam
   - Limit API calls per user

2. **Add Email Templates Editor**
   - Allow customizing email designs
   - Support multiple languages

3. **Add Cloud Storage**
   - S3/R2 integration for scalability
   - CDN for faster media delivery

4. **Add Background Jobs**
   - Queue emails for async sending
   - Process large file uploads

5. **Add Analytics**
   - Track email open rates
   - Monitor storage usage
   - Measure transcription accuracy

## Support

For issues or questions:
- Check backend logs: `tail -f logs/backend.log`
- Check MongoDB logs: `tail -f logs/mongodb.log`
- Review this documentation
- Test with curl commands above

---

**Last Updated:** October 19, 2025
**Version:** 1.0.0
