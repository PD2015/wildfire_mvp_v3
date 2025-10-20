# Manual Integration Test Checklist

This document provides step-by-step manual integration test procedures for WildFire MVP features that require runtime verification beyond automated tests.

## TEST_REGION Feature Verification

### Purpose
Verify that TEST_REGION flag correctly overrides GPS and provides consistent location data across all UI components (RiskBanner and Map).

### When to Run
- ✅ Before each release (all platforms)
- ✅ Quarterly during fire seasons (region-specific)
- ✅ After changes to LocationResolver, HomeController, or MapController
- ✅ After EFFIS service integration changes

### Prerequisites
- Android emulator or physical device configured
- iOS simulator or physical device configured (optional)
- macOS development machine for macOS testing
- Active internet connection for EFFIS API calls
- Understanding of seasonal fire periods for each region

---

## Test Checklist

### 1. GPS Auto-Disable Verification

**Objective**: Verify GPS is skipped when TEST_REGION is set to non-default value.

**Platforms**: Android, iOS, macOS

**Steps**:

1. **Run with TEST_REGION=portugal**:
   ```bash
   flutter run -d android \
     --dart-define=TEST_REGION=portugal \
     --dart-define=MAP_LIVE_DATA=true
   ```

2. **Check Console Logs**:
   - ✅ Look for: `TEST_REGION=portugal: Skipping GPS to use test region coordinates`
   - ✅ Should NOT see: `Location resolved via GPS: ...`
   - ✅ Should see: `Using test region: portugal at 39.60,-9.10`

3. **Expected Behavior**:
   - App loads without requesting GPS permission
   - Location resolves to Portugal coordinates (39.6, -9.1)
   - No GPS permission dialogs appear

**Pass Criteria**: GPS skip log appears, no GPS permission prompts, Portugal coordinates used.

---

### 2. Controller Consistency Verification

**Objective**: Verify both HomeController and MapController use identical coordinates for the same TEST_REGION.

**Platforms**: Android, iOS

**Steps**:

1. **Run with TEST_REGION=california**:
   ```bash
   flutter run -d android \
     --dart-define=TEST_REGION=california \
     --dart-define=MAP_LIVE_DATA=true
   ```

2. **Monitor Console Logs**:
   - ✅ HomeController log: `Using test region: california at 36.70,-119.40`
   - ✅ MapController log: `🗺️ Using test region: california at 36.70,-119.40`

3. **Verify UI Display**:
   - RiskBanner shows fire risk for California region
   - Map centers on California coordinates
   - Both components show "EFFIS" source chip (if live data)

4. **Check Geohash Cache Key**:
   - ✅ Look for: Geohash starting with `9q` (California region)
   - ❌ Should NOT see: `gfjm3` (Scotland) or other region hashes

**Pass Criteria**: Both controllers log identical coordinates, UI components show consistent location.

---

### 3. EFFIS Bounding Box Verification

**Objective**: Verify EFFIS queries use correct geographic bounding box for each test region.

**Platforms**: Android, iOS, macOS

**Steps**:

1. **Run with TEST_REGION=spain**:
   ```bash
   flutter run -d android \
     --dart-define=TEST_REGION=spain \
     --dart-define=MAP_LIVE_DATA=true
   ```

2. **Check EFFIS Query Logs**:
   - ✅ Look for: `EFFIS WFS query for bbox: -10.3,35.4,-6.3,42.4` (Spain bbox)
   - ❌ Should NOT see: Scotland bbox `(-8.8,54.2,-0.8,61.2)`

3. **Verify Fire Data**:
   - If during fire season (June-September), fire markers may appear
   - Source chip shows "EFFIS" indicating live data
   - Empty state shows "No active fires" if outside fire season

**Pass Criteria**: EFFIS queried with correct regional bounding box, not default Scotland.

---

### 4. Seasonal Fire Data Verification

**Objective**: Verify fire data appears during appropriate fire seasons for each region.

**Platforms**: Android, iOS

**Test Matrix**:

| Region | Fire Season | Test Command | Expected Behavior |
|--------|-------------|--------------|-------------------|
| Portugal | June-September | `--dart-define=TEST_REGION=portugal` | Fire markers likely |
| Spain | June-September | `--dart-define=TEST_REGION=spain` | Fire markers likely |
| Greece | July-September | `--dart-define=TEST_REGION=greece` | Fire markers likely |
| California | July-November | `--dart-define=TEST_REGION=california` | Fire markers likely |
| Australia | December-February | `--dart-define=TEST_REGION=australia` | Fire markers likely |
| Scotland | April-May (rare) | Default or `TEST_REGION=scotland` | Fire markers unlikely |

**Steps**:

1. **Choose appropriate region for current month** (see table above)

2. **Run test**:
   ```bash
   flutter run -d android \
     --dart-define=TEST_REGION=<region> \
     --dart-define=MAP_LIVE_DATA=true
   ```

3. **Verify Fire Display**:
   - During fire season: Fire markers should appear on map
   - Outside fire season: "No active fires" empty state
   - Check RiskBanner shows appropriate FWI level

4. **Visual Verification**:
   - Fire markers clustered in realistic geographic regions
   - Marker count matches "Showing X fires" in controls
   - Tapping marker shows fire details

**Pass Criteria**: Fire data appears during expected seasons, empty state shown otherwise.

---

### 5. Privacy-Compliant Logging

**Objective**: Verify coordinate logging uses 2-decimal precision (C2 compliance).

**Platforms**: All

**Steps**:

1. **Run with any TEST_REGION**:
   ```bash
   flutter run -d android \
     --dart-define=TEST_REGION=greece \
     --dart-define=MAP_LIVE_DATA=true
   ```

2. **Audit Console Logs**:
   - ✅ CORRECT: `Using test region: greece at 37.90,23.70`
   - ❌ WRONG: Full precision like `37.9838,23.7275`

3. **Check All Log Statements**:
   - LocationResolver logs
   - HomeController logs
   - MapController logs
   - FireRiskService logs

**Pass Criteria**: All coordinate logs show maximum 2 decimal places.

---

### 6. Platform-Specific Fallback (macOS)

**Objective**: Verify macOS shows fallback UI when TEST_REGION used (GoogleMaps not supported on macOS).

**Platforms**: macOS only

**Steps**:

1. **Run on macOS**:
   ```bash
   flutter run -d macos \
     --dart-define=TEST_REGION=portugal \
     --dart-define=MAP_LIVE_DATA=true
   ```

2. **Verify Fallback UI**:
   - ✅ Shows fire data list (not GoogleMap)
   - ✅ Source chip shows "EFFIS"
   - ✅ Fire count displayed
   - ✅ Each fire item shows location and FWI

3. **Check Logs**:
   - ✅ Should see: `Platform macOS does not support GoogleMap`
   - ✅ Should see: `Using test region: portugal at 39.60,-9.10`

**Pass Criteria**: macOS shows list fallback UI, queries Portugal region successfully.

---

## Regression Testing

### After LocationResolver Changes

Run all TEST_REGION values to ensure GPS skip logic works:

```bash
# Quick regression test script
for region in portugal spain greece california australia; do
  echo "Testing $region..."
  flutter run -d android \
    --dart-define=TEST_REGION=$region \
    --dart-define=MAP_LIVE_DATA=false \
    --no-pub &
  sleep 10
  pkill -f "flutter run"
done
```

**Expected**: Each region logs correct coordinates, no GPS permission prompts.

---

### After Controller Changes

Verify HomeController and MapController consistency:

1. Run with `TEST_REGION=spain`
2. Check both controllers log identical coordinates: `40.40,-3.70`
3. Verify RiskBanner and Map both query Spain region
4. Confirm geohash cache uses `ezjm8` (Spain) not `gfjm3` (Scotland)

---

## Test Failure Troubleshooting

### GPS Not Skipped

**Symptom**: GPS permission prompt appears when TEST_REGION is set.

**Diagnosis**:
- Check FeatureFlags.testRegion value in logs
- Verify `--dart-define=TEST_REGION=<value>` in run command
- Confirm LocationResolver checks `FeatureFlags.testRegion != 'scotland'`

**Fix**: Rebuild after clearing cache: `flutter clean && flutter pub get`

---

### Controllers Use Different Coordinates

**Symptom**: HomeController logs different coordinates than MapController.

**Diagnosis**:
- Check `_getTestRegionCenter()` implementation in both controllers
- Verify both use identical switch/case logic
- Confirm both check `FeatureFlags.testRegion`

**Fix**: Sync controller implementations (see `home_controller.dart` and `map_controller.dart`).

---

### Wrong Bounding Box Queried

**Symptom**: EFFIS queries Scotland bbox when TEST_REGION=portugal.

**Diagnosis**:
- Verify LocationResolver returns error (not Scotland default) when TEST_REGION set
- Check controller fallback logic uses `_getTestRegionCenter()`
- Confirm FireLocationService receives correct coordinates

**Fix**: Ensure LocationResolver returns `Left(LocationError.gpsUnavailable)` when TEST_REGION set.

---

## Release Checklist Integration

### Pre-Release Verification

Before each release, complete this subset:

- [ ] **Test 1**: GPS Auto-Disable (Portugal or California)
- [ ] **Test 2**: Controller Consistency (Spain or Greece)
- [ ] **Test 3**: EFFIS Bounding Box (any non-Scotland region)
- [ ] **Test 5**: Privacy Logging Audit (all logs)
- [ ] **Test 6**: macOS Fallback UI (Portugal with MAP_LIVE_DATA=true)

**Time Estimate**: ~20 minutes per platform (Android, iOS, macOS)

---

## Quarterly Verification Schedule

### Q1 (January-March)
- **Primary Region**: Australia (fire season Dec-Feb)
- **Command**: `--dart-define=TEST_REGION=australia --dart-define=MAP_LIVE_DATA=true`
- **Expected**: Fire markers in southeast Australia

### Q2 (April-June)
- **Primary Region**: Scotland (shoulder season)
- **Command**: Default or `--dart-define=TEST_REGION=scotland`
- **Expected**: Usually "No active fires"

### Q3 (July-September)
- **Primary Region**: California (peak fire season)
- **Command**: `--dart-define=TEST_REGION=california --dart-define=MAP_LIVE_DATA=true`
- **Expected**: Fire markers in California, potential high FWI

### Q4 (October-December)
- **Primary Region**: Portugal (shoulder season ending)
- **Command**: `--dart-define=TEST_REGION=portugal --dart-define=MAP_LIVE_DATA=true`
- **Expected**: Few or no fire markers by November

---

## CI/CD Integration Notes

### Automated Tests
- Unit tests: Cover logic, not compile-time constants
- Widget tests: Verify UI consistency (see `test/widget/test_region_consistency_test.dart`)
- Integration tests: **Require manual execution** (compile-time flags can't be mocked)

### Manual Test Triggers
- Pre-release: Run full checklist (all platforms)
- Quarterly: Run seasonal region verification
- Post-hotfix: Run regression subset (Tests 1-3)

### Test Artifacts
- Console logs saved to `build/logs/integration-test-REGION-DATE.log`
- Screenshots for each region in `screenshots/test-regions/`
- Pass/fail status documented in release notes

---

## References

- **Comprehensive Guide**: [TEST_REGIONS.md](../TEST_REGIONS.md)
- **Test Specifications**: 
  - [location_resolver_test_region_test.dart](../../test/unit/services/location_resolver_test_region_test.dart)
  - [home_controller_test_region_test.dart](../../test/unit/controllers/home_controller_test_region_test.dart)
- **Widget Consistency Tests**: [test_region_consistency_test.dart](../../test/widget/test_region_consistency_test.dart)
- **Quick Reference**: [README.md - Testing with Different Regions](../../README.md#testing-with-different-regions)

---

## Contact

For questions about manual integration testing:
- **TEST_REGION Feature**: See docs/TEST_REGIONS.md
- **EFFIS Integration**: See docs/DATA-SOURCES.md
- **Privacy Compliance**: See docs/privacy-compliance.md

Last Updated: 20 October 2025
