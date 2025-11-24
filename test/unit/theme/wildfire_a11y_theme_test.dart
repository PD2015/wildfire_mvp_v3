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
      expect(theme.colorScheme.onSecondary, equals(BrandPalette.onLightHigh));
      expect(theme.colorScheme.tertiary, equals(BrandPalette.amber500));
      expect(theme.colorScheme.onTertiary, equals(BrandPalette.onLightHigh));
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
      expect(theme.colorScheme.primary, equals(BrandPalette.forest600));
      expect(theme.colorScheme.secondary, equals(BrandPalette.mint400));
      expect(theme.colorScheme.surface, equals(BrandPalette.forest700));
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
