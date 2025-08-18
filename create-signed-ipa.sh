#!/bin/bash

# Create Signed IPA with Proper Framework Signing
# This script ensures frameworks are signed before the main app bundle

set -e

echo "📱 Creating Signed IPA with Proper Framework Signing"
echo "===================================================="

# Check if we have an unsigned IPA or Payload directory
if [ -f "App.ipa" ]; then
    echo "✅ Found App.ipa, extracting..."
    rm -rf Payload
    unzip -q App.ipa
    echo "✅ IPA extracted to Payload/"
elif [ -d "Payload" ]; then
    echo "✅ Found existing Payload directory"
else
    echo "❌ No App.ipa or Payload directory found"
    echo "📥 Please ensure you have either App.ipa or Payload/App.app"
    exit 1
fi

# Verify app structure
if [ ! -d "Payload/App.app" ]; then
    echo "❌ App.app not found in Payload directory"
    exit 1
fi

echo "📱 App bundle found: Payload/App.app"

# Check for frameworks
if [ -d "Payload/App.app/Frameworks" ]; then
    echo "📁 Frameworks found:"
    ls -la Payload/App.app/Frameworks/
else
    echo "ℹ️  No frameworks directory found"
fi

# Install provisioning profile if available
if [ -f "QAOnlineAppStoreProfile.mobileprovision" ]; then
    echo "📄 Installing provisioning profile in app bundle..."
    cp QAOnlineAppStoreProfile.mobileprovision Payload/App.app/embedded.mobileprovision
    echo "✅ Provisioning profile installed"
else
    echo "⚠️  No provisioning profile found - app may not be properly signed"
fi

# Check if we're on macOS (required for proper signing)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Running on macOS - can perform proper signing"
    
    # Find signing identity
    SIGNING_IDENTITY=""
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Distribution"; then
        SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -1 | cut -d'"' -f2)
    elif security find-identity -v -p codesigning 2>/dev/null | grep -q "iPhone Distribution"; then
        SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "iPhone Distribution" | head -1 | cut -d'"' -f2)
    fi
    
    if [ -n "$SIGNING_IDENTITY" ]; then
        echo "✅ Found signing identity: $SIGNING_IDENTITY"
        
        # Sign frameworks first
        if [ -d "Payload/App.app/Frameworks" ]; then
            echo "🔐 Signing frameworks individually..."
            for framework in Payload/App.app/Frameworks/*.framework; do
                if [ -d "$framework" ]; then
                    echo "  🔐 Signing $(basename "$framework")..."
                    codesign --force --sign "$SIGNING_IDENTITY" "$framework"
                    echo "  ✅ $(basename "$framework") signed"
                fi
            done
            echo "✅ All frameworks signed"
        fi
        
        # Sign main app bundle
        echo "🔐 Signing main app bundle..."
        codesign --force --sign "$SIGNING_IDENTITY" Payload/App.app
        echo "✅ Main app bundle signed"
        
        # Verify signatures
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
        
        if codesign --verify Payload/App.app 2>/dev/null; then
            echo "✅ Main app signature verified"
        else
            echo "❌ Main app signature verification failed"
            exit 1
        fi
        
        IPA_NAME="App-signed.ipa"
    else
        echo "⚠️  No signing identity found - creating unsigned IPA"
        IPA_NAME="App-unsigned.ipa"
    fi
else
    echo "🐧 Running on non-macOS system - creating unsigned IPA"
    echo "⚠️  For proper App Store submission, this IPA must be signed on macOS"
    IPA_NAME="App-unsigned.ipa"
fi

# Create the final IPA
echo "📦 Creating final IPA: $IPA_NAME"
rm -f "$IPA_NAME"
zip -r "$IPA_NAME" Payload/

# Create signed-ipa.zip for compatibility with upload scripts
echo "📦 Creating signed-ipa.zip for upload scripts..."
rm -f signed-ipa.zip
zip signed-ipa.zip "$IPA_NAME"
mv "$IPA_NAME" App.ipa  # Rename for upload script compatibility

# Clean up
rm -rf Payload

echo ""
echo "🎉 IPA Creation Complete!"
echo "=========================="
echo "📱 Created: App.ipa"
echo "📦 Archive: signed-ipa.zip"
echo "📊 Size: $(ls -lah App.ipa | awk '{print $5}')"

if [[ "$OSTYPE" == "darwin"* ]] && [ -n "$SIGNING_IDENTITY" ]; then
    echo "✅ IPA is properly signed and ready for App Store Connect"
    echo "🚀 Frameworks are individually signed to pass Apple validation"
else
    echo "⚠️  IPA is unsigned - transfer to macOS for signing before upload"
    echo "🔧 Use ./fix-framework-signing.sh on macOS to sign properly"
fi

echo ""
echo "📤 Ready for upload to App Store Connect!"
