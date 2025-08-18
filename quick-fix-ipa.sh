#!/bin/bash

# Quick Fix for IPA Framework Signing Issue
# Run this script to fix your current IPA for App Store submission

set -e

echo "🚀 Quick IPA Framework Signing Fix"
echo "=================================="

# Check if we have an IPA to fix
IPA_FILE=""

if [ -f "App-signed.ipa" ]; then
    IPA_FILE="App-signed.ipa"
elif [ -f "App.ipa" ]; then
    IPA_FILE="App.ipa"
elif [ -f "ios/App/App.ipa" ]; then
    IPA_FILE="ios/App/App.ipa"
else
    echo "❌ No IPA file found!"
    echo "💡 Looking for: App-signed.ipa, App.ipa, or ios/App/App.ipa"
    exit 1
fi

echo "📦 Found IPA: $IPA_FILE"

# Check if we have the signing certificate
echo "🔍 Checking for signing certificates..."
SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep -E "Apple Distribution.*BL7NANM4RM|iPhone Distribution.*BL7NANM4RM" | head -1 | sed 's/.*"\(.*\)".*/\1/' || echo "")

if [ -z "$SIGNING_IDENTITY" ]; then
    echo "❌ No suitable signing certificate found!"
    echo "🔍 Available certificates:"
    security find-identity -v -p codesigning
    echo ""
    echo "💡 You need an Apple Distribution certificate to fix this issue"
    echo "📋 Please ensure you have a valid distribution certificate installed"
    exit 1
fi

echo "✅ Found signing certificate: $SIGNING_IDENTITY"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "📂 Using temporary directory: $TEMP_DIR"

# Extract the IPA
echo "📦 Extracting IPA..."
cd "$TEMP_DIR"
unzip -q "$(pwd)/../$IPA_FILE"

# Find the app bundle
APP_BUNDLE=$(find . -name "*.app" -type d | head -1)
if [ -z "$APP_BUNDLE" ]; then
    echo "❌ No app bundle found in IPA"
    cd ..
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "📱 Found app bundle: $APP_BUNDLE"

# Create framework entitlements
echo "📝 Creating framework entitlements..."
cat > framework_entitlements.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.team-identifier</key>
    <string>BL7NANM4RM</string>
</dict>
</plist>
EOF

# Create main app entitlements
echo "📝 Creating main app entitlements..."
cat > main_app_entitlements.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>BL7NANM4RM.com.qaonline.app</string>
    <key>com.apple.developer.team-identifier</key>
    <string>BL7NANM4RM</string>
    <key>get-task-allow</key>
    <false/>
    <key>keychain-access-groups</key>
    <array>
        <string>BL7NANM4RM.*</string>
    </array>
</dict>
</plist>
EOF

# Sign all frameworks
echo "🔐 Signing frameworks..."
FRAMEWORKS_DIR="$APP_BUNDLE/Frameworks"

if [ -d "$FRAMEWORKS_DIR" ]; then
    for framework in "$FRAMEWORKS_DIR"/*.framework; do
        if [ -d "$framework" ]; then
            framework_name=$(basename "$framework")
            echo "🔐 Signing framework: $framework_name"
            
            # Remove existing signature
            codesign --remove-signature "$framework" 2>/dev/null || true
            
            # Sign with entitlements
            if codesign --force --sign "$SIGNING_IDENTITY" --entitlements framework_entitlements.plist --verbose "$framework"; then
                echo "✅ Successfully signed $framework_name"
                
                # Verify signature
                if codesign --verify --verbose "$framework" 2>/dev/null; then
                    echo "✅ Signature verification passed for $framework_name"
                else
                    echo "⚠️ Signature verification failed for $framework_name"
                fi
            else
                echo "❌ Failed to sign $framework_name"
            fi
        fi
    done
else
    echo "ℹ️ No frameworks directory found"
fi

# Embed provisioning profile if available
echo "📄 Checking for provisioning profile..."
if [ -f "$(pwd)/../QAOnlineAppStoreProfile.mobileprovision" ]; then
    echo "📄 Embedding provisioning profile..."
    cp "$(pwd)/../QAOnlineAppStoreProfile.mobileprovision" "$APP_BUNDLE/embedded.mobileprovision"
    echo "✅ Provisioning profile embedded"
else
    echo "⚠️ No provisioning profile found - this may cause issues"
fi

# Sign the main app
echo "🔐 Signing main app..."
codesign --remove-signature "$APP_BUNDLE" 2>/dev/null || true

if codesign --force --sign "$SIGNING_IDENTITY" --entitlements main_app_entitlements.plist --verbose "$APP_BUNDLE"; then
    echo "✅ Successfully signed main app"
    
    # Verify main app signature
    if codesign --verify --verbose "$APP_BUNDLE" 2>/dev/null; then
        echo "✅ Main app signature verification passed"
    else
        echo "⚠️ Main app signature verification failed"
    fi
else
    echo "❌ Failed to sign main app"
    cd ..
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Create the fixed IPA
echo "📦 Creating fixed IPA..."
FIXED_IPA="${IPA_FILE%.*}-FIXED.ipa"
zip -r "$FIXED_IPA" Payload/

# Move back and copy the fixed IPA
cd ..
cp "$TEMP_DIR/$FIXED_IPA" "./$(basename "$FIXED_IPA")"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 SUCCESS! Fixed IPA created!"
echo "📱 Fixed IPA: $(basename "$FIXED_IPA")"
echo "📊 File size: $(ls -lh "$(basename "$FIXED_IPA")" | awk '{print $5}')"
echo ""
echo "📋 Next steps:"
echo "1. Upload the fixed IPA to App Store Connect"
echo "2. The frameworks should now be properly signed"
echo "3. Upload at: https://appstoreconnect.apple.com"
echo ""
echo "🔧 Command to upload:"
echo "xcrun altool --upload-app --type ios --file \"$(basename "$FIXED_IPA")\" --apiKey GFAD2LJGMF --apiIssuer ebf8afbb-9400-43d1-8a48-66d148957a62"
