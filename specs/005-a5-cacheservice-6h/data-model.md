# Data Model: CacheService Entities

**Feature**: A5 CacheService with 6-hour TTL and geohash-based spatial keying  
**Model Date**: 2025-10-04  
**Context**: Cache entry structures and metadata for FireRisk data persistence

---

## Core Entities

### CacheEntry<T>
Generic cache entry wrapper with TTL and versioning support.

```dart
import 'package:equatable/equatable.dart';

class CacheEntry<T> extends Equatable {
  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.geohash,
    this.version = '1.0',
  });

  /// The cached data payload
  final T data;
  
  /// When this entry was cached (for TTL calculations)
  final DateTime timestamp;
  
  /// Geohash key for spatial locality (precision 5 = ~4.9km)
  final String geohash;
  
  /// Cache format version for future migrations
  final String version;

  /// Calculate age of this cache entry
  Duration get age => DateTime.now().difference(timestamp);
  
  /// Check if entry has expired (6 hour TTL)
  bool get isExpired => age > const Duration(hours: 6);
  
  /// Create cache entry with current timestamp
  factory CacheEntry.now({
    required T data,
    required String geohash,
    String version = '1.0',
  }) {
    return CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      geohash: geohash,
      version: version,
    );
  }

  /// Deserialize from JSON map
  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return CacheEntry(
      data: fromJsonT(json['data'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      geohash: json['geohash'] as String,
      version: json['version'] as String? ?? '1.0',
    );
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'version': version,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'geohash': geohash,
      'data': toJsonT(data),
    };
  }

  @override
  List<Object?> get props => [data, timestamp, geohash, version];
}
```

### CacheMetadata
Tracks cache state and access patterns for LRU eviction.

```dart
import 'package:equatable/equatable.dart';

class CacheMetadata extends Equatable {
  const CacheMetadata({
    required this.totalEntries,
    required this.lastCleanup,
    this.accessLog = const {},
  });

  /// Current number of entries in cache
  final int totalEntries;
  
  /// Last time LRU cleanup was performed
  final DateTime lastCleanup;
  
  /// Map of cache key → last access timestamp for LRU tracking
  final Map<String, DateTime> accessLog;

  /// Check if cache is at capacity (100 entries max)
  bool get isFull => totalEntries >= 100;
  
  /// Get oldest accessed cache key for LRU eviction
  String? get lruKey {
    if (accessLog.isEmpty) return null;
    
    return accessLog.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
  }

  /// Create initial metadata
  factory CacheMetadata.initial() {
    return CacheMetadata(
      totalEntries: 0,
      lastCleanup: DateTime.now(),
    );
  }

  /// Record access to a cache key
  CacheMetadata recordAccess(String key) {
    final updatedAccessLog = Map<String, DateTime>.from(accessLog);
    updatedAccessLog[key] = DateTime.now();
    
    return CacheMetadata(
      totalEntries: totalEntries,
      lastCleanup: lastCleanup,
      accessLog: updatedAccessLog,
    );
  }

  /// Remove key from access tracking
  CacheMetadata removeKey(String key) {
    final updatedAccessLog = Map<String, DateTime>.from(accessLog);
    updatedAccessLog.remove(key);
    
    return CacheMetadata(
      totalEntries: math.max(0, totalEntries - 1),
      lastCleanup: lastCleanup,
      accessLog: updatedAccessLog,
    );
  }

  /// Add new entry to cache
  CacheMetadata addEntry(String key) {
    final updatedAccessLog = Map<String, DateTime>.from(accessLog);
    updatedAccessLog[key] = DateTime.now();
    
    return CacheMetadata(
      totalEntries: totalEntries + 1,
      lastCleanup: lastCleanup,
      accessLog: updatedAccessLog,
    );
  }

  /// Update cleanup timestamp
  CacheMetadata markCleaned() {
    return CacheMetadata(
      totalEntries: totalEntries,
      lastCleanup: DateTime.now(),
      accessLog: accessLog,
    );
  }

  /// Deserialize from JSON map
  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    final accessLogJson = json['accessLog'] as Map<String, dynamic>? ?? {};
    final accessLog = accessLogJson.map(
      (key, value) => MapEntry(
        key,
        DateTime.fromMillisecondsSinceEpoch(value as int),
      ),
    );

    return CacheMetadata(
      totalEntries: json['totalEntries'] as int,
      lastCleanup: DateTime.fromMillisecondsSinceEpoch(
        json['lastCleanup'] as int,
      ),
      accessLog: accessLog,
    );
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson() {
    final accessLogJson = accessLog.map(
      (key, value) => MapEntry(key, value.millisecondsSinceEpoch),
    );

    return {
      'totalEntries': totalEntries,
      'lastCleanup': lastCleanup.millisecondsSinceEpoch,
      'accessLog': accessLogJson,
    };
  }

  @override
  List<Object?> get props => [totalEntries, lastCleanup, accessLog];
}
```

---

## Value Objects

### GeohashKey
Type-safe wrapper for geohash cache keys.

```dart
import 'package:equatable/equatable.dart';

class GeohashKey extends Equatable {
  const GeohashKey._(this.value);

  /// The geohash string (precision 5, ~4.9km resolution)
  final String value;

  /// Create geohash from coordinates
  factory GeohashKey.fromCoordinates(double lat, double lon) {
    final geohash = GeohashUtils.encode(lat, lon, precision: 5);
    return GeohashKey._(geohash);
  }

  /// Create from existing geohash string (validation optional)
  factory GeohashKey.fromString(String geohash) {
    // Optional: validate geohash format
    if (geohash.length != 5) {
      throw ArgumentError('Invalid geohash length: expected 5, got ${geohash.length}');
    }
    return GeohashKey._(geohash);
  }

  /// Get the geographic bounds of this geohash
  GeohashBounds get bounds => GeohashUtils.bounds(value);

  @override
  String toString() => value;

  @override
  List<Object?> get props => [value];
}
```

### GeohashBounds
Represents the geographic bounding box of a geohash.

```dart
import 'package:equatable/equatable.dart';

class GeohashBounds extends Equatable {
  const GeohashBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  /// Check if coordinates fall within this bounding box
  bool contains(double lat, double lon) {
    return lat >= minLat && 
           lat <= maxLat && 
           lon >= minLon && 
           lon <= maxLon;
  }

  /// Calculate center point of bounding box
  LatLng get center {
    return LatLng(
      (minLat + maxLat) / 2,
      (minLon + maxLon) / 2,
    );
  }

  @override
  List<Object?> get props => [minLat, maxLat, minLon, maxLon];
}
```

---

## Error Types

### CacheError
Domain-specific errors for cache operations.

```dart
import 'package:equatable/equatable.dart';

sealed class CacheError extends Equatable {
  const CacheError();
}

class CacheCorruptionError extends CacheError {
  const CacheCorruptionError(this.key, this.details);
  
  final String key;
  final String details;
  
  @override
  List<Object?> get props => [key, details];
  
  @override
  String toString() => 'CacheCorruptionError: $key - $details';
}

class CacheStorageError extends CacheError {
  const CacheStorageError(this.operation, this.details);
  
  final String operation; // 'read', 'write', 'delete'
  final String details;
  
  @override
  List<Object?> get props => [operation, details];
  
  @override
  String toString() => 'CacheStorageError: $operation failed - $details';
}

class CacheVersionError extends CacheError {
  const CacheVersionError(this.expected, this.actual);
  
  final String expected;
  final String actual;
  
  @override
  List<Object?> get props => [expected, actual];
  
  @override
  String toString() => 'CacheVersionError: expected $expected, got $actual';
}
```

---

## Constants

### CacheConstants
Configuration constants for cache behavior.

```dart
class CacheConstants {
  // TTL Configuration
  static const Duration ttl = Duration(hours: 6);
  static const Duration cleanupInterval = Duration(hours: 1);
  
  // Size Limits
  static const int maxEntries = 100;
  static const int cleanupBatchSize = 10; // Remove 10 entries when full
  
  // Geohash Configuration  
  static const int geohashPrecision = 5; // ~4.9km resolution
  
  // Storage Keys
  static const String metadataKey = 'cache_metadata';
  static const String entryKeyPrefix = 'cache_entry_';
  
  // Version
  static const String currentVersion = '1.0';
  
  // Performance Targets
  static const Duration readTimeout = Duration(milliseconds: 200);
  static const Duration writeTimeout = Duration(milliseconds: 100);
}
```

---

## JSON Schema Examples

### CacheEntry JSON Format
```json
{
  "version": "1.0",
  "timestamp": 1696435200000,
  "geohash": "gcpue",
  "data": {
    "level": "moderate", 
    "source": "effis",
    "freshness": "live",
    "observedAt": "2025-10-04T14:00:00Z",
    "fwi": 18.5
  }
}
```

### CacheMetadata JSON Format
```json
{
  "totalEntries": 47,
  "lastCleanup": 1696431600000,
  "accessLog": {
    "gcpue": 1696435200000,
    "gcpud": 1696434800000,
    "gcpuf": 1696434400000
  }
}
```