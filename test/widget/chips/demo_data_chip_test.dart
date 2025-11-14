import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/widgets/chips/demo_data_chip.dart';

void main() {
  group('DemoDataChip Widget Tests', () {
    testWidgets('displays default DEMO DATA label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(),
          ),
        ),
      );

      // Verify default label
      expect(find.text('DEMO DATA'), findsOneWidget);
      
      // Verify warning icon
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('displays custom label when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(label: 'TEST REGION'),
          ),
        ),
      );

      // Verify custom label
      expect(find.text('TEST REGION'), findsOneWidget);
      expect(find.text('DEMO DATA'), findsNothing);
      
      // Icon should still be present
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('has high contrast styling (C3 compliance)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(),
          ),
        ),
      );

      // Find the Container widget
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      
      // Verify high contrast colors
      expect(decoration.color, equals(RiskPalette.extreme), 
          reason: 'Background should be red for high visibility');
      expect(decoration.border?.top.color, equals(RiskPalette.white),
          reason: 'White border provides high contrast against red');
      expect(decoration.border?.top.width, equals(2),
          reason: 'Bold border for visibility');
      
      // Verify text color
      final text = tester.widget<Text>(find.text('DEMO DATA'));
      expect(text.style?.color, equals(RiskPalette.white),
          reason: 'White text on red background ensures readability');
    });

    testWidgets('has proper semantic labeling (C3 compliance)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(),
          ),
        ),
      );

      // Find the Semantics widget with our specific label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && 
                    widget.properties.label != null &&
                    widget.properties.label!.contains('Warning') &&
                    widget.properties.label!.contains('DEMO DATA'),
      );
      expect(semanticsFinder, findsOneWidget);
      
      final semantics = tester.widget<Semantics>(semanticsFinder);
      expect(semantics.properties.label, contains('test data'),
          reason: 'Should explain what demo data means');
    });

    testWidgets('semantic label updates with custom label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(label: 'TEST REGION'),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && 
                    widget.properties.label != null &&
                    widget.properties.label!.contains('TEST REGION'),
      );
      expect(semanticsFinder, findsOneWidget,
          reason: 'Custom label should be reflected in semantic label');
    });

    testWidgets('has shadow for visibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      
      expect(decoration.boxShadow, isNotNull,
          reason: 'Shadow helps chip stand out');
      expect(decoration.boxShadow!.length, greaterThan(0),
          reason: 'At least one shadow should be defined');
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;
      
      expect(borderRadius.topLeft.x, equals(16),
          reason: 'Rounded corners improve visual appeal');
    });

    testWidgets('icon and text are properly spaced', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(),
          ),
        ),
      );

      // Find the Row containing icon and text
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, equals(MainAxisSize.min),
          reason: 'Chip should only take up needed space');
      
      // Verify SizedBox spacing exists between icon and text
      // The Icon widget creates its own SizedBox, so we find the custom spacing SizedBox
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();
      final spacingSizedBox = sizedBoxes.firstWhere(
        (box) => box.width == 6 && box.height == null,
        orElse: () => throw Exception('Spacing SizedBox not found'),
      );
      
      expect(spacingSizedBox.width, equals(6),
          reason: 'Icon and text should have 6px spacing');
    });

    testWidgets('text has bold styling for prominence', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('DEMO DATA'));
      expect(text.style?.fontWeight, equals(FontWeight.bold),
          reason: 'Bold text increases visibility');
      expect(text.style?.letterSpacing, greaterThan(0),
          reason: 'Letter spacing improves readability');
    });

    testWidgets('is visible against various backgrounds', (tester) async {
      // Test against light background
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: DemoDataChip(),
          ),
        ),
      );
      
      expect(find.byType(DemoDataChip), findsOneWidget);
      
      // Test against dark background
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: DemoDataChip(),
          ),
        ),
      );
      
      expect(find.byType(DemoDataChip), findsOneWidget,
          reason: 'Chip with white border and shadow should be visible on dark background');
    });

    testWidgets('maintains consistent size with different labels', (tester) async {
      // Short label
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(label: 'TEST'),
          ),
        ),
      );
      
      final shortSize = tester.getSize(find.byType(Container));
      
      // Long label
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DemoDataChip(label: 'DEMONSTRATION DATA'),
          ),
        ),
      );
      
      final longSize = tester.getSize(find.byType(Container));
      
      // Height should remain consistent
      expect(longSize.height, equals(shortSize.height),
          reason: 'Chip height should be consistent regardless of text length');
      
      // Width should expand to accommodate text
      expect(longSize.width, greaterThan(shortSize.width),
          reason: 'Chip should expand horizontally for longer text');
    });
  });
}
