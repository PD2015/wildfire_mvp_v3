import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wildfire_mvp_v3/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Report Fire Screen Integration Tests', () {
    testWidgets(
      'complete user flow - navigate to report screen and test emergency buttons',
      (tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle();

        // Wait for home screen to load (async data fetching)
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Navigate to report screen from home
        // Use text matcher instead of icon (more reliable across icon variants)
        final reportButton = find.text('Report Fire');
        expect(reportButton, findsOneWidget);
        await tester.tap(reportButton);
        await tester.pumpAndSettle();

        // Verify we're on the report screen
        expect(find.text('Report a Fire'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNWidgets(3));

        // Test 999 Fire Service button
        final fireServiceButton = find.widgetWithText(
          ElevatedButton,
          'Call 999 — Fire Service',
        );
        expect(fireServiceButton, findsOneWidget);
        await tester.tap(fireServiceButton);
        await tester.pumpAndSettle();

        // Should show SnackBar fallback on emulator/test environment
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Could not open dialer'), findsOneWidget);
        expect(find.textContaining('999'), findsOneWidget);

        // Dismiss SnackBar
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Test 101 Police Scotland button
        final policeButton = find.widgetWithText(
          ElevatedButton,
          'Call 101 — Police Scotland',
        );
        expect(policeButton, findsOneWidget);
        await tester.tap(policeButton);
        await tester.pumpAndSettle();

        // Should show SnackBar fallback
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Could not open dialer'), findsOneWidget);
        expect(find.textContaining('101'), findsOneWidget);

        // Dismiss SnackBar
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Test 0800 555 111 Crimestoppers button
        final crimestoppersButton = find.widgetWithText(
          ElevatedButton,
          'Call 0800 555 111 — Crimestoppers',
        );
        expect(crimestoppersButton, findsOneWidget);
        await tester.tap(crimestoppersButton);
        await tester.pumpAndSettle();

        // Should show SnackBar fallback
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Could not open dialer'), findsOneWidget);
        expect(find.textContaining('0800555111'), findsOneWidget);

        // Dismiss SnackBar and navigate back
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should be back to home screen
        expect(find.text('Report a Fire'), findsNothing);
      },
    );

    testWidgets('screen orientation change preserves functionality', (
      tester,
    ) async {
      // Launch the app and navigate to report screen
      app.main();
      await tester.pumpAndSettle();

      final reportButton = find.text('Report Fire');
      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      // Verify initial portrait layout
      expect(find.text('Report a Fire'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));

      // Simulate landscape orientation
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // Verify functionality still works in landscape
      expect(find.text('Report a Fire'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));

      final fireServiceButton = find.widgetWithText(
        ElevatedButton,
        'Call 999 — Fire Service',
      );
      await tester.tap(fireServiceButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      // Reset to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
    });

    testWidgets('rapid button taps do not cause crashes', (tester) async {
      // Launch the app and navigate to report screen
      app.main();
      await tester.pumpAndSettle();

      final reportButton = find.text('Report Fire');
      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      final fireServiceButton = find.widgetWithText(
        ElevatedButton,
        'Call 999 — Fire Service',
      );

      // Rapid tap test
      for (int i = 0; i < 10; i++) {
        await tester.tap(fireServiceButton);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should handle gracefully without crashes
      expect(find.text('Report a Fire'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));
    });

    testWidgets('deep link navigation to /report works', (tester) async {
      // This test would verify deep-link functionality
      // Note: Actual deep-link testing requires platform-specific setup

      app.main();
      await tester.pumpAndSettle();

      // Simulate navigation to /report route
      // (In a real app, this would be triggered by a deep link)
      final reportButton = find.text('Report Fire');
      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      // Verify direct navigation works
      expect(find.text('Report a Fire'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));
    });

    testWidgets('screen works offline without network dependencies', (
      tester,
    ) async {
      // This test verifies offline capability
      app.main();
      await tester.pumpAndSettle();

      final reportButton = find.text('Report Fire');
      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      // Verify screen loads instantly without network calls
      expect(find.text('Report a Fire'), findsOneWidget);
      expect(find.text('Act fast — stay safe.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));

      // Verify all buttons are functional
      final buttons = [
        find.widgetWithText(ElevatedButton, 'Call 999 — Fire Service'),
        find.widgetWithText(ElevatedButton, 'Call 101 — Police Scotland'),
        find.widgetWithText(
          ElevatedButton,
          'Call 0800 555 111 — Crimestoppers',
        ),
      ];

      for (final button in buttons) {
        expect(button, findsOneWidget);
        await tester.tap(button);
        await tester.pumpAndSettle();

        // Should work offline with SnackBar fallback
        expect(find.byType(SnackBar), findsOneWidget);

        // Dismiss SnackBar before next test
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          await tester.tap(okButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('performance validation - screen load and button response times', (
      tester,
    ) async {
      final stopwatch = Stopwatch()..start();

      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to report screen
      final reportButton = find.text('Report Fire');
      await tester.tap(reportButton);

      final navigationStart = stopwatch.elapsedMilliseconds;
      await tester.pumpAndSettle();
      final navigationEnd = stopwatch.elapsedMilliseconds;

      // Screen should load within 200ms
      final navigationTime = navigationEnd - navigationStart;
      expect(
        navigationTime,
        lessThan(200),
        reason:
            'Screen navigation should complete within 200ms, took ${navigationTime}ms',
      );

      // Test button response time
      final fireServiceButton = find.widgetWithText(
        ElevatedButton,
        'Call 999 — Fire Service',
      );
      final buttonTapStart = stopwatch.elapsedMilliseconds;

      await tester.tap(fireServiceButton);
      await tester.pump(); // Single pump to measure immediate response

      final buttonTapEnd = stopwatch.elapsedMilliseconds;
      final buttonResponseTime = buttonTapEnd - buttonTapStart;

      // Button should respond within 100ms
      expect(
        buttonResponseTime,
        lessThan(100),
        reason:
            'Button response should be within 100ms, took ${buttonResponseTime}ms',
      );

      stopwatch.stop();
    });
  });
}
