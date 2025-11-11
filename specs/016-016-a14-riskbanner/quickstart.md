# Quickstart: RiskBanner Visual Refresh

**Feature**: RiskBanner Visual Refresh  
**Date**: 2025-11-02  
**Estimated Time**: 4-6 hours

## Prerequisites
- Flutter 3.35.5+ and Dart 3.9.2+
- Existing WildFire MVP codebase
- Golden test tooling setup

## Quick Validation Steps

### 1. Visual Verification (2 minutes)
```bash
# Run the app and navigate to Home screen
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Verify in UI:
# ✓ Banner has rounded corners (16dp radius)
# ✓ Banner has elevation shadow
# ✓ Location coordinates appear below title (when available)
# ✓ Timestamp appears inside banner (not external row)
# ✓ Data source appears as plain text inside banner
# ✓ Cached badge still appears when data is cached
```

### 2. Golden Test Verification (30 seconds)
```bash
# Generate and verify golden test images
flutter test test/widget/golden/risk_banner_moderate_light_test.dart
flutter test test/widget/golden/risk_banner_moderate_dark_test.dart

# Check generated images in test/goldens/risk_banner/
# ✓ Images show new rounded banner design
# ✓ Location row with pin icon visible
# ✓ Internal timestamp and data source
```

### 3. Widget Test Verification (1 minute)
```bash
# Run updated widget tests
flutter test test/widget/risk_banner_test.dart

# Verify all tests pass:
# ✓ Existing logic tests (risk colors, cached badge)
# ✓ New location row conditional rendering test
# ✓ Weather panel configuration test (if enabled)
```

### 4. Integration Test Verification (2 minutes)
```bash
# Run home screen integration tests
flutter test integration_test/home_integration_test.dart

# Verify:
# ✓ Home screen displays enhanced banner
# ✓ External timestamp row removed
# ✓ No regression in fire risk data display
```

## User Story Validation

### Story 1: Enhanced Visual Design
**Given** I'm on the Home screen with fire risk data loaded  
**When** I view the risk banner  
**Then** I see a rounded banner with 16dp corner radius, 16dp padding, and subtle elevation

**Validation Steps**:
1. Open app, navigate to Home screen
2. Observe banner container styling
3. Compare with design specifications
4. ✓ **Pass Criteria**: Banner has Material Card appearance with visible elevation and rounded corners

### Story 2: Location Display
**Given** location data is available  
**When** I view the risk banner  
**Then** I see a location row with pin icon and coordinates formatted to two decimals

**Validation Steps**:
1. Ensure location permission granted or mock location enabled
2. Observe banner content for location row
3. Verify format: "(55.95, -3.19)" with pin icon
4. ✓ **Pass Criteria**: Location row visible with correct format and icon

### Story 3: Internal Data Source Display
**Given** fire risk data from any source  
**When** I view the risk banner  
**Then** I see "Data Source: [EFFIS|SEPA|Cache|Mock]" as plain text inside the banner

**Validation Steps**:
1. Test with different data sources (mock, cache if available)
2. Verify data source text appears inside banner
3. Verify external source chip no longer appears
4. ✓ **Pass Criteria**: Data source clearly labeled inside banner, no external chip

### Story 4: Dark Mode Compatibility
**Given** I'm using dark mode  
**When** I view the risk banner  
**Then** I see appropriate text colors with proper contrast

**Validation Steps**:
1. Enable dark mode in device/browser settings
2. Navigate to Home screen
3. Verify text readability and contrast
4. Run dark mode golden test
5. ✓ **Pass Criteria**: All text readable in dark mode, golden test passes

## Rollback Instructions

### Quick Rollback (if issues found)
```bash
# Revert main widget file
git checkout HEAD~1 lib/widgets/risk_banner.dart

# Revert home screen changes
git checkout HEAD~1 lib/screens/home_screen.dart  

# Remove golden test files
rm -rf test/widget/golden/risk_banner_*
rm -rf test/goldens/risk_banner/

# Restore original widget tests
git checkout HEAD~1 test/widget/risk_banner_test.dart
```

### Verification After Rollback
```bash
# Verify app still works with original design
flutter test
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Confirm:
# ✓ Original banner design restored
# ✓ External timestamp row present
# ✓ Source chip functionality restored
# ✓ All tests pass
```

## Troubleshooting

### Golden Test Failures
```bash
# Update golden references if design intentionally changed
flutter test --update-goldens test/widget/golden/

# Compare changes visually before accepting
# Check test/goldens/risk_banner/ for updated images
```

### Widget Test Failures
```bash
# Common issues and fixes:

# 1. Location row not found
# Fix: Verify locationLabel parameter is passed correctly

# 2. External timestamp still expected
# Fix: Update test expectations to look inside banner

# 3. Source chip still expected  
# Fix: Update test expectations for plain text data source
```

### Layout Issues
```bash
# If banner appears malformed:

# 1. Check Material Card wrapping
# Fix: Ensure Card widget properly wraps content

# 2. Check padding/margin
# Fix: Verify kBannerPadding constant is applied correctly

# 3. Check elevation not appearing
# Fix: Verify Material theme supports elevation in test environment
```

## Performance Notes

- **Rendering Impact**: Minimal - same widget count, improved container
- **Golden Test Time**: ~30 seconds for full suite
- **Memory Impact**: Negligible configuration object overhead
- **Animation Performance**: Preserved - no new animations added

## Next Steps After Validation

1. **Update Documentation**: Add visual refresh notes to project README
2. **Monitor Golden Tests**: Include in CI pipeline to prevent regressions  
3. **Gather Feedback**: Collect user feedback on enhanced design
4. **Future Weather Panel**: When ready, enable weather panel via config flag

## Related Files Modified

### Core Implementation
- `lib/widgets/risk_banner.dart` - Primary widget enhancement
- `lib/screens/home_screen.dart` - Coordinate passing, timestamp removal

### Test Files  
- `test/widget/risk_banner_test.dart` - Updated widget tests
- `test/widget/golden/risk_banner_*.dart` - New golden tests
- `test/goldens/risk_banner/*.png` - Golden reference images

### Documentation
- `specs/003-a3-riskbanner-home/quickstart.md` - Updated with visual notes
- This quickstart file - Implementation validation guide