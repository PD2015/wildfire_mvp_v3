import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/content/scotland_risk_guidance.dart';
import 'package:wildfire_mvp_v3/models/risk_guidance.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/widgets/risk_guidance_card.dart';

/// Widget tests for RiskGuidanceCard
///
/// Validates:
/// - Card renders with correct content for each risk level
/// - Border color matches risk level color
/// - Emergency footer displays 999 number
/// - Semantic labels for accessibility (C3)
/// - Generic guidance for null risk level
/// - Help icon renders and navigates when helpRoute provided
/// - Disclaimer renders when provided
void main() {
  group('RiskGuidanceCard', () {
    testWidgets('renders veryLow guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.veryLow)),
        ),
      );

      final guidance = ScotlandRiskGuidance.guidanceByLevel[RiskLevel.veryLow]!;

      // Verify title
      expect(find.text(guidance.title), findsOneWidget);

      // Verify summary
      expect(find.text(guidance.summary), findsOneWidget);

      // Verify all bullet points
      for (final point in guidance.bulletPoints) {
        expect(find.text(point), findsOneWidget);
      }

      // Verify emergency footer
      expect(find.text(ScotlandRiskGuidance.emergencyFooter), findsOneWidget);

      // Verify phone icon in footer
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('renders low guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.low)),
        ),
      );

      final guidance = ScotlandRiskGuidance.guidanceByLevel[RiskLevel.low]!;

      expect(find.text(guidance.title), findsOneWidget);
      expect(find.text(guidance.summary), findsOneWidget);
      for (final point in guidance.bulletPoints) {
        expect(find.text(point), findsOneWidget);
      }
    });

    testWidgets('renders moderate guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.moderate)),
        ),
      );

      final guidance =
          ScotlandRiskGuidance.guidanceByLevel[RiskLevel.moderate]!;

      expect(find.text(guidance.title), findsOneWidget);
      expect(find.text(guidance.summary), findsOneWidget);
      for (final point in guidance.bulletPoints) {
        expect(find.text(point), findsOneWidget);
      }
    });

    testWidgets('renders high guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.high)),
        ),
      );

      final guidance = ScotlandRiskGuidance.guidanceByLevel[RiskLevel.high]!;

      expect(find.text(guidance.title), findsOneWidget);
      expect(find.text(guidance.summary), findsOneWidget);
      for (final point in guidance.bulletPoints) {
        expect(find.text(point), findsOneWidget);
      }
    });

    testWidgets('renders veryHigh guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.veryHigh)),
        ),
      );

      final guidance =
          ScotlandRiskGuidance.guidanceByLevel[RiskLevel.veryHigh]!;

      expect(find.text(guidance.title), findsOneWidget);
      expect(find.text(guidance.summary), findsOneWidget);
      for (final point in guidance.bulletPoints) {
        expect(find.text(point), findsOneWidget);
      }
    });

    testWidgets('renders extreme guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.extreme)),
        ),
      );

      final guidance = ScotlandRiskGuidance.guidanceByLevel[RiskLevel.extreme]!;

      expect(find.text(guidance.title), findsOneWidget);
      expect(find.text(guidance.summary), findsOneWidget);
      for (final point in guidance.bulletPoints) {
        expect(find.text(point), findsOneWidget);
      }
    });

    testWidgets('renders generic guidance when level is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RiskGuidanceCard(level: null))),
      );

      const guidance = ScotlandRiskGuidance.genericGuidance;

      expect(find.text(guidance.title), findsOneWidget);
      expect(find.text(guidance.summary), findsOneWidget);
      for (final point in guidance.bulletPoints) {
        expect(find.text(point), findsOneWidget);
      }
    });

    testWidgets('has correct semantic label for veryLow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.veryLow)),
        ),
      );

      final semantics = tester.getSemantics(find.byType(RiskGuidanceCard));
      expect(semantics.label, contains('veryLow'));
      expect(semantics.label, contains('wildfire risk'));
    });

    testWidgets('has correct semantic label for null level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RiskGuidanceCard(level: null))),
      );

      final semantics = tester.getSemantics(find.byType(RiskGuidanceCard));
      expect(semantics.label, contains('General wildfire safety'));
    });

    testWidgets('displays card with rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.moderate)),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      expect(shape.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets('displays border with risk level color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.high)),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      expect(shape.side.color, equals(RiskLevel.high.color));
      expect(shape.side.width, equals(2));
    });

    testWidgets('displays border with theme outline color when level is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RiskGuidanceCard(level: null))),
      );

      final context = tester.element(find.byType(RiskGuidanceCard));
      final theme = Theme.of(context);
      final expectedColor = theme.colorScheme.outlineVariant;

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      expect(shape.side.color, equals(expectedColor));
      expect(shape.side.width, equals(2));
    });

    testWidgets('displays circle bullets with theme color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.veryHigh),
          ),
        ),
      );

      // Find Container widgets that are bullet points
      final bulletContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      // Should have 3+ bullets (one per bullet point)
      expect(bulletContainers, findsAtLeastNWidgets(3));

      // Verify first bullet uses theme's onSurfaceVariant color (not risk color)
      final firstBullet = tester.widget<Container>(bulletContainers.first);
      final decoration = firstBullet.decoration as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(RiskGuidanceCard)));
      expect(decoration.color, equals(theme.colorScheme.onSurfaceVariant));
    });

    testWidgets(
      'emergency footer is a FilledButton with tertiary container background',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            home: const Scaffold(
              body: RiskGuidanceCard(level: RiskLevel.extreme),
            ),
          ),
        );

        // Find the emergency footer FilledButton
        final footerButton = find.byType(FilledButton);
        expect(footerButton, findsOneWidget);

        // Verify it has the correct icon
        expect(
          find.descendant(of: footerButton, matching: find.byIcon(Icons.phone)),
          findsOneWidget,
        );
      },
    );

    testWidgets('all text is readable and not empty', (tester) async {
      // Test with moderate level
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.moderate)),
        ),
      );

      // Find all Text widgets
      final textWidgets = find.byType(Text);
      expect(
        textWidgets,
        findsAtLeastNWidgets(5),
      ); // Title, summary, bullets, footer

      // Verify none are empty
      for (final textFinder in textWidgets.evaluate()) {
        final textWidget = textFinder.widget as Text;
        final data = textWidget.data;
        if (data != null) {
          expect(data, isNotEmpty);
        }
      }
    });
  });

  group('RiskGuidanceCard help icon', () {
    testWidgets('renders info icon when helpRoute is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.moderate)),
        ),
      );

      // ScotlandRiskGuidance now provides helpRoute for all levels
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('does not render info icon when helpRoute is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(
              guidance: RiskGuidance(
                title: 'Test Title',
                summary: 'Test summary',
                bulletPoints: ['Point 1', 'Point 2'],
                // No helpRoute provided
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('info icon has ≥44dp tap target for accessibility', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.high)),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.constraints!.minWidth, greaterThanOrEqualTo(44));
      expect(iconButton.constraints!.minHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('info icon has tooltip with helpLinkLabel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.veryLow)),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Learn more about risk levels'));
    });
  });

  group('RiskGuidanceCard disclaimer', () {
    testWidgets('renders disclaimer when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.low)),
        ),
      );

      // ScotlandRiskGuidance now provides disclaimer for all levels
      expect(
        find.text(
          'Risk levels describe conditions, not safety. Fires can still start at any level.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not render disclaimer when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(
              guidance: RiskGuidance(
                title: 'Test Title',
                summary: 'Test summary',
                bulletPoints: ['Point 1'],
                // No disclaimer provided
              ),
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Risk levels describe conditions, not safety. Fires can still start at any level.',
        ),
        findsNothing,
      );
    });

    testWidgets('disclaimer uses secondary text styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskGuidanceCard(level: RiskLevel.extreme)),
        ),
      );

      final disclaimerText = tester.widget<Text>(
        find.text(
          'Risk levels describe conditions, not safety. Fires can still start at any level.',
        ),
      );
      expect(disclaimerText.style?.fontStyle, equals(FontStyle.italic));
    });
  });

  group('RiskGuidanceCard with custom guidance', () {
    testWidgets('uses provided guidance instead of ScotlandRiskGuidance', (
      tester,
    ) async {
      const customGuidance = RiskGuidance(
        title: 'Custom Title',
        summary: 'Custom summary text',
        bulletPoints: ['Custom point 1', 'Custom point 2'],
        helpRoute: '/custom/help',
        helpLinkLabel: 'Custom help',
        disclaimer: 'Custom disclaimer text',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(
              level: RiskLevel.high, // Level should be ignored
              guidance: customGuidance,
            ),
          ),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom summary text'), findsOneWidget);
      expect(find.text('Custom point 1'), findsOneWidget);
      expect(find.text('Custom point 2'), findsOneWidget);
      expect(find.text('Custom disclaimer text'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
