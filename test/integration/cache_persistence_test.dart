import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildfire_mvp_v3/services/cache/fire_risk_cache_impl.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/utils/clock.dart';

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
  // Initialize Flutter binding for SharedPreferences platform channel
  WidgetsFlutterBinding.ensureInitialized();

  group('Cache Persistence Integration', () {
    late FireRisk testFireRisk;
    late FakeClock fakeClock;

    setUp(() {
      // Create test FireRisk data
      testFireRisk = FireRisk(
        level: RiskLevel.high,
        fwi: 75.5,
        source: DataSource.effis,
        freshness: Freshness.live,
        observedAt: DateTime.utc(2025, 10, 4, 12, 0, 0),
      );

      // Create fake clock
      fakeClock = FakeClock(DateTime.utc(2025, 10, 4, 12, 0, 0));
    });

    test(
        'set FireRisk; create a new FireRiskCacheImpl with a fresh SharedPreferences (same mock storage map); get returns some(); freshness==cached',
        () async {
      // Initialize SharedPreferences with empty mock data
      final mockData = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockData);

      // Create first cache instance and store data
      final prefs1 = await SharedPreferences.getInstance();
      final cache1 = FireRiskCacheImpl(prefs: prefs1, clock: fakeClock);

      final setResult =
          await cache1.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
      expect(setResult.isRight(), true);

      // Create second cache instance with same mock storage
      // Note: SharedPreferences.getInstance() returns same instance with same mock data
      final prefs2 = await SharedPreferences.getInstance();
      final cache2 = FireRiskCacheImpl(prefs: prefs2, clock: fakeClock);

      // Retrieve data from second cache instance
      final cached = await cache2.get('gcvwr');

      expect(cached.isSome(), true);
      cached.fold(
        () => fail('Expected cached data to persist'),
        (fireRisk) {
          expect(fireRisk.freshness, Freshness.cached);
          expect(fireRisk.level, testFireRisk.level);
          expect(fireRisk.fwi, testFireRisk.fwi);
          expect(fireRisk.source, testFireRisk.source);
        },
      );
    });

    test('cached data survives within same SharedPreferences instance',
        () async {
      // Initialize with empty mock data
      SharedPreferences.setMockInitialValues(<String, Object>{});

      // First cache instance - store data
      final prefs = await SharedPreferences.getInstance();
      final cache1 = FireRiskCacheImpl(prefs: prefs, clock: fakeClock);

      await cache1.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
      await cache1.set(
          lat: 55.8642, lon: -4.2518, data: testFireRisk); // Glasgow

      // Second cache instance using same SharedPreferences instance
      final cache2 = FireRiskCacheImpl(prefs: prefs, clock: fakeClock);

      // Verify both entries persist across cache instances
      final edinburgh = await cache2.get('gcvwr'); // Edinburgh
      final glasgow = await cache2.get('gcuvz'); // Glasgow

      expect(edinburgh.isSome(), true);
      expect(glasgow.isSome(), true);

      // Verify metadata consistency
      final metadata = await cache2.getMetadata();
      expect(metadata.totalEntries, greaterThan(0));
    });

    test('cache persistence works with TTL expiration', () async {
      final mockData = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockData);

      // Store data at T=0
      final prefs1 = await SharedPreferences.getInstance();
      final cache1 = FireRiskCacheImpl(prefs: prefs1, clock: fakeClock);
      await cache1.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);

      // Advance time past TTL
      fakeClock.advance(const Duration(hours: 7));

      // Create new cache instance with same persistent data
      SharedPreferences.setMockInitialValues(Map.from(mockData));
      final prefs2 = await SharedPreferences.getInstance();
      final cache2 = FireRiskCacheImpl(prefs: prefs2, clock: fakeClock);

      // Should return cache miss due to expiration
      final cached = await cache2.get('gcvwr');
      expect(cached.isNone(), true);

      // Metadata should reflect cleanup
      final metadata = await cache2.getMetadata();
      expect(metadata.totalEntries, 0);
    });

    test('cache operations work consistently across instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      // First cache - store multiple entries
      final prefs = await SharedPreferences.getInstance();
      final cache1 = FireRiskCacheImpl(prefs: prefs, clock: fakeClock);

      await cache1.set(lat: 55.0, lon: -3.0, data: testFireRisk);
      await cache1.set(lat: 56.0, lon: -3.0, data: testFireRisk);

      // Access first entry to update LRU tracking
      final firstAccess = await cache1.get('gcvbg'); // First entry geohash
      expect(firstAccess.isSome(), true);

      // Advance time slightly
      fakeClock.advance(const Duration(minutes: 30));

      // Second cache instance using same SharedPreferences
      final cache2 = FireRiskCacheImpl(prefs: prefs, clock: fakeClock);

      // Verify entries are accessible from second instance
      final entry1 = await cache2.get('gcvbg');
      final entry2 = await cache2.get('gcvye'); // Second entry geohash
      expect(entry1.isSome(), true);
      expect(entry2.isSome(), true);

      // Metadata should track the entries consistently
      final metadata1 = await cache1.getMetadata();
      final metadata2 = await cache2.getMetadata();
      expect(metadata1.totalEntries, metadata2.totalEntries);
      expect(metadata2.totalEntries, greaterThan(0));
    });

    test('corrupted cache data handled gracefully on persistence reload',
        () async {
      final mockData = <String, Object>{
        // Store valid entry
        'cache_entry_gcvwr':
            '{"version":"1.0","timestamp":${DateTime.utc(2025, 10, 4, 12, 0, 0).millisecondsSinceEpoch},"geohash":"gcvwr","data":{"level":"high","fwi":75.5,"source":"effis","observedAt":${DateTime.utc(2025, 10, 4, 12, 0, 0).millisecondsSinceEpoch},"freshness":"live"}}',
        // Store corrupted entry
        'cache_entry_gcpue': 'invalid json',
        // Valid metadata
        'cache_metadata':
            '{"totalEntries":2,"lastCleanup":${DateTime.utc(2025, 10, 4, 12, 0, 0).millisecondsSinceEpoch},"accessLog":{}}'
      };

      SharedPreferences.setMockInitialValues(mockData);
      final prefs = await SharedPreferences.getInstance();
      final cache = FireRiskCacheImpl(prefs: prefs, clock: fakeClock);

      // Valid entry should work
      final valid = await cache.get('gcvwr');
      expect(valid.isSome(), true);

      // Corrupted entry should return cache miss gracefully
      final corrupted = await cache.get('gcpue');
      expect(corrupted.isNone(), true);
    });
  });
}
