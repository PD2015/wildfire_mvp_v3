import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildfire_mvp_v3/services/fire_incident_cache.dart';
import 'package:wildfire_mvp_v3/services/cache/fire_incident_cache_impl.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/utils/clock.dart';

void main() {
  group('FireIncidentCache Integration Tests (T018)', () {
    late SharedPreferences prefs;
    late FireIncidentCache cache;
    late TestClock clock;

    setUp(() async {
      // Initialize SharedPreferences with mock data
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      clock = TestClock();
      cache = FireIncidentCacheImpl(prefs: prefs, clock: clock);
    });

    tearDown(() async {
      await cache.clear();
    });

    test('cache stores and retrieves fire incident list with freshness=cached',
        () async {
      // Arrange: Create test incident list
      final incidents = [
        FireIncident(
          id: 'test1',
          location: const LatLng(55.9533, -3.1883), // Edinburgh
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime(2025, 1, 20, 12, 0, 0),
          intensity: 'moderate',
          description: 'Test fire 1',
          areaHectares: 15.5,
        ),
        FireIncident(
          id: 'test2',
          location: const LatLng(55.8642, -4.2518), // Glasgow
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime(2025, 1, 20, 13, 0, 0),
          intensity: 'high',
          description: 'Test fire 2',
          areaHectares: 42.3,
        ),
      ];

      // Act: Store in cache
      final setResult = await cache.set(
        lat: 55.9533,
        lon: -3.1883,
        data: incidents,
      );

      // Assert: Storage succeeded
      expect(setResult.isRight(), isTrue);

      // Act: Retrieve from cache
      final getResult = await cache.getForCoordinates(55.9533, -3.1883);

      // Assert: Cache hit with freshness=cached
      expect(getResult.isSome(), isTrue);
      final cachedIncidents = getResult.getOrElse(() => []);
      expect(cachedIncidents.length, 2);
      expect(cachedIncidents[0].freshness, Freshness.cached);
      expect(cachedIncidents[1].freshness, Freshness.cached);
      expect(cachedIncidents[0].id, 'test1');
      expect(cachedIncidents[1].id, 'test2');
      expect(cachedIncidents[0].intensity, 'moderate');
      expect(cachedIncidents[1].intensity, 'high');
    });

    test('cache respects 6-hour TTL', () async {
      // Arrange: Store incident at T=0
      final incidents = [
        FireIncident(
          id: 'test1',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime(2025, 1, 20, 12, 0, 0),
          intensity: 'low',
        ),
      ];

      await cache.set(lat: 55.9533, lon: -3.1883, data: incidents);

      // Act: Advance clock by 5 hours (within TTL)
      clock.advance(const Duration(hours: 5));

      // Assert: Cache hit (not expired)
      var result = await cache.getForCoordinates(55.9533, -3.1883);
      expect(result.isSome(), isTrue);

      // Act: Advance clock by 2 more hours (total 7 hours, exceeds TTL)
      clock.advance(const Duration(hours: 2));

      // Assert: Cache miss (expired)
      result = await cache.getForCoordinates(55.9533, -3.1883);
      expect(result.isNone(), isTrue);
    });

    test('cache uses geohash spatial keys (precision 5 = ~4.9km)', () async {
      // Arrange: Two locations in same geohash cell (precision 5)
      final incidents1 = [
        FireIncident(
          id: 'fire1',
          location: const LatLng(55.9533, -3.1883), // Edinburgh center
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime(2025, 1, 20, 12, 0, 0),
          intensity: 'low',
        ),
      ];

      // Edinburgh coordinates within same ~4.9km geohash cell
      final lat1 = 55.9533;
      final lon1 = -3.1883;
      final lat2 = 55.9550; // ~1.9km north
      final lon2 = -3.1900; // ~100m west

      // Act: Store at first location
      await cache.set(lat: lat1, lon: lon1, data: incidents1);

      // Assert: Retrieve at nearby location (same geohash cell)
      final result = await cache.getForCoordinates(lat2, lon2);
      expect(result.isSome(), isTrue,
          reason:
              'Coordinates within ~4.9km should share same geohash (precision 5)');
    });

    test('cache enforces 100-entry LRU eviction', () async {
      // Arrange: Fill cache with 100 entries (spread across different geohash cells)
      for (int i = 0; i < 100; i++) {
        final incidents = [
          FireIncident(
            id: 'fire_$i',
            location: LatLng(50.0 + i * 0.1, -5.0 + i * 0.1), // Larger spacing for unique geohashes
            source: DataSource.effis,
            freshness: Freshness.live,
            timestamp: DateTime(2025, 1, 20, 12, 0, 0),
            intensity: 'low',
          ),
        ];
        await cache.set(lat: 50.0 + i * 0.1, lon: -5.0 + i * 0.1, data: incidents);
      }

      // Access first entry to make it recently used
      await cache.getForCoordinates(50.0, -5.0);

      // Act: Add 101st entry (should trigger LRU eviction)
      final newIncident = [
        FireIncident(
          id: 'fire_new',
          location: const LatLng(60.0, 0.0),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime(2025, 1, 20, 12, 0, 0),
          intensity: 'low',
        ),
      ];
      await cache.set(lat: 60.0, lon: 0.0, data: newIncident);

      // Assert: Cache maintains 100-entry limit
      final metadata = await cache.getMetadata();
      expect(metadata.totalEntries, lessThanOrEqualTo(100));

      // Assert: First entry still exists (was recently accessed)
      final firstEntry = await cache.getForCoordinates(50.0, -5.0);
      expect(firstEntry.isSome(), isTrue,
          reason: 'Recently accessed entry should not be evicted');
    });

    test('cache gracefully handles empty incident list', () async {
      // Arrange: Empty incident list
      final emptyList = <FireIncident>[];

      // Act: Store empty list
      final setResult = await cache.set(
        lat: 55.9533,
        lon: -3.1883,
        data: emptyList,
      );

      // Assert: Storage succeeded
      expect(setResult.isRight(), isTrue);

      // Act: Retrieve empty list
      final getResult = await cache.getForCoordinates(55.9533, -3.1883);

      // Assert: Cache hit with empty list
      expect(getResult.isSome(), isTrue);
      expect(getResult.getOrElse(() => []).isEmpty, isTrue);
    });

    test('cache cleanup removes expired entries', () async {
      // Arrange: Add entry that will expire
      final incidents = [
        FireIncident(
          id: 'test1',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime(2025, 1, 20, 12, 0, 0),
          intensity: 'low',
        ),
      ];
      await cache.set(lat: 55.9533, lon: -3.1883, data: incidents);

      // Act: Advance clock beyond TTL
      clock.advance(const Duration(hours: 7));

      // Act: Run cleanup
      final removedCount = await cache.cleanup();

      // Assert: At least one entry removed (may be more due to metadata updates)
      expect(removedCount, greaterThanOrEqualTo(1));

      // Assert: Entry no longer retrievable
      final result = await cache.getForCoordinates(55.9533, -3.1883);
      expect(result.isNone(), isTrue);
    });
  });
}
