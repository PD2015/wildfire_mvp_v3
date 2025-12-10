import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/pages/welcome_page.dart';

void main() {
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

    testWidgets('displays Get Started button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomePage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Get Started'), findsOneWidget);
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

      await tester.tap(find.text('Get Started'));
      await tester.pump();

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
