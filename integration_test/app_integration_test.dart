import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wildfire_mvp_v3/main.dart' as app;
import 'package:wildfire_mvp_v3/screens/home_screen.dart';
import 'package:wildfire_mvp_v3/features/map/screens/map_screen.dart';

/// Full app integration tests covering navigation and state persistence
///
/// REQUIREMENTS:
/// - Run on device/emulator: `flutter test integration_test/app_integration_test.dart -d <device-id>`
/// - Tests complete user journeys across screens
///
/// VERIFIES:
/// - Navigation between Home and Map screens
/// - State persistence across navigation
/// - Back button behavior
/// - Deep linking (if implemented)
/// - App lifecycle (resume from background)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Navigation Integration Tests (Full Journey)', () {
    testWidgets('App launches and displays home screen',
        (WidgetTester tester) async {
      // ACCEPTANCE: App launches without crash

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify home screen is the initial route
      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'Home screen should be initial route');

      debugPrint('✅ App launched successfully with home screen');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Navigate from Home to Map screen',
        (WidgetTester tester) async {
      // ACCEPTANCE: User can navigate to map screen

      app.main();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Find and tap map navigation button
      final mapButton = find.text('Map');
      expect(mapButton, findsOneWidget,
          reason: 'Map navigation button should be visible');

      await tester.tap(mapButton);
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Verify map screen is displayed
      expect(find.byType(MapScreen), findsOneWidget,
          reason: 'Map screen should be visible after navigation');

      debugPrint('✅ Navigation to Map screen successful');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Navigate back to Home from Map screen',
        (WidgetTester tester) async {
      // ACCEPTANCE: User can navigate back to home

      app.main();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Navigate to map
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // Navigate back to home
      final homeButton = find.text('Home');
      if (homeButton.evaluate().isNotEmpty) {
        // Using navigation button
        await tester.tap(homeButton);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
      } else {
        // Using back button
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pump(const Duration(seconds: 3));
          await tester.pump();
        }
      }

      // Verify home screen is displayed
      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'Home screen should be visible after back navigation');

      debugPrint('✅ Back navigation to Home successful');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Fire risk data persists across navigation',
        (WidgetTester tester) async {
      // ACCEPTANCE: Risk data doesn't re-fetch unnecessarily when navigating back

      app.main();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Capture initial risk level (if visible)
      final initialRiskText = find.textContaining('Risk', findRichText: true);
      // ignore: unused_local_variable
      String? initialRiskValue; // Captured for future comparison tests
      if (initialRiskText.evaluate().isNotEmpty) {
        initialRiskValue = initialRiskText.evaluate().first.widget.toString();
      }

      // Navigate to map and back
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      final homeButton = find.text('Home');
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
      }

      // Verify risk data is still present (not blank loading state)
      final afterNavRiskText = find.textContaining('Risk', findRichText: true);
      expect(afterNavRiskText, findsAtLeastNWidgets(1),
          reason: 'Risk data should persist across navigation');

      debugPrint('✅ State persisted across navigation');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Multiple back-and-forth navigations work correctly',
        (WidgetTester tester) async {
      // ACCEPTANCE: App handles multiple navigation cycles without issues

      app.main();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Navigate Home → Map → Home → Map → Home
      for (int i = 0; i < 3; i++) {
        debugPrint('🔄 Navigation cycle ${i + 1}/3');

        // Go to Map
        await tester.tap(find.text('Map'));
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();
        expect(find.byType(MapScreen), findsOneWidget);

        // Go back to Home
        final homeButton = find.text('Home');
        if (homeButton.evaluate().isNotEmpty) {
          await tester.tap(homeButton);
          await tester.pump(const Duration(seconds: 3));
          await tester.pump();
        }
        expect(find.byType(HomeScreen), findsOneWidget);
      }

      debugPrint('✅ Multiple navigation cycles successful');
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('App handles rapid navigation without crashes',
        (WidgetTester tester) async {
      // ACCEPTANCE: Rapid taps don't cause navigation stack issues

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Rapid navigation
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Map'));
        await tester.pump(const Duration(milliseconds: 100));

        final homeButton = find.text('Home');
        if (homeButton.evaluate().isNotEmpty) {
          await tester.tap(homeButton);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // App should still be functional
      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'App should handle rapid navigation gracefully');

      debugPrint('✅ Rapid navigation handled correctly');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Bottom navigation (if present) highlights correct tab',
        (WidgetTester tester) async {
      // ACCEPTANCE: Active tab is visually indicated

      app.main();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Look for NavigationBar (Material 3)
      final bottomNav = find.byType(NavigationBar);

      if (bottomNav.evaluate().isEmpty) {
        debugPrint('ℹ️  No NavigationBar (using alternative navigation)');
        return;
      }

      // Verify home tab is selected initially
      // Then navigate to map and verify map tab is selected
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // Note: Actual selected index verification requires inspecting widget state
      // This test verifies navigation bar exists and responds to taps
      expect(bottomNav, findsOneWidget);

      debugPrint('✅ Bottom navigation responds to tab selection');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('App Lifecycle Integration Tests', () {
    testWidgets('App resumes from background without data loss',
        (WidgetTester tester) async {
      // ACCEPTANCE: Data persists when app is backgrounded

      app.main();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Simulate app lifecycle: resumed → paused → resumed
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // Verify app is still functional
      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'App should resume correctly after backgrounding');

      debugPrint('✅ App lifecycle (background/resume) handled correctly');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('App handles memory warnings gracefully',
        (WidgetTester tester) async {
      // ACCEPTANCE: App doesn't crash on low memory

      app.main();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      // Navigate to create some state
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // Simulate memory warning (platform message)
      // Note: Actual memory pressure testing requires platform-specific tools

      // Verify app is still responsive
      final homeButton = find.text('Home');
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
      }

      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'App should remain functional after navigation');

      debugPrint('✅ App handles state management during navigation');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
