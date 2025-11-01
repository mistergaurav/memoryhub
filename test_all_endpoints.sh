#!/bin/bash

# Memory Hub API Endpoint Testing Script
BASE_URL="http://localhost:5000/api/v1"
TOKEN=""

echo "=== Memory Hub API Testing ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test result counter
PASSED=0
FAILED=0

test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    local auth_header=""
    
    if [ -n "$TOKEN" ]; then
        auth_header="-H \"Authorization: Bearer $TOKEN\""
    fi
    
    echo -n "Testing: $description... "
    
    if [ "$method" == "GET" ]; then
        response=$(eval curl -s -o /dev/null -w "%{http_code}" $auth_header "$BASE_URL$endpoint")
    elif [ "$method" == "POST" ]; then
        response=$(eval curl -s -o /dev/null -w "%{http_code}" -X POST $auth_header -H "Content-Type: application/json" -d "'$data'" "$BASE_URL$endpoint")
    elif [ "$method" == "PUT" ]; then
        response=$(eval curl -s -o /dev/null -w "%{http_code}" -X PUT $auth_header -H "Content-Type: application/json" -d "'$data'" "$BASE_URL$endpoint")
    elif [ "$method" == "DELETE" ]; then
        response=$(eval curl -s -o /dev/null -w "%{http_code}" -X DELETE $auth_header "$BASE_URL$endpoint")
    fi
    
    if [ "$response" -ge 200 ] && [ "$response" -lt 400 ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $response)"
        ((FAILED++))
    fi
}

# 1. Authentication Tests
echo "=== 1. Authentication Endpoints ==="
echo "Registering test user..."
REG_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"apitest@example.com","password":"testpass123","full_name":"API Test User"}')
echo "Registration response: $REG_RESPONSE"

echo "Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"email":"apitest@example.com","password":"testpass123"}')
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
echo "Login successful, token obtained"
echo ""

# 2. User Endpoints
echo "=== 2. User Endpoints ==="
test_endpoint "GET" "/users/me" "" "Get current user profile"
test_endpoint "PUT" "/users/me" '{"full_name":"Updated Test User","bio":"Testing API"}' "Update user profile"
echo ""

# 3. Memory Endpoints
echo "=== 3. Memory Endpoints ==="
test_endpoint "GET" "/memories/search/" "" "Search memories"
echo ""

# 4. Vault Endpoints
echo "=== 4. Vault/File Endpoints ==="
test_endpoint "GET" "/vault/" "" "List vault files"
test_endpoint "GET" "/vault/stats" "" "Get vault statistics"
echo ""

# 5. Hub Endpoints
echo "=== 5. Hub Endpoints ==="
test_endpoint "GET" "/hub/dashboard" "" "Get hub dashboard"
test_endpoint "GET" "/hub/items" "" "List hub items"
test_endpoint "GET" "/hub/stats" "" "Get hub statistics"
test_endpoint "GET" "/hub/activity" "" "Get hub activity"
echo ""

# 6. Social Endpoints
echo "=== 6. Social Endpoints ==="
test_endpoint "GET" "/social/hubs" "" "List social hubs"
test_endpoint "GET" "/social/users/search?q=test" "" "Search users"
echo ""

# 7. Comments Endpoints
echo "=== 7. Comments Endpoints ==="
test_endpoint "GET" "/comments/" "" "List comments"
echo ""

# 8. Notifications Endpoints
echo "=== 8. Notifications Endpoints ==="
test_endpoint "GET" "/notifications/" "" "List notifications"
echo ""

# 9. Collections Endpoints
echo "=== 9. Collections Endpoints ==="
test_endpoint "GET" "/collections/" "" "List collections"
test_endpoint "POST" "/collections/" '{"name":"Test Collection","privacy":"private"}' "Create collection"
echo ""

# 10. Activity Feed
echo "=== 10. Activity Feed Endpoints ==="
test_endpoint "GET" "/activity/feed" "" "Get activity feed"
echo ""

# 11. Search Endpoints
echo "=== 11. Search Endpoints ==="
test_endpoint "GET" "/search/?q=test" "" "Global search"
test_endpoint "GET" "/search/suggestions?q=test" "" "Search suggestions"
echo ""

# 12. Tags Endpoints
echo "=== 12. Tags Endpoints ==="
test_endpoint "GET" "/tags/" "" "List tags"
test_endpoint "GET" "/tags/popular" "" "Get popular tags"
echo ""

# 13. Analytics Endpoints
echo "=== 13. Analytics Endpoints ==="
test_endpoint "GET" "/analytics/overview" "" "Analytics overview"
test_endpoint "GET" "/analytics/activity-chart?days=7" "" "Activity chart"
test_endpoint "GET" "/analytics/top-tags?limit=10" "" "Top tags"
test_endpoint "GET" "/analytics/storage-breakdown" "" "Storage breakdown"
echo ""

# 14. Sharing Endpoints
echo "=== 14. File Sharing Endpoints ==="
test_endpoint "GET" "/sharing/files/test123" "" "Get shared file (expect 404)"
echo ""

# 15. Reminders Endpoints
echo "=== 15. Reminders Endpoints ==="
test_endpoint "GET" "/reminders/" "" "List reminders"
echo ""

# 16. Stories Endpoints
echo "=== 16. Stories Endpoints ==="
test_endpoint "GET" "/stories/" "" "List stories"
echo ""

# 17. Voice Notes Endpoints
echo "=== 17. Voice Notes Endpoints ==="
test_endpoint "GET" "/voice-notes/" "" "List voice notes"
echo ""

# 18. Categories Endpoints
echo "=== 18. Categories Endpoints ==="
test_endpoint "GET" "/categories/" "" "List categories"
echo ""

# 19. Reactions Endpoints
echo "=== 19. Reactions Endpoints ==="
test_endpoint "GET" "/reactions/user/stats" "" "Get user reaction stats"
echo ""

# 20. Memory Templates Endpoints
echo "=== 20. Memory Templates Endpoints ==="
test_endpoint "GET" "/memory-templates/" "" "List memory templates"
test_endpoint "GET" "/memory-templates/categories/list" "" "List template categories"
echo ""

# 21. Two-Factor Auth Endpoints
echo "=== 21. Two-Factor Authentication Endpoints ==="
test_endpoint "GET" "/2fa/status" "" "Get 2FA status"
echo ""

# 22. Password Reset Endpoints
echo "=== 22. Password Reset Endpoints ==="
test_endpoint "POST" "/password-reset/request" '{"email":"apitest@example.com"}' "Request password reset"
echo ""

# 23. Privacy Endpoints
echo "=== 23. Privacy Settings Endpoints ==="
test_endpoint "GET" "/privacy/settings" "" "Get privacy settings"
test_endpoint "GET" "/privacy/blocked" "" "List blocked users"
echo ""

# 24. Places Endpoints
echo "=== 24. Places/Geolocation Endpoints ==="
test_endpoint "GET" "/places/" "" "List places"
test_endpoint "GET" "/places/nearby?lat=37.7749&lng=-122.4194&radius=5000" "" "Get nearby places"
echo ""

# 25. Scheduled Posts Endpoints
echo "=== 25. Scheduled Posts Endpoints ==="
test_endpoint "GET" "/scheduled-posts/" "" "List scheduled posts"
echo ""

# Summary
echo ""
echo "==========================="
echo "=== Test Results Summary ==="
echo "==========================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Check the output above for details.${NC}"
    exit 1
fi
