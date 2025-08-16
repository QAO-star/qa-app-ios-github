#!/bin/bash

set -e

echo "🔐 iOS Signing and Export Script"
echo "================================"

# Configuration
TEAM_ID="${APPLE_TEAM_ID:-BL7NANM4RM}"
BUNDLE_ID="com.qaonline.app"
VERSION="${CIRCLE_TAG:-1.0.0}"
BUILD_NUM="${CIRCLE_BUILD_NUM:-1}"

echo "📱 Bundle ID: $BUNDLE_ID"
echo "📱 Team ID: $TEAM_ID"
echo "📱 Version: $VERSION"
echo "📱 Build: $BUILD_NUM"

# Install certificates and profiles if they exist
echo "🔐 Installing certificates and profiles..."

# Check if certificates directory exists and has files
if [ -d "certificates" ]; then
    echo "📁 Certificates directory found, checking contents..."
    ls -la certificates/
    
    if [ -f "certificates/distribution.cer" ]; then
        echo "  📄 Installing distribution certificate..."
        security import certificates/distribution.cer -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign
    fi

    if [ -f "certificates/distribution.p12" ]; then
        echo "  📄 Installing P12 certificate..."
        security import certificates/distribution.p12 -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign
    fi

    if [ -f "certificates/QA-Online-App-Store-Profile.mobileprovision" ]; then
        echo "  📄 Installing provisioning profile..."
        mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
        cp certificates/QA-Online-App-Store-Profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
    fi
else
    echo "📁 No certificates directory found, will use automatic signing"
fi

# Also check for the existing provisioning profile in the root
if [ -f "../../QAOnlineAppStoreProfile.mobileprovision" ]; then
    echo "📄 Installing existing provisioning profile from root..."
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    cp ../../QAOnlineAppStoreProfile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/QA-Online-App-Store-Profile.mobileprovision
fi

# Show available signing identities
echo "🔍 Available signing identities:"
security find-identity -v -p codesigning ~/Library/Keychains/login.keychain-db

# Configure iOS build settings
echo "⚙️ Configuring iOS build settings..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" App/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName QA-Online" App/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" App/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUM" App/Info.plist

# Clean and archive
echo "🔨 Building archive..."
xcodebuild clean -workspace App.xcworkspace -scheme App -configuration Release

# Try building with automatic signing first
echo "🔨 Building with automatic signing..."
xcodebuild archive \
    -workspace App.xcworkspace \
    -scheme App \
    -configuration Release \
    -destination generic/platform=iOS \
    -archivePath App.xcarchive \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CURRENT_PROJECT_VERSION="$BUILD_NUM" \
    MARKETING_VERSION="$VERSION" \
    CODE_SIGN_STYLE="Automatic" \
    -allowProvisioningUpdates

# If that fails, try without signing
if [ $? -ne 0 ]; then
    echo "❌ Automatic signing build failed, trying without signing..."
    xcodebuild archive \
        -workspace App.xcworkspace \
        -scheme App \
        -configuration Release \
        -destination generic/platform=iOS \
        -archivePath App.xcarchive \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
        CURRENT_PROJECT_VERSION="$BUILD_NUM" \
        MARKETING_VERSION="$VERSION" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
fi

# Create automatic signing export options
echo "📝 Creating automatic signing export options..."
cat > exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EOF

# Try automatic signing first
echo "🔐 Attempting automatic signing..."
xcodebuild -exportArchive \
    -archivePath App.xcarchive \
    -exportPath . \
    -exportOptionsPlist exportOptions.plist \
    -allowProvisioningUpdates

# Check if automatic signing succeeded
if [ -f "App.ipa" ]; then
    echo "✅ Automatic signing succeeded!"
    ls -la App.ipa
    exit 0
fi

echo "❌ Automatic signing failed, trying manual signing..."

# Try manual signing if certificates exist
if [ -f "certificates/distribution.p12" ] && [ -f "certificates/QA-Online-App-Store-Profile.mobileprovision" ]; then
    echo "🔐 Attempting manual signing with existing certificates..."
    
    # Create manual export options
    cat > exportOptions-manual.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingCertificate</key>
    <string>iPhone Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>QA-Online-App-Store-Profile</string>
    </dict>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EOF
    
    # Try manual export
    xcodebuild -exportArchive \
        -archivePath App.xcarchive \
        -exportPath . \
        -exportOptionsPlist exportOptions-manual.plist
else
    echo "❌ No manual certificates available, trying development export..."
    
    # Try development export as last resort
    cat > exportOptions-dev.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EOF
    
    xcodebuild -exportArchive \
        -archivePath App.xcarchive \
        -exportPath . \
        -exportOptionsPlist exportOptions-dev.plist \
        -allowProvisioningUpdates
fi

# Final verification
if [ ! -f "App.ipa" ]; then
    echo "❌ Signed IPA file was not created!"
    exit 1
fi

echo "✅ Signed IPA file created successfully!"
ls -la App.ipa
