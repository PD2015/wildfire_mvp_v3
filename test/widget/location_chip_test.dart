import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/location_chip.dart';

/// Widget tests for LocationChip
///
/// Tests cover:
/// - Display format: "📍 Location Name · Source ˅"
/// - Always uses location_on icon (doesn't change with source)
/// - Source shown as text after dot separator
/// - Loading state
/// - Tap behavior and expand indicator
/// - Accessibility (C3 compliance)
void main() {
  group('LocationChip', () {
    Widget buildTestWidget({
      String locationName = 'Grantown-on-Spey',
      LocationSource? locationSource,
      Color parentBackgroundColor = const Color(0xFFFFEB3B), // Amber/Moderate
      VoidCallback? onTap,
      bool isExpanded = false,
      bool isLoading = false,
      String? coordinates,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: LocationChip(
              locationName: locationName,
              locationSource: locationSource,
              parentBackgroundColor: parentBackgroundColor,
              onTap: onTap,
              isExpanded: isExpanded,
              isLoading: isLoading,
              coordinates: coordinates,
            ),
          ),
        ),
      );
    }

    group('Display', () {
      testWidgets('shows location name', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationName: 'Grantown-on-Spey',
        ));

        expect(find.text('Grantown-on-Spey'), findsOneWidget);
      });

      testWidgets('truncates long location names', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationName:
              'Near Aviemore, Highland, Scotland, United Kingdom, Europe',
        ));

        expect(
          find.text(
              'Near Aviemore, Highland, Scotland, United Kingdom, Europe'),
          findsOneWidget,
        );
      });

      testWidgets('shows expand indicator when onTap provided', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onTap: () {},
        ));

        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      });

      testWidgets('hides expand indicator when no onTap', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onTap: null,
        ));

        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      });
    });

    group('Icon (always map pin)', () {
      testWidgets('shows location_on for GPS source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.gps,
        ));

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('shows location_on for manual source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.manual,
        ));

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('shows location_on for cached source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.cached,
        ));

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('shows location_on for default fallback', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.defaultFallback,
        ));

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('shows location_on when no source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: null,
        ));

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });
    });

    group('Source text after dot separator', () {
      testWidgets('shows "GPS" text for GPS source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.gps,
        ));

        expect(find.text('GPS'), findsOneWidget);
        expect(find.text(' · '), findsOneWidget);
      });

      testWidgets('shows "Manual" text for manual source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.manual,
        ));

        expect(find.text('Manual'), findsOneWidget);
      });

      testWidgets('shows "Cached" text for cached source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.cached,
        ));

        expect(find.text('Cached'), findsOneWidget);
      });

      testWidgets('shows "Default" text for default fallback', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: LocationSource.defaultFallback,
        ));

        expect(find.text('Default'), findsOneWidget);
      });

      testWidgets('no source text when source is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationSource: null,
        ));

        expect(find.text(' · '), findsNothing);
        expect(find.text('GPS'), findsNothing);
      });
    });

    group('Loading state', () {
      testWidgets('shows CircularProgressIndicator when loading',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          isLoading: true,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides map pin icon when loading', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          isLoading: true,
          locationSource: LocationSource.gps,
        ));

        expect(find.byIcon(Icons.location_on_outlined), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides source text when loading', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          isLoading: true,
          locationSource: LocationSource.gps,
        ));

        expect(find.text('GPS'), findsNothing);
        expect(find.text(' · '), findsNothing);
      });
    });

    group('Expand state', () {
      testWidgets('chevron points down when collapsed', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onTap: () {},
          isExpanded: false,
        ));

        final rotation = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation),
        );
        expect(rotation.turns, 0);
      });

      testWidgets('chevron rotates 180° when expanded', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onTap: () {},
          isExpanded: true,
        ));

        final rotation = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation),
        );
        expect(rotation.turns, 0.5);
      });
    });

    group('Tap behavior', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(buildTestWidget(
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(LocationChip));
        expect(tapped, isTrue);
      });

      testWidgets('does not crash when onTap is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onTap: null,
        ));

        await tester.tap(find.byType(LocationChip));
        await tester.pump();
      });
    });

    group('Accessibility (C3)', () {
      testWidgets('has minimum 36dp touch target height', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LocationChip),
            matching: find.byType(Container).first,
          ),
        );

        expect(container.constraints?.minHeight, greaterThanOrEqualTo(36));
      });

      testWidgets('has semantic label for screen readers', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationName: 'Grantown-on-Spey',
          locationSource: LocationSource.gps,
        ));

        expect(
          find.bySemanticsLabel(RegExp(r'Location from GPS.*Grantown-on-Spey')),
          findsOneWidget,
        );
      });

      testWidgets('marks as button when tappable', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationName: 'Test Location',
          onTap: () {},
        ));

        final inkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(inkWell.onTap, isNotNull);
      });

      testWidgets('includes expand state in semantics', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationName: 'Test Location',
          onTap: () {},
          isExpanded: true,
        ));

        expect(
          find.bySemanticsLabel(RegExp(r'expanded')),
          findsOneWidget,
        );
      });
    });

    group('Adaptive colors', () {
      testWidgets('renders on dark background', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          parentBackgroundColor: const Color(0xFF8B0000),
        ));

        expect(find.byType(LocationChip), findsOneWidget);
      });

      testWidgets('renders on light background', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          parentBackgroundColor: const Color(0xFFFFFF00),
        ));

        expect(find.byType(LocationChip), findsOneWidget);
      });
    });
  });
}
