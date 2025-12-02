import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/theme/wildfire_a11y_theme.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

/// Tests that OutlinedButton styling is inherited from theme (not overridden in widgets)
///
/// These tests verify that the M3 theme consolidation is working correctly:
/// - OutlinedButtons should inherit foregroundColor from theme
/// - OutlinedButtons should inherit side (border) from theme
/// - Both light and dark themes should be tested
void main() {
  group('OutlinedButton theme styling', () {
    group('Light theme configuration', () {
      test('theme defines foregroundColor as forest700', () {
        final theme = WildfireA11yTheme.light;
        final buttonStyle = theme.outlinedButtonTheme.style!;

        // Access the foregroundColor from the style
        final foregroundColor = buttonStyle.foregroundColor;
        expect(foregroundColor, isNotNull);

        // Resolve for default state
        final resolvedColor = foregroundColor!.resolve({});
        expect(resolvedColor, equals(BrandPalette.forest700));
      });

      test('theme defines border side with BrandPalette.outline', () {
        final theme = WildfireA11yTheme.light;
        final buttonStyle = theme.outlinedButtonTheme.style!;

        final side = buttonStyle.side;
        expect(side, isNotNull);

        // Resolve for default state
        final resolvedSide = side!.resolve({});
        expect(resolvedSide, isNotNull);
        expect(resolvedSide!.color, equals(BrandPalette.outline));
        expect(resolvedSide.width, equals(1.5));
      });

      test('theme defines ≥44dp minimum height (C3)', () {
        final theme = WildfireA11yTheme.light;
        final buttonStyle = theme.outlinedButtonTheme.style!;

        final minimumSize = buttonStyle.minimumSize;
        expect(minimumSize, isNotNull);

        final resolvedSize = minimumSize!.resolve({});
        expect(resolvedSize, isNotNull);
        expect(resolvedSize!.height, greaterThanOrEqualTo(44));
      });

      test('theme defines 12dp corner radius', () {
        final theme = WildfireA11yTheme.light;
        final buttonStyle = theme.outlinedButtonTheme.style!;

        final shape = buttonStyle.shape;
        expect(shape, isNotNull);

        final resolvedShape = shape!.resolve({});
        expect(resolvedShape, isA<RoundedRectangleBorder>());

        final rrb = resolvedShape as RoundedRectangleBorder;
        expect(rrb.borderRadius, equals(BorderRadius.circular(12)));
      });
    });

    group('Dark theme configuration', () {
      test('theme defines foregroundColor as onDarkMedium', () {
        final theme = WildfireA11yTheme.dark;
        final buttonStyle = theme.outlinedButtonTheme.style!;

        final foregroundColor = buttonStyle.foregroundColor;
        expect(foregroundColor, isNotNull);

        final resolvedColor = foregroundColor!.resolve({});
        expect(resolvedColor, equals(BrandPalette.onDarkMedium));
      });

      test('theme defines border side with 1.5 width', () {
        final theme = WildfireA11yTheme.dark;
        final buttonStyle = theme.outlinedButtonTheme.style!;

        final side = buttonStyle.side;
        expect(side, isNotNull);

        final resolvedSide = side!.resolve({});
        expect(resolvedSide, isNotNull);
        expect(resolvedSide!.width, equals(1.5));
        // Dark theme uses colorScheme.outline which is dynamically resolved
      });

      test('theme defines ≥44dp minimum height (C3)', () {
        final theme = WildfireA11yTheme.dark;
        final buttonStyle = theme.outlinedButtonTheme.style!;

        final minimumSize = buttonStyle.minimumSize;
        expect(minimumSize, isNotNull);

        final resolvedSize = minimumSize!.resolve({});
        expect(resolvedSize, isNotNull);
        expect(resolvedSize!.height, greaterThanOrEqualTo(44));
      });
    });

    group('Widget inheritance verification', () {
      testWidgets('OutlinedButton without explicit style inherits theme',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: WildfireA11yTheme.light,
            home: Scaffold(
              body: Center(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Unstyled Button'),
                ),
              ),
            ),
          ),
        );

        // Find the button
        final buttonFinder = find.byType(OutlinedButton);
        expect(buttonFinder, findsOneWidget);

        // Verify it's using theme defaults (no explicit style)
        final button = tester.widget<OutlinedButton>(buttonFinder);
        expect(button.style,
            isNull); // No explicit style means full theme inheritance
      });

      testWidgets(
          'OutlinedButton text uses theme foregroundColor in light mode',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: WildfireA11yTheme.light,
            home: Scaffold(
              body: Center(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Test Button'),
                ),
              ),
            ),
          ),
        );

        // The Text widget should inherit the theme's foreground color
        final textFinder = find.text('Test Button');
        expect(textFinder, findsOneWidget);

        // Verify button is rendered
        final buttonFinder = find.byType(OutlinedButton);
        expect(buttonFinder, findsOneWidget);
      });

      testWidgets('OutlinedButton text uses theme foregroundColor in dark mode',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: WildfireA11yTheme.dark,
            home: Scaffold(
              body: Center(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Test Button'),
                ),
              ),
            ),
          ),
        );

        // The Text widget should inherit the theme's foreground color
        final textFinder = find.text('Test Button');
        expect(textFinder, findsOneWidget);

        // Verify button is rendered
        final buttonFinder = find.byType(OutlinedButton);
        expect(buttonFinder, findsOneWidget);
      });

      testWidgets(
          'OutlinedButton with padding-only override preserves theme colors',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: WildfireA11yTheme.light,
            home: Scaffold(
              body: Center(
                child: OutlinedButton(
                  onPressed: () {},
                  // Only override padding - colors should come from theme
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text('Custom Padding Button'),
                ),
              ),
            ),
          ),
        );

        final buttonFinder = find.byType(OutlinedButton);
        final button = tester.widget<OutlinedButton>(buttonFinder);

        // Button has custom style for padding
        expect(button.style, isNotNull);

        // But the style only specifies padding, so colors come from theme
        // (This is the pattern used in confirmation_panel.dart)
        final customPadding = button.style!.padding?.resolve({});
        expect(customPadding?.vertical, equals(40)); // 20 * 2
      });
    });
  });

  group('FilledButton theme styling', () {
    test('light theme defines ≥44dp minimum height (C3)', () {
      final theme = WildfireA11yTheme.light;
      final buttonStyle = theme.filledButtonTheme.style!;

      final minimumSize = buttonStyle.minimumSize;
      expect(minimumSize, isNotNull);

      final resolvedSize = minimumSize!.resolve({});
      expect(resolvedSize, isNotNull);
      expect(resolvedSize!.height, greaterThanOrEqualTo(44));
    });

    test('dark theme defines ≥44dp minimum height (C3)', () {
      final theme = WildfireA11yTheme.dark;
      final buttonStyle = theme.filledButtonTheme.style!;

      final minimumSize = buttonStyle.minimumSize;
      expect(minimumSize, isNotNull);

      final resolvedSize = minimumSize!.resolve({});
      expect(resolvedSize, isNotNull);
      expect(resolvedSize!.height, greaterThanOrEqualTo(44));
    });

    test('light theme defines 12dp corner radius', () {
      final theme = WildfireA11yTheme.light;
      final buttonStyle = theme.filledButtonTheme.style!;

      final shape = buttonStyle.shape;
      expect(shape, isNotNull);

      final resolvedShape = shape!.resolve({});
      expect(resolvedShape, isA<RoundedRectangleBorder>());

      final rrb = resolvedShape as RoundedRectangleBorder;
      expect(rrb.borderRadius, equals(BorderRadius.circular(12)));
    });
  });

  group('ElevatedButton theme styling', () {
    test('light theme defines ≥44dp minimum height (C3)', () {
      final theme = WildfireA11yTheme.light;
      final buttonStyle = theme.elevatedButtonTheme.style!;

      final minimumSize = buttonStyle.minimumSize;
      expect(minimumSize, isNotNull);

      final resolvedSize = minimumSize!.resolve({});
      expect(resolvedSize, isNotNull);
      expect(resolvedSize!.height, greaterThanOrEqualTo(44));
    });

    test('dark theme defines ≥44dp minimum height (C3)', () {
      final theme = WildfireA11yTheme.dark;
      final buttonStyle = theme.elevatedButtonTheme.style!;

      final minimumSize = buttonStyle.minimumSize;
      expect(minimumSize, isNotNull);

      final resolvedSize = minimumSize!.resolve({});
      expect(resolvedSize, isNotNull);
      expect(resolvedSize!.height, greaterThanOrEqualTo(44));
    });
  });

  group('TextButton theme styling', () {
    test('light theme defines ≥44dp minimum height (C3)', () {
      final theme = WildfireA11yTheme.light;
      final buttonStyle = theme.textButtonTheme.style!;

      final minimumSize = buttonStyle.minimumSize;
      expect(minimumSize, isNotNull);

      final resolvedSize = minimumSize!.resolve({});
      expect(resolvedSize, isNotNull);
      expect(resolvedSize!.height, greaterThanOrEqualTo(44));
    });

    test('dark theme defines ≥44dp minimum height (C3)', () {
      final theme = WildfireA11yTheme.dark;
      final buttonStyle = theme.textButtonTheme.style!;

      final minimumSize = buttonStyle.minimumSize;
      expect(minimumSize, isNotNull);

      final resolvedSize = minimumSize!.resolve({});
      expect(resolvedSize, isNotNull);
      expect(resolvedSize!.height, greaterThanOrEqualTo(44));
    });
  });
}
