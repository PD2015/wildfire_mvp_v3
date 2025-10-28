# iOS Testing - Quick Action Plan

**Date**: 2025-10-19  
**Status**: 3 Critical Issues Identified  
**Goal**: Fix P0 blockers before proceeding to live data testing

---

## 🔴 P0: Critical Fixes Required (Block Release)

### Fix #1: Home Screen Risk Banner Shows Wrong Data ⚠️
**Problem**: Banner shows LOW (blue) but should show HIGH (red) with FWI=28.3

**Files to Fix**:
- `lib/controllers/home_controller.dart`
- `lib/widgets/risk_banner.dart`
- `lib/screens/home_screen.dart`

**Steps**:
1. Add debug logging to trace data flow
2. Check if cached data overrides EFFIS result
3. Verify state propagation from service → controller → widget
4. Test with hot reload after fix

**Expected Time**: 30-45 minutes

---

### Fix #2: Fire Marker Intensities Reversed ⚠️
**Problem**: Glasgow shows HIGH (should be LOW), Aviemore shows LOW (should be HIGH)

**Files to Fix**:
- `assets/mock/active_fires.json` (check source data)
- `lib/models/fire_incident.dart` (check JSON parsing)
- `lib/features/map/controllers/map_controller.dart` (check marker creation)

**Steps**:
1. Verify `active_fires.json` has correct intensity values
2. Check `FireIncident.fromJson()` field mapping
3. Add logging to trace intensity values through pipeline
4. Test with hot reload after fix

**Expected Time**: 20-30 minutes

---

### Fix #3: Marker Info Windows Missing Data ⚠️
**Problem**: Info windows don't show title "Fire Incident" or snippet with intensity

**Files to Fix**:
- `lib/features/map/screens/map_screen.dart`
- `lib/features/map/controllers/map_controller.dart`

**Steps**:
1. Check `Marker` widget `InfoWindow` configuration
2. Ensure `title` and `snippet` properties are set
3. Format snippet as: "{INTENSITY} - {source}"
4. Test by tapping markers after fix

**Expected Time**: 15-20 minutes

---

## 📋 Testing After Fixes

### Quick Smoke Test:
```bash
# Run app on iOS
flutter run -d "7858966D-32C4-441B-999A-03F571410BC2" --dart-define=MAP_LIVE_DATA=false

# Verify:
# 1. Home screen shows HIGH risk banner (red/orange)
# 2. Map markers: Edinburgh=MODERATE, Glasgow=LOW, Aviemore=HIGH
# 3. Tap each marker → info window shows "Fire Incident" + intensity
```

### Full Test:
```bash
# Run automated tests
flutter test

# Expected: 363 passing, 6 skipped, 1 pre-existing failure
```

---

## 🟡 P1: Should Fix Next (Before Release)

### Fix #4: Map Centers on Edinburgh (Should be Aviemore)
**Quick Fix**: Update `MapScreen` initial `CameraPosition`
**Time**: 10 minutes

### Fix #5: FAB Blends with Map Tiles
**Quick Fix**: Update FAB background color + add elevation
**Time**: 5 minutes

### Fix #6: Zoom Controls Not Visible
**Quick Fix**: Enable `zoomControlsEnabled: true` in GoogleMap widget
**Time**: 5 minutes

---

## 🎯 Today's Goal

**Minimum**: Fix all 3 P0 issues
**Stretch**: Also fix P1 issues #4-6
**Total Time**: ~1.5-2 hours

---

## ✅ Definition of Done

- [ ] Home screen shows HIGH risk banner with FWI value
- [ ] Fire markers have correct intensities (Glasgow=LOW, Aviemore=HIGH)
- [ ] Marker info windows display title + intensity snippet
- [ ] All automated tests still pass (363+)
- [ ] Manual re-test on iOS confirms fixes
- [ ] Commit with message: `fix(ios): resolve 3 critical data display issues`

---

## 🚀 After Fixes

### Next Session Goals:
1. Fix remaining P1 issues (#4-6)
2. Test with `MAP_LIVE_DATA=true` (live EFFIS data)
3. Complete TODO #1: End-to-end EFFIS WFS testing
4. Update coverage report if needed
5. Proceed to T017-T019 integration tasks

---

**Ready to start?** Let's fix Issue #1 first (risk banner). 🔧
