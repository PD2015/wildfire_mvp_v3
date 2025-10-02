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
            home: Scaffold(
              body: RiskBanner(state: RiskBannerLoading()),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading wildfire risk...'), findsOneWidget);
      });

      testWidgets('has proper accessibility label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: RiskBannerLoading()),
            ),
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
        testWidgets('displays correct color for ${level.name} level',
            (tester) async {
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

          // Find the main container with risk level background color
          final containers = tester.widgetList<Container>(find.byType(Container));
          final decoratedContainer = containers.firstWhere((container) {
            final decoration = container.decoration as BoxDecoration?;
            return decoration?.color != null && 
                   decoration!.color != Colors.transparent &&
                   decoration.color != RiskPalette.lightGray;
          });
          final decoration = decoratedContainer.decoration as BoxDecoration;
          final expectedColor = _getRiskLevelColorTest(level);

          expect(decoration.color, equals(expectedColor));
        });

        testWidgets('displays correct risk level text for ${level.name}',
            (tester) async {
          final fireRisk = _fakeFireRisk(level: level);
          final expectedText =
              'Wildfire Risk: ${_getRiskLevelName(level).toUpperCase()}';

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

      for (final source in DataSource.values) {
        testWidgets('displays correct source chip for ${source.name}',
            (tester) async {
          final fireRisk = _fakeFireRisk(source: source);
          final expectedSourceText = _getSourceName(source);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiskBanner(state: RiskBannerSuccess(fireRisk)),
              ),
            ),
          );

          expect(find.text(expectedSourceText), findsOneWidget);
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

      testWidgets('shows cached badge when freshness is cached',
          (tester) async {
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

      testWidgets('has proper accessibility label for success state',
          (tester) async {
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
          find.bySemanticsLabel(RegExp(r'Current wildfire risk High.*data from EFFIS')),
          findsOneWidget,
        );
      });
    });

    group('Error State', () {
      testWidgets('displays error message when no cached data', (tester) async {
        const errorMessage = 'Network error';
        const errorState = RiskBannerError(errorMessage);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: errorState),
            ),
          ),
        );

        expect(find.text('Unable to load wildfire risk data'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('displays retry button when onRetry provided',
          (tester) async {
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
            home: Scaffold(
              body: RiskBanner(state: errorState),
            ),
          ),
        );

        expect(find.text('Retry'), findsNothing);
      });

      testWidgets('displays cached data when available in error state',
          (tester) async {
        const errorMessage = 'Network error';
        final cachedData = _fakeFireRisk(level: RiskLevel.moderate);
        final errorState = RiskBannerError(errorMessage, cached: cachedData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: errorState),
            ),
          ),
        );

        // Should show the cached risk level
        expect(find.text('Wildfire Risk: MODERATE'), findsOneWidget);
        // Should show cached badge
        expect(find.text('Cached'), findsOneWidget);
        // Should show error indicator
        expect(find.text('Unable to load current data'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('uses cached data colors when showing cached error state',
          (tester) async {
        final cachedData = _fakeFireRisk(level: RiskLevel.veryHigh);
        final errorState = RiskBannerError('Network error', cached: cachedData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: errorState),
            ),
          ),
        );

        // Find the main container (skip the outer container with constraints)
        final containers = tester.widgetList<Container>(find.byType(Container));
        final mainContainer = containers.firstWhere((container) {
          final decoration = container.decoration as BoxDecoration?;
          return decoration?.color != null &&
              decoration!.color != RiskPalette.lightGray;
        });

        final decoration = mainContainer.decoration as BoxDecoration;
        final expectedColor =
            _getRiskLevelColorTest(RiskLevel.veryHigh).withValues(alpha: 0.6);

        expect(decoration.color, equals(expectedColor));
      });
    });

    group('Accessibility', () {
      testWidgets('retry button meets minimum touch target size',
          (tester) async {
        // Use cached error state to ensure retry button shows
        final cachedData = _fakeFireRisk(level: RiskLevel.moderate);
        final errorState = RiskBannerError('Network error', cached: cachedData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(
                state: errorState,
                onRetry: () {},
              ),
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

      testWidgets('entire widget meets minimum height requirement',
          (tester) async {
        const loadingState = RiskBannerLoading();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: loadingState),
            ),
          ),
        );

        final widget = tester.renderObject<RenderBox>(find.byType(RiskBanner));
        expect(widget.size.height, greaterThanOrEqualTo(44.0));
      });
    });
  });

  group('Golden Tests', () {
    group('Success State - Light Theme', () {
      for (final level in RiskLevel.values) {
        testWidgets('${level.name} risk level', (tester) async {
          final fireRisk =
              _fakeFireRisk(level: level, source: DataSource.effis);

          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: Container(
                  width: 400,
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  child: RiskBanner(state: RiskBannerSuccess(fireRisk)),
                ),
              ),
            ),
          );

          await expectLater(
            find.byType(Container).first,
            matchesGoldenFile('goldens/risk_banner/${level.name}_light.png'),
          );
        });
      }
    });

    group('Success State - Dark Theme', () {
      for (final level in RiskLevel.values) {
        testWidgets('${level.name} risk level', (tester) async {
          final fireRisk =
              _fakeFireRisk(level: level, source: DataSource.effis);

          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                body: Container(
                  width: 400,
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  child: RiskBanner(state: RiskBannerSuccess(fireRisk)),
                ),
              ),
            ),
          );

          await expectLater(
            find.byType(Container).first,
            matchesGoldenFile('goldens/risk_banner/${level.name}_dark.png'),
          );
        });
      }
    });

    testWidgets('cached state golden', (tester) async {
      final fireRisk = _fakeFireRisk(
        level: RiskLevel.moderate,
        freshness: Freshness.cached,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 400,
              height: 300,
              padding: const EdgeInsets.all(16),
              child: RiskBanner(state: RiskBannerSuccess(fireRisk)),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Container).first,
        matchesGoldenFile('goldens/risk_banner/cached_state.png'),
      );
    });

    testWidgets('error state with retry golden', (tester) async {
      const errorState = RiskBannerError('Network connection failed');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 400,
              height: 350,
              padding: const EdgeInsets.all(16),
              child: RiskBanner(
                state: errorState,
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Container).first,
        matchesGoldenFile('goldens/risk_banner/error_with_retry.png'),
      );
    });

    testWidgets('error state with cached data golden', (tester) async {
      final cachedData = _fakeFireRisk(level: RiskLevel.high);
      final errorState = RiskBannerError('Network error', cached: cachedData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 400,
              height: 400,
              padding: const EdgeInsets.all(16),
              child: RiskBanner(
                state: errorState,
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Container).first,
        matchesGoldenFile('goldens/risk_banner/error_with_cached.png'),
      );
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
    observedAt:
        observedAtUtc ?? DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
  );
}

String _getRiskLevelName(RiskLevel level) {
  return switch (level) {
    RiskLevel.veryLow => 'Very Low',
    RiskLevel.low => 'Low',
    RiskLevel.moderate => 'Moderate',
    RiskLevel.high => 'High',
    RiskLevel.veryHigh => 'Very High',
    RiskLevel.extreme => 'Extreme',
  };
}

String _getSourceName(DataSource source) {
  return switch (source) {
    DataSource.effis => 'EFFIS',
    DataSource.sepa => 'SEPA',
    DataSource.cache => 'Cache',
    DataSource.mock => 'Mock',
  };
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
