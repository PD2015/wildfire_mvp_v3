import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';

void main() {
  group('EmergencyContact Model Tests', () {
    group('EmergencyContact creation and properties', () {
      test('creates Fire Service contact with correct properties', () {
        const contact = EmergencyContact(
          name: 'Fire Service',
          phoneNumber: '999',
          priority: EmergencyPriority.urgent,
          description: 'For life-threatening emergencies',
        );

        expect(contact.name, 'Fire Service');
        expect(contact.phoneNumber, '999');
        expect(contact.priority, EmergencyPriority.urgent);
        expect(contact.description, 'For life-threatening emergencies');
      });

      test('creates Police Scotland contact with correct properties', () {
        const contact = EmergencyContact(
          name: 'Police Scotland',
          phoneNumber: '101',
          priority: EmergencyPriority.nonEmergency,
          description: 'For non-emergency incidents',
        );

        expect(contact.name, 'Police Scotland');
        expect(contact.phoneNumber, '101');
        expect(contact.priority, EmergencyPriority.nonEmergency);
      });

      test('creates Crimestoppers contact with correct properties', () {
        const contact = EmergencyContact(
          name: 'Crimestoppers',
          phoneNumber: '0800 555 111',
          priority: EmergencyPriority.anonymous,
          description: 'Anonymous reporting line',
        );

        const contact2 = EmergencyContact(
          name: 'Crimestoppers',
          phoneNumber: '0800 555 111',
          priority: EmergencyPriority.anonymous,
          description: 'Anonymous reporting line',
        );

        expect(contact, equals(contact2)); // Tests Equatable
      });

      test('tel URI formatting works correctly', () {
        const contact = EmergencyContact(
          name: 'Test Service',
          phoneNumber: '0800 555 111',
          priority: EmergencyPriority.anonymous,
        );

        expect(contact.telUri, 'tel:0800555111');
      });

      test('display text format is correct', () {
        const contact = EmergencyContact(
          name: 'Fire Service',
          phoneNumber: '999',
          priority: EmergencyPriority.urgent,
        );

        expect(contact.displayText, '999 Fire Service');
      });

      test('isUrgent property works correctly', () {
        expect(EmergencyContact.fireService.isUrgent, isTrue);
        expect(EmergencyContact.policeScotland.isUrgent, isFalse);
        expect(EmergencyContact.crimestoppers.isUrgent, isFalse);
      });
    });

    group('Scottish Fire Reporting Constants', () {
      test('provides correct Scottish fire reporting contacts', () {
        expect(EmergencyContact.scottishFireContacts, hasLength(3));

        final fireService = EmergencyContact.scottishFireContacts[0];
        expect(fireService.phoneNumber, '999');
        expect(fireService.priority, EmergencyPriority.urgent);

        final policeScotland = EmergencyContact.scottishFireContacts[1];
        expect(policeScotland.phoneNumber, '101');
        expect(policeScotland.priority, EmergencyPriority.nonEmergency);

        final crimestoppers = EmergencyContact.scottishFireContacts[2];
        expect(crimestoppers.phoneNumber, '0800 555 111');
        expect(crimestoppers.priority, EmergencyPriority.anonymous);
      });

      test('provides individual emergency contact constants', () {
        // Test Fire Service constant
        expect(EmergencyContact.fireService.phoneNumber, '999');
        expect(EmergencyContact.fireService.name, 'Fire Service');
        expect(EmergencyContact.fireService.priority, EmergencyPriority.urgent);

        // Test Police Scotland constant
        expect(EmergencyContact.policeScotland.phoneNumber, '101');
        expect(EmergencyContact.policeScotland.name, 'Police Scotland');
        expect(
          EmergencyContact.policeScotland.priority,
          EmergencyPriority.nonEmergency,
        );

        // Test Crimestoppers constant
        expect(EmergencyContact.crimestoppers.phoneNumber, '0800 555 111');
        expect(EmergencyContact.crimestoppers.name, 'Crimestoppers');
        expect(
          EmergencyContact.crimestoppers.priority,
          EmergencyPriority.anonymous,
        );
      });
    });

    group('EmergencyPriority Enum', () {
      test('has all expected priority levels', () {
        expect(EmergencyPriority.values, hasLength(3));
        expect(EmergencyPriority.values, contains(EmergencyPriority.urgent));
        expect(
          EmergencyPriority.values,
          contains(EmergencyPriority.nonEmergency),
        );
        expect(EmergencyPriority.values, contains(EmergencyPriority.anonymous));
      });
    });

    group('CallResult Enum', () {
      test('has all expected call result values', () {
        expect(CallResult.values, hasLength(4));
        expect(CallResult.values, contains(CallResult.success));
        expect(CallResult.values, contains(CallResult.failed));
        expect(CallResult.values, contains(CallResult.cancelled));
        expect(CallResult.values, contains(CallResult.unsupported));
      });
    });

    group('Validation', () {
      test('validated factory throws on empty name', () {
        expect(
          () => EmergencyContact.validated(
            name: '',
            phoneNumber: '999',
            priority: EmergencyPriority.urgent,
          ),
          throwsArgumentError,
        );
      });

      test('validated factory throws on empty phone number', () {
        expect(
          () => EmergencyContact.validated(
            name: 'Fire Service',
            phoneNumber: '',
            priority: EmergencyPriority.urgent,
          ),
          throwsArgumentError,
        );
      });

      test('validated factory throws on invalid phone number', () {
        expect(
          () => EmergencyContact.validated(
            name: 'Fire Service',
            phoneNumber: '12',
            priority: EmergencyPriority.urgent,
          ),
          throwsArgumentError,
        );
      });

      test('validated factory accepts valid input', () {
        final contact = EmergencyContact.validated(
          name: 'Fire Service',
          phoneNumber: '999',
          priority: EmergencyPriority.urgent,
        );

        expect(contact.name, 'Fire Service');
        expect(contact.phoneNumber, '999');
      });
    });

    group('copyWith method', () {
      test('creates copy with modified properties', () {
        const original = EmergencyContact(
          name: 'Original',
          phoneNumber: '999',
          priority: EmergencyPriority.urgent,
        );

        final modified = original.copyWith(
          name: 'Modified',
          phoneNumber: '101',
        );

        expect(modified.name, 'Modified');
        expect(modified.phoneNumber, '101');
        expect(modified.priority, EmergencyPriority.urgent); // Unchanged
      });
    });
  });
}
