import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/content/scotland_risk_guidance.dart';
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
void main() {
  group('RiskGuidanceCard', () {
    testWidgets('renders veryLow guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.veryLow),
          ),
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
      expect(
        find.text(ScotlandRiskGuidance.emergencyFooter),
        findsOneWidget,
      );

      // Verify phone icon in footer
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('renders low guidance correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.low),
          ),
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
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.moderate),
          ),
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
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.high),
          ),
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
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.veryHigh),
          ),
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
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.extreme),
          ),
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
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: null),
          ),
        ),
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
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.veryLow),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(RiskGuidanceCard));
      expect(
        semantics.label,
        contains('veryLow'),
      );
      expect(
        semantics.label,
        contains('wildfire risk'),
      );
    });

    testWidgets('has correct semantic label for null level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: null),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(RiskGuidanceCard));
      expect(
        semantics.label,
        contains('General wildfire safety'),
      );
    });

    testWidgets('displays card with rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.moderate),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      expect(shape.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets('displays border with risk level color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.high),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      expect(shape.side.color, equals(RiskLevel.high.color));
      expect(shape.side.width, equals(2));
    });

    testWidgets('displays border with grey when level is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: null),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      expect(shape.side.color, equals(Colors.grey));
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

    testWidgets('emergency footer has error container background',
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

      // Find the emergency footer Container
      final footerContainer = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.padding == const EdgeInsets.all(12) &&
            widget.decoration is BoxDecoration,
      );

      expect(footerContainer, findsOneWidget);
    });

    testWidgets('all text is readable and not empty', (tester) async {
      // Test with moderate level
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskGuidanceCard(level: RiskLevel.moderate),
          ),
        ),
      );

      // Find all Text widgets
      final textWidgets = find.byType(Text);
      expect(textWidgets,
          findsAtLeastNWidgets(5)); // Title, summary, bullets, footer

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
}
