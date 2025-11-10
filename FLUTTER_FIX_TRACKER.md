# Flutter Compilation Errors Fix Tracker

**Total Errors to Fix:** 285 errors across ~50 files

**Strategy:** Feature-area phased approach with subagent delegation

---

## Phase 1: Profile Screens

### Profile-High (>12 errors)
- [ ] settings_screen.dart (14 errors)
- [ ] account_security_screen.dart (8 errors)
**Status:** Not Started
**Validation:** `flutter analyze lib/screens/profile`

### Profile-Medium (6-12 errors)
- [ ] settings_home_screen.dart (3 errors)
- [ ] support_legal_screen.dart (5 errors)
- [ ] edit_profile_screen.dart (est. 3 errors)
**Status:** Not Started

### Profile-Low (≤5 errors)
- [ ] profile_screen.dart (est. 2 errors)
- [ ] change_password_screen.dart (est. 2 errors)
**Status:** Not Started

---

## Phase 2: Auth Screens

### Auth-High
- [ ] login_screen.dart (est. 6 errors)
- [ ] signup_screen.dart (est. 6 errors)
**Status:** Not Started

### Auth-Low
- [ ] password_reset_request_screen.dart (est. 4 errors)
**Status:** Not Started

---

## Phase 3: Social Screens

### Social-High
- [ ] hub_detail_screen.dart (9 errors)
- [ ] user_profile_view_screen.dart (7 errors)
- [ ] hub_info_screen.dart (6 errors)
**Status:** Not Started

### Social-Medium
- [ ] hubs_screen.dart (4 errors)
- [ ] user_search_screen.dart (est. 3 errors)
**Status:** Not Started

---

## Phase 4: Family Screens (LARGEST - 15 files)

### Family-Critical (>20 errors)
- [ ] family_hub_dashboard_screen.dart (64 errors) ⚠️ CRITICAL
**Status:** Not Started

### Family-High (12-20 errors)
- [ ] timeline_event_detail_screen.dart (17 errors)
- [ ] family_circle_detail_screen.dart (14 errors)
- [ ] recipe_detail_screen.dart (12 errors)
- [ ] family_recipes_screen.dart (12 errors)
**Status:** Not Started

### Family-Medium (5-12 errors)
- [ ] family_albums_screen.dart (8 errors)
- [ ] event_detail_screen.dart (5 errors)
**Status:** Not Started

### Family-Low (≤5 errors)
- [ ] parental_controls_screen.dart (4 errors)
- [ ] family_calendar_screen.dart (4 errors)
- [ ] family_circles_screen.dart (est. 3 errors)
- [ ] milestone_detail_screen.dart (est. 2 errors)
**Status:** Not Started

---

## Phase 5: Remaining Screens

### Collections
- [ ] collection_detail_screen.dart (10 errors)
- [ ] collections_screen.dart (4 errors)
**Status:** Not Started

### Vault
- [ ] vault_detail_screen.dart (2 errors)
- [ ] vault_list_screen.dart (est. 2 errors)
- [ ] vault_upload_screen.dart (est. 2 errors)
**Status:** Not Started

### Other
- [ ] categories_screen.dart (4 errors)
- [ ] admin_users_screen.dart (4 errors)
- [ ] two_factor_setup_screen.dart (4 errors)
- [ ] share_management_screen.dart (4 errors)
- [ ] gdpr/account_deletion_screen.dart (4 errors)
- [ ] templates/template_editor_screen.dart (2 errors)
- [ ] search screens (4 errors total)
- [ ] scheduled_posts (2 errors)
- [ ] reminders (2 errors)
**Status:** Not Started

---

## Progress Metrics

- **Phase 1 (Profile):** 0/7 files fixed
- **Phase 2 (Auth):** 0/3 files fixed  
- **Phase 3 (Social):** 0/5 files fixed
- **Phase 4 (Family):** 0/15 files fixed
- **Phase 5 (Remaining):** 0/20+ files fixed

**Current Error Count:** 285
**Target Error Count:** 0

---

## Common Error Patterns to Fix

1. **Button label vs child:** PrimaryButton/SecondaryButton/DangerButton/TonalButton use `label:`, standard Flutter widgets use `child:`
2. **Missing icon parameter:** IconButton/IconButtonX need `icon:` not `child:` or `label:`
3. **Spacing helpers:** Use Spacing.edgeInsetsAll(), Spacing.edgeInsetsFromLTRB() for backward compat
4. **FloatingActionButton.extended:** Uses `label: const Text()` not just `label: 'string'`

---

## Reference Documents

- `WIDGET_API_REFERENCE.md` - Complete widget API documentation
- `memory_hub_app/lib/design_system/tokens/spacing_tokens.dart` - Spacing shims
- `memory_hub_app/lib/design_system/components/buttons/*` - Custom button definitions
