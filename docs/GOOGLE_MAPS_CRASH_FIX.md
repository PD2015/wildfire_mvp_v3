# Google Maps Crash Fix - iOS GMSServices Error

## Problem Description

**Crash Signature**: `+[GMSServices checkServicePreconditions] + 260`

**Error**: App crashes on iOS when Google Maps tries to initialize due to missing or invalid API key.

**Root Cause**: The iOS app is configured to read Google Maps API key from `Info.plist` via environment variable substitution (`${GOOGLE_MAPS_API_KEY_IOS}`), but when running with standard `flutter run`, this variable is not available and the literal string is passed to `GMSServices.provideAPIKey()`.

## Stack Trace Analysis

```
Last Exception Backtrace:
0   CoreFoundation                  0x1804f39dc __exceptionPreprocess + 160
1   libobjc.A.dylib                 0x18009c084 objc_exception_throw + 72
2   CoreFoundation                  0x1804f38f8 -[NSException initWithCoder:] + 0
3   Runner.debug.dylib              0x102073394 +[GMSServices checkServicePreconditions] + 260
4   Runner.debug.dylib              0x102071154 +[GMSServices preLaunchServices] + 112
5   Runner.debug.dylib              0x1027d1340 -[FLTGoogleMapFactory sharedMapServices] + 52
6   Runner.debug.dylib              0x1027d1270 -[FLTGoogleMapFactory createWithFrame:viewIdentifier:arguments:] + 84
7   Flutter                         0x105fbbfc0 -[FlutterPlatformViewsController onCreate:result:] + 824
```

The crash occurs during Google Maps factory initialization when `GMSServices` validates the provided API key.

## Solution

### ✅ Correct Way to Run the App

Always use the environment file when running on iOS:

```bash
# iOS Simulator
flutter run -d 7858966D-32C4-441B-999A-03F571410BC2 --dart-define-from-file=env/dev.env.json

# Generic iOS (will prompt for device selection)
flutter run --dart-define-from-file=env/dev.env.json
```

### ❌ Incorrect Way (Causes Crash)

```bash
# This WILL crash on iOS because API key is not injected
flutter run -d ios
flutter run
```

## Technical Details

### iOS Configuration

**File**: `ios/Runner/Info.plist`
```xml
<key>GMSApiKey</key>
<string>${GOOGLE_MAPS_API_KEY_IOS}</string>
```

**File**: `ios/Runner/AppDelegate.swift`
```swift
if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
  GMSServices.provideAPIKey(apiKey)
}
```

### Environment File

**File**: `env/dev.env.json`
```json
{
  "GOOGLE_MAPS_API_KEY_IOS": "AIzaSy...your-ios-key-here...",
  "GOOGLE_MAPS_API_KEY_ANDROID": "AIzaSy...your-android-key-here...",
  "MAP_LIVE_DATA": "false"
}
```

### What Happens Without Environment File

1. **Build time**: `${GOOGLE_MAPS_API_KEY_IOS}` is NOT replaced
2. **Runtime**: `Bundle.main.object(forInfoDictionaryKey: "GMSApiKey")` returns literal string `"${GOOGLE_MAPS_API_KEY_IOS}"`
3. **Google Maps**: `GMSServices.provideAPIKey("${GOOGLE_MAPS_API_KEY_IOS}")` fails validation
4. **Result**: App crashes with `checkServicePreconditions` error

### What Happens With Environment File

1. **Build time**: Flutter processes `--dart-define-from-file` and replaces `${GOOGLE_MAPS_API_KEY_IOS}` with actual API key
2. **Runtime**: `Bundle.main.object(forInfoDictionaryKey: "GMSApiKey")` returns valid API key
3. **Google Maps**: `GMSServices.provideAPIKey("AIzaSy...")` succeeds
4. **Result**: App runs successfully

## Verification Steps

### 1. Check API Key Injection

Run with environment file and check logs:

```bash
flutter run -d ios --dart-define-from-file=env/dev.env.json
```

**Expected output** (no crashes):
```
✅ Xcode build done.
✅ flutter: 🔍 EFFIS direct test SUCCESS
✅ flutter: Location resolved via GPS: 55.95,-3.19
✅ A Dart VM Service on iPhone 16e is available
```

### 2. Verify Map Loading

Navigate to map screen in the app:
- Maps should load without watermarks (indicates valid API key)
- No console errors about API key restrictions
- Smooth pan/zoom functionality

### 3. Check API Key Validity

If maps show "For development purposes only" watermark:
1. Verify API key in Google Cloud Console
2. Check iOS app bundle ID restrictions
3. Ensure billing is enabled

## Alternative Solutions (Not Recommended)

### Option 1: Hardcode API Key in AppDelegate

**❌ Security Risk**: Exposes API key in source code

```swift
// DON'T DO THIS - Security risk
GMSServices.provideAPIKey("AIzaSy...") // Hardcoded key
```

### Option 2: Fallback to Placeholder

**❌ Functionality Loss**: Maps won't work properly

```swift
// DON'T DO THIS - Maps will be watermarked
let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String 
    ?? "FALLBACK_PLACEHOLDER_KEY"
GMSServices.provideAPIKey(apiKey)
```

## Platform Differences

### iOS
- **Requires**: `--dart-define-from-file` for environment variable substitution
- **Crashes**: When API key is missing/invalid (strict validation)
- **Config**: `Info.plist` + `AppDelegate.swift`

### Android
- **Graceful**: Usually shows error message instead of crashing
- **Config**: `AndroidManifest.xml` with `${GOOGLE_MAPS_API_KEY_ANDROID}`
- **Same Fix**: Use `--dart-define-from-file` for consistency

### Web
- **Different**: Uses `google_maps_flutter_web` with JavaScript API
- **Config**: `web/index.html` with `${GOOGLE_MAPS_API_KEY_WEB}`
- **Same Fix**: Use `--dart-define-from-file` for consistency

## Development Workflow

### 1. Daily Development

```bash
# Always use environment file
flutter run --dart-define-from-file=env/dev.env.json

# Or use the convenient script
./scripts/run_web.sh  # For web development
```

### 2. IDE Configuration

**VS Code**: Update `.vscode/launch.json`:
```json
{
  "configurations": [
    {
      "name": "Flutter (iOS with API keys)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define-from-file=env/dev.env.json"]
    }
  ]
}
```

**Android Studio**: Add to run configuration:
- **Additional run args**: `--dart-define-from-file=env/dev.env.json`

### 3. Team Onboarding

**New developers must**:
1. Copy `env/dev.env.json.template` to `env/dev.env.json`
2. Add valid Google Maps API keys
3. Always run with `--dart-define-from-file=env/dev.env.json`

## API Key Setup Reference

### Google Cloud Console

1. **Enable APIs**:
   - Maps SDK for iOS
   - Maps SDK for Android
   - Maps JavaScript API (for web)

2. **Create Credentials**:
   - API Key → Restrict by platform
   - iOS: Bundle ID `com.example.wildfireMvpV3`
   - Android: Package name `com.example.wildfire_mvp_v3` + SHA-1
   - Web: HTTP referrers (optional)

3. **Enable Billing**:
   - Required for production use
   - Free tier: $200/month credit
   - Set up billing alerts

### Security Best Practices

- ✅ Use platform-specific restricted API keys
- ✅ Keep keys in environment files (git-ignored)
- ✅ Use `--dart-define-from-file` for injection
- ❌ Never commit API keys to version control
- ❌ Never hardcode keys in source code

## Related Documentation

- [`docs/GOOGLE_MAPS_SETUP.md`](./GOOGLE_MAPS_SETUP.md) - Complete setup guide
- [`docs/API_KEY_SETUP.md`](./API_KEY_SETUP.md) - API key configuration
- [`.github/copilot-instructions.md`](../.github/copilot-instructions.md) - Project commands

## Troubleshooting

### Still Crashing After Fix?

1. **Clean Build**: `flutter clean && flutter pub get`
2. **Check Device ID**: Use actual device ID instead of `ios`
3. **Verify API Key**: Ensure key is valid in Google Cloud Console
4. **Check Bundle ID**: Must match Google Cloud Console restrictions

### Maps Not Loading?

1. **Check Console**: Look for API key errors in DevTools
2. **Verify Billing**: Ensure Google Cloud billing is enabled
3. **Wait for Propagation**: API key restrictions take ~5 minutes
4. **Check Network**: Ensure internet connectivity

### Environment File Not Found?

```bash
# Check if file exists
ls -la env/dev.env.json

# Copy from template if missing
cp env/dev.env.json.template env/dev.env.json
# Then add your API keys
```

---

**Resolution**: Use `flutter run --dart-define-from-file=env/dev.env.json` to properly inject Google Maps API keys and prevent iOS crashes.