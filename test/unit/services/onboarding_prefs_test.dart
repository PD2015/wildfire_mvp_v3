import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/models/consent_record.dart';
import 'package:wildfire_mvp_v3/services/onboarding_prefs_impl.dart';

void main() {
  // Required for SharedPreferences mock
  WidgetsFlutterBinding.ensureInitialized();

  late OnboardingPrefsImpl service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = OnboardingPrefsImpl(prefs);
  });

  group('isOnboardingRequired', () {
    test('returns true when no onboarding_version exists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.isOnboardingRequired(), isTrue);
    });

    test('returns true when version is 0', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion: 0,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.isOnboardingRequired(), isTrue);
    });

    test('returns true when version < current', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion:
            OnboardingConfig.currentOnboardingVersion - 1,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      // Only relevant if currentOnboardingVersion > 1
      if (OnboardingConfig.currentOnboardingVersion > 1) {
        expect(await service.isOnboardingRequired(), isTrue);
      }
    });

    test('returns false when version >= current', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion:
            OnboardingConfig.currentOnboardingVersion,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.isOnboardingRequired(), isFalse);
    });

    test('returns false when version > current', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion:
            OnboardingConfig.currentOnboardingVersion + 1,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.isOnboardingRequired(), isFalse);
    });
  });

  group('isMigrationRequired', () {
    test('returns false for first-time users (no version)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.isMigrationRequired(), isFalse);
    });

    test('returns false for first-time users (version 0)', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion: 0,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.isMigrationRequired(), isFalse);
    });

    test('returns false when version equals current', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion:
            OnboardingConfig.currentOnboardingVersion,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.isMigrationRequired(), isFalse);
    });

    test('returns true when has old version and needs update', () async {
      // Only test if we can simulate an old version
      if (OnboardingConfig.currentOnboardingVersion > 1) {
        SharedPreferences.setMockInitialValues({
          OnboardingConfig.keyOnboardingVersion: 1,
        });
        final prefs = await SharedPreferences.getInstance();
        service = OnboardingPrefsImpl(prefs);

        expect(await service.isMigrationRequired(), isTrue);
      }
    });
  });

  group('getOnboardingVersion', () {
    test('returns 0 when not set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getOnboardingVersion(), equals(0));
    });

    test('returns stored version', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion: 5,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getOnboardingVersion(), equals(5));
    });
  });

  group('getConsentRecord', () {
    test('returns null when not consented (no keys)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getConsentRecord(), isNull);
    });

    test('returns null when version is missing', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyTermsTimestamp: timestamp,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getConsentRecord(), isNull);
    });

    test('returns null when timestamp is missing', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyTermsVersion: 1,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getConsentRecord(), isNull);
    });

    test('returns null when timestamp is too old (corrupted)', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyTermsVersion: 1,
        OnboardingConfig.keyTermsTimestamp: 1000, // Year 1970
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getConsentRecord(), isNull);
    });

    test('returns ConsentRecord when valid data exists', () async {
      final timestamp =
          DateTime.utc(2025, 12, 10, 14, 30).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyTermsVersion: 1,
        OnboardingConfig.keyTermsTimestamp: timestamp,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      final record = await service.getConsentRecord();

      expect(record, isNotNull);
      expect(record!.termsVersion, equals(1));
      expect(record.acceptedAt.millisecondsSinceEpoch, equals(timestamp));
    });
  });

  group('getNotificationRadiusKm', () {
    test('returns default when not set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(
        await service.getNotificationRadiusKm(),
        equals(OnboardingConfig.defaultRadiusKm),
      );
    });

    test('returns stored radius', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyNotificationRadius: 25,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getNotificationRadiusKm(), equals(25));
    });

    test('returns 0 when set to off', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyNotificationRadius: 0,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getNotificationRadiusKm(), equals(0));
    });
  });

  group('getPreviousVersion', () {
    test('returns 0 when not set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getPreviousVersion(), equals(0));
    });

    test('returns stored version', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion: 3,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(await service.getPreviousVersion(), equals(3));
    });
  });

  group('completeOnboarding', () {
    test('saves all 4 preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      await service.completeOnboarding(radiusKm: 25);

      expect(
        prefs.getInt(OnboardingConfig.keyOnboardingVersion),
        equals(OnboardingConfig.currentOnboardingVersion),
      );
      expect(
        prefs.getInt(OnboardingConfig.keyTermsVersion),
        equals(OnboardingConfig.currentTermsVersion),
      );
      expect(
        prefs.getInt(OnboardingConfig.keyTermsTimestamp),
        isNotNull,
      );
      expect(
        prefs.getInt(OnboardingConfig.keyNotificationRadius),
        equals(25),
      );
    });

    test('timestamp is recent', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      final before = DateTime.now().millisecondsSinceEpoch;
      await service.completeOnboarding(radiusKm: 10);
      final after = DateTime.now().millisecondsSinceEpoch;

      final timestamp = prefs.getInt(OnboardingConfig.keyTermsTimestamp)!;
      expect(timestamp, greaterThanOrEqualTo(before));
      expect(timestamp, lessThanOrEqualTo(after));
    });

    test('throws ArgumentError for invalid radius', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(
        () => service.completeOnboarding(radiusKm: 15),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for negative radius', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(
        () => service.completeOnboarding(radiusKm: -5),
        throwsArgumentError,
      );
    });

    test('accepts all valid radius options', () async {
      for (final radius in OnboardingConfig.validRadiusOptions) {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        service = OnboardingPrefsImpl(prefs);

        await service.completeOnboarding(radiusKm: radius);

        expect(
          prefs.getInt(OnboardingConfig.keyNotificationRadius),
          equals(radius),
        );
      }
    });

    test('onboarding no longer required after completion', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      // Before completion
      expect(await service.isOnboardingRequired(), isTrue);

      await service.completeOnboarding(radiusKm: 10);

      // After completion
      expect(await service.isOnboardingRequired(), isFalse);
    });
  });

  group('updateNotificationRadius', () {
    test('updates only radius', () async {
      final timestamp = DateTime.utc(2025, 12, 10).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyOnboardingVersion: 1,
        OnboardingConfig.keyTermsVersion: 1,
        OnboardingConfig.keyTermsTimestamp: timestamp,
        OnboardingConfig.keyNotificationRadius: 10,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      await service.updateNotificationRadius(radiusKm: 50);

      // Radius updated
      expect(
        prefs.getInt(OnboardingConfig.keyNotificationRadius),
        equals(50),
      );

      // Other values unchanged
      expect(prefs.getInt(OnboardingConfig.keyOnboardingVersion), equals(1));
      expect(prefs.getInt(OnboardingConfig.keyTermsVersion), equals(1));
      expect(
          prefs.getInt(OnboardingConfig.keyTermsTimestamp), equals(timestamp));
    });

    test('throws ArgumentError for invalid radius', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      expect(
        () => service.updateNotificationRadius(radiusKm: 100),
        throwsArgumentError,
      );
    });

    test('accepts 0 (off) as valid radius', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingConfig.keyNotificationRadius: 10,
      });
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      await service.updateNotificationRadius(radiusKm: 0);

      expect(
        prefs.getInt(OnboardingConfig.keyNotificationRadius),
        equals(0),
      );
    });
  });

  group('integration scenarios', () {
    test('full onboarding flow', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      // Initial state
      expect(await service.isOnboardingRequired(), isTrue);
      expect(await service.isMigrationRequired(), isFalse);
      expect(await service.getConsentRecord(), isNull);

      // Complete onboarding
      await service.completeOnboarding(radiusKm: 25);

      // Final state
      expect(await service.isOnboardingRequired(), isFalse);
      expect(await service.isMigrationRequired(), isFalse);

      final consent = await service.getConsentRecord();
      expect(consent, isNotNull);
      expect(
          consent!.termsVersion, equals(OnboardingConfig.currentTermsVersion));
      expect(consent.isCurrentVersion, isTrue);
    });

    test('settings update after onboarding', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OnboardingPrefsImpl(prefs);

      // Complete onboarding with default radius
      await service.completeOnboarding(radiusKm: 10);
      expect(await service.getNotificationRadiusKm(), equals(10));

      // Update radius in settings
      await service.updateNotificationRadius(radiusKm: 50);
      expect(await service.getNotificationRadiusKm(), equals(50));

      // Consent should still be valid
      final consent = await service.getConsentRecord();
      expect(consent, isNotNull);
      expect(consent!.isCurrentVersion, isTrue);
    });
  });
}
