import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/features/onboarding/screens/onboarding_screen.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs_impl.dart';

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

  group('Onboarding Flow Integration', () {
    late SharedPreferences prefs;
    late OnboardingPrefsImpl prefsService;

    setUp(() async {
      // Start with fresh preferences (simulates fresh install)
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      prefsService = OnboardingPrefsImpl(prefs);
    });

    testWidgets('complete onboarding flow - fresh install to home',
        (tester) async {
      var onboardingComplete = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
            onComplete: () => onboardingComplete = true,
          ),
        ),
      );

      // Page 1: Welcome
      expect(find.text('Welcome to WildFire'), findsOneWidget);
      await scrollAndTap(tester, 'Get Started');

      // Page 2: Disclaimer
      expect(find.text('Important Safety Information'), findsOneWidget);
      await scrollAndTap(tester, 'I Understand');

      // Page 3: Privacy
      expect(find.text('Your Privacy Matters'), findsOneWidget);
      await scrollAndTap(tester, 'Continue');

      // Page 4: Setup
      expect(find.text('Set Your Preferences'), findsOneWidget);

      // Accept terms (checkbox)
      await tester.scrollUntilVisible(
        find.byType(Checkbox),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Complete onboarding
      await scrollAndTap(tester, 'Complete Setup');

      // Verify onComplete was called
      expect(onboardingComplete, isTrue);

      // Verify consent was saved
      final consent = await prefsService.getConsentRecord();
      expect(consent, isNotNull);
      expect(consent!.termsVersion, OnboardingConfig.currentTermsVersion);

      // Verify onboarding no longer required
      final isRequired = await prefsService.isOnboardingRequired();
      expect(isRequired, isFalse);
    });

    testWidgets('persistence - completed onboarding is remembered',
        (tester) async {
      // Pre-populate with completed onboarding state
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion:
            OnboardingConfig.currentOnboardingVersion,
        OnboardingConfig.keyTermsVersion: OnboardingConfig.currentTermsVersion,
        OnboardingConfig.keyTermsTimestamp:
            DateTime.now().millisecondsSinceEpoch,
        OnboardingConfig.keyNotificationRadius:
            OnboardingConfig.defaultRadiusKm,
      });
      final existingPrefs = await SharedPreferences.getInstance();
      final existingService = OnboardingPrefsImpl(existingPrefs);

      // Verify onboarding is not required
      final isRequired = await existingService.isOnboardingRequired();
      expect(isRequired, isFalse);

      // Verify consent record exists
      final consent = await existingService.getConsentRecord();
      expect(consent, isNotNull);
      expect(consent!.termsVersion, OnboardingConfig.currentTermsVersion);
    });

    testWidgets('radius selection is saved correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Navigate to setup page
      await scrollAndTap(tester, 'Get Started');
      await scrollAndTap(tester, 'I Understand');
      await scrollAndTap(tester, 'Continue');

      // Select 25km radius (different from default 10km)
      await tester.tap(find.text('25km'));
      await tester.pumpAndSettle();

      // Accept terms
      await tester.scrollUntilVisible(
        find.byType(Checkbox),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Complete onboarding
      await scrollAndTap(tester, 'Complete Setup');

      // Verify 25km radius was saved
      final savedRadius = await prefsService.getNotificationRadiusKm();
      expect(savedRadius, 25);
    });

    testWidgets('page indicator updates correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Page 1
      expect(find.bySemanticsLabel('Page 1 of 4'), findsOneWidget);

      // Navigate to page 2
      await scrollAndTap(tester, 'Get Started');
      expect(find.bySemanticsLabel('Page 2 of 4'), findsOneWidget);

      // Navigate to page 3
      await scrollAndTap(tester, 'I Understand');
      expect(find.bySemanticsLabel('Page 3 of 4'), findsOneWidget);

      // Navigate to page 4
      await scrollAndTap(tester, 'Continue');
      expect(find.bySemanticsLabel('Page 4 of 4'), findsOneWidget);
    });

    testWidgets('cannot complete without accepting terms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Navigate to setup page
      await scrollAndTap(tester, 'Get Started');
      await scrollAndTap(tester, 'I Understand');
      await scrollAndTap(tester, 'Continue');

      // Scroll to Complete button without accepting terms
      await tester.scrollUntilVisible(
        find.text('Complete Setup'),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find the Complete Setup button
      final button = find.widgetWithText(FilledButton, 'Complete Setup');
      expect(button, findsOneWidget);

      // Verify button is disabled
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('complete button enables after accepting terms',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            prefsService: prefsService,
          ),
        ),
      );

      // Navigate to setup page
      await scrollAndTap(tester, 'Get Started');
      await scrollAndTap(tester, 'I Understand');
      await scrollAndTap(tester, 'Continue');

      // Accept terms
      await tester.scrollUntilVisible(
        find.byType(Checkbox),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Scroll to Complete button
      await tester.scrollUntilVisible(
        find.text('Complete Setup'),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find the Complete Setup button
      final button = find.widgetWithText(FilledButton, 'Complete Setup');
      expect(button, findsOneWidget);

      // Verify button is enabled
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNotNull);
    });
  });
}
