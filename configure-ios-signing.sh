#!/bin/bash

echo "🔧 Configuring iOS code signing..."

cd ios/App

# Update Info.plist
echo "📱 Updating Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.qaonline.app" App/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName QA-Online" App/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0.0" App/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $GITHUB_RUN_NUMBER" App/Info.plist

# Configure Xcode project for automatic signing
echo "🔐 Configuring Xcode project for automatic signing..."

# Use sed to update the project.pbxproj file
sed -i '' 's/CODE_SIGN_STYLE = Manual;/CODE_SIGN_STYLE = Automatic;/g' App.xcodeproj/project.pbxproj
sed -i '' 's/DEVELOPMENT_TEAM = "";/DEVELOPMENT_TEAM = "'$APPLE_TEAM_ID'";/g' App.xcodeproj/project.pbxproj
sed -i '' 's/CODE_SIGN_IDENTITY = "iPhone Distribution";/CODE_SIGN_IDENTITY = "Apple Development";/g' App.xcodeproj/project.pbxproj

echo "✅ iOS signing configuration complete!"
