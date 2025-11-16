# ActiveFiresService Contract

## Interface Definition

```dart
abstract class ActiveFiresService {
  /// Get active fire incidents within geographic bounds
  /// 
  /// Returns Either<ApiError, List<FireIncident>>
  /// 
  /// @param bounds Geographic viewport to query
  /// @param timeWindowHours Hours back from now to include incidents (default 24)
  /// @param maxResults Maximum incidents to return (default 1000)
  /// @returns Left(ApiError) on failure, Right(List<FireIncident>) on success
  Future<Either<ApiError, List<FireIncident>>> getIncidentsForViewport(
    LatLngBounds bounds, {
    int timeWindowHours = 24,
    int maxResults = 1000,
  });
  
  /// Get detailed information for specific fire incident
  /// 
  /// @param incidentId Unique fire incident identifier
  /// @returns Left(ApiError) on failure, Right(FireIncident) on success
  Future<Either<ApiError, FireIncident>> getIncidentDetails(String incidentId);
}
```

## Request/Response Schemas

### GetIncidentsForViewport Request
```dart
class ViewportQuery {
  final LatLngBounds bounds;        // Required: geographic bounds
  final int timeWindowHours;        // Optional: default 24
  final int maxResults;             // Optional: default 1000
  final bool includeStale;          // Optional: include >6hr old data
}
```

### GetIncidentsForViewport Response  
```dart
class ViewportResponse {
  final List<FireIncident> incidents;    // Fire incidents in bounds
  final LatLngBounds queriedBounds;     // Actual bounds queried (may differ)
  final DateTime responseTime;          // When response generated
  final int totalCount;                 // Total available (may exceed list)
  final bool hasMoreResults;            // Whether more results exist
  final String dataSource;              // EFFIS|SEPA|CACHE|MOCK
}
```

## Error Responses

### ApiError Structure
```dart
class ApiError {
  final String code;              // ERROR_NETWORK, ERROR_TIMEOUT, ERROR_INVALID_BOUNDS
  final String message;           // Human-readable error description
  final Map<String, dynamic>? details; // Additional error context
  final bool isRetryable;         // Whether request can be retried
}
```

### Standard Error Codes
- `ERROR_NETWORK`: Network connectivity issues
- `ERROR_TIMEOUT`: Request exceeded timeout threshold
- `ERROR_INVALID_BOUNDS`: Geographic bounds validation failed
- `ERROR_RATE_LIMIT`: API rate limit exceeded
- `ERROR_SERVICE_UNAVAILABLE`: Upstream service temporarily unavailable
- `ERROR_AUTHENTICATION`: API authentication failed
- `ERROR_INVALID_RESPONSE`: Malformed response from service

## Implementation Requirements

### Live Data Mode (MAP_LIVE_DATA=true)
- Query EFFIS WFS service for active fire data
- Apply geographic bounds filtering server-side when possible
- Implement 8-second request timeout
- Handle CORS and authentication as required
- Parse GeoJSON FeatureCollection response format

### Mock Data Mode (MAP_LIVE_DATA=false)  
- Return predefined fire incidents for testing
- Include variety of confidence levels, FRP values, ages
- Ensure mock data falls within provided bounds
- Add "MOCK" data source labeling
- Simulate realistic response delays (100-500ms)

### Caching Layer
- Cache responses by geohash-encoded bounds + time window
- 6-hour TTL for live data freshness
- LRU eviction when cache size limit reached  
- Return cached data with Freshness.cached indicator
- Bypass cache for explicit refresh requests

### Error Handling
- Network timeouts with exponential backoff
- Fallback to cached data when live service fails
- Graceful degradation with partial results
- User-friendly error messages for UI display
- Retry mechanism with jitter to avoid thundering herd

## Contract Tests

### Success Cases
```dart
testWidgets('getIncidentsForViewport returns valid incidents', (tester) async {
  // Given: Valid geographic bounds covering Scotland  
  const bounds = LatLngBounds(
    southwest: LatLng(55.0, -8.0),
    northeast: LatLng(61.0, 0.0),
  );
  
  // When: Requesting incidents for viewport
  final result = await service.getIncidentsForViewport(bounds);
  
  // Then: Returns success with valid incident list
  expect(result.isRight(), isTrue);
  final incidents = result.getOrElse(() => []);
  for (final incident in incidents) {
    expect(incident.location.isWithin(bounds), isTrue);
    expect(incident.detectedAt, isBefore(DateTime.now()));
    expect(incident.confidence, inInclusiveRange(0.0, 100.0));
  }
});
```

### Error Cases
```dart
testWidgets('getIncidentsForViewport handles timeout', (tester) async {
  // Given: Service configured with short timeout
  // When: Network request exceeds timeout
  // Then: Returns Left(ApiError) with timeout code
  
  final result = await service.getIncidentsForViewport(bounds);
  expect(result.isLeft(), isTrue);
  final error = result.swap().getOrElse(() => ApiError.unknown());
  expect(error.code, equals('ERROR_TIMEOUT'));
  expect(error.isRetryable, isTrue);
});
```

### Mock Mode Validation
```dart
testWidgets('mock mode returns DEMO DATA indicators', (tester) async {
  // Given: MAP_LIVE_DATA=false
  // When: Requesting incidents
  // Then: All incidents marked as mock data source
  
  final result = await service.getIncidentsForViewport(bounds);
  final incidents = result.getOrElse(() => []);
  for (final incident in incidents) {
    expect(incident.dataSource, equals(DataSource.mock));
  }
});
```

## Performance Requirements

- **Response Time**: <2 seconds for typical viewport queries
- **Throughput**: Support 10 requests/minute per user  
- **Cache Hit Ratio**: >70% for repeat viewport queries
- **Memory Usage**: <50MB for cached incident data
- **Offline Capability**: Return cached data when network unavailable