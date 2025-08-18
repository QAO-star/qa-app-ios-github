#!/bin/bash

# iOS Signing Diagnostic Script
# This script helps diagnose signing issues with your iOS app

set -e

echo "🔍 iOS Signing Diagnostic Script"
echo "================================"
echo ""

# Check operating system
echo "🖥️  System Information:"
echo "   OS: $(uname -s)"
echo "   Version: $(uname -r)"
echo "   Architecture: $(uname -m)"
echo ""

# Check if we have the IPA or Payload
echo "📱 App Bundle Check:"
if [ -f "App.ipa" ]; then
    echo "   ✅ App.ipa found ($(ls -lah App.ipa | awk '{print $5}')"
elif [ -d "Payload" ]; then
    echo "   ✅ Payload directory found"
    if [ -d "Payload/App.app" ]; then
        echo "   ✅ App.app found in Payload"
    else
        echo "   ❌ App.app not found in Payload"
    fi
else
    echo "   ❌ Neither App.ipa nor Payload directory found"
fi
echo ""

# Check for signing files
echo "🔐 Signing Files Check:"
if [ -f "QAOnlineAppStoreProfile.mobileprovision" ]; then
    echo "   ✅ QAOnlineAppStoreProfile.mobileprovision found"
else
    echo "   ❌ QAOnlineAppStoreProfile.mobileprovision not found"
fi

if [ -f "ios_distribution.p12" ]; then
    echo "   ✅ ios_distribution.p12 found"
else
    echo "   ❌ ios_distribution.p12 not found"
fi
echo ""

# Check if we're on macOS and can check signing tools
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 macOS Signing Tools Check:"
    
    # Check for Xcode tools
    if command -v codesign &> /dev/null; then
        echo "   ✅ codesign available"
    else
        echo "   ❌ codesign not available - install Xcode Command Line Tools"
    fi
    
    if command -v security &> /dev/null; then
        echo "   ✅ security command available"
    else
        echo "   ❌ security command not available"
    fi
    
    if command -v xcrun &> /dev/null; then
        echo "   ✅ xcrun available"
    else
        echo "   ❌ xcrun not available - install Xcode"
    fi
    
    echo ""
    echo "🔑 Available Signing Identities:"
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "iPhone Distribution\|Apple Distribution"; then
        security find-identity -v -p codesigning | grep -E "iPhone Distribution|Apple Distribution"
        echo "   ✅ Distribution certificate found"
    else
        echo "   ❌ No distribution certificate found"
        echo "   📋 All available signing identities:"
        security find-identity -v -p codesigning 2>/dev/null || echo "   No signing identities found"
    fi
    
    echo ""
    echo "📄 Provisioning Profiles:"
    PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
    if [ -d "$PROFILES_DIR" ]; then
        PROFILE_COUNT=$(find "$PROFILES_DIR" -name "*.mobileprovision" 2>/dev/null | wc -l)
        echo "   📁 Profiles directory: $PROFILES_DIR"
        echo "   📊 Installed profiles: $PROFILE_COUNT"
        if [ $PROFILE_COUNT -gt 0 ]; then
            echo "   📋 Recent profiles:"
            find "$PROFILES_DIR" -name "*.mobileprovision" -exec basename {} \; 2>/dev/null | head -3 | sed 's/^/      /'
        fi
    else
        echo "   ❌ No provisioning profiles directory found"
    fi
    
else
    echo "🐧 Non-macOS System:"
    echo "   ⚠️  You're on a non-macOS system"
    echo "   ⚠️  iOS signing requires macOS with Xcode"
    echo "   💡 Consider using:"
    echo "      - macOS virtual machine"
    echo "      - CI/CD with macOS runners"
    echo "      - Transfer files to macOS for signing"
fi

echo ""

# Check app structure if Payload exists
if [ -d "Payload/App.app" ]; then
    echo "📦 App Bundle Structure:"
    echo "   📱 Main app: Payload/App.app"
    
    if [ -f "Payload/App.app/Info.plist" ]; then
        echo "   ✅ Info.plist found"
        if command -v plutil &> /dev/null; then
            BUNDLE_ID=$(plutil -p "Payload/App.app/Info.plist" 2>/dev/null | grep CFBundleIdentifier | cut -d'"' -f4 || echo "unknown")
            echo "   📱 Bundle ID: $BUNDLE_ID"
        fi
    else
        echo "   ❌ Info.plist not found"
    fi
    
    if [ -f "Payload/App.app/embedded.mobileprovision" ]; then
        echo "   ✅ Embedded provisioning profile found"
    else
        echo "   ❌ No embedded provisioning profile"
    fi
    
    if [ -d "Payload/App.app/Frameworks" ]; then
        echo "   📁 Frameworks directory found:"
        for framework in Payload/App.app/Frameworks/*.framework; do
            if [ -d "$framework" ]; then
                FRAMEWORK_NAME=$(basename "$framework")
                echo "      📦 $FRAMEWORK_NAME"
                
                # Check signing on macOS
                if [[ "$OSTYPE" == "darwin"* ]] && command -v codesign &> /dev/null; then
                    if codesign --verify "$framework" 2>/dev/null; then
                        echo "         ✅ Properly signed"
                    else
                        echo "         ❌ Not signed or invalid signature"
                    fi
                fi
            fi
        done
    else
        echo "   ℹ️  No Frameworks directory"
    fi
    
    # Check main app signing on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && command -v codesign &> /dev/null; then
        echo ""
        echo "🔍 Current Signing Status:"
        if codesign --verify "Payload/App.app" 2>/dev/null; then
            echo "   ✅ Main app bundle is properly signed"
            codesign -dv "Payload/App.app" 2>&1 | sed 's/^/      /'
        else
            echo "   ❌ Main app bundle is not signed or has invalid signature"
        fi
    fi
fi

echo ""
echo "📋 Recommendations:"

# Provide specific recommendations based on findings
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "   1. 🍎 Move to macOS for proper iOS signing"
    echo "   2. 🔧 Use the Ubuntu script to create unsigned IPA"
    echo "   3. 🚀 Set up CI/CD with macOS runners"
elif ! command -v codesign &> /dev/null; then
    echo "   1. 🛠️  Install Xcode Command Line Tools: xcode-select --install"
    echo "   2. 🍎 Install Xcode from App Store"
elif ! security find-identity -v -p codesigning 2>/dev/null | grep -q "iPhone Distribution\|Apple Distribution"; then
    echo "   1. 📄 Install your distribution certificate (.p12 file)"
    echo "   2. 🔑 Import certificate into Keychain Access"
    echo "   3. 🔐 Ensure certificate is trusted"
else
    echo "   1. ✅ Your system appears ready for iOS signing"
    echo "   2. 🚀 Run ./fix-framework-signing.sh to sign your app"
    echo "   3. 📤 Upload signed IPA to App Store Connect"
fi

echo ""
echo "🔗 For detailed help, see: FRAMEWORK_SIGNING_FIX.md"
echo ""
echo "🎯 Diagnostic complete!"
