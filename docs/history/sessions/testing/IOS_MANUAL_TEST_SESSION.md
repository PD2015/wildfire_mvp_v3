# iOS Manual Testing Session - A10 Map MVP

**Test Date**: 2025-10-19  
**Platform**: iOS Simulator (iPhone 16e)  
**Test Environment**: `--dart-define=MAP_LIVE_DATA=false` (Mock data)  
**Tester**: Liz Stevenson  
**App Status**: ✅ Launched successfully

## Launch Verification

### ✅ App Launch
- **Status**: PASSED
- **Evidence**: 
  ```
  flutter: 🔍 EFFIS direct test SUCCESS: FWI=28.343298, Risk=RiskLevel.high
  flutter: Location resolved via default: 57.20,-3.80
  flutter: Total location resolution time: 11ms
  ```
- **Notes**: App launches cleanly with no errors, EFFIS service operational

---

## Test Phase 1: Home Screen (Existing A1-A9 Features)

### Test 1.1: Risk Banner Display
**What to check**: Look for the risk banner at the top of the home screen

- [ ] Risk banner is visible
- [ ] Risk level shows "HIGH" (red/orange color)
- [ ] FWI value displays "28.3" or similar
- [ ] Risk banner uses accessible colors (sufficient contrast)

**Instructions**: On the iPhone 16e simulator, observe the top section of the home screen.

**Screenshot location** (optional): `screenshots/ios_home_risk_banner.png`

---

### Test 1.2: Location Display
**What to check**: Verify location information is shown

- [ ] Location coordinates visible (57.20, -3.80 - Aviemore)
- [ ] Location text is readable
- [ ] No raw GPS coordinates shown (privacy C2 compliance)

---

### Test 1.3: View Map Button
**What to check**: Navigation button to map screen

- [ ] "View Map" button is visible
- [ ] Button is ≥44dp touch target (iOS accessibility)
- [ ] Button has clear label/icon

**Action**: Tap the "View Map" button to proceed to Phase 2

---

## Test Phase 2: Map Screen Display (T014)

### Test 2.1: Map Widget Rendering
**What to check**: Verify Google Maps widget loads correctly

- [ ] GoogleMap widget renders (should see map tiles)
- [ ] Map centers on Scotland region (Aviemore area: 57.20, -3.80)
- [ ] Initial zoom level shows regional view (~zoom level 8)
- [ ] Map tiles load without errors
- [ ] No console errors in debug output

**Expected visual**: Map should show Scotland with Aviemore roughly centered

---

### Test 2.2: Map Controls
**What to check**: Verify native map controls are accessible

- [ ] Zoom in button (+) visible and functional
- [ ] Zoom out button (-) visible and functional
- [ ] Buttons are ≥44dp touch target
- [ ] Pan gesture works (drag map with finger/cursor)
- [ ] Pinch-to-zoom works (if using trackpad gestures)

**Actions**: 
1. Tap zoom in button → map should zoom closer
2. Tap zoom out button → map should zoom farther
3. Drag map → map should pan to new location

---

### Test 2.3: Fire Markers Display (T014)
**What to check**: Verify mock fire incidents appear as markers

**Expected**: 3 mock fire markers from `assets/mock/active_fires.json`

- [ ] Edinburgh marker visible (55.9533, -3.1883) - moderate intensity 🟠
- [ ] Glasgow marker visible (55.8642, -4.2518) - low intensity 🟡
- [ ] Aviemore marker visible (57.2, -3.8) - high intensity 🔴

**Visual check**:
- [ ] Markers use distinct colors based on intensity
- [ ] Markers are clearly visible on map
- [ ] Marker icons are appropriate size (not too small/large)

**Actions**: Note the number and positions of visible markers

---

### Test 2.4: Marker Info Windows (T014)
**What to check**: Verify marker tap shows info window

**Action 1**: Tap Edinburgh marker (southeast of center)
- [ ] Info window appears
- [ ] Title shows "Fire Incident" or similar
- [ ] Snippet shows intensity: "MODERATE - mock"
- [ ] Info window is readable
- [ ] Close button works (tap X or tap elsewhere)

**Action 2**: Tap Glasgow marker (west of center)
- [ ] Info window shows "LOW - mock"

**Action 3**: Tap Aviemore marker (near center)
- [ ] Info window shows "HIGH - mock"

---

## Test Phase 3: Map UI Components (T014-T015)

### Test 3.1: Map Source Chip (C4 Transparency)
**What to check**: Look for data source indicator chip at top of map

- [ ] Chip is visible (top of screen)
- [ ] Shows "MOCK" label
- [ ] Science icon (🔬) or similar displayed
- [ ] Blue/gray color indicating mock data
- [ ] Timestamp shows "Just now" or relative time (e.g., "2 min ago")
- [ ] Text is readable with sufficient contrast

**Purpose**: C4 constitutional compliance - users must know data source

---

### Test 3.2: Risk Check Button (T015)
**What to check**: FloatingActionButton for risk assessment

- [ ] FAB visible (typically bottom-right corner)
- [ ] Fire icon (🔥) or similar displayed
- [ ] Button is ≥44dp touch target (iOS requirement)
- [ ] Button has semantic label "Check fire risk at this location" (screen reader)
- [ ] Button color matches app theme (Scottish palette)

**Accessibility check**: 
- Size should be at least 44x44 logical pixels
- Color contrast should meet WCAG AA standards

---

### Test 3.3: Risk Check Flow (T015)
**What to check**: Tap FAB to trigger risk assessment

**Action**: Tap the Risk Check Button (FAB)

**Expected sequence**:
1. [ ] Loading indicator appears immediately
2. [ ] Loading spinner has semantic label "Loading risk data"
3. [ ] Bottom sheet modal opens after ~1-2 seconds
4. [ ] Bottom sheet is semi-transparent with rounded corners

---

### Test 3.4: Risk Result Display (T015)
**What to check**: Bottom sheet shows risk assessment

- [ ] Risk level displayed prominently: "HIGH"
- [ ] Background color matches risk level (red/orange for HIGH)
- [ ] FWI value shown: "FWI: 28.3" or similar
- [ ] Data source label: "EFFIS" or "MOCK" with icon
- [ ] Timestamp in UTC format (ISO-8601): "2025-10-19T14:30:00Z"
- [ ] Location coordinates: "57.20, -3.80"
- [ ] All text is readable with sufficient contrast
- [ ] Close button or gesture dismisses bottom sheet

**Purpose**: C4 transparency - complete risk data with source and timestamp

---

## Test Phase 4: Loading & Error States (T014)

### Test 4.1: Loading State
**What to check**: Initial map load behavior

**Note**: You may have already seen this when map first loaded

- [ ] CircularProgressIndicator appears during initial load
- [ ] Spinner is centered on screen
- [ ] Semantic label: "Loading map data" (for screen readers)
- [ ] No frozen UI during loading
- [ ] Loading completes within 3-5 seconds

---

### Test 4.2: Empty State
**What to check**: Map behavior when no fires in region

**Action**: Pan map away from Scotland (e.g., zoom out and pan to London/England)

**Expected**:
- [ ] Map still renders (no crash)
- [ ] No markers visible in non-Scotland regions
- [ ] Optional: Card overlay shows "No active fires detected in this region"
- [ ] UI remains responsive

**Note**: With mock data, fires only appear in Scotland bbox

---

### Test 4.3: Error State (Simulated)
**What to check**: Error handling when map fails to load

**Note**: This is hard to simulate with mock data, but check:

- [ ] If any errors appear, there's a user-friendly message
- [ ] Error icon displayed (not technical stack trace)
- [ ] Retry button is ≥44dp (if shown)
- [ ] App doesn't crash on errors

---

## Test Phase 5: Accessibility Testing (C3 Compliance)

### Test 5.1: Touch Target Sizes
**What to check**: All interactive elements meet iOS 44dp minimum

- [ ] "View Map" button on HomeScreen ≥44dp
- [ ] Risk Check FAB ≥44dp
- [ ] Zoom in/out buttons ≥44dp (native controls)
- [ ] Marker tap targets are reasonable size
- [ ] Close buttons on modals ≥44dp

**How to verify**: Visual inspection + actual tap testing

---

### Test 5.2: Color Contrast
**What to check**: Text readable against backgrounds

- [ ] Risk banner text readable (HIGH on red/orange)
- [ ] Map source chip text readable
- [ ] Risk result bottom sheet text readable
- [ ] Button labels have sufficient contrast

**Standard**: WCAG AA (4.5:1 for normal text, 3:1 for large text)

---

### Test 5.3: Screen Reader Support (Optional)
**What to check**: VoiceOver compatibility

**Note**: Only test if you have VoiceOver enabled

- [ ] "View Map" button announces correctly
- [ ] Risk Check FAB announces "Check fire risk at this location"
- [ ] Loading spinners have descriptive labels
- [ ] Risk result content is readable by VoiceOver

**How to test**: Enable VoiceOver in iOS Settings > Accessibility

---

## Test Phase 6: Performance & Stability

### Test 6.1: Map Performance
**What to check**: Smooth interaction without lag

- [ ] Map panning is smooth (no stuttering)
- [ ] Zoom animations are fluid
- [ ] Marker rendering doesn't cause lag
- [ ] No memory warnings in console
- [ ] App remains responsive throughout testing

---

### Test 6.2: Battery & Resource Usage (Optional)
**What to check**: Reasonable resource consumption

- [ ] Simulator doesn't become unresponsive
- [ ] No excessive CPU warnings in Xcode
- [ ] Memory usage stays reasonable (<100MB for MVP)

**Note**: These are informal checks, not precise benchmarks

---

## Test Results Summary

### Overall Status: [ ] PASS / [ ] FAIL / [ ] PARTIAL

**Tests Passed**: _____ / 30 total checks

**Critical Issues Found**: 
- (List any blocking issues that prevent app usage)

**Minor Issues Found**:
- (List cosmetic or non-critical issues)

**Notes**:
- (Additional observations or context)

---

## Next Steps

### If All Tests Pass ✅
1. Update `docs/VISUAL_TEST_RESULTS.md` with "PASSED" status
2. Commit test results: `git commit -m "test(ios): complete manual visual testing checklist"`
3. Proceed to TODO #1: Test with `MAP_LIVE_DATA=true` (live EFFIS data)
4. Consider unskipping integration tests in `test/widget/map_screen_test.dart`

### If Tests Fail ❌
1. Document specific failures in "Critical Issues Found" section
2. Create GitHub issues for each blocking problem
3. Fix issues before proceeding to live data testing
4. Re-run failed tests after fixes

---

## Testing Tips

**Simulator Controls**:
- **Rotate device**: Cmd + Arrow keys
- **Take screenshot**: Cmd + S (saves to Desktop)
- **Home button**: Cmd + Shift + H
- **Shake gesture**: Device > Shake

**Flutter DevTools**:
- Open at: http://127.0.0.1:9101
- Use Widget Inspector to debug UI issues
- Use Performance tab to check frame rates

**Hot Reload**:
- Press `r` in terminal to hot reload changes
- Press `R` to hot restart app completely

---

## Screenshots (Optional)

Save screenshots to `docs/screenshots/ios_manual_test/`:
1. `home_screen_risk_banner.png` - Home screen with HIGH risk
2. `map_initial_load.png` - Map centered on Aviemore
3. `map_with_markers.png` - All 3 mock fire markers visible
4. `marker_info_window.png` - Tapped marker showing details
5. `source_chip.png` - MOCK data source chip
6. `risk_check_fab.png` - Risk Check button visible
7. `risk_result_modal.png` - Bottom sheet with risk assessment

**Screenshot command** (in terminal while app running):
```bash
xcrun simctl io booted screenshot ~/Desktop/screenshot_$(date +%s).png
```
