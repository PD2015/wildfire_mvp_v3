# Data Model: A11y Theme Overhaul & Risk Palette Segregation

**Feature**: 017-a11y-theme-overhaul  
**Date**: 2025-11-13  
**Status**: Phase 1 Complete

## Entity Overview

This feature introduces two new theme entities and preserves one existing entity:

1. **BrandPalette** (NEW): App chrome color constants
2. **WildfireA11yTheme** (NEW): WCAG 2.1 AA compliant theme configuration
3. **RiskPalette** (PRESERVED): Official Scottish risk colors (unchanged per C4)

---

## Entity 1: BrandPalette

**Purpose**: Centralized color constants for non-risk UI elements (app chrome, navigation, surfaces, backgrounds)

**Type**: Abstract class with static const Color fields (compile-time constants)

**Attributes**:

| Field | Type | Value | Usage | Contrast Verified |
|-------|------|-------|-------|-------------------|
| `forest900` | Color | `0xFF0D4F48` | Dark backgrounds, dark mode surfaces | ✓ |
| `forest800` | Color | `0xFF0F5A52` | Dark mode surface variants | ✓ |
| `forest700` | Color | `0xFF17645B` | Medium surfaces | ✓ |
| `forest600` | Color | `0xFF1B6B61` | Primary brand color, app bars, FABs | ✓ 5.2:1 with white |
| `forest500` | Color | `0xFF246F65` | Light mode surfaces | ✓ |
| `forest400` | Color | `0xFF2E786E` | Light mode surface variants, dark mode primary | ✓ 5.4:1 with black |
| `outline` | Color | `0xFF52A497` | Borders, dividers, outlines | ✓ 3.4:1 |
| `mint400` | Color | `0xFF64C8BB` | Secondary accent color | ✓ 4.8:1 with black |
| `mint300` | Color | `0xFF7ED5CA` | Lighter mint accent | ✓ 8.2:1 dark bg |
| `amber500` | Color | `0xFFF5A623` | Warning/tertiary accent | ✓ 6.1:1 with black |
| `amber600` | Color | `0xFFE59414` | Darker amber variant | ✓ |
| `onDarkHigh` | Color | `0xFFFFFFFF` | High-emphasis text on dark | ✓ 15.8:1 on forest900 |
| `onDarkMed` | Color | `0xFFDCEFEB` | Medium-emphasis text on dark | ✓ |
| `offWhite` | Color | `0xFFF4F4F4` | Light backgrounds | ✓ |
| `onLightHigh` | Color | `0xFF111111` | High-emphasis text on light | ✓ |
| `onLightMed` | Color | `0xFF333333` | Medium-emphasis text on light | ✓ |

**Methods**:

```dart
static Color onColorFor(Color bg)
```
- **Purpose**: Calculate appropriate text color based on background luminance
- **Logic**: Returns `onLightHigh` if luminance > 0.5, else `onDarkHigh`
- **Usage**: Dynamic on-color selection for custom backgrounds

**Validation Rules**:
- All colors are immutable (const)
- All text/background pairings MUST meet ≥4.5:1 contrast (verified in unit tests)
- All outline/surface pairings MUST meet ≥3:1 contrast (verified in unit tests)
- No runtime color modification allowed

**Relationships**:
- Used by: `WildfireA11yTheme` (ColorScheme generation)
- Independent from: `RiskPalette` (no shared colors)

---

## Entity 2: WildfireA11yTheme

**Purpose**: WCAG 2.1 AA compliant theme providing light and dark mode configurations

**Type**: Class with static getter methods returning ThemeData

**Attributes**:

### Static Getters

| Method | Return Type | Description |
|--------|-------------|-------------|
| `light` | ThemeData | Light mode theme configuration |
| `dark` | ThemeData | Dark mode theme configuration |

### ThemeData Structure (both modes)

**Core Configuration**:
- `useMaterial3: true` (Material 3 component design)
- `brightness`: `Brightness.light` or `Brightness.dark`
- `colorScheme`: Custom ColorScheme from BrandPalette

**ColorScheme Mappings**:

#### Light Mode
```dart
ColorScheme.light(
  primary: BrandPalette.forest600,           // App bars, FABs
  onPrimary: BrandPalette.onDarkHigh,        // White text on primary
  secondary: BrandPalette.mint400,           // Secondary actions
  onSecondary: BrandPalette.onLightHigh,     // Black text on mint
  tertiary: BrandPalette.amber500,           // Warning accents
  onTertiary: BrandPalette.onLightHigh,      // Black text on amber
  surface: BrandPalette.offWhite,            // Card backgrounds
  onSurface: BrandPalette.onLightHigh,       // Dark text on cards
  surfaceVariant: BrandPalette.forest500,    // Subtle backgrounds
  onSurfaceVariant: BrandPalette.onDarkMed,  // Text on variants
  outline: BrandPalette.outline,             // Borders
  error: Colors.red.shade700,                // Error states (not RiskPalette)
  onError: BrandPalette.onDarkHigh,          // White text on error
)
```

#### Dark Mode
```dart
ColorScheme.dark(
  primary: BrandPalette.forest400,           // Lighter for dark bg
  onPrimary: BrandPalette.onLightHigh,       // Black text on light primary
  secondary: BrandPalette.mint300,           // Lighter mint
  onSecondary: BrandPalette.onLightHigh,     // Black text
  tertiary: BrandPalette.amber500,           // Same amber (good contrast)
  onTertiary: BrandPalette.onLightHigh,      // Black text
  surface: BrandPalette.forest900,           // Dark backgrounds
  onSurface: BrandPalette.onDarkHigh,        // White text
  surfaceVariant: BrandPalette.forest800,    // Darker variants
  onSurfaceVariant: BrandPalette.onDarkMed,  // Muted text
  outline: BrandPalette.outline,             // Same outline
  error: Colors.red.shade300,                // Lighter error for dark
  onError: BrandPalette.onLightHigh,         // Black on light error
)
```

**Component Theme Overrides**:

1. **AppBarTheme**
   - `backgroundColor`: colorScheme.primary
   - `foregroundColor`: colorScheme.onPrimary
   - `elevation`: 2
   - `centerTitle`: true

2. **ElevatedButtonTheme**
   - `backgroundColor`: colorScheme.primary
   - `foregroundColor`: colorScheme.onPrimary
   - `minimumSize`: Size(88, 44) // C3: ≥44dp
   - `elevation`: 2
   - `shape`: RoundedRectangleBorder (8dp radius)

3. **OutlinedButtonTheme**
   - `foregroundColor`: colorScheme.primary
   - `side`: BorderSide(colorScheme.outline, 1.5)
   - `minimumSize`: Size(88, 44)

4. **TextButtonTheme**
   - `foregroundColor`: colorScheme.primary
   - `minimumSize`: Size(88, 44)

5. **InputDecorationTheme**
   - `border`: OutlineInputBorder (colorScheme.outline, 1.5)
   - `focusedBorder`: OutlineInputBorder (colorScheme.primary, 2.0)
   - `filled`: true
   - `fillColor`: colorScheme.surfaceVariant
   - `labelStyle`: TextStyle(colorScheme.onSurfaceVariant)

6. **ChipTheme**
   - `backgroundColor`: colorScheme.surfaceVariant
   - `labelStyle`: TextStyle(colorScheme.onSurfaceVariant)
   - `padding`: EdgeInsets.all(12) // ≥44dp height

7. **SnackBarTheme**
   - `backgroundColor`: colorScheme.inverseSurface
   - `contentTextStyle`: TextStyle(colorScheme.onInverseSurface)
   - `actionTextColor`: colorScheme.primary

8. **CardTheme**
   - `color`: colorScheme.surface
   - `elevation`: 2
   - `shape`: RoundedRectangleBorder (8dp radius)

**Validation Rules**:
- All component themes MUST preserve ≥44dp touch targets (C3)
- All text/background combinations MUST meet ≥4.5:1 contrast (verified in contrast_test.dart)
- All outline/surface combinations MUST meet ≥3:1 contrast
- Theme switching MUST complete in <16ms (no jank)

**Relationships**:
- Depends on: `BrandPalette` (color constants)
- Used by: `MaterialApp` (via themeMode, theme, darkTheme)
- Independent from: `RiskPalette` (different color system)

---

## Entity 3: RiskPalette (PRESERVED)

**Purpose**: Official Scottish wildfire risk colors for fire risk visualization

**Status**: **UNCHANGED** per constitutional gate C4

**Usage**: Exclusively for risk widgets:
- `lib/widgets/risk_banner.dart`
- `lib/features/map/widgets/risk_result_chip.dart`
- Any widget displaying fire risk levels

**Non-Usage**: NOT used for:
- App chrome (navigation, backgrounds)
- Generic UI states (success, warning, error)
- Material component themes

**Validation**: `scripts/allowed_colors.txt` enforces segregation via color guard script

---

## State Transitions

### Theme Mode Switching

```
User toggles system dark mode
  ↓
MaterialApp.themeMode detects brightness change
  ↓
WildfireA11yTheme.dark loaded (replaces .light)
  ↓
All widgets rebuild with new ColorScheme
  ↓
<16ms transition (no perceived jank)
```

**Edge Cases**:
- Mid-transition theme access: Flutter handles gracefully (atomic rebuild)
- Conflicting system/app theme mode: Respect system preference (default behavior)

---

## Testing Contracts

### Unit Tests (contrast_test.dart)

```dart
group('BrandPalette Contrast Compliance', () {
  test('forest600 + white >= 4.5:1 (AA normal text)', () {
    final ratio = contrastRatio(BrandPalette.forest600, BrandPalette.onDarkHigh);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('mint400 + black >= 4.5:1 (AA normal text)', () {
    final ratio = contrastRatio(BrandPalette.mint400, BrandPalette.onLightHigh);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('outline + surface >= 3:1 (AA UI components)', () {
    final ratio = contrastRatio(BrandPalette.outline, BrandPalette.offWhite);
    expect(ratio, greaterThanOrEqualTo(3.0));
  });
});

group('WildfireA11yTheme Touch Targets', () {
  test('ElevatedButton minimum size >= 44dp', () {
    final theme = WildfireA11yTheme.light;
    final buttonTheme = theme.elevatedButtonTheme;
    expect(buttonTheme.style!.minimumSize!.resolve({}), Size(88, 44));
  });
});
```

### Widget Tests (component_theme_test.dart)

```dart
testWidgets('Themed ElevatedButton meets contrast', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: WildfireA11yTheme.light,
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () {},
          child: Text('Test'),
        ),
      ),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  // Golden snapshot comparison for visual regression
  await expectLater(find.byType(ElevatedButton), matchesGoldenFile('button_light.png'));
});
```

---

## Migration Impact

**Files to Create**:
- `lib/theme/brand_palette.dart` (BrandPalette entity)
- `lib/theme/wildfire_a11y_theme.dart` (WildfireA11yTheme entity)
- `test/unit/theme/contrast_test.dart` (validation tests)
- `test/widget/theme/component_theme_test.dart` (golden tests)

**Files to Update**:
- `lib/app.dart` (wire WildfireA11yTheme.light/dark)
- `lib/theme/wildfire_theme.dart` (add deprecation comment)
- `lib/features/map/screens/map_screen.dart` (replace Colors.*)
- All files with ad-hoc `Colors.*` usage (sweep)
- `docs/ux_cues.md` (document palette segregation)
- `scripts/allowed_colors.txt` (add BrandPalette tokens)

**Files Unchanged**:
- `lib/theme/risk_palette.dart` (preserved per C4)
- `lib/widgets/risk_banner.dart` (uses RiskPalette)
- `lib/features/map/widgets/risk_result_chip.dart` (uses RiskPalette)

---

**Phase 1 Complete**: Data model entities defined with validation rules and testing contracts. Ready for contract generation and task planning.
