import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/widgets/chips/data_source_chip.dart';

void main() {
  group('DataSourceChip Widget Tests', () {
    testWidgets('displays LIVE chip with correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataSourceChip(sourceType: DataSourceType.live),
          ),
        ),
      );

      // Verify label
      expect(find.text('LIVE'), findsOneWidget);
      
      // Verify icon
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      
      // Verify chip exists
      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, equals(RiskPalette.low)); // Green for live
      
      // Verify semantic label exists in the widget tree
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && 
                    widget.properties.label != null &&
                    widget.properties.label!.contains('Live data from EFFIS'),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('displays CACHED chip with correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataSourceChip(sourceType: DataSourceType.cached),
          ),
        ),
      );

      // Verify label
      expect(find.text('CACHED'), findsOneWidget);
      
      // Verify icon
      expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
      
      // Verify chip exists
      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, equals(RiskPalette.lightGray)); // Gray for cached
      
      // Verify semantic label exists in the widget tree
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && 
                    widget.properties.label != null &&
                    widget.properties.label!.contains('Cached data'),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('displays MOCK chip with correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataSourceChip(sourceType: DataSourceType.mock),
          ),
        ),
      );

      // Verify label
      expect(find.text('MOCK'), findsOneWidget);
      
      // Verify icon
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
      
      // Verify chip exists
      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, equals(RiskPalette.blueAccent)); // Blue for test
      
      // Verify semantic label exists in the widget tree
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && 
                    widget.properties.label != null &&
                    widget.properties.label!.contains('Mock test data'),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('accepts custom label override', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataSourceChip(
              sourceType: DataSourceType.live,
              label: 'CUSTOM',
            ),
          ),
        ),
      );

      // Verify custom label is displayed
      expect(find.text('CUSTOM'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
    });

    testWidgets('chip has compact size and proper padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataSourceChip(sourceType: DataSourceType.live),
          ),
        ),
      );

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.materialTapTargetSize, equals(MaterialTapTargetSize.shrinkWrap));
      expect(chip.visualDensity, equals(VisualDensity.compact));
      expect(chip.padding, equals(const EdgeInsets.symmetric(horizontal: 8, vertical: 4)));
    });

    testWidgets('all chip types have distinct colors (C4 compliance)', (tester) async {
      const sourceTypes = [
        DataSourceType.live,
        DataSourceType.cached,
        DataSourceType.mock,
      ];

      final Set<Color> backgroundColors = {};
      
      for (final sourceType in sourceTypes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DataSourceChip(sourceType: sourceType),
            ),
          ),
        );
        
        final chip = tester.widget<Chip>(find.byType(Chip));
        backgroundColors.add(chip.backgroundColor!);
      }
      
      // Verify all three source types have distinct background colors
      expect(backgroundColors.length, equals(3),
          reason: 'Each data source type must have a visually distinct color');
    });

    testWidgets('semantic labels are accessible (C3 compliance)', (tester) async {
      const sourceTypes = [
        DataSourceType.live,
        DataSourceType.cached,
        DataSourceType.mock,
      ];

      for (final sourceType in sourceTypes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DataSourceChip(sourceType: sourceType),
            ),
          ),
        );
        
        // Find the Semantics widget with a non-empty label
        final semanticsFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && 
                      widget.properties.label != null &&
                      widget.properties.label!.isNotEmpty,
        );
        expect(semanticsFinder, findsWidgets,
            reason: 'Each chip must have semantic labeling');
      }
    });

    testWidgets('chip border is visible for all types', (tester) async {
      const sourceTypes = [
        DataSourceType.live,
        DataSourceType.cached,
        DataSourceType.mock,
      ];

      for (final sourceType in sourceTypes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DataSourceChip(sourceType: sourceType),
            ),
          ),
        );
        
        final chip = tester.widget<Chip>(find.byType(Chip));
        expect(chip.side, isNotNull, reason: 'Chip must have border');
        expect(chip.side!.width, equals(1.5),
            reason: 'Border must be visible (1.5px width)');
      }
    });
  });
}
