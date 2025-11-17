import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';
import 'package:wildfire_mvp_v3/theme/wildfire_a11y_theme.dart';

/// WCAG 2.1 AA Contrast Verification Tests
///
/// Standard:
/// - Normal text (<18pt / <14pt bold): ≥ 4.5:1
/// - Large text (≥18pt / ≥14pt bold): ≥ 3:1
/// - UI components (icons, borders): ≥ 3:1
void main() {
  group('WCAG AA Contrast Requirements', () {
    double contrastRatio(Color c1, Color c2) {
      final l1 = c1.computeLuminance();
      final l2 = c2.computeLuminance();
      final lighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('BrandPalette forest600 + white >= 4.5:1 (normal text)', () {
      final ratio =
          contrastRatio(BrandPalette.forest600, BrandPalette.onDarkHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Forest600 on white must meet AA normal text contrast');
    });

    test('BrandPalette mint400 + black >= 4.5:1 (normal text)', () {
      final ratio =
          contrastRatio(BrandPalette.mint400, BrandPalette.onLightHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Mint400 on black must meet AA normal text contrast');
    });

    test('BrandPalette amber500 + black >= 4.5:1 (normal text)', () {
      final ratio =
          contrastRatio(BrandPalette.amber500, BrandPalette.onLightHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Amber500 on black must meet AA normal text contrast');
    });

    test('Light theme primary + onPrimary >= 4.5:1', () {
      final theme = WildfireA11yTheme.light;
      final ratio = contrastRatio(
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      );
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Light theme primary/onPrimary contrast insufficient');
    });

    test('Light theme surface + onSurface >= 4.5:1', () {
      final theme = WildfireA11yTheme.light;
      final ratio = contrastRatio(
        theme.colorScheme.surface,
        theme.colorScheme.onSurface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Light theme surface/onSurface contrast insufficient');
    });

    test('Dark theme primary + onPrimary >= 4.5:1', () {
      final theme = WildfireA11yTheme.dark;
      final ratio = contrastRatio(
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      );
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Dark theme primary/onPrimary contrast insufficient');
    });

    test('Dark theme surface + onSurface >= 4.5:1', () {
      final theme = WildfireA11yTheme.dark;
      final ratio = contrastRatio(
        theme.colorScheme.surface,
        theme.colorScheme.onSurface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Dark theme surface/onSurface contrast insufficient');
    });
  });

  group('UI Component Contrast (3:1 minimum)', () {
    double contrastRatio(Color c1, Color c2) {
      final l1 = c1.computeLuminance();
      final l2 = c2.computeLuminance();
      final lighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('Light theme outline + surface >= 3:1', () {
      final theme = WildfireA11yTheme.light;
      final ratio = contrastRatio(
        theme.colorScheme.outline,
        theme.colorScheme.surface,
      );
      expect(ratio, greaterThanOrEqualTo(3.0),
          reason: 'Outline borders must be visible against surface');
    });

    test('Dark theme outline + surface >= 3:1', () {
      final theme = WildfireA11yTheme.dark;
      final ratio = contrastRatio(
        theme.colorScheme.outline,
        theme.colorScheme.surface,
      );
      expect(ratio, greaterThanOrEqualTo(3.0),
          reason: 'Outline borders must be visible against surface');
    });
  });
}
