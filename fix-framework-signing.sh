#!/bin/bash

# QA-Online iOS Framework Signing Fix Script
# This script fixes the Capacitor framework signing issue for App Store submission

set -e

echo "🔐 QA-Online iOS Framework Signing Fix Script"
echo "=============================================="
echo ""

# Check if we're on macOS (required for codesign)
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS to properly sign frameworks"
    echo "📱 Current OS: $OSTYPE"
    echo ""
    echo "🔧 Alternative solutions:"
    echo "1. Run this script on a macOS machine with Xcode installed"
    echo "2. Use GitHub Actions or CircleCI with macOS runners"
    echo "3. Use a macOS virtual machine"
    echo ""
    echo "📦 For now, creating an unsigned IPA that you can sign manually..."
    
    # Create properly structured unsigned IPA
    if [ -d "Payload" ]; then
        echo "📦 Creating unsigned IPA from existing Payload..."
        zip -r App-unsigned-fixed.ipa Payload/
        echo "✅ Created App-unsigned-fixed.ipa"
        echo "📱 Transfer this to a macOS machine and run the fix-framework-signing.sh script there"
    fi
    
    exit 1
fi

# Check if IPA or Payload exists
if [ ! -f "App.ipa" ] && [ ! -d "Payload" ]; then
    echo "❌ Neither App.ipa nor Payload directory found"
    echo "📥 Please ensure you have either:"
    echo "   - App.ipa file in the current directory"
    echo "   - Payload/ directory with the extracted app"
    exit 1
fi

# Extract IPA if needed
if [ ! -d "Payload" ] && [ -f "App.ipa" ]; then
    echo "📦 Extracting IPA..."
    rm -rf Payload
    unzip -q App.ipa
    echo "✅ IPA extracted to Payload/"
fi

# Verify app structure
if [ ! -d "Payload/App.app" ]; then
    echo "❌ App.app not found in Payload directory"
    echo "📁 Current Payload contents:"
    ls -la Payload/ || echo "Payload directory is empty"
    exit 1
fi

echo "📱 Found app bundle: Payload/App.app"

# Check for frameworks directory
if [ ! -d "Payload/App.app/Frameworks" ]; then
    echo "⚠️  No Frameworks directory found - this might be okay"
    echo "📦 Creating signed IPA without framework signing..."
else
    echo "📁 Found Frameworks directory with:"
    ls -la Payload/App.app/Frameworks/
    echo ""
fi

# Check for required signing files
echo "🔍 Checking for signing requirements..."

# Look for distribution certificate
CERT_NAME=""
if security find-identity -v -p codesigning | grep -q "iPhone Distribution"; then
    CERT_NAME="iPhone Distribution"
    echo "✅ Found iPhone Distribution certificate"
elif security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
    CERT_NAME="Apple Distribution"
    echo "✅ Found Apple Distribution certificate"
else
    echo "❌ No distribution certificate found in keychain"
    echo "🔐 Please install your distribution certificate first:"
    echo "   1. Double-click your .p12 file to install it in Keychain"
    echo "   2. Or run: security import your-cert.p12 -k ~/Library/Keychains/login.keychain-db"
    echo ""
    echo "📋 Available signing identities:"
    security find-identity -v -p codesigning
    exit 1
fi

# Check for provisioning profile
PROFILE_PATH=""
if [ -f "QAOnlineAppStoreProfile.mobileprovision" ]; then
    PROFILE_PATH="QAOnlineAppStoreProfile.mobileprovision"
    echo "✅ Found provisioning profile: $PROFILE_PATH"
elif [ -f "embedded.mobileprovision" ]; then
    PROFILE_PATH="embedded.mobileprovision"
    echo "✅ Found provisioning profile: $PROFILE_PATH"
else
    # Look in standard locations
    PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
    if [ -d "$PROFILES_DIR" ]; then
        FOUND_PROFILE=$(find "$PROFILES_DIR" -name "*.mobileprovision" -print -quit 2>/dev/null || echo "")
        if [ -n "$FOUND_PROFILE" ]; then
            PROFILE_PATH="$FOUND_PROFILE"
            echo "✅ Found provisioning profile: $PROFILE_PATH"
        fi
    fi
fi

if [ -z "$PROFILE_PATH" ]; then
    echo "❌ No provisioning profile found"
    echo "📄 Please ensure QAOnlineAppStoreProfile.mobileprovision is in the current directory"
    echo "   Or install it in ~/Library/MobileDevice/Provisioning Profiles/"
    exit 1
fi

# Install provisioning profile in the app bundle
echo "📄 Installing provisioning profile in app bundle..."
cp "$PROFILE_PATH" Payload/App.app/embedded.mobileprovision
echo "✅ Provisioning profile installed"

# Sign all frameworks first (if they exist)
if [ -d "Payload/App.app/Frameworks" ]; then
    echo "🔐 Signing frameworks..."
    for framework in Payload/App.app/Frameworks/*.framework; do
        if [ -d "$framework" ]; then
            echo "  🔐 Signing $(basename "$framework")..."
            codesign --force --sign "$CERT_NAME" --verbose "$framework"
            echo "  ✅ $(basename "$framework") signed successfully"
        fi
    done
    echo "✅ All frameworks signed"
else
    echo "ℹ️  No frameworks to sign"
fi

# Sign the main app bundle
echo "🔐 Signing main app bundle..."
codesign --force --sign "$CERT_NAME" --verbose Payload/App.app
echo "✅ Main app bundle signed"

# Verify the signing
echo "🔍 Verifying app signature..."
codesign --verify --verbose=4 Payload/App.app
if [ $? -eq 0 ]; then
    echo "✅ App signature verified successfully"
else
    echo "❌ App signature verification failed"
    exit 1
fi

# Verify framework signatures (if they exist)
if [ -d "Payload/App.app/Frameworks" ]; then
    echo "🔍 Verifying framework signatures..."
    for framework in Payload/App.app/Frameworks/*.framework; do
        if [ -d "$framework" ]; then
            echo "  🔍 Verifying $(basename "$framework")..."
            if codesign --verify --verbose=4 "$framework" 2>/dev/null; then
                echo "  ✅ $(basename "$framework") signature verified"
            else
                echo "  ❌ $(basename "$framework") signature verification failed"
                exit 1
            fi
        fi
    done
    echo "✅ All framework signatures verified"
fi

# Create signed IPA
echo "📱 Creating signed IPA..."
rm -f App-signed.ipa
zip -r App-signed.ipa Payload/
echo "✅ Signed IPA created: App-signed.ipa"

# Show file info
echo ""
echo "📊 IPA Information:"
ls -la App-signed.ipa
echo "📱 File size: $(ls -la App-signed.ipa | awk '{print $5}') bytes"

# Final verification of the IPA
echo ""
echo "🔍 Final IPA verification..."
if unzip -t App-signed.ipa >/dev/null 2>&1; then
    echo "✅ IPA file integrity verified"
else
    echo "❌ IPA file integrity check failed"
    exit 1
fi

echo ""
echo "🎉 SUCCESS! Your IPA has been properly signed!"
echo "============================================="
echo "📱 Signed IPA: App-signed.ipa"
echo "🚀 This IPA is now ready for App Store Connect upload"
echo ""
echo "📤 Next steps:"
echo "1. Upload App-signed.ipa to App Store Connect"
echo "2. The frameworks should now pass Apple's validation"
echo "3. Your app will be processed for TestFlight distribution"
echo ""
echo "🔗 Upload using:"
echo "   - Xcode Organizer"
echo "   - Application Loader"
echo "   - xcrun altool --upload-app -f App-signed.ipa -t ios -u your@email.com"

# Clean up temporary files
echo ""
echo "🧹 Cleaning up..."
rm -rf Payload
echo "✅ Temporary files cleaned up"
echo ""
echo "🎯 Framework signing fix completed successfully!"
