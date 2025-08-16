#!/bin/bash

# 🚀 QA-Online iOS App Deployment Script
# This script handles the complete deployment process for iOS App Store builds

set -e  # Exit on any error

echo "🚀 Starting QA-Online iOS deployment process..."

# Configuration
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
NEW_VERSION="v1.0.$(($(echo $CURRENT_VERSION | cut -d. -f3) + 1))"
RELEASE_TAG="release-${NEW_VERSION}"

echo "📱 Current version: $CURRENT_VERSION"
echo "📱 New version: $NEW_VERSION"
echo "📱 Release tag: $RELEASE_TAG"

# Step 1: Check if we have uncommitted changes
echo "🔍 Checking for uncommitted changes..."
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ You have uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi
echo "✅ No uncommitted changes found"

# Step 2: Pull latest changes from main
echo "📥 Pulling latest changes from main..."
git pull origin main
echo "✅ Latest changes pulled"

# Step 3: Create new version tag
echo "🏷️ Creating new version tag: $NEW_VERSION"
git tag $NEW_VERSION
echo "✅ Version tag created: $NEW_VERSION"

# Step 4: Create release tag
echo "🏷️ Creating release tag: $RELEASE_TAG"
git tag $RELEASE_TAG
echo "✅ Release tag created: $RELEASE_TAG"

# Step 5: Push all tags
echo "📤 Pushing all tags to remote..."
git push origin --tags
echo "✅ All tags pushed to remote"

# Step 6: Push main branch (triggers test pipeline)
echo "📤 Pushing main branch (triggers test pipeline)..."
git push origin main
echo "✅ Main branch pushed"

echo ""
echo "🎉 Deployment process completed!"
echo ""
echo "📱 Version: $NEW_VERSION"
echo "📱 Release tag: $RELEASE_TAG"
echo "📱 CircleCI URL: https://app.circleci.com/pipelines/github/QAI-O/qa-app-ios"
echo ""
echo "⏱️ Expected timeline:"
echo "   - Test build: 5-10 minutes"
echo "   - Release build: 15-20 minutes"
echo ""
echo "🔍 Monitor your builds at: https://app.circleci.com/pipelines/github/QAI-O/qa-app-ios"
