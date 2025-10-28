# iOS Manual Testing - Issues Summary

**Test Date**: 2025-10-19  
**Tester**: Liz Stevenson  
**Platform**: iOS Simulator (iPhone 16e)  
**Test Environment**: `--dart-define=MAP_LIVE_DATA=false` (Mock data)  
**Source**: Manual testing results from `IOS_MANUAL_TEST_SESSION.md`

---

## 🔴 Critical Issues (Must Fix Before Production)

### 1. **Home Screen Risk Banner Shows Wrong Data**
**Status**: 🔴 CRITICAL  
**Location**: HomeScreen - Risk Banner (Phase 1, Test 1.1)

**Expected**:
- Risk level: HIGH (red/orange color)
- FWI value: ~28.3
- Location: Aviemore (57.20, -3.80)

**Actual**:
- ❌ Risk level shows "LOW" with blue banner and white text
- ❌ FWI value not displayed
- ❌ Location output missing

**Evidence from logs**:
```
flutter: 🔍 EFFIS direct test SUCCESS: FWI=28.343298, Risk=RiskLevel.high
```
The EFFIS service returns HIGH (28.3), but HomeScreen displays LOW.

**Impact**: 
- **Data integrity failure**: Critical safety data mismatch
- **C4 Constitutional violation**: Users see incorrect risk assessment
- Users may make dangerous decisions based on wrong information

**Root Cause Analysis Needed**:
1. Check `HomeController` state propagation to `RiskBanner` widget
2. Verify `FireRiskService` → `HomeController` → `RiskBanner` data flow
3. Investigate if cached data is overriding EFFIS results
4. Check if banner is reading from wrong state variable

**Fix Priority**: 🔴 **P0 - Block Release**

---

### 2. **Fire Marker Intensities Reversed**
**Status**: 🔴 CRITICAL  
**Location**: MapScreen - Fire Markers (Phase 2, Test 2.3)

**Expected** (from `assets/mock/active_fires.json`):
- Edinburgh (55.9533, -3.1883): MODERATE intensity 🟠
- Glasgow (55.8642, -4.2518): LOW intensity 🟡
- Aviemore (57.2, -3.8): HIGH intensity 🔴

**Actual**:
- ✅ Edinburgh: MODERATE ✅ (Correct)
- ❌ Glasgow: Shows HIGH intensity (should be LOW)
- ❌ Aviemore: Shows LOW intensity (should be HIGH)

**Evidence from logs**:
```
flutter: 🎯 Creating marker: id=mock_fire_002, intensity="high", desc=Glasgow - Campsie Fells
flutter: 🎨 Using RED marker (high) - hue 0

flutter: 🎯 Creating marker: id=mock_fire_003, intensity="low", desc=Aviemore - Cairngorms
flutter: 🎨 Using CYAN marker (low) - hue 180
```

**Impact**:
- **Data integrity failure**: Wrong risk levels displayed to users
- **Safety concern**: HIGH risk fires shown as LOW
- **User confusion**: Marker colors don't match actual fire severity

**Root Cause Analysis Needed**:
1. Check `assets/mock/active_fires.json` - verify intensity values
2. Verify `FireIncident` model parsing from JSON
3. Check `MapController` marker creation logic
4. Investigate if intensity field is being swapped/inverted

**Fix Priority**: 🔴 **P0 - Block Release**

---

### 3. **Marker Info Windows Missing Critical Data**
**Status**: 🔴 CRITICAL  
**Location**: MapScreen - Marker Info Windows (Phase 2, Test 2.4)

**Expected**:
- Title: "Fire Incident" or fire name
- Snippet: Intensity level + source (e.g., "MODERATE - mock")

**Actual**:
- ✅ Info window appears on tap
- ❌ Title not showing expected format
- ❌ Snippet missing intensity information

**Impact**:
- **C4 Constitutional violation**: Incomplete data transparency
- Users can't identify fire severity without tapping marker
- Missing context for decision-making

**Root Cause Analysis Needed**:
1. Check `Marker` widget `infoWindow` parameter configuration
2. Verify `FireIncident` → `Marker.infoWindow` mapping
3. Ensure `title` and `snippet` properties are set correctly

**Fix Priority**: 🔴 **P0 - Block Release**

---

## 🟡 High Priority Issues (Should Fix Before Release)

### 4. **Map Centers on Edinburgh Instead of Aviemore**
**Status**: 🟡 HIGH  
**Location**: MapScreen Initial Load (Phase 2, Test 2.1)

**Expected**:
- Map centers on Aviemore (57.20, -3.80)
- Matches resolved location from logs

**Actual**:
- ❌ Map centers on Edinburgh instead

**Evidence from logs**:
```
flutter: Location resolved via default: 57.20,-3.80
flutter: 🗺️ MapController: Fetching fires for bounds: SW(55.2,-5.8) NE(59.2,-1.8)
```
Location resolves to Aviemore, but map bbox suggests Edinburgh center.

**Impact**:
- **UX inconsistency**: Map doesn't match user's location
- Users must manually pan to see their area
- Confusing initial view

**Root Cause Analysis Needed**:
1. Check `MapScreen` initial `CameraPosition` parameter
2. Verify `MapController.initialize()` sets correct center
3. Investigate if hardcoded Edinburgh coordinates exist in `MapScreen`

**Fix Priority**: 🟡 **P1 - Should Fix**

---

### 5. **Risk Check FAB Blends with Map Tiles**
**Status**: 🟡 HIGH  
**Location**: MapScreen - FloatingActionButton (Phase 3, Test 3.2)

**Expected**:
- FAB uses Scottish palette colors
- Sufficient contrast against map background
- Clearly visible in all map states

**Actual**:
- ❌ Button color blends in with map tiles
- Poor visibility/discoverability

**Impact**:
- **C3 Accessibility violation**: Low color contrast
- Users may not find the risk check feature
- WCAG AA failure likely

**Root Cause Analysis Needed**:
1. Check `RiskCheckButton` background color
2. Verify color is from `AppTheme.riskPalette` (Scottish colors)
3. Consider adding drop shadow or border for contrast

**Suggested Fix**:
```dart
// Add elevation and distinct color
FloatingActionButton(
  backgroundColor: AppTheme.primaryOrange, // Scottish palette
  elevation: 6.0, // Add shadow for depth
  // ... rest of config
)
```

**Fix Priority**: 🟡 **P1 - Should Fix**

---

### 6. **Map Zoom Controls Not Visible**
**Status**: 🟡 HIGH  
**Location**: MapScreen - Native Controls (Phase 2, Test 2.2)

**Expected**:
- Zoom in (+) button visible
- Zoom out (-) button visible
- Buttons ≥44dp touch targets

**Actual**:
- ❌ Zoom buttons not visible/tested

**Impact**:
- **C3 Accessibility concern**: Missing standard map controls
- Users can't zoom without pinch gestures (accessibility issue)
- iOS users expect native zoom buttons

**Root Cause Analysis Needed**:
1. Check `GoogleMap` widget `zoomControlsEnabled` property
2. Verify iOS-specific zoom button configuration
3. May need to add custom zoom buttons if native ones unavailable

**Fix Priority**: 🟡 **P1 - Should Fix**

---

## 🟢 Minor Issues (Nice to Have / Polish)

### 7. **Bottom Sheet Lacks Explicit Close Button**
**Status**: 🟢 MINOR  
**Location**: Risk Result Bottom Sheet (Phase 5, Test 5.1)

**Expected**:
- Close button (X) at top-right
- Button ≥44dp touch target

**Actual**:
- ❌ No explicit close button
- ✅ Tap-off gesture works to dismiss

**Impact**:
- **UX inconsistency**: Users must discover tap-off gesture
- Some users may not realize modal is dismissible
- Mild accessibility concern

**Suggested Fix**:
```dart
// Add IconButton to bottom sheet header
actions: [
  IconButton(
    icon: Icon(Icons.close, semanticLabel: 'Close risk assessment'),
    iconSize: 24.0,
    padding: EdgeInsets.all(12.0), // = 48dp touch target
    onPressed: () => Navigator.of(context).pop(),
  ),
],
```

**Fix Priority**: 🟢 **P2 - Nice to Have**

---

### 8. **Loading Indicator Not Visible**
**Status**: 🟢 MINOR  
**Location**: Risk Check Flow (Phase 3, Test 3.3)

**Expected**:
- Loading spinner appears immediately on FAB tap
- Spinner has semantic label

**Actual**:
- ❌ Loading indicator not observed
- Bottom sheet opens after ~1-2 seconds (as expected)

**Impact**:
- **UX polish**: No feedback during 1-2s wait
- Users may tap button multiple times
- Not a blocker (wait time is short)

**Suggested Fix**:
```dart
// Show inline loading indicator in FAB
child: _isLoading 
  ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(Colors.white),
      ),
    )
  : Icon(Icons.local_fire_department),
```

**Fix Priority**: 🟢 **P3 - Polish**

---

## ✅ Passing Tests (No Action Needed)

### Working Correctly:
1. ✅ App launches without errors
2. ✅ EFFIS service operational (FWI=28.343298)
3. ✅ GoogleMap widget renders
4. ✅ Map tiles load correctly
5. ✅ Fire markers visible and distinct colors
6. ✅ Marker icons appropriate size
7. ✅ Info windows appear on tap
8. ✅ Info windows dismissible
9. ✅ Map source chip visible with "MOCK" label
10. ✅ Source chip shows timestamp
11. ✅ Risk Check FAB visible and functional
12. ✅ FAB ≥44dp touch target ✅
13. ✅ Bottom sheet modal appears
14. ✅ Risk level displayed in bottom sheet
15. ✅ FWI value shown in bottom sheet
16. ✅ Data source label present
17. ✅ UTC timestamp formatted correctly
18. ✅ Location coordinates shown
19. ✅ Text readable with sufficient contrast
20. ✅ Loading completes within 3-5 seconds
21. ✅ "View Map" button visible and accessible

---

## 📊 Test Results Summary

**Overall Status**: ❌ **FAIL** (3 critical issues block release)

**Tests Completed**: 30 test cases
**Tests Passed**: 21 / 30 (70%)
**Critical Failures**: 3 🔴
**High Priority Issues**: 3 🟡
**Minor Issues**: 2 🟢

---

## 🎯 Prioritized Fix List

### Must Fix Before Any Release (P0):
1. 🔴 **Fix HomeScreen risk banner data mismatch** (shows LOW instead of HIGH)
2. 🔴 **Fix reversed fire marker intensities** (Glasgow/Aviemore swapped)
3. 🔴 **Add marker info window data** (title + intensity snippet)

### Should Fix Before Public Release (P1):
4. 🟡 **Fix map initial center** (should be Aviemore, not Edinburgh)
5. 🟡 **Improve FAB visibility** (color contrast on map background)
6. 🟡 **Add zoom controls** (or verify native controls enabled)

### Nice to Have (P2-P3):
7. 🟢 **Add close button to bottom sheet** (explicit dismiss action)
8. 🟢 **Show loading indicator during risk check** (FAB feedback)

---

## 🔬 Root Cause Investigation Steps

### Issue #1: Risk Banner Data Mismatch
**Files to Check**:
1. `lib/controllers/home_controller.dart` - State management
2. `lib/widgets/risk_banner.dart` - Display logic
3. `lib/services/fire_risk_service_impl.dart` - Data source
4. `lib/screens/home_screen.dart` - Widget integration

**Debug Strategy**:
```dart
// Add logging in HomeController
print('🏠 HomeController risk: ${_fireRisk?.level}, FWI: ${_fireRisk?.fwi}');

// Add logging in RiskBanner
print('🎨 RiskBanner displaying: level=${riskLevel}, fwi=${fwiValue}');
```

**Hypothesis**:
- Cached data overriding EFFIS results
- State not updating after initial load
- Wrong property being read in widget

---

### Issue #2: Marker Intensity Swap
**Files to Check**:
1. `assets/mock/active_fires.json` - Source data
2. `lib/models/fire_incident.dart` - JSON parsing
3. `lib/features/map/controllers/map_controller.dart` - Marker creation
4. `lib/services/fire_location_service.dart` - Data loading

**Debug Strategy**:
```bash
# Check mock data file
cat assets/mock/active_fires.json | jq '.features[] | {id, intensity, desc: .properties.description}'
```

**Hypothesis**:
- Intensity values swapped in JSON file
- Field mapping error in `FireIncident.fromJson()`
- Array iteration error (wrong index assignments)

---

### Issue #3: Info Window Missing Data
**Files to Check**:
1. `lib/features/map/screens/map_screen.dart` - Marker widget
2. `lib/features/map/controllers/map_controller.dart` - InfoWindow config
3. `lib/models/fire_incident.dart` - Data availability

**Debug Strategy**:
```dart
// Log InfoWindow content
print('📍 InfoWindow: title="${marker.infoWindow.title}", snippet="${marker.infoWindow.snippet}"');
```

**Hypothesis**:
- `InfoWindow` properties not set in `Marker` constructor
- `title`/`snippet` receiving null values
- String interpolation error

---

## 📸 Screenshots Reference

**Note**: No screenshots found in repository yet. Consider adding:

```bash
# Create screenshots directory
mkdir -p docs/screenshots/ios_manual_test

# Take screenshots during testing
xcrun simctl io booted screenshot docs/screenshots/ios_manual_test/issue_1_risk_banner.png
xcrun simctl io booted screenshot docs/screenshots/ios_manual_test/issue_2_markers.png
xcrun simctl io booted screenshot docs/screenshots/ios_manual_test/issue_3_info_window.png
```

**Recommended Screenshots**:
1. `issue_1_risk_banner_shows_low.png` - Home screen with LOW banner (should be HIGH)
2. `issue_2_glasgow_high_marker.png` - Glasgow marker showing HIGH (should be LOW)
3. `issue_3_aviemore_low_marker.png` - Aviemore marker showing LOW (should be HIGH)
4. `issue_4_map_centered_edinburgh.png` - Map centered on Edinburgh (should be Aviemore)
5. `issue_5_fab_poor_contrast.png` - FAB blending with map tiles

---

## 🔄 Next Steps

### Immediate Actions (Today):
1. ✅ Review this summary document
2. 🔧 Fix Issue #1: Risk banner data mismatch
3. 🔧 Fix Issue #2: Marker intensity reversal
4. 🔧 Fix Issue #3: Info window missing data
5. 🧪 Re-test on iOS simulator after fixes
6. 📝 Update `IOS_MANUAL_TEST_SESSION.md` with results

### After P0 Fixes (Next Session):
1. 🔧 Fix Issue #4: Map centering
2. 🎨 Fix Issue #5: FAB color contrast
3. ⚙️ Fix Issue #6: Zoom controls
4. 🧪 Run full test suite: `flutter test`
5. 📊 Verify test coverage still ≥65%

### Before Live Data Testing:
1. ✅ All P0 issues resolved
2. ✅ Re-test mock data flow end-to-end
3. ✅ Automated tests passing (363 tests)
4. ✅ Coverage report updated
5. 🚀 **Then**: Test with `MAP_LIVE_DATA=true` (TODO #1)

---

## 📚 Related Documentation

- `docs/IOS_MANUAL_TEST_SESSION.md` - Full test checklist
- `docs/TEST_COVERAGE_REPORT.md` - Automated test coverage
- `specs/011-a10-google-maps/tasks.md` - A10 implementation tasks
- `docs/SESSION_SUMMARY_2025-10-19.md` - Previous session summary

---

## 💡 Key Takeaways

**What Went Well**:
- ✅ App launches cleanly on iOS
- ✅ EFFIS service integration working
- ✅ Core map functionality operational
- ✅ UI components render correctly
- ✅ Most accessibility targets met

**What Needs Work**:
- 🔴 Data integrity issues (risk levels, intensities)
- 🔴 Widget state propagation problems
- 🟡 UX polish (centering, contrast, controls)

**Confidence Level**: 70%
- Ready for development testing ✅
- **Not ready for production** ❌ (3 critical issues)
- Can proceed after P0 fixes ✅

---

**Generated**: 2025-10-19  
**Next Review**: After P0 fixes implemented
