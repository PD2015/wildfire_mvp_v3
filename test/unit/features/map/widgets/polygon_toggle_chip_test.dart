import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/polygon_toggle_chip.dart';

void main() {
  group('PolygonToggleChip', () {
    testWidgets('shows "Hide burn areas" when showPolygons is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(showPolygons: true, onToggle: () {}),
          ),
        ),
      );

      expect(find.text('Hide burn areas'), findsOneWidget);
      expect(find.text('Show burn areas'), findsNothing);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('shows "Show burn areas" when showPolygons is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(showPolygons: false, onToggle: () {}),
          ),
        ),
      );

      expect(find.text('Show burn areas'), findsOneWidget);
      expect(find.text('Hide burn areas'), findsNothing);
      expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
    });

    testWidgets('calls onToggle when tapped', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(
              showPolygons: true,
              onToggle: () {
                toggled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PolygonToggleChip));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('does not call onToggle when disabled', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(
              showPolygons: true,
              enabled: false,
              onToggle: () {
                toggled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PolygonToggleChip));
      await tester.pump();

      expect(toggled, isFalse);
    });

    testWidgets('has minimum 44dp touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(showPolygons: true, onToggle: () {}),
          ),
        ),
      );

      // Verify the widget meets minimum touch target requirements (48dp set in widget)
      final size = tester.getSize(find.byType(PolygonToggleChip));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('has proper semantics when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(showPolygons: true, onToggle: () {}),
          ),
        ),
      );

      // Find the Semantics widget and verify the label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.contains('Burnt areas visible') == true,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('has proper semantics when areas hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(showPolygons: false, onToggle: () {}),
          ),
        ),
      );

      // Find the Semantics widget and verify the label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.contains('Burnt areas hidden') == true,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('uses reduced opacity for disabled state', (tester) async {
      // Enabled state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(
              showPolygons: true,
              enabled: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Get icon color for enabled state
      final enabledIcon = tester.widget<Icon>(
        find.byIcon(Icons.local_fire_department),
      );
      final enabledOpacity = enabledIcon.color?.a ?? 1.0;

      // Disabled state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(
              showPolygons: true,
              enabled: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      final disabledIcon = tester.widget<Icon>(
        find.byIcon(Icons.local_fire_department),
      );
      final disabledOpacity = disabledIcon.color?.a ?? 1.0;

      // Disabled state should have lower opacity
      expect(disabledOpacity, lessThan(enabledOpacity));
    });
  });
}
