# Map Screen Manual Testing Guide

**Status**: Required for Map Integration Tests  
**Last Updated**: 2025-10-20  
**Reason**: GoogleMap widget incompatible with Flutter integration test framework

---

## Why Manual Testing is Required

GoogleMap integration tests **cannot** be automated with Flutter's `integration_test` framework due to a fundamental architecture incompatibility:

### Technical Explanation

**Problem**: GoogleMap continuously schedules rendering frames for:
- Tile loading and rendering
- Camera animations (pan, zoom, tilt)
- Marker updates and clustering
- User interaction feedback

**Flutter Test Framework Expectation**: All animations and frames must eventually settle before test completes. The framework checks `_pendingFrame == null` at test end.

**GoogleMap Reality**: As a platform view (native Android/iOS component), GoogleMap **never stops scheduling frames** while visible, causing tests to timeout with:
```
TimeoutException after 0:02:00.000000
'_pendingFrame == null': is not true
```

**Attempted Solutions (All Failed)**:
- ❌ Using `pump()` instead of `pumpAndSettle()` - GoogleMap still schedules new frames
- ❌ Adding frame delays - Doesn't prevent continuous rendering
- ❌ Overriding test bindings - Too invasive, breaks other tests

**Conclusion**: GoogleMap integration testing requires manual verification or end-to-end testing outside Flutter's test framework (e.g., Appium, Maestro).

---

## Manual Test Procedures

### Prerequisites

1. **Device/Emulator Required**: Map tests MUST run on real device or emulator
   ```bash
   # List available devices
   flutter devices
   
   # Android emulator
   flutter run -d emulator-5554 --dart-define=MAP_LIVE_DATA=false
   
   # iOS simulator
   flutter run -d iphone --dart-define=MAP_LIVE_DATA=false
   
   # Chrome (Web)
   ./scripts/run_web.sh  # Secure script with API key injection
   ```

2. **API Key Configuration**: Ensure Google Maps API keys are configured
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`
   - Web: `web/index.html` (injected via `run_web.sh`)
   
   See: `docs/GOOGLE_MAPS_SETUP.md` for setup instructions

3. **Data Source**: Choose demo data or live EFFIS data
   ```bash
   # Demo data (3 mock fire incidents near Aviemore)
   flutter run --dart-define=MAP_LIVE_DATA=false
   
   # Live EFFIS data (real fire locations in Europe)
   flutter run --dart-define=MAP_LIVE_DATA=true
   ```

4. **Platform Limitations**:
   - ❌ **macOS Desktop**: NOT supported (no Google Maps plugin)
   - ✅ **macOS Web (Chrome/Safari)**: Supported via `google_maps_flutter_web`
   - ✅ Android: Full support
   - ✅ iOS: Full support

---

## Test Cases

### T034: GoogleMap Renders with Fire Markers

**Objective**: Verify GoogleMap widget loads and displays fire incident markers

**Steps**:
1. Launch app on device/emulator
2. Wait for home screen to load (~2-5 seconds)
3. Tap "Map" navigation button (bottom navigation bar)
4. Observe map screen

**Expected Results**:
- ✅ GoogleMap renders within 3 seconds (T035 performance requirement)
- ✅ Map tiles load and display (satellite/terrain view)
- ✅ Fire incident markers visible on map
  - **Demo data**: 3 red flame markers near Aviemore, Scotland
  - **Live data**: Variable count, depends on active fires in Europe
- ✅ Map is interactive (can pan, zoom, tilt)

**Acceptance Criteria**:
- GoogleMap widget renders successfully
- At least 1 fire marker visible (for demo data: exactly 3)
- Map tiles load without errors
- No blank/grey map tiles

**Common Issues**:
- ❌ Blank map with "For development purposes only" watermark → API key not configured or restricted
- ❌ Grey tiles → Network error or incorrect API key restrictions
- ❌ No markers → Check MAP_LIVE_DATA setting and data source

---

### T035: Map Performance - Loads Within 3 Seconds

**Objective**: Verify map loads and becomes interactive within 3 seconds (C5 performance requirement)

**Steps**:
1. Launch app on device/emulator
2. Wait for home screen to load
3. Start timer
4. Tap "Map" navigation button
5. Stop timer when map is fully rendered and interactive

**Expected Results**:
- ✅ Map visible within 3 seconds from navigation tap
- ✅ Map tiles start loading immediately
- ✅ Markers appear within 3 seconds
- ✅ Map responds to pan/zoom gestures within 3 seconds

**Acceptance Criteria**:
- Time from navigation tap to interactive map ≤ 3000ms
- No loading spinners beyond 3 seconds
- Smooth frame rate (≥30fps) during initial render

**Measurement**:
- Use device developer tools or visual inspection
- Acceptable range: 1000-3000ms (excellent), 3000-5000ms (acceptable), >5000ms (fail)

---

### C3: "Check Risk Here" FAB Touch Target ≥44dp

**Objective**: Verify floating action button meets accessibility touch target requirements

**Steps**:
1. Navigate to Map screen
2. Locate "Check risk here" FAB (bottom-right corner)
3. Visually inspect FAB size
4. Attempt to tap FAB with thumb/finger

**Expected Results**:
- ✅ FAB clearly visible in bottom-right corner
- ✅ FAB touch target ≥44dp (iOS HIG) / ≥48dp (Android Material)
- ✅ FAB responds to tap immediately
- ✅ No accidental taps on surrounding elements

**Acceptance Criteria**:
- iOS: FAB size ≥ 44x44dp
- Android: FAB size ≥ 48x48dp
- Sufficient contrast with map background
- No overlap with map controls

**Testing Aids**:
```dart
// To verify FAB size in Flutter DevTools:
// 1. Tap FAB in app
// 2. Open Flutter DevTools
// 3. Select Widget Inspector
// 4. Find FloatingActionButton widget
// 5. Check size property: Should be ≥44dp (iOS) or ≥48dp (Android)
```

---

### C4: Source Chip Displays Data Transparency

**Objective**: Verify data source is clearly visible to users (C4 transparency requirement)

**Steps**:
1. Navigate to Map screen
2. Locate source chip (top of screen, below app bar)
3. Read chip content

**Expected Results**:
- ✅ Source chip visible at top of screen
- ✅ Data source clearly labeled:
  - **Demo data**: "DEMO DATA" (orange/amber color)
  - **Live data**: "LIVE" (green color)
  - **Cached data**: "CACHED" (blue/grey color)
- ✅ "Last updated" timestamp visible in chip
- ✅ Timestamp in UTC format (e.g., "Last updated: 14:35 UTC")

**Acceptance Criteria**:
- Chip text ≥14sp font size
- Sufficient color contrast (WCAG AA minimum)
- Timestamp updates when data refreshes
- Icon matches data source (demo/live/cached)

**Example Chip Content**:
```
🔥 DEMO DATA • Last updated: 14:35 UTC
🌍 LIVE • Last updated: 14:35 UTC
💾 CACHED • Last updated: 14:35 UTC
```

---

### Interactive Verification: Pan and Zoom

**Objective**: Verify map supports pan, zoom, and tilt gestures

**Steps**:
1. Navigate to Map screen
2. Wait for map to load
3. Perform gestures:
   - **Pan**: Single finger drag across map
   - **Zoom in**: Pinch out with two fingers
   - **Zoom out**: Pinch in with two fingers
   - **Tilt** (optional): Two-finger drag up/down

**Expected Results**:
- ✅ Pan gesture moves map smoothly
- ✅ Zoom in increases map detail (zoom level 6→10)
- ✅ Zoom out decreases map detail (zoom level 10→6)
- ✅ Fire markers remain visible during gestures
- ✅ Smooth animation (≥30fps) during gestures

**Acceptance Criteria**:
- All gestures respond within 100ms
- No lag or stuttering during pan/zoom
- Markers re-render at correct positions after zoom
- Map bounds constrain to valid geographic coordinates

---

### Empty State: No Fire Incidents

**Objective**: Verify map handles gracefully when no fires in region

**Steps**:
1. **Option A**: Use test region with no fires
   ```bash
   flutter run --dart-define=TEST_REGION=no_fires
   ```
2. **Option B**: Zoom to region with no active fires (e.g., Antarctica)
3. Observe map display

**Expected Results**:
- ✅ Map renders normally (tiles load)
- ✅ No markers displayed
- ✅ Source chip still visible ("DEMO DATA" or "LIVE")
- ✅ FAB "Check risk here" still functional
- ✅ No error messages or blank screens

**Acceptance Criteria**:
- Map functional even with zero markers
- User can still interact with map (pan/zoom)
- No crashes or freezes

---

### Timestamp Visibility (C4 Transparency)

**Objective**: Verify "Last updated" timestamp is visible and accurate

**Steps**:
1. Navigate to Map screen
2. Locate source chip (top of screen)
3. Read timestamp content
4. Wait 10 seconds
5. Pull-to-refresh or re-navigate to map
6. Check if timestamp updates

**Expected Results**:
- ✅ Timestamp visible in source chip
- ✅ Format: "Last updated: HH:MM UTC"
- ✅ Timestamp matches data fetch time (±60 seconds)
- ✅ Timestamp updates when data refreshes

**Acceptance Criteria**:
- Timestamp always in UTC timezone
- Clear timezone indicator ("UTC" suffix)
- Timestamp updates on data refresh
- No placeholder text ("--:--" or "Unknown")

---

## Test Execution Checklist

Use this checklist when performing manual map tests:

```
[ ] Prerequisites
    [ ] Device/emulator running
    [ ] Google Maps API key configured
    [ ] Data source selected (demo/live)
    [ ] Platform verified (not macOS desktop)

[ ] T034: GoogleMap Renders
    [ ] Map tiles load within 3s
    [ ] Fire markers visible
    [ ] Map is interactive

[ ] T035: Performance
    [ ] Map loads ≤3s from navigation tap
    [ ] Smooth frame rate (≥30fps)

[ ] C3: FAB Touch Target
    [ ] FAB visible bottom-right
    [ ] Size ≥44dp (iOS) / ≥48dp (Android)
    [ ] Responds to tap

[ ] C4: Source Chip Transparency
    [ ] Chip visible at top
    [ ] Data source labeled (DEMO/LIVE/CACHED)
    [ ] Timestamp visible (HH:MM UTC)

[ ] Interactive Gestures
    [ ] Pan works smoothly
    [ ] Zoom in works
    [ ] Zoom out works
    [ ] Markers remain visible during gestures

[ ] Empty State
    [ ] Map renders with 0 markers
    [ ] No errors or crashes

[ ] Timestamp Verification
    [ ] Timestamp format correct (UTC)
    [ ] Updates on data refresh
```

---

## Reporting Issues

When reporting map issues during manual testing, include:

1. **Platform**: Android, iOS, or Web (specify browser)
2. **Device**: Emulator/simulator or physical device (model)
3. **Data Source**: `MAP_LIVE_DATA=true` or `false`
4. **Test Case**: Which test case failed (T034, T035, C3, C4, etc.)
5. **Expected vs Actual**: What should happen vs what actually happened
6. **Screenshots**: Capture map screen showing the issue
7. **Logs**: Run with `flutter run -v` and capture terminal output

**Example Issue Report**:
```
Platform: iOS Simulator (iPhone 15 Pro)
Device: iOS 17.0
Data Source: MAP_LIVE_DATA=false (demo data)
Test Case: T034 - GoogleMap Renders

Expected: 3 fire markers near Aviemore, Scotland
Actual: Map loads but shows 0 markers

Screenshots: [attach map_empty_state.png]
Logs: [paste relevant terminal output]
```

---

## Integration Test Status

These integration tests are **SKIPPED** in automated runs:

```dart
// integration_test/map_integration_test.dart
testWidgets('GoogleMap renders on device with fire markers visible',
    (WidgetTester tester) async {
  // SKIPPED: GoogleMap continuously schedules frames, incompatible with test framework
  // Use manual testing instead (see docs/MAP_MANUAL_TESTING.md)
  ...
}, skip: true, timeout: const Timeout(Duration(minutes: 2)));
```

**Test Suite Summary**:
- ✅ `home_integration_test.dart` - 9/9 automated tests passing
- ⏭️ `map_integration_test.dart` - 8/8 tests **SKIPPED** (manual testing required)
- ⏸️ `app_integration_test.dart` - 7/7 tests depend on map tests (partially automated)

**Total Coverage**:
- Automated: 9/24 tests (37.5%)
- Manual: 8/24 tests (33.3%)
- Combined: 17/24 tests covered (70.8%)

---

## Alternative Testing Approaches

If manual testing is insufficient, consider these alternatives:

### 1. End-to-End Testing with Patrol

[Patrol](https://patrol.leancode.co/) is a Flutter E2E testing framework that handles platform views better than `integration_test`:

```yaml
# pubspec.yaml
dev_dependencies:
  patrol: ^3.0.0
```

```dart
// test/e2e/map_test.dart
patrolTest('GoogleMap renders with markers', ($) async {
  await $.pumpWidgetAndSettle(WildfireApp());
  await $.tap(find.text('Map'));
  await $.waitUntilVisible(find.byType(GoogleMap));
  
  // Patrol handles platform views better
  expect($(find.byType(GoogleMap)), findsOneWidget);
});
```

### 2. Appium/Maestro for Cross-Platform E2E

[Maestro](https://maestro.mobile.dev/) or [Appium](https://appium.io/) can test native platform views:

```yaml
# maestro/map_test.yaml
appId: com.wildfire.mvp
---
- launchApp
- tapOn: "Map"
- assertVisible: "Check risk here"
- assertVisible:
    id: "map_container"
```

### 3. Golden File Testing for Map Layout

Test map layout and UI positioning without testing GoogleMap itself:

```dart
// test/widget/map_screen_golden_test.dart
testWidgets('Map screen layout matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MapScreen(
        // Use mock controller that doesn't render GoogleMap
        controller: MockMapController(),
      ),
    ),
  );
  
  await expectLater(
    find.byType(MapScreen),
    matchesGoldenFile('goldens/map_screen.png'),
  );
});
```

---

## Frequency and Ownership

**Test Frequency**: Manual map tests should be run:
- ✅ Before every release (required)
- ✅ When map-related code changes (recommended)
- ✅ When Google Maps API updates (recommended)
- ⏸️ During CI/CD pipeline (optional, use Patrol/Maestro)

**Ownership**:
- **QA Team**: Primary responsibility for manual testing
- **Developers**: Run tests when modifying map features
- **Release Manager**: Verify tests pass before release approval

---

## References

- **EFFIS API**: `docs/DATA-SOURCES.md`
- **Google Maps Setup**: `docs/GOOGLE_MAPS_SETUP.md`
- **Test Coverage**: `docs/TEST_COVERAGE.md`
- **Integration Test Fixes**: `docs/INTEGRATION_TEST_FIXES.md`
- **Pump Strategy (Failed)**: `docs/INTEGRATION_TEST_PUMP_STRATEGY.md`

---

## Appendix: Why pump() Strategy Failed

Previous attempts to fix GoogleMap integration tests using `pump()` instead of `pumpAndSettle()` **did not work**.

**Attempted Fix**:
```dart
// Before (timeout):
await tester.pumpAndSettle(const Duration(seconds: 5));

// After (still timeout):
await tester.pump(const Duration(seconds: 5));
await tester.pump();
```

**Why It Failed**:
1. `pumpAndSettle()` waits for animations to complete
2. `pump()` advances time but doesn't wait for animations
3. **Neither approach prevents GoogleMap from scheduling new frames**
4. Test framework checks `_pendingFrame == null` at test end
5. GoogleMap continuously schedules frames, violating this invariant

**Conclusion**: The issue is not about waiting for animations to settle. GoogleMap **never settles** because it's a continuously rendering platform view. The only solution is to skip integration tests or use external E2E frameworks (Patrol, Maestro).

**Documentation of Failed Attempt**: See `docs/INTEGRATION_TEST_PUMP_STRATEGY.md` for detailed explanation of why this approach was tried and why it didn't work.
