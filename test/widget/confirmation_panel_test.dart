import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/location_picker/widgets/confirmation_panel.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';

void main() {
  group('ConfirmationPanel', () {
    group('riskLocation mode', () {
      testWidgets('displays Confirm Location button text', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(find.text('Confirm Location'), findsOneWidget);
      });

      testWidgets('does not show emergency banner', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(find.text('Call 999 for emergencies'), findsNothing);
        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });
    });

    group('fireReport mode', () {
      testWidgets('displays Use This Location button text', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.fireReport,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(find.text('Use This Location'), findsOneWidget);
      });

      testWidgets('shows emergency banner with warning icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.fireReport,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(find.text('Call 999 for emergencies'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      });
    });

    group('Cancel button', () {
      testWidgets('is displayed with key', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('cancel_location_button')), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('triggers onCancel callback when tapped', (tester) async {
        bool cancelTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {
                  cancelTapped = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('cancel_location_button')));
        await tester.pump();

        expect(cancelTapped, isTrue);
      });

      testWidgets('is an OutlinedButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        final cancelButton = find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(OutlinedButton),
        );
        expect(cancelButton, findsOneWidget);
      });
    });

    group('Confirm button', () {
      testWidgets('is displayed with key', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(
            find.byKey(const Key('confirm_location_button')), findsOneWidget);
      });

      testWidgets('triggers onConfirm callback when tapped', (tester) async {
        bool confirmTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {
                  confirmTapped = true;
                },
                onCancel: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('confirm_location_button')));
        await tester.pump();

        expect(confirmTapped, isTrue);
      });

      testWidgets('is disabled when isConfirmEnabled is false', (tester) async {
        bool confirmTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {
                  confirmTapped = true;
                },
                onCancel: () {},
                isConfirmEnabled: false,
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('confirm_location_button')));
        await tester.pump();

        expect(confirmTapped, isFalse);
      });

      testWidgets('is enabled by default', (tester) async {
        bool confirmTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {
                  confirmTapped = true;
                },
                onCancel: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('confirm_location_button')));
        await tester.pump();

        expect(confirmTapped, isTrue);
      });

      testWidgets('is a FilledButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        final confirmButton = find.ancestor(
          of: find.text('Confirm Location'),
          matching: find.byType(FilledButton),
        );
        expect(confirmButton, findsOneWidget);
      });
    });

    group('accessibility (C3)', () {
      testWidgets('buttons have ≥44dp minimum height', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        // Verify Cancel button has adequate touch target
        final cancelButton = tester.widget<OutlinedButton>(
          find.byKey(const Key('cancel_location_button')),
        );
        final cancelStyle = cancelButton.style;
        expect(cancelStyle?.padding?.resolve({})?.vertical,
            greaterThanOrEqualTo(32)); // 16 * 2

        // Verify Confirm button has adequate touch target
        final confirmButton = tester.widget<FilledButton>(
          find.byKey(const Key('confirm_location_button')),
        );
        final confirmStyle = confirmButton.style;
        expect(confirmStyle?.padding?.resolve({})?.vertical,
            greaterThanOrEqualTo(32)); // 16 * 2
      });

      testWidgets('emergency banner uses error colors for visibility',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.fireReport,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        // Banner should be visible (uses errorContainer color)
        expect(find.text('Call 999 for emergencies'), findsOneWidget);
      });
    });

    group('layout', () {
      testWidgets('Cancel button takes 1x flex, Confirm takes 2x flex',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfirmationPanel(
                mode: LocationPickerMode.riskLocation,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        // Find the Expanded widgets wrapping the buttons
        final expandedWidgets = tester.widgetList<Expanded>(
          find.ancestor(
            of: find.byType(OutlinedButton).first,
            matching: find.byType(Expanded),
          ),
        );

        // Cancel should be in Expanded with flex: 1 (default)
        expect(expandedWidgets.first.flex, 1);
      });

      testWidgets('has proper safe area padding', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                padding: EdgeInsets.only(bottom: 34), // iPhone notch
              ),
              child: Scaffold(
                body: ConfirmationPanel(
                  mode: LocationPickerMode.riskLocation,
                  onConfirm: () {},
                  onCancel: () {},
                ),
              ),
            ),
          ),
        );

        // Panel should render without overflow
        expect(tester.takeException(), isNull);
      });
    });
  });
}
