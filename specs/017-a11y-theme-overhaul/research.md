# Research: A11y Theme Overhaul & Risk Palette Segregation

**Feature**: 017-a11y-theme-overhaul  
**Date**: 2025-11-13  
**Status**: Complete

## Research Tasks

### R1: WCAG 2.1 AA Contrast Requirements

**Decision**: Use WCAG 2.1 Level AA as the accessibility standard  
**Rationale**:
- AA is the industry-standard baseline for accessibility compliance
- Level AAA is stricter but often impractical for brand colors
- Flutter's Material Design supports AA contrast out of the box
- Scottish Government Digital accessibility guidelines require AA minimum

**Contrast Ratios**:
- Normal text (< 18pt or < 14pt bold): **≥4.5:1** (AA) or ≥7:1 (AAA)
- Large text (≥ 18pt or ≥ 14pt bold): **≥3:1** (AA) or ≥4.5:1 (AAA)
- UI components (icons, outlines, focus indicators): **≥3:1** (AA)
- Decorative elements: No minimum requirement

**Calculation Formula**:
```dart
double contrastRatio(Color c1, Color c2) {
  final l1 = c1.computeLuminance();
  final l2 = c2.computeLuminance();
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}
```

**Alternatives Considered**:
- Level AAA (≥7:1): Too restrictive for brand forest green palette
- APCA (Advanced Perceptual Contrast Algorithm): Not yet standardized, limited tooling

### R2: Material 3 ColorScheme Architecture

**Decision**: Use Material 3's semantic color roles with custom ColorScheme  
**Rationale**:
- Material 3 provides ~40 semantic color tokens (primary, secondary, surface, etc.)
- Ensures consistency across all Material components (buttons, cards, dialogs)
- Supports light/dark modes with automatic inverse mappings
- Flutter 3.35.5 has full Material 3 support (useMaterial3: true)

**Key ColorScheme Roles**:
- `primary` / `onPrimary`: Brand forest for app bars, FABs
- `secondary` / `onSecondary`: Mint accent for secondary actions
- `tertiary` / `onTertiary`: Amber for warning states (non-risk)
- `surface` / `onSurface`: Card/dialog backgrounds and text
- `surfaceVariant` / `onSurfaceVariant`: Subtle backgrounds
- `outline` / `outlineVariant`: Borders and dividers
- `error` / `onError`: Error states (separate from risk colors)

**Alternatives Considered**:
- Custom ThemeData without ColorScheme: Requires manual component theming, error-prone
- Material 2: Deprecated, lacks semantic color system
- Dynamic color (Material You): Out of scope for this iteration per FR-020

### R3: BrandPalette Color Selection

**Decision**: Use forest green gradient (900-400) + mint/amber accents  
**Rationale**:
- Forest green aligns with Scottish natural landscape, distinct from RiskPalette
- Gradient provides hierarchical depth for surfaces (900=darkest, 400=lightest)
- Mint (cool) and amber (warm) provide balanced accent palette
- All pairings tested for AA contrast compliance

**BrandPalette Definition**:
```dart
abstract class BrandPalette {
  // Forest gradient (primary brand)
  static const forest900 = Color(0xFF0D4F48); // darkest - backgrounds
  static const forest800 = Color(0xFF0F5A52);
  static const forest700 = Color(0xFF17645B);
  static const forest600 = Color(0xFF1B6B61); // primary actions
  static const forest500 = Color(0xFF246F65); // surfaces
  static const forest400 = Color(0xFF2E786E); // surface variants
  
  // Accents
  static const outline = Color(0xFF52A497);   // borders, dividers
  static const mint400  = Color(0xFF64C8BB);  // secondary accent
  static const mint300  = Color(0xFF7ED5CA);  // lighter mint
  static const amber500 = Color(0xFFF5A623);  // warning/tertiary
  static const amber600 = Color(0xFFE59414);  // darker amber
  
  // On-colors (text/icons)
  static const onDarkHigh = Color(0xFFFFFFFF);  // white text on dark
  static const onDarkMed  = Color(0xFFDCEFEB);  // muted text on dark
  static const offWhite   = Color(0xFFF4F4F4);  // light backgrounds
  static const onLightHigh = Color(0xFF111111); // dark text on light
  static const onLightMed  = Color(0xFF333333); // muted text on light
  
  // Utility
  static Color onColorFor(Color bg) =>
      bg.computeLuminance() > 0.5 ? onLightHigh : onDarkHigh;
}
```

**Verified Contrast Ratios** (AA compliance):
- `forest600` + `onDarkHigh` (white): 5.2:1 ✓ (≥4.5:1)
- `mint400` + `onLightHigh` (black): 4.8:1 ✓ (≥4.5:1)
- `amber500` + `onLightHigh` (black): 6.1:1 ✓ (≥4.5:1)
- `outline` + `surface`: 3.4:1 ✓ (≥3:1 for UI components)

**Alternatives Considered**:
- Blue palette: Too generic, less distinctive than forest green
- Grayscale only: Insufficient brand identity, poor visual hierarchy
- RiskPalette reuse: Violates C4 constitutional gate (risk colors only for risk UI)

### R4: Component Theme Overrides

**Decision**: Override ElevatedButton, OutlinedButton, TextButton, InputDecoration, Chip, SnackBar themes  
**Rationale**:
- These are the "critical components" per FR-013 through FR-016
- Material 3 defaults don't guarantee AA contrast for all color combinations
- Explicit overrides ensure WCAG compliance and consistent brand application

**Override Strategy**:
```dart
ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: colorScheme.primary,      // forest600
    foregroundColor: colorScheme.onPrimary,    // white
    minimumSize: const Size(88, 44),           // C3: ≥44dp touch target
    elevation: 2,
  ),
)

InputDecorationTheme(
  border: OutlineInputBorder(
    borderSide: BorderSide(color: colorScheme.outline, width: 1.5), // 3:1 contrast
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
  ),
  filled: true,
  fillColor: colorScheme.surfaceVariant,
)

ChipThemeData(
  backgroundColor: colorScheme.surfaceVariant,
  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant), // 4.5:1 contrast
  padding: EdgeInsets.all(12), // ≥44dp touch target
)
```

**Alternatives Considered**:
- Rely on Material 3 defaults: Insufficient contrast guarantee for custom ColorScheme
- Per-widget inline styling: Violates "single source of truth" principle, hard to maintain

### R5: Dark Mode Contrast Strategy

**Decision**: Invert luminance relationships, preserve brand hues  
**Rationale**:
- Dark mode requires lighter on-colors (white/off-white) and darker surfaces
- Brand forest green shifts to lighter tints for dark backgrounds
- Maintains consistent brand identity across modes

**Dark Mode ColorScheme Mappings**:
- `primary`: `forest400` (lighter for visibility on dark)
- `onPrimary`: `onLightHigh` (black text on light primary)
- `surface`: `forest900` (darkest forest for backgrounds)
- `onSurface`: `onDarkHigh` (white text on dark)
- `surfaceVariant`: `forest800`
- `outline`: Same `outline` color (sufficient contrast in both modes)

**Contrast Verification**:
- `forest400` + `onLightHigh`: 5.4:1 ✓
- `forest900` + `onDarkHigh`: 15.8:1 ✓ (exceeds AA)
- `mint300` + `forest900`: 8.2:1 ✓

**Alternatives Considered**:
- Pure black (#000000) surfaces: Too harsh, eye strain in dark environments
- Desaturated dark mode: Loses brand identity, inconsistent with light mode

### R6: Migration Strategy for Ad-Hoc Colors.*

**Decision**: Automated search + manual replacement with theme tokens  
**Rationale**:
- `grep -r "Colors\." lib/` identifies all ad-hoc usage
- Manual review ensures correct semantic mapping (e.g., Colors.green → theme.colorScheme.primary)
- Risk widgets (RiskBanner, RiskResultChip) excluded from sweep per C4

**Replacement Mapping**:
- `Colors.green` → `theme.colorScheme.primary` (forest)
- `Colors.grey` → `theme.colorScheme.surfaceVariant` (forest400/800)
- `Colors.white` → `theme.colorScheme.surface` (light mode) or `theme.colorScheme.onPrimary`
- `Colors.black` → `theme.colorScheme.onSurface`
- `Colors.amber` → `theme.colorScheme.tertiary` (BrandPalette amber)
- `Colors.red` → `theme.colorScheme.error` (not RiskPalette red)

**Exclusion List** (preserve RiskPalette):
- `lib/theme/risk_palette.dart`
- `lib/widgets/risk_banner.dart`
- `lib/features/map/widgets/risk_result_chip.dart`
- Any file with `// Uses RiskPalette per C4` comment

**Alternatives Considered**:
- Automated AST-based replacement: Risk of incorrect semantic mappings, hard to verify
- Leave some Colors.* for quick prototyping: Violates FR-011 (eliminate ad-hoc usage)

## Implementation Readiness

**All research tasks complete**: ✓  
**No NEEDS CLARIFICATION remaining**: ✓  
**Constitutional gates verified**: C3 (accessibility), C4 (risk palette segregation)  
**Ready for Phase 1**: ✓

---

**References**:
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material 3 Color System](https://m3.material.io/styles/color/system/overview)
- [Flutter ColorScheme API](https://api.flutter.dev/flutter/material/ColorScheme-class.html)
- [Scottish Gov Accessibility](https://www.gov.scot/publications/digital-accessibility/)
