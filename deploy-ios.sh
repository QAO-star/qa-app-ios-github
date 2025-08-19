#!/bin/bash

# QA-Online iOS Deployment Script
# This script helps you quickly deploy your iOS app to the App Store

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

echo "🚀 QA-Online iOS App Store Deployment"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f ".circleci/config.yml" ]; then
    error "Please run this script from the project root directory"
    exit 1
fi

# Check if required files exist
log "Checking required files..."

REQUIRED_FILES=(
    "auto_distribution.cer"
    "auto_distribution_private_key.pem"
    "QAOnlineAppStoreProfile.mobileprovision"
)

MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    else
        success "Found $file"
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    warning "Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "🔧 To generate missing certificates:"
    echo "   1. Create a branch called 'csr-generation'"
    echo "   2. Push it: git checkout -b csr-generation && git push origin csr-generation"
    echo "   3. Wait for CircleCI to generate the CSR"
    echo "   4. Download artifacts and create certificates"
    echo "   5. Add them to your repository"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check git status
log "Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
    warning "You have uncommitted changes:"
    git status --short
    echo ""
    read -p "Commit changes before deploying? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Prepare for iOS deployment"
        success "Changes committed"
    fi
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    warning "You're on branch '$CURRENT_BRANCH', not 'main'"
    read -p "Switch to main branch? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout main
        success "Switched to main branch"
    fi
fi

# Check CircleCI context
log "Checking CircleCI context..."
echo "Make sure you have set up the 'apple-credentials' context in CircleCI with:"
echo "  - APPLE_ID"
echo "  - APP_SPECIFIC_PASSWORD"
echo "  - APPLE_TEAM_ID"
echo ""

# Deploy
log "Ready to deploy!"
echo ""
echo "🎯 Next steps:"
echo "1. Push to main branch to trigger CircleCI build:"
echo "   git push origin main"
echo ""
echo "2. Monitor the build at:"
echo "   https://app.circleci.com/pipelines/github/[your-username]/qa-app-ios-github"
echo ""
echo "3. Check App Store Connect after successful upload:"
echo "   https://appstoreconnect.apple.com/apps"
echo ""

read -p "Push to main branch now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Pushing to main branch..."
    git push origin main
    success "Pushed to main branch!"
    echo ""
    echo "🚀 Deployment triggered!"
    echo "📱 Check CircleCI for build progress"
    echo "⏱️  Build typically takes 10-15 minutes"
    echo ""
    echo "📋 After successful build:"
    echo "1. Go to App Store Connect"
    echo "2. Create your app if it doesn't exist"
    echo "3. Submit for review"
    echo ""
    success "Your QA-Online iOS app is on its way to the App Store! 🎉"
else
    echo ""
    warning "Deployment cancelled. Run 'git push origin main' when ready."
fi 