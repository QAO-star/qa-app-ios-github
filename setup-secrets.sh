#!/bin/bash

echo "🚀 iOS Automated Build Setup Helper"
echo "=================================="
echo ""

echo "This script will help you set up the required GitHub secrets for automated iOS builds."
echo ""

# Check if we're in the right directory
if [ ! -f "capacitor.config.js" ]; then
    echo "❌ Error: Please run this script from your project root directory"
    exit 1
fi

echo "📋 Required GitHub Secrets:"
echo ""

echo "1. APP_STORE_CONNECT_API_KEY"
echo "   - Go to: https://appstoreconnect.apple.com"
echo "   - Navigate to: Users and Access → Keys"
echo "   - Generate a new API Key"
echo "   - Download the .p8 file"
echo "   - Copy the ENTIRE content of the .p8 file"
echo ""

echo "2. APP_STORE_CONNECT_API_KEY_ID"
echo "   - This is the filename of your .p8 file (without extension)"
echo "   - Example: If your file is 'AuthKey_ZA7M4DJPV8.p8', the ID is 'ZA7M4DJPV8'"
echo ""

echo "3. APP_STORE_CONNECT_ISSUER_ID"
echo "   - Found in App Store Connect → Users and Access → Keys"
echo "   - It's a long string like: 6751101564"
echo ""

echo "4. APPLE_TEAM_ID"
echo "   - Go to: https://developer.apple.com"
echo "   - Navigate to: Membership"
echo "   - Copy your Team ID"
echo ""

echo "🔧 How to add these secrets:"
echo "1. Go to your GitHub repository: https://github.com/QAI-O/qa-app-ios"
echo "2. Click 'Settings' tab"
echo "3. Click 'Secrets and variables' → 'Actions'"
echo "4. Click 'New repository secret' for each secret"
echo ""

echo "📱 Current App Configuration:"
echo "   - Bundle ID: com.qaonline.app"
echo "   - App Name: QA-Online"
echo "   - Team ID: BL7NANM4RM (from your files)"
echo "   - API Key ID: ZA7M4DJPV8 (from your files)"
echo ""

echo "🚀 After setting up secrets, you can:"
echo "1. Test the build: Go to Actions tab and run 'Test iOS Build'"
echo "2. Deploy to TestFlight: Push to main branch"
echo "3. Release to App Store: Create a version tag (e.g., v1.0.0)"
echo ""

echo "📚 For detailed instructions, see: SETUP_GUIDE.md"
echo ""

read -p "Press Enter to continue..."
