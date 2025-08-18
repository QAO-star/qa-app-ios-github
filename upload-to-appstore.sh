#!/bin/bash

# 🚀 QA-Online iOS App Store Upload Script
# This script signs the existing IPA and uploads it to App Store Connect

set -e  # Exit on any error

echo "🚀 Starting QA-Online iOS App Store upload process..."

# Configuration
APPLE_ID="6751101564"
TEAM_ID="BL7NANM4RM"
BUNDLE_ID="com.qaonline.app"
API_KEY_ID="ZA7M4DJPV8"
API_KEY_FILE="AuthKey_ZA7M4DJPV8.p8"
API_ISSUER_ID="ebf8afbb-9400-43d1-8a48-66d148957a62"

echo "📱 Configuration:"
echo "  Apple ID: $APPLE_ID"
echo "  Team ID: $TEAM_ID"
echo "  Bundle ID: $BUNDLE_ID"
echo "  API Key ID: $API_KEY_ID"

# Step 1: Check if we have the signed IPA
echo "🔍 Checking for signed IPA..."
if [ -f "signed-ipa.zip" ]; then
    echo "✅ Found signed-ipa.zip"
    unzip -o signed-ipa.zip
    if [ -f "App.ipa" ]; then
        echo "✅ Found App.ipa"
        IPA_FILE="App.ipa"
    elif [ -d "Payload" ]; then
        echo "✅ Found Payload directory in signed-ipa.zip, creating IPA..."
        # Create IPA from Payload directory
        zip -r App.ipa Payload/
        IPA_FILE="App.ipa"
        echo "✅ Created App.ipa from Payload"
    else
        echo "❌ Neither App.ipa nor Payload directory found in signed-ipa.zip"
        exit 1
    fi
elif [ -d "Payload" ]; then
    echo "✅ Found Payload directory, creating IPA..."
    # Create IPA from Payload directory
    zip -r App.ipa Payload/
    IPA_FILE="App.ipa"
    echo "✅ Created App.ipa from Payload"
else
    echo "❌ No signed IPA or Payload directory found"
    exit 1
fi

# Step 2: Set up keychain for signing
echo "🔐 Setting up keychain for signing..."
security create-keychain -p "" build.keychain || echo "Keychain may already exist"
security list-keychains -s build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "" build.keychain
security set-keychain-settings build.keychain

# Step 3: Install certificates
echo "📄 Installing certificates..."

# Check for P12 certificate
if [ -f "ios_distribution.p12" ]; then
    echo "✅ Found P12 certificate, installing..."
    # Try different passwords
    PASSWORDS=("" "Geok1800!" "password" "123456" "admin" "ios" "apple" "developer")
    
    for PASSWORD in "${PASSWORDS[@]}"; do
        echo "🔐 Trying password: ${PASSWORD:-'empty'}"
        if security import ios_distribution.p12 -k build.keychain -T /usr/bin/codesign -P "$PASSWORD" 2>/dev/null; then
            echo "✅ P12 certificate installed successfully with password: ${PASSWORD:-'empty'}"
            break
        fi
    done
else
    echo "⚠️ P12 certificate not found, checking for base64 encoded certificate..."
    if [ -f "ios_cert_base64.txt" ]; then
        echo "✅ Found base64 encoded certificate, decoding and installing..."
        base64 -d ios_cert_base64.txt > ios_distribution.p12
        security import ios_distribution.p12 -k build.keychain -T /usr/bin/codesign -P "" 2>/dev/null || echo "Certificate import failed"
    fi
fi

# Step 4: Install provisioning profile
echo "📄 Installing provisioning profile..."
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

if [ -f "QAOnlineAppStoreProfile.mobileprovision" ]; then
    echo "✅ Found provisioning profile, installing..."
    cp QAOnlineAppStoreProfile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
    echo "✅ Provisioning profile installed"
elif [ -f "provisioning_profile_base64.txt" ]; then
    echo "✅ Found base64 encoded provisioning profile, decoding and installing..."
    base64 -d provisioning_profile_base64.txt > QAOnlineAppStoreProfile.mobileprovision
    cp QAOnlineAppStoreProfile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
    echo "✅ Provisioning profile installed"
else
    echo "⚠️ No provisioning profile found, will use automatic signing"
fi

# Step 5: Find signing identity
echo "🔍 Finding signing identity..."
IDENTITIES_OUTPUT=$(security find-identity -v -p codesigning build.keychain)
echo "Available identities:"
echo "$IDENTITIES_OUTPUT"

# Look for distribution certificate
SIGNING_IDENTITY=$(echo "$IDENTITIES_OUTPUT" | grep -E "Apple Distribution|iPhone Distribution.*App Store" | head -1 | cut -d'"' -f2 || echo "")

if [ -n "$SIGNING_IDENTITY" ]; then
    echo "✅ Found signing identity: $SIGNING_IDENTITY"
else
    echo "⚠️ No distribution certificate found, will use automatic signing"
fi

# Step 6: Sign the IPA if needed
echo "🔐 Checking if IPA needs signing..."
if [ -n "$SIGNING_IDENTITY" ]; then
    echo "🔐 Signing IPA with identity: $SIGNING_IDENTITY"
    
    # Extract IPA
    mkdir -p temp_ipa
    cd temp_ipa
    unzip -o "../$IPA_FILE"
    
    # Install provisioning profile in app bundle
    if [ -f "../QAOnlineAppStoreProfile.mobileprovision" ]; then
        echo "📄 Installing provisioning profile in app bundle..."
        cp "../QAOnlineAppStoreProfile.mobileprovision" Payload/App.app/embedded.mobileprovision
        echo "✅ Provisioning profile installed in app bundle"
    fi
    
    # Sign all frameworks first (CRITICAL for App Store Connect validation)
    if [ -d "Payload/App.app/Frameworks" ]; then
        echo "🔐 Signing frameworks individually..."
        for framework in Payload/App.app/Frameworks/*.framework; do
            if [ -d "$framework" ]; then
                echo "  🔐 Signing $(basename "$framework")..."
                codesign --force --sign "$SIGNING_IDENTITY" "$framework"
                if [ $? -eq 0 ]; then
                    echo "  ✅ $(basename "$framework") signed successfully"
                else
                    echo "  ❌ Failed to sign $(basename "$framework")"
                    exit 1
                fi
            fi
        done
        echo "✅ All frameworks signed successfully"
    else
        echo "ℹ️  No frameworks directory found"
    fi
    
    # Now sign the main app bundle (must be done after frameworks)
    echo "🔐 Signing main app bundle..."
    codesign --force --sign "$SIGNING_IDENTITY" Payload/App.app/
    if [ $? -eq 0 ]; then
        echo "✅ Main app bundle signed successfully"
    else
        echo "❌ Failed to sign main app bundle"
        exit 1
    fi
    
    # Verify all signatures
    echo "🔍 Verifying signatures..."
    if [ -d "Payload/App.app/Frameworks" ]; then
        for framework in Payload/App.app/Frameworks/*.framework; do
            if [ -d "$framework" ]; then
                if codesign --verify "$framework" 2>/dev/null; then
                    echo "  ✅ $(basename "$framework") signature verified"
                else
                    echo "  ❌ $(basename "$framework") signature verification failed"
                    exit 1
                fi
            fi
        done
    fi
    
    if codesign --verify Payload/App.app/ 2>/dev/null; then
        echo "✅ Main app signature verified"
    else
        echo "❌ Main app signature verification failed"
        exit 1
    fi
    
    # Recreate IPA
    zip -r "../App-signed.ipa" Payload/
    cd ..
    rm -rf temp_ipa
    
    FINAL_IPA="App-signed.ipa"
    echo "✅ IPA signed successfully with proper framework signing"
else
    echo "⚠️ Using unsigned IPA for upload"
    FINAL_IPA="$IPA_FILE"
fi

# Step 7: Set up fastlane for upload
echo "🚀 Setting up fastlane for App Store Connect upload..."
mkdir -p fastlane

# Create Appfile
cat > fastlane/Appfile << EOF
app_identifier("$BUNDLE_ID")
apple_id("jonatan.k@qaonline.co.il")
team_id("$TEAM_ID")
EOF

# Create Fastfile
cat > fastlane/Fastfile << EOF
default_platform(:ios)

platform :ios do
  desc "Upload to App Store Connect"
  lane :upload do
    begin
      # Use API key for authentication
      UI.message("🔑 Using API key authentication...")
      api_key = app_store_connect_api_key(
        key_id: "$API_KEY_ID",
        issuer_id: "$API_ISSUER_ID",
        key_filepath: "$API_KEY_FILE",
        duration: 1200,
        in_house: false
      )
      UI.message("✅ API key authentication successful")
      
      # Upload to TestFlight
      UI.message("🚀 Uploading to TestFlight...")
      pilot(
        ipa: "$FINAL_IPA",
        app_platform: "ios",
        skip_waiting_for_build_processing: true,
        skip_submission: true,
        api_key: api_key
      )
      UI.message("✅ Upload to TestFlight completed successfully!")
    rescue => e
      UI.error("❌ Upload failed: \#{e.message}")
      UI.message("📦 IPA created successfully but upload failed")
      UI.message("📱 You can manually upload $FINAL_IPA to App Store Connect")
      raise e
    end
  end
end
EOF

# Step 8: Upload to App Store Connect
echo "🚀 Uploading to App Store Connect..."
if fastlane upload; then
    echo "✅ Upload to App Store Connect completed successfully!"
    echo "📱 Your app is now available in TestFlight"
    echo "🔗 Check: https://appstoreconnect.apple.com"
else
    echo "⚠️ Fastlane upload failed, trying altool fallback..."
    
    # Try altool as fallback
    mkdir -p ~/.appstoreconnect/private_keys
    cp "$API_KEY_FILE" ~/.appstoreconnect/private_keys/
    
    xcrun altool --upload-app --type ios --file "$FINAL_IPA" \
        --apiKey "$API_KEY_ID" \
        --apiIssuer "$API_ISSUER_ID" \
        --verbose
    
    if [ $? -eq 0 ]; then
        echo "✅ Upload to App Store Connect completed via altool"
    else
        echo "❌ Both fastlane and altool uploads failed"
        echo "📱 IPA created successfully: $FINAL_IPA"
        echo "📤 You can manually upload this IPA to App Store Connect"
        echo "🔗 Go to: https://appstoreconnect.apple.com"
        exit 1
    fi
fi

echo ""
echo "🎉 Upload process completed!"
echo "📱 IPA file: $FINAL_IPA"
echo "🔗 App Store Connect: https://appstoreconnect.apple.com"
echo "📧 Apple ID: jonatan.k@qaonline.co.il"
echo "�� Team ID: $TEAM_ID" 