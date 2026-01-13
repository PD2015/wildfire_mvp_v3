// Risk Banner + Location Chip Integration Tests (Spec 023 Phase 2)
//
// Tests the integration of LocationChipWithPanel inside RiskBanner.
// Verifies the chip appears below RiskScale and functions correctly
// within the banner's various states (loading, success, error).
//
// NOTE: Uses pump() + pump(Duration) pattern to avoid pumpAndSettle timeouts
// from CircularProgressIndicator animations.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/widgets/location_chip.dart';
import 'package:wildfire_mvp_v3/widgets/location_chip_with_panel.dart';
import 'package:wildfire_mvp_v3/widgets/risk_banner.dart';
import 'package:wildfire_mvp_v3/widgets/risk_scale.dart';

void main() {
  group('RiskBanner + LocationChip Integration', () {
    // Test data
    final testRisk = FireRisk(
      level: RiskLevel.moderate,
      fwi: 15.5,
      source: DataSource.effis,
      observedAt: DateTime.now().toUtc(),
      freshness: Freshness.live,
    );

    Widget buildTestWidget({
      required RiskBannerState state,
      Widget? locationChip,
      String? locationLabel,
    }) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RiskBanner(
                state: state,
                locationLabel: locationLabel,
                locationChip: locationChip,
              ),
            ),
          ),
        ),
      );
    }

    Widget buildLocationChip({
      String locationName = 'Aviemore, Highland',
      String? coordinatesLabel = '57.20, -3.83',
      LocationSource locationSource = LocationSource.gps,
      Color parentBackgroundColor = RiskPalette.moderate,
      bool isLoading = false,
    }) {
      return LocationChipWithPanel(
        locationName: locationName,
        coordinatesLabel: coordinatesLabel,
        locationSource: locationSource,
        parentBackgroundColor: parentBackgroundColor,
        isLoading: isLoading,
        showMapPreview: false, // Disable to avoid spinner timeouts
        onChangeLocation: () {},
      );
    }

    group('Success State with LocationChip', () {
      testWidgets('displays LocationChip below RiskScale', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationLabel: '57.20, -3.83',
          locationChip: buildLocationChip(),
        ));
        await tester.pump();

        // Verify RiskScale exists
        expect(find.byType(RiskScale), findsOneWidget);

        // Verify LocationChip exists
        expect(find.byType(LocationChip), findsOneWidget);
      });

      testWidgets('LocationChip shows correct location name', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(
            locationName: 'Near Aviemore',
          ),
        ));
        await tester.pump();

        expect(find.text('Near Aviemore'), findsOneWidget);
      });

      testWidgets('LocationChip shows location_on_outlined icon and GPS text',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(
            locationSource: LocationSource.gps,
          ),
        ));
        await tester.pump();

        // Always shows location_on_outlined icon (doesn't change with source)
        // Note: findsWidgets because both chip and collapsed panel contain this icon
        expect(find.byIcon(Icons.location_on_outlined), findsWidgets);
        // Source shown as text after dot separator
        expect(find.text('GPS'), findsOneWidget);
      });

      testWidgets(
          'LocationChip shows location_on_outlined icon and Manual text',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(
            locationSource: LocationSource.manual,
          ),
        ));
        await tester.pump();

        // Always shows location_on_outlined icon (doesn't change with source)
        // Note: findsWidgets because both chip and collapsed panel contain this icon
        expect(find.byIcon(Icons.location_on_outlined), findsWidgets);
        // Source shown as text - may appear in both chip and panel header
        expect(find.text('Manual'), findsWidgets);
      });

      testWidgets('LocationChip expands on tap', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(
            coordinatesLabel: '57.20, -3.83',
          ),
        ));
        await tester.pump();

        // Initially collapsed - should only see chip
        expect(find.byType(LocationChip), findsOneWidget);

        // Tap to expand
        await tester.tap(find.byType(LocationChip));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Panel should now be visible with coordinates
        expect(find.text('57.20, -3.83'), findsWidgets);
      });

      testWidgets('displays banner without locationChip when null',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationLabel: '57.20, -3.83',
          locationChip: null, // No chip provided
        ));
        await tester.pump();

        // RiskScale should exist
        expect(find.byType(RiskScale), findsOneWidget);

        // LocationChip should NOT exist
        expect(find.byType(LocationChip), findsNothing);
      });
    });

    group('Loading State with LocationChip', () {
      testWidgets('loading banner does not show LocationChip', (tester) async {
        // RiskBannerLoading is a simple loading indicator state
        // It doesn't render the locationChip prop (no Column structure)
        await tester.pumpWidget(buildTestWidget(
          state: const RiskBannerLoading(),
          locationChip: buildLocationChip(
            isLoading: true,
            locationName: '57.20, -3.83',
          ),
        ));
        await tester.pump();

        // LocationChip should NOT exist in loading state
        // (loading state is a simple indicator, not a full card)
        expect(find.byType(LocationChip), findsNothing);
        expect(find.text('Loading wildfire risk...'), findsOneWidget);
      });
    });

    group('Error State with LocationChip', () {
      testWidgets('displays LocationChip in error state with cached data',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerError('Network error', cached: testRisk),
          locationChip: buildLocationChip(
            locationSource: LocationSource.cached,
          ),
        ));
        await tester.pump();

        // LocationChip should exist
        expect(find.byType(LocationChip), findsOneWidget);

        // Error state indicators
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('error banner without cached data shows no chip',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: const RiskBannerError('Network error'),
          locationChip: null, // No location available in error
        ));
        await tester.pump();

        // LocationChip should NOT exist
        expect(find.byType(LocationChip), findsNothing);
      });
    });

    group('Risk Level Color Adaptation', () {
      for (final level in RiskLevel.values) {
        testWidgets('LocationChip adapts to ${level.name} risk color',
            (tester) async {
          final risk = FireRisk(
            level: level,
            fwi: 15.5,
            source: DataSource.effis,
            observedAt: DateTime.now().toUtc(),
            freshness: Freshness.live,
          );

          await tester.pumpWidget(buildTestWidget(
            state: RiskBannerSuccess(risk),
            locationChip: buildLocationChip(
              parentBackgroundColor: level.color,
            ),
          ));
          await tester.pump();

          // Verify chip renders without error
          expect(find.byType(LocationChip), findsOneWidget);
        });
      }
    });

    group('Accessibility', () {
      testWidgets('LocationChip has semantic label', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(
            locationName: 'Aviemore, Highland',
            locationSource: LocationSource.gps,
          ),
        ));
        await tester.pump();

        // Check for semantic label containing location info
        final semantics = tester.getSemantics(find.byType(LocationChip));
        expect(semantics.label, contains('Aviemore'));
      });

      testWidgets('LocationChip is tappable', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(),
        ));
        await tester.pump();

        // Verify chip is tappable by checking it responds to tap
        final chipFinder = find.byType(LocationChip);
        expect(chipFinder, findsOneWidget);

        // Tap should toggle expansion (no error means tappable)
        await tester.tap(chipFinder);
        await tester.pump();
      });

      testWidgets('LocationChip meets minimum touch target', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(),
        ));
        await tester.pump();

        // Thinner design uses 36dp (cleaner look per spec 023 screenshots)
        final chipSize = tester.getSize(find.byType(LocationChip));
        expect(chipSize.height, greaterThanOrEqualTo(36.0));
      });
    });

    group('Visual Hierarchy', () {
      testWidgets('RiskScale appears before LocationChip in widget tree',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(),
        ));
        await tester.pump();

        // Find positions
        final scalePosition = tester.getTopLeft(find.byType(RiskScale)).dy;
        final chipPosition = tester.getTopLeft(find.byType(LocationChip)).dy;

        // RiskScale should be above (smaller Y) LocationChip
        expect(scalePosition, lessThan(chipPosition));
      });

      testWidgets('LocationChip is visually distinct from RiskScale',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: RiskBannerSuccess(testRisk),
          locationChip: buildLocationChip(),
        ));
        await tester.pump();

        // Verify there's spacing between them (via SizedBox in RiskBanner)
        final scaleBottom = tester.getBottomLeft(find.byType(RiskScale)).dy;
        final chipTop = tester.getTopLeft(find.byType(LocationChip)).dy;
        final gap = chipTop - scaleBottom;

        // Should have at least 8dp spacing
        expect(gap, greaterThanOrEqualTo(8.0));
      });
    });
  });
}
