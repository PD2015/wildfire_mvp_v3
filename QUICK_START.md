# Quick Start - Run Commands

**⚠️ IMPORTANT**: Always use `--dart-define-from-file=env/dev.env.json` to prevent Google Maps crashes on iOS.

## Correct Run Commands

### iOS Simulator
```bash
flutter run --dart-define-from-file=env/dev.env.json
# Will prompt for device selection - choose iPhone option
```

### Android Emulator
```bash
flutter run -d android --dart-define-from-file=env/dev.env.json
```

### Web (Chrome)
```bash
flutter run -d chrome --dart-define-from-file=env/dev.env.json
# Or use the convenient script:
./scripts/run_web.sh
```

### macOS Desktop
```bash
flutter run -d macos --dart-define-from-file=env/dev.env.json
```

## Why This Is Required

The app requires Google Maps API keys to be injected via environment variables:

- **iOS**: `Info.plist` contains `${GOOGLE_MAPS_API_KEY_IOS}` placeholder
- **Android**: `AndroidManifest.xml` contains `${GOOGLE_MAPS_API_KEY_ANDROID}` placeholder  
- **Web**: `index.html` contains `${GOOGLE_MAPS_API_KEY_WEB}` placeholder

Without `--dart-define-from-file=env/dev.env.json`, these placeholders are not replaced and the app will:

- ❌ **iOS**: Crash with `GMSServices checkServicePreconditions` error
- ❌ **Android**: Show API key error in maps
- ❌ **Web**: Maps won't load properly

## What The Environment File Does

`env/dev.env.json` contains:
```json
{
  "GOOGLE_MAPS_API_KEY_IOS": "AIzaSy...",
  "GOOGLE_MAPS_API_KEY_ANDROID": "AIzaSy...",
  "GOOGLE_MAPS_API_KEY_WEB": "AIzaSy...",
  "MAP_LIVE_DATA": "false"
}
```

Flutter's `--dart-define-from-file` flag processes this file and replaces all `${VARIABLE_NAME}` placeholders in your app configuration files with the actual values.

## IDE Setup

### VS Code
Add to `.vscode/launch.json`:
```json
{
  "configurations": [
    {
      "name": "Flutter (with API keys)",
      "request": "launch", 
      "type": "dart",
      "args": ["--dart-define-from-file=env/dev.env.json"]
    }
  ]
}
```

### Android Studio
In Run Configuration:
- **Additional run args**: `--dart-define-from-file=env/dev.env.json`

## Common Errors

### ❌ "No such file or directory: env/dev.env.json"
**Solution**: Copy the template:
```bash
cp env/dev.env.json.template env/dev.env.json
# Then add your Google Maps API keys
```

### ❌ iOS app crashes with GMSServices error
**Solution**: You forgot `--dart-define-from-file=env/dev.env.json`

### ❌ Maps show "For development purposes only" watermark
**Solution**: 
1. Get valid Google Maps API keys from [Google Cloud Console](https://console.cloud.google.com/)
2. Add them to `env/dev.env.json`
3. Ensure billing is enabled in Google Cloud Console

## Quick Troubleshooting

1. **Clean build**: `flutter clean && flutter pub get`
2. **Check environment file**: `cat env/dev.env.json`
3. **Use device ID**: `flutter devices` then `flutter run -d [device-id] --dart-define-from-file=env/dev.env.json`
4. **Check logs**: Look for API key errors in console output

---

**Remember**: Always use the environment file flag. It's required for proper Google Maps functionality across all platforms.