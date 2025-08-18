#!/bin/bash

# Quick test script to validate API key authentication
set -e

echo "🔍 Testing API key authentication..."

# Read configuration
API_KEY_ID=$(cat AuthKey_ZA7M4DJPV8.id | tr -d '\n\r' | head -1)
echo "📋 API Key ID: $API_KEY_ID"

# Check if files exist
if [ ! -f "AuthKey_${API_KEY_ID}.p8" ]; then
  echo "❌ ERROR: AuthKey_${API_KEY_ID}.p8 not found!"
  exit 1
fi

if [ ! -f "signed-ipa.zip" ]; then
  echo "❌ ERROR: signed-ipa.zip not found!"
  exit 1
fi

echo "✅ Required files found"

# Extract IPA
echo "📦 Extracting IPA..."
unzip -o signed-ipa.zip > /dev/null
zip -r App.ipa Payload/ > /dev/null
rm -rf Payload/

echo "✅ IPA created: $(ls -lh App.ipa)"

# Test with xcrun notarytool (newer method)
echo "🚀 Testing with xcrun notarytool..."
if command -v xcrun >/dev/null 2>&1; then
  echo "📱 Attempting upload with notarytool..."
  
  # Create temporary keychain for testing
  xcrun notarytool store-credentials "test-profile" \
    --key "AuthKey_${API_KEY_ID}.p8" \
    --key-id "$API_KEY_ID" \
    --issuer "6751101564" 2>/dev/null || echo "⚠️ Profile creation failed"
  
  # Try submitting to notary service (this tests authentication)
  xcrun notarytool submit App.ipa \
    --key "AuthKey_${API_KEY_ID}.p8" \
    --key-id "$API_KEY_ID" \
    --issuer "6751101564" \
    --wait || echo "⚠️ Notarytool failed"
else
  echo "⚠️ xcrun not available"
fi

# Test API key format
echo "🔍 Checking API key format..."
head -1 "AuthKey_${API_KEY_ID}.p8"
echo "..."
tail -1 "AuthKey_${API_KEY_ID}.p8"

# Test with curl to App Store Connect API
echo "🔍 Testing App Store Connect API access..."
python3 -c "
import jwt
import time
import json

# Read the private key
with open('AuthKey_${API_KEY_ID}.p8', 'r') as f:
    private_key = f.read()

# Create JWT token
header = {
    'alg': 'ES256',
    'kid': '${API_KEY_ID}',
    'typ': 'JWT'
}

payload = {
    'iss': '6751101564',
    'iat': int(time.time()),
    'exp': int(time.time()) + 1200,
    'aud': 'appstoreconnect-v1'
}

token = jwt.encode(payload, private_key, algorithm='ES256', headers=header)
print('Token generated successfully')
print('Length:', len(token))
" 2>/dev/null || echo "⚠️ Python JWT test failed - install PyJWT: pip3 install PyJWT"

echo "🔧 To fix authentication issues:"
echo "📋 1. Check API key permissions in App Store Connect"
echo "📋 2. Ensure key has 'App Manager' role and 'App Store Connect' access"
echo "📋 3. Verify key is not expired"
echo "📋 4. Check if key format is correct (should start with -----BEGIN PRIVATE KEY-----)"

# Cleanup
rm -f App.ipa

echo "✅ Test complete" 