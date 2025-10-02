# Data Model: FireRiskService Implementation

## Overview
FireRiskService orchestrates multiple data sources to provide normalized fire risk assessments. This document defines the exact Dart implementations, API signatures, and data structures for the fallback orchestration system.

## Dart API Signatures

### Primary Service Interface
```dart
abstract class FireRiskService {
  /// Gets current fire risk for specified coordinates using fallback chain
  /// 
  /// Attempts services in order: EFFIS → SEPA (Scotland only) → Cache → Mock
  /// Always returns a result, never fails completely due to guaranteed mock fallback
  ///
  /// [lat] Latitude in decimal degrees (-90.0 to 90.0)
  /// [lon] Longitude in decimal degrees (-180.0 to 180.0)
  ///
  /// Returns Either<ApiError, FireRisk> where:
  /// - Left: Validation error only (invalid coordinates)
  /// - Right: FireRisk with source attribution and freshness
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
  });
}
```

### Geographic Utility Interface
```dart
abstract class GeographicUtils {
  /// Determines if coordinates are within Scotland boundaries
  /// 
  /// Uses polygon containment with established Scottish administrative boundaries
  /// Includes mainland Scotland and major islands (Hebrides, Orkney, Shetland)
  ///
  /// [lat] Latitude in decimal degrees
  /// [lon] Longitude in decimal degrees
  /// 
  /// Returns true if coordinates are within Scotland, false otherwise
  bool isInScotland(double lat, double lon);
  
  /// Generates geohash for cache key (5-character precision ~4.9km²)
  /// 
  /// Provides privacy-protected location identifier for caching
  /// Balances cache efficiency with user privacy protection
  ///
  /// [lat] Latitude in decimal degrees  
  /// [lon] Longitude in decimal degrees
  ///
  /// Returns 5-character geohash string
  String generateCacheKey(double lat, double lon);
}
```

### Telemetry Interface
```dart
abstract class TelemetryService {
  /// Records service attempt for monitoring and analysis
  ///
  /// [source] Service identifier: 'effis', 'sepa', 'cache', 'mock'
  /// [latency] Time taken for service call
  /// [success] Whether service returned valid data
  /// [errorReason] Optional error description for failed attempts
  /// [locationHash] Geohash of location (privacy-protected)
  void recordServiceAttempt({
    required String source,
    required Duration latency,
    required bool success,
    String? errorReason,
    required String locationHash,
  });

  /// Records cache-related events for performance monitoring
  ///
  /// [event] Cache event type: 'hit', 'miss', 'expired'
  /// [locationHash] Geohash of location (privacy-protected)
  void recordCacheEvent({
    required String event,
    required String locationHash,
  });
}
```

## Core Data Models

### FireRisk
```dart
class FireRisk extends Equatable {
  /// Fire risk level using standardized categories
  final RiskLevel level;
  
  /// Fire Weather Index value (optional - available from EFFIS/SEPA only)
  final double? fwi;
  
  /// Data source identifier for audit trail and user transparency
  final FireRiskSource source;
  
  /// UTC timestamp of when data was originally collected
  final DateTime updatedAt;
  
  /// Indicates if data is live or cached
  final DataFreshness freshness;

  const FireRisk({
    required this.level,
    this.fwi,
    required this.source,
    required this.updatedAt,
    required this.freshness,
  });

  @override
  List<Object?> get props => [level, fwi, source, updatedAt, freshness];
}
```

### FireRiskSource (Enum)
```dart
enum FireRiskSource {
  effis('effis'),
  sepa('sepa'), 
  cache('cache'),
  mock('mock');
  
  const FireRiskSource(this.value);
  final String value;
}
```

### DataFreshness (Enum)
```dart
enum DataFreshness {
  live('live'),
  cached('cached');
  
  const DataFreshness(this.value);
  final String value;
}
```

**Business Rules**:
- Must always have a valid risk level
- FWI value only present for EFFIS/SEPA sources (null for cache/mock)
- Source attribution is mandatory for audit trail and user transparency
- updatedAt represents original data collection time, not request time
- Freshness indicates whether data came from live service or cache

### ServiceAttempt
```dart
class ServiceAttempt extends Equatable {
  /// Service identifier for this attempt
  final FireRiskSource service;
  
  /// Whether this service was attempted (false if skipped)
  final bool attempted;
  
  /// Whether the service call succeeded
  final bool succeeded;
  
  /// Response time for the service call
  final Duration? latency;
  
  /// Reason service was skipped (if not attempted)
  final String? skipReason;
  
  /// Error details (if attempt failed)
  final String? errorReason;

  const ServiceAttempt({
    required this.service,
    required this.attempted,
    required this.succeeded,
    this.latency,
    this.skipReason,
    this.errorReason,
  });

  @override
  List<Object?> get props => [service, attempted, succeeded, latency, skipReason, errorReason];
}
```

**Business Rules**:
- Services attempted in strict order: EFFIS → SEPA → Cache → Mock
- SEPA skipped when coordinates outside Scotland (skipReason: "out-of-region")
- Mock service never fails (always returns moderate risk)
- Latency only recorded for attempted services
- Used for telemetry and debugging, not persisted long-term

### GeographicContext
```dart
class GeographicContext extends Equatable {
  /// Latitude in decimal degrees
  final double latitude;
  
  /// Longitude in decimal degrees  
  final double longitude;
  
  /// Whether coordinates are within Scotland boundaries
  final bool isInScotland;
  
  /// Geohash-based cache key for privacy protection
  final String cacheKey;

  const GeographicContext({
    required this.latitude,
    required this.longitude,
    required this.isInScotland,
    required this.cacheKey,
  });

  /// Factory constructor with validation and derived fields
  factory GeographicContext.create({
    required double latitude,
    required double longitude,
    required GeographicUtils geoUtils,
  }) {
    // Validate coordinate ranges
    if (latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError('Latitude must be between -90 and 90 degrees');
    }
    if (longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError('Longitude must be between -180 and 180 degrees');
    }
    
    return GeographicContext(
      latitude: latitude,
      longitude: longitude,
      isInScotland: geoUtils.isInScotland(latitude, longitude),
      cacheKey: geoUtils.generateCacheKey(latitude, longitude),
    );
  }

  @override
  List<Object> get props => [latitude, longitude, isInScotland, cacheKey];
}
```

**Business Rules**:
- Coordinates validated at construction time
- Scotland boundary detection determines SEPA eligibility
- Cache keys use coarse geohash (5-char) to protect privacy
- Raw coordinates not persisted beyond request scope
- Immutable value object for thread safety

### CacheEntry
```dart
class CacheEntry extends Equatable {
  /// Geohash-based location identifier (privacy-protected)
  final String cacheKey;
  
  /// Stored fire risk data
  final FireRisk fireRisk;
  
  /// UTC timestamp when data was cached
  final DateTime cachedAt;
  
  /// UTC timestamp when cache entry expires
  final DateTime expiresAt;

  const CacheEntry({
    required this.cacheKey,
    required this.fireRisk,
    required this.cachedAt,
    required this.expiresAt,
  });

  /// Factory constructor with automatic expiration calculation
  factory CacheEntry.create({
    required String cacheKey,
    required FireRisk fireRisk,
    DateTime? cachedAt,
  }) {
    final now = cachedAt ?? DateTime.now().toUtc();
    return CacheEntry(
      cacheKey: cacheKey,
      fireRisk: fireRisk,
      cachedAt: now,
      expiresAt: now.add(const Duration(hours: 6)),
    );
  }

  /// Checks if cache entry is still valid
  bool get isValid => DateTime.now().toUtc().isBefore(expiresAt);

  /// Returns cached FireRisk with updated freshness indicator
  FireRisk get cachedFireRisk => FireRisk(
        level: fireRisk.level,
        fwi: fireRisk.fwi,
        source: FireRiskSource.cache,
        updatedAt: fireRisk.updatedAt, // Preserve original timestamp
        freshness: DataFreshness.cached,
      );

  @override
  List<Object> get props => [cacheKey, fireRisk, cachedAt, expiresAt];
}
```

**Business Rules**:
- TTL fixed at 6 hours from cache creation time
- Only successful EFFIS/SEPA responses are cached (source != mock)
- Mock data never cached to avoid confusion
- Expired entries automatically skipped via isValid check
- Cached FireRisk preserves original updatedAt timestamp but changes source and freshness

## Error Taxonomy

### ApiError Extensions
```dart
enum FireRiskErrorReason {
  /// Invalid coordinate values (lat/lon out of range)
  invalidCoordinates,
  
  /// Total request timeout exceeded (>10 seconds)
  totalTimeout,
  
  /// All services failed (should never happen due to mock fallback)
  allServicesFailed,
}

extension FireRiskApiError on ApiError {
  /// Creates validation error for invalid coordinates
  static ApiError invalidCoordinates(String details) => ApiError(
        message: 'Invalid coordinates: $details',
        reason: ApiErrorReason.validation,
      );

  /// Creates timeout error for total request timeout
  static ApiError totalTimeout() => ApiError(
        message: 'Fire risk request timed out after 10 seconds',
        reason: ApiErrorReason.timeout,
      );
}
```

## Fallback Decision Logic

### FallbackDecision
```dart
class FallbackDecision extends Equatable {
  /// Current service being attempted
  final FireRiskSource currentService;
  
  /// Whether to attempt this service
  final bool shouldAttempt;
  
  /// Reason for skipping (if shouldAttempt is false)
  final String? skipReason;
  
  /// Next service in fallback chain (null if this is final)
  final FireRiskSource? nextService;

  const FallbackDecision({
    required this.currentService,
    required this.shouldAttempt,
    this.skipReason,
    this.nextService,
  });

  @override
  List<Object?> get props => [currentService, shouldAttempt, skipReason, nextService];
}
```

### FallbackChain
```dart
class FallbackChain {
  static const List<FireRiskSource> _services = [
    FireRiskSource.effis,
    FireRiskSource.sepa,
    FireRiskSource.cache,
    FireRiskSource.mock,
  ];

  /// Determines next fallback decision based on context and previous attempts
  static FallbackDecision getNextDecision({
    required GeographicContext context,
    required List<ServiceAttempt> previousAttempts,
  }) {
    final attemptedServices = previousAttempts.map((a) => a.service).toSet();
    
    for (int i = 0; i < _services.length; i++) {
      final service = _services[i];
      
      if (attemptedServices.contains(service)) continue;
      
      // SEPA service only for Scotland
      if (service == FireRiskSource.sepa && !context.isInScotland) {
        continue; // Will be marked as skipped in calling code
      }
      
      return FallbackDecision(
        currentService: service,
        shouldAttempt: true,
        nextService: i < _services.length - 1 ? _services[i + 1] : null,
      );
    }
    
    // Should never reach here due to mock fallback
    throw StateError('No more services in fallback chain');
  }
}
```

## Entity Relationships

```
Request → GeographicContext.create()
       → FallbackChain.getNextDecision()
       → ServiceAttempt[] (tracking attempts)
       → CacheEntry.lookup/store()
       → FireRisk (final result)

GeographicContext.isInScotland → FallbackDecision.shouldAttempt (SEPA)
GeographicContext.cacheKey → CacheEntry.lookup()
ServiceAttempt.succeeded → FallbackChain.getNextDecision()
CacheEntry.isValid → determines cache usage
FallbackDecision → guides service attempt logic
```

## Privacy & Security Considerations

### Data Minimization
- Geographic coordinates rounded to 2-3 decimal places in logs
- Cache keys use coarse geohash (not precise coordinates)  
- No persistent storage of exact user locations

### Data Retention
- ServiceAttempt data discarded after telemetry logging
- CacheEntry data auto-expires after 6 hours
- FireRisk data not persisted (created per request)

### Audit Trail
- All service attempts logged with anonymized location data
- Source attribution preserved in FireRisk responses
- Fallback reasons captured for service improvement