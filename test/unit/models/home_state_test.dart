import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/home_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

/// Unit tests for HomeState sealed class hierarchy
///
/// Validates:
/// - Equatable equality for all states
/// - Props list includes all fields
/// - Timestamp equality and staleness logic
/// - toString() output formatting
/// - isLocationStale getter behavior
void main() {
  group('HomeStateLoading', () {
    final now = DateTime(2025, 11, 24, 10, 0);
    final oneHourAgo = DateTime(2025, 11, 24, 9, 0);
    final twoHoursAgo = DateTime(2025, 11, 24, 8, 0);
    const testLocation = LatLng(55.9533, -3.1883);

    test('equality without lastKnownLocation', () {
      final state1 = HomeStateLoading(startTime: now);
      final state2 = HomeStateLoading(startTime: now);

      expect(state1, equals(state2));
    });

    test('equality with identical lastKnownLocation', () {
      final state1 = HomeStateLoading(
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: oneHourAgo,
      );
      final state2 = HomeStateLoading(
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: oneHourAgo,
      );

      expect(state1, equals(state2));
    });

    test('different when lastKnownLocation differs', () {
      final state1 = HomeStateLoading(
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: now,
      );
      final state2 = HomeStateLoading(
        startTime: now,
        lastKnownLocation: const LatLng(55.8642, -4.2518), // Glasgow
        lastKnownLocationTimestamp: now,
      );

      expect(state1, isNot(equals(state2)));
    });

    test('different when timestamp differs', () {
      final state1 = HomeStateLoading(
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: oneHourAgo,
      );
      final state2 = HomeStateLoading(
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: twoHoursAgo,
      );

      expect(state1, isNot(equals(state2)));
    });

    test('different when isRetry differs', () {
      final state1 = HomeStateLoading(startTime: now, isRetry: false);
      final state2 = HomeStateLoading(startTime: now, isRetry: true);

      expect(state1, isNot(equals(state2)));
    });

    test('props list includes all fields', () {
      final state = HomeStateLoading(
        isRetry: true,
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: oneHourAgo,
        isWhat3wordsLoading: true,
        isGeocodingLoading: true,
      );

      expect(state.props, [
        true, // isRetry
        now, // startTime
        testLocation, // lastKnownLocation
        oneHourAgo, // lastKnownLocationTimestamp
        true, // isWhat3wordsLoading
        true, // isGeocodingLoading
      ]);
    });

    test('isLocationStale returns false when no timestamp', () {
      final state = HomeStateLoading(
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: null,
      );

      expect(state.isLocationStale, isFalse);
    });

    test('isLocationStale returns false when location is fresh (<1 hour)', () {
      // Use actual DateTime.now() and subtract 30 minutes
      final thirtyMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 30),
      );

      final state = HomeStateLoading(
        startTime: DateTime.now(),
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: thirtyMinutesAgo,
      );

      expect(state.isLocationStale, isFalse);
    });

    test('isLocationStale returns true when location is old (>1 hour)', () {
      // Use actual DateTime.now() and subtract 2 hours
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));

      final state = HomeStateLoading(
        startTime: DateTime.now(),
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: twoHoursAgo,
      );

      expect(state.isLocationStale, isTrue);
    });

    test('isLocationStale boundary: exactly 1 hour returns false', () {
      // Exactly 1 hour old - should not be stale yet
      // Add 1ms buffer to account for execution time
      final exactlyOneHourAgo = DateTime.now()
          .subtract(const Duration(hours: 1))
          .add(const Duration(milliseconds: 1));

      final state = HomeStateLoading(
        startTime: DateTime.now(),
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: exactlyOneHourAgo,
      );

      expect(state.isLocationStale, isFalse);
    });

    test('isLocationStale boundary: 1 hour + 1 second returns true', () {
      // Just over 1 hour old - should be stale
      final overOneHourAgo = DateTime.now().subtract(
        const Duration(hours: 1, seconds: 2),
      );

      final state = HomeStateLoading(
        startTime: DateTime.now(),
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: overOneHourAgo,
      );

      expect(state.isLocationStale, isTrue);
    });

    test('toString includes all fields and isStale status', () {
      final state = HomeStateLoading(
        isRetry: true,
        startTime: now,
        lastKnownLocation: testLocation,
        lastKnownLocationTimestamp: oneHourAgo,
      );

      final str = state.toString();

      expect(str, contains('isRetry: true'));
      expect(str, contains('startTime: $now'));
      expect(str, contains('lastKnownLocation: $testLocation'));
      expect(str, contains('lastKnownLocationTimestamp: $oneHourAgo'));
      expect(str, contains('isStale:')); // Should include staleness indicator
    });

    test('toString with null location fields', () {
      final state = HomeStateLoading(startTime: now);
      final str = state.toString();

      expect(str, contains('lastKnownLocation: null'));
      expect(str, contains('lastKnownLocationTimestamp: null'));
    });
  });

  group('HomeStateSuccess', () {
    final now = DateTime(2025, 11, 24, 10, 0);
    const testLocation = LatLng(55.9533, -3.1883);
    final testFireRisk = FireRisk(
      level: RiskLevel.moderate,
      fwi: 15.0,
      source: DataSource.effis,
      observedAt: now.toUtc(),
      freshness: Freshness.live,
    );

    test('equality with all fields identical', () {
      final state1 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.gps,
        placeName: null,
      );
      final state2 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.gps,
        placeName: null,
      );

      expect(state1, equals(state2));
    });

    test('equality with placeName', () {
      final state1 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
        placeName: 'Edinburgh',
      );
      final state2 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
        placeName: 'Edinburgh',
      );

      expect(state1, equals(state2));
    });

    test('different when locationSource differs', () {
      final state1 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.gps,
      );
      final state2 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
      );

      expect(state1, isNot(equals(state2)));
    });

    test('different when placeName differs', () {
      final state1 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
        placeName: 'Edinburgh',
      );
      final state2 = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
        placeName: 'Glasgow',
      );

      expect(state1, isNot(equals(state2)));
    });

    test('props list includes all fields', () {
      final state = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
        placeName: 'Edinburgh',
        what3words: '///index.home.raft',
        formattedLocation: 'Near Aviemore, Highland',
        isWhat3wordsLoading: true,
        isGeocodingLoading: false,
      );

      expect(state.props, [
        testFireRisk,
        testLocation,
        now,
        LocationSource.manual,
        'Edinburgh',
        '///index.home.raft',
        'Near Aviemore, Highland',
        true,
        false,
      ]);
    });

    test('toString includes locationSource and placeName', () {
      final state = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
        placeName: 'Edinburgh City Centre',
      );

      final str = state.toString();

      expect(str, contains('source: LocationSource.manual'));
      expect(str, contains('placeName: Edinburgh City Centre'));
      expect(str, contains('location: $testLocation'));
    });

    test('toString with null placeName', () {
      final state = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.gps,
        placeName: null,
      );

      final str = state.toString();

      expect(str, contains('placeName: null'));
    });

    test('copyWith preserves existing values', () {
      final state = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.manual,
        placeName: 'Edinburgh',
        what3words: '///index.home.raft',
        formattedLocation: 'Near Aviemore',
        isWhat3wordsLoading: false,
        isGeocodingLoading: false,
      );

      final copied = state.copyWith();

      expect(copied, equals(state));
    });

    test('copyWith updates what3words', () {
      final state = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.gps,
        isWhat3wordsLoading: true,
      );

      final updated = state.copyWith(
        what3words: '///filled.count.soap',
        isWhat3wordsLoading: false,
      );

      expect(updated.what3words, equals('///filled.count.soap'));
      expect(updated.isWhat3wordsLoading, isFalse);
      // Other fields unchanged
      expect(updated.location, equals(testLocation));
      expect(updated.locationSource, equals(LocationSource.gps));
    });

    test('copyWith updates formattedLocation', () {
      final state = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.gps,
        isGeocodingLoading: true,
      );

      final updated = state.copyWith(
        formattedLocation: 'Near Glasgow',
        isGeocodingLoading: false,
      );

      expect(updated.formattedLocation, equals('Near Glasgow'));
      expect(updated.isGeocodingLoading, isFalse);
    });

    test('toString redacts what3words for privacy', () {
      final state = HomeStateSuccess(
        riskData: testFireRisk,
        location: testLocation,
        lastUpdated: now,
        locationSource: LocationSource.gps,
        what3words: '///sensitive.address.here',
      );

      final str = state.toString();

      expect(str, contains('what3words: [REDACTED]'));
      expect(str, isNot(contains('sensitive.address.here')));
    });
  });

  group('HomeStateError', () {
    const testLocation = LatLng(55.9533, -3.1883);
    final testFireRisk = FireRisk(
      level: RiskLevel.moderate,
      fwi: 15.0,
      source: DataSource.cache,
      observedAt: DateTime.now().toUtc(),
      freshness: Freshness.cached,
    );

    test('equality with cachedLocation', () {
      final state1 = HomeStateError(
        errorMessage: 'Network error',
        cachedData: testFireRisk,
        cachedLocation: testLocation,
        canRetry: true,
      );
      final state2 = HomeStateError(
        errorMessage: 'Network error',
        cachedData: testFireRisk,
        cachedLocation: testLocation,
        canRetry: true,
      );

      expect(state1, equals(state2));
    });

    test('hasCachedData returns true when both data and location present', () {
      final state = HomeStateError(
        errorMessage: 'Error',
        cachedData: testFireRisk,
        cachedLocation: testLocation,
      );

      expect(state.hasCachedData, isTrue);
    });

    test('hasCachedData returns false when location missing', () {
      final state = HomeStateError(
        errorMessage: 'Error',
        cachedData: testFireRisk,
        cachedLocation: null,
      );

      expect(state.hasCachedData, isFalse);
    });

    test('hasCachedData returns false when data missing', () {
      const state = HomeStateError(
        errorMessage: 'Error',
        cachedData: null,
        cachedLocation: testLocation,
      );

      expect(state.hasCachedData, isFalse);
    });

    test('hasCachedData returns false when both missing', () {
      const state = HomeStateError(
        errorMessage: 'Error',
        cachedData: null,
        cachedLocation: null,
      );

      expect(state.hasCachedData, isFalse);
    });

    test('toString includes hasCachedData status', () {
      final stateWithCache = HomeStateError(
        errorMessage: 'Network error',
        cachedData: testFireRisk,
        cachedLocation: testLocation,
      );

      final strWithCache = stateWithCache.toString();
      expect(strWithCache, contains('hasCachedData: true'));

      const stateWithoutCache = HomeStateError(errorMessage: 'Network error');

      final strWithoutCache = stateWithoutCache.toString();
      expect(strWithoutCache, contains('hasCachedData: false'));
    });
  });
}
