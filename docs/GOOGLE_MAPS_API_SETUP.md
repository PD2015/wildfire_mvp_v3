# Google Maps API Setup Guide

## Overview

This comprehensive guide covers setting up Google Maps API keys for iOS, Android, and Web platforms in the WildFire MVP v3 application. The app uses environment-based API key management for security and supports live EFFIS fire data integration.

⚠️ **IMPORTANT**: Never commit API keys to git. This repository uses environment files to manage secrets securely.

---

## 🚀 Quick Start (Development)

### 1. Copy Environment Template
```bash
cp env/dev.env.json.template env/dev.env.json
```

### 2. Add Your API Keys to `env/dev.env.json`
```json
{
  "MAP_LIVE_DATA": "false",
  "GOOGLE_MAPS_API_KEY_ANDROID": "your_android_key_here",
  "GOOGLE_MAPS_API_KEY_IOS": "your_ios_key_here",
  "GOOGLE_MAPS_API_KEY_WEB": "your_web_key_here",
  "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/"
}
```

### 3. Run with Environment File
```bash
# Android with mock data (safest for testing)
flutter run -d android --dart-define-from-file=env/dev.env.json

# iOS with API key injection (uses automatic Xcode Build Phase)
flutter run -d ios --dart-define-from-file=env/dev.env.json

# Web with secure API key injection
./scripts/run_web.sh

# With live EFFIS fire data (requires proper EFFIS configuration)
flutter run -d <device> --dart-define-from-file=env/dev.env.json --dart-define=MAP_LIVE_DATA=true
```

**📱 iOS Note**: For iOS Google Maps integration, see **[iOS Google Maps Integration Guide](IOS_GOOGLE_MAPS_INTEGRATION.md)** for complete crash-free setup with automatic API key injection.

---

## 🔧 Creating Google Maps API Keys

### Prerequisites
- Google Cloud Platform account
- Project with billing enabled (free tier: $200/month)
- Required APIs enabled:
  - Maps SDK for Android
  - Maps SDK for iOS  
  - Maps JavaScript API (for web platform)

### Step 1: Enable Required APIs
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Navigate to **APIs & Services > Library**
4. Enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Maps JavaScript API** (for web support)

### Step 2: Create API Keys
1. Navigate to **APIs & Services > Credentials**
2. Click **Create Credentials > API Key**
3. Create **separate keys** for Android, iOS, and Web (recommended for security)

### Step 3: Restrict API Keys (CRITICAL for Security)

#### Android Key Restrictions
1. Click on your Android API key
2. Under **Application restrictions**, select **Android apps**
3. Click **Add an item**
4. Add package name: `com.example.wildfire_mvp_v3`
5. Get SHA-1 fingerprint:
   ```bash
   # Debug certificate (development)
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   
   # Release certificate (production)
   keytool -list -v -keystore /path/to/your/keystore.jks \
     -alias your_alias
   ```
6. Add SHA-1 fingerprint to key restrictions
7. Under **API restrictions**, select **Maps SDK for Android**
8. Save changes

#### iOS Key Restrictions
1. Click on your iOS API key
2. Under **Application restrictions**, select **iOS apps**
3. Click **Add an item**
4. Add bundle ID: `com.example.wildfire_mvp_v3` (check `ios/Runner/Info.plist`)
5. Under **API restrictions**, select **Maps SDK for iOS**
6. Save changes

#### Web Key Restrictions
1. Click on your Web API key
2. Under **Application restrictions**, select **HTTP referrers (web sites)**
3. Add authorized domains:
   - Development: `http://localhost:*`
   - Production: `https://yourdomain.com/*`
4. Under **API restrictions**, select **Maps JavaScript API**
5. Save changes

**⚠️ Web Security Note**: Web keys are visible in browser source code. Use HTTP referrer restrictions and consider implementing a backend proxy for production (see `WEB_API_KEY_SECURITY.md`).

---

## 📂 Environment File Structure

```
env/
├── .gitignore              # Excludes *.env.json from git
├── ci.env.json             # CI/CD config (no secrets, uses placeholders)
├── dev.env.json.template   # Template with placeholders for sharing
└── dev.env.json            # ← Your actual keys (git-ignored)
```

### Example `env/dev.env.json`
```json
{
  "MAP_LIVE_DATA": "false",
  "GOOGLE_MAPS_API_KEY_ANDROID": "YOUR_ANDROID_API_KEY_HERE",
  "GOOGLE_MAPS_API_KEY_IOS": "YOUR_IOS_API_KEY_HERE", 
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_WEB_API_KEY_HERE",
  "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/"
}
```

**Security Features**:
- ✅ `env/*.env.json` is gitignored (never committed)
- ✅ Separate keys for each platform
- ✅ Template file for sharing structure without secrets
- ✅ CI configuration uses placeholder keys with mock data

---

## 🌐 Platform-Specific Configuration

### Android Configuration

**Current Setup**: Environment variables via `AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY_ANDROID}" />
```

**Development**:
```bash
flutter run -d android --dart-define-from-file=env/dev.env.json
```

**Production**:
```bash
flutter build apk --dart-define-from-file=env/prod.env.json
```

### iOS Configuration  

**Current Setup**: Automatic API key injection via Xcode Build Phase
- ✅ **Crash-Free**: Resolves `[GMSServices checkServicePreconditions]` crashes
- ✅ **Automatic**: Works with all standard Flutter commands
- ✅ **Secure**: API keys injected at build time, not hardcoded

**Development**:
```bash
# Standard Flutter command (API key injection happens automatically)
flutter run -d ios --dart-define-from-file=env/dev.env.json
```

**Setup Requirements**:
1. Xcode Build Phase: "Process DART_DEFINES (API Keys)" 
2. Build phase script: `ios/xcode_build_phase_script.sh`
3. Core injection logic: `ios/ios_prebuild.sh`

📖 **Complete Setup Guide**: See `IOS_GOOGLE_MAPS_INTEGRATION.md` for full instructions.

### Web Configuration

**Why Use Build Scripts Instead of `flutter run`?**

Flutter web has a [known architectural limitation](https://github.com/flutter/flutter/issues/73830): `--dart-define` only works for Dart code, **not HTML files**. The Google Maps JavaScript API loads in `web/index.html` **before** Flutter starts, so there's no way for Flutter to inject environment variables at runtime.

**Industry best practice** ([per official Google Maps Flutter Web docs](https://pub.dev/packages/google_maps_flutter_web#usage)): Use build-time injection scripts to keep API keys out of git while maintaining functionality. This is the standard approach for Flutter web projects with secrets.

**Current Setup**: Build-time injection via secure scripts
- ✅ **Secure**: API keys injected during build, not in source code
- ✅ **HTTP Referrer Protection**: Keys restricted to specific domains  
- ✅ **Development-Friendly**: Local development support with localhost referrers
- ✅ **Auto-cleanup**: Scripts automatically restore clean HTML (no secrets in git)

**Development**:
```bash
# Recommended: Secure development with API key injection (no watermark)
./scripts/run_web.sh

# Alternative: Quick testing (shows "For development purposes only" watermark)
flutter run -d chrome

# Pro tip: Create shell alias for convenience
echo "alias fweb='./scripts/run_web.sh'" >> ~/.zshrc && source ~/.zshrc
fweb  # Now just use this!
```

**Production**:
```bash
# Secure production build with API key injection
./scripts/build_web.sh
```

📖 **Web Security Details**: See `WEB_API_KEY_SECURITY.md` for security considerations.

---

## 🔥 EFFIS Fire Data Integration

### Overview
The app integrates with EFFIS (European Forest Fire Information System) for live wildfire data:

**Base URL**: `https://ies-ows.jrc.ec.europa.eu/`  
**WFS Layer**: `effis:burntareas.latest` (current year burnt areas)  
**Update Frequency**: Daily during fire season  
**Timeout**: 8 seconds per service tier  

### Configuration
```json
{
  "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/",
  "MAP_LIVE_DATA": "true"
}
```

### Service Fallback Chain
1. **EFFIS WFS** (8s timeout) → Live fire data
2. **Cache Service** (6h TTL) → Recent cached data  
3. **Mock Service** (never fails) → Demo fire data

### Data Source Control

**MAP_LIVE_DATA Feature Flag**:
- `false` (default): Uses mock data directly (fast, offline-capable)
- `true`: Attempts EFFIS → Cache → Mock fallback chain

**Visual Indicators** (C4 Trust & Transparency):
- Demo mode: Prominent "DEMO DATA" chip in amber
- Live mode: Source chips - "LIVE" (EFFIS), "CACHED", or "MOCK"  
- Timestamp: Always visible "Last updated: [ISO-8601 UTC]"

### Example WFS Query
```
GET /wfs?service=WFS&version=2.0.0&request=GetFeature
&typeName=effis:burntareas.latest&outputFormat=application/json
&bbox={minLon},{minLat},{maxLon},{maxLat}
```

📖 **Operational Procedures**: See `docs/runbooks/effis-monitoring.md`

---

## 💰 Cost Management

### Free Tier Limits
- **$200/month free tier** across all Google Maps APIs
- **28,000 map loads/month** per platform (~$200 value)
- **100,000 static map loads/month** (additional free quota)

### Cost per 1,000 Loads (After Free Tier)
- **Dynamic Maps**: $7/1,000 loads (Android, iOS, Web)
- **Static Maps**: $2/1,000 loads

### Billing Alerts Setup
1. Go to **Google Cloud Console > Billing > Budgets & alerts**
2. Create budget for your project  
3. Set **progressive alert thresholds**:
   - **50% ($100/month)**: Warning email - review usage patterns
   - **80% ($160/month)**: Critical alert - audit API calls, optimize caching  
   - **95% ($190/month)**: Emergency alert - consider quota caps or service pause

### Cost Optimization Features
- ✅ **6-hour cache** (reduces API calls by ~75%)
- ✅ **Lazy marker rendering** (only visible markers loaded)
- ✅ **Mock-first development** (MAP_LIVE_DATA=false by default)
- ✅ **Viewport-based data fetching** (only load data for visible map area)

### Usage Monitoring
- **Dashboard**: APIs & Services > Dashboard
- **Quotas**: APIs & Services > Quotas  
- **Custom Limits**: Set quota caps to prevent overspend

---

## 🔒 Security Best Practices

### API Key Security (C2 Constitutional Compliance)

#### ✅ DO
- **Use environment files** (`env/dev.env.json`) - never hardcode keys
- **Add `env/*.env.json` to `.gitignore`** - prevent accidental commits
- **Restrict API keys** by package name, bundle ID, SHA-1, HTTP referrers
- **Set up billing alerts** at 50%, 80%, 95% thresholds
- **Rotate keys periodically** - quarterly rotation recommended
- **Use separate keys** for dev/staging/production environments
- **Monitor usage for anomalies** - investigate unexpected spikes

#### ❌ DON'T
- **Hardcode API keys in source code** - always use environment variables
- **Commit API keys to git** - use .gitignore and pre-commit hooks
- **Share API keys in chat/email/docs** - use secure key management
- **Use unrestricted keys in production** - always apply appropriate restrictions
- **Use production keys in development** - maintain environment separation

### Privacy-Compliant Logging (C2 Constitutional Compliance)
- ✅ **Coordinate redaction**: Use `GeographicUtils.logRedact()` or `LocationUtils.logRedact()`
  - Logs coordinates at 2 decimal places (~1km precision)
  - Example: `55.95,-3.19` instead of `55.9533,-3.1883`
- ✅ **Geohash logging**: Use geohash keys for spatial operations  
  - Example: `gcpue` (precision 5 = ~4.9km resolution)
  - Inherently privacy-preserving spatial indexing
- ✅ **No PII in logs**: Never log device IDs, user IDs, or precise location traces

### Key Rotation Procedure
1. **Create new API key** in Google Cloud Console
2. **Apply same restrictions** as old key  
3. **Update environment files** (`env/dev.env.json`, `env/prod.env.json`)
4. **Deploy updated configuration** to all environments
5. **Test functionality** on all platforms  
6. **Delete old API key** after successful deployment
7. **Document rotation** in team changelog

---

## 🐛 Troubleshooting

### API Key Not Working

**Symptoms**: Map displays "For development purposes only" watermark, tiles don't load

**Solutions**:
1. **Verify key restrictions** match your app configuration:
   - Android: Package name `com.example.wildfire_mvp_v3` + SHA-1 fingerprint
   - iOS: Bundle ID matches `ios/Runner/Info.plist`  
   - Web: HTTP referrer matches your domain
2. **Check SHA-1 fingerprint** (Android):
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```
3. **Ensure correct Maps SDK enabled** in GCP console:
   - Android: Maps SDK for Android
   - iOS: Maps SDK for iOS
   - Web: Maps JavaScript API
4. **Wait 5-10 minutes** after key creation for propagation
5. **Verify environment file** exists and contains actual keys (not placeholders)

### Platform-Specific Issues

**Android: "Authorization failure" error**
```
E/Google Android Maps SDK: Authorization failure
E/Google Android Maps SDK: API Key: YOUR_API_KEY_HERE
```
- ✅ Verify `env/dev.env.json` exists with actual key
- ✅ Run with `--dart-define-from-file=env/dev.env.json`  
- ✅ Check package name matches exactly: `com.example.wildfire_mvp_v3`
- ✅ Verify SHA-1 fingerprint is correct (case-sensitive)
- ✅ Check Logcat for additional errors: `adb logcat | grep -i "maps"`

**iOS: Map crashes on load**
```
+[GMSServices checkServicePreconditions] + 260
```
- ✅ See `IOS_GOOGLE_MAPS_INTEGRATION.md` for complete crash fix
- ✅ Verify Xcode Build Phase integration is working
- ✅ Check `ios/Runner/Info.plist` has `GMSApiKey` entry after build
- ✅ Run with `--dart-define-from-file=env/dev.env.json`

**Web: Map not displaying**
- ✅ Use secure injection scripts: `./scripts/run_web.sh`
- ✅ Check browser console for CORS or API key errors
- ✅ Verify HTTP referrer restrictions allow your domain  
- ✅ Ensure `web/index.html` has Google Maps JavaScript API script

### Quota and Billing Issues

**Quota Exceeded (403 errors)**
1. **Check current usage**: GCP Console > APIs & Services > Dashboard
2. **Verify caching is working**: 
   ```bash
   grep "Cache hit" logs/app.log
   ```
3. **Review cost optimization**:
   - 6-hour cache should reduce calls by ~75%
   - Lazy rendering loads only visible markers
   - Consider increasing cache TTL to 12h
4. **Temporary fix**: Set quota cap in GCP (prevents overspend)
5. **Long-term**: Upgrade billing plan or optimize data fetching patterns

**Unexpected Billing Charges**
1. **Review usage patterns** in GCP Dashboard
2. **Check for API abuse** - unusual spikes in usage
3. **Verify key restrictions** are properly configured
4. **Audit application logs** for excessive API calls
5. **Consider implementing** request throttling or user-based rate limits

### EFFIS Integration Issues

**Symptoms**: Fire markers not loading, falls back to cached/mock data

**Solutions**:
1. **Check EFFIS endpoint health**:
   ```bash
   curl -I https://ies-ows.jrc.ec.europa.eu/wfs
   ```
2. **Verify configuration** in `env/dev.env.json`:
   ```json
   "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/",
   "MAP_LIVE_DATA": "true"
   ```
3. **Check network connectivity**: `ping ies-ows.jrc.ec.europa.eu`
4. **Review timeout settings**: Default 8s may need adjustment for slow networks
5. **Verify fallback chain**: Cache → Mock (check source chip shows "CACHED" or "MOCK")

**Expected Behavior**:
- EFFIS timeout is **normal and expected** in production
- Fallback chain ensures service never fails completely  
- Cache provides 6-hour resilience window
- Mock data guarantees offline functionality

### Environment File Issues

**Symptoms**: Keys not loading, app crashes on startup, "dart-define not found" errors

**Solutions**:
1. **Verify file exists**: 
   ```bash
   test -f env/dev.env.json && echo "✅ Found" || echo "❌ Missing"
   ```
2. **Check file is valid JSON**:
   ```bash
   cat env/dev.env.json | python -m json.tool
   ```
3. **Ensure all required fields present**:
   - `MAP_LIVE_DATA`
   - `GOOGLE_MAPS_API_KEY_ANDROID`  
   - `GOOGLE_MAPS_API_KEY_IOS`
   - `GOOGLE_MAPS_API_KEY_WEB` (for web platform)
   - `EFFIS_BASE_URL`
4. **Restore from template** if corrupted:
   ```bash
   cp env/dev.env.json.template env/dev.env.json
   # Then add your actual keys
   ```
5. **Verify gitignore protection**:
   ```bash
   git check-ignore -v env/dev.env.json
   # Should show: .gitignore:XX:env/*.env.json    env/dev.env.json
   ```

---

## 🚀 CI/CD Configuration

### GitHub Actions Example
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run tests with CI environment
        run: flutter test --dart-define-from-file=env/ci.env.json
        
      - name: Build Android (if secrets available)
        if: ${{ secrets.GOOGLE_MAPS_API_KEY_ANDROID }}
        env:
          GOOGLE_MAPS_API_KEY_ANDROID: ${{ secrets.GOOGLE_MAPS_API_KEY_ANDROID }}
        run: flutter build apk --dart-define=GOOGLE_MAPS_API_KEY_ANDROID="$GOOGLE_MAPS_API_KEY_ANDROID"
```

### CI Environment (`env/ci.env.json`)
```json
{
  "MAP_LIVE_DATA": "false",
  "GOOGLE_MAPS_API_KEY_ANDROID": "placeholder_for_ci",
  "GOOGLE_MAPS_API_KEY_IOS": "placeholder_for_ci",
  "GOOGLE_MAPS_API_KEY_WEB": "placeholder_for_ci",
  "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/"
}
```

**CI/CD Benefits**:
- ✅ **No secrets in CI logs** - uses placeholder keys with mock data
- ✅ **Consistent testing environment** - all tests use mock data  
- ✅ **Production builds use secrets** - actual keys only for deployment
- ✅ **Fast CI runs** - no external API dependencies

---

## 📚 References

### Google Maps Platform
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Maps SDK for Android Setup](https://developers.google.com/maps/documentation/android-sdk/start)
- [Maps SDK for iOS Setup](https://developers.google.com/maps/documentation/ios-sdk/start)  
- [Maps JavaScript API Setup](https://developers.google.com/maps/documentation/javascript/get-api-key)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Google Maps Pricing](https://mapsplatform.google.com/pricing/)

### EFFIS Integration
- [EFFIS Homepage](https://effis.jrc.ec.europa.eu/)
- [EFFIS WFS Service](https://ies-ows.jrc.ec.europa.eu/)
- [EFFIS Data Access](https://effis.jrc.ec.europa.eu/applications/data-and-services)

### Project Documentation
- **[iOS Google Maps Integration](IOS_GOOGLE_MAPS_INTEGRATION.md)** - Complete iOS crash-free setup
- **[Web API Security](WEB_API_KEY_SECURITY.md)** - Web platform security guide  
- **[Cross-Platform Testing](CROSS_PLATFORM_TESTING.md)** - Platform testing matrix
- **[Privacy Compliance](privacy-compliance.md)** - Privacy compliance statement
- **[EFFIS Monitoring](runbooks/effis-monitoring.md)** - Operational procedures

### Cost Management
- [Cost Calculator](https://cloud.google.com/products/calculator)
- [Billing Alerts Setup](https://cloud.google.com/billing/docs/how-to/budgets)
- [Free Tier Details](https://cloud.google.com/maps-platform/pricing#maps-static)

---

**Last Updated**: October 28, 2025  
**Status**: Production-ready with comprehensive platform support