#!/bin/bash

echo "🧪 Testing iOS Signing Setup"
echo "============================"

# Check environment variables
echo "🔍 Environment Variables:"
echo "  APPLE_TEAM_ID: ${APPLE_TEAM_ID:-'NOT SET'}"
echo "  APP_STORE_CONNECT_API_KEY_ID: ${APP_STORE_CONNECT_API_KEY_ID:-'NOT SET'}"
echo "  APP_STORE_CONNECT_ISSUER_ID: ${APP_STORE_CONNECT_ISSUER_ID:-'NOT SET'}"
echo "  APP_STORE_CONNECT_API_KEY: ${APP_STORE_CONNECT_API_KEY:+'SET'}"
echo ""

# Check if certificates directory exists
if [ -d "certificates" ]; then
    echo "📁 Certificates directory found:"
    ls -la certificates/
    echo ""
else
    echo "❌ Certificates directory not found"
    echo ""
fi

# Check if keychain has any signing identities
echo "🔐 Checking signing identities:"
security find-identity -v -p codesigning ~/Library/Keychains/login.keychain-db
echo ""

# Check if provisioning profiles are installed
echo "📋 Checking provisioning profiles:"
if [ -d ~/Library/MobileDevice/Provisioning\ Profiles ]; then
    ls -la ~/Library/MobileDevice/Provisioning\ Profiles/ | grep -E "(QA-Online|\.mobileprovision)" || echo "No QA-Online profiles found"
else
    echo "No provisioning profiles directory found"
fi
echo ""

# Test API key authentication
echo "🔑 Testing API key authentication:"
if command -v fastlane &> /dev/null; then
    fastlane test_api_key || echo "❌ API key test failed"
else
    echo "❌ Fastlane not available"
fi
echo ""

echo "✅ Signing setup test completed"
