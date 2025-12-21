import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/features/onboarding/screens/onboarding_screen.dart';
import 'package:wildfire_mvp_v3/features/onboarding/widgets/page_indicator.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs_impl.dart';

void main() {
  late OnboardingPrefsImpl prefsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    prefsService = OnboardingPrefsImpl(prefs);
  });

  // Helper to scroll within current page and tap
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

  // Helper to tap a CheckboxListTile by finding and tapping the Checkbox inside it
  // This avoids hitting GestureDetector links within the tile
  Future<void> tapCheckboxListTile(WidgetTester tester, Key tileKey) async {
    final tileFinder = find.byKey(tileKey);
    final scrollableFinder = find.byType(Scrollable);
    if (scrollableFinder.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(
          tileFinder,
          50,
          scrollable: scrollableFinder.first,
        );
      } catch (_) {
        // Checkbox might already be visible
      }
    }
    await tester.pumpAndSettle();

    // Find the Checkbox widget inside the CheckboxListTile
    final checkboxFinder = find.descendant(
      of: tileFinder,
      matching: find.byType(Checkbox),
    );

    if (checkboxFinder.evaluate().isNotEmpty) {
      await tester.tap(checkboxFinder);
    } else {
      // Fallback: tap the tile itself
      await tester.tap(tileFinder);
    }
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen', () {
    testWidgets('displays page indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      expect(find.byType(PageIndicator), findsOneWidget);
    });

    testWidgets('starts on welcome page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      expect(find.text('Welcome to WildFire'), findsOneWidget);
    });

    testWidgets('navigates to disclaimer page on continue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      await scrollAndTap(tester, 'Continue');

      expect(find.text('Important Safety Information'), findsOneWidget);
    });

    testWidgets('navigates to privacy page from disclaimer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Navigate through pages with scroll support
      await scrollAndTap(tester, 'Continue');
      await scrollAndTap(tester, 'I Understand');

      expect(find.text('Your Privacy Matters'), findsOneWidget);
    });

    testWidgets('navigates to setup page from privacy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Navigate through pages with scroll support
      await scrollAndTap(tester, 'Continue');
      await scrollAndTap(tester, 'I Understand');
      await scrollAndTap(tester, 'Continue');

      expect(find.text('Set Your Preferences'), findsOneWidget);
    });

    testWidgets('page indicator updates as pages change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Verify initial page indicator (semantics: "Step X of Y: title")
      expect(find.bySemanticsLabel(RegExp(r'Step 1 of 4')), findsOneWidget);

      // Navigate to next page with scroll support
      await scrollAndTap(tester, 'Continue');

      // Verify page indicator updated
      expect(find.bySemanticsLabel(RegExp(r'Step 2 of 4')), findsOneWidget);
    });

    testWidgets('calls onComplete after completing onboarding', (tester) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
            onComplete: () => completed = true,
          ),
        ),
      );

      // Navigate through all pages with scroll support
      await scrollAndTap(tester, 'Continue');
      await scrollAndTap(tester, 'I Understand');
      await scrollAndTap(tester, 'Continue');

      // Accept both checkboxes using helper that targets the Checkbox widget
      await tapCheckboxListTile(tester, const Key('disclaimer_checkbox'));
      await tapCheckboxListTile(tester, const Key('terms_checkbox'));

      await scrollAndTap(tester, 'Complete Setup');

      expect(completed, isTrue);
    });

    testWidgets('saves consent when completing onboarding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Navigate through all pages with scroll support
      await scrollAndTap(tester, 'Continue');
      await scrollAndTap(tester, 'I Understand');
      await scrollAndTap(tester, 'Continue');

      // Accept both checkboxes using helper that targets the Checkbox widget
      await tapCheckboxListTile(tester, const Key('disclaimer_checkbox'));
      await tapCheckboxListTile(tester, const Key('terms_checkbox'));

      await scrollAndTap(tester, 'Complete Setup');

      // Verify consent was recorded
      final consent = await prefsService.getConsentRecord();
      expect(consent, isNotNull);
      expect(consent!.termsVersion, OnboardingConfig.currentTermsVersion);
    });

    testWidgets('saves default notification radius when completing onboarding',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Navigate through all pages with scroll support
      await scrollAndTap(tester, 'Continue');
      await scrollAndTap(tester, 'I Understand');
      await scrollAndTap(tester, 'Continue');

      // Accept both checkboxes using helper that targets the Checkbox widget
      await tapCheckboxListTile(tester, const Key('disclaimer_checkbox'));
      await tapCheckboxListTile(tester, const Key('terms_checkbox'));

      // Complete onboarding (uses default radius of 10)
      await scrollAndTap(tester, 'Complete Setup');

      // Verify default radius was saved
      final radius = await prefsService.getNotificationRadiusKm();
      expect(radius, OnboardingConfig.defaultRadiusKm);
    });

    testWidgets('uses PageView for page navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('disables swipe navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Try to swipe left
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Should still be on welcome page (swipe disabled)
      expect(find.text('Welcome to WildFire'), findsOneWidget);
    });
  });
}
