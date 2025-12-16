import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/pages/setup_page.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';

void main() {
  // Helper to scroll within page and tap
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

  group('SetupPage', () {
    testWidgets('displays setup title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Set Your Preferences'), findsOneWidget);
    });

    testWidgets('displays notification radius section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Notification Radius'), findsOneWidget);
      expect(find.text('Get notified about fires within:'), findsOneWidget);
    });

    testWidgets('displays radius selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      // Check radius options are visible
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('10km'), findsOneWidget);
    });

    testWidgets('calls onRadiusChanged when selection changes', (tester) async {
      int? selectedRadius;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (radius) => selectedRadius = radius,
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      await scrollAndTap(tester, '25km');

      expect(selectedRadius, 25);
    });

    testWidgets('displays terms checkbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('calls onTermsChanged when terms checkbox toggled',
        (tester) async {
      bool? accepted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (value) => accepted = value,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Scroll to terms checkbox first since it may be off-screen
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('terms_checkbox')),
        50,
        scrollable: scrollableFinder,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
    });

    testWidgets('calls onDisclaimerChanged when disclaimer checkbox toggled',
        (tester) async {
      bool? acknowledged;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: false,
              onDisclaimerChanged: (value) => acknowledged = value,
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      // Scroll to disclaimer checkbox first since it may be off-screen
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('disclaimer_checkbox')),
        50,
        scrollable: scrollableFinder,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('disclaimer_checkbox')));
      await tester.pumpAndSettle();

      expect(acknowledged, isTrue);
    });

    testWidgets('displays version info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('Terms version: ${OnboardingConfig.currentTermsVersion}'),
        findsOneWidget,
      );
    });

    testWidgets('Complete button disabled when terms not accepted',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Complete Setup'),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('Complete button enabled when both checkboxes checked',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: true,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Complete Setup'),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('Complete button disabled when disclaimer not acknowledged',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: false,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: true, // Terms accepted but disclaimer not
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Complete Setup'),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('calls onComplete when button tapped with terms accepted',
        (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: true,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () => called = true,
            ),
          ),
        ),
      );

      await scrollAndTap(tester, 'Complete Setup');

      expect(called, isTrue);
    });

    testWidgets('shows helper text when terms not accepted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(
        find.text(
            'Please acknowledge the disclaimer and accept the terms to continue'),
        findsOneWidget,
      );
    });

    testWidgets('hides helper text when both checkboxes checked',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: true,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(
        find.text(
            'Please acknowledge the disclaimer and accept the terms to continue'),
        findsNothing,
      );
    });

    testWidgets('calls onViewTerms when terms link tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
              onViewTerms: () => called = true,
            ),
          ),
        ),
      );

      await scrollAndTap(tester, 'Terms of Service');

      expect(called, isTrue);
    });

    testWidgets('calls onViewPrivacy when privacy link tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 10,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
              onViewPrivacy: () => called = true,
            ),
          ),
        ),
      );

      await scrollAndTap(tester, 'Privacy Policy');

      expect(called, isTrue);
    });

    testWidgets('updates radius description when Off selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 0,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(
        find.text("You won't receive fire notifications"),
        findsOneWidget,
      );
    });

    testWidgets('shows radius description with km value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupPage(
              disclaimerAcknowledged: true,
              onDisclaimerChanged: (_) {},
              initialRadius: 25,
              termsAccepted: false,
              onRadiusChanged: (_) {},
              onTermsChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(
        find.text(
            "You'll be notified about fires within 25 km of your location"),
        findsOneWidget,
      );
    });
  });
}
