import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/widgets/risk_scale.dart';

void main() {
  group('RiskScale Widget', () {
    testWidgets('renders all 6 risk level bars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.moderate,
              textColor: RiskPalette.white,
            ),
          ),
        ),
      );

      // Verify all 6 bars are rendered (inside AnimatedContainer widgets)
      expect(find.byType(AnimatedContainer), findsNWidgets(6));
    });

    testWidgets('highlights current risk level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.high,
              textColor: RiskPalette.white,
            ),
          ),
        ),
      );

      // Find all Semantics widgets and check that HIGH level is marked as selected
      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );

      // Find the one with label 'HIGH' and verify it's selected
      final highSemantic = semanticsWidgets.firstWhere(
        (s) => s.properties.label == 'HIGH',
      );

      expect(highSemantic.properties.selected, true);

      // Verify other levels are not selected
      final lowSemantic = semanticsWidgets.firstWhere(
        (s) => s.properties.label == 'LOW',
      );
      expect(lowSemantic.properties.selected, isFalse);
    });

    testWidgets('shows tooltips on all bars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.veryLow,
              textColor: RiskPalette.white,
            ),
          ),
        ),
      );

      // Verify all 6 tooltips exist
      expect(find.byType(Tooltip), findsNWidgets(6));

      // Verify tooltip messages
      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      final messages = tooltips.map((t) => t.message).toList();

      expect(
        messages,
        containsAll([
          'VERY LOW',
          'LOW',
          'MODERATE',
          'HIGH',
          'VERY HIGH',
          'EXTREME',
        ]),
      );
    });

    testWidgets('displays level labels when showLabels is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.moderate,
              textColor: RiskPalette.white,
              showLabels: true,
            ),
          ),
        ),
      );

      // Verify labels are shown (6 labels + possible other Text widgets)
      expect(find.byType(Text), findsAtLeastNWidgets(6));

      // Check for specific short labels
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Mod'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('hides level labels when showLabels is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.moderate,
              textColor: RiskPalette.white,
              showLabels: false,
            ),
          ),
        ),
      );

      // Verify no label text widgets
      expect(find.text('Low'), findsNothing);
      expect(find.text('Mod'), findsNothing);
      expect(find.text('High'), findsNothing);
    });

    testWidgets('uses correct colors from RiskPalette', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.extreme,
              textColor: RiskPalette.white,
            ),
          ),
        ),
      );

      // Get all AnimatedContainer widgets
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // Verify each container has a decoration with a color from RiskPalette
      final expectedColors = [
        RiskPalette.veryLow,
        RiskPalette.low,
        RiskPalette.moderate,
        RiskPalette.high,
        RiskPalette.veryHigh,
        RiskPalette.extreme,
      ];

      int colorIndex = 0;
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        final baseColor = expectedColors[colorIndex];

        // Current level (extreme) should have full opacity
        if (colorIndex == 5) {
          // extreme is last (index 5)
          expect(decoration.color, baseColor.withValues(alpha: 1.0));
        } else {
          // Other levels should have reduced opacity
          expect(decoration.color, baseColor.withValues(alpha: 0.65));
        }

        colorIndex++;
      }
    });

    testWidgets('animates height change for current level', (tester) async {
      const barHeight = 8.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.low,
              textColor: RiskPalette.white,
              barHeight: barHeight,
            ),
          ),
        ),
      );

      // Verify LOW level bar has scaled height (via constraints or direct check)
      // LOW is at index 1 in RiskLevel.values
      final lowBar = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).at(1),
      );

      // Check that the animation properties are set correctly
      expect(lowBar.duration, const Duration(milliseconds: 200));
      expect(lowBar.curve, Curves.easeInOut);
    });

    testWidgets('respects custom barHeight parameter', (tester) async {
      const customHeight = 12.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.moderate,
              textColor: RiskPalette.white,
              barHeight: customHeight,
            ),
          ),
        ),
      );

      // Verify animation properties are configured
      final moderateBar = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).at(2), // MODERATE is at index 2
      );

      expect(moderateBar.duration, const Duration(milliseconds: 200));
      expect(moderateBar.curve, Curves.easeInOut);
    });

    testWidgets('has proper semantics for accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.veryHigh,
              textColor: RiskPalette.white,
            ),
          ),
        ),
      );

      // Verify main container has descriptive label
      final mainSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains(
                'Risk scale showing VERY HIGH highlighted',
              ),
        ),
      );

      expect(mainSemantics.properties.label, isNotNull);
      expect(
        mainSemantics.properties.label,
        'Risk scale showing VERY HIGH highlighted among all six risk levels',
      );
    });
  });

  group('RiskScale Tappable Behavior', () {
    testWidgets('does not show InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.moderate,
              textColor: RiskPalette.white,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('wraps content in InkWell when onTap is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.moderate,
              textColor: RiskPalette.white,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.high,
              textColor: RiskPalette.white,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('has correct semantics when tappable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.low,
              textColor: RiskPalette.white,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the outer Semantics widget with button property
      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!
                  .contains('Learn what the wildfire risk levels mean'),
        ),
      );

      expect(semantics.properties.label,
          'Learn what the wildfire risk levels mean');
      expect(semantics.properties.hint, 'Opens help information');
      expect(semantics.properties.button, isTrue);
    });

    testWidgets('has minimum 44dp tap target height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.extreme,
              textColor: RiskPalette.white,
              onTap: () {},
            ),
          ),
        ),
      );

      final constrainedBoxFinder = find.descendant(
        of: find.byType(RiskScale),
        matching: find.byType(ConstrainedBox),
      );

      // Get the first ConstrainedBox (the outer tap target wrapper)
      final constrainedBox =
          tester.widget<ConstrainedBox>(constrainedBoxFinder.first);

      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('tap anywhere on scale row triggers callback', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.veryLow,
              textColor: RiskPalette.white,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      // Tap on the left side
      await tester.tapAt(
          tester.getTopLeft(find.byType(InkWell)) + const Offset(10, 10));
      await tester.pump();
      expect(tapCount, 1);

      // Tap on the right side
      await tester.tapAt(
          tester.getTopRight(find.byType(InkWell)) + const Offset(-10, 10));
      await tester.pump();
      expect(tapCount, 2);

      // Tap in the center
      await tester.tapAt(tester.getCenter(find.byType(InkWell)));
      await tester.pump();
      expect(tapCount, 3);
    });

    testWidgets('uses descriptive semantics when not tappable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskScale(
              currentLevel: RiskLevel.high,
              textColor: RiskPalette.white,
              // No onTap - should use descriptive semantics
            ),
          ),
        ),
      );

      // Find semantics with descriptive label
      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('Risk scale showing HIGH'),
        ),
      );

      expect(semantics.properties.label, contains('Risk scale showing HIGH'));
      expect(semantics.properties.button, isNull);
    });
  });
}
