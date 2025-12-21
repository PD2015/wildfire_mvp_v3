import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/pages/welcome_page.dart';

void main() {
  // Helper to scroll within page and tap by text
  Future<void> scrollAndTap(WidgetTester tester, String text) async {
    final scrollableFinder = find.byType(Scrollable);
    if (scrollableFinder.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(
          find.text(text),
          50,
          scrollable: scrollableFinder.first,
        );
      } catch (_) {
        // Button might already be visible
      }
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('WelcomePage', () {
    testWidgets('displays app title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Welcome to WildFire'), findsOneWidget);
    });

    testWidgets('displays subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('Stay informed about wildfire activity in Scotland'),
        findsOneWidget,
      );
    });

    testWidgets('displays feature list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('View active fires on an interactive map'),
        findsOneWidget,
      );
      expect(
        find.text('Check fire risk levels for your area'),
        findsOneWidget,
      );
      expect(
        find.text('Get alerts about nearby fire activity'),
        findsOneWidget,
      );
    });

    testWidgets('displays fire icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('displays Continue button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('calls onContinue when button tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () => called = true,
            ),
          ),
        ),
      );

      await scrollAndTap(tester, 'Continue');

      expect(called, isTrue);
    });

    testWidgets('button has 56dp height for accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(FilledButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.height, 56);
    });
  });
}
