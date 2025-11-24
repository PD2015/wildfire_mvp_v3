---
title: Material 3 Implementation Plan
status: active
last_updated: 2025-01-19
category: guides
subcategory: setup
related:
  - docs/MATERIAL_3_COMPLIANCE_AUDIT.md
  - lib/theme/wildfire_a11y_theme.dart
  - docs/ux_cues.md
---

# Material 3 Implementation Plan

**Based on**: User-provided Material 3 audit (2025-01-19)  
**Branch**: `feature/manual-style-updates`  
**Scope**: Fix 4 identified M3 gaps while maintaining WCAG 2.1 AA compliance

---

## Overview

This plan addresses **4 key Material 3 compliance gaps** identified in the comprehensive audit:

1. ❌ Missing `secondaryContainer` and `onSecondaryContainer` ColorScheme properties
2. ❌ Dark theme uses amber for error color (should be red for proper semantics)
3. ❌ No `FilledButtonTheme` (M3 replacement for ElevatedButton)
4. ✅ Cards already use theme defaults correctly (no changes needed)

**Priority**: Medium - Improves Material 3 compliance and accessibility  
**Risk**: Low - Changes isolated to theme system, minimal widget impact  
**Estimated Time**: 2-3 hours (including testing and documentation)

---

## Research Findings

### Material 3 ColorScheme Container Colors

**Purpose**: Container colors provide tonal variants for secondary UI elements:
- **`secondaryContainer`**: Lighter/darker shade of secondary color for info cards, tonal buttons
- **`onSecondaryContainer`**: Contrast-safe text color for secondaryContainer backgrounds

**Usage Patterns** (from M3 spec):
```dart
// Info cards with secondary accent
Card(
  color: Theme.of(context).colorScheme.secondaryContainer,
  child: Text(
    'Safety Tips',
    style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
  ),
)

// Tonal buttons (secondary actions)
FilledButton.tonal(
  onPressed: () {},
  child: Text('Set Location'), // Uses secondaryContainer background
)
```

**References**:
- [Material 3 Color System](https://m3.material.io/styles/color/the-color-system/color-roles)
- [Flutter ColorScheme API](https://api.flutter.dev/flutter/material/ColorScheme-class.html)

### Error Color Semantics

**Current Issue**: Dark theme uses `BrandPalette.amber500` for error  
**Problem**: Amber conventionally indicates **warning**, not error  
**M3 Guidance**: Errors should use red family for clear semantic distinction

**Color Mapping**:
- ⚠️ **Warning**: Amber, yellow - temporary issues, informational alerts
- ❌ **Error**: Red - critical failures, blocked actions, data loss

**Example Impact**:
```dart
// Before (amber error - confusing)
error: BrandPalette.amber500, // Looks like warning

// After (red error - clear semantics)
error: Colors.redAccent.shade200, // Clearly indicates error state
```

### FilledButton vs ElevatedButton

**Material 3 Guidance**: `FilledButton` replaces `ElevatedButton` as primary CTA  
**Reasoning**: Flat, filled design aligns with M3's bold simplicity

**Button Hierarchy** (M3 spec):
1. **FilledButton**: Primary CTAs (Get GPS Location, Save, Login)
2. **FilledButton.tonal()**: Secondary actions (Set Manual Location, 101, Crimestoppers)
3. **OutlinedButton**: Low-emphasis actions (Cancel)
4. **TextButton**: Inline actions (Learn More, Dismiss)

**Migration Strategy**:
- Primary CTAs (bright forest600 filled) → `FilledButton`
- Secondary CTAs (currently outlined/text) → `FilledButton.tonal()` (uses secondaryContainer)
- Keep `OutlinedButton` for cancel/dismiss actions
- Keep `TextButton` for inline links

**Exception**: `EmergencyButton` stays `ElevatedButton` with custom styling (pulse animation, red error color)

---

## Implementation Plan (11 Tasks)

### Task 1: Add secondaryContainer to ColorScheme

**Files**: `lib/theme/wildfire_a11y_theme.dart`

**Light Theme** (lines 104-128):
```dart
// Add after line 105 (onSecondary: BrandPalette.onLightHigh)
secondaryContainer: BrandPalette.mint300, // Lighter mint for info cards
onSecondaryContainer: BrandPalette.onLightHigh, // Dark text on light mint
```

**Dark Theme** (lines 287-318):
```dart
// Add after line 290 (onSecondary: BrandPalette.onDarkHigh)
secondaryContainer: BrandPalette.mint400, // Darker mint for dark mode
onSecondaryContainer: BrandPalette.onDarkHigh, // White text on dark mint
```

**Rationale**:
- `mint300` (light) already in `BrandPalette` with WCAG-verified contrast
- `mint400` (dark) provides sufficient distinction on `forest500` surface
- Enables `FilledButton.tonal()` styling per M3 spec

---

### Task 2: Fix dark theme error color

**File**: `lib/theme/wildfire_a11y_theme.dart` (line 300)

**Change**:
```dart
// Before
error: BrandPalette.amber500, // ❌ Amber suggests warning

// After
error: Colors.redAccent.shade200, // ✅ Red indicates error
```

**WCAG Verification Required**:
- Test `Colors.redAccent.shade200` on `BrandPalette.forest500` (dark surface)
- Must meet ≥4.5:1 contrast ratio for text
- Use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

**Expected Impact**:
- Error cards in dark mode now use red background (clearer semantics)
- Error icons/text maintain proper contrast
- Aligns with M3 error handling guidelines

---

### Task 3: Add FilledButtonTheme

**Files**: `lib/theme/wildfire_a11y_theme.dart`

**Light Theme** (insert after line 143):
```dart
// FilledButton: M3 primary CTA (≥44dp height)
filledButtonTheme: FilledButtonThemeData(
  style: FilledButton.styleFrom(
    minimumSize: const Size(64, 44),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    // backgroundColor defaults to colorScheme.primary
  ),
),
```

**Dark Theme** (insert after line 327):
```dart
// FilledButton: M3 primary CTA (≥44dp height)
filledButtonTheme: FilledButtonThemeData(
  style: FilledButton.styleFrom(
    minimumSize: const Size(64, 44),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  ),
),
```

**Rationale**:
- Matches existing `ElevatedButtonTheme` sizing (C3 accessibility compliance)
- Uses `colorScheme.primary` background by default (forest600)
- `.tonal()` variant uses `colorScheme.secondaryContainer` (mint300/mint400)

---

### Task 4: Migrate primary CTAs to FilledButton

**Files to Update**:

#### `lib/screens/home_screen.dart`
- **Line 176**: "Get GPS Location" button (primary CTA)
- **Line 201**: "Set Manual Location" button (secondary → use `.tonal()`)

```dart
// Before (line 176)
child: ElevatedButton.icon(

// After
child: FilledButton.icon(

// Before (line 201)
child: ElevatedButton.icon(

// After
child: FilledButton.icon(
  style: FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
  ),
  // OR use FilledButton.tonal() if supported in Flutter 3.35.5
```

#### `lib/widgets/manual_location_dialog.dart`
- **Line 202**: "Save Location" button (primary CTA)

```dart
// Before
child: ElevatedButton(

// After
child: FilledButton(
```

#### `lib/widgets/risk_banner.dart`
- **Line 428**: "Call 101" button (secondary → use `.tonal()`)
- **Line 498**: "Call Crimestoppers" button (secondary → use `.tonal()`)

```dart
// Before (both)
child: ElevatedButton.icon(

// After
child: FilledButton.icon(
  style: FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
  ),
```

**Note**: Keep `OutlinedButton` in manual_location_dialog.dart line 192 (Cancel) - correct M3 hierarchy

---

### Task 5: Update EmergencyButton to use colorScheme.error

**File**: `lib/features/report/widgets/emergency_button.dart`

**Lines 84-115**: Replace amber with red error color

```dart
// Before (line 84 - light theme)
return ElevatedButton.styleFrom(
  backgroundColor: BrandPalette.amber500, // ❌ Amber

// After
return ElevatedButton.styleFrom(
  backgroundColor: Theme.of(context).colorScheme.error, // ✅ Red

// Before (line 99 - dark theme)
return ElevatedButton.styleFrom(
  backgroundColor: BrandPalette.amber600, // ❌ Amber

// After
return ElevatedButton.styleFrom(
  backgroundColor: Theme.of(context).colorScheme.error, // ✅ Red
```

**Special Case**: Keep `ElevatedButton` (not FilledButton) for 999 emergency  
**Rationale**: Elevated + pulse animation provides extra visual emphasis for critical action

---

### Task 6: Verify Card Widgets (NO CHANGES REQUIRED)

**Audit Results**:
- ✅ **RiskBanner Cards** (4 instances): Use RiskPalette colors (risk visualization - correct)
- ✅ **HomeScreen Cards** (2 instances): Use `theme.colorScheme.errorContainer` (correct M3)
- ✅ **ReportFireScreen** (line 238): Already uses `cs.secondaryContainer` (correct M3)

**Conclusion**: All Card widgets already follow M3 best practices. No migration needed.

---

### Task 7: WCAG 2.1 AA Contrast Verification

**Required Tests** (use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)):

| Foreground | Background | Min Ratio | Purpose |
|------------|-----------|-----------|---------|
| `BrandPalette.onLightHigh` | `BrandPalette.mint300` | ≥4.5:1 | Light secondaryContainer text |
| `BrandPalette.onDarkHigh` | `BrandPalette.mint400` | ≥4.5:1 | Dark secondaryContainer text |
| `Colors.redAccent.shade200` | `BrandPalette.forest500` | ≥4.5:1 | Dark error text on surface |
| `BrandPalette.onDarkHigh` | `Colors.redAccent.shade200` | ≥4.5:1 | Dark error container text |

**BrandPalette Color Values** (for checker):
- `mint300`: #7ED5CA
- `mint400`: #64C8BB
- `forest500`: #246F65
- `onLightHigh`: #212121 (~87% black)
- `onDarkHigh`: #FFFFFF (white)

**Action**: Document all ratios in `test/unit/theme/contrast_test.dart` (if exists) or test comments

---

### Task 8: Update Theme Unit Tests

**File**: `test/unit/theme/wildfire_a11y_theme_test.dart`

**Add Test Cases**:

```dart
test('Light theme has secondaryContainer colors', () {
  final theme = WildfireA11yTheme.light;
  expect(theme.colorScheme.secondaryContainer, equals(BrandPalette.mint300));
  expect(theme.colorScheme.onSecondaryContainer, equals(BrandPalette.onLightHigh));
});

test('Dark theme has secondaryContainer colors', () {
  final theme = WildfireA11yTheme.dark;
  expect(theme.colorScheme.secondaryContainer, equals(BrandPalette.mint400));
  expect(theme.colorScheme.onSecondaryContainer, equals(BrandPalette.onDarkHigh));
});

test('Dark theme uses red for error (not amber)', () {
  final theme = WildfireA11yTheme.dark;
  expect(theme.colorScheme.error, equals(Colors.redAccent.shade200));
  expect(theme.colorScheme.error, isNot(equals(BrandPalette.amber500)));
});

test('FilledButton theme has minimum 44dp height', () {
  final theme = WildfireA11yTheme.light;
  final style = theme.filledButtonTheme.style;
  expect(style?.minimumSize?.resolve({}), equals(const Size(64, 44)));
});
```

---

### Task 9: Update Widget Tests for FilledButton

**Files to Check**:

```bash
# Find tests expecting ElevatedButton for migrated widgets
grep -r "ElevatedButton" test/widget/home_screen_test.dart
grep -r "ElevatedButton" test/widget/manual_location_dialog_test.dart
grep -r "ElevatedButton" test/widget/risk_banner_test.dart
```

**Update Expectations**:
```dart
// Before
expect(find.byType(ElevatedButton), findsOneWidget);

// After
expect(find.byType(FilledButton), findsOneWidget);
```

**Golden Test Regeneration**:
If golden tests fail due to visual changes (FilledButton vs ElevatedButton styling):

```bash
# Regenerate all golden master images
./scripts/update_goldens.sh

# Or manually
flutter test --update-goldens test/widget/golden/
```

**Commit Message**: `test: update golden tests for FilledButton migration`

---

### Task 10: Run Full Test Suite + Analyzer

**Commands**:
```bash
# Format code
dart format lib/ test/

# Run analyzer (expect 0 issues)
flutter analyze

# Run all tests (expect all pass)
flutter test

# Check constitutional gates
./.specify/scripts/bash/constitution-gates.sh
```

**Expected Results**:
- ✅ `flutter analyze`: 0 errors, 0 warnings
- ✅ `flutter test`: All tests pass (may need golden updates)
- ✅ C1 (Code Quality): No test failures
- ✅ C3 (Accessibility): WCAG 2.1 AA maintained
- ✅ C4 (Transparency): Proper M3 semantic colors

**Troubleshooting**:
- **Import errors**: Add `import 'package:flutter/material.dart';` where FilledButton used
- **Golden failures**: Run `./scripts/update_goldens.sh`
- **Contrast failures**: Re-verify color values in WebAIM checker

---

### Task 11: Update CHANGELOG.md + Commit

**CHANGELOG.md Entry** (under `## [Unreleased]`):

```markdown
### Added
- Material 3 `secondaryContainer` and `onSecondaryContainer` colors to light/dark themes
- `FilledButtonTheme` for Material 3 button hierarchy

### Changed
- Migrated primary CTAs from `ElevatedButton` to `FilledButton` (Get GPS, Save Location, 101, Crimestoppers)
- Dark theme error color from amber to red for proper M3 error semantics
- EmergencyButton now uses `colorScheme.error` instead of hardcoded amber

### Fixed
- WCAG 2.1 AA contrast compliance verified for all new color combinations
- Material 3 compliance: proper semantic color usage per M3 spec

**Constitutional Gates**: C3 (Accessibility), C4 (Transparency)
```

**Commit Message** (Conventional Commits):
```bash
git add -A
git commit -m "feat(theme): Material 3 compliance - secondaryContainer, FilledButton, red error

- Add secondaryContainer (mint300/mint400) and onSecondaryContainer to ColorScheme
- Add FilledButtonTheme with ≥44dp touch targets (C3 compliance)
- Migrate ElevatedButton → FilledButton for primary CTAs (home, dialogs, risk banner)
- Fix dark theme error color: amber → red for proper M3 semantics
- Update EmergencyButton to use colorScheme.error (now red)
- Verify WCAG 2.1 AA contrast ratios ≥4.5:1 for all new colors
- Update theme unit tests for new ColorScheme properties
- Regenerate golden tests for FilledButton visual changes

Constitutional gates: C3 (Accessibility), C4 (Transparency)
Ref: Material 3 audit findings (2025-01-19)"
```

---

## Testing Checklist

Before committing, verify:

- [ ] Light theme renders correctly with secondaryContainer cards
- [ ] Dark theme shows red error color (not amber)
- [ ] FilledButton styling matches ElevatedButton sizing (≥44dp)
- [ ] FilledButton.tonal() uses secondaryContainer background
- [ ] EmergencyButton pulse animation still works with red error color
- [ ] All WCAG contrast ratios meet ≥4.5:1 for text
- [ ] Golden tests updated and passing
- [ ] No flutter analyze warnings
- [ ] All unit/widget tests pass
- [ ] Constitutional gates C1, C3, C4 pass

---

## Rollback Plan

If issues arise after implementation:

1. **Revert Commit**:
   ```bash
   git revert HEAD
   ```

2. **Incremental Rollback** (if only one task problematic):
   ```bash
   # Revert specific file
   git checkout HEAD~1 -- lib/theme/wildfire_a11y_theme.dart
   ```

3. **Regenerate Goldens** (if visual tests fail):
   ```bash
   ./scripts/update_goldens.sh
   ```

---

## References

### Material 3 Documentation
- [Material 3 Design Kit](https://m3.material.io/)
- [Color System](https://m3.material.io/styles/color/the-color-system/color-roles)
- [Flutter ColorScheme API](https://api.flutter.dev/flutter/material/ColorScheme-class.html)
- [FilledButton API](https://api.flutter.dev/flutter/material/FilledButton-class.html)

### WCAG 2.1 AA Compliance
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- Constitutional Gate C3 (Accessibility): ≥4.5:1 text, ≥3:1 UI components

### Internal Docs
- [Material 3 Compliance Audit](../MATERIAL_3_COMPLIANCE_AUDIT.md)
- [UX Cues - Color System](../ux_cues.md#color-system-architecture)
- [BrandPalette Documentation](../../lib/theme/brand_palette.dart)
- [WildfireA11yTheme Implementation](../../lib/theme/wildfire_a11y_theme.dart)

---

**Generated by**: AI Agent (GitHub Copilot)  
**Based on**: User-provided Material 3 audit and codebase analysis  
**Last Updated**: 2025-01-19
