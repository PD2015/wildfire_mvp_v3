import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fire_risk_cache.dart';
import '../models/fire_risk.dart';
import '../../models/cache_entry.dart';
import '../../models/cache_metadata.dart';
import '../../utils/clock.dart';
import '../../utils/geohash_utils.dart';
import 'cache_error.dart';

/// SharedPreferences implementation of FireRiskCache with TTL and LRU eviction
///
/// Provides persistent caching of FireRisk data with 6-hour TTL enforcement,
/// 100-entry capacity limit, and least-recently-used eviction policy.
class FireRiskCacheImpl implements FireRiskCache {
  final SharedPreferences _prefs;
  final Clock _clock;

  static const String _metadataKey = 'cache_metadata';
  static const String _entryKeyPrefix = 'cache_entry_';

  /// Create cache implementation with SharedPreferences and optional Clock
  ///
  /// Parameters:
  /// - [prefs]: SharedPreferences instance for persistent storage
  /// - [clock]: Clock for testable time operations (defaults to SystemClock)
  FireRiskCacheImpl({
    required SharedPreferences prefs,
    Clock? clock,
  })  : _prefs = prefs,
        _clock = clock ?? SystemClock();

  @override
  Future<Option<FireRisk>> get(String geohashKey) async {
    try {
      final jsonStr = _prefs.getString('$_entryKeyPrefix$geohashKey');
      if (jsonStr == null) return none();

      final entry = CacheEntry.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
        FireRisk.fromJson,
      );

      if (entry.isExpired(_clock)) {
        await remove(geohashKey); // Cleanup expired entry
        return none();
      }

      await _updateAccessTime(geohashKey); // LRU tracking
      final cachedRisk = entry.data.copyWith(freshness: Freshness.cached);
      return some(cachedRisk);
    } catch (e) {
      // Corruption handling: log error without PII, treat as cache miss (C5)
      // Note: No logging framework available, silently handle corruption
      return none();
    }
  }

  @override
  Future<Either<CacheError, void>> set({
    required double lat,
    required double lon,
    required FireRisk data,
  }) async {
    final geohash = GeohashUtils.encode(lat, lon, precision: 5);
    return await setWithKey(geohashKey: geohash, data: data);
  }

  @override
  Future<Either<CacheError, void>> setWithKey({
    required String geohashKey,
    required FireRisk data,
  }) async {
    try {
      // Create cache entry with current UTC timestamp
      final entry = CacheEntry(
        data: data,
        timestamp: _clock.nowUtc(),
        geohash: geohashKey,
      );

      // Serialize and store entry
      final jsonStr = jsonEncode(entry.toJson((data) => data.toJson()));
      final success =
          await _prefs.setString('$_entryKeyPrefix$geohashKey', jsonStr);
      if (!success) {
        return left(const StorageError(
            'Failed to write cache entry to SharedPreferences'));
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

  @override
  Future<void> clear() async {
    try {
      final keys =
          _prefs.getKeys().where((key) => key.startsWith(_entryKeyPrefix));
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
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      // Return default metadata on corruption
      return CacheMetadata(
        totalEntries: 0,
        lastCleanup: _clock.nowUtc(),
        accessLog: const {},
      );
    }
  }

  @override
  Future<int> cleanup() async {
    int removedCount = 0;

    try {
      final keys =
          _prefs.getKeys().where((key) => key.startsWith(_entryKeyPrefix));

      for (final key in keys) {
        final geohashKey = key.substring(_entryKeyPrefix.length);
        final jsonStr = _prefs.getString(key);
        if (jsonStr == null) continue;

        try {
          final entry = CacheEntry.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
            FireRisk.fromJson,
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
  Future<Option<FireRisk>> getForCoordinates(double lat, double lon) async {
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
      final keys =
          _prefs.getKeys().where((key) => key.startsWith(_entryKeyPrefix));
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
