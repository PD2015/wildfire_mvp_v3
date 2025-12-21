import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  /// Creates a test app with GoRouter wrapper (needed for context.push() calls)
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
        // Stub routes for terms/privacy navigation (hit by links in terms checkbox)
        GoRoute(
          path: '/settings/about/terms',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Terms Screen')),
          ),
        ),
        GoRoute(
          path: '/settings/about/privacy',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Privacy Screen')),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  /// Helper to tap a FilledButton with ensureVisible
  Future<void> tapFilledButton(WidgetTester tester, String text) async {
    final buttonFinder = find.text(text);
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  /// Helper to tap a checkbox by key (taps the actual Checkbox widget to avoid hitting embedded links)
  Future<void> tapCheckbox(WidgetTester tester, Key key) async {
    final checkboxListTileFinder = find.byKey(key);
    await tester.ensureVisible(checkboxListTileFinder);
    await tester.pumpAndSettle();
    // Find the actual Checkbox inside the CheckboxListTile to avoid hitting links
    final checkboxFinder = find.descendant(
      of: checkboxListTileFinder,
      matching: find.byType(Checkbox),
    );
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen', () {
    testWidgets('displays page indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      expect(find.byType(PageIndicator), findsOneWidget);
    });

    testWidgets('starts on welcome page', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to WildFire'), findsOneWidget);
    });

    testWidgets('navigates to disclaimer page on continue', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      await tapFilledButton(tester, 'Continue');

      expect(find.text('Important Safety Information'), findsOneWidget);
    });

    testWidgets('navigates to privacy page from disclaimer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');

      expect(find.text('Your Privacy Matters'), findsOneWidget);
    });

    testWidgets('navigates to setup page from privacy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');
      await tapFilledButton(tester, 'Continue');

      expect(find.text('Set Your Preferences'), findsOneWidget);
    });

    testWidgets('page indicator updates as pages change', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      // Verify initial page indicator (Step 1 of 4: Welcome)
      expect(
        find.bySemanticsLabel(RegExp(r'Step 1 of 4')),
        findsOneWidget,
      );

      // Navigate to next page
      await tapFilledButton(tester, 'Continue');

      // Verify page indicator updated (Step 2 of 4: Safety)
      expect(
        find.bySemanticsLabel(RegExp(r'Step 2 of 4')),
        findsOneWidget,
      );
    });

    testWidgets('calls onComplete after completing onboarding', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var completed = false;

      await tester.pumpWidget(createTestApp(
        prefsService: prefsService,
        onComplete: () => completed = true,
      ));
      await tester.pumpAndSettle();

      // Navigate through all pages
      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');
      await tapFilledButton(tester, 'Continue');

      // Accept both checkboxes
      await tapCheckbox(tester, const Key('disclaimer_checkbox'));
      await tapCheckbox(tester, const Key('terms_checkbox'));

      // Complete
      await tapFilledButton(tester, 'Complete Setup');

      expect(completed, isTrue);
    });

    testWidgets('saves consent when completing onboarding', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      // Navigate through all pages
      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');
      await tapFilledButton(tester, 'Continue');

      // Accept both checkboxes
      await tapCheckbox(tester, const Key('disclaimer_checkbox'));
      await tapCheckbox(tester, const Key('terms_checkbox'));

      // Complete
      await tapFilledButton(tester, 'Complete Setup');

      // Verify consent was recorded
      final consent = await prefsService.getConsentRecord();
      expect(consent, isNotNull);
      expect(consent!.termsVersion, OnboardingConfig.currentTermsVersion);
    });

    testWidgets('saves default notification radius when completing onboarding',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      // Navigate through all pages
      await tapFilledButton(tester, 'Continue');
      await tapFilledButton(tester, 'I Understand');
      await tapFilledButton(tester, 'Continue');

      // Accept both checkboxes
      await tapCheckbox(tester, const Key('disclaimer_checkbox'));
      await tapCheckbox(tester, const Key('terms_checkbox'));

      // Complete
      await tapFilledButton(tester, 'Complete Setup');

      // Verify default radius was saved
      final radius = await prefsService.getNotificationRadiusKm();
      expect(radius, OnboardingConfig.defaultRadiusKm);
    });

    testWidgets('uses PageView for page navigation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('disables swipe navigation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefsService: prefsService));
      await tester.pumpAndSettle();

      // Try to swipe left
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Should still be on welcome page (swipe disabled)
      expect(find.text('Welcome to WildFire'), findsOneWidget);
    });
  });
}
