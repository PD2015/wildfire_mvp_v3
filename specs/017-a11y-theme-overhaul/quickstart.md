# Quickstart: A11y Theme Overhaul Verification

**Feature**: 017-a11y-theme-overhaul  
**Date**: 2025-11-13  
**Purpose**: Manual verification steps for WCAG 2.1 AA compliance

## Prerequisites

- Implementation complete (all tasks.md items done)
- All unit tests passing (`flutter test test/unit/theme/`)
- All widget tests passing (`flutter test test/widget/theme/`)
- App builds successfully (`flutter build apk` or `flutter build ios`)

---

## Quick Verification Steps

### Step 1: Run Automated Tests

```bash
# Run all theme-related tests
flutter test test/unit/theme/
flutter test test/widget/theme/

# Run color guard script
./scripts/color_guard.sh

# Run ad-hoc colors verification
./scripts/verify_no_adhoc_colors.sh

# Expected: All tests PASS, no violations
```

**Success Criteria**: ✅ Zero test failures, zero color violations

---

### Step 2: Visual Verification - Light Mode

```bash
# Run app in light mode
flutter run -d <device>
```

**Manual Checks**:

1. **App Bar**
   - [ ] Background: Forest green (#1B6B61)
   - [ ] Title text: White, clearly readable
   - [ ] Icons: White, ≥3:1 contrast

2. **ElevatedButton**
   - [ ] Background: Forest green primary
   - [ ] Text: White, clearly readable
   - [ ] Touch target: ≥44dp tap area (verify with taps near edges)

3. **OutlinedButton**
   - [ ] Text: Forest green, clearly readable on white/light surface
   - [ ] Outline: Visible border with ≥3:1 contrast
   - [ ] Touch target: ≥44dp

4. **TextButton**
   - [ ] Text: Forest green, clearly readable
   - [ ] Touch target: ≥44dp

5. **Text Input Fields**
   - [ ] Border: Outline color, clearly visible
   - [ ] Focused border: Primary forest green, 2px width
   - [ ] Fill color: Subtle forest variant background
   - [ ] Text: Dark on light, ≥4.5:1 contrast

6. **Chips**
   - [ ] Background: Surface variant (forest500)
   - [ ] Text: Muted on-color, readable
   - [ ] Touch target: ≥44dp height

7. **Snackbars**
   - [ ] Background: Inverse surface
   - [ ] Text: High contrast on-inverse-surface
   - [ ] Action text: Primary color, ≥4.5:1

8. **Fire Risk Banner** (RiskPalette - unchanged)
   - [ ] Uses RiskPalette colors (NOT BrandPalette)
   - [ ] Risk level colors unchanged from previous version
   - [ ] Timestamp and source label visible

---

### Step 3: Visual Verification - Dark Mode

```bash
# Enable dark mode on device/emulator, then run app
flutter run -d <device>
```

**Manual Checks**:

1. **App Bar**
   - [ ] Background: Lighter forest (#2E786E) for visibility on dark
   - [ ] Title text: Black/dark text on light primary
   - [ ] Icons: Dark, ≥3:1 contrast

2. **Surfaces (Cards, Dialogs)**
   - [ ] Background: Dark forest (#0D4F48)
   - [ ] Text: White, ≥4.5:1 contrast
   - [ ] Elevation: Visible depth cues

3. **ElevatedButton**
   - [ ] Background: Lighter primary (forest400)
   - [ ] Text: Dark, clearly readable
   - [ ] Touch target: ≥44dp

4. **Text Input Fields**
   - [ ] Border: Outline still visible in dark mode
   - [ ] Fill color: Dark variant background
   - [ ] Text: White on dark, ≥4.5:1

5. **Status Bar** (T010 verification)
   - [ ] Icons/time visible against primary/charcoal backgrounds
   - [ ] Switch between light/dark: status bar adapts properly

6. **Fire Risk Banner** (Dark Mode)
   - [ ] RiskPalette colors remain unchanged (no dark mode variants)
   - [ ] Text luminance-adjusted for readability
   - [ ] Cached badge visible in dark mode

---

### Step 4: Contrast Ratio Verification

Use browser DevTools or contrast checker tool:

**Light Mode Pairs**:
```
forest600 (#1B6B61) + white (#FFFFFF)
Expected: ≥5.0:1 (exceeds AA 4.5:1)

mint400 (#64C8BB) + black (#111111)
Expected: ≥4.8:1 (exceeds AA)

amber500 (#F5A623) + black (#111111)
Expected: ≥6.1:1 (exceeds AA)

outline (#52A497) + offWhite (#F4F4F4)
Expected: ≥3.4:1 (exceeds AA 3:1 for UI)
```

**Dark Mode Pairs**:
```
forest400 (#2E786E) + black (#111111)
Expected: ≥5.4:1

forest900 (#0D4F48) + white (#FFFFFF)
Expected: ≥15.8:1 (exceeds AAA)

mint300 (#7ED5CA) + forest900
Expected: ≥8.2:1
```

**Verification Tool**: [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

---

### Step 5: Accessibility Screen Reader Test

**iOS VoiceOver**:
```bash
flutter run -d iphone
# Enable VoiceOver: Settings > Accessibility > VoiceOver
```

1. Navigate to each button, input, chip
2. [ ] Screen reader announces label correctly
3. [ ] Touch targets are easy to hit (≥44dp)
4. [ ] Focus indicators visible when element selected

**Android TalkBack**:
```bash
flutter run -d android
# Enable TalkBack: Settings > Accessibility > TalkBack
```

1. Navigate through UI elements
2. [ ] Semantic labels announced correctly
3. [ ] Touch targets accessible
4. [ ] Focus order logical (top to bottom, left to right)

---

### Step 6: Theme Mode Switching Performance

```bash
# Run app with Flutter DevTools performance overlay
flutter run --profile -d <device>
```

1. Open app in light mode
2. Switch system theme to dark mode
3. [ ] UI rebuilds in <16ms (no perceived jank)
4. [ ] No frame drops in DevTools timeline
5. [ ] All widgets render correctly in new theme

**Switch back to light**:
1. [ ] Same smooth transition
2. [ ] No visual artifacts or flickering

---

### Step 7: Ad-Hoc Colors Sweep Verification

```bash
# Search for any remaining Colors.* usage (excluding risk widgets)
grep -r "Colors\." lib/ --exclude-dir=theme | grep -v "import" | grep -v "risk_palette.dart" | grep -v "risk_banner.dart" | grep -v "risk_result_chip.dart"

# Expected: No matches (or only intentional exceptions with comments)
```

**Manual Code Review**:
1. [ ] `lib/app.dart` uses `WildfireA11yTheme.light/dark`
2. [ ] `lib/theme/wildfire_theme.dart` has deprecation comment
3. [ ] `lib/features/map/screens/map_screen.dart` uses `theme.colorScheme.*` instead of `Colors.*`
4. [ ] No ad-hoc `Colors.*` in widgets (sweep complete)

---

### Step 8: Documentation Verification

1. [ ] `docs/ux_cues.md` updated with BrandPalette vs RiskPalette usage
2. [ ] `scripts/allowed_colors.txt` includes all BrandPalette tokens
3. [ ] `lib/theme/brand_palette.dart` has dartdoc comments
4. [ ] `lib/theme/wildfire_a11y_theme.dart` has usage examples in docs

---

### Step 9: CI/CD Integration Check

```bash
# Run local CI checks
flutter analyze
dart format --set-exit-if-changed .
flutter test

# Expected: All PASS
```

**GitHub Actions** (if merged to main):
1. [ ] Analyze job passes
2. [ ] Test job passes (all unit/widget tests)
3. [ ] Color guard script passes in CI

---

## Acceptance Checklist

### Functional Requirements (from spec.md)

- [ ] **FR-001**: WildfireA11yTheme provides light and dark modes
- [ ] **FR-002**: Material 3 (useMaterial3: true) used
- [ ] **FR-003**: BrandPalette defined with app chrome tokens
- [ ] **FR-004**: MaterialApp wired to WildfireA11yTheme
- [ ] **FR-005**: Normal text ≥4.5:1 contrast in both modes
- [ ] **FR-006**: Large text/UI glyphs ≥3:1 contrast
- [ ] **FR-007**: Touch targets ≥44dp maintained
- [ ] **FR-008**: Semantic labels preserved
- [ ] **FR-009**: RiskPalette preserved unchanged (C4)
- [ ] **FR-010**: RiskPalette NOT used for app chrome
- [ ] **FR-011**: Ad-hoc Colors.* eliminated
- [ ] **FR-012**: Color token usage documented
- [ ] **FR-013-017**: Critical components (buttons, inputs, chips, snackbars, outlines) meet contrast requirements

### Constitutional Gates

- [ ] **C1**: flutter analyze passes, tests included
- [ ] **C2**: No secrets (N/A for theme), no PII logging
- [ ] **C3**: ≥44dp touch targets, semantic labels, contrast verified
- [ ] **C4**: RiskPalette unchanged, color segregation enforced
- [ ] **C5**: N/A (no network calls in theme layer)

---

## Troubleshooting

### Issue: Text unreadable in light mode
**Check**: Verify ColorScheme primary/onPrimary contrast in unit tests  
**Fix**: Adjust BrandPalette color if <4.5:1 ratio

### Issue: Dark mode surfaces too dark/too light
**Check**: Compare forest900/forest800 luminance values  
**Fix**: Adjust gradient in BrandPalette, rerun contrast tests

### Issue: Button touch targets feel small
**Check**: Measure actual tap area with layout inspector  
**Fix**: Increase minimumSize or padding in component theme

### Issue: Risk banner using wrong colors
**Check**: Verify risk_banner.dart still imports RiskPalette  
**Fix**: Ensure sweep didn't accidentally replace RiskPalette colors

### Issue: Theme switching lags
**Check**: Flutter DevTools performance timeline  
**Fix**: Reduce widget rebuilds, use const constructors where possible

---

## Success Criteria

✅ All automated tests pass  
✅ All manual verification steps complete  
✅ Zero color violations in color guard  
✅ Zero ad-hoc Colors.* usage outside risk widgets  
✅ WCAG 2.1 AA contrast ratios verified  
✅ Touch targets ≥44dp verified  
✅ Screen reader navigation works correctly  
✅ Theme mode switching smooth (<16ms)  
✅ Documentation updated  
✅ CI/CD passes

---

**Estimated Verification Time**: 30-45 minutes  
**Recommended Devices**: iOS simulator, Android emulator, macOS web (Chrome)

**Sign-off**: _______________ (Developer) | Date: _______________
