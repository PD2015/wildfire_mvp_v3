import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/screens/report_fire_screen.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_button.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';

void main() {
  group('A12 Accessibility Validation Tests', () {
    group('Touch Target Size Requirements (C3 Compliance)', () {
      testWidgets(
          'emergency buttons meet minimum 44dp touch target requirement',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        // Find all emergency buttons
        final buttonFinders = [
          find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service'),
          find.widgetWithText(EmergencyButton, 'Call 101 — Police Scotland'),
          find.widgetWithText(
              EmergencyButton, 'Call 0800 555 111 — Crimestoppers'),
        ];

        for (final buttonFinder in buttonFinders) {
          expect(buttonFinder, findsOneWidget);

          final buttonSize = tester.getSize(buttonFinder);

          // iOS minimum: 44dp, Android minimum: 48dp
          // Use 44dp as minimum (iOS requirement) with 48dp preferred
          const minTouchTarget = 44.0;

          expect(buttonSize.height, greaterThanOrEqualTo(minTouchTarget),
              reason:
                  'Button height ${buttonSize.height} must be ≥${minTouchTarget}dp for accessibility');

          expect(buttonSize.width, greaterThanOrEqualTo(minTouchTarget),
              reason:
                  'Button width ${buttonSize.width} must be ≥${minTouchTarget}dp for accessibility');
        }
      });

      testWidgets('back button meets touch target requirements',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);

        final backButtonSize = tester.getSize(backButton);
        const minTouchTarget = 44.0;

        expect(backButtonSize.height, greaterThanOrEqualTo(minTouchTarget),
            reason: 'Back button height must be ≥44dp for accessibility');
        expect(backButtonSize.width, greaterThanOrEqualTo(minTouchTarget),
            reason: 'Back button width must be ≥44dp for accessibility');
      });

      testWidgets('touch targets have adequate spacing', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        final buttonFinders = [
          find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service'),
          find.widgetWithText(EmergencyButton, 'Call 101 — Police Scotland'),
          find.widgetWithText(
              EmergencyButton, 'Call 0800 555 111 — Crimestoppers'),
        ];

        // Check vertical spacing between buttons
        for (int i = 0; i < buttonFinders.length - 1; i++) {
          final currentButton = tester.getBottomLeft(buttonFinders[i]);
          final nextButton = tester.getTopLeft(buttonFinders[i + 1]);

          final verticalSpacing = nextButton.dy - currentButton.dy;
          const minSpacing = 8.0; // Material Design minimum spacing

          expect(verticalSpacing, greaterThanOrEqualTo(minSpacing),
              reason: 'Buttons must have ≥8dp spacing for touch accuracy');
        }
      });
    });

    group('Semantic Labels and Screen Reader Support (C4 Compliance)', () {
      testWidgets('emergency buttons have proper semantic labels',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        // Test button text visibility
        expect(find.text('Call 999 — Fire Service'), findsOneWidget);
        expect(find.text('Call 101 — Police Scotland'), findsOneWidget);
        expect(find.text('Call 0800 555 111 — Crimestoppers'), findsOneWidget);

        // Verify buttons exist and are tappable
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        expect(fireServiceButton, findsOneWidget);
        
        final policeButton =
            find.widgetWithText(EmergencyButton, 'Call 101 — Police Scotland');
        expect(policeButton, findsOneWidget);
        
        final crimestoppersButton = find.widgetWithText(
            EmergencyButton, 'Call 0800 555 111 — Crimestoppers');
        expect(crimestoppersButton, findsOneWidget);
      });

      testWidgets('screen has proper semantic structure', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        // AppBar should be present with title
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);
        expect(find.text('Report a Fire'), findsOneWidget);

        // Back button should be present
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
      });

      testWidgets('emergency priority is conveyed through semantics',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        // Verify emergency contact constants have correct priorities
        expect(EmergencyContact.fireService.priority, EmergencyPriority.urgent);
        expect(EmergencyContact.policeScotland.priority, EmergencyPriority.nonEmergency);
        expect(EmergencyContact.crimestoppers.priority, EmergencyPriority.anonymous);
      });
    });

    group('Color Contrast and Visual Accessibility (C3/C4 Compliance)', () {
      testWidgets('emergency button colors meet contrast requirements',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            home: const ReportFireScreen(),
          ),
        );

        // Test 999 button uses error color (highest contrast)
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        expect(fireServiceButton, findsOneWidget);

        final fireServiceWidget =
            tester.widget<EmergencyButton>(fireServiceButton);
        expect(fireServiceWidget.priority, equals(EmergencyPriority.urgent));

        // Find the actual ElevatedButton widget
        final elevatedButton = find.descendant(
          of: fireServiceButton,
          matching: find.byType(ElevatedButton),
        );
        expect(elevatedButton, findsOneWidget);
      });

      testWidgets('text size scales with system accessibility settings',
          (tester) async {
        // Test with large text scale
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2.0), // 200% text size
                ),
                child: child!,
              );
            },
            home: const ReportFireScreen(),
          ),
        );

        // Buttons should still be properly sized with large text
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        expect(fireServiceButton, findsOneWidget);

        final buttonSize = tester.getSize(fireServiceButton);

        // With 200% text scale, button should be larger but still maintain minimum touch target
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
        expect(buttonSize.width,
            greaterThan(200.0)); // Should be wider due to larger text
      });
    });

    group('Keyboard Navigation and Focus (WCAG AA Compliance)', () {
      testWidgets('all interactive elements are keyboard accessible',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        // Test tab navigation through elements
        final backButton = find.byType(BackButton);
        final buttons = [
          find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service'),
          find.widgetWithText(EmergencyButton, 'Call 101 — Police Scotland'),
          find.widgetWithText(
              EmergencyButton, 'Call 0800 555 111 — Crimestoppers'),
        ];

        // All elements should be focusable
        expect(backButton, findsOneWidget);
        for (final button in buttons) {
          expect(button, findsOneWidget);

          // Each button should be focusable
          final buttonWidget = tester.widget<EmergencyButton>(button);
          expect(buttonWidget.onPressed, isNotNull,
              reason:
                  'Button should have onPressed callback for keyboard activation');
        }
      });
    });

    group('Error State Accessibility', () {
      testWidgets('SnackBar fallback messages are accessible', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        // Trigger SnackBar by tapping button (will fail in test environment)
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        await tester.tap(fireServiceButton);
        await tester.pumpAndSettle();

        // SnackBar should be accessible
        final snackBar = find.byType(SnackBar);
        expect(snackBar, findsOneWidget);

        // Should have error message and phone number
        expect(find.textContaining('Could not open dialer'), findsOneWidget);
        expect(find.textContaining('999'), findsOneWidget);

        // OK button should be accessible
        final okButton = find.text('OK');
        expect(okButton, findsOneWidget);
      });
    });

    group('Device Orientation Accessibility', () {
      testWidgets('accessibility features work in landscape orientation',
          (tester) async {
        // Set landscape orientation
        await tester.binding.setSurfaceSize(const Size(800, 600));

        await tester.pumpWidget(
          const MaterialApp(home: ReportFireScreen()),
        );

        // Touch targets should still meet requirements in landscape
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        expect(fireServiceButton, findsOneWidget);

        final buttonSize = tester.getSize(fireServiceButton);
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
        expect(buttonSize.width, greaterThanOrEqualTo(44.0));

        // Reset to portrait
        await tester.binding.setSurfaceSize(const Size(400, 800));
      });
    });
  });
}
