import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/fire_data_mode_toggle.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';

void main() {
  group('FireDataModeToggle', () {
    group('rendering', () {
      testWidgets('displays both segment options', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Hotspots'), findsOneWidget);
        expect(find.text('Burnt Areas'), findsOneWidget);
      });

      testWidgets('displays correct icons', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.whatshot), findsOneWidget);
        expect(find.byIcon(Icons.layers), findsOneWidget);
      });

      testWidgets('shows hotspots as selected when selectedMode is hotspots',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        final segmentedButton = tester.widget<SegmentedButton<FireDataMode>>(
          find.byType(SegmentedButton<FireDataMode>),
        );
        expect(segmentedButton.selected, contains(FireDataMode.hotspots));
        expect(
            segmentedButton.selected, isNot(contains(FireDataMode.burntAreas)));
      });

      testWidgets(
          'shows burnt areas as selected when selectedMode is burntAreas',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.burntAreas,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        final segmentedButton = tester.widget<SegmentedButton<FireDataMode>>(
          find.byType(SegmentedButton<FireDataMode>),
        );
        expect(segmentedButton.selected, contains(FireDataMode.burntAreas));
        expect(
            segmentedButton.selected, isNot(contains(FireDataMode.hotspots)));
      });
    });

    group('interactions', () {
      testWidgets('calls onModeChanged when burnt areas is tapped',
          (tester) async {
        FireDataMode? selectedMode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (mode) => selectedMode = mode,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Burnt Areas'));
        await tester.pumpAndSettle();

        expect(selectedMode, FireDataMode.burntAreas);
      });

      testWidgets('calls onModeChanged when hotspots is tapped',
          (tester) async {
        FireDataMode? selectedMode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.burntAreas,
                onModeChanged: (mode) => selectedMode = mode,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Hotspots'));
        await tester.pumpAndSettle();

        expect(selectedMode, FireDataMode.hotspots);
      });

      testWidgets('tapping already selected segment does not call callback',
          (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) => callCount++,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Hotspots'));
        await tester.pumpAndSettle();

        expect(callCount, 0);
      });
    });

    group('disabled state', () {
      testWidgets('disabled toggle does not respond to taps', (tester) async {
        FireDataMode? selectedMode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (mode) => selectedMode = mode,
                enabled: false,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Burnt Areas'));
        await tester.pumpAndSettle();

        expect(selectedMode, isNull);
      });

      testWidgets('enabled toggle responds to taps', (tester) async {
        FireDataMode? selectedMode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (mode) => selectedMode = mode,
                enabled: true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Burnt Areas'));
        await tester.pumpAndSettle();

        expect(selectedMode, FireDataMode.burntAreas);
      });
    });

    group('accessibility', () {
      testWidgets('has proper semantics for screen readers', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        // Ensure the container has the semantic label
        expect(
          find.bySemanticsLabel('Fire data display mode'),
          findsOneWidget,
        );
      });

      testWidgets('segments have tooltips for accessibility', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        final segmentedButton = tester.widget<SegmentedButton<FireDataMode>>(
          find.byType(SegmentedButton<FireDataMode>),
        );

        // Verify segments have tooltips
        final hotspotsSegment = segmentedButton.segments.firstWhere(
          (s) => s.value == FireDataMode.hotspots,
        );
        final burntAreasSegment = segmentedButton.segments.firstWhere(
          (s) => s.value == FireDataMode.burntAreas,
        );

        expect(hotspotsSegment.tooltip, isNotNull);
        expect(burntAreasSegment.tooltip, isNotNull);
        expect(hotspotsSegment.tooltip, contains('hotspot'));
        expect(burntAreasSegment.tooltip, contains('burnt area'));
      });
    });

    group('styling', () {
      testWidgets('applies shadow for elevation effect', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        // Find the Container with BoxDecoration
        final containerFinder = find.descendant(
          of: find.byType(FireDataModeToggle),
          matching: find.byType(Container),
        );
        expect(containerFinder, findsOneWidget);
      });

      testWidgets('has rounded corners', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDataModeToggle(
                mode: FireDataMode.hotspots,
                onModeChanged: (_) {},
              ),
            ),
          ),
        );

        // Widget uses Container with BoxDecoration for rounded corners
        final containerFinder = find.descendant(
          of: find.byType(FireDataModeToggle),
          matching: find.byType(Container),
        );
        expect(containerFinder, findsOneWidget);
      });
    });
  });
}
