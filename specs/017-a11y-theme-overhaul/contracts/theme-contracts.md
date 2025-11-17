# Theme API Contracts

**Feature**: 017-a11y-theme-overhaul  
**Date**: 2025-11-13  
**Type**: Static Configuration Contracts

## Contract 1: BrandPalette API

### Interface

```dart
abstract class BrandPalette {
  // Forest gradient (primary brand)
  static const Color forest900;
  static const Color forest800;
  static const Color forest700;
  static const Color forest600;
  static const Color forest500;
  static const Color forest400;
  
  // Accents
  static const Color outline;
  static const Color mint400;
  static const Color mint300;
  static const Color amber500;
  static const Color amber600;
  
  // On-colors (text/icons)
  static const Color onDarkHigh;
  static const Color onDarkMed;
  static const Color offWhite;
  static const Color onLightHigh;
  static const Color onLightMed;
  
  // Utility
  static Color onColorFor(Color bg);
}
```

### Contract Tests

**File**: `test/unit/theme/brand_palette_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

// Contrast calculation helper
double contrastRatio(Color c1, Color c2) {
  final l1 = c1.computeLuminance();
  final l2 = c2.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('BrandPalette Color Constants', () {
    test('all forest gradient colors are defined', () {
      expect(BrandPalette.forest900, isA<Color>());
      expect(BrandPalette.forest800, isA<Color>());
      expect(BrandPalette.forest700, isA<Color>());
      expect(BrandPalette.forest600, isA<Color>());
      expect(BrandPalette.forest500, isA<Color>());
      expect(BrandPalette.forest400, isA<Color>());
    });

    test('all accent colors are defined', () {
      expect(BrandPalette.outline, isA<Color>());
      expect(BrandPalette.mint400, isA<Color>());
      expect(BrandPalette.mint300, isA<Color>());
      expect(BrandPalette.amber500, isA<Color>());
      expect(BrandPalette.amber600, isA<Color>());
    });

    test('all on-colors are defined', () {
      expect(BrandPalette.onDarkHigh, isA<Color>());
      expect(BrandPalette.onDarkMed, isA<Color>());
      expect(BrandPalette.offWhite, isA<Color>());
      expect(BrandPalette.onLightHigh, isA<Color>());
      expect(BrandPalette.onLightMed, isA<Color>());
    });
  });

  group('BrandPalette WCAG AA Contrast Compliance', () {
    test('forest600 + onDarkHigh >= 4.5:1 (normal text)', () {
      final ratio = contrastRatio(BrandPalette.forest600, BrandPalette.onDarkHigh);
      expect(ratio, greaterThanOrEqualTo(4.5), 
        reason: 'Primary brand color must meet AA contrast with white text');
    });

    test('forest400 + onLightHigh >= 4.5:1 (dark mode primary)', () {
      final ratio = contrastRatio(BrandPalette.forest400, BrandPalette.onLightHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Dark mode primary must meet AA contrast with black text');
    });

    test('mint400 + onLightHigh >= 4.5:1 (secondary accent)', () {
      final ratio = contrastRatio(BrandPalette.mint400, BrandPalette.onLightHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Mint accent must meet AA contrast for buttons');
    });

    test('amber500 + onLightHigh >= 4.5:1 (tertiary accent)', () {
      final ratio = contrastRatio(BrandPalette.amber500, BrandPalette.onLightHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Amber accent must meet AA contrast for warning states');
    });

    test('outline + offWhite >= 3:1 (UI components)', () {
      final ratio = contrastRatio(BrandPalette.outline, BrandPalette.offWhite);
      expect(ratio, greaterThanOrEqualTo(3.0),
        reason: 'Outline must meet AA contrast for borders and dividers');
    });

    test('forest900 + onDarkHigh >= 4.5:1 (dark mode surface)', () {
      final ratio = contrastRatio(BrandPalette.forest900, BrandPalette.onDarkHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Dark mode surface must meet AA contrast with white text');
    });
  });

  group('BrandPalette.onColorFor utility', () {
    test('returns onLightHigh for light backgrounds', () {
      final result = BrandPalette.onColorFor(BrandPalette.offWhite);
      expect(result, equals(BrandPalette.onLightHigh));
    });

    test('returns onDarkHigh for dark backgrounds', () {
      final result = BrandPalette.onColorFor(BrandPalette.forest900);
      expect(result, equals(BrandPalette.onDarkHigh));
    });

    test('luminance threshold is 0.5', () {
      final lightColor = Color(0xFF808080); // ~0.5 luminance
      final darkColor = Color(0xFF404040);  // <0.5 luminance
      
      expect(lightColor.computeLuminance(), greaterThan(0.5));
      expect(darkColor.computeLuminance(), lessThan(0.5));
      
      expect(BrandPalette.onColorFor(lightColor), equals(BrandPalette.onLightHigh));
      expect(BrandPalette.onColorFor(darkColor), equals(BrandPalette.onDarkHigh));
    });
  });
}
```

**Expected Result**: All tests FAIL (implementation not yet created)

---

## Contract 2: WildfireA11yTheme API

### Interface

```dart
class WildfireA11yTheme {
  static ThemeData get light;
  static ThemeData get dark;
}
```

### Contract Tests

**File**: `test/unit/theme/wildfire_a11y_theme_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/wildfire_a11y_theme.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

void main() {
  group('WildfireA11yTheme.light', () {
    late ThemeData theme;

    setUp(() {
      theme = WildfireA11yTheme.light;
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has light brightness', () {
      expect(theme.brightness, equals(Brightness.light));
    });

    test('colorScheme uses BrandPalette colors', () {
      expect(theme.colorScheme.primary, equals(BrandPalette.forest600));
      expect(theme.colorScheme.onPrimary, equals(BrandPalette.onDarkHigh));
      expect(theme.colorScheme.secondary, equals(BrandPalette.mint400));
      expect(theme.colorScheme.tertiary, equals(BrandPalette.amber500));
      expect(theme.colorScheme.surface, equals(BrandPalette.offWhite));
    });

    test('ElevatedButton has >= 44dp minimum size (C3)', () {
      final buttonStyle = theme.elevatedButtonTheme.style!;
      final minSize = buttonStyle.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(44));
    });

    test('OutlinedButton has >= 44dp minimum size (C3)', () {
      final buttonStyle = theme.outlinedButtonTheme.style!;
      final minSize = buttonStyle.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(44));
    });

    test('TextButton has >= 44dp minimum size (C3)', () {
      final buttonStyle = theme.textButtonTheme.style!;
      final minSize = buttonStyle.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(44));
    });

    test('InputDecoration uses outline border', () {
      final inputTheme = theme.inputDecorationTheme;
      expect(inputTheme.border, isA<OutlineInputBorder>());
      expect(inputTheme.filled, isTrue);
    });

    test('ChipTheme has sufficient padding for touch target', () {
      final chipTheme = theme.chipTheme;
      expect(chipTheme.padding, isNotNull);
      // Padding should contribute to >= 44dp height
    });
  });

  group('WildfireA11yTheme.dark', () {
    late ThemeData theme;

    setUp(() {
      theme = WildfireA11yTheme.dark;
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has dark brightness', () {
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('colorScheme uses lighter BrandPalette colors for dark mode', () {
      expect(theme.colorScheme.primary, equals(BrandPalette.forest400));
      expect(theme.colorScheme.surface, equals(BrandPalette.forest900));
      expect(theme.colorScheme.onSurface, equals(BrandPalette.onDarkHigh));
    });

    test('maintains >= 44dp touch targets in dark mode', () {
      final buttonStyle = theme.elevatedButtonTheme.style!;
      final minSize = buttonStyle.minimumSize!.resolve({});
      expect(minSize!.height, greaterThanOrEqualTo(44));
    });
  });

  group('WildfireA11yTheme Contrast Verification', () {
    double contrastRatio(Color c1, Color c2) {
      final l1 = c1.computeLuminance();
      final l2 = c2.computeLuminance();
      final lighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('light theme primary/onPrimary >= 4.5:1', () {
      final theme = WildfireA11yTheme.light;
      final ratio = contrastRatio(
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('light theme secondary/onSecondary >= 4.5:1', () {
      final theme = WildfireA11yTheme.light;
      final ratio = contrastRatio(
        theme.colorScheme.secondary,
        theme.colorScheme.onSecondary,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('dark theme primary/onPrimary >= 4.5:1', () {
      final theme = WildfireA11yTheme.dark;
      final ratio = contrastRatio(
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('dark theme surface/onSurface >= 4.5:1', () {
      final theme = WildfireA11yTheme.dark;
      final ratio = contrastRatio(
        theme.colorScheme.surface,
        theme.colorScheme.onSurface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });
}
```

**Expected Result**: All tests FAIL (implementation not yet created)

---

## Contract 3: MaterialApp Integration

### Integration Point

**File**: `lib/app.dart`

### Expected Behavior

```dart
MaterialApp(
  title: 'Wildfire MVP',
  theme: WildfireA11yTheme.light,        // Light mode theme
  darkTheme: WildfireA11yTheme.dark,      // Dark mode theme
  themeMode: ThemeMode.system,            // Respect system preference
  // ... other config
)
```

### Contract Test

**File**: `test/widget/theme/app_theme_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/app.dart';

void main() {
  testWidgets('App uses WildfireA11yTheme for light mode', (tester) async {
    await tester.pumpWidget(App());
    
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
    expect(materialApp.theme?.brightness, equals(Brightness.light));
  });

  testWidgets('App provides dark theme', (tester) async {
    await tester.pumpWidget(App());
    
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.darkTheme, isNotNull);
    expect(materialApp.darkTheme?.brightness, equals(Brightness.dark));
  });

  testWidgets('App respects system theme mode', (tester) async {
    await tester.pumpWidget(App());
    
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, equals(ThemeMode.system));
  });
}
```

**Expected Result**: Tests FAIL until `lib/app.dart` is updated

---

## Contract 4: Ad-Hoc Colors Elimination

### Constraint

No files in `lib/` (excluding risk widgets) should contain `Colors.green`, `Colors.grey`, `Colors.amber`, etc. outside of import statements.

### Verification Script

**File**: `scripts/verify_no_adhoc_colors.sh`

```bash
#!/usr/bin/env bash
# Verify no ad-hoc Colors.* usage except in risk widgets

EXCLUDED_FILES=(
  "lib/theme/risk_palette.dart"
  "lib/widgets/risk_banner.dart"
  "lib/features/map/widgets/risk_result_chip.dart"
)

# Build exclusion pattern for grep
EXCLUDE_PATTERN=""
for file in "${EXCLUDED_FILES[@]}"; do
  EXCLUDE_PATTERN="$EXCLUDE_PATTERN --exclude=$file"
done

# Search for Colors.* usage (not in imports)
VIOLATIONS=$(grep -r "Colors\." lib/ $EXCLUDE_PATTERN | grep -v "import 'package:flutter/material.dart'")

if [ -n "$VIOLATIONS" ]; then
  echo "❌ Ad-hoc Colors.* usage found:"
  echo "$VIOLATIONS"
  exit 1
else
  echo "✅ No ad-hoc Colors.* usage (risk widgets excluded)"
  exit 0
fi
```

**Expected Result**: Script FAILS until sweep is complete, then PASSES

---

## Contract 5: Color Guard Integration

### Requirement

`scripts/allowed_colors.txt` must include all BrandPalette tokens to pass color guard validation.

### Updated allowed_colors.txt

```
# BrandPalette (app chrome)
0xFF0D4F48  # forest900
0xFF0F5A52  # forest800
0xFF17645B  # forest700
0xFF1B6B61  # forest600
0xFF246F65  # forest500
0xFF2E786E  # forest400
0xFF52A497  # outline
0xFF64C8BB  # mint400
0xFF7ED5CA  # mint300
0xFFF5A623  # amber500
0xFFE59414  # amber600
0xFFFFFFFF  # onDarkHigh (white)
0xFFDCEFEB  # onDarkMed
0xFFF4F4F4  # offWhite
0xFF111111  # onLightHigh (black)
0xFF333333  # onLightMed

# RiskPalette (risk widgets only - unchanged)
# ... existing RiskPalette colors ...
```

### Verification

Run `./scripts/color_guard.sh` - should PASS after BrandPalette tokens added.

---

## Summary

All contract tests are defined and will FAIL until implementation is complete. This follows TDD (Test-Driven Development) principles per C1 constitutional gate.

**Next Phase**: Generate tasks.md with implementation order (contracts first, then implementation to make tests pass).
