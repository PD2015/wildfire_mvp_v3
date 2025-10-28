# Android Testing Session - 2025-10-20

## Summary
First Android emulator test of Google Maps MVP (T028).

## Test Environment
- **Device**: Android Emulator (Medium Phone API 36.1)
- **Emulator ID**: emulator-5554
- **Android Version**: API 36 (Android 16)
- **Platform**: sdk gphone64 arm64

## Build Results
✅ **Build Successful** (after manifest placeholder fix)
- Initial build failed: Missing `GOOGLE_MAPS_API_KEY_ANDROID` manifest placeholder
- Fix: Added `manifestPlaceholders` to `android/app/build.gradle.kts`
- Build time: ~32 seconds
- APK size: Normal for debug build

## App Launch
✅ **App Launches Successfully**
- No crashes
- EFFIS service test passed: FWI=28.343298, Risk=RiskLevel.high
- GPS resolution working: `Location resolved via GPS: 37.42,-122.08` (Mountain View, CA - emulator default)
- Resolution time: 549ms

## Issues Found

### 1. Map Tiles Not Loading ❌
**Symptom**: Map area shows but no visible map tiles
**Cause**: Placeholder API key "YOUR_API_KEY_HERE" is invalid
**Solution Required**: 
- Obtain Google Maps API key from GCP Console
- Add SHA-1 fingerprint restriction for debug certificate
- Add to `env/dev.env.json`

**Debug certificate SHA-1**:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 2. GPS Location Outside Scotland ⚠️
**Symptom**: Emulator defaults to Mountain View, CA (37.42, -122.08)
**Impact**: No fire markers visible (mock data only in Scotland bounds)
**Solution**: Set emulator location via Extended Controls → Location → Edinburgh (55.9533, -3.1883)

## Features Not Tested (Blocked by API Key)
⏸️ Cannot test without visible map tiles:
- Zoom controls visibility (Android should show +/- buttons)
- Pinch-to-zoom gesture
- Pan/drag gesture
- Fire marker display
- Marker info windows
- FAB positioning relative to map controls

## Gradle Configuration Added
```kotlin
// android/app/build.gradle.kts
manifestPlaceholders["GOOGLE_MAPS_API_KEY_ANDROID"] = 
    project.findProperty("GOOGLE_MAPS_API_KEY_ANDROID")?.toString() 
    ?: System.getenv("GOOGLE_MAPS_API_KEY_ANDROID") 
    ?: "YOUR_API_KEY_HERE"
```

## Next Steps
1. ✅ Commit gradle fix for manifest placeholder
2. ⏸️ Obtain Google Maps API key (see `docs/google-maps-setup.md`)
3. ⏸️ Add key to `env/dev.env.json`
4. ⏸️ Run with `flutter run -d emulator-5554 --dart-define-from-file=env/dev.env.json`
5. ⏸️ Complete T028 acceptance criteria testing

## Comparison: iOS vs Android

| Feature | iOS Simulator | Android Emulator |
|---------|--------------|------------------|
| App Launch | ✅ Working | ✅ Working |
| GPS Resolution | ✅ Working (SF default) | ✅ Working (MV default) |
| Map Tiles | ✅ Visible (has API key) | ❌ Not visible (placeholder key) |
| Zoom Controls | ⚠️ Hidden (iOS design) | ⏸️ Cannot test yet |
| Gestures | ✅ Working | ⏸️ Cannot test yet |
| Fire Markers | ✅ Visible (with location change) | ⏸️ Cannot test yet |

## Constitutional Gate Compliance
- **C1 (Code Quality)**: Build succeeds with proper gradle configuration
- **C2 (Secrets)**: Placeholder key used, real key in `.gitignore`'d env file ✅
- **C3 (Accessibility)**: ⏸️ Cannot verify touch targets without visible map
- **C5 (Resilience)**: App gracefully handles missing API key (launches without crash) ✅

## Session Duration
- Build setup: ~5 minutes
- Debugging manifest error: ~3 minutes
- First successful launch: ~2 minutes
- **Total**: ~10 minutes

## Files Modified
- `android/app/build.gradle.kts` - Added manifestPlaceholders configuration
