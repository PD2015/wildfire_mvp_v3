import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/features/onboarding/screens/onboarding_screen.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs_impl.dart';

void main() {
  group('Onboarding Flow Integration', () {
    late SharedPreferences prefs;
    late OnboardingPrefsImpl prefsService;

    setUp(() async {
      // Start with fresh preferences (simulates fresh install)
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      prefsService = OnboardingPrefsImpl(prefs);
    });

    /// Creates a test app with GoRouter to support navigation
    Widget createTestApp({
      required OnboardingPrefsImpl prefsService,
      VoidCallback? onComplete,
    }) {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => OnboardingScreen(
              prefsService: prefsService,
              onComplete: onComplete,
            ),
          ),
          // Stub routes for terms and privacy navigation
          GoRoute(
            path: '/settings/about/terms',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Terms Page')),
            ),
          ),
          GoRoute(
            path: '/settings/about/privacy',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Privacy Page')),
            ),
          ),
        ],
      );

      return MaterialApp.router(
        routerConfig: router,
      );
    }

    /// Helper to tap a button by finding it via FilledButton with text.
    /// Scrolls to make the button visible before tapping.
    Future<void> tapFilledButton(WidgetTester tester, String buttonText) async {
      final button = find.widgetWithText(FilledButton, buttonText);
      expect(button, findsOneWidget,
          reason: 'FilledButton "$buttonText" should be visible');

      // Scroll to make the button visible
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    /// Helper to tap a checkbox by key, scrolling if needed.
    /// Taps on the actual Checkbox widget (not the full tile) to avoid hitting embedded links.
    Future<void> tapCheckbox(WidgetTester tester, Key key) async {
      final checkboxTile = find.byKey(key);
      expect(checkboxTile, findsOneWidget,
          reason: 'Checkbox with key $key should be visible');

      // Scroll to make the checkbox visible
      await tester.ensureVisible(checkboxTile);
      await tester.pumpAndSettle();

      // Find the Checkbox widget inside the CheckboxListTile and tap it
      final checkbox = find.descendant(
        of: checkboxTile,
        matching: find.byType(Checkbox),
      );
      expect(checkbox, findsOneWidget,
          reason: 'Checkbox inside tile should be found');
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
    }

    /// Helper to tap the Back button, scrolling if needed.
    Future<void> tapBackButton(WidgetTester tester) async {
      final backButton = find.text('Back');
      expect(backButton, findsOneWidget,
          reason: 'Back button should be visible');

      // Scroll to make the button visible
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();

      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }

    testWidgets('complete onboarding flow - fresh install to home',
        (tester) async {
      // Set a large surface size to accommodate all onboarding content
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var onboardingComplete = false;

      await tester.pumpWidget(
        createTestApp(
          prefsService: prefsService,
          onComplete: () => onboardingComplete = true,
        ),
      );
      await tester.pumpAndSettle();

      // Page 1: Welcome
      expect(find.text('Welcome to WildFire'), findsOneWidget);
      await tapFilledButton(tester, 'Continue');

      // Page 2: Disclaimer
      expect(find.text('Important Safety Information'), findsOneWidget);
      await tapFilledButton(tester, 'I Understand');

      // Page 3: Privacy
      expect(find.text('Your Privacy Matters'), findsOneWidget);
      await tapFilledButton(tester, 'Continue');

      // Page 4: Setup
      expect(find.text('Set Your Preferences'), findsOneWidget);

      // Accept disclaimer checkbox
      await tapCheckbox(tester, const Key('disclaimer_checkbox'));

      // Accept terms checkbox
      await tapCheckbox(tester, const Key('terms_checkbox'));

      // Complete onboarding
      await tapFilledButton(tester, 'Complete Setup');

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
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(prefsService: prefsService),
      );
      await tester.pumpAndSettle();

      // Navigate to setup page
      await tapFilledButton(tester, 'Continue'); // Welcome -> Disclaimer
      await tapFilledButton(tester, 'I Understand'); // Disclaimer -> Privacy
      await tapFilledButton(tester, 'Continue'); // Privacy -> Setup

      // Select 25km radius (different from default 10km)
      final radius25 = find.text('25km');
      expect(radius25, findsOneWidget);
      await tester.ensureVisible(radius25);
      await tester.pumpAndSettle();
      await tester.tap(radius25);
      await tester.pumpAndSettle();

      // Accept disclaimer checkbox
      await tapCheckbox(tester, const Key('disclaimer_checkbox'));

      // Accept terms checkbox
      await tapCheckbox(tester, const Key('terms_checkbox'));

      // Complete onboarding
      await tapFilledButton(tester, 'Complete Setup');

      // Verify 25km radius was saved
      final savedRadius = await prefsService.getNotificationRadiusKm();
      expect(savedRadius, 25);
    });

    testWidgets('page indicator updates correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(prefsService: prefsService),
      );
      await tester.pumpAndSettle();

      // Page 1
      expect(find.bySemanticsLabel('Step 1 of 4: Welcome'), findsOneWidget);

      // Navigate to page 2
      await tapFilledButton(tester, 'Continue');
      expect(find.bySemanticsLabel('Step 2 of 4: Safety information'),
          findsOneWidget);

      // Navigate to page 3
      await tapFilledButton(tester, 'I Understand');
      expect(find.bySemanticsLabel('Step 3 of 4: Privacy'), findsOneWidget);

      // Navigate to page 4
      await tapFilledButton(tester, 'Continue');
      expect(find.bySemanticsLabel('Step 4 of 4: Setup'), findsOneWidget);
    });

    testWidgets('cannot complete without accepting terms', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(prefsService: prefsService),
      );
      await tester.pumpAndSettle();

      // Navigate to setup page
      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');
      await tapFilledButton(tester, 'Continue');

      // Find the Complete Setup button and scroll to it
      final button = find.widgetWithText(FilledButton, 'Complete Setup');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      // Verify button is disabled (onPressed is null)
      final filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('complete button enables after accepting both checkboxes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(prefsService: prefsService),
      );
      await tester.pumpAndSettle();

      // Navigate to setup page
      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');
      await tapFilledButton(tester, 'Continue');

      // Scroll to see Complete Setup button and verify it starts disabled
      var button = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      var filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull);

      // Accept only disclaimer - button should still be disabled
      await tapCheckbox(tester, const Key('disclaimer_checkbox'));

      button = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNull);

      // Accept terms - button should now be enabled
      await tapCheckbox(tester, const Key('terms_checkbox'));

      button = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNotNull);
    });

    testWidgets('back navigation works on all pages', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(prefsService: prefsService),
      );
      await tester.pumpAndSettle();

      // Navigate to page 4
      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');
      await tapFilledButton(tester, 'Continue');
      expect(find.text('Set Your Preferences'), findsOneWidget);

      // Go back to page 3
      await tapBackButton(tester);
      expect(find.text('Your Privacy Matters'), findsOneWidget);

      // Go back to page 2
      await tapBackButton(tester);
      expect(find.text('Important Safety Information'), findsOneWidget);

      // Go back to page 1 (Welcome has no back button)
      await tapBackButton(tester);
      expect(find.text('Welcome to WildFire'), findsOneWidget);
    });
  });
}
