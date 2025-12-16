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

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

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

      // Verify initial page indicator
      expect(find.bySemanticsLabel('Page 1 of 4'), findsOneWidget);

      // Navigate to next page with scroll support
      await scrollAndTap(tester, 'Continue');

      // Verify page indicator updated
      expect(find.bySemanticsLabel('Page 2 of 4'), findsOneWidget);
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

      // Scroll to and accept both checkboxes (disclaimer + terms)
      await tester.scrollUntilVisible(
        find.byKey(const Key('disclaimer_checkbox')),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('disclaimer_checkbox')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

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

      // Scroll to and accept both checkboxes (disclaimer + terms)
      await tester.scrollUntilVisible(
        find.byKey(const Key('disclaimer_checkbox')),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('disclaimer_checkbox')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

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

      // Scroll to and accept both checkboxes (disclaimer + terms)
      await tester.scrollUntilVisible(
        find.byKey(const Key('disclaimer_checkbox')),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('disclaimer_checkbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pump();

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
