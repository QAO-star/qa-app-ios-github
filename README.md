# QA-Online iOS App

A Capacitor-based iOS app that wraps the QA-Online web application for native iOS distribution with automated App Store builds.

**🚀 Ready for automated deployment!**

## 🍎 Features

- **Native iOS App**: Wraps QA-Online web application in a native iOS container
- **Automated Builds**: GitHub Actions automatically builds and uploads to App Store Connect
- **App Store Ready**: Configured for TestFlight and App Store distribution
- **Modern UI**: Optimized for iOS with proper system integration

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Xcode (for local development)
- Apple Developer Account
- App Store Connect API Key

### Local Development

1. **Clone the repository:**
```bash
git clone https://github.com/QAI-O/qa-app-ios.git
cd qa-app-ios
```

2. **Install dependencies:**
```bash
npm install
```

3. **Add iOS platform:**
```bash
npm install @capacitor/ios
npx cap add ios
```

4. **Sync Capacitor:**
```bash
npx cap sync
```

5. **Open in Xcode:**
```bash
npx cap open ios
```

## 🔄 Automated Builds

This repository uses GitHub Actions to automatically build and upload iOS apps to App Store Connect.

### GitHub Secrets Required

Set up these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `APP_STORE_CONNECT_API_KEY` | Content of `AuthKey_ZA7M4DJPV8.p8` | Your App Store Connect API key |
| `APP_STORE_CONNECT_API_KEY_ID` | `ZA7M4DJPV8` | Your API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | `6751101564` | Your Issuer ID |
| `APPLE_TEAM_ID` | `BL7NANM4RM` | Your Apple Developer Team ID |

### Triggering Builds

#### Option 1: Tag-based releases (Recommended)
```bash
git tag v1.0.0
git push origin v1.0.0
```

#### Option 2: Manual trigger
- Go to your GitHub repository
- Click **Actions** tab
- Select the workflow
- Click **Run workflow**

## 📱 App Configuration

- **Bundle ID**: `com.qaonline.app`
- **App Name**: QA-Online
- **SKU**: `qaonline-app-2025`
- **Production URL**: `https://aiagent.qaonline.co.il/new/`
- **Team ID**: `BL7NANM4RM`
- **API Key ID**: `ZA7M4DJPV8`

## 🔄 Build Process

The GitHub Actions workflow:

1. **Setup**: Node.js and Xcode environment
2. **Install**: Dependencies and iOS platform
3. **Sync**: Capacitor configuration
4. **Build**: iOS app with Xcode
5. **Upload**: To App Store Connect
6. **Artifact**: Store IPA for download

## 📊 Monitoring

- **Actions**: https://github.com/QAI-O/qa-app-ios/actions
- **App Store Connect**: https://appstoreconnect.apple.com
- **TestFlight**: Available after first successful upload

## 🛠️ Development

### Project Structure

```
qa-app-ios/
├── .github/workflows/     # GitHub Actions workflows
├── ios/                   # iOS platform files
├── public/                # Web assets
├── capacitor.config.js    # Capacitor configuration
├── package.json          # Dependencies and scripts
└── README.md             # This file
```

### Available Scripts

- `npm run build` - Build web assets
- `npm run cap:sync` - Sync Capacitor
- `npm run cap:build:ios` - Build iOS app

## 🔧 Troubleshooting

### Common Issues

1. **Build fails**: Check that all GitHub secrets are properly configured
2. **Signing issues**: Verify your Apple Developer Team ID is correct
3. **Upload fails**: Ensure your App Store Connect API key has proper permissions

### Check Build Status

- Go to: https://github.com/QAI-O/qa-app-ios/actions
- Click on the latest workflow run
- Check the logs for any errors

## 📞 Support

For issues with the build process:

1. Check the GitHub Actions logs
2. Verify all secrets are correctly set
3. Ensure your Apple Developer account has proper permissions
4. Check that the bundle ID `com.qaonline.app` is registered in App Store Connect

## 📄 License

ISC

---

**Your iOS app is ready for automated builds and App Store distribution! 🚀**
