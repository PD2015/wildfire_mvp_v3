import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/pages/privacy_page.dart';

void main() {
  group('PrivacyPage', () {
    testWidgets('displays privacy title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Your Privacy Matters'), findsOneWidget);
    });

    testWidgets('displays shield icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('displays what we use section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('What we use'), findsOneWidget);
      expect(
        find.text('Location (only while app is open)'),
        findsOneWidget,
      );
      expect(
        find.text('Your notification preferences'),
        findsOneWidget,
      );
    });

    testWidgets('displays what we don\'t do section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('What we don\'t do'), findsOneWidget);
      expect(find.text('No tracking or analytics'), findsOneWidget);
      expect(
        find.text('No personal data stored on servers'),
        findsOneWidget,
      );
      expect(find.text('No location history saved'), findsOneWidget);
    });

    testWidgets('displays Continue button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('calls onContinue when button tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () => called = true,
            ),
          ),
        ),
      );

      // Scroll to make the button visible
      await tester.scrollUntilVisible(
        find.text('Continue'),
        50,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('shows privacy link when callback provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
              onViewPrivacy: () {},
            ),
          ),
        ),
      );

      expect(find.text('View full privacy policy'), findsOneWidget);
    });

    testWidgets('hides privacy link when callback not provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
            ),
          ),
        ),
      );

      expect(find.text('View full privacy policy'), findsNothing);
    });

    testWidgets('calls onViewPrivacy when link tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacyPage(
              onContinue: () {},
              onViewPrivacy: () => called = true,
            ),
          ),
        ),
      );

      // Scroll to make the link visible
      await tester.scrollUntilVisible(
        find.text('View full privacy policy'),
        50,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View full privacy policy'));
      await tester.pump();

      expect(called, isTrue);
    });
  });
}
