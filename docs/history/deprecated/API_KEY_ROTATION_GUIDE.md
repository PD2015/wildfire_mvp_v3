# 🔑 API Key Rotation Guide

## ⚠️ URGENT: Exposed Keys Need Rotation

The following API keys were exposed in git history and documentation:
- `AIzaSyAfqZyjB20CypVDYQMd41VsefEwhdv5cys` (Android/iOS)
- `AIzaSyAN8Aaiz1W59VnQYcJCYQyGDGFw2CzIkrE` (Web)

**Status**: ✅ Removed from current documentation (replaced with placeholders)  
**Action Required**: 🔴 **Keys must be rotated** - they are still in git history

---

## 🚀 Quick Rotation Steps

### 1. Create New API Keys in Google Cloud Console

1. Go to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)
2. Select your project
3. Click **+ CREATE CREDENTIALS** → **API key**
4. **Create 3 separate keys**:
   - One for Android
   - One for iOS  
   - One for Web

### 2. Restrict the New Keys (IMPORTANT)

#### Android Key Restrictions:
```
Application restrictions:
  ✓ Android apps
  
  Package name: com.example.wildfire_mvp_v3
  SHA-1 fingerprint: [Get from: keytool -list -v -keystore ~/.android/debug.keystore]

API restrictions:
  ✓ Restrict key
  ✓ Maps SDK for Android
```

#### iOS Key Restrictions:
```
Application restrictions:
  ✓ iOS apps
  
  Bundle ID: com.example.wildfire_mvp_v3

API restrictions:
  ✓ Restrict key
  ✓ Maps SDK for iOS
```

#### Web Key Restrictions:
```
Application restrictions:
  ✓ HTTP referrers (web sites)
  
  Website restrictions:
  - https://wildfire-mvp-v3.web.app/*
  - https://wildfire-mvp-v3.firebaseapp.com/*
  - http://localhost:*/*  (for development)

API restrictions:
  ✓ Restrict key
  ✓ Maps JavaScript API
```

### 3. Update Your Local Development Environment

```bash
# Update env/dev.env.json with new keys
cat > env/dev.env.json << 'EOF'
{
  "MAP_LIVE_DATA": "false",
  "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.com/",
  "GOOGLE_MAPS_API_KEY_ANDROID": "YOUR_NEW_ANDROID_KEY_HERE",
  "GOOGLE_MAPS_API_KEY_IOS": "YOUR_NEW_IOS_KEY_HERE",
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_NEW_WEB_KEY_HERE"
}
EOF

# Verify file is git-ignored
git check-ignore env/dev.env.json
# Should output: env/dev.env.json
```

### 4. Update GitHub Secrets (for CI/CD)

1. Go to [GitHub Repository Settings → Secrets and variables → Actions](https://github.com/PD2015/wildfire_mvp_v3/settings/secrets/actions)
2. Update these secrets:
   - `GOOGLE_MAPS_API_KEY_ANDROID` → New Android key
   - `GOOGLE_MAPS_API_KEY_IOS` → New iOS key  
   - `GOOGLE_MAPS_API_KEY_WEB_PREVIEW` → New Web key (for PR previews)
   - `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION` → New Web key (for production)

### 5. Delete/Disable the Old Exposed Keys

⚠️ **DO THIS LAST** - after confirming new keys work

1. Go back to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)
2. Find the old keys:
   - `AIzaSyAfqZyjB20CypVDYQMd41VsefEwhdv5cys`
   - `AIzaSyAN8Aaiz1W59VnQYcJCYQyGDGFw2CzIkrE`
3. Click **DELETE** or **DISABLE** for each

---

## 🧪 Testing New Keys

### Local Development Test:
```bash
# Test on web (should show map without watermark)
./scripts/run_web.sh

# Test on Android
flutter run -d android --dart-define-from-file=env/dev.env.json

# Test on iOS
flutter run -d ios --dart-define-from-file=env/dev.env.json
```

### CI/CD Test:
```bash
# Push a test commit to trigger CI/CD
git commit --allow-empty -m "test: verify new API keys in CI/CD"
git push

# Check GitHub Actions
gh run list --limit 1
```

---

## 📊 Verification Checklist

- [ ] New keys created in Google Cloud Console
- [ ] All 3 keys have proper restrictions (Android, iOS, Web)
- [ ] `env/dev.env.json` updated locally
- [ ] GitHub Secrets updated
- [ ] Local development tested (map loads without watermark)
- [ ] CI/CD pipeline tested (GitHub Actions green)
- [ ] Old exposed keys deleted from Google Cloud Console
- [ ] Billing alerts configured (50% and 80% of free tier)

---

## 🔒 Security Best Practices Going Forward

### ✅ DO:
- Store keys in `env/dev.env.json` (git-ignored)
- Use GitHub Secrets for CI/CD
- Restrict keys by package/bundle ID
- Rotate keys every 90 days
- Monitor usage in Google Cloud Console

### ❌ DON'T:
- Commit keys to git (pre-commit hook will block)
- Share keys in Slack/email
- Use unrestricted keys in production
- Document real keys (use `YOUR_API_KEY_HERE` placeholders)

---

## 🆘 Troubleshooting

### Map shows "For development purposes only" watermark
**Cause**: Web key not injected or invalid  
**Fix**: 
```bash
# Check if key is in index.html
grep "script.*maps.*js" build/web/index.html

# Rebuild with key injection
./scripts/build_web.sh
```

### "API key not valid" error on Android
**Cause**: SHA-1 fingerprint doesn't match or key not restricted properly  
**Fix**:
```bash
# Get correct SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey

# Update Google Cloud Console restrictions
```

### CI/CD deployment fails with API key error
**Cause**: GitHub Secrets not updated  
**Fix**: Update all 4 secrets in GitHub repository settings

---

## 📚 Related Documentation

- [API Key Setup Guide](./API_KEY_SETUP.md)
- [Security Incident Response](./SECURITY_INCIDENT_RESPONSE_2025-10-29.md)
- [Multi-Layer Security Controls](./MULTI_LAYER_SECURITY_CONTROLS.md)
- [Firebase Deployment](./FIREBASE_DEPLOYMENT.md)

---

**Last Updated**: 2025-10-29  
**Status**: 🔴 ROTATION REQUIRED  
**Priority**: HIGH - Keys are in git history
