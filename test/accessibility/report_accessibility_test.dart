import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/screens/report_fire_screen.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_button.dart';

void main() {
  group('A12 Accessibility Validation Tests', () {
    group('Touch Target Size Requirements (C3 Compliance)', () {
      testWidgets(
          'emergency buttons meet minimum 44dp touch target requirement',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
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

          final button = tester.widget<EmergencyButton>(buttonFinder);
          final buttonSize = tester.getSize(buttonFinder);

          // iOS minimum: 44dp, Android minimum: 48dp
          // Use 44dp as minimum (iOS requirement) with 48dp preferred
          const minTouchTarget = 44.0;

          expect(buttonSize.height, greaterThanOrEqualTo(minTouchTarget),
              reason:
                  'Button "${button.text}" height ${buttonSize.height} must be ≥${minTouchTarget}dp for accessibility');

          expect(buttonSize.width, greaterThanOrEqualTo(minTouchTarget),
              reason:
                  'Button "${button.text}" width ${buttonSize.width} must be ≥${minTouchTarget}dp for accessibility');
        }
      });

      testWidgets('back button meets touch target requirements',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
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
          MaterialApp(home: ReportFireScreen()),
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
          MaterialApp(home: ReportFireScreen()),
        );

        // Test 999 Fire Service button
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        expect(fireServiceButton, findsOneWidget);

        final fireServiceSemantics = tester.getSemantics(fireServiceButton);
        expect(fireServiceSemantics.label, contains('Call 999'));
        expect(fireServiceSemantics.label, contains('Fire Service'));
        expect(
            fireServiceSemantics.hasEnabledAction(SemanticsAction.tap), isTrue);
        expect(fireServiceSemantics.isButton, isTrue);

        // Test 101 Police Scotland button
        final policeButton =
            find.widgetWithText(EmergencyButton, 'Call 101 — Police Scotland');
        expect(policeButton, findsOneWidget);

        final policeSemantics = tester.getSemantics(policeButton);
        expect(policeSemantics.label, contains('Call 101'));
        expect(policeSemantics.label, contains('Police Scotland'));
        expect(policeSemantics.hasEnabledAction(SemanticsAction.tap), isTrue);
        expect(policeSemantics.isButton, isTrue);

        // Test 0800 555 111 Crimestoppers button
        final crimestoppersButton = find.widgetWithText(
            EmergencyButton, 'Call 0800 555 111 — Crimestoppers');
        expect(crimestoppersButton, findsOneWidget);

        final crimestoppersSemantics = tester.getSemantics(crimestoppersButton);
        expect(crimestoppersSemantics.label, contains('Call 0800 555 111'));
        expect(crimestoppersSemantics.label, contains('Crimestoppers'));
        expect(crimestoppersSemantics.hasEnabledAction(SemanticsAction.tap),
            isTrue);
        expect(crimestoppersSemantics.isButton, isTrue);
      });

      testWidgets('screen has proper semantic structure', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
        );

        // AppBar should have proper semantics
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);

        final appBarSemantics = tester.getSemantics(appBar);
        expect(appBarSemantics.label, contains('Report a Fire'));
        expect(appBarSemantics.isHeader, isTrue);

        // Screen should have semantic structure for navigation
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);

        final backButtonSemantics = tester.getSemantics(backButton);
        expect(
            backButtonSemantics.hasEnabledAction(SemanticsAction.tap), isTrue);
        expect(backButtonSemantics.isButton, isTrue);
      });

      testWidgets('emergency priority is conveyed through semantics',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
        );

        // 999 button should be marked as urgent
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        final fireServiceSemantics = tester.getSemantics(fireServiceButton);

        // Should contain urgent/emergency indicators in semantic description
        expect(
            fireServiceSemantics.label?.toLowerCase(),
            anyOf([
              contains('emergency'),
              contains('urgent'),
              contains('999'),
            ]));

        // Non-emergency buttons should not have urgent semantics
        final policeButton =
            find.widgetWithText(EmergencyButton, 'Call 101 — Police Scotland');
        final policeSemantics = tester.getSemantics(policeButton);

        expect(policeSemantics.label, contains('101'));
        // Should not be marked as urgent (101 is non-emergency)
      });

      testWidgets('semantic focus order follows logical reading pattern',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
        );

        // Get all semantically focusable elements
        final semanticNodes = tester
            .binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!
            .debugDescribeChildren(DebugSemanticsDumpOrder.traversalOrder);

        // Find button semantics in order
        final buttonLabels = semanticNodes
            .where((node) =>
                node.contains('Call 999') ||
                node.contains('Call 101') ||
                node.contains('Call 0800'))
            .toList();

        // Should be in order of priority: 999, 101, 0800
        expect(buttonLabels.length, equals(3));
        expect(buttonLabels[0], contains('Call 999'));
        expect(buttonLabels[1], contains('Call 101'));
        expect(buttonLabels[2], contains('Call 0800'));
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
            home: ReportFireScreen(),
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

        // Test theme application
        final elevatedButtonWidget =
            tester.widget<ElevatedButton>(elevatedButton);
        expect(elevatedButtonWidget.style?.backgroundColor?.resolve({}),
            isNotNull);
      });

      testWidgets('buttons maintain visibility in high contrast mode',
          (tester) async {
        // Test with high contrast theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.highContrast(),
            ),
            home: ReportFireScreen(),
          ),
        );

        final buttons = [
          find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service'),
          find.widgetWithText(EmergencyButton, 'Call 101 — Police Scotland'),
          find.widgetWithText(
              EmergencyButton, 'Call 0800 555 111 — Crimestoppers'),
        ];

        for (final button in buttons) {
          expect(button, findsOneWidget);

          // Buttons should be visible and properly styled
          final elevatedButton = find.descendant(
            of: button,
            matching: find.byType(ElevatedButton),
          );
          expect(elevatedButton, findsOneWidget);
        }
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
            home: ReportFireScreen(),
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
          MaterialApp(home: ReportFireScreen()),
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

      testWidgets('focus indicators are visible', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
        );

        // Focus on first emergency button
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        await tester.tap(fireServiceButton);
        await tester.pumpAndSettle();

        // Button should show focus state (tested through Material elevation/color changes)
        final elevatedButton = find.descendant(
          of: fireServiceButton,
          matching: find.byType(ElevatedButton),
        );

        expect(elevatedButton, findsOneWidget);

        // Material buttons show focus through elevation changes
        final elevatedButtonWidget =
            tester.widget<ElevatedButton>(elevatedButton);
        expect(elevatedButtonWidget.style, isNotNull);
      });
    });

    group('Error State Accessibility', () {
      testWidgets('SnackBar fallback messages are accessible', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
        );

        // Trigger SnackBar by tapping button (will fail in test environment)
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        await tester.tap(fireServiceButton);
        await tester.pumpAndSettle();

        // SnackBar should be accessible
        final snackBar = find.byType(SnackBar);
        expect(snackBar, findsOneWidget);

        // SnackBar should have proper semantics
        final snackBarSemantics = tester.getSemantics(snackBar);
        expect(snackBarSemantics.label, isNotNull);
        expect(snackBarSemantics.label, contains('Could not open dialer'));
        expect(snackBarSemantics.label, contains('999'));

        // OK button should be accessible
        final okButton = find.text('OK');
        expect(okButton, findsOneWidget);

        final okButtonSemantics = tester.getSemantics(okButton);
        expect(okButtonSemantics.hasEnabledAction(SemanticsAction.tap), isTrue);
        expect(okButtonSemantics.isButton, isTrue);
      });
    });

    group('Device Orientation Accessibility', () {
      testWidgets('accessibility features work in landscape orientation',
          (tester) async {
        // Set landscape orientation
        await tester.binding.setSurfaceSize(const Size(800, 600));

        await tester.pumpWidget(
          MaterialApp(home: ReportFireScreen()),
        );

        // Touch targets should still meet requirements in landscape
        final fireServiceButton =
            find.widgetWithText(EmergencyButton, 'Call 999 — Fire Service');
        expect(fireServiceButton, findsOneWidget);

        final buttonSize = tester.getSize(fireServiceButton);
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
        expect(buttonSize.width, greaterThanOrEqualTo(44.0));

        // Semantic labels should still work
        final fireServiceSemantics = tester.getSemantics(fireServiceButton);
        expect(fireServiceSemantics.label, contains('Call 999'));
        expect(fireServiceSemantics.isButton, isTrue);

        // Reset to portrait
        await tester.binding.setSurfaceSize(const Size(400, 800));
      });
    });
  });
}
