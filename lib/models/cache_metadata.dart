import 'package:equatable/equatable.dart';

/// Cache metadata for monitoring and LRU eviction policy
///
/// Tracks cache state and access patterns for optimal cache management
/// with 100-entry capacity and least-recently-used eviction strategy.
class CacheMetadata extends Equatable {
  const CacheMetadata({
    required this.totalEntries,
    required this.lastCleanup,
    this.accessLog = const {},
  });

  /// Current number of entries in cache
  final int totalEntries;

  /// Last time cleanup() was called (UTC timezone)
  final DateTime lastCleanup;

  /// Access timestamp log for LRU eviction policy
  /// Maps geohash keys to last access time (UTC)
  final Map<String, DateTime> accessLog;

  /// Check if cache has reached capacity (100 entries)
  bool get isFull => totalEntries >= 100;

  /// Get least recently used entry key for eviction
  ///
  /// Returns null if no access log entries exist.
  /// Used by LRU eviction policy to identify victim entries.
  String? get lruKey {
    if (accessLog.isEmpty) return null;
    return accessLog.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
  }

  /// Create updated metadata with new values
  CacheMetadata copyWith({
    int? totalEntries,
    DateTime? lastCleanup,
    Map<String, DateTime>? accessLog,
  }) {
    return CacheMetadata(
      totalEntries: totalEntries ?? this.totalEntries,
      lastCleanup: lastCleanup ?? this.lastCleanup,
      accessLog: accessLog ?? this.accessLog,
    );
  }

  /// Serialize to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'lastCleanup': lastCleanup.millisecondsSinceEpoch,
      'accessLog': accessLog
          .map((key, value) => MapEntry(key, value.millisecondsSinceEpoch)),
    };
  }

  /// Deserialize from JSON with UTC timestamp conversion
  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    final accessLogJson = json['accessLog'] as Map<String, dynamic>? ?? {};
    final accessLog = accessLogJson.map((key, value) => MapEntry(
        key, DateTime.fromMillisecondsSinceEpoch(value as int).toUtc()));

    return CacheMetadata(
      totalEntries: json['totalEntries'] as int,
      lastCleanup:
          DateTime.fromMillisecondsSinceEpoch(json['lastCleanup'] as int)
              .toUtc(),
      accessLog: accessLog,
    );
  }

  @override
  List<Object?> get props => [totalEntries, lastCleanup, accessLog];
}
