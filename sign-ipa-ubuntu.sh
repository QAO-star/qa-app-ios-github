#!/bin/bash

echo "🔐 iOS IPA Signing Script for Ubuntu"
echo "===================================="

# Check if we have the required files
if [ ! -f "ios/App/App.ipa" ]; then
    echo "❌ App.ipa not found in ios/App/"
    echo "📥 Please ensure the unsigned IPA is available"
    exit 1
fi

if [ ! -f "QAOnlineAppStoreProfile.mobileprovision" ]; then
    echo "❌ QAOnlineAppStoreProfile.mobileprovision not found"
    echo "📥 Please ensure the provisioning profile is in the project root"
    exit 1
fi

if [ ! -f "ios_distribution.p12" ]; then
    echo "❌ ios_distribution.p12 not found"
    echo "📥 Please ensure the P12 certificate is in the project root"
    exit 1
fi

echo "✅ All required files found!"

# Create a temporary directory for signing
echo "📁 Creating temporary directory..."
TEMP_DIR=$(mktemp -d)
echo "📁 Temp directory: $TEMP_DIR"

# Copy files to temp directory
cp ios/App/App.ipa "$TEMP_DIR/"
cp QAOnlineAppStoreProfile.mobileprovision "$TEMP_DIR/"
cp ios_distribution.p12 "$TEMP_DIR/"

cd "$TEMP_DIR"

echo "📦 Extracting IPA..."
unzip -q App.ipa -d Payload/

echo "📄 Installing provisioning profile..."
mkdir -p Payload/App.app/embedded.mobileprovision
cp QAOnlineAppStoreProfile.mobileprovision Payload/App.app/embedded.mobileprovision/

echo "🔐 Attempting to sign with available tools..."

# Try different signing approaches
if command -v codesign &> /dev/null; then
    echo "🔐 Using codesign..."
    if codesign --force --sign "iPhone Distribution" Payload/App.app 2>/dev/null; then
        echo "✅ Successfully signed with codesign"
        SIGNED=true
    else
        echo "⚠️ codesign failed, trying alternative..."
        SIGNED=false
    fi
else
    echo "⚠️ codesign not available"
    SIGNED=false
fi

# If codesign failed or not available, create unsigned IPA
if [ "$SIGNED" = false ]; then
    echo "🔧 Creating unsigned IPA for manual signing..."
    rm -f App.ipa
    zip -r App-unsigned.ipa Payload/
    
    echo "📦 Created unsigned IPA: App-unsigned.ipa"
    echo ""
    echo "📱 Manual signing instructions:"
    echo "1. Transfer App-unsigned.ipa to a macOS machine"
    echo "2. Install your certificates in Keychain Access"
    echo "3. Run: codesign --force --sign 'iPhone Distribution' App-unsigned.ipa"
    echo "4. Upload the signed IPA to App Store Connect"
    
    # Copy unsigned IPA back to project
    cp App-unsigned.ipa /home/jonatan_koren/qa-app-ios-github/
    echo "✅ Unsigned IPA copied to project root"
else
    # Create signed IPA
    echo "📦 Creating signed IPA..."
    rm -f App.ipa
    zip -r App-signed.ipa Payload/
    
    echo "✅ IPA signed successfully!"
    ls -la App-signed.ipa
    echo "📊 File size: $(ls -la App-signed.ipa | awk '{print $5}')"
    
    # Copy signed IPA back to project
    cp App-signed.ipa /home/jonatan_koren/qa-app-ios-github/
    echo "✅ Signed IPA copied to project root"
fi

# Clean up
cd /home/jonatan_koren/qa-app-ios-github
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 Process completed!"
echo "📱 Check your project root for the IPA file"
