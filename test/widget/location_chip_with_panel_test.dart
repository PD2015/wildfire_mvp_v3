import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/expandable_location_panel.dart';
import 'package:wildfire_mvp_v3/widgets/location_chip.dart';
import 'package:wildfire_mvp_v3/widgets/location_chip_with_panel.dart';

/// Widget tests for LocationChipWithPanel
///
/// Tests cover:
/// - Expand/collapse state management
/// - Animation behavior
/// - Callback invocation
/// - Panel content pass-through
/// - Controller variant
void main() {
  group('LocationChipWithPanel', () {
    Widget buildTestWidget({
      String locationName = 'Near Aviemore, Highland',
      String? coordinatesLabel = '57.20, -3.83',
      String? what3words,
      bool isWhat3wordsLoading = false,
      String? formattedLocation,
      bool isGeocodingLoading = false,
      String? staticMapUrl,
      bool isMapLoading = false,
      LocationSource? locationSource,
      Color parentBackgroundColor = const Color(0xFFFFEB3B),
      bool isLoading = false,
      VoidCallback? onChangeLocation,
      VoidCallback? onUseGps,
      VoidCallback? onCopyWhat3words,
      VoidCallback? onCopyCoordinates,
      bool showMapPreview = true,
      bool showActions = true,
      bool initiallyExpanded = false,
      ValueChanged<bool>? onExpandedChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: LocationChipWithPanel(
              locationName: locationName,
              coordinatesLabel: coordinatesLabel,
              what3words: what3words,
              isWhat3wordsLoading: isWhat3wordsLoading,
              formattedLocation: formattedLocation,
              isGeocodingLoading: isGeocodingLoading,
              staticMapUrl: staticMapUrl,
              isMapLoading: isMapLoading,
              locationSource: locationSource,
              parentBackgroundColor: parentBackgroundColor,
              isLoading: isLoading,
              onChangeLocation: onChangeLocation,
              onUseGps: onUseGps,
              onCopyWhat3words: onCopyWhat3words,
              onCopyCoordinates: onCopyCoordinates,
              showMapPreview: showMapPreview,
              showActions: showActions,
              initiallyExpanded: initiallyExpanded,
              onExpandedChanged: onExpandedChanged,
            ),
          ),
        ),
      );
    }

    group('Initial state', () {
      testWidgets('starts collapsed by default', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Chip should be visible
        expect(find.byType(LocationChip), findsOneWidget);

        // Panel should not be visible (zero size)
        final sizeTransition = tester.widget<SizeTransition>(
          find.byType(SizeTransition),
        );
        expect(sizeTransition.sizeFactor.value, 0.0);
      });

      testWidgets('starts expanded when initiallyExpanded is true',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(initiallyExpanded: true));

        final sizeTransition = tester.widget<SizeTransition>(
          find.byType(SizeTransition),
        );
        expect(sizeTransition.sizeFactor.value, 1.0);
      });

      testWidgets('shows location name in chip', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationName: 'Near Aviemore, Highland',
        ));

        expect(find.text('Near Aviemore, Highland'), findsOneWidget);
      });
    });

    group('Expand/collapse', () {
      testWidgets('expands panel on chip tap', (tester) async {
        await tester.pumpWidget(buildTestWidget(showMapPreview: false));

        // Tap chip to expand
        await tester.tap(find.byType(LocationChip));
        // Pump twice - once to start animation, once to complete
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Panel should now be visible
        expect(find.byType(ExpandableLocationPanel), findsOneWidget);

        // Coordinates should be visible in panel
        expect(find.text('57.20, -3.83'), findsOneWidget);
      });

      testWidgets('collapses panel on second chip tap', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          initiallyExpanded: true,
          showMapPreview: false,
        ));

        // Panel starts expanded - verify coordinates visible
        expect(find.text('57.20, -3.83'), findsOneWidget);

        // Tap chip to collapse
        await tester.tap(find.byType(LocationChip));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // After collapse, panel size should be 0
        final sizeTransition = tester.widget<SizeTransition>(
          find.byType(SizeTransition),
        );
        expect(sizeTransition.sizeFactor.value, closeTo(0.0, 0.05));
      });

      testWidgets('calls onExpandedChanged callback', (tester) async {
        final expandStates = <bool>[];
        await tester.pumpWidget(buildTestWidget(
          onExpandedChanged: (expanded) => expandStates.add(expanded),
          showMapPreview: false,
        ));

        // Tap to expand
        await tester.tap(find.byType(LocationChip));
        await tester.pump();
        expect(expandStates, [true]);

        // Tap to collapse
        await tester.tap(find.byType(LocationChip));
        await tester.pump();
        expect(expandStates, [true, false]);
      });
    });

    group('Animation', () {
      testWidgets('animation completes within 300ms', (tester) async {
        await tester.pumpWidget(buildTestWidget(showMapPreview: false));

        await tester.tap(find.byType(LocationChip));
        await tester.pump(); // Start animation

        // Animation duration is 250ms, pump just past that
        await tester.pump(const Duration(milliseconds: 260));

        final sizeTransition = tester.widget<SizeTransition>(
          find.byType(SizeTransition),
        );
        expect(sizeTransition.sizeFactor.value, closeTo(1.0, 0.05));
      });

      testWidgets('has fade animation on panel', (tester) async {
        await tester.pumpWidget(buildTestWidget(showMapPreview: false));

        // Initially collapsed - panel should have 0 opacity
        final fadeTransition = tester.widget<FadeTransition>(
          find.byType(FadeTransition),
        );
        expect(fadeTransition.opacity.value, 0.0);

        // Expand
        await tester.tap(find.byType(LocationChip));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Panel should have full opacity
        final expandedFade = tester.widget<FadeTransition>(
          find.byType(FadeTransition),
        );
        expect(expandedFade.opacity.value, closeTo(1.0, 0.1));
      });
    });

    group('Panel content pass-through', () {
      testWidgets('passes coordinatesLabel to panel', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          initiallyExpanded: true,
          showMapPreview: false,
        ));

        expect(find.text('57.20, -3.83'), findsOneWidget);
      });

      testWidgets('passes what3words to panel', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          what3words: '///daring.lion.race',
          initiallyExpanded: true,
          showMapPreview: false,
        ));

        expect(find.text('///daring.lion.race'), findsOneWidget);
      });

      testWidgets('passes onChangeLocation callback', (tester) async {
        var changed = false;
        await tester.pumpWidget(buildTestWidget(
          onChangeLocation: () => changed = true,
          initiallyExpanded: true,
          showMapPreview: false,
        ));

        await tester.tap(find.text('Change Location'));
        expect(changed, isTrue);
      });

      testWidgets('passes locationSource for styling', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.gps,
          showMapPreview: false,
        ));

        // Location pin icon always appears (source shown as text)
        // Note: findsWidgets because both chip and collapsed panel contain this icon
        expect(find.byIcon(Icons.location_on_outlined), findsWidgets);
        // Source text should appear
        expect(find.text('GPS'), findsOneWidget);
      });
    });

    group('Loading state', () {
      testWidgets('passes loading state to chip', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          isLoading: true,
          showMapPreview: false, // Avoid spinner from map
        ));

        // Chip should show loading indicator (only one - from chip)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });
}
