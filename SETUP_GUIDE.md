# 🚀 iOS Automated Build & App Store Deployment Setup Guide

This guide will help you set up automatic iOS builds and App Store deployments using GitHub Actions.

## 📋 Prerequisites

### 1. Apple Developer Account
- Active Apple Developer Program membership ($99/year)
- Access to App Store Connect
- App Store Connect API Key

### 2. GitHub Repository
- Repository with your iOS app code
- Admin access to repository settings

## 🔑 Required GitHub Secrets

You need to set up these secrets in your GitHub repository:

### Go to: `Settings` → `Secrets and variables` → `Actions`

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `APP_STORE_CONNECT_API_KEY` | Content of your `.p8` file | Your App Store Connect API key file content |
| `APP_STORE_CONNECT_API_KEY_ID` | `ZA7M4DJPV8` | Your API Key ID (from the filename) |
| `APP_STORE_CONNECT_ISSUER_ID` | `6751101564` | Your Issuer ID from App Store Connect |
| `APPLE_TEAM_ID` | `BL7NANM4RM` | Your Apple Developer Team ID |

## 🛠️ How to Get Your Apple Credentials

### 1. App Store Connect API Key
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to `Users and Access` → `Keys`
3. Click `Generate API Key`
4. Download the `.p8` file
5. Copy the **Key ID** and **Issuer ID**

### 2. Apple Developer Team ID
1. Go to [Apple Developer](https://developer.apple.com)
2. Navigate to `Membership`
3. Copy your **Team ID**

## 🔄 Workflow Triggers

The automated build will trigger on:

1. **Push to main branch** - Builds and uploads to TestFlight
2. **Version tags** (e.g., `v1.0.0`) - Creates release and uploads to App Store
3. **Manual trigger** - Via GitHub Actions UI
4. **Release published** - When you create a GitHub release

## 📱 Build Process

### What the workflow does:

1. **Setup Environment**
   - macOS runner with Xcode 15.2
   - Node.js 18
   - Capacitor CLI

2. **Build Preparation**
   - Install dependencies
   - Add iOS platform (if needed)
   - Sync Capacitor configuration
   - Install CocoaPods dependencies

3. **iOS Build**
   - Configure app settings
   - Build archive with Xcode
   - Export IPA file
   - Verify build success

4. **Deployment**
   - Upload to App Store Connect
   - Create GitHub release (for tags)
   - Store IPA as artifact

## 🚀 How to Deploy

### Option 1: Tag-based Release (Recommended)
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

### Option 2: Manual Trigger
1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Build and Deploy iOS to App Store**
4. Click **Run workflow**

### Option 3: Push to Main
```bash
# Any push to main branch triggers build
git push origin main
```

## 📊 Monitoring Builds

### Check Build Status
- **GitHub Actions**: https://github.com/QAI-O/qa-app-ios/actions
- **App Store Connect**: https://appstoreconnect.apple.com
- **TestFlight**: Available after first successful upload

### Build Artifacts
- IPA files are stored as GitHub artifacts
- Available for 90 days
- Can be downloaded for manual installation

## 🔧 Troubleshooting

### Common Issues

#### 1. Build Fails
**Error**: `xcodebuild: error: No signing certificate found`
**Solution**: Verify your `APPLE_TEAM_ID` secret is correct

#### 2. Upload Fails
**Error**: `Authentication failed`
**Solution**: Check your App Store Connect API credentials

#### 3. Bundle ID Issues
**Error**: `Bundle identifier conflicts`
**Solution**: Ensure `com.qaonline.app` is registered in App Store Connect

### Debug Steps

1. **Check Secrets**: Verify all GitHub secrets are set correctly
2. **Review Logs**: Check the Actions tab for detailed error messages
3. **Test Locally**: Try building locally with Xcode first
4. **Verify Permissions**: Ensure your Apple Developer account has proper permissions

## 📱 App Configuration

### Current Settings
- **Bundle ID**: `com.qaonline.app`
- **App Name**: QA-Online
- **Team ID**: `BL7NANM4RM`
- **API Key ID**: `ZA7M4DJPV8`

### Customization
To change app settings, modify:
- `capacitor.config.js` - App configuration
- `ios/App/exportOptions.plist` - Build settings
- `.github/workflows/ios-app-store-deploy.yml` - Build process

## 🔄 Continuous Integration

### Test Builds
- Pull requests trigger test builds
- Validates build process without uploading
- Helps catch issues early

### Release Process
1. **Development**: Push to main for TestFlight builds
2. **Testing**: Use TestFlight for beta testing
3. **Release**: Create version tag for App Store release

## 📞 Support

### Getting Help
1. Check the GitHub Actions logs first
2. Verify all secrets are correctly configured
3. Ensure your Apple Developer account is active
4. Check that the bundle ID is registered

### Useful Links
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Capacitor Documentation](https://capacitorjs.com/docs)

---

## ✅ Quick Start Checklist

- [ ] Set up all GitHub secrets
- [ ] Verify Apple Developer account access
- [ ] Register bundle ID in App Store Connect
- [ ] Test build with manual trigger
- [ ] Create first version tag for release

**Your iOS app is now ready for automated builds and App Store distribution! 🎉**
