# Quickstart: Rename Home → Fire Risk Screen

**Feature**: 015-rename-home-fire  
**Purpose**: Verify the Home → Fire Risk rename implementation works correctly  
**Execution Time**: ~10 minutes  
**Prerequisites**: Flutter development environment, device/simulator

## Setup

1. **Ensure you're on the correct branch**:
   ```bash
   git checkout 015-rename-home-fire
   git status  # Should show clean working tree
   ```

2. **Install dependencies** (if needed):
   ```bash
   flutter pub get
   flutter pub deps  # Verify go_router and material icons available
   ```

3. **Choose test platform**:
   ```bash
   # Mobile (recommended - full icon support)
   flutter devices | grep -E "(android|ios)"
   
   # Web (alternative - verify routing)
   flutter devices | grep chrome
   ```

## Validation Scenarios

### Scenario 1: Visual UI Changes
**Goal**: Verify the renamed UI elements display correctly

**Steps**:
1. Launch the app:
   ```bash
   flutter run -d [device-id]
   ```

2. **Check bottom navigation**:
   - ✅ Navigation tab shows "Fire Risk" label (not "Home")
   - ✅ Icon displays warning triangle/amber symbol (not house icon)
   - ✅ Touch target feels responsive (≥44dp)

3. **Check app bar**:
   - ✅ Title displays "Wildfire Risk" or "Fire Risk"
   - ✅ Title is readable and properly styled

4. **Check accessibility** (if available):
   - Enable screen reader (TalkBack/VoiceOver)
   - Tap navigation item
   - ✅ Announces "Fire risk information tab" or similar descriptive text

**Expected Results**:
- No "Home" text visible anywhere in main screen
- Warning/amber icon clearly visible and distinguishable
- All text properly styled and readable

### Scenario 2: Navigation Functionality  
**Goal**: Verify navigation and routing work correctly

**Steps**:
1. **Test basic navigation**:
   - Tap fire risk navigation item
   - ✅ Screen remains on fire risk content (no navigation change since it's current)
   - ✅ Navigation item shows selected state

2. **Test deep linking** (Web only):
   ```bash
   # In browser address bar or new tab
   http://localhost:[port]/fire-risk
   ```
   - ✅ Navigates to fire risk screen
   - ✅ URL shows `/fire-risk` or `/` 
   - ✅ Content identical to main navigation

3. **Test route aliases**:
   ```bash
   # Both should work (if web testing available)
   http://localhost:[port]/           # Primary route
   http://localhost:[port]/fire-risk  # Alias route
   ```
   - ✅ Both URLs load the same screen
   - ✅ No broken navigation or 404 errors

**Expected Results**:
- All navigation functions work as before
- No broken routes or navigation errors
- Deep linking functional for both routes

### Scenario 3: Existing Functionality Preservation
**Goal**: Verify all fire risk features still work unchanged

**Steps**:
1. **Check fire risk data display**:
   - ✅ Risk level banner shows current fire risk (Low/Moderate/High/etc.)
   - ✅ "Last updated" timestamp visible and formatted correctly
   - ✅ Source label present (EFFIS/SEPA/Cache/Mock)

2. **Test interactive features**:
   - Try manual location entry (if available)
   - ✅ Location picker/manual entry works
   - ✅ Risk data updates based on location
   - ✅ No functionality lost or broken

3. **Check error states**:
   - Disconnect internet (if possible)
   - ✅ Error handling works as before
   - ✅ Cache/fallback behavior unchanged
   - ✅ Error messages appropriate and helpful

**Expected Results**:
- Zero regression in existing fire risk functionality
- All data displays and interactions work identically
- Error handling and edge cases preserved

### Scenario 4: Cross-Platform Consistency
**Goal**: Verify changes work across different platforms

**Steps**:
1. **Test on mobile** (if available):
   ```bash
   flutter run -d android  # or ios
   ```
   - ✅ Warning icon renders correctly
   - ✅ Navigation labels displayed properly
   - ✅ Touch interactions responsive

2. **Test on web** (recommended):
   ```bash
   flutter run -d chrome
   ```
   - ✅ Material icons load correctly
   - ✅ Navigation responsive to clicks
   - ✅ URL routing functional
   - ✅ Browser back/forward buttons work

3. **Test on desktop** (optional):
   ```bash
   flutter run -d macos  # or windows/linux
   ```
   - ✅ Icons and labels display correctly
   - ✅ Mouse interactions work properly

**Expected Results**:
- Consistent appearance across all platforms
- Icons render correctly (no missing/broken icons)
- Navigation behavior identical on all platforms

## Quick Test Commands

### Automated Widget Tests
```bash
# Run tests related to navigation
flutter test test/widget/ --name="navigation"

# Run tests for home/fire risk screen
flutter test test/widget/ --name="home|fire.*risk"

# Run all widget tests (verify no regressions)
flutter test test/widget/
```

### Integration Tests
```bash
# Test navigation flows
flutter test integration_test/ --name="navigation"

# Test route handling  
flutter test integration_test/ --name="route"

# Full integration test suite
flutter test integration_test/
```

### Code Quality Checks
```bash
# Constitutional gate verification
flutter analyze                    # C1: Code quality
dart format --set-exit-if-changed lib/ test/  # C1: Formatting
flutter test                       # C1: All tests pass

# Check for any accidental secrets or PII
grep -r "lat.*[0-9]\|lon.*[0-9]" lib/ | head -5  # C2: No raw coordinates
```

## Success Criteria Checklist

### Visual/UI Requirements
- [ ] Bottom navigation shows "Fire Risk" label
- [ ] Navigation icon is warning/amber triangle (not home icon)
- [ ] App bar title shows "Wildfire Risk" or "Fire Risk"
- [ ] No "Home" text visible in UI
- [ ] All text properly styled and readable

### Functional Requirements  
- [ ] Fire risk data displays correctly (banner, timestamp, source)
- [ ] Navigation to fire risk screen works
- [ ] All existing features preserved (location, data refresh, etc.)
- [ ] Error handling and edge cases work as before

### Technical Requirements
- [ ] Route "/" navigates to fire risk screen
- [ ] Route "/fire-risk" alias works (if implemented)
- [ ] Deep linking functional
- [ ] Browser navigation works (web)
- [ ] All automated tests pass

### Accessibility Requirements
- [ ] Screen reader announces appropriate labels
- [ ] Touch targets ≥44dp and responsive
- [ ] Icon contrast adequate in light/dark themes
- [ ] Focus navigation logical and clear

### Constitutional Compliance
- [ ] `flutter analyze` passes (C1)
- [ ] No raw coordinates in logs/UI (C2)
- [ ] Accessibility standards met (C3)
- [ ] Official colors preserved (C4)
- [ ] Error handling unchanged (C5)

## Troubleshooting

### Common Issues

**Icon not displaying**:
- Verify Flutter SDK includes Material Design icons
- Check if Icons.warning_amber supported in current version
- Try fallback to Icons.report_outlined

**Route navigation broken**:
- Check go_router configuration updated correctly
- Verify route names don't conflict with existing routes
- Test with `flutter clean && flutter pub get`

**Tests failing**:
- Update test expectations for new labels/icons
- Check widget tests for hardcoded "Home" strings
- Verify test data includes new navigation configuration

**Accessibility issues**:
- Check semantic labels properly configured
- Verify touch target sizes maintained
- Test with actual screen reader if available

### Rollback Procedure
If critical issues found:
```bash
git checkout staging                    # Return to known good state
# Or revert specific commit
git revert [commit-hash]               # Revert rename changes only
```

## Completion
✅ **Quickstart Complete** when all success criteria checked off and no critical issues found.

This validation confirms the Home → Fire Risk rename is ready for production deployment.