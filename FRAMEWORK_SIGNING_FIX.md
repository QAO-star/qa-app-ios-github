# iOS Framework Signing Fix Guide

## The Problem

You're encountering this error when uploading to App Store Connect:

```
Missing or invalid signature. The bundle 'com.qaonline.app' at bundle path 'Payload/App.app/Frameworks/Capacitor.framework' is not signed using an Apple submission certificate.
```

This happens because the Capacitor framework (and potentially other frameworks) inside your IPA are not properly signed with your Apple distribution certificate.

## Why This Happens

1. **Cross-platform build**: When building iOS apps on non-macOS systems (like Linux/Ubuntu), the frameworks are not automatically signed with your distribution certificate
2. **Framework dependencies**: Capacitor and Cordova frameworks need to be individually signed before the main app bundle
3. **App Store requirements**: Apple requires all frameworks to be signed with the same certificate as the main app

## Solutions

### Option 1: Use the Automated Fix Script (Recommended)

Run the comprehensive framework signing fix script:

```bash
# Make sure you have your IPA and provisioning profile ready
./fix-framework-signing.sh
```

This script will:
- ✅ Extract your IPA if needed
- ✅ Sign all frameworks individually with your distribution certificate
- ✅ Install the provisioning profile in the app bundle
- ✅ Sign the main app bundle
- ✅ Verify all signatures
- ✅ Create a properly signed IPA ready for App Store Connect

### Option 2: Use Updated Signing Scripts

#### For macOS users:
```bash
./sign-ipa-locally.sh
```

#### For Linux/Ubuntu users (creates unsigned IPA for manual signing):
```bash
./sign-ipa-ubuntu.sh
```

### Option 3: Manual Framework Signing

If you prefer to do it manually:

```bash
# 1. Extract the IPA
unzip App.ipa

# 2. Install provisioning profile in app bundle
cp QAOnlineAppStoreProfile.mobileprovision Payload/App.app/embedded.mobileprovision

# 3. Sign each framework individually
codesign --force --sign "iPhone Distribution" Payload/App.app/Frameworks/Capacitor.framework
codesign --force --sign "iPhone Distribution" Payload/App.app/Frameworks/Cordova.framework

# 4. Sign the main app bundle
codesign --force --sign "iPhone Distribution" Payload/App.app

# 5. Verify signatures
codesign --verify --verbose=4 Payload/App.app/Frameworks/Capacitor.framework
codesign --verify --verbose=4 Payload/App.app/Frameworks/Cordova.framework
codesign --verify --verbose=4 Payload/App.app

# 6. Create signed IPA
zip -r App-signed.ipa Payload/

# 7. Clean up
rm -rf Payload
```

## Prerequisites

### Required Files
- `App.ipa` - Your unsigned IPA file
- `QAOnlineAppStoreProfile.mobileprovision` - Your App Store provisioning profile
- Distribution certificate installed in macOS Keychain

### Required Tools (macOS only)
- Xcode Command Line Tools (`xcode-select --install`)
- Valid Apple Developer account
- Distribution certificate in Keychain Access

## Verification Steps

After signing, verify your IPA is ready:

```bash
# Check if IPA is properly structured
unzip -t App-signed.ipa

# Verify main app signature (macOS only)
codesign --verify --verbose=4 App-signed.ipa

# Check file size (should be similar to original)
ls -la App-signed.ipa
```

## Upload to App Store Connect

Once you have a properly signed IPA:

### Option 1: Xcode (Recommended)
1. Open Xcode
2. Window → Organizer
3. Distribute App → Upload to App Store Connect

### Option 2: Command Line
```bash
xcrun altool --upload-app \
  --file App-signed.ipa \
  --type ios \
  --username your@email.com \
  --password your-app-specific-password
```

### Option 3: Transporter App
1. Download Transporter from Mac App Store
2. Drag and drop your signed IPA
3. Click "Deliver"

## Troubleshooting

### "codesign command not found"
- You're on a non-macOS system
- Use the Ubuntu script to create an unsigned IPA
- Transfer to macOS for signing

### "No signing identity found"
- Install your distribution certificate in Keychain Access
- Check: `security find-identity -v -p codesigning`

### "Provisioning profile not found"
- Ensure `QAOnlineAppStoreProfile.mobileprovision` is in the project root
- Check it matches your bundle ID and certificate

### "Framework signature verification failed"
- Make sure you're using the correct certificate name
- Try: `security find-identity -v -p codesigning` to see available certificates
- Use the exact certificate name (e.g., "iPhone Distribution: Your Name (TEAMID)")

## Framework Signing Order

**Important**: Always sign in this order:
1. Individual frameworks first
2. Main app bundle last

This is because signing the main app bundle creates a signature that encompasses all its contents, including frameworks.

## Alternative: CI/CD with macOS Runners

For automated builds, consider using:
- **GitHub Actions** with macOS runners
- **CircleCI** with macOS executors  
- **Bitrise** (iOS-focused CI/CD)
- **Codemagic** (Flutter/Capacitor friendly)

Example GitHub Actions workflow:
```yaml
name: iOS Build and Sign
on: [push]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup certificates
        run: |
          # Install certificates and provisioning profiles
          # Build and sign IPA
          # Upload to App Store Connect
```

## Success Indicators

✅ **You'll know it worked when:**
- No framework signing errors during upload
- App Store Connect accepts your IPA
- Processing completes successfully
- App appears in TestFlight

❌ **Still having issues?**
- Double-check certificate installation
- Verify provisioning profile matches bundle ID
- Ensure all frameworks are signed with same certificate
- Try uploading with Xcode Organizer for better error messages

## Support

If you continue having issues:
1. Check the detailed logs in the signing scripts
2. Verify your Apple Developer account status
3. Ensure your provisioning profile is not expired
4. Contact Apple Developer Support for certificate issues

---

**Remember**: iOS app signing must be done on macOS with proper certificates. The scripts help automate the process, but the fundamental requirement remains the same.
