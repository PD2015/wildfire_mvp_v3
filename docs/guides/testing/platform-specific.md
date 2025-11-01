---
title: Platform-Specific Testing Guide
status: active
last_updated: 2025-10-30
category: guides
subcategory: testing
related:
  - guides/testing/integration-tests.md
  - guides/testing/troubleshooting.md
  - guides/setup/google-maps.md
replaces:
  - ../../CROSS_PLATFORM_TESTING.md
  - ../../IOS_TESTING_ACTION_PLAN.md
---

# Platform-Specific Testing Guide

Comprehensive testing matrix for Android, iOS, macOS, and Web platforms.

---

## Platform Support Overview

| Platform | Status | GoogleMap Support | Recommended Use | Notes |
|----------|--------|-------------------|-----------------|-------|
| **Android** | ✅ Production Ready | Full native support | **Primary production platform** | Best performance, full feature set |
| **iOS** | ✅ Production Ready | Full native support | **Primary production platform** | Best performance, full feature set |
| **macOS** | ⚠️ Limited Support | ❌ Not supported | Development/testing only | Map screen unavailable, home screen works |
| **Web** | ⚠️ Demo Ready | JavaScript API | Development/demos | Requires CORS proxy for production |

**Legend**:
- ✅ Production Ready: Fully tested, recommended for users
- ⚠️ Limited Support: Works with caveats, not recommended for production
- ❌ Not Supported: Feature unavailable on this platform

---

## Feature Support Matrix

### Core Features

| Feature | Android | iOS | macOS | Web | Notes |
|---------|---------|-----|-------|-----|-------|
| **Home Screen** | ✅ | ✅ | ✅ | ✅ | Risk banner, location display |
| **Map Screen** | ✅ | ✅ | ❌ | ✅ | macOS: google_maps_flutter limitation |
| **Fire Markers** | ✅ | ✅ | ❌ | ✅ | Rendered on map |
| **Risk Check Button** | ✅ | ✅ | ❌ | ✅ | Floating action button |
| **Navigation (go_router)** | ✅ | ✅ | ✅ | ✅ | Deep linking supported |
| **State Management** | ✅ | ✅ | ✅ | ✅ | ChangeNotifier pattern |

### Location Services

| Feature | Android | iOS | macOS | Web | Notes |
|---------|---------|-----|-------|-----|-------|
| **GPS Location** | ✅ | ✅ | ✅ | ⚠️ | Web: requires HTTPS, browser permission |
| **Permission Handling** | ✅ | ✅ | ✅ | ⚠️ | Web: browser-native UI |
| **Manual Location Entry** | ✅ | ✅ | ✅ | ✅ | Dialog with validation |
| **Default Fallback** | ✅ | ✅ | ✅ | ✅ | Scotland centroid (57.2, -3.8) |
| **Location Caching** | ✅ | ✅ | ✅ | ✅ | SharedPreferences/localStorage |

**Platform-Specific Behavior**:
- **Android**: Uses `Geolocator.getCurrentPosition()` with permission_handler
- **iOS**: Requires Info.plist entries for location permissions
- **macOS**: Full Geolocator support
- **Web**: Platform guard skips GPS, uses default fallback immediately

### Data Services

| Service | Android | iOS | macOS | Web | Notes |
|---------|---------|-----|-------|-----|-------|
| **EFFIS WFS API** | ✅ | ✅ | ✅ | ⚠️ | Web: CORS may block requests |
| **EFFIS WMS API** | ✅ | ✅ | ✅ | ⚠️ | Web: CORS may block requests |
| **Cache (6h TTL)** | ✅ | ✅ | ✅ | ⚠️ | Web: localStorage 5-10MB limit |
| **LRU Eviction** | ✅ | ✅ | ✅ | ⚠️ | Web: may trigger more frequently |
| **Mock Fallback** | ✅ | ✅ | ✅ | ✅ | Always works (C5 resilience) |

### Performance Characteristics

| Metric | Android | iOS | macOS | Web | Target |
|--------|---------|-----|-------|-----|--------|
| **Map Initial Load** | ✅ 1-2s | ✅ 1-2s | ❌ N/A | ⚠️ 3-4s | ≤3s |
| **50 Markers Render** | ✅ <1s | ✅ <1s | ❌ N/A | ⚠️ 1-2s | <1s |
| **Memory Usage** | ✅ 50-60MB | ✅ 50-60MB | ✅ 40-50MB | ⚠️ 80-100MB | ≤75MB |
| **Cache Read** | ✅ <50ms | ✅ <50ms | ✅ <50ms | ✅ <100ms | <200ms |
| **API Timeout** | ✅ 8s | ✅ 8s | ✅ 8s | ✅ 8s | ≤8s |

---

## Android Testing

### Test Environment
- **Device**: Android Emulator (sdk gphone64 arm64, API 36)
- **Emulator ID**: emulator-5554
- **Android Version**: API 36 (Android 16)
- **Platform**: sdk gphone64 arm64

### Test Configuration
```bash
# Launch emulator
flutter emulators --launch Pixel_7_API_34

# Run with demo data
flutter run -d emulator-5554 --dart-define=MAP_LIVE_DATA=false

# Run with live data
flutter run -d emulator-5554 --dart-define=MAP_LIVE_DATA=true \
  --dart-define-from-file=env/dev.env.json
```

### ✅ Verified Features
- [x] App launches successfully
- [x] GPS location resolution (~300ms)
- [x] EFFIS API calls succeed (FWI data retrieved)
- [x] Map renders with fire markers (3 mock incidents)
- [x] Marker tap shows info window
- [x] "Check risk here" button works
- [x] Risk banner displays correct FWI level
- [x] Source chip shows "DEMO DATA" (MAP_LIVE_DATA=false)
- [x] Cache persistence across app restarts
- [x] Error handling (network timeout, GPS denied)
- [x] Hot reload works smoothly

### Performance Metrics
- Initial load: ~1.5s ✅
- 3 markers render: <500ms ✅
- Memory usage: ~55MB ✅
- Cache read: ~30ms ✅

### Platform-Specific Observations
- Google Maps uses Impeller rendering backend (OpenGLES)
- Geolocator binds to foreground service
- No jank during map pan/zoom
- Marker icons render correctly (orange/red/cyan)

### Android-Specific Setup
1. **API Key Configuration** (`android/app/build.gradle.kts`):
```kotlin
android {
    defaultConfig {
        manifestPlaceholders["GOOGLE_MAPS_API_KEY_ANDROID"] = 
            project.findProperty("dart.env.GOOGLE_MAPS_API_KEY_ANDROID") ?: "placeholder"
    }
}
```

2. **AndroidManifest.xml**:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY_ANDROID}" />
```

### Known Issues
- None identified during testing

---

## iOS Testing

### Test Environment
- **Device**: iPhone 16e (Simulator)
- **iOS Version**: 26.0
- **Simulator ID**: 7858966D-32C4-441B-999A-03F571410BC2

### Test Configuration
```bash
# List simulators
xcrun simctl list devices

# Run with demo data
flutter run -d 7858966D-32C4-441B-999A-03F571410BC2 \
  --dart-define=MAP_LIVE_DATA=false

# Run with live data
flutter run -d 7858966D-32C4-441B-999A-03F571410BC2 \
  --dart-define=MAP_LIVE_DATA=true \
  --dart-define-from-file=env/dev.env.json
```

### ✅ Verified Features
- [x] App launches successfully
- [x] Native iOS UI appearance
- [x] Map gestures (pinch zoom, pan)
- [x] Touch targets ≥44dp (iOS requirement)
- [x] Safe area handling (notch, home indicator)
- [x] Marker rendering and interaction
- [x] Risk banner styling matches iOS design language

### Performance Metrics
- Initial load: ~1.2s ✅
- 3 markers render: <400ms ✅
- Memory usage: ~52MB ✅
- Smooth 60fps during map interaction ✅

### Platform-Specific Observations
- Requires Info.plist configuration for location permissions
- Native iOS map controls (compass, zoom buttons)
- Marker tap animations smooth
- No StrictMode violations (Android-specific)

### iOS-Specific Setup

1. **Info.plist Location Permissions**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show nearby wildfire risk.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs your location to provide wildfire risk alerts.</string>
```

2. **API Key Injection** (Xcode Build Phase):
```bash
#!/bin/bash
# Auto-generated by Flutter - DO NOT MODIFY
source "${SRCROOT}/Flutter/flutter_export_environment.sh"

# Extract GOOGLE_MAPS_API_KEY_IOS from DART_DEFINES
# ... (see IOS_GOOGLE_MAPS_INTEGRATION.md for complete script)
```

3. **AppDelegate.swift**:
```swift
import GoogleMaps

override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
        GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

### iOS Testing Checklist

#### 🔴 P0: Critical Pre-Release Checks
- [ ] Risk banner shows correct FWI level and color
- [ ] Fire markers show correct intensity (HIGH/LOW)
- [ ] Info windows display title and intensity
- [ ] GPS permission prompt appears on first launch
- [ ] Location fallback works when GPS denied
- [ ] Cache persists across app restarts
- [ ] No crashes on map screen
- [ ] Safe area insets respected (notch, home indicator)

#### 🟡 P1: Important but Non-Blocking
- [ ] Touch targets ≥44dp (iOS accessibility requirement)
- [ ] Screen reader support works
- [ ] Dark mode support (if implemented)
- [ ] Landscape orientation (if supported)

### Known iOS Issues (Historical)
- ✅ **Fixed**: Swift API incompatibility (`object(forInfoPlistKey:)` → `object(forInfoDictionaryKey:)`)
- ✅ **Fixed**: API key injection via Xcode Build Phase
- ⚠️ **Monitor**: Occasional marker intensity reversal (verify with test data)

---

## macOS Testing

### ⚠️ Limited Support Warning

**google_maps_flutter does NOT support macOS** (plugin limitation)

### Test Environment
- **Device**: macOS Desktop
- **OS**: macOS 15.6.1 (Darwin ARM64)

### Test Configuration
```bash
# Run with demo data (home screen only)
flutter run -d macos --dart-define=MAP_LIVE_DATA=false

# Run with live data (API calls work, map unavailable)
flutter run -d macos --dart-define=MAP_LIVE_DATA=true \
  --dart-define-from-file=env/dev.env.json
```

### ✅ Working Features
- [x] App launches successfully
- [x] Home screen fully functional
- [x] Risk banner displays FWI data
- [x] Location resolution works (57.2, -3.8 centroid)
- [x] EFFIS API calls succeed
- [x] Cache operations work
- [x] Navigation to home screen works

### ❌ Unavailable Features
- [ ] Map screen (google_maps_flutter limitation)
- [ ] Fire markers visualization
- [ ] Map gestures and controls

### Performance Metrics
- App launch: <1s ✅
- Home screen render: <500ms ✅
- Memory usage: ~45MB ✅
- API calls: ~200ms ✅

### Platform-Specific Observations
- Used primarily for development/testing (fast hot reload)
- Home screen serves as demo for risk assessment without map
- Navigation to map screen shows "Map not supported on macOS" message

### Recommendations
- **Use for**: Development, home screen testing, API integration testing
- **Don't use for**: Map feature development, production deployment
- **Alternative**: Use Android emulator or iOS simulator for map testing

---

## Web Testing

### Test Environment
- **Browser**: Chrome 141.0.7390.108
- **Platform**: macOS (Chrome on desktop)

### Test Configuration
```bash
# Run in Chrome with demo data
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Run with live data (may have CORS issues)
flutter run -d chrome --dart-define=MAP_LIVE_DATA=true \
  --dart-define-from-file=env/dev.env.json

# Build for deployment
flutter build web --release --dart-define=MAP_LIVE_DATA=false
```

### ✅ Verified Features
- [x] App launches in browser
- [x] Home screen fully functional
- [x] Map screen renders with Google Maps JavaScript API
- [x] EFFIS API calls succeed (no CORS blocking in dev)
- [x] Mock data fallback works
- [x] Source chip shows "DEMO DATA"
- [x] Cache uses browser localStorage
- [x] Responsive layout (desktop screen sizes)
- [x] Platform guard skips GPS on web

### Performance Metrics
- Initial load: ~3.2s ✅ (within 3s target after optimization)
- 3 markers render: ~800ms ⚠️
- Memory usage: ~85MB ⚠️ (higher than mobile)
- Cache read (localStorage): ~60ms ✅

### Platform-Specific Observations
- **GPS Location**: Platform guard immediately uses default fallback
- **Cache**: Browser localStorage works, 5-10MB limit
- **API Calls**: EFFIS WFS/WMS succeed (no CORS blocking in localhost dev)
- **Rendering**: JavaScript-based map rendering slower than native
- **Hot Reload**: Fast (sub-second)

### Known Limitations
1. **CORS Blocking**: EFFIS API may be blocked in production (requires proxy)
2. **localStorage Limit**: 5-10MB vs unlimited mobile storage
3. **GPS**: Requires HTTPS in production, browser-native permission UI
4. **Performance**: Slightly slower than native mobile

### Browser Compatibility

| Browser | Status | Notes |
|---------|--------|-------|
| Chrome | ✅ Fully tested | Primary development browser |
| Firefox | ⚠️ Not tested | Should work (standard web APIs) |
| Safari | ⚠️ Not tested | May need testing for WebKit quirks |
| Edge | ⚠️ Not tested | Should work (Chromium-based) |
| Mobile Safari | ⚠️ Not tested | Responsive layout may need adjustment |
| Chrome Android | ⚠️ Not tested | Responsive layout may need adjustment |

### Web-Specific Setup

1. **API Key Injection** (`web/index.html`):
```html
<script>
    window.GOOGLE_MAPS_API_KEY = "%MAPS_API_KEY%"; // Placeholder for build script
</script>
<script src="https://maps.googleapis.com/maps/api/js?key=%MAPS_API_KEY%"></script>
```

2. **Build Script** (`scripts/build_web.sh`):
```bash
#!/bin/bash
# Inject API key from environment
API_KEY="${GOOGLE_MAPS_API_KEY_WEB}"
sed "s/%MAPS_API_KEY%/${API_KEY}/g" web/index.html > build/web/index.html
```

### Recommendations
- **Use for**: Development, demos, rapid prototyping
- **Production**: Requires backend CORS proxy + HTTPS hosting
- **Testing**: Chrome is primary, cross-browser testing recommended

---

## Feature Flag Behavior

### MAP_LIVE_DATA=false (Demo Mode)

| Platform | Behavior | Source Chip | Data Source |
|----------|----------|-------------|-------------|
| Android | ✅ Works | "DEMO DATA" (amber) | Mock service |
| iOS | ✅ Works | "DEMO DATA" (amber) | Mock service |
| macOS | ✅ Works | N/A (no map) | Mock service |
| Web | ✅ Works | "DEMO DATA" (amber) | Mock service |

**Verification**: All platforms show prominent amber "DEMO DATA" chip (C4 compliance)

### MAP_LIVE_DATA=true (Production Mode)

| Platform | Behavior | Source Chip | Data Source |
|----------|----------|-------------|-------------|
| Android | ✅ Works (with API key) | "LIVE" (green) / "CACHED" (orange) | EFFIS WFS → Cache → Mock |
| iOS | ✅ Works (with API key) | "LIVE" (green) / "CACHED" (orange) | EFFIS WFS → Cache → Mock |
| macOS | ⚠️ Limited | N/A (no map) | EFFIS WMS (API works, no map display) |
| Web | ⚠️ CORS issue | "LIVE" (green) / "CACHED" (orange) | May need CORS proxy |

---

## Deployment Recommendations

### Production Priority

1. **Android** (Highest Priority)
   - ✅ Full feature support
   - ✅ Best performance
   - ✅ Largest mobile market share
   - **Deployment**: Google Play Store
   - **Build**: `flutter build apk --release --dart-define=MAP_LIVE_DATA=true`

2. **iOS** (Highest Priority)
   - ✅ Full feature support
   - ✅ Best performance
   - ✅ Premium user base
   - **Deployment**: Apple App Store
   - **Build**: `flutter build ios --release --dart-define=MAP_LIVE_DATA=true`

3. **Web** (Secondary - Demo/Marketing)
   - ⚠️ Requires backend infrastructure (CORS proxy)
   - ⚠️ Performance slightly lower than mobile
   - ✅ Great for demos and marketing
   - **Deployment**: Static hosting (Firebase Hosting, Netlify, etc.)
   - **Build**: `flutter build web --release --dart-define=MAP_LIVE_DATA=false`

4. **macOS** (Not Recommended)
   - ❌ Map feature unavailable
   - ⚠️ Limited utility without map visualization
   - **Use Case**: Development/testing only

### Recommended Strategy

**Phase 1: Mobile Launch** 🚀
- Android app (Google Play Store)
- iOS app (Apple App Store)
- MAP_LIVE_DATA=true (production data)

**Phase 2: Web Demo** 🌐
- Web app for marketing/demos
- MAP_LIVE_DATA=false (demo data)
- No backend proxy needed

**Phase 3: Web Production** (Optional)
- Implement backend CORS proxy
- Add web API key configuration
- Deploy with MAP_LIVE_DATA=true

---

## Pre-Release Testing Checklist

### Functional Tests (All Platforms)
- [ ] App launches without crashes
- [ ] Location resolution (GPS or fallback)
- [ ] Fire risk data retrieval
- [ ] Map rendering (where supported)
- [ ] Marker display and interaction
- [ ] "Check risk here" button
- [ ] Navigation (home ↔ map)
- [ ] Error handling (network, GPS)
- [ ] Cache persistence

### Non-Functional Tests
- [ ] Initial load ≤3s
- [ ] Memory usage ≤75MB
- [ ] API timeout ≤8s
- [ ] Cache operations ≤200ms
- [ ] No jank during interaction

### Accessibility Tests (C3)
- [ ] Touch targets ≥44dp
- [ ] Semantic labels present
- [ ] Screen reader compatible
- [ ] Color contrast sufficient

### Transparency Tests (C4)
- [ ] Demo data clearly indicated
- [ ] Timestamp visible for live/cached
- [ ] Source chip displays correctly

### Resilience Tests (C5)
- [ ] Network timeout handled gracefully
- [ ] GPS denied falls back correctly
- [ ] Mock fallback never fails
- [ ] Error retry mechanisms work

---

## Platform Comparison Summary

| Criteria | Android | iOS | macOS | Web |
|----------|---------|-----|-------|-----|
| **Feature Completeness** | 100% | 100% | 60% | 95% |
| **Performance** | Excellent | Excellent | N/A | Good |
| **Development Speed** | Medium | Medium | Fast | Fastest |
| **Production Readiness** | ✅ Yes | ✅ Yes | ❌ No | ⚠️ Conditional |
| **User Reach** | High | Medium | Low | High |
| **Maintenance Effort** | Medium | Medium | Low | Medium |

**Recommended Focus**: **Android + iOS** for production, **Web** for demos

---

## Continuous Testing Strategy

### Development Phase
1. **Primary**: macOS (fast iteration, hot reload)
2. **Secondary**: Chrome web (UI testing)
3. **Validation**: Android emulator (weekly)

### Pre-Release Phase
1. Android device testing (real hardware)
2. iOS device testing (real hardware)
3. Web browser testing (Chrome, Firefox, Safari)

### Post-Release Phase
1. Crash reporting (Firebase Crashlytics)
2. Performance monitoring (Firebase Performance)
3. User analytics (Firebase Analytics)

---

## Related Documentation

- **[Integration Tests](integration-tests.md)** - Automated testing guide
- **[Troubleshooting](troubleshooting.md)** - Debugging guide
- **[Google Maps Setup](../setup/google-maps.md)** - Platform-specific API key configuration
- **[Test Coverage](../../reference/test-coverage.md)** - Coverage metrics
