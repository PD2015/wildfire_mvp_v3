import 'package:dartz/dartz.dart';
import '../models/cache_metadata.dart';
import 'cache/cache_error.dart';

/// Generic cache service interface with TTL and spatial keying support
///
/// Provides type-safe caching operations with geohash-based spatial locality,
/// 6-hour TTL enforcement, and LRU eviction policy.
abstract class CacheService<T> {
  /// Retrieve cached entry by geohash key
  ///
  /// Returns:
  /// - Some(T) if entry exists and is not expired
  /// - None() if entry missing, expired, or corrupted
  ///
  /// Performance target: <200ms
  Future<Option<T>> get(String geohashKey);

  /// Store entry with automatic geohash key generation
  ///
  /// Parameters:
  /// - [lat]: Latitude for geohash key generation
  /// - [lon]: Longitude for geohash key generation
  /// - [data]: Data to cache
  ///
  /// Behavior:
  /// - Generates geohash key at precision 5 (~4.9km)
  /// - Triggers LRU eviction if cache full (100 entries)
  /// - Updates access tracking for LRU policy
  ///
  /// Performance target: <100ms
  Future<Either<CacheError, void>> set({
    required double lat,
    required double lon,
    required T data,
  });

  /// Store entry with explicit geohash key
  ///
  /// Use for pre-computed keys or testing scenarios.
  ///
  /// Parameters:
  /// - [geohashKey]: Pre-computed geohash key
  /// - [data]: Data to cache
  Future<Either<CacheError, void>> setWithKey({
    required String geohashKey,
    required T data,
  });

  /// Remove specific cache entry
  ///
  /// Parameters:
  /// - [geohashKey]: Key of entry to remove
  ///
  /// Returns: true if entry was removed, false if not found
  Future<bool> remove(String geohashKey);

  /// Clear all cache entries and reset metadata
  ///
  /// Use for user privacy actions or storage corruption recovery.
  Future<void> clear();

  /// Get cache statistics for monitoring
  ///
  /// Returns metadata including:
  /// - Total entries count
  /// - Last cleanup timestamp
  /// - LRU access information
  Future<CacheMetadata> getMetadata();

  /// Force LRU cleanup of expired and least-accessed entries
  ///
  /// Removes:
  /// - All expired entries (TTL > 6 hours)
  /// - Oldest accessed entries if still over limit
  ///
  /// Performance target: <500ms
  ///
  /// Returns: Number of entries removed
  Future<int> cleanup();
}
