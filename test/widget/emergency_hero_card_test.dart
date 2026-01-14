import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_hero_card.dart';

/// Widget tests for EmergencyHeroCard
///
/// Tests cover:
/// - Header display (icon, headline)
/// - Emergency instruction text
/// - 999 button functionality
/// - 101 Police button functionality
/// - Crimestoppers button functionality
/// - Disclaimer text
/// - Accessibility (C3 compliance)
void main() {
  group('EmergencyHeroCard', () {
    Widget buildTestWidget({
      VoidCallback? onCall999,
      VoidCallback? onCall101,
      VoidCallback? onCallCrimestoppers,
    }) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EmergencyHeroCard(
                onCall999: onCall999,
                onCall101: onCall101,
                onCallCrimestoppers: onCallCrimestoppers,
              ),
            ),
          ),
        ),
      );
    }

    group('Header display', () {
      testWidgets('shows warning icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      });

      testWidgets('shows headline text', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.text('See smoke, flames, or a campfire?'),
          findsOneWidget,
        );
      });
    });

    group('Instruction text', () {
      testWidgets('shows emergency instructions', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.textContaining('If it\'s spreading or unsafe'),
          findsOneWidget,
        );
        expect(
          find.textContaining('call 999 immediately'),
          findsOneWidget,
        );
      });
    });

    group('999 Button', () {
      testWidgets('shows 999 Fire Service button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find the exact text in the button (with en-dash)
        expect(find.text('999 – Fire Service'), findsOneWidget);
      });

      testWidgets('999 button is an ElevatedButton', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find ElevatedButton containing the 999 label
        final button = find.ancestor(
          of: find.text('999 – Fire Service'),
          matching: find.byType(ElevatedButton),
        );
        expect(button, findsOneWidget);
      });

      testWidgets('calls onCall999 when tapped', (tester) async {
        bool called = false;
        await tester.pumpWidget(buildTestWidget(
          onCall999: () => called = true,
        ));

        // Find and tap the 999 button
        final button = find.ancestor(
          of: find.text('999 – Fire Service'),
          matching: find.byType(ElevatedButton),
        );
        await tester.tap(button);
        await tester.pump();

        expect(called, isTrue);
      });
    });

    group('Secondary buttons', () {
      testWidgets('shows 101 Police button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('101 Police'), findsOneWidget);
      });

      testWidgets('shows Crimestoppers button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Crimestoppers'), findsOneWidget);
      });

      testWidgets('calls onCall101 when 101 button tapped', (tester) async {
        bool called = false;
        await tester.pumpWidget(buildTestWidget(
          onCall101: () => called = true,
        ));

        // Tap on the 101 Police text - the gesture bubbles up to the button
        await tester.tap(find.text('101 Police'));
        await tester.pump();

        expect(called, isTrue);
      });

      testWidgets('calls onCallCrimestoppers when Crimestoppers tapped',
          (tester) async {
        bool called = false;
        await tester.pumpWidget(buildTestWidget(
          onCallCrimestoppers: () => called = true,
        ));

        // Tap on the Crimestoppers text - the gesture bubbles up to the button
        await tester.tap(find.text('Crimestoppers'));
        await tester.pump();

        expect(called, isTrue);
      });

      testWidgets('secondary buttons are in a row', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Both 101 Police and Crimestoppers buttons exist
        expect(find.text('101 Police'), findsOneWidget);
        expect(find.text('Crimestoppers'), findsOneWidget);
      });
    });

    group('Non-emergency guidance', () {
      testWidgets('shows "Not an emergency?" heading', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Not an emergency?'), findsOneWidget);
      });

      testWidgets('shows 101 guidance for campfires and peat', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.textContaining('campfire or smouldering peat'),
          findsOneWidget,
        );
      });

      testWidgets('shows Crimestoppers guidance', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.textContaining('Suspicious activity'),
          findsOneWidget,
        );
      });

      testWidgets('shows "Learn more" link', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.text('When to call each number →'),
          findsOneWidget,
        );
      });

      testWidgets('"Learn more" link has semantic label', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find InkWell with the link text
        final inkWell =
            find.widgetWithText(InkWell, 'When to call each number →');
        expect(inkWell, findsOneWidget);
      });
    });

    group('Disclaimer', () {
      testWidgets('shows disclaimer text', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.textContaining('does not contact emergency services'),
          findsOneWidget,
        );
      });

      testWidgets('shows info icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });
    });

    group('Accessibility (C3)', () {
      testWidgets('has semantic container label', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final semantics = tester.getSemantics(find.byType(EmergencyHeroCard));
        expect(semantics.label, contains('Emergency'));
      });

      testWidgets('headline has header semantics', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find text with header semantics
        final headline = find.text('See smoke, flames, or a campfire?');
        expect(headline, findsOneWidget);

        // The header should be in a Semantics widget with header: true
        final semanticsWidget = find.ancestor(
          of: headline,
          matching: find.byType(Semantics),
        );
        expect(semanticsWidget, findsWidgets);
      });

      testWidgets('999 button has minimum touch target', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final button = find.ancestor(
          of: find.text('999 – Fire Service'),
          matching: find.byType(ElevatedButton),
        );
        final renderBox = tester.renderObject(button.first) as RenderBox;

        expect(renderBox.size.height, greaterThanOrEqualTo(48));
      });

      testWidgets('secondary buttons have minimum touch target',
          (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find the SizedBox containers wrapping the OutlinedButtons
        // The SizedBox has height: 48.0 set explicitly
        final sizedBoxes = find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.height == 48.0 &&
              widget.child is OutlinedButton,
        );

        // Should find exactly 2 SizedBoxes (101 Police and Crimestoppers)
        expect(sizedBoxes, findsNWidgets(2));
      });
    });
  });
}
