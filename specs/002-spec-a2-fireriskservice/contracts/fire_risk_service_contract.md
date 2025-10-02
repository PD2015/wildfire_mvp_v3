# Contract: FireRiskService Implementation Specification

## Primary Service Contract

### FireRiskService.getCurrent()
```dart
abstract class FireRiskService {
  /// Gets current fire risk for coordinates using fallback orchestration
  ///
  /// Implements fallback chain: EFFIS → SEPA (Scotland only) → Cache → Mock
  /// Always returns a result due to guaranteed mock fallback
  ///
  /// Throws: Never throws exceptions - all errors returned as Left(ApiError)
  /// Timeout: Maximum 10 seconds total for all fallback attempts
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
  });
}
```

#### Input Validation Contract
- **lat**: Latitude in decimal degrees
  - Range: -90.0 to 90.0 (inclusive)
  - Precision: Up to 6 decimal places supported
  - Invalid range returns `Left(ApiError.invalidCoordinates())`
- **lon**: Longitude in decimal degrees  
  - Range: -180.0 to 180.0 (inclusive)
  - Precision: Up to 6 decimal places supported
  - Invalid range returns `Left(ApiError.invalidCoordinates())`

#### Return Contract
- **Success**: `Right(FireRisk)` - Always includes source attribution and freshness
- **Error**: `Left(ApiError)` - Only for invalid coordinates (validation errors)
- **Guarantee**: Never returns null, never throws exceptions

## Data Contracts

### FireRisk Object
```
{
  "level": String,      // Risk level: "veryLow" | "low" | "moderate" | "high" | "veryHigh" | "extreme"
  "fwi": double?,       // Fire Weather Index (optional, null for cache/mock)
  "source": String,     // Data source: "effis" | "sepa" | "cache" | "mock"
  "updatedAt": DateTime, // UTC timestamp of original data
  "freshness": String   // Freshness indicator: "live" | "cached"
}
```

### ApiError Object  
```
{
  "message": String,           // Human-readable error description
  "statusCode": int?,          // HTTP status code (optional)
  "reason": ApiErrorReason?    // Categorized error type (optional)
}
```

## Behavior Contracts

### Fallback Chain Contract
The service MUST attempt data sources in this exact order:
1. **EFFIS Service** - Always attempted first
2. **SEPA Service** - Only if coordinates are in Scotland AND EFFIS fails
3. **Cache Service** - Only if previous services fail AND cache data ≤6h old  
4. **Mock Service** - Only if all other sources fail (guaranteed success)

### Geographic Routing Contract
- **Scotland Detection**: Coordinates within Scottish geographic boundaries qualify for SEPA service
- **Out of Region**: Coordinates outside Scotland skip SEPA without error
- **Invalid Coordinates**: Lat/lon outside valid ranges return validation error immediately

### Response Guarantee Contract
- **Never Null**: Service MUST always return either ApiError or FireRisk
- **Never Exception**: Service MUST NOT throw unhandled exceptions
- **Always Attributed**: FireRisk MUST always include source and freshness
- **Timestamp Accuracy**: updatedAt MUST reflect original data time, not request time

### Caching Contract
- **TTL Enforcement**: Cache entries older than 6 hours MUST be ignored
- **Source Restriction**: Only EFFIS and SEPA responses are cached
- **Privacy Protection**: Cache keys MUST use geohash, not raw coordinates
- **Automatic Cleanup**: Expired cache entries MUST be cleaned up automatically

### Error Handling Contract
- **Validation Errors**: Invalid coordinates return immediate ApiError
- **Service Failures**: Individual service failures trigger next fallback
- **Ultimate Fallback**: Mock service MUST always succeed with "moderate" risk
- **Error Context**: ApiError MUST include meaningful error descriptions

## Performance Contracts

### Response Time Contract
- **Total Timeout**: Maximum 10 seconds for complete fallback chain
- **Individual Timeout**: Each service attempt has its own timeout limits
- **Parallel Restrictions**: Services MUST be attempted sequentially, not in parallel

### Caching Performance Contract  
- **Cache Lookup**: Cache checks MUST complete within 100ms
- **Cache Storage**: Cache writes MUST be non-blocking
- **Memory Efficiency**: Cache MUST not exceed reasonable memory limits

## Privacy & Security Contracts

### Data Privacy Contract
- **Location Anonymization**: Coordinates rounded to 2-3 decimal places in logs
- **No Persistence**: Raw coordinates MUST NOT be stored permanently
- **Coarse Caching**: Cache keys use geohash precision appropriate for privacy

### Security Contract
- **Input Validation**: All coordinate inputs validated before processing
- **Safe Logging**: No sensitive data exposed in application logs
- **Error Information**: Error messages MUST NOT leak internal system details

## Service Integration Contracts

### EffisService Integration Contract
```dart
// Uses existing A1 EffisService implementation
abstract class EffisServiceIntegration {
  /// Integrates with implemented EffisService.getCurrent()
  /// 
  /// Timeout: 5 seconds maximum
  /// Fallback Trigger: Any Left(ApiError) response
  /// Success Mapping: FireRisk with source="effis", freshness="live"
  Future<Either<ApiError, FireRisk>> getCurrentViaEffis(double lat, double lon);
}
```

### SepaService Integration Contract  
```dart
abstract class SepaService {
  /// Gets fire risk data from SEPA API for Scotland coordinates
  ///
  /// Geographic Scope: 54.6-60.9°N, 8.2°W-1.0°E (Scotland bounds)
  /// Input Conversion: WGS84 lat/lon → UK National Grid reference
  /// Timeout: 3 seconds maximum
  /// Fallback Trigger: HTTP errors, timeouts, invalid responses
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
  });
}
```

### CacheService Integration Contract
```dart
abstract class CacheService {
  /// Retrieves cached fire risk data
  ///
  /// Key Strategy: "firerisk_{geohash}" (0.01° precision for privacy)
  /// TTL Enforcement: Entries >1 hour old return null
  /// Storage: Encrypted local storage (privacy compliance)
  /// Thread Safety: All operations must be thread-safe
  Future<FireRisk?> get(String key);
  
  /// Stores fire risk data in cache
  ///
  /// Source Restriction: Only cache 'effis' and 'sepa' responses
  /// Expiry: 1 hour TTL from storage time
  /// Privacy: Raw coordinates never stored, only geohash keys
  Future<void> put(String key, FireRisk data);
  
  /// Cleans expired cache entries
  Future<void> cleanup();
}
```

### MockService Integration Contract
```dart
abstract class MockService {
  /// Provides guaranteed fallback fire risk data
  ///
  /// Guarantee: Always succeeds, never throws, never returns Left()
  /// Logic: Deterministic risk level based on coordinate hash
  /// Response Time: <100ms guaranteed
  /// Attribution: source="mock", freshness="live"
  FireRisk getCurrent(double lat, double lon) {
    // Deterministic mock logic based on coordinates
    final hash = _hashCoordinates(lat, lon);
    final riskIndex = hash % 6;
    return FireRisk(
      level: RiskLevel.values[riskIndex].name,
      fwi: null, // No FWI for mock data
      source: 'mock',
      updatedAt: DateTime.now().toUtc(),
      freshness: 'live',
    );
  }
}
```

## Telemetry & Monitoring Contracts

### TelemetryService Contract
```dart
abstract class TelemetryService {
  /// Records successful service response
  void recordServiceSuccess({
    required ServiceType type,
    required Duration responseTime,
    required double lat,
    required double lon,
  });
  
  /// Records service failure requiring fallback
  void recordServiceFailure({
    required ServiceType type,
    required FireRiskErrorReason reason,
    required double lat,
    required double lon,
  });
  
  /// Records complete fallback chain execution
  void recordFallbackChain({
    required List<ServiceAttempt> attempts,
    required ServiceType successfulService,
    required Duration totalTime,
  });
  
  /// Records cache hit/miss statistics
  void recordCacheEvent({
    required CacheEventType event, // hit, miss, expired, write
    required String key,
  });
}
```

### ServiceAttempt Data Contract
```dart
class ServiceAttempt {
  final ServiceType service;
  final Duration responseTime;
  final bool success;
  final FireRiskErrorReason? errorReason;
  final DateTime attemptedAt;
  
  const ServiceAttempt({
    required this.service,
    required this.responseTime,
    required this.success,
    this.errorReason,
    required this.attemptedAt,
  });
}
```

## Testing Contracts

### Integration Test Requirements
- **Fallback Chain Tests**:
  - EFFIS failure → SEPA success (Scotland coordinates)
  - EFFIS + SEPA failure → cache success scenario
  - All services failure → mock success (guaranteed)
  - Non-Scotland coordinates skip SEPA appropriately

- **Geographic Boundary Tests**:
  - Scotland boundary edge cases (54.6°N, 60.9°N, 8.2°W, 1.0°E)
  - Coordinates just inside/outside Scotland bounds
  - International date line handling

- **Cache TTL Tests**:
  - Fresh cache entries (< 1 hour) are used
  - Expired cache entries (> 1 hour) are ignored
  - Cache cleanup removes expired entries

### Unit Test Requirements
- **Input Validation Tests**:
  - Valid coordinate ranges (-90/90, -180/180)
  - Invalid coordinate boundary conditions
  - Precision handling (6 decimal places)

- **Fallback Logic Tests**:
  - Service selection for Scotland vs non-Scotland
  - Error propagation and fallback triggering
  - Mock service guarantee (never fails)

- **Data Transformation Tests**:
  - EFFIS → FireRisk mapping accuracy
  - SEPA → FireRisk mapping accuracy
  - Cache → FireRisk deserialization
  - Error → ApiError mapping

- **Performance Tests**:
  - Total timeout enforcement (10 seconds)
  - Individual service timeouts
  - Cache lookup performance (<100ms)