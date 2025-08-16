# 🚀 GitLab CI/CD Setup for iOS App Store Deployment

This guide will help you set up the GitLab CI/CD pipeline for automated iOS builds and App Store deployment using GitLab's free macOS runners.

## 📋 Prerequisites

Before setting up the pipeline, ensure you have:

- ✅ GitLab account (free tier includes macOS runners)
- ✅ Apple Developer Account ($99/year)
- ✅ App Store Connect API Key
- ✅ Apple Team ID
- ✅ App registered in App Store Connect with bundle ID: `com.qaonline.app`

## 🔧 Step 1: Configure GitLab CI/CD Variables

Navigate to your GitLab project: **https://gitlab.com/QA-Online-AI/qa-app-ios**

1. **Go to Settings → CI/CD → Variables**
2. **Add the following variables** (all should be **Protected** and **Masked** when possible):

### Required Variables

| Variable Name | Value | Type | Description |
|---------------|-------|------|-------------|
| `APP_STORE_CONNECT_API_KEY` | Content of `AuthKey_ZA7M4DJPV8.p8` | Variable | Your App Store Connect API key (entire file content) |
| `APP_STORE_CONNECT_API_KEY_ID` | `ZA7M4DJPV8` | Variable | Your API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | `6751101564` | Variable | Your Issuer ID |
| `APPLE_TEAM_ID` | `BL7NANM4RM` | Variable | Your Apple Developer Team ID |

### 📝 How to Get These Values:

#### App Store Connect API Key (`APP_STORE_CONNECT_API_KEY`):
```bash
# Copy the entire content of your .p8 file
cat AuthKey_ZA7M4DJPV8.p8
```

#### API Key ID (`APP_STORE_CONNECT_API_KEY_ID`):
- Found in App Store Connect → Users and Access → Integrations
- The ID after "AuthKey_" in your filename (e.g., `ZA7M4DJPV8`)

#### Issuer ID (`APP_STORE_CONNECT_ISSUER_ID`):
- Found in App Store Connect → Users and Access → Integrations
- The UUID at the top of the page

#### Team ID (`APPLE_TEAM_ID`):
- Found in Apple Developer → Membership → Team ID
- Also in App Store Connect → Users and Access → Team ID

## 🚀 Step 2: Pipeline Stages

The GitLab CI pipeline includes 3 stages:

### 🧪 **Test Stage** (`ios_test_build`)
- **Triggers**: Every push to `main` branch and merge requests
- **Purpose**: Quick build verification without signing
- **Duration**: ~5-10 minutes
- **Runner**: GitLab's free macOS runners

### 🔨 **Build Stage** (`ios_app_store_signed`)
- **Triggers**: 
  - Release tags matching `release-*` (e.g., `release-v1.0.0`)
  - Manual trigger from GitLab UI
- **Purpose**: Full signed build for App Store
- **Duration**: ~15-30 minutes
- **Outputs**: Signed IPA, certificates
- **Runner**: GitLab's free macOS runners

### 🚀 **Deploy Stage** (`deploy_app_store`)
- **Triggers**: Manual approval after successful build
- **Purpose**: Final deployment confirmation
- **Duration**: ~1 minute

## 📱 Step 3: Triggering Builds

### For Testing (Test Stage):
```bash
# Push to main branch - triggers test build
git push gitlab main
```

### For App Store Release (Build + Deploy):
```bash
# Create and push a release tag
git tag release-v1.0.0
git push gitlab release-v1.0.0
```

### Manual Trigger:
1. Go to **CI/CD → Pipelines**
2. Click **Run pipeline**
3. Select branch/tag
4. Click **Run pipeline**

## 📊 Step 4: Monitoring Builds

### GitLab Pipeline Status:
- **URL**: https://gitlab.com/QA-Online-AI/qa-app-ios/-/pipelines
- **Real-time logs**: Click on any pipeline → Click job name
- **Artifacts**: Download built IPA files from successful builds

### App Store Connect:
- **URL**: https://appstoreconnect.apple.com
- **TestFlight**: Available 30 minutes after successful upload
- **Build Status**: Check "App Store Connect → TestFlight → Builds"

## 🔧 Pipeline Features

### ✅ **Robust Error Handling**
- Continues build even if certificate generation fails
- Automatic signing fallback
- Comprehensive debugging output

### ✅ **Automatic Certificate Management**
- Uses App Store Connect API for certificate generation
- Handles provisioning profiles automatically
- No manual certificate management required

### ✅ **Optimized for GitLab**
- Uses GitLab's free macOS runners
- Proper artifact storage (90 days)
- Environment-specific deployments

### ✅ **Security**
- All secrets stored in GitLab CI/CD variables
- No hardcoded credentials in code
- Protected and masked variables

## 🛠️ Troubleshooting

### Common Issues:

#### 1. **"API key authentication failed"**
- **Solution**: Verify `APP_STORE_CONNECT_API_KEY` contains the entire .p8 file content
- **Check**: API key has proper permissions in App Store Connect

#### 2. **"No Team ID found"**
- **Solution**: Verify `APPLE_TEAM_ID` matches your Apple Developer Team ID
- **Check**: Team ID is exactly 10 characters (e.g., `BL7NANM4RM`)

#### 3. **"Bundle ID not found"**
- **Solution**: Ensure `com.qaonline.app` is registered in App Store Connect
- **Check**: App Store Connect → Apps → Your app → App Information

#### 4. **"Pods signing errors"**
- **Solution**: The pipeline automatically handles this with mixed signing
- **Info**: Main app uses automatic signing, Pods use automatic signing

### Debug Steps:

1. **Check Pipeline Logs**:
   - Go to GitLab → CI/CD → Pipelines
   - Click on failed pipeline
   - Review job logs for specific errors

2. **Verify Variables**:
   - Settings → CI/CD → Variables
   - Ensure all 4 required variables are set
   - Check for extra spaces or newlines

3. **Test API Key Locally**:
   ```bash
   openssl ec -in AuthKey_ZA7M4DJPV8.p8 -text -noout
   # Should show key details without errors
   ```

## 🎯 Expected Build Times

| Stage | Duration | Purpose |
|-------|----------|---------|
| Test Build | 5-10 min | Verify code compiles |
| Signed Build | 15-30 min | Full App Store build |
| Upload to ASC | 2-5 min | TestFlight upload |
| **Total** | **20-45 min** | **Complete pipeline** |

## 📞 Support

### GitLab-specific Issues:
- **GitLab Docs**: https://docs.gitlab.com/ee/ci/
- **Runner Issues**: Check GitLab's macOS runner status
- **Pipeline Quota**: Free tier includes 400 CI/CD minutes/month

### iOS Build Issues:
- **Apple Developer Forums**: https://developer.apple.com/forums/
- **Fastlane Docs**: https://docs.fastlane.tools/
- **App Store Connect**: https://developer.apple.com/support/app-store-connect/

---

## 🎉 You're Ready!

Once the variables are configured, your GitLab pipeline will:

1. ✅ **Automatically test** every push to main
2. ✅ **Build signed IPAs** for release tags  
3. ✅ **Upload to TestFlight** automatically
4. ✅ **Store artifacts** for 90 days
5. ✅ **Provide detailed logs** for debugging

**Your iOS app is now ready for automated GitLab CI/CD deployment! 🚀**

### Next Steps:
1. Configure the CI/CD variables above
2. Push a test commit to main branch
3. Create your first release tag
4. Monitor the pipeline in GitLab
5. Check TestFlight for your build!
# GitLab CI/CD Test - Sat Aug 16 09:51:12 AM IDT 2025
