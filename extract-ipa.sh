#!/bin/bash

echo "🔧 Manually extracting IPA from archive..."

cd ios/App

# Check if archive exists
if [ ! -d "App.xcarchive" ]; then
    echo "❌ Archive not found!"
    exit 1
fi

echo "📦 Archive found, extracting app..."

# Create Payload directory
mkdir -p Payload

# Copy the app to Payload directory
cp -r App.xcarchive/Products/Applications/App.app Payload/

# Create IPA file
echo "📱 Creating IPA file..."
zip -r App.ipa Payload/

# Verify IPA was created
if [ -f "App.ipa" ]; then
    echo "✅ IPA file created successfully!"
    ls -la App.ipa
    echo "📱 IPA file size: $(ls -lh App.ipa | awk '{print $5}')"
else
    echo "❌ Failed to create IPA file!"
    exit 1
fi

# Clean up
rm -rf Payload

echo "🎉 IPA extraction complete!"
