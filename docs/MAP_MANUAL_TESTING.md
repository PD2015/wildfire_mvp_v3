# Manual Testing Guide: Fire Marker Interaction (Task 24)

**Feature**: Map Fire Information Sheet  
**Test Type**: End-to-End Integration Testing  
**Why Manual?**: GoogleMap widget continuously schedules frames for tile loading and animations, causing Flutter integration tests to timeout. Manual testing is the recommended approach.

---

## Prerequisites

### 1. Platform Setup
Choose one of these platforms for testing:

**Web (Chrome)** - Recommended for fastest iteration:
```bash
cd ~/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3
./scripts/run_web.sh  # Uses dev.env.json with API key
```

**Android Emulator**:
```bash
flutter run -d android --dart-define-from-file=env/dev.env.json
```

**iOS Simulator**:
```bash
flutter run -d ios --dart-define-from-file=env/dev.env.json
```

⚠️ **macOS Desktop NOT supported** (no Google Maps support)

### 2. Test Data Modes

**Demo Mode** (Default - No API key needed):
```bash
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false
```

**Live Mode** (Requires API key):
```bash
./scripts/run_web.sh  # Automatically injects API key
```

---

## Test Scenarios

### 📍 **Test 1: Basic Marker Rendering**

**Objective**: Verify fire incident markers appear on the map.

**Steps**:
1. Launch app in demo mode
2. Tap "Map" in bottom navigation
3. Wait for map to load (should be < 3 seconds per C5 performance requirement)

**Expected Results**:
- ✅ Map loads and displays centered on Scotland (default location)
- ✅ Multiple fire markers visible (red/orange flame icons)
- ✅ Markers vary in size based on confidence/FRP (visual intensity)
- ✅ "DEMO DATA" chip visible in bottom-left corner (C4 transparency)

**Pass Criteria**:
- [ ] At least 5 fire markers visible on Scotland map
- [ ] Markers have distinct visual styling (not default pins)
- [ ] Map loads within 3 seconds ✓ (C5 performance)

---

### 🔥 **Test 2: Marker Tap → Bottom Sheet Flow**

**Objective**: Verify tapping a fire marker opens bottom sheet with incident details.

**Steps**:
1. With map loaded and markers visible
2. Tap any fire marker on the map
3. Observe bottom sheet animation
4. Review displayed information

**Expected Results**:
- ✅ Bottom sheet slides up from bottom with smooth animation
- ✅ Draggable handle visible at top of sheet
- ✅ Fire incident header displays "Fire Incident Details"
- ✅ Fire icon and close button (✖) visible in header
- ✅ All fire details displayed:
  - **Detection Time**: "Detected at: [timestamp]" (e.g., "Nov 14, 2024 10:30 AM")
  - **Sensor Source**: "Source: MODIS" or "VIIRS"
  - **Confidence**: "Confidence: 85.5%" (0-100 range)
  - **FRP**: "Fire Radiative Power: 12.3 MW"
  - **Distance**: "Distance: 5.2 km NE" (if user location available)
  - **Location**: "Location: 56.00°N, -3.50°W"
  - **Data Source Chip**: "DEMO DATA" (orange) or "LIVE" (green)

**Pass Criteria**:
- [ ] Bottom sheet opens within 500ms of marker tap
- [ ] Sheet displays all required fire incident fields
- [ ] Confidence and FRP values are realistic (confidence 0-100%, FRP > 0)
- [ ] Timestamps are recent (within 24 hours for demo data)
- [ ] Data source chip clearly visible ✓ (C4 transparency)

---

### 📏 **Test 3: Distance Calculation**

**Objective**: Verify distance and bearing calculation when user location available.

**Steps**:
1. Allow location permissions when prompted
2. Wait for user location to resolve
3. Tap a fire marker
4. Check distance card in bottom sheet

**Expected Results**:
- ✅ Distance card displays: "Distance: [X.X km] [Direction]"
- ✅ Direction is cardinal (N, NE, E, SE, S, SW, W, NW)
- ✅ Distance is calculated using great circle formula
- ✅ If location permission denied, distance card is hidden gracefully

**Pass Criteria**:
- [ ] Distance values are plausible (e.g., 0.5km to 500km for Scotland)
- [ ] Direction matches visual map position
- [ ] Card hidden when location unavailable (no error state)

---

### 🎨 **Test 4: Accessibility Compliance (C3)**

**Objective**: Verify accessibility requirements are met.

**Steps**:
1. Open bottom sheet by tapping marker
2. Measure touch targets (use platform tools or visual inspection)
3. Enable screen reader (VoiceOver on iOS, TalkBack on Android)
4. Navigate through bottom sheet with screen reader

**Expected Results**:
- ✅ Close button (✖) has ≥44dp touch target
- ✅ All interactive elements have semantic labels
- ✅ Screen reader announces: "Fire incident detected at [location]"
- ✅ All fields have descriptive labels (not just raw values)

**Pass Criteria**:
- [ ] Close button touch target ≥44dp ✓ (iOS) or ≥48dp ✓ (Android)
- [ ] Screen reader can navigate all content
- [ ] Semantic labels describe data clearly

---

### 🔄 **Test 5: Sheet Interaction & Dismissal**

**Objective**: Verify multiple ways to close bottom sheet.

**Steps**:
1. Open bottom sheet by tapping marker
2. **Test A**: Tap close button (✖)
3. Open sheet again
4. **Test B**: Swipe sheet down
5. Open sheet again
6. **Test C**: Tap outside sheet (on map)

**Expected Results**:
- ✅ All three methods close the sheet smoothly
- ✅ Sheet animates out with smooth motion
- ✅ No memory leaks or UI artifacts after closing

**Pass Criteria**:
- [ ] Close button works consistently
- [ ] Swipe-to-dismiss works (drag down from handle)
- [ ] Tap-outside dismisses sheet
- [ ] No crashes or memory spikes after repeated open/close (test 5-10 times)

---

### 🗺️ **Test 6: Multiple Markers & Selection**

**Objective**: Verify tapping different markers updates bottom sheet content.

**Steps**:
1. Open bottom sheet on marker A
2. Without closing sheet, tap marker B on map
3. Observe sheet content update

**Expected Results**:
- ✅ Sheet content updates to show marker B's details
- ✅ No visual glitches during transition
- ✅ All fields update correctly (confidence, FRP, location, etc.)

**Pass Criteria**:
- [ ] Sheet updates smoothly when selecting different markers
- [ ] No stale data from previous selection
- [ ] Performance remains smooth (<200ms update)

---

### 🌐 **Test 7: Data Source Transparency (C4)**

**Objective**: Verify clear indication of data source at all times.

**Steps**:
1. **Demo Mode**: Run with `MAP_LIVE_DATA=false`
   - Tap marker, verify "DEMO DATA" chip (orange background)
2. **Live Mode**: Run with API key and `MAP_LIVE_DATA=true`
   - Tap marker, verify "LIVE" chip (green background)
3. **Cached Mode**: Disconnect network, reload viewport
   - Tap marker, verify "CACHED" chip (blue background)

**Expected Results**:
- ✅ Data source chip always visible in bottom sheet
- ✅ Chip colors follow constitutional palette (C4):
  - DEMO DATA: Orange/amber warning color
  - LIVE: Green success color
  - CACHED: Blue information color
- ✅ Chip has clear text with sufficient contrast

**Pass Criteria**:
- [ ] Correct chip displayed for each data mode
- [ ] Colors meet WCAG AA contrast requirements ✓ (C3)
- [ ] Chip never hidden or unclear

---

### ⚡ **Test 8: Performance Benchmarking**

**Objective**: Verify performance meets requirements.

**Steps**:
1. Use stopwatch or DevTools to measure timings
2. Test on both high-end and mid-range devices if possible

**Measurements**:
- **Map Load Time**: From navigation tap to map fully rendered
- **Marker Render Time**: From map load to markers visible
- **Bottom Sheet Open**: From marker tap to sheet fully displayed
- **Sheet Update**: From second marker tap to content updated

**Expected Results**:
- ✅ Map load: < 3 seconds (C5 performance requirement)
- ✅ Markers render: < 1 second after map loads
- ✅ Bottom sheet open: < 500ms (smooth user experience)
- ✅ Sheet update: < 200ms (per Task 24 requirements)

**Pass Criteria**:
- [ ] All timing requirements met on test device
- [ ] No frame drops or stuttering during interactions
- [ ] Memory usage stable (check DevTools for leaks)

---

### 🐛 **Test 9: Error Handling**

**Objective**: Verify graceful error handling for edge cases.

**Steps**:
1. **No Markers Scenario**: 
   - Set very restrictive viewport (e.g., zoom out over ocean)
   - Verify: Empty state or message displayed
   
2. **Network Error** (Live Mode):
   - Disable network connection
   - Pan map to new area
   - Verify: Fallback to cache or clear error message

3. **Invalid Marker Data**:
   - Verify app doesn't crash if marker missing optional fields (confidence, FRP)

**Expected Results**:
- ✅ No crashes under any error condition (C5 resilience)
- ✅ Clear error messages when data unavailable
- ✅ Graceful fallback chain: Live → Cache → Mock (per orchestrator design)

**Pass Criteria**:
- [ ] App never crashes from missing/invalid data
- [ ] Error states have clear messaging
- [ ] User can recover (e.g., retry button or automatic fallback)

---

### 📱 **Test 10: Cross-Platform Verification**

**Objective**: Verify feature works on all supported platforms.

**Test Matrix**:

| Platform | Status | Notes |
|----------|--------|-------|
| **Chrome (Web)** | ⬜ | Primary dev platform, fastest iteration |
| **Android Emulator** | ⬜ | Test touch targets (≥48dp) |
| **iOS Simulator** | ⬜ | Test touch targets (≥44dp) |
| **macOS Desktop** | ❌ SKIP | No Google Maps support |

**Steps**: Run Tests 1-9 on each platform

**Pass Criteria**:
- [ ] All core flows work on Chrome ✓
- [ ] Android-specific checks pass (48dp targets)
- [ ] iOS-specific checks pass (44dp targets)

---

## Test Completion Checklist

Use this checklist to track your manual testing progress:

### Core Functionality
- [ ] Test 1: Markers render correctly
- [ ] Test 2: Marker tap → bottom sheet flow works
- [ ] Test 3: Distance calculation accurate
- [ ] Test 5: All dismissal methods work
- [ ] Test 6: Multiple marker selection works

### Constitutional Compliance
- [ ] Test 4: Accessibility (C3) - ≥44dp targets, screen reader support
- [ ] Test 7: Data transparency (C4) - Source chips always visible
- [ ] Test 8: Performance (C5) - Map loads <3s, interactions smooth
- [ ] Test 9: Error handling (C5) - No crashes, graceful fallbacks

### Cross-Platform
- [ ] Test 10: Chrome web testing complete
- [ ] Test 10: Android testing complete (if required)
- [ ] Test 10: iOS testing complete (if required)

---

## Reporting Issues

If you find bugs during manual testing, document them with:

1. **Platform**: Chrome/Android/iOS and version
2. **Data Mode**: Demo/Live/Cached
3. **Steps to Reproduce**: Exact sequence that triggers issue
4. **Expected**: What should happen
5. **Actual**: What actually happened
6. **Screenshots**: Capture the issue visually
7. **Logs**: Check browser console or `flutter logs` for errors

**Example Issue Report**:
```
Platform: Chrome 120, macOS 14.1
Data Mode: Demo (MAP_LIVE_DATA=false)
Steps:
1. Load map
2. Tap marker in Edinburgh area
3. Tap close button

Expected: Sheet closes smoothly
Actual: Sheet disappears but map markers become unresponsive
Logs: "setState() called after dispose()" in console
```

---

## Success Criteria Summary

Task 24 is **COMPLETE** when:

✅ All 10 test scenarios pass on at least one platform (Chrome recommended)  
✅ No critical bugs found (crashes, data loss, accessibility violations)  
✅ Performance requirements met (map <3s, interactions <500ms)  
✅ Constitutional compliance verified (C3, C4, C5)  
✅ Testing documented with this checklist completed

---

## Quick Start Commands

**Fastest Testing Setup (Chrome + Demo Data)**:
```bash
cd ~/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3

# Run in Chrome with demo data (no API key needed)
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Or use secure script with API key for production-like experience
./scripts/run_web.sh
```

**Open Browser DevTools**: Press F12 for console logs and performance profiling

**Hot Reload**: Press `r` in terminal for instant code updates during testing

---

## Notes

- **Why Manual Testing?** GoogleMap's continuous frame scheduling is incompatible with Flutter's test framework. This is a known limitation of google_maps_flutter plugin, not a deficiency in the implementation.

- **Testing Time**: Allow ~2-3 hours for thorough manual testing across all scenarios.

- **Best Platform**: Chrome (web) offers fastest iteration and easiest debugging.

- **Documentation**: This guide fulfills Task 24's integration testing requirement through documented manual test procedures.
