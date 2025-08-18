# 🔐 Framework Signing Fix for App Store Submission

## Problem Analysis

Your iOS app upload is failing with this error:
```
Missing or invalid signature. The bundle 'com.qaonline.app' at bundle path 'Payload/App.app/Frameworks/Capacitor.framework' is not signed using an Apple submission certificate.
```

This is a **critical issue** that prevents App Store acceptance. The Capacitor framework (and potentially other frameworks) inside your app bundle are not properly signed with your Apple Distribution certificate.

## Root Cause

1. **Embedded frameworks must be signed** with the same Apple Distribution certificate as the main app
2. **Framework signing order matters** - frameworks must be signed BEFORE the main app
3. **Proper entitlements** must be used for framework signing
4. **Signature verification** must pass for all components

## 🚀 Solution Options

### Option 1: Use CircleCI with Updated Configuration (Recommended)

The CircleCI configuration has been updated to properly sign all frameworks. Here's what it now does:

1. **Creates proper entitlements** for frameworks
2. **Signs frameworks first** with Apple Distribution certificate
3. **Verifies signatures** after signing
4. **Signs main app last** with full entitlements
5. **Embeds provisioning profile** correctly

**To trigger the fixed build:**

```bash
# Push to main branch to trigger the build
git add .
git commit -m "Fix framework signing for App Store submission"
git push origin main
```

### Option 2: Fix Locally (If you have macOS)

If you're on macOS, you can use the provided scripts to fix your current IPA:

```bash
# Fix the existing IPA
./quick-fix-ipa.sh

# Or use the comprehensive fix script
./fix-framework-signing.sh
```

### Option 3: Manual Fix Steps (Advanced)

If you need to understand the exact process:

1. **Extract the IPA:**
   ```bash
   unzip App.ipa
   ```

2. **Create framework entitlements:**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.developer.team-identifier</key>
       <string>BL7NANM4RM</string>
   </dict>
   </plist>
   ```

3. **Sign each framework:**
   ```bash
   # For each framework in Payload/App.app/Frameworks/
   codesign --remove-signature Payload/App.app/Frameworks/Capacitor.framework
   codesign --force --sign "Apple Distribution: Jonatan Koren (BL7NANM4RM)" \
            --entitlements framework_entitlements.plist \
            --verbose Payload/App.app/Frameworks/Capacitor.framework
   ```

4. **Sign the main app:**
   ```bash
   codesign --force --sign "Apple Distribution: Jonatan Koren (BL7NANM4RM)" \
            --entitlements main_app_entitlements.plist \
            --verbose Payload/App.app
   ```

5. **Repackage the IPA:**
   ```bash
   zip -r App-FIXED.ipa Payload/
   ```

## 🔍 Verification Steps

After fixing, verify the signatures:

```bash
# Verify framework signatures
codesign --verify --verbose Payload/App.app/Frameworks/Capacitor.framework
codesign --verify --verbose Payload/App.app/Frameworks/Cordova.framework

# Verify main app signature
codesign --verify --verbose Payload/App.app

# Check signing details
codesign -dv --verbose=4 Payload/App.app
```

## 📋 Updated CircleCI Changes

The CircleCI configuration now includes:

1. **Proper framework entitlements creation**
2. **Sequential framework signing** (frameworks first, then main app)
3. **Signature verification** after each signing step
4. **Better error handling** and logging
5. **Automatic certificate selection** (Apple Distribution preferred)

## 🎯 Next Steps

### Immediate Action:
1. **Trigger a new CircleCI build** by pushing to main branch
2. The updated pipeline will properly sign all frameworks
3. Monitor the build logs for successful framework signing
4. Upload the new IPA to App Store Connect

### Verification:
1. Check that the build logs show successful framework signing
2. Verify that the upload to App Store Connect succeeds
3. Confirm the app appears in TestFlight

## 🚨 Critical Points

- **Framework signing is mandatory** for App Store submission
- **Order matters**: Always sign frameworks before the main app
- **Use the same certificate** for all components (Apple Distribution)
- **Include proper entitlements** for each component
- **Verify signatures** before creating the final IPA

## 📞 Troubleshooting

### If the build still fails:

1. **Check certificate availability:**
   - Ensure Apple Distribution certificate is in the keychain
   - Verify the certificate is valid and not expired

2. **Verify provisioning profile:**
   - Ensure the provisioning profile matches the certificate
   - Check that the profile includes all required entitlements

3. **Framework-specific issues:**
   - Some frameworks may need special handling
   - Check for nested frameworks or bundles

### Common Error Messages:

- **"No suitable signing identity found"**: Missing or expired certificate
- **"Provisioning profile doesn't match"**: Certificate/profile mismatch
- **"Code signing failed"**: Incorrect entitlements or permissions

## 📈 Success Indicators

You'll know the fix worked when you see:

1. ✅ **Build logs show successful framework signing**
2. ✅ **No codesigning errors in CircleCI**
3. ✅ **App Store Connect upload succeeds**
4. ✅ **App appears in TestFlight within 30 minutes**
5. ✅ **No validation errors in App Store Connect**

---

**The framework signing issue has been addressed in the updated CircleCI configuration. Push your changes to trigger a new build with proper framework signing!** 🚀
