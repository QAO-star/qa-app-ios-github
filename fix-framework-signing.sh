#!/bin/bash

# Fix Framework Signing for App Store Submission
# This script properly signs all embedded frameworks with Apple Distribution certificate

set -e

echo "🔐 Starting framework signing fix for App Store submission..."

# Function to find the correct signing identity
find_signing_identity() {
    echo "🔍 Looking for Apple Distribution certificate..."
    
    # Try to find Apple Distribution certificate
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep -E "Apple Distribution.*BL7NANM4RM" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    
    if [ -z "$SIGNING_IDENTITY" ]; then
        # Fallback to iPhone Distribution
        SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep -E "iPhone Distribution.*BL7NANM4RM" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    fi
    
    if [ -z "$SIGNING_IDENTITY" ]; then
        echo "❌ No suitable distribution certificate found!"
        echo "🔍 Available certificates:"
        security find-identity -v -p codesigning
        exit 1
    fi
    
    echo "✅ Found signing identity: $SIGNING_IDENTITY"
    echo "$SIGNING_IDENTITY"
}

# Function to sign a single framework
sign_framework() {
    local framework_path="$1"
    local signing_identity="$2"
    local framework_name=$(basename "$framework_path")
    
    echo "🔐 Signing framework: $framework_name"
    
    # Check if framework exists
    if [ ! -d "$framework_path" ]; then
        echo "⚠️ Framework not found: $framework_path"
        return 1
    fi
    
    # Get the framework binary path
    local framework_binary="$framework_path/$(basename "$framework_path" .framework)"
    
    if [ ! -f "$framework_binary" ]; then
        echo "⚠️ Framework binary not found: $framework_binary"
        return 1
    fi
    
    # Remove existing signature
    echo "🧹 Removing existing signature from $framework_name..."
    codesign --remove-signature "$framework_path" 2>/dev/null || true
    
    # Sign the framework with proper entitlements
    echo "✍️ Signing $framework_name with Apple Distribution certificate..."
    
    # Create temporary entitlements for frameworks
    local temp_entitlements="/tmp/${framework_name}_entitlements.plist"
    cat > "$temp_entitlements" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.team-identifier</key>
    <string>BL7NANM4RM</string>
</dict>
</plist>
EOF
    
    # Sign the framework
    if codesign --force --sign "$signing_identity" --entitlements "$temp_entitlements" --verbose "$framework_path"; then
        echo "✅ Successfully signed $framework_name"
        
        # Verify the signature
        if codesign --verify --verbose "$framework_path" 2>/dev/null; then
            echo "✅ Signature verification passed for $framework_name"
        else
            echo "⚠️ Signature verification failed for $framework_name"
        fi
    else
        echo "❌ Failed to sign $framework_name"
        return 1
    fi
    
    # Clean up temporary entitlements
    rm -f "$temp_entitlements"
}

# Function to sign all frameworks in an app bundle
sign_all_frameworks() {
    local app_path="$1"
    local signing_identity="$2"
    
    echo "🔍 Looking for frameworks in: $app_path"
    
    local frameworks_dir="$app_path/Frameworks"
    
    if [ ! -d "$frameworks_dir" ]; then
        echo "ℹ️ No Frameworks directory found in app bundle"
        return 0
    fi
    
    echo "📁 Found Frameworks directory: $frameworks_dir"
    ls -la "$frameworks_dir"
    
    # Sign each framework
    local signed_count=0
    local failed_count=0
    
    for framework in "$frameworks_dir"/*.framework; do
        if [ -d "$framework" ]; then
            if sign_framework "$framework" "$signing_identity"; then
                ((signed_count++))
            else
                ((failed_count++))
            fi
        fi
    done
    
    echo "📊 Framework signing summary:"
    echo "   ✅ Successfully signed: $signed_count frameworks"
    echo "   ❌ Failed to sign: $failed_count frameworks"
    
    if [ $failed_count -gt 0 ]; then
        echo "⚠️ Some frameworks failed to sign, but continuing..."
    fi
}

# Function to re-sign the main app bundle
sign_main_app() {
    local app_path="$1"
    local signing_identity="$2"
    
    echo "🔐 Re-signing main app bundle..."
    
    # Create main app entitlements
    local main_entitlements="/tmp/main_app_entitlements.plist"
    cat > "$main_entitlements" << 'EOF'
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
    
    # Remove existing signature from main app
    echo "🧹 Removing existing signature from main app..."
    codesign --remove-signature "$app_path" 2>/dev/null || true
    
    # Sign main app
    echo "✍️ Signing main app with Apple Distribution certificate..."
    if codesign --force --sign "$signing_identity" --entitlements "$main_entitlements" --verbose "$app_path"; then
        echo "✅ Successfully signed main app"
        
        # Verify main app signature
        if codesign --verify --verbose "$app_path" 2>/dev/null; then
            echo "✅ Main app signature verification passed"
        else
            echo "⚠️ Main app signature verification failed"
        fi
    else
        echo "❌ Failed to sign main app"
        rm -f "$main_entitlements"
        return 1
    fi
    
    # Clean up
    rm -f "$main_entitlements"
}

# Function to fix an existing IPA
fix_ipa_signing() {
    local ipa_path="$1"
    
    if [ ! -f "$ipa_path" ]; then
        echo "❌ IPA file not found: $ipa_path"
        return 1
    fi
    
    echo "📦 Processing IPA: $ipa_path"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local fixed_ipa="${ipa_path%.*}-fixed.ipa"
    
    echo "📂 Using temporary directory: $temp_dir"
    
    # Extract IPA
    echo "📦 Extracting IPA..."
    cd "$temp_dir"
    unzip -q "$ipa_path"
    
    # Find the app bundle
    local app_bundle=$(find . -name "*.app" -type d | head -1)
    
    if [ -z "$app_bundle" ]; then
        echo "❌ No app bundle found in IPA"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo "📱 Found app bundle: $app_bundle"
    
    # Get signing identity
    local signing_identity=$(find_signing_identity)
    
    # Sign all frameworks first
    sign_all_frameworks "$app_bundle" "$signing_identity"
    
    # Then sign the main app
    sign_main_app "$app_bundle" "$signing_identity"
    
    # Embed provisioning profile if available
    if [ -f "$(dirname "$ipa_path")/QAOnlineAppStoreProfile.mobileprovision" ]; then
        echo "📄 Embedding provisioning profile..."
        cp "$(dirname "$ipa_path")/QAOnlineAppStoreProfile.mobileprovision" "$app_bundle/embedded.mobileprovision"
        echo "✅ Provisioning profile embedded"
    elif [ -f "./QAOnlineAppStoreProfile.mobileprovision" ]; then
        echo "📄 Embedding provisioning profile from current directory..."
        cp "./QAOnlineAppStoreProfile.mobileprovision" "$app_bundle/embedded.mobileprovision"
        echo "✅ Provisioning profile embedded"
    else
        echo "⚠️ No provisioning profile found to embed"
    fi
    
    # Create new IPA
    echo "📦 Creating fixed IPA..."
    zip -r "$fixed_ipa" Payload/
    
    # Move back to original directory
    cd - > /dev/null
    mv "$temp_dir/$fixed_ipa" "$fixed_ipa"
    
    # Clean up
    rm -rf "$temp_dir"
    
    echo "✅ Fixed IPA created: $fixed_ipa"
    echo "📊 File size: $(ls -lh "$fixed_ipa" | awk '{print $5}')"
    
    return 0
}

# Main execution
main() {
    echo "🚀 Framework Signing Fix Script"
    echo "================================"
    
    # Check if we're in the right directory
    if [ ! -f "capacitor.config.js" ] && [ ! -f "package.json" ]; then
        echo "❌ This doesn't appear to be a Capacitor project directory"
        echo "💡 Please run this script from your project root"
        exit 1
    fi
    
    # Look for IPA files to fix
    local ipa_files=(*.ipa)
    
    if [ ${#ipa_files[@]} -eq 0 ] || [ ! -f "${ipa_files[0]}" ]; then
        echo "❌ No IPA files found in current directory"
        echo "💡 Please ensure you have an IPA file to fix"
        echo "🔍 Looking for IPA files in common locations..."
        
        # Check common locations
        if [ -f "ios/App/App.ipa" ]; then
            echo "✅ Found IPA in ios/App/App.ipa"
            ipa_files=("ios/App/App.ipa")
        elif [ -f "App.ipa" ]; then
            echo "✅ Found IPA in current directory"
            ipa_files=("App.ipa")
        else
            echo "❌ No IPA files found"
            exit 1
        fi
    fi
    
    # Process each IPA file
    for ipa_file in "${ipa_files[@]}"; do
        if [ -f "$ipa_file" ]; then
            echo ""
            echo "🔧 Processing: $ipa_file"
            echo "================================"
            
            if fix_ipa_signing "$ipa_file"; then
                echo "✅ Successfully fixed: $ipa_file"
            else
                echo "❌ Failed to fix: $ipa_file"
            fi
        fi
    done
    
    echo ""
    echo "🎉 Framework signing fix completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Test the fixed IPA by uploading to App Store Connect"
    echo "2. If successful, update your build pipeline to include framework signing"
    echo "3. The fixed IPA should now pass Apple's validation"
    echo ""
    echo "🔗 Upload your fixed IPA at: https://appstoreconnect.apple.com"
}

# Run main function
main "$@"
