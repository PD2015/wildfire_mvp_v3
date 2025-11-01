# Google Maps API Key Setup

## Overview

The WildFire MVP app uses Google Maps on iOS and Android platforms. To function properly, you need to provide valid Google Maps API keys for each platform.

## Quick Start (Development/Testing)

For **testing with mock fire data only** (no actual map tiles needed), the app can run with a placeholder API key on iOS. However, you'll see a watermarked map.

### iOS Development Setup

The app is currently configured with a placeholder key in `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("AIzaSyDevelopmentKeyPlaceholder_ReplaceWithRealKey")
```

**To get a real Google Maps API key:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select existing)
3. Enable **Maps SDK for iOS** API
4. Go to **APIs & Services > Credentials**
5. Click **Create Credentials > API Key**
6. **Restrict the key:**
   - Application restrictions: **iOS apps**
   - Bundle ID: `com.example.wildfireMvpV3` (or your custom bundle ID)
7. Copy the API key
8. Replace the placeholder in `ios/Runner/AppDelegate.swift`

### Android Development Setup

Android is configured to use environment variables via `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY_ANDROID}" />
```

**To provide the API key:**

1. Get an API key from Google Cloud Console (same as iOS steps 1-5)
2. **Restrict the key:**
   - Application restrictions: **Android apps**
   - Package name: `com.example.wildfire_mvp_v3`
   - SHA-1 certificate fingerprint: (get from `keytool` or Android Studio)
3. Create `env/dev.env.json`:

```json
{
  "MAP_LIVE_DATA": "false",
  "GOOGLE_MAPS_API_KEY_ANDROID": "YOUR_ANDROID_KEY_HERE",
  "GOOGLE_MAPS_API_KEY_IOS": "YOUR_IOS_KEY_HERE"
}
```

4. Run with environment file:

```bash
flutter run -d android --dart-define-from-file=env/dev.env.json
```

## Production Setup

### iOS Production

For production builds, you should use `--dart-define` instead of hardcoding keys:

1. Update `ios/Runner/AppDelegate.swift` to read from environment:

```swift
// Read API key from --dart-define
let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY_IOS"] 
    ?? "AIzaSyDevelopmentKeyPlaceholder_ReplaceWithRealKey"
GMSServices.provideAPIKey(apiKey)
```

2. Build with environment file:

```bash
flutter build ipa --dart-define-from-file=env/prod.env.json
```

### Android Production

Android already reads from environment variables. Just ensure `env/prod.env.json` has production keys:

```bash
flutter build apk --dart-define-from-file=env/prod.env.json
```

## Security Best Practices

### API Key Restrictions

**iOS Keys:**
- Restrict to iOS apps only
- Add your bundle ID: `com.example.wildfireMvpV3`
- Consider adding bundle ID restrictions for App Store builds

**Android Keys:**
- Restrict to Android apps only
- Add package name: `com.example.wildfire_mvp_v3`
- Add SHA-1 fingerprints for debug and release builds

### Get SHA-1 Fingerprints

**Debug keystore:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release keystore:**
```bash
keytool -list -v -keystore path/to/your-release-key.keystore
```

### Billing Quotas

Set up billing alerts in Google Cloud Console:
- Alert at 50% of free tier ($200/month = $100 alert)
- Alert at 80% of free tier ($160 alert)
- Monitor usage dashboard weekly

### .gitignore

Ensure environment files with real keys are never committed:

```gitignore
# Environment files with API keys
env/*.env.json
!env/example.env.json
```

## Troubleshooting

### "Google Maps API Key is missing" error on iOS

**Symptom:** App crashes with `[GMSServices checkServicePreconditions]` in stack trace

**Solution:** 
1. Verify `GMSServices.provideAPIKey()` is called in `AppDelegate.swift`
2. Check the API key is valid and not a placeholder
3. Ensure Maps SDK for iOS is enabled in Google Cloud Console

### Map shows "For development purposes only" watermark

**Cause:** Using unrestricted or invalid API key

**Solution:** 
1. Create properly restricted API keys
2. Ensure billing is enabled in Google Cloud Console
3. Wait 5 minutes for restrictions to propagate

### Map tiles not loading (gray map)

**Possible causes:**
1. Invalid API key
2. Maps SDK for iOS/Android not enabled
3. API key restrictions too strict (wrong bundle ID)
4. Billing not enabled in Google Cloud Console

**Solution:**
1. Check Google Cloud Console > APIs & Services > Dashboard for API errors
2. Verify bundle ID/package name matches restrictions
3. Enable billing (free tier available)
4. Check network connectivity (iOS requires entitlements)

## Current Status (As of 2025-10-19)

- ✅ iOS: Placeholder key configured in `AppDelegate.swift` (needs real key for map tiles)
- ✅ Android: Environment variable configured in `AndroidManifest.xml`
- ⚠️ Mock fire data works without real API keys (but map will show watermark)
- ⚠️ User needs to obtain real Google Maps API keys for full functionality

## References

- [Google Maps Platform - Get Started](https://developers.google.com/maps/gmp-get-started)
- [Maps SDK for iOS - Get API Key](https://developers.google.com/maps/documentation/ios-sdk/get-api-key)
- [Maps SDK for Android - Get API Key](https://developers.google.com/maps/documentation/android-sdk/get-api-key)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
