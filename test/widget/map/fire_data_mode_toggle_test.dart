import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/fire_data_mode_toggle.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

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

      testWidgets('shows hotspots as selected when mode is hotspots', (
        tester,
      ) async {
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

        // Find the Material widgets that represent the chips
        final materials = tester.widgetList<Material>(
          find.descendant(
            of: find.byType(FireDataModeToggle),
            matching: find.byType(Material),
          ),
        );

        // First Material is the Hotspots chip, second is Burnt Areas
        // When hotspots is selected, first should have mint400 background
        final hotspotsChip = materials.first;
        final burntAreasChip = materials.elementAt(1);

        expect(hotspotsChip.color, equals(BrandPalette.mint400));
        expect(burntAreasChip.color, equals(Colors.transparent));
      });

      testWidgets('shows burnt areas as selected when mode is burntAreas', (
        tester,
      ) async {
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

        // Find the Material widgets that represent the chips
        final materials = tester.widgetList<Material>(
          find.descendant(
            of: find.byType(FireDataModeToggle),
            matching: find.byType(Material),
          ),
        );

        // When burnt areas is selected, second should have mint400 background
        final hotspotsChip = materials.first;
        final burntAreasChip = materials.elementAt(1);

        expect(hotspotsChip.color, equals(Colors.transparent));
        expect(burntAreasChip.color, equals(BrandPalette.mint400));
      });
    });

    group('interactions', () {
      testWidgets('calls onModeChanged when burnt areas is tapped', (
        tester,
      ) async {
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

      testWidgets('calls onModeChanged when hotspots is tapped', (
        tester,
      ) async {
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

      testWidgets('tapping already selected segment still calls callback', (
        tester,
      ) async {
        // Note: Custom chip implementation fires callback on every tap,
        // unlike SegmentedButton which only fires on actual selection change.
        // This is intentional to allow parent widget to handle re-taps if needed.
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

        expect(callCount, 1);
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
        expect(find.bySemanticsLabel('Fire data display mode'), findsOneWidget);
      });

      testWidgets('chips have tooltips for accessibility', (tester) async {
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

        // Find Tooltip widgets
        final tooltips = tester.widgetList<Tooltip>(
          find.descendant(
            of: find.byType(FireDataModeToggle),
            matching: find.byType(Tooltip),
          ),
        );

        expect(tooltips.length, 2);

        final messages = tooltips.map((t) => t.message).toList();
        expect(messages.any((m) => m!.contains('hotspot')), isTrue);
        expect(messages.any((m) => m!.contains('burnt area')), isTrue);
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

        // Find the outer Container with BoxDecoration that has shadow
        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(FireDataModeToggle),
            matching: find.byType(Container),
          ),
        );

        // First container is the outer one with shadow
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration?;

        expect(decoration, isNotNull);
        expect(decoration!.boxShadow, isNotNull);
        expect(decoration.boxShadow!.isNotEmpty, isTrue);
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

        // Find the outer Container with BoxDecoration
        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(FireDataModeToggle),
            matching: find.byType(Container),
          ),
        );

        // First container is the outer one with border radius
        final outerContainer = containers.first;
        final decoration = outerContainer.decoration as BoxDecoration?;

        expect(decoration, isNotNull);
        expect(decoration!.borderRadius, isNotNull);
        expect(decoration.borderRadius, equals(BorderRadius.circular(24)));
      });
    });
  });
}
