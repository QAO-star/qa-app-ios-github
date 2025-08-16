#!/bin/bash

# QA-Online iOS App Local Signing Script
# This script helps you sign the unsigned IPA with your existing certificates

set -e

echo "🔐 QA-Online iOS App Local Signing Script"
echo "=========================================="
echo ""

# Check if IPA file exists
if [ ! -f "App.ipa" ]; then
    echo "❌ App.ipa not found in current directory"
    echo "📥 Please download the unsigned IPA from CircleCI artifacts first"
    exit 1
fi

echo "📱 Found App.ipa: $(ls -la App.ipa | awk '{print $5}')"
echo ""

# Check for required files
echo "🔍 Checking for required signing files..."

if [ ! -f "QAOnlineAppStoreProfile.mobileprovision" ]; then
    echo "❌ QAOnlineAppStoreProfile.mobileprovision not found"
    echo "📥 Please ensure the provisioning profile is in the current directory"
    exit 1
fi

if [ ! -f "ios_distribution.p12" ]; then
    echo "❌ ios_distribution.p12 not found"
    echo "📥 Please ensure the P12 certificate is in the current directory"
    exit 1
fi

echo "✅ All required files found"
echo ""

# Extract the IPA
echo "📦 Extracting IPA..."
rm -rf Payload
unzip -q App.ipa
echo "✅ IPA extracted"

# Install the certificate
echo "🔐 Installing distribution certificate..."
security import ios_distribution.p12 -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign
echo "✅ Certificate installed"

# Install the provisioning profile
echo "📄 Installing provisioning profile..."
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp QAOnlineAppStoreProfile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
echo "✅ Provisioning profile installed"

# Sign the app bundle
echo "🔐 Signing app bundle..."
codesign --force --sign "iPhone Distribution" --entitlements QAOnlineAppStoreProfile.mobileprovision Payload/App.app
echo "✅ App bundle signed"

# Create signed IPA
echo "📱 Creating signed IPA..."
rm -f App-signed.ipa
zip -r App-signed.ipa Payload/

# Clean up
rm -rf Payload

# Verify the signing
echo "🔍 Verifying app signature..."
codesign -dv --verbose=4 App-signed.ipa

echo ""
echo "🎉 Successfully created signed IPA!"
echo "📱 Signed IPA: App-signed.ipa"
echo "📊 File size: $(ls -la App-signed.ipa | awk '{print $5}')"
echo ""
echo "🚀 The signed IPA is ready for upload to App Store Connect!"
echo "📤 You can now upload App-signed.ipa to TestFlight or App Store Connect"
