import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/pages/disclaimer_page.dart';

void main() {
  // Helper to scroll within page and tap by text
  Future<void> scrollAndTap(WidgetTester tester, String text) async {
    final scrollableFinder = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text(text),
      50,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('DisclaimerPage', () {
    testWidgets('displays safety information title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Important Safety Information'), findsOneWidget);
    });

    testWidgets('displays warning icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('displays emergency numbers 999 and 101', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('999'), findsOneWidget);
      expect(find.text('101'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);
      expect(find.text('Non-emergency'), findsOneWidget);
    });

    testWidgets('displays disclaimer text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('informational data only'),
        findsOneWidget,
      );
    });

    testWidgets('displays I Understand button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('I Understand'), findsOneWidget);
    });

    testWidgets('calls onContinue when button tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () => called = true,
            ),
          ),
        ),
      );

      await scrollAndTap(tester, 'I Understand');

      expect(called, isTrue);
    });

    testWidgets('shows terms link when callback provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
              onViewTerms: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('View full terms and conditions'),
        findsOneWidget,
      );
    });

    testWidgets('hides terms link when callback not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('View full terms and conditions'),
        findsNothing,
      );
    });

    testWidgets('calls onViewTerms when link tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisclaimerPage(
              onContinue: () {},
              onViewTerms: () => called = true,
            ),
          ),
        ),
      );

      await scrollAndTap(tester, 'View full terms and conditions');

      expect(called, isTrue);
    });
  });
}
