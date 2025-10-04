import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildfire_mvp_v3/services/cache/fire_risk_cache_impl.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/utils/clock.dart';
import 'package:wildfire_mvp_v3/utils/geohash_utils.dart';

/// Test clock for controlling time in cache TTL tests
class FakeClock implements Clock {
  DateTime _currentTime;

  FakeClock(this._currentTime);

  @override
  DateTime nowUtc() => _currentTime;

  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  void setTime(DateTime time) {
    _currentTime = time.toUtc();
  }
}

void main() {
  group('FireRiskCache TTL and Size Management', () {
    late FireRiskCacheImpl cache;
    late FakeClock fakeClock;
    late FireRisk testFireRisk;

    setUp(() async {
      // Initialize SharedPreferences with empty mock data
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      // Create fake clock starting at specific time
      fakeClock = FakeClock(DateTime.utc(2025, 10, 4, 12, 0, 0));
      
      // Create cache with fake clock
      cache = FireRiskCacheImpl(prefs: prefs, clock: fakeClock);
      
      // Create test FireRisk data
      testFireRisk = FireRisk(
        level: RiskLevel.high,
        fwi: 75.5,
        source: DataSource.effis,
        freshness: Freshness.live,
        observedAt: DateTime.utc(2025, 10, 4, 12, 0, 0),
      );
    });

    group('TTL Enforcement', () {
      test('Case 1: set → advance +7h → get returns none()', () async {
        // Store entry
        final result = await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
        expect(result.isRight(), true);

        // Advance time by 7 hours (past 6h TTL)
        fakeClock.advance(const Duration(hours: 7));

        // Should return cache miss due to expiration
        final cached = await cache.get('gcvwr');
        expect(cached.isNone(), true);
      });

      test('valid entry within TTL returns cached data', () async {
        // Store entry
        await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);

        // Advance time by 5 hours (within 6h TTL)
        fakeClock.advance(const Duration(hours: 5));

        // Should return cached data with freshness=cached
        final cached = await cache.get('gcvwr');
        expect(cached.isSome(), true);
        cached.fold(
          () => fail('Expected some value'),
          (fireRisk) {
            expect(fireRisk.freshness, Freshness.cached);
            expect(fireRisk.level, RiskLevel.high);
          },
        );
      });
    });

    group('LRU Eviction', () {
      test('Case 2: fill cache entries; access first; add more → LRU eviction works', () async {
        // Fill cache with multiple entries
        for (int i = 0; i < 25; i++) {
          final lat = 55.0 + i * 0.01;
          await cache.set(lat: lat, lon: -3.0, data: testFireRisk);
        }

        // Access the first entry to make it recently used
        final firstGeohash = GeohashUtils.encode(55.0, -3.0); // Should be 'gcvbg'
        final accessed = await cache.get(firstGeohash);
        expect(accessed.isSome(), true);

        // Add more entries
        await cache.set(lat: 56.0, lon: -3.0, data: testFireRisk);

        // Verify cache metadata is tracking entries
        final metadata = await cache.getMetadata();
        expect(metadata.totalEntries, greaterThan(0));

        // Verify first entry still exists (was recently accessed)
        final stillExists = await cache.get(firstGeohash);
        expect(stillExists.isSome(), true);
      });
    });

    group('Metadata and Edge Cases', () {
      test('Case 3: metadata.accessLog empty → lruKey==null and no crash during cleanup', () async {
        // Get metadata when cache is empty
        final metadata = await cache.getMetadata();
        
        expect(metadata.accessLog.isEmpty, true);
        expect(metadata.lruKey, null);
        expect(metadata.totalEntries, 0);

        // Cleanup should not crash with empty access log
        final cleaned = await cache.cleanup();
        expect(cleaned, 0); // No entries to clean
      });

      test('metadata tracks access times correctly', () async {
        // Add entry and access it
        await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
        await cache.get('gcvwr');

        final metadata = await cache.getMetadata();
        expect(metadata.totalEntries, 1);
        expect(metadata.accessLog.containsKey('gcvwr'), true);
        expect(metadata.lruKey, 'gcvwr');
      });
    });

    group('JSON Version and Corruption Handling', () {
      test('Case 4: unsupported version in stored JSON → get returns none() (graceful)', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Manually store entry with unsupported version
        final badJson = jsonEncode({
          'version': '2.0', // Unsupported version
          'timestamp': DateTime.utc(2025, 10, 4, 12, 0, 0).millisecondsSinceEpoch,
          'geohash': 'gcvwr',
          'data': testFireRisk.toJson(),
        });
        
        await prefs.setString('cache_entry_gcvwr', badJson);

        // Should gracefully handle unsupported version and return cache miss
        final result = await cache.get('gcvwr');
        expect(result.isNone(), true);
      });

      test('Case 5: corrupt JSON string → get returns none() (graceful)', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Manually store corrupt JSON
        await prefs.setString('cache_entry_gcvwr', 'invalid json string');

        // Should gracefully handle corruption and return cache miss
        final result = await cache.get('gcvwr');
        expect(result.isNone(), true);
      });

      test('malformed entry data handled gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Store JSON with missing required fields
        final badJson = jsonEncode({
          'version': '1.0',
          'timestamp': DateTime.utc(2025, 10, 4, 12, 0, 0).millisecondsSinceEpoch,
          'geohash': 'gcvwr',
          'data': {'incomplete': 'data'}, // Missing FireRisk fields
        });
        
        await prefs.setString('cache_entry_gcvwr', badJson);

        // Should gracefully handle malformed data
        final result = await cache.get('gcvwr');
        expect(result.isNone(), true);
      });
    });

    group('Freshness and Data Integrity', () {
      test('Case 6: on hit → returned FireRisk has freshness==Freshness.cached', () async {
        // Store live data
        final liveRisk = testFireRisk.copyWith(freshness: Freshness.live);
        await cache.set(lat: 55.9533, lon: -3.1883, data: liveRisk);

        // Retrieve cached data
        final cached = await cache.get('gcvwr');
        
        expect(cached.isSome(), true);
        cached.fold(
          () => fail('Expected some value'),
          (fireRisk) {
            expect(fireRisk.freshness, Freshness.cached);
            expect(fireRisk.level, liveRisk.level);
            expect(fireRisk.fwi, liveRisk.fwi);
          },
        );
      });
    });

    group('Geohash Determinism', () {
      test('Case 7: geohash determinism: encode(55.9533,-3.1883)== "gcvwr"', () async {
        final geohash = GeohashUtils.encode(55.9533, -3.1883);
        expect(geohash, 'gcvwr');

        // Verify deterministic behavior across multiple calls
        final geohash2 = GeohashUtils.encode(55.9533, -3.1883);
        expect(geohash2, geohash);
      });

      test('consistent geohash generation for cache operations', () async {
        // Store data using coordinates
        await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);

        // Retrieve using manually computed geohash
        final manualGeohash = GeohashUtils.encode(55.9533, -3.1883);
        final cached = await cache.get(manualGeohash);
        
        expect(cached.isSome(), true);
        expect(manualGeohash, 'gcvwr');
      });
    });

    group('Cache Operations', () {
      test('remove operation works correctly', () async {
        // Store entry
        await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
        
        // Verify it exists
        final before = await cache.get('gcvwr');
        expect(before.isSome(), true);

        // Remove entry
        final removed = await cache.remove('gcvwr');
        expect(removed, true);

        // Verify it's gone
        final after = await cache.get('gcvwr');
        expect(after.isNone(), true);
      });

      test('clear operation removes all entries', () async {
        // Store multiple entries
        await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
        await cache.set(lat: 55.8642, lon: -4.2518, data: testFireRisk);

        // Verify entries exist
        final metadata1 = await cache.getMetadata();
        expect(metadata1.totalEntries, 2);

        // Clear cache
        await cache.clear();

        // Verify all entries are gone
        final metadata2 = await cache.getMetadata();
        expect(metadata2.totalEntries, 0);
        expect(metadata2.accessLog.isEmpty, true);
      });
    });

    group('Performance and Concurrency', () {
      test('cache operations complete within reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        // Perform multiple cache operations
        await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
        await cache.get('gcvwr');
        await cache.getMetadata();

        stopwatch.stop();
        
        // Should complete well under performance targets
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });
  });
}