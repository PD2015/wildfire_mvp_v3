import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/cache_entry.dart';
import 'package:wildfire_mvp_v3/utils/clock.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/services/cache/cache_error.dart';

/// Fake clock for deterministic testing
class FakeClock implements Clock {
  DateTime _currentTime;

  FakeClock(this._currentTime) {
    if (!_currentTime.isUtc) {
      throw ArgumentError('FakeClock time must be UTC');
    }
  }

  @override
  DateTime nowUtc() => _currentTime;

  void setTime(DateTime newTime) {
    if (!newTime.isUtc) {
      throw ArgumentError('FakeClock time must be UTC');
    }
    _currentTime = newTime;
  }

  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }
}

void main() {
  group('CacheEntry', () {
    late FakeClock fakeClock;
    late FireRisk testFireRisk;
    late DateTime baseTime;

    setUp(() {
      baseTime = DateTime.utc(2025, 10, 4, 12, 0, 0);
      fakeClock = FakeClock(baseTime);
      testFireRisk = FireRisk.fromMock(
        level: RiskLevel.low,
        observedAt: baseTime,
      );
    });

    group('construction', () {
      test('creates entry with UTC timestamp', () {
        final entry = CacheEntry(
          data: testFireRisk,
          timestamp: baseTime,
          geohash: 'gcvwr',
        );

        expect(entry.data, equals(testFireRisk));
        expect(entry.timestamp, equals(baseTime));
        expect(entry.geohash, equals('gcvwr'));
        expect(entry.version, equals('1.0'));
      });

      test('now factory creates entry with current time from clock', () {
        final entry = CacheEntry.now(
          data: testFireRisk,
          geohash: 'gcvwr',
          clock: fakeClock,
        );

        expect(entry.timestamp, equals(baseTime));
        expect(entry.data, equals(testFireRisk));
        expect(entry.geohash, equals('gcvwr'));
      });
    });

    group('TTL behavior', () {
      test('isExpired returns false within 6 hour TTL', () {
        final entry = CacheEntry(
          data: testFireRisk,
          timestamp: baseTime,
          geohash: 'gcvwr',
        );

        // Test at various times within TTL
        fakeClock.setTime(baseTime.add(const Duration(hours: 1)));
        expect(entry.isExpired(fakeClock), isFalse);

        fakeClock.setTime(baseTime.add(const Duration(hours: 5, minutes: 59)));
        expect(entry.isExpired(fakeClock), isFalse);
      });

      test('isExpired returns true exactly at 6 hour boundary', () {
        final entry = CacheEntry(
          data: testFireRisk,
          timestamp: baseTime,
          geohash: 'gcvwr',
        );

        fakeClock.setTime(baseTime.add(const Duration(hours: 6)));
        expect(entry.isExpired(fakeClock), isFalse); // Exactly 6 hours

        fakeClock.setTime(baseTime.add(const Duration(hours: 6, milliseconds: 1)));
        expect(entry.isExpired(fakeClock), isTrue); // Just over 6 hours
      });

      test('isExpired returns true after 6 hour TTL', () {
        final entry = CacheEntry(
          data: testFireRisk,
          timestamp: baseTime,
          geohash: 'gcvwr',
        );

        fakeClock.setTime(baseTime.add(const Duration(hours: 7)));
        expect(entry.isExpired(fakeClock), isTrue);
        
        fakeClock.setTime(baseTime.add(const Duration(days: 1)));
        expect(entry.isExpired(fakeClock), isTrue);
      });

      test('age calculation uses clock correctly', () {
        final entry = CacheEntry(
          data: testFireRisk,
          timestamp: baseTime,
          geohash: 'gcvwr',
        );

        fakeClock.setTime(baseTime.add(const Duration(hours: 2, minutes: 30)));
        final age = entry.age(fakeClock);
        expect(age, equals(const Duration(hours: 2, minutes: 30)));
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields with version', () {
        final entry = CacheEntry(
          data: testFireRisk,
          timestamp: baseTime,
          geohash: 'gcvwr',
        );

        final json = entry.toJson((data) => data.toJson());

        expect(json['version'], equals('1.0'));
        expect(json['timestamp'], equals(baseTime.millisecondsSinceEpoch));
        expect(json['geohash'], equals('gcvwr'));
        expect(json['data'], isA<Map<String, dynamic>>());
      });

      test('fromJson recreates equivalent entry', () {
        final originalEntry = CacheEntry(
          data: testFireRisk,
          timestamp: baseTime,
          geohash: 'gcvwr',
        );

        final json = originalEntry.toJson((data) => data.toJson());
        final recreatedEntry = CacheEntry.fromJson(
          json,
          (data) => FireRisk.fromJson(data),
        );

        expect(recreatedEntry, equals(originalEntry));
      });

      test('fromJson throws UnsupportedVersionError for unsupported version',
          () {
        final json = {
          'version': '2.0',
          'timestamp': baseTime.millisecondsSinceEpoch,
          'geohash': 'gcvwr',
          'data': testFireRisk.toJson(),
        };

        expect(
          () => CacheEntry.fromJson(json, (data) => FireRisk.fromJson(data)),
          throwsA(isA<UnsupportedVersionError>()),
        );
      });

      test('fromJson throws SerializationError for malformed JSON', () {
        final json = {
          'version': '1.0',
          'timestamp': 'invalid',
          'geohash': 'gcvwr',
          'data': testFireRisk.toJson(),
        };

        expect(
          () => CacheEntry.fromJson(json, (data) => FireRisk.fromJson(data)),
          throwsA(isA<SerializationError>()),
        );
      });

      test('fromJson handles missing version field', () {
        final json = {
          'timestamp': baseTime.millisecondsSinceEpoch,
          'geohash': 'gcvwr',
          'data': testFireRisk.toJson(),
        };

        final entry =
            CacheEntry.fromJson(json, (data) => FireRisk.fromJson(data));
        expect(entry.version, equals('1.0')); // Default version
      });
    });

    group('UTC timestamp assertions', () {
      test('age() asserts UTC timestamp', () {
        final nonUtcTimestamp = DateTime(2025, 10, 4, 12, 0, 0); // Local time
        final entry = CacheEntry(
          data: testFireRisk,
          timestamp: nonUtcTimestamp,
          geohash: 'gcvwr',
        );

        expect(() => entry.age(fakeClock), throwsAssertionError);
      });
    });
  });
}
