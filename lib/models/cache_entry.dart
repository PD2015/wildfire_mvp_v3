import 'package:equatable/equatable.dart';
import '../utils/clock.dart';
import '../services/cache/cache_error.dart';

/// Generic cache entry wrapper with TTL and versioning support
///
/// Wraps cached data with metadata for TTL calculations, version tracking,
/// and spatial keying. All timestamps use UTC for consistent TTL behavior.
class CacheEntry<T> extends Equatable {
  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.geohash,
    this.version = '1.0',
  });

  /// The cached data payload
  final T data;

  /// When this entry was cached (UTC timezone)
  final DateTime timestamp;

  /// Geohash key for spatial locality (precision 5 = ~4.9km)
  final String geohash;

  /// Cache format version for migration compatibility
  final String version;

  /// Calculate age of this cache entry using Clock abstraction
  ///
  /// Parameters:
  /// - [clock]: Clock instance for testable time operations
  ///
  /// Returns: Duration since entry was cached
  Duration age(Clock clock) {
    assert(timestamp.isUtc,
        'Timestamp must be UTC for consistent TTL calculations');
    return clock.nowUtc().difference(timestamp);
  }

  /// Check if entry has expired (6 hour TTL)
  ///
  /// Parameters:
  /// - [clock]: Clock instance for testable time operations
  ///
  /// Returns: true if entry age exceeds 6 hours
  bool isExpired(Clock clock) => age(clock) > const Duration(hours: 6);

  /// Create cache entry with current timestamp from Clock
  ///
  /// Parameters:
  /// - [data]: Data to cache
  /// - [geohash]: Spatial key for cache locality
  /// - [clock]: Clock for timestamp generation (defaults to SystemClock)
  /// - [version]: Cache format version
  factory CacheEntry.now({
    required T data,
    required String geohash,
    Clock? clock,
    String version = '1.0',
  }) {
    final clockInstance = clock ?? SystemClock();
    return CacheEntry(
      data: data,
      timestamp: clockInstance.nowUtc(),
      geohash: geohash,
      version: version,
    );
  }

  /// Deserialize from JSON map with version validation
  ///
  /// Parameters:
  /// - [json]: JSON map containing cache entry data
  /// - [fromJsonT]: Function to deserialize data payload
  ///
  /// Throws:
  /// - [UnsupportedVersionError]: if version is not supported
  /// - [SerializationError]: if JSON format is invalid
  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    try {
      final version = json['version'] as String? ?? '1.0';
      if (version != '1.0') {
        throw UnsupportedVersionError(version);
      }

      return CacheEntry(
        data: fromJsonT(json['data'] as Map<String, dynamic>),
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
            .toUtc(),
        geohash: json['geohash'] as String,
        version: version,
      );
    } catch (e) {
      if (e is UnsupportedVersionError) rethrow;
      throw SerializationError('Failed to deserialize cache entry', e);
    }
  }

  /// Serialize to JSON map with version field
  ///
  /// Parameters:
  /// - [toJsonT]: Function to serialize data payload
  ///
  /// Returns: JSON map representation
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
