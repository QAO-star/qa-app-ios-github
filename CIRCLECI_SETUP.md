# CircleCI Setup Guide for iOS App Store Builds

## 🎉 CircleCI Connected Successfully!

Your CircleCI organization is now connected to your GitHub repository:
- **Organization**: QA-Online
- **Organization ID**: `dae814e8-2691-43de-a1dd-138b2c2bc831`
- **Organization Slug**: `circleci/U2q2E7E9Sn4oNAWicKc2uE`

## 🔐 Required Environment Variables

You need to add these environment variables in CircleCI:

### 1. Go to CircleCI Project Settings
1. Visit: https://app.circleci.com/pipelines/github/[your-github-username]/qa-app-ios
2. Click on **Project Settings** (gear icon)
3. Go to **Environment Variables** in the left sidebar

### 2. Add These Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `APP_STORE_CONNECT_API_KEY` | Your `.p8` file content | The entire content of your App Store Connect API key file (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`) |
| `APP_STORE_CONNECT_API_KEY_ID` | Your API key ID | The key ID from App Store Connect (e.g., `ZA7M4DJPV8`) |
| `APP_STORE_CONNECT_ISSUER_ID` | Your issuer ID | The issuer ID from App Store Connect (e.g., `57246542-96fe-1a63-e053-0824d011072a`) |
| `APPLE_TEAM_ID` | Your team ID | Your Apple Developer Team ID (e.g., `BL7NANM4RM`) |

### 3. Important Notes
- **Do NOT check "Sensitive"** for `APP_STORE_CONNECT_API_KEY` - it contains newlines
- **Check "Sensitive"** for the other variables
- Make sure to copy the **entire** `.p8` file content for `APP_STORE_CONNECT_API_KEY`

## 🚀 Pipeline Overview

The CircleCI pipeline includes 3 jobs:

### 1. `test_build` (Node.js)
- Runs on every push to `main`
- Tests web build functionality
- Uses Docker executor (fast)

### 2. `ios_test_build` (macOS)
- Runs on every push to `main`
- Tests iOS build without signing
- Uses macOS executor with Xcode 15.2

### 3. `ios_app_store_build` (macOS)
- Runs only on tags starting with `release-`
- Creates signed IPA for App Store
- Uploads to App Store Connect via Fastlane

## 🏷️ Triggering Builds

### Test Builds
```bash
# Push to main branch (triggers test builds)
git push origin main
```

### Release Builds
```bash
# Create and push a release tag
git tag release-v1.0.0
git push origin release-v1.0.0
```

## 📱 What Happens in Each Build

### Test Workflow
1. **Web Build**: Tests the web version builds correctly
2. **iOS Test Build**: Tests iOS compilation without signing

### Release Workflow
1. **Setup**: Node.js, Capacitor, Xcode, CocoaPods
2. **Signing**: Configures automatic signing for all targets
3. **Fastlane**: Tests API key authentication
4. **Certificates**: Generates certificates and provisioning profiles
5. **Build**: Creates signed IPA with proper versioning
6. **Upload**: Uploads to App Store Connect via TestFlight

## 🔧 Troubleshooting

### Common Issues
1. **API Key Authentication Failed**: Check your App Store Connect API key values
2. **Build Fails**: Check Xcode version compatibility
3. **Signing Issues**: Verify your Apple Team ID

### Viewing Logs
- Go to your CircleCI project dashboard
- Click on any job to see detailed logs
- Failed jobs show exactly where the issue occurred

## 💰 Cost Information
- **Free Tier**: 6,000 minutes/month
- **iOS builds**: ~15-20 minutes each
- **Estimated builds/month**: ~300-400 builds

## 🎯 Next Steps
1. Add the environment variables above
2. Push a test commit to trigger the first build
3. Monitor the build logs for any issues
4. Create a release tag to test the full App Store build

## 📞 Support
If you encounter issues:
1. Check the CircleCI logs for detailed error messages
2. Verify all environment variables are set correctly
3. Ensure your App Store Connect API key has the right permissions

---

**Ready to test?** Push a commit to `main` to trigger your first CircleCI build! 🚀
