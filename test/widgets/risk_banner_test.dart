// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/widgets/risk_banner.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

void main() {
  group('RiskBanner Widget Tests', () {
    group('Loading State', () {
      testWidgets('displays loading indicator and text', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskBanner(state: RiskBannerLoading())),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading wildfire risk...'), findsOneWidget);
      });

      testWidgets('has proper accessibility label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskBanner(state: RiskBannerLoading())),
          ),
        );

        // Check for semantic label in the widget tree
        expect(
          find.bySemanticsLabel(RegExp(r'Loading wildfire risk data')),
          findsOneWidget,
        );
      });
    });

    group('Success State', () {
      for (final level in RiskLevel.values) {
        testWidgets('displays correct color for ${level.name} level', (
          tester,
        ) async {
          final fireRisk = _fakeFireRisk(
            level: level,
            source: DataSource.effis,
            freshness: Freshness.live,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiskBanner(state: RiskBannerSuccess(fireRisk)),
              ),
            ),
          );

          // Find the Card widget with risk level background color
          final card = tester.widget<Card>(find.byType(Card));
          final expectedColor = _getRiskLevelColorTest(level);

          expect(card.color, equals(expectedColor));
        });

        testWidgets('displays correct risk level text for ${level.name}', (
          tester,
        ) async {
          final fireRisk = _fakeFireRisk(level: level);
          final expectedText = 'WILDFIRE RISK';

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiskBanner(state: RiskBannerSuccess(fireRisk)),
              ),
            ),
          );

          expect(find.text(expectedText), findsOneWidget);
        });
      }

      testWidgets('displays timestamp for success state', (tester) async {
        final fireRisk = _fakeFireRisk();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: RiskBannerSuccess(fireRisk)),
            ),
          ),
        );

        expect(find.textContaining('Updated'), findsOneWidget);
      });

      testWidgets('shows cached badge when freshness is cached', (
        tester,
      ) async {
        final fireRisk = _fakeFireRisk(freshness: Freshness.cached);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: RiskBannerSuccess(fireRisk)),
            ),
          ),
        );

        expect(find.text('Cached'), findsOneWidget);
      });

      testWidgets('has proper accessibility label for success state', (
        tester,
      ) async {
        final fireRisk = _fakeFireRisk(
          level: RiskLevel.high,
          source: DataSource.effis,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: RiskBannerSuccess(fireRisk)),
            ),
          ),
        );

        // Check for semantic label containing risk level and data source
        expect(
          find.bySemanticsLabel(
            RegExp(r'Current wildfire risk High.*data from EFFIS'),
          ),
          findsOneWidget,
        );
      });

      group('Weather Panel', () {
        testWidgets('does not display weather panel by default', (
          tester,
        ) async {
          final fireRisk = _fakeFireRisk();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiskBanner(state: RiskBannerSuccess(fireRisk)),
              ),
            ),
          );

          // Weather panel should not be visible with default config
          expect(find.text('Temperature'), findsNothing);
          expect(find.text('Humidity'), findsNothing);
          expect(find.text('Wind Speed'), findsNothing);
        });

        testWidgets('displays weather panel when config enabled', (
          tester,
        ) async {
          final fireRisk = _fakeFireRisk();
          const config = RiskBannerConfig(showWeatherPanel: true);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiskBanner(
                  state: RiskBannerSuccess(fireRisk),
                  config: config,
                ),
              ),
            ),
          );

          // Weather panel should be visible
          expect(find.text('Temperature'), findsOneWidget);
          expect(find.text('Humidity'), findsOneWidget);
          expect(find.text('Wind Speed'), findsOneWidget);
        });

        testWidgets('displays placeholder weather values', (tester) async {
          final fireRisk = _fakeFireRisk();
          const config = RiskBannerConfig(showWeatherPanel: true);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiskBanner(
                  state: RiskBannerSuccess(fireRisk),
                  config: config,
                ),
              ),
            ),
          );

          // Check placeholder values
          expect(find.text('18°C'), findsOneWidget);
          expect(find.text('65%'), findsOneWidget);
          expect(find.text('12 mph'), findsOneWidget);
        });

        testWidgets('weather panel has proper rounded container', (
          tester,
        ) async {
          final fireRisk = _fakeFireRisk();
          const config = RiskBannerConfig(showWeatherPanel: true);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiskBanner(
                  state: RiskBannerSuccess(fireRisk),
                  config: config,
                ),
              ),
            ),
          );

          // Find the weather panel container
          final containers = tester.widgetList<Container>(
            find.byType(Container),
          );

          // Weather panel should have rounded corners and semi-transparent background
          final weatherContainer = containers.firstWhere((container) {
            final decoration = container.decoration as BoxDecoration?;
            final color = decoration?.color;
            final alphaValue =
                color != null ? (color.a * 255.0).round() & 0xff : null;
            return decoration?.borderRadius != null &&
                alphaValue != null &&
                alphaValue < 255;
          });

          expect(weatherContainer, isNotNull);
          final decoration = weatherContainer.decoration as BoxDecoration;
          expect(decoration.borderRadius, isNotNull);
          final alphaValue = decoration.color != null
              ? (decoration.color!.a * 255.0).round() & 0xff
              : null;
          expect(alphaValue, lessThan(255));
        });
      });
    });

    group('Error State', () {
      testWidgets('displays error message when no cached data', (tester) async {
        const errorMessage = 'Network error';
        const errorState = RiskBannerError(errorMessage);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskBanner(state: errorState)),
          ),
        );

        expect(find.text('Unable to load wildfire risk data'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('displays retry button when onRetry provided', (
        tester,
      ) async {
        const errorState = RiskBannerError('Network error');
        bool retryTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(
                state: errorState,
                onRetry: () => retryTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        expect(retryTapped, isTrue);
      });

      testWidgets('hides retry button when onRetry is null', (tester) async {
        const errorState = RiskBannerError('Network error');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskBanner(state: errorState)),
          ),
        );

        expect(find.text('Retry'), findsNothing);
      });

      testWidgets('displays cached data when available in error state', (
        tester,
      ) async {
        const errorMessage = 'Network error';
        final cachedData = _fakeFireRisk(level: RiskLevel.moderate);
        final errorState = RiskBannerError(errorMessage, cached: cachedData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskBanner(state: errorState)),
          ),
        );

        // Should show the cached risk level
        expect(find.text('WILDFIRE RISK'), findsOneWidget);
        // Should show cached badge
        expect(find.text('Cached'), findsOneWidget);
        // Should show error indicator
        expect(find.text('Unable to load current data'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('uses cached data colors when showing cached error state', (
        tester,
      ) async {
        final cachedData = _fakeFireRisk(level: RiskLevel.veryHigh);
        final errorState = RiskBannerError('Network error', cached: cachedData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskBanner(state: errorState)),
          ),
        );

        // Find the Card widget with cached risk level background color
        final card = tester.widget<Card>(find.byType(Card));
        final expectedColor = _getRiskLevelColorTest(
          RiskLevel.veryHigh,
        ).withValues(alpha: 0.6);

        expect(card.color, equals(expectedColor));
      });
    });

    group('Accessibility', () {
      testWidgets('retry button meets minimum touch target size', (
        tester,
      ) async {
        // Use cached error state to ensure retry button shows
        final cachedData = _fakeFireRisk(level: RiskLevel.moderate);
        final errorState = RiskBannerError('Network error', cached: cachedData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: errorState, onRetry: () {}),
            ),
          ),
        );

        // Allow the widget to settle
        await tester.pumpAndSettle();

        // Find the retry button text first (should always exist with onRetry callback)
        expect(find.text('Retry'), findsOneWidget);

        // Find the button by text and check its container size
        final retryFinder = find.ancestor(
          of: find.text('Retry'),
          matching: find.byType(SizedBox),
        );
        expect(retryFinder, findsOneWidget);
        final button = tester.renderObject<RenderBox>(retryFinder);
        expect(button.size.height, greaterThanOrEqualTo(44.0));
      });

      testWidgets('entire widget meets minimum height requirement', (
        tester,
      ) async {
        const loadingState = RiskBannerLoading();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskBanner(state: loadingState)),
          ),
        );

        final widget = tester.renderObject<RenderBox>(find.byType(RiskBanner));
        expect(widget.size.height, greaterThanOrEqualTo(44.0));
      });
    });
  });
}

// Test helper functions
FireRisk _fakeFireRisk({
  RiskLevel level = RiskLevel.moderate,
  DataSource source = DataSource.effis,
  Freshness freshness = Freshness.live,
  DateTime? observedAtUtc,
}) {
  return FireRisk(
    level: level,
    source: source,
    freshness: freshness,
    observedAt: observedAtUtc ??
        DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
  );
}

Color _getRiskLevelColorTest(RiskLevel level) {
  return switch (level) {
    RiskLevel.veryLow => RiskPalette.veryLow,
    RiskLevel.low => RiskPalette.low,
    RiskLevel.moderate => RiskPalette.moderate,
    RiskLevel.high => RiskPalette.high,
    RiskLevel.veryHigh => RiskPalette.veryHigh,
    RiskLevel.extreme => RiskPalette.extreme,
  };
}
