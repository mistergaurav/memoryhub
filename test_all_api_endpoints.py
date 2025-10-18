#!/usr/bin/env python3
"""
Comprehensive API Endpoint Testing Script
Tests all backend endpoints and reports any errors
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000/api/v1"

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

test_results = {
    'passed': 0,
    'failed': 0,
    'errors': []
}

def log_result(endpoint, method, status, expected, message=""):
    """Log test result with colors"""
    if status in expected:
        print(f"{GREEN}✓{RESET} {method:6} {endpoint:50} → {status}")
        test_results['passed'] += 1
    else:
        print(f"{RED}✗{RESET} {method:6} {endpoint:50} → {status} {message}")
        test_results['failed'] += 1
        test_results['errors'].append({
            'endpoint': endpoint,
            'method': method,
            'status': status,
            'message': message
        })

def test_endpoint(method, endpoint, expected_status=[200], data=None, headers=None, description=""):
    """Test a single endpoint"""
    url = f"{BASE_URL}{endpoint}"
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, timeout=5)
        elif method == "POST":
            response = requests.post(url, json=data, headers=headers, timeout=5)
        elif method == "PUT":
            response = requests.put(url, json=data, headers=headers, timeout=5)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers, timeout=5)
        else:
            response = None
        
        log_result(endpoint, method, response.status_code, expected_status, description)
        return response
    except Exception as e:
        log_result(endpoint, method, "ERROR", expected_status, str(e))
        return None

print(f"\n{BLUE}{'='*80}{RESET}")
print(f"{BLUE}Memory Hub API Endpoint Testing{RESET}")
print(f"{BLUE}Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{RESET}")
print(f"{BLUE}{'='*80}{RESET}\n")

# 1. AUTH ENDPOINTS
print(f"\n{YELLOW}=== AUTH ENDPOINTS ==={RESET}")
test_endpoint("POST", "/auth/signup", [200, 400, 422], {
    "email": "test@example.com",
    "password": "Test123!@#",
    "full_name": "Test User"
})
test_endpoint("POST", "/auth/login", [200, 401, 422], {
    "email": "test@example.com",
    "password": "Test123!@#"
})
test_endpoint("POST", "/auth/refresh", [401, 422])
test_endpoint("POST", "/auth/logout", [200, 401])

# 2. USER ENDPOINTS
print(f"\n{YELLOW}=== USER ENDPOINTS ==={RESET}")
test_endpoint("GET", "/users/me", [401, 200])
test_endpoint("GET", "/users/", [401, 200])
test_endpoint("PUT", "/users/me", [401, 422], {"full_name": "Updated Name"})

# 3. MEMORY ENDPOINTS
print(f"\n{YELLOW}=== MEMORY ENDPOINTS ==={RESET}")
test_endpoint("GET", "/memories/", [401, 200])
test_endpoint("POST", "/memories/", [401, 422], {
    "title": "Test Memory",
    "content": "Test content",
    "memory_type": "text"
})
test_endpoint("GET", "/memories/stats", [401, 200])

# 4. VAULT ENDPOINTS
print(f"\n{YELLOW}=== VAULT ENDPOINTS ==={RESET}")
test_endpoint("GET", "/vault/", [401, 200])
test_endpoint("GET", "/vault/stats", [401, 200])

# 5. HUB ENDPOINTS
print(f"\n{YELLOW}=== HUB ENDPOINTS ==={RESET}")
test_endpoint("GET", "/hub/", [401, 200])
test_endpoint("POST", "/hub/", [401, 422], {
    "name": "Test Hub",
    "description": "Test Description"
})

# 6. SOCIAL ENDPOINTS
print(f"\n{YELLOW}=== SOCIAL ENDPOINTS ==={RESET}")
test_endpoint("GET", "/social/search", [401, 200])
test_endpoint("GET", "/social/following", [401, 200])
test_endpoint("GET", "/social/followers", [401, 200])

# 7. COLLECTIONS ENDPOINTS
print(f"\n{YELLOW}=== COLLECTIONS ENDPOINTS ==={RESET}")
test_endpoint("GET", "/collections/", [401, 200])
test_endpoint("POST", "/collections/", [401, 422], {
    "name": "Test Collection",
    "description": "Test"
})

# 8. COMMENTS ENDPOINTS
print(f"\n{YELLOW}=== COMMENTS ENDPOINTS ==={RESET}")
test_endpoint("GET", "/comments/memory/test-id", [401, 404])

# 9. NOTIFICATIONS ENDPOINTS
print(f"\n{YELLOW}=== NOTIFICATIONS ENDPOINTS ==={RESET}")
test_endpoint("GET", "/notifications/", [401, 200])
test_endpoint("GET", "/notifications/unread-count", [401, 200])

# 10. ACTIVITY ENDPOINTS
print(f"\n{YELLOW}=== ACTIVITY ENDPOINTS ==={RESET}")
test_endpoint("GET", "/activity/feed", [401, 200])

# 11. SEARCH ENDPOINTS
print(f"\n{YELLOW}=== SEARCH ENDPOINTS ==={RESET}")
test_endpoint("GET", "/search/?q=test", [401, 200])

# 12. TAGS ENDPOINTS
print(f"\n{YELLOW}=== TAGS ENDPOINTS ==={RESET}")
test_endpoint("GET", "/tags/", [401, 200])
test_endpoint("GET", "/tags/popular", [401, 200])

# 13. ANALYTICS ENDPOINTS
print(f"\n{YELLOW}=== ANALYTICS ENDPOINTS ==={RESET}")
test_endpoint("GET", "/analytics/dashboard", [401, 200])

# 14. SHARING ENDPOINTS (RECENTLY ADDED - GDPR COMPLIANT)
print(f"\n{YELLOW}=== SHARING ENDPOINTS ==={RESET}")
test_endpoint("POST", "/sharing/memory/test-id", [401, 404, 422])
test_endpoint("POST", "/sharing/collection/test-id", [401, 404, 422])
test_endpoint("POST", "/sharing/file/test-id", [401, 404, 422])
test_endpoint("POST", "/sharing/hub/test-id", [401, 404, 422])
test_endpoint("GET", "/sharing/link/test-token", [404, 200])

# 15. REMINDERS ENDPOINTS
print(f"\n{YELLOW}=== REMINDERS ENDPOINTS ==={RESET}")
test_endpoint("GET", "/reminders/", [401, 200])

# 16. EXPORT ENDPOINTS (GDPR DATA PORTABILITY)
print(f"\n{YELLOW}=== EXPORT ENDPOINTS (GDPR) ==={RESET}")
test_endpoint("POST", "/export/json", [401, 200])
test_endpoint("POST", "/export/archive", [401, 200])
test_endpoint("GET", "/export/history", [401, 200])

# 17. GDPR ENDPOINTS (RECENTLY ADDED)
print(f"\n{YELLOW}=== GDPR COMPLIANCE ENDPOINTS ==={RESET}")
test_endpoint("GET", "/gdpr/consent", [401, 200])
test_endpoint("PUT", "/gdpr/consent", [401, 422], {
    "analytics": True,
    "marketing": False
})
test_endpoint("POST", "/gdpr/delete-account", [401, 422])
test_endpoint("POST", "/gdpr/cancel-deletion", [401, 404])
test_endpoint("GET", "/gdpr/data-info", [401, 200])

# 18. ADMIN ENDPOINTS
print(f"\n{YELLOW}=== ADMIN ENDPOINTS ==={RESET}")
test_endpoint("GET", "/admin/stats", [401, 403])
test_endpoint("GET", "/admin/users", [401, 403])

# 19. STORIES ENDPOINTS
print(f"\n{YELLOW}=== STORIES ENDPOINTS ==={RESET}")
test_endpoint("GET", "/stories/", [401, 200])
test_endpoint("POST", "/stories/", [401, 422])

# 20. VOICE NOTES ENDPOINTS
print(f"\n{YELLOW}=== VOICE NOTES ENDPOINTS ==={RESET}")
test_endpoint("GET", "/voice-notes/", [401, 200])

# 21. CATEGORIES ENDPOINTS
print(f"\n{YELLOW}=== CATEGORIES ENDPOINTS ==={RESET}")
test_endpoint("GET", "/categories/", [401, 200])

# 22. REACTIONS ENDPOINTS
print(f"\n{YELLOW}=== REACTIONS ENDPOINTS ==={RESET}")
test_endpoint("POST", "/reactions/memory/test-id", [401, 404, 422])

# 23. MEMORY TEMPLATES ENDPOINTS
print(f"\n{YELLOW}=== MEMORY TEMPLATES ENDPOINTS ==={RESET}")
test_endpoint("GET", "/memory-templates/", [401, 200])

# 24. TWO FACTOR AUTH ENDPOINTS
print(f"\n{YELLOW}=== 2FA ENDPOINTS ==={RESET}")
test_endpoint("POST", "/2fa/setup", [401, 200])
test_endpoint("POST", "/2fa/verify", [401, 422])
test_endpoint("POST", "/2fa/disable", [401, 422])

# 25. PASSWORD RESET ENDPOINTS
print(f"\n{YELLOW}=== PASSWORD RESET ENDPOINTS ==={RESET}")
test_endpoint("POST", "/password-reset/request", [200, 422], {
    "email": "test@example.com"
})
test_endpoint("POST", "/password-reset/verify", [400, 422])
test_endpoint("POST", "/password-reset/reset", [400, 422])

# 26. PRIVACY ENDPOINTS
print(f"\n{YELLOW}=== PRIVACY ENDPOINTS ==={RESET}")
test_endpoint("GET", "/privacy/settings", [401, 200])
test_endpoint("PUT", "/privacy/settings", [401, 422])
test_endpoint("GET", "/privacy/blocked-users", [401, 200])

# 27. PLACES ENDPOINTS
print(f"\n{YELLOW}=== PLACES ENDPOINTS ==={RESET}")
test_endpoint("GET", "/places/", [401, 200])
test_endpoint("GET", "/places/nearby", [401, 422])

# 28. SCHEDULED POSTS ENDPOINTS
print(f"\n{YELLOW}=== SCHEDULED POSTS ENDPOINTS ==={RESET}")
test_endpoint("GET", "/scheduled-posts/", [401, 200])

# PRINT SUMMARY
print(f"\n{BLUE}{'='*80}{RESET}")
print(f"{BLUE}TEST SUMMARY{RESET}")
print(f"{BLUE}{'='*80}{RESET}")
print(f"{GREEN}Passed:{RESET} {test_results['passed']}")
print(f"{RED}Failed:{RESET} {test_results['failed']}")
print(f"Total: {test_results['passed'] + test_results['failed']}")

if test_results['errors']:
    print(f"\n{RED}ERRORS FOUND:{RESET}")
    for error in test_results['errors']:
        print(f"  - {error['method']} {error['endpoint']}: {error['status']} - {error['message']}")

print(f"\n{BLUE}Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{RESET}\n")
