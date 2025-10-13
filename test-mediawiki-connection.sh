#!/bin/bash

# MediaWiki Connection Test Script
# This script tests if you can connect to your MediaWiki API

echo "MediaWiki Connection Test"
echo "=========================="
echo ""

# Prompt for credentials (they won't be saved anywhere)
read -p "Enter your MediaWiki API URL (e.g., https://wiki.example.com/api.php): " WIKI_API
read -p "Enter your MediaWiki username: " WIKI_USER
read -sp "Enter your MediaWiki password: " WIKI_PASS
echo ""
echo ""

# Test 1: Check if API is accessible
echo "Test 1: Checking if MediaWiki API is accessible..."
if curl -fsSL "$WIKI_API?action=query&meta=siteinfo&format=json" > /dev/null 2>&1; then
    echo "✓ API is accessible"
else
    echo "✗ API is NOT accessible - check your WIKI_API URL"
    exit 1
fi

# Test 2: Try to login
echo ""
echo "Test 2: Testing authentication..."
LOGIN_RESPONSE=$(curl -s -X POST "$WIKI_API" \
    -d "action=login" \
    -d "lgname=$WIKI_USER" \
    -d "lgpassword=$WIKI_PASS" \
    -d "format=json")

echo "Login response: $LOGIN_RESPONSE"

if echo "$LOGIN_RESPONSE" | grep -q '"result":"Success"'; then
    echo "✓ Authentication successful!"
elif echo "$LOGIN_RESPONSE" | grep -q '"result":"NeedToken"'; then
    echo "⚠ Bot password might be required (this is normal for bot accounts)"
    echo "  Make sure you're using a bot password, not your regular password"
elif echo "$LOGIN_RESPONSE" | grep -q '"result":"Failed"'; then
    echo "✗ Authentication failed - check username/password"
    exit 1
else
    echo "⚠ Unexpected response - see above for details"
fi

echo ""
echo "Test 3: Checking git-remote-mediawiki compatibility..."
# Test if we can construct the mediawiki URL properly
SCHEME="${WIKI_API%%://*}"
REST="${WIKI_API#*://}"
REST="${REST%%\?*}"
REST="${REST%%#*}"
REST="${REST%/api.php}"
REST="${REST%/index.php}"
REST="${REST%/}"

echo "Base URL would be: ${SCHEME}://${REST}"
echo "Git remote URL would be: mediawiki::${SCHEME}://${WIKI_USER}:***@${REST}"

echo ""
echo "=========================="
echo "If all tests passed, your credentials work!"
echo "The issue might be with the git-remote-mediawiki script installation."

