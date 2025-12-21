import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/manual_location_dialog.dart';

void main() {
  group('ManualLocationDialog Widget Tests', () {
    testWidgets('dialog displays with correct title and input fields', (
      tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => ManualLocationDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Enter Location'), findsOneWidget);
      expect(find.byKey(const Key('latitude_field')), findsOneWidget);
      expect(find.byKey(const Key('longitude_field')), findsOneWidget);
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('save_button')), findsOneWidget);
    });

    testWidgets('accepts valid coordinate input with proper formatting', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => ManualLocationDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - Enter valid coordinates
      await tester.enterText(
        find.byKey(const Key('latitude_field')),
        '55.9533',
      );
      await tester.enterText(
        find.byKey(const Key('longitude_field')),
        '-3.1883',
      );
      await tester.pumpAndSettle();

      // Assert - Save button should be enabled
      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_button')),
      );
      expect(
        saveButton.onPressed,
        isNotNull,
        reason: 'Save button should be enabled for valid coordinates',
      );

      // No error message should be displayed
      expect(find.textContaining('must be between'), findsNothing);
    });

    testWidgets('rejects invalid coordinate ranges with clear error messages', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => ManualLocationDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - Enter invalid coordinates (out of range)
      await tester.enterText(find.byKey(const Key('latitude_field')), '999');
      await tester.enterText(find.byKey(const Key('longitude_field')), '999');
      await tester.pumpAndSettle();

      // Assert - Error message should be displayed
      expect(
        find.textContaining('Latitude must be between -90 and 90 degrees'),
        findsOneWidget,
      );

      // Save button should be disabled
      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_button')),
      );
      expect(
        saveButton.onPressed,
        isNull,
        reason: 'Save button should be disabled for invalid coordinates',
      );
    });

    testWidgets('input formatters prevent invalid characters', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => ManualLocationDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - Try to enter invalid characters
      await tester.enterText(
        find.byKey(const Key('latitude_field')),
        'abc123.45def',
      );
      await tester.enterText(
        find.byKey(const Key('longitude_field')),
        'xyz-67.89ghi',
      );
      await tester.pumpAndSettle();

      // Assert - Only valid numeric characters should remain (letters filtered out)
      final latField = tester.widget<TextField>(
        find.byKey(const Key('latitude_field')),
      );
      final lonField = tester.widget<TextField>(
        find.byKey(const Key('longitude_field')),
      );

      expect(latField.controller?.text, equals('123.45'));
      expect(lonField.controller?.text, equals('-67.89'));
    });

    testWidgets('keyboard type is configured correctly for numeric input', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => ManualLocationDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      final latField = tester.widget<TextField>(
        find.byKey(const Key('latitude_field')),
      );
      final lonField = tester.widget<TextField>(
        find.byKey(const Key('longitude_field')),
      );

      expect(
        latField.keyboardType,
        equals(
          const TextInputType.numberWithOptions(signed: true, decimal: true),
        ),
      );
      expect(
        lonField.keyboardType,
        equals(
          const TextInputType.numberWithOptions(signed: true, decimal: true),
        ),
      );
    });

    testWidgets('input formatters are configured correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => ManualLocationDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      final latField = tester.widget<TextField>(
        find.byKey(const Key('latitude_field')),
      );
      final lonField = tester.widget<TextField>(
        find.byKey(const Key('longitude_field')),
      );

      expect(latField.inputFormatters, hasLength(1));
      expect(lonField.inputFormatters, hasLength(1));

      // Verify input formatters allow expected patterns
      final formatter =
          latField.inputFormatters!.first as FilteringTextInputFormatter;
      expect(formatter.allow, isTrue);
    });

    group('Touch Target Size Validation (Gate C3)', () {
      testWidgets('all interactive elements meet 44dp minimum size requirement', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - Check button sizes (48dp height as specified in implementation)
        final cancelButtonSize = tester.getSize(
          find.byKey(const Key('cancel_button')),
        );
        final saveButtonSize = tester.getSize(
          find.byKey(const Key('save_button')),
        );

        const minimumSize = 44.0;
        expect(
          cancelButtonSize.height,
          greaterThanOrEqualTo(minimumSize),
          reason: 'Cancel button height should be ≥44dp',
        );
        expect(
          saveButtonSize.height,
          greaterThanOrEqualTo(minimumSize),
          reason: 'Save button height should be ≥44dp',
        );

        // Text fields should also be adequately sized for touch
        final latFieldSize = tester.getSize(
          find.byKey(const Key('latitude_field')),
        );
        final lonFieldSize = tester.getSize(
          find.byKey(const Key('longitude_field')),
        );

        expect(
          latFieldSize.height,
          greaterThanOrEqualTo(minimumSize),
          reason: 'Latitude field should be ≥44dp for touch accessibility',
        );
        expect(
          lonFieldSize.height,
          greaterThanOrEqualTo(minimumSize),
          reason: 'Longitude field should be ≥44dp for touch accessibility',
        );
      });
    });

    group('Accessibility Compliance (Gate C3)', () {
      testWidgets('proper semantic labels are present for screen readers', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - Check that our specific widgets with keys exist
        expect(find.byKey(const Key('latitude_field')), findsOneWidget);
        expect(find.byKey(const Key('longitude_field')), findsOneWidget);
        expect(find.byKey(const Key('cancel_button')), findsOneWidget);
        expect(find.byKey(const Key('save_button')), findsOneWidget);

        // Verify that semantic labels exist by checking for widgets with semantic properties
        // Note: find.bySemanticsLabel() sometimes fails in tests, but the labels are there
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Latitude coordinate input',
          ),
          findsOneWidget,
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Longitude coordinate input',
          ),
          findsOneWidget,
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == 'Cancel',
          ),
          findsOneWidget,
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Save manual location',
          ),
          findsOneWidget,
        );
      });

      testWidgets('semantic labels are meaningful and not generic', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - Verify semantic labels are descriptive
        final latFieldSemantics = tester.getSemantics(
          find.byKey(const Key('latitude_field')),
        );
        final lonFieldSemantics = tester.getSemantics(
          find.byKey(const Key('longitude_field')),
        );

        expect(latFieldSemantics.label, contains('Latitude'));
        expect(latFieldSemantics.label, contains('coordinate'));
        expect(lonFieldSemantics.label, contains('Longitude'));
        expect(lonFieldSemantics.label, contains('coordinate'));
      });
    });

    group('Button Behavior', () {
      testWidgets('cancel button closes dialog without returning data', (
        tester,
      ) async {
        // Arrange
        LatLng? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () async {
                    result = await ManualLocationDialog.show(context);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byKey(const Key('cancel_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.byType(Dialog),
          findsNothing,
          reason: 'Dialog should be closed',
        );
        expect(result, isNull, reason: 'Cancel should return null');
      });

      testWidgets(
        'save button returns valid LatLng when coordinates are valid',
        (tester) async {
          // Arrange
          LatLng? result;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => FilledButton(
                    onPressed: () async {
                      result = await ManualLocationDialog.show(context);
                    },
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Show Dialog'));
          await tester.pumpAndSettle();

          // Act
          await tester.enterText(
            find.byKey(const Key('latitude_field')),
            '55.9533',
          );
          await tester.enterText(
            find.byKey(const Key('longitude_field')),
            '-3.1883',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('save_button')));
          await tester.pumpAndSettle();

          // Assert
          expect(
            find.byType(Dialog),
            findsNothing,
            reason: 'Dialog should be closed',
          );
          expect(result, isNotNull, reason: 'Save should return LatLng');
          expect(result!.latitude, closeTo(55.9533, 0.0001));
          expect(result!.longitude, closeTo(-3.1883, 0.0001));
        },
      );

      testWidgets('save button is disabled when coordinates are invalid', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - Enter invalid coordinates
        await tester.enterText(find.byKey(const Key('latitude_field')), '999');
        await tester.pumpAndSettle();

        // Assert
        final saveButton = tester.widget<FilledButton>(
          find.byKey(const Key('save_button')),
        );
        expect(
          saveButton.onPressed,
          isNull,
          reason: 'Save button should be disabled for invalid input',
        );
      });
    });

    group('Real-time Validation', () {
      testWidgets('validation updates in real-time as user types', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act & Assert - Enter invalid latitude first (no validation yet)
        await tester.enterText(find.byKey(const Key('latitude_field')), '99');
        await tester.pumpAndSettle();

        // No error yet because longitude is empty (validation requires both fields)
        expect(
          find.textContaining('Latitude must be between -90 and 90 degrees'),
          findsNothing,
        );

        // Now enter longitude - this should trigger validation and show latitude error
        await tester.enterText(
          find.byKey(const Key('longitude_field')),
          '-3.1883',
        );
        await tester.pumpAndSettle();

        // Should now show latitude validation error
        expect(
          find.textContaining('Latitude must be between -90 and 90 degrees'),
          findsOneWidget,
        );

        final saveButton = tester.widget<FilledButton>(
          find.byKey(const Key('save_button')),
        );
        expect(
          saveButton.onPressed,
          isNull,
          reason: 'Invalid latitude should keep save disabled',
        );
      });

      testWidgets('clears error when input becomes valid', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - Enter invalid then valid coordinates
        await tester.enterText(find.byKey(const Key('latitude_field')), '999');
        await tester.enterText(
          find.byKey(const Key('longitude_field')),
          '-3.1883',
        );
        await tester.pumpAndSettle();

        // Should show error
        expect(
          find.textContaining('Latitude must be between -90 and 90 degrees'),
          findsOneWidget,
        );

        // Fix the latitude
        await tester.enterText(
          find.byKey(const Key('latitude_field')),
          '55.9533',
        );
        await tester.pumpAndSettle();

        // Assert - Error should be cleared
        expect(find.textContaining('must be between'), findsNothing);

        final saveButton = tester.widget<FilledButton>(
          find.byKey(const Key('save_button')),
        );
        expect(
          saveButton.onPressed,
          isNotNull,
          reason: 'Save button should be enabled for valid coordinates',
        );
      });
    });

    group('Edge Cases', () {
      testWidgets('handles boundary coordinate values correctly', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - Test boundary values
        await tester.enterText(find.byKey(const Key('latitude_field')), '90.0');
        await tester.enterText(
          find.byKey(const Key('longitude_field')),
          '180.0',
        );
        await tester.pumpAndSettle();

        // Assert - Should be valid
        expect(find.textContaining('must be between'), findsNothing);

        final saveButton = tester.widget<FilledButton>(
          find.byKey(const Key('save_button')),
        );
        expect(
          saveButton.onPressed,
          isNotNull,
          reason: 'Boundary values should be valid',
        );
      });

      testWidgets('handles negative coordinates correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - Test negative coordinates
        await tester.enterText(
          find.byKey(const Key('latitude_field')),
          '-45.5',
        );
        await tester.enterText(
          find.byKey(const Key('longitude_field')),
          '-122.3',
        );
        await tester.pumpAndSettle();

        // Assert - Should be valid
        expect(find.textContaining('must be between'), findsNothing);

        final saveButton = tester.widget<FilledButton>(
          find.byKey(const Key('save_button')),
        );
        expect(
          saveButton.onPressed,
          isNotNull,
          reason: 'Negative coordinates should be valid',
        );
      });

      testWidgets('handles empty fields gracefully', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => ManualLocationDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - Empty fields should not show error but save should be disabled
        expect(find.textContaining('must be between'), findsNothing);

        final saveButton = tester.widget<FilledButton>(
          find.byKey(const Key('save_button')),
        );
        expect(
          saveButton.onPressed,
          isNull,
          reason: 'Empty fields should disable save button',
        );
      });
    });
  });
}
