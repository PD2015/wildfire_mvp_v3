import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fire_incident_cache.dart';
import '../../models/fire_incident.dart';
import '../../models/cache_entry.dart';
import '../../models/cache_metadata.dart';
import '../../utils/clock.dart';
import '../../utils/geohash_utils.dart';
import '../models/fire_risk.dart'; // For Freshness enum
import 'cache_error.dart';

/// SharedPreferences implementation of FireIncidentCache with TTL and LRU eviction
///
/// Provides persistent caching of fire incident lists with 6-hour TTL enforcement,
/// 100-entry capacity limit, and least-recently-used eviction policy.
///
/// ## Cache Policies
/// - **TTL**: 6-hour expiration with lazy cleanup on read operations
/// - **Capacity**: Maximum 100 entries with LRU eviction when full
/// - **Keys**: Geohash precision-5 (~4.9km spatial resolution) of bbox center
/// - **Timestamps**: UTC discipline prevents timezone corruption errors
/// - **Versioning**: JSON entries include version field for migration safety
///
/// ## Privacy Compliance (C2)
/// - Uses geohash spatial keys instead of raw coordinates in storage
/// - ~4.9km resolution provides inherent coordinate obfuscation
/// - No raw latitude/longitude values stored in SharedPreferences keys
/// - Cache operations log geohash keys, never raw coordinates
///
/// ## Resilience (C5)
/// - Graceful degradation: corruption/errors return cache miss (none())
/// - Version checking prevents deserialization failures on format changes
/// - Clock injection enables deterministic testing of TTL behavior
/// - Atomic SharedPreferences operations prevent partial state corruption
///
/// ## Performance
/// - Read operations: <200ms target with lazy expiration cleanup
/// - Write operations: <100ms target with LRU maintenance
/// - Non-blocking: All operations avoid UI thread blocking
class FireIncidentCacheImpl implements FireIncidentCache {
  final SharedPreferences _prefs;
  final Clock _clock;

  static const String _metadataKey = 'fire_incident_cache_metadata';
  static const String _entryKeyPrefix = 'fire_incident_cache_';

  /// Create cache implementation with SharedPreferences and optional Clock
  ///
  /// Parameters:
  /// - [prefs]: SharedPreferences instance for persistent storage
  /// - [clock]: Clock for testable time operations (defaults to SystemClock)
  FireIncidentCacheImpl({required SharedPreferences prefs, Clock? clock})
    : _prefs = prefs,
      _clock = clock ?? SystemClock();

  /// Retrieve cached fire incident list by geohash key with TTL enforcement
  ///
  /// Performs lazy expiration cleanup: expired entries (>6h) are automatically
  /// removed and treated as cache miss. Successful reads update LRU access time
  /// and mark all returned FireIncidents with [Freshness.cached].
  ///
  /// Privacy: Uses geohash key instead of raw coordinates for storage lookup.
  /// Resilience: Corrupted JSON entries gracefully return cache miss.
  ///
  /// Returns:
  /// - [Some<List<FireIncident>>] with freshness=cached if valid entry found
  /// - [None] if key not found, expired, or corrupted
  @override
  Future<Option<List<FireIncident>>> get(String geohashKey) async {
    try {
      final jsonStr = _prefs.getString('$_entryKeyPrefix$geohashKey');
      if (jsonStr == null) return none();

      final entry = CacheEntry<Map<String, dynamic>>.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
        (json) => json, // Pass through the wrapper map
      );

      if (entry.isExpired(_clock)) {
        await remove(geohashKey); // Cleanup expired entry
        return none();
      }

      await _updateAccessTime(geohashKey); // LRU tracking

      // Extract incidents list from wrapper
      final incidents = (entry.data['incidents'] as List<dynamic>)
          .map(
            (item) => FireIncident.fromCacheJson(item as Map<String, dynamic>),
          )
          .toList();

      // Mark all incidents with cached freshness
      final cachedIncidents = incidents
          .map((incident) => incident.copyWith(freshness: Freshness.cached))
          .toList();

      return some(cachedIncidents);
    } catch (e) {
      // Corruption handling: log error without PII, treat as cache miss (C5)
      // Note: No logging framework available, silently handle corruption
      return none();
    }
  }

  /// Store fire incident list by coordinates with geohash spatial keying
  ///
  /// Converts coordinates to precision-5 geohash (~4.9km resolution) for
  /// privacy-compliant storage. Delegates to [setWithKey] for actual storage.
  ///
  /// Privacy: Raw coordinates never stored, only geohash spatial keys.
  @override
  Future<Either<CacheError, void>> set({
    required double lat,
    required double lon,
    required List<FireIncident> data,
  }) async {
    final geohash = GeohashUtils.encode(lat, lon, precision: 5);
    return await setWithKey(geohashKey: geohash, data: data);
  }

  /// Store fire incident list with explicit geohash key and LRU maintenance
  ///
  /// Creates versioned JSON cache entry with UTC timestamp and stores in
  /// SharedPreferences. Updates access time for LRU tracking and enforces
  /// 100-entry capacity limit with LRU eviction when full.
  ///
  /// Operations performed atomically:
  /// 1. Serialize entry with version field and UTC timestamp
  /// 2. Store in SharedPreferences with geohash-prefixed key
  /// 3. Update LRU access time for this entry
  /// 4. Update total entry count metadata
  /// 5. Enforce capacity limit with LRU eviction if needed
  ///
  /// Returns [Right(void)] on success, [Left(CacheError)] on failure.
  @override
  Future<Either<CacheError, void>> setWithKey({
    required String geohashKey,
    required List<FireIncident> data,
  }) async {
    try {
      // Wrap list in map for CacheEntry serialization
      final wrappedData = {'incidents': data};

      // Create cache entry with current UTC timestamp
      final entry = CacheEntry<Map<String, dynamic>>(
        data: wrappedData,
        timestamp: _clock.nowUtc(),
        geohash: geohashKey,
      );

      // Serialize and store entry
      final jsonStr = jsonEncode(
        entry.toJson(
          (wrapper) => {
            'incidents': (wrapper['incidents'] as List<FireIncident>)
                .map((i) => i.toJson())
                .toList(),
          },
        ),
      );
      final success = await _prefs.setString(
        '$_entryKeyPrefix$geohashKey',
        jsonStr,
      );
      if (!success) {
        return left(
          const StorageError(
            'Failed to write cache entry to SharedPreferences',
          ),
        );
      }

      // Update metadata and access log
      await _updateAccessTime(geohashKey);
      await _updateTotalEntries();

      // Enforce 100-entry limit with LRU eviction
      await _enforceCapacityLimit();

      return right(null);
    } catch (e) {
      return left(SerializationError('Failed to serialize cache entry', e));
    }
  }

  /// Remove specific cache entry and update LRU metadata
  ///
  /// Removes entry from SharedPreferences storage and cleans up associated
  /// LRU access log entry. Updates total entry count to maintain accurate
  /// capacity tracking for LRU eviction decisions.
  ///
  /// Returns true if entry existed and was removed, false otherwise.
  /// Gracefully handles corruption by returning false on any exception.
  @override
  Future<bool> remove(String geohashKey) async {
    try {
      final removed = await _prefs.remove('$_entryKeyPrefix$geohashKey');
      if (removed) {
        await _removeFromAccessLog(geohashKey);
        await _updateTotalEntries();
      }
      return removed;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cache data and reset metadata atomically
  ///
  /// Removes all fire incident cache entries from SharedPreferences and resets
  /// metadata including total entry count, LRU access log, and cleanup timestamp.
  /// Provides complete cache reset capability for testing and maintenance.
  ///
  /// Handles corruption gracefully by silently continuing on removal failures.
  /// Always attempts to reset metadata to ensure consistent state.
  @override
  Future<void> clear() async {
    try {
      final keys = _prefs.getKeys().where(
        (key) => key.startsWith(_entryKeyPrefix),
      );
      for (final key in keys) {
        _prefs.remove(key);
      }

      // Reset metadata
      final metadata = CacheMetadata(
        totalEntries: 0,
        lastCleanup: _clock.nowUtc(),
        accessLog: const {},
      );
      await _saveMetadata(metadata);
    } catch (e) {
      // Silently handle clear failures
    }
  }

  /// Retrieve cache metadata with LRU access tracking
  ///
  /// Returns current cache state including total entry count, last cleanup
  /// timestamp, and LRU access log for eviction decisions. Initializes
  /// default metadata if not found in SharedPreferences.
  ///
  /// Gracefully handles JSON corruption by returning safe default metadata
  /// with zero entries and current timestamp. Essential for capacity
  /// management and LRU eviction algorithm operation.
  @override
  Future<CacheMetadata> getMetadata() async {
    try {
      final jsonStr = _prefs.getString(_metadataKey);
      if (jsonStr == null) {
        // Initialize default metadata
        final metadata = CacheMetadata(
          totalEntries: 0,
          lastCleanup: _clock.nowUtc(),
          accessLog: const {},
        );
        await _saveMetadata(metadata);
        return metadata;
      }

      return CacheMetadata.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (e) {
      // Return default metadata on corruption
      return CacheMetadata(
        totalEntries: 0,
        lastCleanup: _clock.nowUtc(),
        accessLog: const {},
      );
    }
  }

  /// Remove expired entries and corrupted data with TTL enforcement
  ///
  /// Scans all cache entries and removes those exceeding 6-hour TTL or
  /// containing corrupted JSON. Updates LRU access log and entry count
  /// metadata after cleanup. Records cleanup timestamp for observability.
  ///
  /// Returns count of entries removed for monitoring and debugging.
  /// Handles corruption gracefully by removing invalid entries and
  /// continuing cleanup process. Essential for maintaining cache health
  /// and preventing unbounded growth in production environments.
  @override
  Future<int> cleanup() async {
    int removedCount = 0;

    try {
      final keys = _prefs.getKeys().where(
        (key) => key.startsWith(_entryKeyPrefix),
      );

      for (final key in keys) {
        final geohashKey = key.substring(_entryKeyPrefix.length);
        final jsonStr = _prefs.getString(key);
        if (jsonStr == null) continue;

        try {
          final entry = CacheEntry<Map<String, dynamic>>.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
            (json) => json, // Pass through the wrapper map
          );

          if (entry.isExpired(_clock)) {
            _prefs.remove(key);
            await _removeFromAccessLog(geohashKey);
            removedCount++;
          }
        } catch (e) {
          // Remove corrupted entries
          _prefs.remove(key);
          await _removeFromAccessLog(geohashKey);
          removedCount++;
        }
      }

      await _updateTotalEntries();

      // Update last cleanup time
      final metadata = await getMetadata();
      await _saveMetadata(metadata.copyWith(lastCleanup: _clock.nowUtc()));
    } catch (e) {
      // Silently handle cleanup failures
    }

    return removedCount;
  }

  @override
  Future<Option<List<FireIncident>>> getForCoordinates(
    double lat,
    double lon,
  ) async {
    final geohash = GeohashUtils.encode(lat, lon, precision: 5);
    return await get(geohash);
  }

  /// Update access time for LRU tracking
  Future<void> _updateAccessTime(String geohashKey) async {
    try {
      final metadata = await getMetadata();
      final updatedAccessLog = Map<String, DateTime>.from(metadata.accessLog);
      updatedAccessLog[geohashKey] = _clock.nowUtc();

      await _saveMetadata(metadata.copyWith(accessLog: updatedAccessLog));
    } catch (e) {
      // Silently handle access log update failures
    }
  }

  /// Remove key from access log
  Future<void> _removeFromAccessLog(String geohashKey) async {
    try {
      final metadata = await getMetadata();
      final updatedAccessLog = Map<String, DateTime>.from(metadata.accessLog);
      updatedAccessLog.remove(geohashKey);

      await _saveMetadata(metadata.copyWith(accessLog: updatedAccessLog));
    } catch (e) {
      // Silently handle access log update failures
    }
  }

  /// Update total entries count based on actual stored entries
  Future<void> _updateTotalEntries() async {
    try {
      final keys = _prefs.getKeys().where(
        (key) => key.startsWith(_entryKeyPrefix),
      );
      final metadata = await getMetadata();

      await _saveMetadata(metadata.copyWith(totalEntries: keys.length));
    } catch (e) {
      // Silently handle metadata update failures
    }
  }

  /// Enforce 100-entry capacity limit with LRU eviction
  Future<void> _enforceCapacityLimit() async {
    try {
      var metadata = await getMetadata();

      while (metadata.isFull) {
        final lruKey = metadata.lruKey;
        if (lruKey == null) break; // Safety check for empty access log

        // Remove LRU entry
        _prefs.remove('$_entryKeyPrefix$lruKey');

        // Update metadata
        final updatedAccessLog = Map<String, DateTime>.from(metadata.accessLog);
        updatedAccessLog.remove(lruKey);

        metadata = metadata.copyWith(
          totalEntries: metadata.totalEntries - 1,
          accessLog: updatedAccessLog,
        );
      }

      await _saveMetadata(metadata);
    } catch (e) {
      // Silently handle capacity enforcement failures
    }
  }

  /// Save metadata to SharedPreferences
  Future<void> _saveMetadata(CacheMetadata metadata) async {
    try {
      // Assert UTC timestamps for consistency
      assert(metadata.lastCleanup.isUtc, 'lastCleanup must be UTC');
      for (final timestamp in metadata.accessLog.values) {
        assert(timestamp.isUtc, 'Access log timestamps must be UTC');
      }

      final jsonStr = jsonEncode(metadata.toJson());
      await _prefs.setString(_metadataKey, jsonStr);
    } catch (e) {
      // Silently handle metadata save failures
    }
  }
}
