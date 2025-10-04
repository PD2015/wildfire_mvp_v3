# CacheService<T> Interface Contract

**Feature**: A5 CacheService with 6-hour TTL and geohash-based spatial keying  
**Contract Date**: 2025-10-04  
**Context**: Generic cache service interface for type-safe caching operations

---

## Core Interface

```dart
import 'package:dartz/dartz.dart';

/// Generic cache service interface with TTL and spatial keying support
abstract class CacheService<T> {
  /// Retrieve cached entry by geohash key
  /// 
  /// Returns:
  /// - Some(T) if entry exists and is not expired
  /// - None() if entry missing, expired, or corrupted
  /// 
  /// Performance: <200ms target
  Future<Option<T>> get(String geohashKey);

  /// Store entry with automatic geohash key generation
  /// 
  /// Parameters:
  /// - lat/lon: Coordinates for geohash key generation
  /// - data: Data to cache
  /// 
  /// Behavior:
  /// - Generates geohash key at precision 5 (~4.9km)
  /// - Triggers LRU eviction if cache full (100 entries)
  /// - Updates access tracking for LRU policy
  /// 
  /// Performance: <100ms target
  Future<Either<CacheError, void>> set({
    required double lat,
    required double lon, 
    required T data,
  });

  /// Store entry with explicit geohash key
  /// 
  /// Use for pre-computed keys or testing scenarios
  Future<Either<CacheError, void>> setWithKey(String geohashKey, T data);

  /// Remove specific cache entry
  /// 
  /// Returns true if entry was removed, false if not found
  Future<bool> remove(String geohashKey);

  /// Clear all cache entries and reset metadata
  /// 
  /// Use for user privacy actions or storage corruption recovery
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
  /// Performance: <500ms target
  Future<int> cleanup();
}
```

---

## Type-Safe Implementations

### FireRiskCache Interface
Specific contract for FireRisk data caching.

```dart
import 'package:dartz/dartz.dart';
import '../models/fire_risk.dart';

/// FireRisk-specific cache service
abstract class FireRiskCache extends CacheService<FireRisk> {
  /// Get cached fire risk with freshness marking
  /// 
  /// Returns FireRisk with freshness set to 'cached' on successful hit
  @override
  Future<Option<FireRisk>> get(String geohashKey);

  /// Cache fire risk data with geohash spatial indexing
  /// 
  /// Automatically generates geohash key from coordinates
  @override
  Future<Either<CacheError, void>> set({
    required double lat,
    required double lon,
    required FireRisk data,
  });

  /// Get fire risk for coordinates (convenience method)
  /// 
  /// Generates geohash key internally and retrieves cached data
  Future<Option<FireRisk>> getForCoordinates(double lat, double lon);

  /// Cache fire risk for coordinates (convenience method)
  /// 
  /// Generates geohash key internally and stores data
  Future<Either<CacheError, void>> cacheForCoordinates({
    required double lat,
    required double lon,
    required FireRisk fireRisk,
  });
}
```

---

## Contract Guarantees

### Performance Contracts
```dart
/// Performance expectations for cache operations
class CachePerformanceContract {
  // Read operations must complete within 200ms
  static const Duration maxReadTime = Duration(milliseconds: 200);
  
  // Write operations must complete within 100ms  
  static const Duration maxWriteTime = Duration(milliseconds: 100);
  
  // Cleanup operations must complete within 500ms
  static const Duration maxCleanupTime = Duration(milliseconds: 500);
  
  // Cache hit rate should exceed 70% under normal usage
  static const double minHitRate = 0.70;
}
```

### Reliability Contracts
```dart
/// Reliability guarantees for cache behavior
class CacheReliabilityContract {
  // Cache failures must not prevent fresh data retrieval
  static const bool failureMustNotBlock = true;
  
  // Expired entries must never be returned as valid
  static const bool expiredEntriesInvalid = true;
  
  // Cache must handle corruption gracefully
  static const bool corruptionMustNotCrash = true;
  
  // Cache must enforce size limits (max 100 entries)
  static const int maxEntries = 100;
  static const bool sizeLimitEnforced = true;
}
```

### Privacy Contracts
```dart  
/// Privacy compliance for cache operations
class CachePrivacyContract {
  // Raw coordinates must not appear in logs
  static const bool coordinatesRedacted = true;
  
  // Geohash keys provide spatial privacy (4.9km resolution)
  static const double geohashResolutionKm = 4.9;
  
  // Cache must support complete data clearing
  static const bool clearingSupported = true;
  
  // No sensitive data beyond fire risk levels
  static const bool noSensitiveData = true;
}
```

---

## Error Handling Contracts

### CacheError Hierarchy
```dart
/// Required error types for cache operations
sealed class CacheError extends Equatable {
  const CacheError();
  
  // Must provide user-friendly error messages
  String get userMessage;
  
  // Must provide technical details for logging
  String get technicalDetails;
  
  // Must indicate if operation can be retried
  bool get isRetryable;
}

class CacheCorruptionError extends CacheError {
  const CacheCorruptionError(this.key, this.details);
  
  final String key;
  final String details;
  
  @override
  String get userMessage => 'Cache data corruption detected';
  
  @override
  String get technicalDetails => 'Key: $key, Details: $details';
  
  @override
  bool get isRetryable => false; // Corruption requires manual intervention
  
  @override
  List<Object?> get props => [key, details];
}

class CacheStorageError extends CacheError {
  const CacheStorageError(this.operation, this.details);
  
  final String operation;
  final String details;
  
  @override
  String get userMessage => 'Cache storage temporarily unavailable';
  
  @override
  String get technicalDetails => 'Operation: $operation, Details: $details';
  
  @override
  bool get isRetryable => true; // Storage errors may be transient
  
  @override
  List<Object?> get props => [operation, details];
}
```

---

## Integration Contracts

### FireRiskService Integration
```dart
/// Contract for FireRiskService cache integration
class FireRiskServiceCacheContract {
  /// Cache must integrate as optional dependency
  static const bool optionalDependency = true;
  
  /// Cache must fit in fallback chain between SEPA and Mock
  static const int fallbackOrder = 3; // [1=EFFIS, 2=SEPA, 3=Cache, 4=Mock]
  
  /// Cache hits must be marked with 'cached' freshness
  static const Freshness cacheHitFreshness = Freshness.cached;
  
  /// Cache misses must fall through to next service
  static const bool cacheMissFallthrough = true;
  
  /// Cache failures must not break fallback chain
  static const bool failureTransparent = true;
}
```

### LocationResolver Integration
```dart
/// Contract for LocationResolver coordinate integration  
class LocationCacheIntegrationContract {
  /// Must use same coordinate privacy utilities
  static const bool useLocationUtilsLogRedact = true;
  
  /// Must handle manual location coordinates
  static const bool supportManualCoordinates = true;
  
  /// Must handle GPS and cached coordinates equally
  static const bool coordinateSourceAgnostic = true;
  
  /// Must work with Scotland centroid fallback
  static const bool supportDefaultCoordinates = true;
}
```

---

## Testing Contracts

### Unit Test Requirements
```dart
/// Unit test coverage requirements for cache implementations
class CacheTestContract {
  // Minimum test coverage percentage
  static const double minCoverage = 95.0;
  
  // Required test scenarios
  static const List<String> requiredScenarios = [
    'cache_hit_returns_cached_data',
    'cache_miss_returns_none', 
    'expired_entry_returns_none',
    'ttl_enforcement_accurate',
    'lru_eviction_correct_victim',
    'corruption_handling_graceful',
    'storage_error_recovery',
    'geohash_key_generation',
    'size_limit_enforcement',
    'access_tracking_updated',
  ];
  
  // Performance validation requirements
  static const bool performanceTestsRequired = true;
  static const bool memoryLeakTestsRequired = true;
  static const bool concurrencyTestsRequired = false; // Single-threaded Flutter
}
```

### Integration Test Requirements
```dart
/// Integration test requirements for cache service
class CacheIntegrationTestContract {
  // Must test with real SharedPreferences
  static const bool realStorageRequired = true;
  
  // Must test app restart persistence  
  static const bool persistenceTestRequired = true;
  
  // Must test FireRiskService integration
  static const bool fallbackChainTestRequired = true;
  
  // Must test with realistic data volumes
  static const int minTestEntries = 150; // Above limit to test eviction
  
  // Must test with realistic geographic spread
  static const bool spatialTestRequired = true;
}
```

---

## Mock Contracts

### Test Double Requirements
```dart
/// Contract for cache service test doubles
abstract class MockCacheService<T> implements CacheService<T> {
  // Must allow controllable cache hits/misses
  void setNextResult(Option<T> result);
  
  // Must allow controllable errors
  void setNextError(CacheError error);
  
  // Must track method invocations for verification
  List<String> get methodCalls;
  
  // Must reset state between tests
  void reset();
  
  // Must simulate realistic timing for performance tests
  void setSimulatedLatency(Duration latency);
}
```