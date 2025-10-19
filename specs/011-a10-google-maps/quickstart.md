# A10 Quickstart: Google Maps MVP Map

**Feature**: Production-ready Google Maps integration with fire markers and risk assessment  
**Estimated Setup Time**: 15 minutes  
**Prerequisites**: Flutter 3.35.5+, Dart 3.0+, A9 MapScreen scaffold complete

---

## Quick Validation (2 minutes)

### Verify you can run this feature in < 2 minutes:

```bash
# 1. Checkout the A10 branch
git checkout 011-a10-google-maps

# 2. Set up environment variables (Google Maps API keys)
cp .env.example .env
# Edit .env and add your keys:
# GOOGLE_MAPS_API_KEY_ANDROID=AIza...
# GOOGLE_MAPS_API_KEY_IOS=AIza...

# 3. Get dependencies
flutter pub get

# 4. Run with mock data (no API calls)
flutter run -d macos --dart-define=MAP_LIVE_DATA=false

# Expected: Map loads with 2-3 mock fire markers near Scotland
```

**Success Criteria**:
- ✅ Map renders within 3 seconds
- ✅ User location centered (or Scotland default)
- ✅ 2-3 fire markers visible with "Mock" source badge
- ✅ Tapping marker shows info window with timestamp
- ✅ Long-press map shows risk assessment chip

---

## Setup Instructions (15 minutes)

### Step 1: Google Maps API Key Configuration (5 minutes)

#### Get API Keys
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create project "WildFire MVP" (or use existing)
3. Enable **Maps SDK for Android** and **Maps SDK for iOS**
4. Create API keys:
   - **Android Key**: Restrict by application (SHA-1 fingerprint)
   - **iOS Key**: Restrict by bundle ID (`com.wildfire.mvp`)

#### Configure Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<manifest ...>
  <application ...>
    <!-- Add inside <application> tag -->
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="${GOOGLE_MAPS_API_KEY_ANDROID}" />
  </application>
</manifest>
```

#### Configure iOS (`ios/Runner/AppDelegate.swift`)
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey(ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY_IOS"] ?? "")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### Set Environment Variables (`.env`)
```bash
# Never commit this file!
GOOGLE_MAPS_API_KEY_ANDROID=AIzaSyD...
GOOGLE_MAPS_API_KEY_IOS=AIzaSyD...
```

**Verification**:
```bash
flutter run -d ios --dart-define-from-file=.env
# Map should load without "Google Maps API key missing" error
```

---

### Step 2: Verify Dependencies (2 minutes)

Check `pubspec.yaml` includes:
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  go_router: ^14.8.1
  http: ^1.1.0
  dartz: ^0.10.1
  equatable: ^2.0.5
  flutter_bloc: ^8.1.3
  shared_preferences: ^2.2.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
```

**Install**:
```bash
flutter pub get
```

**Verify**:
```bash
flutter pub deps | grep google_maps_flutter
# Should show: google_maps_flutter 2.5.0
```

---

### Step 3: Run Integration Tests (3 minutes)

```bash
# Run all A10 tests (mocked by default)
flutter test test/integration/map/

# Expected output:
# ✓ Map loads with mock data
# ✓ Markers render with source labels
# ✓ Fallback chain works (EFFIS → SEPA → Cache → Mock)
# ✓ Risk assessment shows correct FWI values
# ✓ Accessibility: controls ≥44dp, semantic labels present
```

**If tests fail**:
- Check dependencies: `flutter pub get`
- Verify mocks: `test/mocks.dart` should have `MockFireLocationService`
- Check logs: `flutter test --verbose`

---

### Step 4: Run App with Live Data (5 minutes)

```bash
# Enable live EFFIS API calls
flutter run -d macos --dart-define=MAP_LIVE_DATA=true --dart-define-from-file=.env

# Expected behavior:
# 1. Map loads with user location (or Scotland default)
# 2. Fire markers appear from EFFIS WFS API (if any in visible region)
# 3. Source label shows "EFFIS" (live) or "Cache" (if recent fetch)
# 4. Long-press map → "Check risk here" → shows FWI chip
```

**Troubleshooting**:
- **No markers**: EFFIS may have no fires in visible region (zoom out or pan to active fire areas)
- **"Mock" label**: MAP_LIVE_DATA not set or EFFIS API failed (check logs)
- **Timeout**: Check network connection, EFFIS endpoint may be slow (fallback to cache/mock)

---

## Acceptance Test Scenarios

### Scenario 1: Initial Map Load (FR-009: ≤3s)
```
GIVEN: User has GPS permission enabled
WHEN: User navigates to MapScreen
THEN:
  - Map renders within 3 seconds
  - User location centered on map
  - Fire markers visible (if any in region)
  - Source label shows "EFFIS" or "Cache" or "Mock"
  - Timestamp shows "Updated X minutes ago"
```

**Manual Test**:
1. Open app → tap "Map" button
2. Start timer when navigation begins
3. Stop timer when map interactive
4. **PASS**: Timer < 3s, markers visible

---

### Scenario 2: Marker Tap (FR-005: Show details)
```
GIVEN: Map displaying fire markers
WHEN: User taps any fire marker
THEN:
  - Info window appears above marker
  - Shows: Source (EFFIS/SEPA/Cache/Mock), Timestamp, Intensity
  - Info window has ≥44dp touch target
  - Semantic label present for screen readers
```

**Manual Test**:
1. Tap fire marker
2. Verify info window appears
3. Check semantic label: `flutter run --verbose` → look for "Semantics" logs
4. **PASS**: Info displays, accessible

---

### Scenario 3: Risk Assessment (FR-006: "Check risk here")
```
GIVEN: Map is interactive
WHEN: User long-presses any location on map
THEN:
  - Risk assessment chip appears
  - Shows: FWI value, Risk level (Low/Moderate/High/VeryHigh/Extreme), Source, Timestamp
  - Chip has ≥44dp height
  - Semantic label: "Fire risk at this location: {level}"
```

**Manual Test**:
1. Long-press map (hold 1 second)
2. Verify chip appears with risk info
3. Check source label (EFFIS/SEPA/Cache/Mock)
4. **PASS**: Chip displays, correct FWI mapping

---

### Scenario 4: GPS Denied Fallback (FR-016: Function without GPS)
```
GIVEN: User has denied GPS permission
WHEN: User navigates to MapScreen
THEN:
  - Map centers on Scotland default (57.2, -3.8)
  - Fire markers still display
  - Manual location button visible
  - App does not crash
```

**Manual Test**:
1. System Settings → App Permissions → Disable Location
2. Open app → navigate to Map
3. Verify Scotland center, no crash
4. **PASS**: Graceful degradation

---

### Scenario 5: Service Fallback Chain (FR-004: 4-tier fallback)
```
GIVEN: EFFIS API is unavailable (simulate with network off)
WHEN: User loads map
THEN:
  - System tries EFFIS (8s timeout)
  - Falls back to SEPA (if Scotland)
  - Falls back to Cache (if available)
  - Falls back to Mock (never fails)
  - UI shows appropriate source label
  - No blank map or crash
```

**Manual Test**:
1. Turn off Wi-Fi/cellular
2. Open app → navigate to Map
3. Wait for timeout (~10s)
4. Verify mock markers appear with "Mock" label
5. **PASS**: Never fails, mock data displays

---

### Scenario 6: Performance ≤50 Markers (FR-010: No jank)
```
GIVEN: Map displaying 50 fire markers
WHEN: User pans and zooms map
THEN:
  - Frame rate stays ≥60fps
  - No stuttering or lag
  - Markers render smoothly
```

**Manual Test**:
1. Pan to region with many fires (or mock 50 markers in test)
2. Quickly pan/zoom map
3. Observe frame rate (use Flutter DevTools)
4. **PASS**: No visible jank

---

### Scenario 7: Memory Usage (FR-011: ≤75MB)
```
GIVEN: Map with 50 markers loaded
WHEN: User interacts with map for 1 minute
THEN:
  - Memory usage ≤75MB
  - No memory leaks
```

**Manual Test**:
1. Run app in Profile mode: `flutter run --profile`
2. Open DevTools → Memory tab
3. Load map → wait 1 minute
4. Check heap size
5. **PASS**: Δ memory < 75MB

---

## Debugging Tips

### Issue: Map won't load
**Symptoms**: Blank screen, "Google Maps API key missing" error  
**Fix**:
1. Check `.env` file has correct keys
2. Verify `--dart-define-from-file=.env` in run command
3. Check `AndroidManifest.xml` and `AppDelegate.swift` configuration
4. Rebuild: `flutter clean && flutter pub get && flutter run`

---

### Issue: No fire markers
**Symptoms**: Map loads but no markers visible  
**Fix**:
1. Check MAP_LIVE_DATA flag: `--dart-define=MAP_LIVE_DATA=true`
2. Verify EFFIS API reachable: `curl https://ies-ows.jrc.ec.europa.eu/wfs`
3. Check logs: `flutter run --verbose` → look for "EFFIS_SUCCESS" or "CACHE_HIT"
4. Pan to known fire region (or zoom out to see more area)

---

### Issue: Performance issues
**Symptoms**: Jank, stuttering, slow map interactions  
**Fix**:
1. Check marker count: `_controller.state.incidents.length` (should be ≤50)
2. Profile mode: `flutter run --profile` → DevTools → Performance tab
3. Check for synchronous blocking: All API calls should be async
4. Verify debounce working: Camera idle should wait 1s before refresh

---

### Issue: Coordinates in logs
**Symptoms**: Full precision coordinates (55.953252, -3.188267) in logs  
**Fix**:
1. Check all logging uses `LocationUtils.logRedact(lat, lon)`
2. Run constitution gate: `./.specify/scripts/bash/constitution-gates.sh`
3. Search codebase: `grep -r "latitude\|longitude" lib/` (should only see redacted calls)

---

## Next Steps

After completing quickstart:
1. ✅ **Commit working feature**: `git add . && git commit -m "Complete A10: Google Maps MVP"`
2. 🚀 **Open PR**: Compare against `main`, verify CI gates pass
3. 📊 **Monitor metrics**: Check Google Maps API usage (stay under free tier)
4. 🔄 **Iterate**: Gather user feedback, plan A11 enhancements (clustering, polygons)

---

## Support & Resources

- **Google Maps Flutter Docs**: https://pub.dev/packages/google_maps_flutter
- **EFFIS WFS API Docs**: https://effis.jrc.ec.europa.eu/about-effis/technical-background/
- **Constitution**: `.specify/memory/constitution.md`
- **Data Sources**: `docs/DATA-SOURCES.md`
- **Issue Tracker**: GitHub Issues with label `A10-google-maps`

---

**Quickstart Version**: 1.0  
**Last Updated**: October 19, 2025  
**Status**: Ready for validation
