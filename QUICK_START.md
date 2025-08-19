# 🚀 Quick Start - Deploy Your QA App to App Store TODAY!

## ⚡ Immediate Action Plan

You can deploy your QA app to the App Store **today**! Here's what you need to do:

## 1. 🔐 Set Up CircleCI Context (5 minutes)

1. Go to [CircleCI Dashboard](https://app.circleci.com/)
2. Find your project: `qa-app-ios-github`
3. Go to **Settings** → **Contexts**
4. Create context: `apple-credentials`
5. Add these variables:
   ```
   APPLE_ID=jonatan.k@qaonline.co.il
   APP_SPECIFIC_PASSWORD=[generate at appleid.apple.com]
   APPLE_TEAM_ID=BL7NANM4RM
   ```

## 2. 🔑 Generate App-Specific Password (2 minutes)

1. Go to [Apple ID Settings](https://appleid.apple.com/)
2. Sign in with `jonatan.k@qaonline.co.il`
3. **Security** → **App-Specific Passwords**
4. Click **Generate Password**
5. Name: `CircleCI iOS Upload`
6. Copy the password to CircleCI context

## 3. 📱 Create App in App Store Connect (3 minutes)

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. **My Apps** → **+** → **New App**
3. Fill in:
   - **Platforms**: iOS
   - **Name**: QA-Online
   - **Bundle ID**: `com.qaonline.app`
   - **SKU**: `qa-online-ios`

## 4. 🚀 Deploy! (1 minute)

```bash
# Run the deployment script
./deploy-ios.sh

# Or manually push to trigger build
git push origin main
```

## ✅ What Happens Next

1. **CircleCI builds your app** (10-15 minutes)
2. **App uploads to TestFlight** automatically
3. **You submit for review** in App Store Connect
4. **Apple reviews** (1-3 days)
5. **App goes live** on App Store! 🎉

## 📋 Required Files Check

Your repository should have:
- ✅ `auto_distribution.cer` (or `distribution.cer`)
- ✅ `auto_distribution_private_key.pem` (or `distribution_private_key.pem`)
- ✅ `QAOnlineAppStoreProfile.mobileprovision`

**If missing**: Run `./deploy-ios.sh` - it will guide you through generating them.

## 🎯 Success Timeline

- **Today**: Set up CircleCI context and push to main
- **Today + 15 minutes**: App uploaded to TestFlight
- **Today + 1 hour**: Submit for App Store review
- **Today + 1-3 days**: App approved and live on App Store

## 🆘 Need Help?

1. **Check CircleCI logs** for build errors
2. **Verify context variables** are set correctly
3. **Run `./deploy-ios.sh`** for guided deployment
4. **Read `CIRCLECI_SETUP.md`** for detailed instructions

---

## 🎉 Ready to Deploy?

```bash
# Just run this and follow the prompts!
./deploy-ios.sh
```

**Your QA app will be on the App Store in 1-3 days!** 🚀 