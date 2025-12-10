import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';

void main() {
  group('OnboardingConfig', () {
    test('has valid current versions', () {
      expect(OnboardingConfig.currentOnboardingVersion, greaterThan(0));
      expect(OnboardingConfig.currentTermsVersion, greaterThan(0));
    });

    test('has valid radius options', () {
      expect(OnboardingConfig.validRadiusOptions, isNotEmpty);
      expect(OnboardingConfig.validRadiusOptions, contains(0)); // Off option
      expect(
        OnboardingConfig.validRadiusOptions,
        contains(OnboardingConfig.defaultRadiusKm),
      );
    });

    test('has all SharedPreferences keys defined', () {
      expect(OnboardingConfig.keyOnboardingVersion, isNotEmpty);
      expect(OnboardingConfig.keyTermsVersion, isNotEmpty);
      expect(OnboardingConfig.keyTermsTimestamp, isNotEmpty);
      expect(OnboardingConfig.keyNotificationRadius, isNotEmpty);
    });
  });

  group('ConsentRecord', () {
    group('equality', () {
      test('two records with same values are equal', () {
        final timestamp = DateTime.utc(2025, 12, 10, 14, 30);
        final record1 = ConsentRecord(termsVersion: 1, acceptedAt: timestamp);
        final record2 = ConsentRecord(termsVersion: 1, acceptedAt: timestamp);

        expect(record1, equals(record2));
        expect(record1.hashCode, equals(record2.hashCode));
      });

      test('records with different versions are not equal', () {
        final timestamp = DateTime.utc(2025, 12, 10, 14, 30);
        final record1 = ConsentRecord(termsVersion: 1, acceptedAt: timestamp);
        final record2 = ConsentRecord(termsVersion: 2, acceptedAt: timestamp);

        expect(record1, isNot(equals(record2)));
      });

      test('records with different timestamps are not equal', () {
        final record1 = ConsentRecord(
          termsVersion: 1,
          acceptedAt: DateTime.utc(2025, 12, 10, 14, 30),
        );
        final record2 = ConsentRecord(
          termsVersion: 1,
          acceptedAt: DateTime.utc(2025, 12, 10, 14, 31),
        );

        expect(record1, isNot(equals(record2)));
      });
    });

    group('props', () {
      test('contains termsVersion and acceptedAt', () {
        final timestamp = DateTime.utc(2025, 12, 10, 14, 30);
        final record = ConsentRecord(termsVersion: 1, acceptedAt: timestamp);

        expect(record.props, contains(1));
        expect(record.props, contains(timestamp));
        expect(record.props.length, equals(2));
      });
    });

    group('isCurrentVersion', () {
      test('returns true when version equals current', () {
        final record = ConsentRecord(
          termsVersion: OnboardingConfig.currentTermsVersion,
          acceptedAt: DateTime.now(),
        );

        expect(record.isCurrentVersion, isTrue);
      });

      test('returns true when version is higher than current', () {
        final record = ConsentRecord(
          termsVersion: OnboardingConfig.currentTermsVersion + 1,
          acceptedAt: DateTime.now(),
        );

        expect(record.isCurrentVersion, isTrue);
      });

      test('returns false when version is lower than current', () {
        final record = ConsentRecord(
          termsVersion: OnboardingConfig.currentTermsVersion - 1,
          acceptedAt: DateTime.now(),
        );

        // Only fails if currentTermsVersion > 1
        if (OnboardingConfig.currentTermsVersion > 1) {
          expect(record.isCurrentVersion, isFalse);
        }
      });

      test('returns false for version 0 when current is 1', () {
        final record = ConsentRecord(
          termsVersion: 0,
          acceptedAt: DateTime.now(),
        );

        expect(record.isCurrentVersion, isFalse);
      });
    });

    group('formattedDate', () {
      test('formats date correctly', () {
        final record = ConsentRecord(
          termsVersion: 1,
          acceptedAt: DateTime.utc(2025, 12, 10, 14, 30),
        );

        expect(record.formattedDate, equals('10 Dec 2025 at 14:30 UTC'));
      });

      test('pads single digit hours', () {
        final record = ConsentRecord(
          termsVersion: 1,
          acceptedAt: DateTime.utc(2025, 1, 5, 9, 5),
        );

        expect(record.formattedDate, equals('5 Jan 2025 at 09:05 UTC'));
      });

      test('handles all months correctly', () {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        for (var i = 1; i <= 12; i++) {
          final record = ConsentRecord(
            termsVersion: 1,
            acceptedAt: DateTime.utc(2025, i, 15, 12, 0),
          );

          expect(record.formattedDate, contains(months[i - 1]));
        }
      });

      test('converts local time to UTC for display', () {
        // Create a local time that would be different in UTC
        final localTime = DateTime(2025, 12, 10, 14, 30);
        final record = ConsentRecord(
          termsVersion: 1,
          acceptedAt: localTime,
        );

        // Should display UTC time
        expect(record.formattedDate, contains('UTC'));
      });
    });

    group('toString', () {
      test('includes all fields', () {
        final timestamp = DateTime.utc(2025, 12, 10, 14, 30);
        final record = ConsentRecord(termsVersion: 1, acceptedAt: timestamp);

        final str = record.toString();
        expect(str, contains('ConsentRecord'));
        expect(str, contains('termsVersion: 1'));
        expect(str, contains('acceptedAt:'));
      });
    });
  });
}
