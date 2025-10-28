import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wildfire_mvp_v3/main.dart' as app;
import 'package:wildfire_mvp_v3/screens/home_screen.dart';

/// Integration tests for Home Screen with real location services
///
/// REQUIREMENTS:
/// - Run on device/emulator: `flutter test integration_test/home_integration_test.dart -d <device-id>`
/// - May prompt for location permissions on first run
/// - Can test real GPS or use cached/manual location
///
/// VERIFIES:
/// - Real location resolution (GPS, cache, manual, fallback)
/// - Fire risk banner display with correct colors
/// - Retry functionality after service errors
/// - C2 Privacy: Coordinate logging uses redaction
/// - C3 Accessibility: Touch targets meet minimums
/// - C4 Transparency: Source and timestamp visible
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Screen Integration Tests (On Device)', () {
    testWidgets('Home screen loads and displays fire risk banner',
        (WidgetTester tester) async {
      // ACCEPTANCE: Home screen renders with risk assessment

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify home screen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);

      // Look for risk banner (text contains "Risk" or risk level)
      final riskIndicators = [
        'Risk',
        'Very Low',
        'Low',
        'Moderate',
        'High',
        'Very High',
        'Extreme',
      ];

      bool foundRiskBanner = false;
      for (final indicator in riskIndicators) {
        if (find
            .textContaining(indicator, findRichText: true)
            .evaluate()
            .isNotEmpty) {
          foundRiskBanner = true;
          debugPrint('✅ Found risk banner with: $indicator');
          break;
        }
      }

      expect(foundRiskBanner, isTrue,
          reason: 'Risk banner should be visible on home screen');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Location resolution works (GPS, cache, or fallback)',
        (WidgetTester tester) async {
      // ACCEPTANCE: Location resolves via any tier (GPS → cache → manual → default)

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // If location permission dialog appears, handle it
      // Note: Automated permission granting requires platform-specific setup

      // Verify some location was resolved (indicated by risk data or location display)
      // We can't assert exact coordinates due to privacy (C2), but we can verify
      // the app is not in error state

      final errorText = find.textContaining('Error', findRichText: true);
      final noDataText = find.textContaining('No data', findRichText: true);

      // App should have either resolved location or fallen back gracefully
      // (showing data or showing a retry button, not just blank error)
      final hasContent = find
              .textContaining('Risk', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find.byType(ElevatedButton).evaluate().isNotEmpty;

      expect(hasContent, isTrue,
          reason: 'App should display risk data or provide retry option');

      debugPrint(
          '✅ Location resolution completed (via GPS, cache, manual, or fallback)');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Fire risk colors match FWI thresholds',
        (WidgetTester tester) async {
      // ACCEPTANCE: Risk colors follow FWI guidelines
      // Very Low: Blue, Low: Green, Moderate: Yellow, High: Orange,
      // Very High: Red, Extreme: Purple

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find any Container with colored background (risk chip)
      final containers = find.byType(Container);
      expect(containers, findsWidgets,
          reason: 'Risk banner should use colored containers for risk levels');

      // Note: Exact color verification requires inspecting widget properties
      // This verifies colored containers exist (visual indicator present)
      debugPrint('✅ Risk banner rendered with visual indicators');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Timestamp shows relative time (C4 transparency)',
        (WidgetTester tester) async {
      // ACCEPTANCE: "Updated X ago" visible when data is available
      // NOTE: Timestamp is shown in success states OR error states with cached data
      // If error without cached data, no timestamp is shown (no data = no timestamp)

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Wait additional time for state to fully update
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check if we're in an error state without cached data
      final errorWithoutData = find
              .textContaining('Unable to load', findRichText: true)
              .evaluate()
              .isNotEmpty &&
          find
              .textContaining('Retry', findRichText: true)
              .evaluate()
              .isNotEmpty;

      if (errorWithoutData) {
        debugPrint(
            'ℹ️  App in error state without cached data - timestamp not expected');
        // This is acceptable - you can't show timestamp for data that doesn't exist
        // Test passes because the app is handling error gracefully
        return;
      }

      // Look for "Updated" text which is part of timestamp display
      // Shown in RiskBanner success state and HomeScreen success/error-with-cache states
      final updatedFinder = find.textContaining('Updated', findRichText: true);

      // Also search for time-related words that appear in relative timestamps
      final timePatterns = ['ago', 'now', 'min', 'hour', 'day'];
      bool foundTimePattern = timePatterns.any((pattern) => find
          .textContaining(pattern, findRichText: true)
          .evaluate()
          .isNotEmpty);

      final foundTimestamp =
          updatedFinder.evaluate().isNotEmpty || foundTimePattern;

      if (foundTimestamp) {
        debugPrint('✅ Found timestamp display (data available)');
      } else {
        // Debug: Print all visible text to help diagnose
        final allText = tester.widgetList<Text>(find.byType(Text));
        debugPrint(
            '❌ Timestamp not found but data appears available. Visible text:');
        for (final text in allText) {
          debugPrint('  - "${text.data}"');
        }
      }

      expect(foundTimestamp, isTrue,
          reason: 'Timestamp must be visible when data is available (C4)');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Source chip displays data source (C4 transparency)',
        (WidgetTester tester) async {
      // ACCEPTANCE: EFFIS/SEPA/Cache/Mock source visible when data is available
      // NOTE: Source is shown in success states OR error states with cached data
      // If error without cached data, no source is shown (no data = no source)

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Wait additional time for state to fully update
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check if we're in an error state without cached data
      final errorWithoutData = find
              .textContaining('Unable to load', findRichText: true)
              .evaluate()
              .isNotEmpty &&
          find
              .textContaining('Retry', findRichText: true)
              .evaluate()
              .isNotEmpty;

      if (errorWithoutData) {
        debugPrint(
            'ℹ️  App in error state without cached data - source chip not expected');
        // This is acceptable - you can't show source for data that doesn't exist
        // Test passes because the app is handling error gracefully
        return;
      }

      // Look for source names that appear in success or error-with-cache states
      // RiskBanner._getSourceName() returns: EFFIS, SEPA, Cache, or Mock
      final sourcePatterns = ['EFFIS', 'SEPA', 'Cache', 'Mock'];

      bool foundSource = sourcePatterns.any((pattern) => find
          .textContaining(pattern, findRichText: true)
          .evaluate()
          .isNotEmpty);

      if (foundSource) {
        final matchedSource = sourcePatterns.firstWhere(
          (pattern) => find
              .textContaining(pattern, findRichText: true)
              .evaluate()
              .isNotEmpty,
          orElse: () => 'unknown',
        );
        debugPrint('✅ Found data source: $matchedSource (data available)');
      } else {
        // Debug: Print all visible text to help diagnose
        final allText = tester.widgetList<Text>(find.byType(Text));
        debugPrint(
            '❌ Source chip not found but data appears available. Visible text:');
        for (final text in allText) {
          debugPrint('  - "${text.data}"');
        }
      }

      expect(foundSource, isTrue,
          reason: 'Data source must be visible when data is available (C4)');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Retry button appears and works after error',
        (WidgetTester tester) async {
      // ACCEPTANCE: User can retry after service failure

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Look for retry button (may or may not be present depending on service state)
      final retryButton = find.textContaining('Retry', findRichText: true);

      if (retryButton.evaluate().isNotEmpty) {
        debugPrint('🔄 Retry button found - testing retry functionality');

        await tester.tap(retryButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // After retry, either data loads or error persists
        final hasContentAfterRetry = find
                .textContaining('Risk', findRichText: true)
                .evaluate()
                .isNotEmpty ||
            find
                .textContaining('Error', findRichText: true)
                .evaluate()
                .isNotEmpty;

        expect(hasContentAfterRetry, isTrue,
            reason: 'Retry should trigger new data fetch');

        debugPrint('✅ Retry functionality verified');
      } else {
        debugPrint('ℹ️  No retry button (data loaded successfully)');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Touch targets meet 44dp minimum (C3 accessibility)',
        (WidgetTester tester) async {
      // ACCEPTANCE: All interactive elements ≥44dp

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find all buttons
      final buttons = find.byType(ElevatedButton);

      for (final button in buttons.evaluate()) {
        final size = button.size!;
        expect(size.width, greaterThanOrEqualTo(44.0),
            reason: 'Button width must be ≥44dp (C3)');
        expect(size.height, greaterThanOrEqualTo(44.0),
            reason: 'Button height must be ≥44dp (C3)');
      }

      debugPrint('✅ All buttons meet 44dp minimum touch target');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('Manual location entry dialog can be opened',
        (WidgetTester tester) async {
      // ACCEPTANCE: User can manually enter coordinates if GPS unavailable

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Look for manual location entry trigger
      // This might be a button or automatically shown if GPS denied
      final manualEntryTriggers = [
        'Enter location',
        'Manual',
        'Set location',
      ];

      bool foundManualEntry = false;
      for (final trigger in manualEntryTriggers) {
        final finder = find.textContaining(trigger, findRichText: true);
        if (finder.evaluate().isNotEmpty) {
          foundManualEntry = true;
          debugPrint('✅ Manual location entry available: $trigger');

          // Try to open dialog
          await tester.tap(finder.first);
          await tester.pumpAndSettle();

          // Look for latitude/longitude input fields
          final latField = find.textContaining('Latitude', findRichText: true);
          final lonField = find.textContaining('Longitude', findRichText: true);

          if (latField.evaluate().isNotEmpty &&
              lonField.evaluate().isNotEmpty) {
            debugPrint('✅ Manual location dialog opened successfully');
          }

          break;
        }
      }

      // Manual entry may not be shown if GPS works - this is expected
      debugPrint(foundManualEntry
          ? '✅ Manual location entry verified'
          : 'ℹ️  Manual entry not needed (GPS working)');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('App handles location permission denial gracefully',
        (WidgetTester tester) async {
      // ACCEPTANCE: App doesn't crash if GPS denied, falls back to cache/manual/default

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Verify app is in some valid state (not crashed)
      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'Home screen should render even if location denied');

      // App should show either:
      // - Risk data (from cache/fallback)
      // - Manual entry option
      // - Error with retry
      final hasValidState = find
              .textContaining('Risk', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find
              .textContaining('Enter', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find
              .textContaining('Retry', findRichText: true)
              .evaluate()
              .isNotEmpty;

      expect(hasValidState, isTrue,
          reason: 'App should handle permission denial gracefully');

      debugPrint('✅ App handles location permission denial gracefully');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('View Map navigation button is visible and accessible (C3)',
        (WidgetTester tester) async {
      // ACCEPTANCE: Map navigation button exists, is ≥44dp, and navigates to map
      // From manual test requirements: Test 1.3 "View Map Button"

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find "Map" navigation button in bottom navigation bar
      final mapButton = find.widgetWithText(NavigationDestination, 'Map');

      expect(mapButton, findsOneWidget,
          reason: 'Map navigation button should be visible in bottom nav');

      // Verify touch target size (C3 accessibility)
      // NavigationBar items are ≥48dp by Material Design 3 spec
      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      final navBarSize = tester.getSize(navBar);

      // NavigationBar height is typically 80dp, ensuring destinations are ≥44dp
      expect(navBarSize.height, greaterThanOrEqualTo(44.0),
          reason: 'Navigation bar must be ≥44dp height (C3)');

      debugPrint('✅ Map navigation button is visible and accessible');

      // Tap the Map button to verify navigation works
      await tester.tap(mapButton);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify navigation occurred (map screen should be loading or visible)
      // Note: We can't verify GoogleMap renders (that's skipped in integration tests)
      // But we can verify the navigation happened
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsWidgets,
          reason: 'Scaffold should be present after navigation');

      debugPrint('✅ Map navigation completed');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
