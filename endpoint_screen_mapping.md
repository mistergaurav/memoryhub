# Backend Endpoints vs Flutter Screens Mapping

## Existing Flutter Screens:
1. **Auth Screens:**
   - login_screen.dart ✓
   - signup_screen.dart ✓

2. **Profile Screens:**
   - profile_screen.dart ✓
   - edit_profile_screen.dart ✓
   - change_password_screen.dart ✓
   - settings_screen.dart ✓

3. **Memory Screens:**
   - memories_list_screen.dart ✓
   - memory_detail_screen.dart ✓
   - memory_create_screen.dart ✓

4. **Vault Screens:**
   - vault_list_screen.dart ✓
   - vault_detail_screen.dart ✓
   - vault_upload_screen.dart ✓

5. **Hub Screens:**
   - hub_screen.dart ✓

6. **Social Screens:**
   - hubs_screen.dart ✓
   - user_search_screen.dart ✓
   - user_profile_view_screen.dart ✓

7. **Collections:**
   - collections_screen.dart ✓

8. **Activity:**
   - activity_feed_screen.dart ✓

9. **Notifications:**
   - notifications_screen.dart ✓

10. **Analytics:**
    - analytics_screen.dart ✓

11. **Admin:**
    - admin_dashboard_screen.dart ✓
    - admin_users_screen.dart ✓

## Missing Screens (Based on Backend Endpoints):

### 1. Comments Module
- ❌ comments_screen.dart - List/view all comments
- ❌ comment_detail_screen.dart - View single comment with replies

### 2. Search Module
- ❌ search_screen.dart - Global search interface
- ❌ advanced_search_screen.dart - Advanced search with filters

### 3. Tags Management
- ❌ tags_screen.dart - Browse all tags
- ❌ tag_detail_screen.dart - View content by tag
- ❌ tags_management_screen.dart - Rename/delete tags

### 4. File Sharing
- ❌ file_sharing_screen.dart - Create shareable links
- ❌ shared_files_screen.dart - View shared files

### 5. Reminders
- ❌ reminders_screen.dart - View/manage reminders
- ❌ create_reminder_screen.dart - Create new reminder

### 6. Export/Backup
- ❌ export_screen.dart - Export memories/files

### 7. Stories (24-hour content)
- ❌ stories_screen.dart - View stories feed
- ❌ create_story_screen.dart - Create new story
- ❌ story_viewer_screen.dart - View single story

### 8. Voice Notes
- ❌ voice_notes_screen.dart - List voice notes
- ❌ create_voice_note_screen.dart - Record voice note

### 9. Categories
- ❌ categories_screen.dart - Manage categories
- ❌ category_detail_screen.dart - View memories by category

### 10. Reactions/Emoji
- ❌ No dedicated screen needed (can be inline widgets)

### 11. Memory Templates
- ❌ templates_screen.dart - Browse templates
- ❌ template_editor_screen.dart - Create/edit templates

### 12. Two-Factor Authentication
- ❌ two_factor_setup_screen.dart - Set up 2FA
- ❌ two_factor_verify_screen.dart - Verify 2FA code

### 13. Password Reset
- ❌ password_reset_request_screen.dart - Request reset
- ❌ password_reset_confirm_screen.dart - Confirm reset with token

### 14. Privacy Settings
- ❌ privacy_settings_screen.dart - Manage privacy
- ❌ blocked_users_screen.dart - Manage blocked users

### 15. Places/Geolocation
- ❌ places_screen.dart - Browse places
- ❌ nearby_places_screen.dart - Find nearby places
- ❌ place_detail_screen.dart - View place details

### 16. Scheduled Posts
- ❌ scheduled_posts_screen.dart - View scheduled posts
- ❌ create_scheduled_post_screen.dart - Schedule a post

## Summary:
- **Existing Screens:** 22
- **Missing Screens:** ~30+
- **Total Screens Needed:** ~52+
