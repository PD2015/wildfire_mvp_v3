import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/features/onboarding/screens/onboarding_screen.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs_impl.dart';

void main() {
  // Helper to tap a button by text, scrolling if needed
  Future<void> tapButton(WidgetTester tester, String text) async {
    final buttonFinder = find.text(text);
    // Try to scroll to the button if it's not visible
    final scrollableFinder = find.byType(Scrollable);
    if (scrollableFinder.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(
          buttonFinder,
          50,
          scrollable: scrollableFinder.first,
        );
      } catch (_) {
        // Button might already be visible
      }
    }
    await tester.pumpAndSettle();
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  // Helper to tap a CheckboxListTile by finding and tapping the Checkbox inside it
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

      // Page 1: Welcome - button says "Continue"
      expect(find.text('Welcome to WildFire'), findsOneWidget);
      await tapButton(tester, 'Continue');

      // Page 2: Disclaimer - button says "I Understand"
      expect(find.text('Important Safety Information'), findsOneWidget);
      await tapButton(tester, 'I Understand');

      // Page 3: Privacy - button says "Continue"
      expect(find.text('Your Privacy Matters'), findsOneWidget);
      await tapButton(tester, 'Continue');

      // Page 4: Setup
      expect(find.text('Set Your Preferences'), findsOneWidget);

      // Accept both checkboxes (disclaimer and terms)
      await tapCheckboxListTile(tester, const Key('disclaimer_checkbox'));
      await tapCheckboxListTile(tester, const Key('terms_checkbox'));

      // Complete onboarding
      await tapButton(tester, 'Complete Setup');

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
      await tapButton(tester, 'Continue'); // Welcome -> Disclaimer
      await tapButton(tester, 'I Understand'); // Disclaimer -> Privacy
      await tapButton(tester, 'Continue'); // Privacy -> Setup

      // Scroll to 25km option and select it
      final scrollableFinder = find.byType(Scrollable);
      if (scrollableFinder.evaluate().isNotEmpty) {
        try {
          await tester.scrollUntilVisible(
            find.text('25km'),
            50,
            scrollable: scrollableFinder.first,
          );
        } catch (_) {
          // Button might already be visible
        }
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('25km'));
      await tester.pumpAndSettle();

      // Accept both checkboxes (disclaimer and terms)
      await tapCheckboxListTile(tester, const Key('disclaimer_checkbox'));
      await tapCheckboxListTile(tester, const Key('terms_checkbox'));

      // Complete onboarding
      await tapButton(tester, 'Complete Setup');

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

      // Page 1 - actual semantics: "Step 1 of 4: Welcome"
      expect(
        find.bySemanticsLabel(RegExp(r'Step 1 of 4')),
        findsOneWidget,
      );

      // Navigate to page 2
      await tapButton(tester, 'Continue');
      expect(
        find.bySemanticsLabel(RegExp(r'Step 2 of 4')),
        findsOneWidget,
      );

      // Navigate to page 3
      await tapButton(tester, 'I Understand');
      expect(
        find.bySemanticsLabel(RegExp(r'Step 3 of 4')),
        findsOneWidget,
      );

      // Navigate to page 4
      await tapButton(tester, 'Continue');
      expect(
        find.bySemanticsLabel(RegExp(r'Step 4 of 4')),
        findsOneWidget,
      );
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
      await tapButton(tester, 'Continue'); // Welcome -> Disclaimer
      await tapButton(tester, 'I Understand'); // Disclaimer -> Privacy
      await tapButton(tester, 'Continue'); // Privacy -> Setup

      // Scroll to Complete button without accepting terms
      final scrollableFinder = find.byType(Scrollable);
      if (scrollableFinder.evaluate().isNotEmpty) {
        try {
          await tester.scrollUntilVisible(
            find.text('Complete Setup'),
            50,
            scrollable: scrollableFinder.first,
          );
        } catch (_) {
          // Button might already be visible
        }
      }
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
      await tapButton(tester, 'Continue'); // Welcome -> Disclaimer
      await tapButton(tester, 'I Understand'); // Disclaimer -> Privacy
      await tapButton(tester, 'Continue'); // Privacy -> Setup

      // Accept both checkboxes (disclaimer and terms)
      await tapCheckboxListTile(tester, const Key('disclaimer_checkbox'));
      await tapCheckboxListTile(tester, const Key('terms_checkbox'));

      // Scroll to Complete button
      final scrollableFinder = find.byType(Scrollable);
      if (scrollableFinder.evaluate().isNotEmpty) {
        try {
          await tester.scrollUntilVisible(
            find.text('Complete Setup'),
            50,
            scrollable: scrollableFinder.first,
          );
        } catch (_) {
          // Button might already be visible
        }
      }
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
