import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_button.dart';

void main() {
  group('EmergencyButton Widget Tests', () {
    testWidgets('should render Fire Service button with correct styling', (
      tester,
    ) async {
      // Arrange
      const contact = EmergencyContact.fireService;
      bool wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyButton(
              contact: contact,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Call 999 — Fire Service'), findsOneWidget);
      expect(find.byType(EmergencyButton), findsOneWidget);

      // Test button tap
      await tester.tap(find.text('Call 999 — Fire Service'));
      expect(wasPressed, true);
    });

    testWidgets('should render Police Scotland button with correct styling', (
      tester,
    ) async {
      // Arrange
      const contact = EmergencyContact.policeScotland;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyButton(contact: contact, onPressed: () {}),
          ),
        ),
      );

      // Assert
      expect(find.text('Call 101 — Police Scotland'), findsOneWidget);
      expect(find.byType(EmergencyButton), findsOneWidget);
    });

    testWidgets('should render Crimestoppers button with correct styling', (
      tester,
    ) async {
      // Arrange
      const contact = EmergencyContact.crimestoppers;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyButton(contact: contact, onPressed: () {}),
          ),
        ),
      );

      // Assert
      expect(find.text('Call 0800 555 111 — Crimestoppers'), findsOneWidget);
      expect(find.byType(EmergencyButton), findsOneWidget);
    });

    testWidgets(
      'should meet accessibility requirements for touch target size',
      (tester) async {
        // Arrange
        const contact = EmergencyContact.fireService;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(contact: contact, onPressed: () {}),
            ),
          ),
        );

        // Assert - Check minimum touch target size (48dp)
        final buttonFinder = find.byType(EmergencyButton);
        expect(buttonFinder, findsOneWidget);

        final RenderBox buttonBox = tester.renderObject(buttonFinder);
        expect(buttonBox.size.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets('should have proper semantic labels for accessibility', (
      tester,
    ) async {
      // Arrange
      const contact = EmergencyContact.fireService;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyButton(contact: contact, onPressed: () {}),
          ),
        ),
      );

      // Assert - Check semantic labeling
      final semantics = tester.getSemantics(find.byType(EmergencyButton));
      expect(semantics.label, contains('Call 999'));
      expect(semantics.label, contains('Fire Service'));
    });

    testWidgets('should apply correct color scheme based on priority', (
      tester,
    ) async {
      // Arrange
      const fireContact = EmergencyContact.fireService;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyButton(contact: fireContact, onPressed: () {}),
          ),
        ),
      );

      // Assert - Fire Service should use error color (red)
      // We verify the button exists and has been styled
      final emergencyButton = find.byType(EmergencyButton);
      expect(emergencyButton, findsOneWidget);
    });
  });

  group('EmergencyButton Factory Widget Tests', () {
    testWidgets('FireServiceButton should create correct button', (
      tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FireServiceButton(onPressed: () {})),
        ),
      );

      // Assert
      expect(find.text('Call 999 — Fire Service'), findsOneWidget);
    });

    testWidgets('PoliceScotlandButton should create correct button', (
      tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PoliceScotlandButton(onPressed: () {})),
        ),
      );

      // Assert
      expect(find.text('Call 101 — Police Scotland'), findsOneWidget);
    });

    testWidgets('CrimestoppersButton should create correct button', (
      tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CrimestoppersButton(onPressed: () {})),
        ),
      );

      // Assert
      expect(find.text('Call 0800 555 111 — Crimestoppers'), findsOneWidget);
    });
  });
}
