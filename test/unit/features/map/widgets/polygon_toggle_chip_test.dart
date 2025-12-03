import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/polygon_toggle_chip.dart';

void main() {
  group('PolygonToggleChip', () {
    testWidgets('shows "Areas ON" when showPolygons is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(
              showPolygons: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Areas ON'), findsOneWidget);
      expect(find.text('Areas OFF'), findsNothing);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('shows "Areas OFF" when showPolygons is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(
              showPolygons: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Areas OFF'), findsOneWidget);
      expect(find.text('Areas ON'), findsNothing);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
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
            body: PolygonToggleChip(
              showPolygons: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(PolygonToggleChip),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsOneWidget);

      // Verify the widget meets minimum touch target requirements
      final size = tester.getSize(find.byType(PolygonToggleChip));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('has proper semantics when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolygonToggleChip(
              showPolygons: true,
              onToggle: () {},
            ),
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
            body: PolygonToggleChip(
              showPolygons: false,
              onToggle: () {},
            ),
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

    testWidgets('uses different background color when enabled vs disabled',
        (tester) async {
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

      // Get first Material widget color for enabled state
      final enabledMaterials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(PolygonToggleChip),
          matching: find.byType(Material),
        ),
      );
      final enabledColor = enabledMaterials.first.color;

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

      final disabledMaterials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(PolygonToggleChip),
          matching: find.byType(Material),
        ),
      );
      final disabledColor = disabledMaterials.first.color;

      // Colors should differ between enabled and disabled states
      expect(enabledColor, isNot(equals(disabledColor)));
    });
  });
}
