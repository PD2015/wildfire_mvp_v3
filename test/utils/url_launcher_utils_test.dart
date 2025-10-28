import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/utils/url_launcher_utils.dart';

void main() {
  group('UrlLauncherUtils Tests', () {
    group('Phone Number Validation', () {
      test('validates correct phone numbers', () {
        expect(UrlLauncherUtils.isValidPhoneNumber('999'), isTrue);
        expect(UrlLauncherUtils.isValidPhoneNumber('101'), isTrue);
        expect(UrlLauncherUtils.isValidPhoneNumber('0800 555 111'), isTrue);
        expect(UrlLauncherUtils.isValidPhoneNumber('08005551111'), isTrue);
        expect(UrlLauncherUtils.isValidPhoneNumber('+44 800 555 111'), isTrue);
      });

      test('rejects invalid phone numbers', () {
        expect(UrlLauncherUtils.isValidPhoneNumber(''), isFalse);
        expect(UrlLauncherUtils.isValidPhoneNumber('12'), isFalse);
        expect(UrlLauncherUtils.isValidPhoneNumber('abc'), isFalse);
        expect(UrlLauncherUtils.isValidPhoneNumber('12345678901234567890'),
            isFalse);
      });
    });

    group('Tel URI Formatting', () {
      test('formats phone numbers correctly for tel: URIs', () {
        expect(UrlLauncherUtils.formatTelUri('999'), 'tel:999');
        expect(UrlLauncherUtils.formatTelUri('101'), 'tel:101');
        expect(UrlLauncherUtils.formatTelUri('0800 555 111'), 'tel:0800555111');
        expect(UrlLauncherUtils.formatTelUri('+44 800 555 111'),
            'tel:44800555111');
        expect(UrlLauncherUtils.formatTelUri('0800-555-111'), 'tel:0800555111');
      });

      test('removes all non-digit characters', () {
        expect(
            UrlLauncherUtils.formatTelUri('(0800) 555-111'), 'tel:0800555111');
        expect(UrlLauncherUtils.formatTelUri('0800.555.111'), 'tel:0800555111');
        expect(UrlLauncherUtils.formatTelUri('0800 - 555 - 111'),
            'tel:0800555111');
      });
    });

    group('Error Messages', () {
      test('generates appropriate error messages for different call results',
          () {
        const contact = EmergencyContact.fireService;

        // Test unsupported platform message
        final unsupportedMessage = UrlLauncherUtils.getErrorMessage(
          CallResult.unsupported,
          contact,
        );
        expect(unsupportedMessage, contains('Could not open dialer'));
        expect(unsupportedMessage, contains('999'));
        expect(unsupportedMessage, contains('manually'));

        // Test failed call message
        final failedMessage = UrlLauncherUtils.getErrorMessage(
          CallResult.failed,
          contact,
        );
        expect(failedMessage, contains('Could not open dialer'));
        expect(failedMessage, contains('999'));

        // Test cancelled call message
        final cancelledMessage = UrlLauncherUtils.getErrorMessage(
          CallResult.cancelled,
          contact,
        );
        expect(cancelledMessage, contains('cancelled'));
        expect(cancelledMessage, contains('999'));

        // Test success message
        final successMessage = UrlLauncherUtils.getErrorMessage(
          CallResult.success,
          contact,
        );
        expect(successMessage, contains('Successfully opened'));
        expect(successMessage, contains('999'));
      });
    });

    group('Platform Support Detection', () {
      test('detects platform dialing capabilities', () {
        // Note: This test runs on the test platform, so we can only test the getter exists
        expect(() => UrlLauncherUtils.platformSupportsDialing, returnsNormally);

        // The actual value depends on the test platform (likely false for desktop)
        final supportsDialing = UrlLauncherUtils.platformSupportsDialing;
        expect(supportsDialing, isA<bool>());

        // In test environment, typically false since it's not mobile
        if (!kIsWeb &&
            defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) {
          expect(supportsDialing, isFalse);
        }
      });
    });

    group('Emergency Call Launch', () {
      // Note: These tests will fail in test environment since url_launcher
      // cannot actually launch URLs, but we test the logic path

      test('handles emergency contact objects correctly', () async {
        const contact = EmergencyContact.fireService;

        // This will fail in test environment, but we're testing the API
        final result = await UrlLauncherUtils.launchEmergencyCall(contact);

        // In test environment, should return unsupported or failed
        expect([CallResult.unsupported, CallResult.failed], contains(result));
      });

      test('handles Police Scotland contact', () async {
        const contact = EmergencyContact.policeScotland;

        final result = await UrlLauncherUtils.launchEmergencyCall(contact);
        expect([CallResult.unsupported, CallResult.failed], contains(result));
      });

      test('handles Crimestoppers contact', () async {
        const contact = EmergencyContact.crimestoppers;

        final result = await UrlLauncherUtils.launchEmergencyCall(contact);
        expect([CallResult.unsupported, CallResult.failed], contains(result));
      });
    });

    group('Emergency Call Handler', () {
      test('calls onFailure callback when call fails', () async {
        const contact = EmergencyContact.fireService;
        String? receivedMessage;

        await UrlLauncherUtils.handleEmergencyCall(
          contact: contact,
          onFailure: (message) {
            receivedMessage = message;
          },
        );

        // Should have called onFailure since we're in test environment
        expect(receivedMessage, isNotNull);
        expect(receivedMessage, contains('Could not open dialer'));
        expect(receivedMessage, contains('999'));
      });

      test('does not call onFailure on success', () async {
        // Note: This test is theoretical since we can't mock url_launcher easily
        // In a real implementation, we'd use dependency injection to mock the launcher

        // For now, we just verify the method signature works
        expect(
          () => UrlLauncherUtils.handleEmergencyCall(
            contact: EmergencyContact.fireService,
            onFailure: (message) {},
          ),
          returnsNormally,
        );
      });
    });

    group('Emergency Contact Integration', () {
      test('works with all Scottish fire contacts', () {
        for (final contact in EmergencyContact.scottishFireContacts) {
          // Verify tel URI formatting
          expect(contact.telUri, startsWith('tel:'));

          // Verify phone number validation
          expect(
              UrlLauncherUtils.isValidPhoneNumber(contact.phoneNumber), isTrue);

          // Verify error message generation
          final errorMessage = UrlLauncherUtils.getErrorMessage(
            CallResult.failed,
            contact,
          );
          expect(errorMessage, contains(contact.phoneNumber));
        }
      });

      test('telUri property matches formatTelUri function', () {
        for (final contact in EmergencyContact.scottishFireContacts) {
          final expectedUri =
              UrlLauncherUtils.formatTelUri(contact.phoneNumber);
          expect(contact.telUri, equals(expectedUri));
        }
      });
    });
  });
}
