#!/bin/bash

echo "🔍 CERTIFICATE SETUP VERIFICATION"
echo "=================================="
echo ""

# Check if files exist
echo "📁 Checking for certificate files..."
if [ -f "ios_distribution.p12" ]; then
    echo "✅ ios_distribution.p12 exists"
    echo "   Size: $(ls -lh ios_distribution.p12 | awk '{print $5}')"
    echo "   Type: $(file ios_distribution.p12)"
else
    echo "❌ ios_distribution.p12 not found"
    echo "   Please create it first:"
    echo "   openssl pkcs12 -export -out ios_distribution.p12 -inkey ios_distribution.key -in ios_distribution.cer -nodes"
    exit 1
fi

if [ -f "ios_distribution.key" ]; then
    echo "✅ ios_distribution.key exists"
else
    echo "❌ ios_distribution.key not found"
fi

if [ -f "ios_distribution.cer" ]; then
    echo "✅ ios_distribution.cer exists"
else
    echo "❌ ios_distribution.cer not found"
fi

echo ""

# Test base64 encoding/decoding
echo "🔐 Testing base64 encoding/decoding..."
echo "Creating test base64 file..."
base64 -w 0 ios_distribution.p12 > test_base64.txt

echo "Decoding test file..."
base64 -d test_base64.txt > test_decoded.p12

echo "Comparing original and decoded files..."
if diff ios_distribution.p12 test_decoded.p12 > /dev/null; then
    echo "✅ Base64 encoding/decoding works correctly"
else
    echo "❌ Base64 encoding/decoding failed - files are different"
    echo "   This indicates an issue with the encoding process"
fi

echo ""

# Show base64 content
echo "📋 Base64 content (first 100 characters):"
head -c 100 test_base64.txt
echo "..."
echo ""

echo "📋 Base64 content length:"
wc -c < test_base64.txt
echo ""

# Clean up test files
rm -f test_base64.txt test_decoded.p12

echo "🎯 NEXT STEPS:"
echo "=============="
echo ""
echo "1. Copy the ENTIRE content of test_base64.txt to GitHub secret 'IOS_DIST_CERTIFICATE'"
echo "2. Make sure to copy ALL characters (no line breaks)"
echo "3. Verify the secret was saved correctly"
echo "4. Create a new tag to test:"
echo "   git tag release-v1.0.9"
echo "   git push origin release-v1.0.9"
echo ""

echo "✅ Verification complete!"
