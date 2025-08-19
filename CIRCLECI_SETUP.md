# CircleCI iOS App Store Deployment Setup

## 🚀 Quick Start - Deploy Your QA App to App Store Today!

This guide will help you set up automated iOS builds and deployments to the App Store using CircleCI.

## 📋 Prerequisites

1. **Apple Developer Account** with App Store Connect access
2. **GitHub Repository** connected to CircleCI
3. **App Store Connect API Key** (recommended) or App-specific password

## 🔧 Step 1: Set Up CircleCI Context

### Create Apple Credentials Context

1. Go to [CircleCI Dashboard](https://app.circleci.com/)
2. Navigate to your project
3. Go to **Settings** → **Contexts**
4. Click **Create Context**
5. Name it: `apple-credentials`
6. Add the following environment variables:

```
APPLE_ID=your-apple-id@example.com
APP_SPECIFIC_PASSWORD=your-app-specific-password
APPLE_TEAM_ID=BL7NANM4RM
```

### Get App-Specific Password

1. Go to [Apple ID Settings](https://appleid.apple.com/)
2. Sign in with your Apple ID
3. Go to **Security** → **App-Specific Passwords**
4. Click **Generate Password**
5. Name it: `CircleCI iOS Upload`
6. Copy the generated password

## 🔐 Step 2: Set Up Certificates and Profiles

### Option A: Use Existing Certificates (Recommended)

If you already have the required files in your repository:
- `auto_distribution.cer` (or `distribution.cer`)
- `auto_distribution_private_key.pem` (or `distribution_private_key.pem`)
- `QAOnlineAppStoreProfile.mobileprovision`

**Skip to Step 3** - your pipeline will work immediately!

### Option B: Generate New Certificates

If you need to generate new certificates:

1. **Create a new branch** called `csr-generation`
2. **Push the branch** to trigger the CSR generation pipeline
3. **Wait for the pipeline** to complete
4. **Download the artifacts**:
   - `auto_distribution.csr`
   - `auto_distribution_private_key.pem`

5. **Create Apple Distribution Certificate**:
   - Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
   - Click **+** to create new certificate
   - Select **Apple Distribution**
   - Upload the `auto_distribution.csr` file
   - Download the generated `.cer` file

6. **Add files to repository**:
   ```bash
   # Rename the downloaded certificate
   mv ~/Downloads/Apple\ Distribution\ *.cer auto_distribution.cer
   
   # Add both files to your repository
   git add auto_distribution.cer auto_distribution_private_key.pem
   git commit -m "Add Apple Distribution certificate and private key"
   git push origin main
   ```

## 📱 Step 3: Create App Store Connect App

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** → **+** → **New App**
3. Fill in the details:
   - **Platforms**: iOS
   - **Name**: QA-Online
   - **Bundle ID**: `com.qaonline.app`
   - **SKU**: `qa-online-ios`
   - **User Access**: Full Access

## 🚀 Step 4: Deploy to App Store

### Automatic Deployment

1. **Push to main branch** to trigger the build:
   ```bash
   git push origin main
   ```

2. **Monitor the pipeline** in CircleCI:
   - Go to your project in CircleCI
   - Watch the `build_and_upload_ios` job
   - The pipeline will:
     - Set up Xcode environment
     - Install dependencies
     - Build the iOS app
     - Upload to App Store Connect

3. **Check App Store Connect**:
   - Go to your app in App Store Connect
   - Check **TestFlight** tab for the uploaded build
   - The build will be processed automatically

### Manual Upload (Fallback)

If the automatic upload fails, you can manually upload:

1. **Download the IPA** from CircleCI artifacts
2. **Go to App Store Connect** → Your App → **TestFlight**
3. **Click +** → **Upload Build**
4. **Drag and drop** the downloaded IPA file

## 📋 Step 5: Submit for Review

1. **In App Store Connect**:
   - Go to **App Store** tab
   - Fill in app information:
     - **App Name**: QA-Online
     - **Subtitle**: AI-Powered QA Platform
     - **Description**: Your app description
     - **Keywords**: qa, testing, ai, automation
     - **Support URL**: https://qaonline.co.il
     - **Marketing URL**: https://qaonline.co.il

2. **Add App Screenshots**:
   - iPhone 6.7" Display: 1290 x 2796
   - iPhone 6.5" Display: 1242 x 2688
   - iPad Pro 12.9" Display: 2048 x 2732

3. **Set App Review Information**:
   - **Contact Information**: Your contact details
   - **Demo Account**: Test account credentials
   - **Notes**: Any special instructions for reviewers

4. **Submit for Review**:
   - Click **Submit for Review**
   - Apple will review your app (typically 1-3 days)

## 🔧 Troubleshooting

### Common Issues

1. **Certificate Issues**:
   ```
   Error: No valid signing identity found
   ```
   **Solution**: Ensure `auto_distribution.cer` and `auto_distribution_private_key.pem` are in your repository

2. **Provisioning Profile Issues**:
   ```
   Error: No provisioning profile found
   ```
   **Solution**: Ensure `QAOnlineAppStoreProfile.mobileprovision` is in your repository

3. **Upload Authentication Issues**:
   ```
   Error: Authentication failed
   ```
   **Solution**: Check your `APPLE_ID` and `APP_SPECIFIC_PASSWORD` in CircleCI context

4. **Build Failures**:
   ```
   Error: Xcode build failed
   ```
   **Solution**: Check the build logs in CircleCI for specific error messages

### Debug Commands

If you need to debug locally:

```bash
# Check if certificates are valid
security find-identity -v -p codesigning

# Verify provisioning profile
security cms -D -i QAOnlineAppStoreProfile.mobileprovision

# Test altool upload
xcrun altool --upload-app --type ios --file App.ipa --username "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD"
```

## 📊 Monitoring

### CircleCI Dashboard
- Monitor build status and logs
- Download artifacts (IPA files)
- Check build times and success rates

### App Store Connect
- Track build processing status
- Monitor TestFlight distribution
- Check app review status

## 🎯 Success Checklist

- [ ] CircleCI context configured with Apple credentials
- [ ] Certificates and provisioning profiles in repository
- [ ] App created in App Store Connect
- [ ] Pipeline builds successfully
- [ ] App uploaded to TestFlight
- [ ] App submitted for review
- [ ] App approved and published

## 🚀 Next Steps

After successful deployment:

1. **Set up TestFlight distribution** for beta testing
2. **Configure app analytics** (Firebase, etc.)
3. **Set up automated versioning** for future releases
4. **Configure branch protection** for main branch
5. **Set up notifications** for build status

## 📞 Support

If you encounter issues:

1. Check the CircleCI build logs for detailed error messages
2. Verify all environment variables are set correctly
3. Ensure certificates and profiles are valid and not expired
4. Contact Apple Developer Support for App Store Connect issues

---

**🎉 Congratulations! Your QA app is now ready for the App Store!**
