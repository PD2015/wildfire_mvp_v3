# EffisService API Contract

**Service**: EffisService  
**Created**: 2025-10-02  
**Version**: 1.0.0

## Interface Definition

```dart
abstract class EffisService {
  /// Retrieves Fire Weather Index for given coordinates
  /// 
  /// Returns Either<ApiError, EffisFwiResult> where:
  /// - Left: Structured error information for all failure cases
  /// - Right: Successful FWI result with risk level mapping
  ///
  /// Throws: Never throws exceptions, all errors returned as ApiError
  Future<Either<ApiError, EffisFwiResult>> getFwi({
    required double lat,
    required double lon,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  });
}
```

## Method Contracts

### getFwi()

**Preconditions**:
- `lat` must be in range [-90, 90]
- `lon` must be in range [-180, 180]  
- `timeout` must be positive duration
- `maxRetries` must be >= 0 and <= 10

**Postconditions**:
- Always returns Either<ApiError, EffisFwiResult>
- Never throws exceptions
- Network requests respect timeout parameter
- Retries follow exponential backoff pattern
- Coordinates in logs limited to 3 decimal places

**Performance Contract**:
- Successful requests complete in <3 seconds (95th percentile)
- Timeout after specified duration (default 30s)
- Total time including retries: <2 minutes worst case

**Error Handling Contract**:
- All network errors mapped to structured ApiError
- HTTP status codes categorized appropriately
- Retry logic applied only for retriable errors (5xx, timeouts, network)
- No retries for client errors (4xx)

## Input/Output Schemas

### Input Parameters
```dart
// Coordinate validation
double lat;     // -90.0 to 90.0, precision 6 decimal places
double lon;     // -180.0 to 180.0, precision 6 decimal places
Duration timeout;  // positive duration, default 30s
int maxRetries;    // 0-10, default 3
```

### Success Response
```dart
class EffisFwiResult {
  final double fwi;          // 0.0 to 100.0+ (no upper limit)
  final RiskLevel level;     // veryLow|low|moderate|high|veryHigh|extreme  
  final DateTime observedAt; // UTC timestamp from EFFIS
  final Uri source;          // EFFIS endpoint URL used
}
```

### Error Response  
```dart
class ApiError {
  final ApiErrorType type;           // networkError|serverError|clientError|parseError|noDataError
  final String message;              // Human-readable description
  final int? statusCode;             // HTTP status (null for network errors)
  final Duration? retryAfter;        // Suggested delay (null if not retriable)
  final Map<String, dynamic> context; // Debug info (sanitized)
}
```

## EFFIS API Integration Contract

### HTTP Request Format
```
GET https://effis.jrc.ec.europa.eu/applications/data.service/wms?
  SERVICE=WMS&
  VERSION=1.1.1&
  REQUEST=GetFeatureInfo&
  LAYERS=ecmwf.fwi.prd&
  QUERY_LAYERS=ecmwf.fwi.prd&
  X=1&Y=1&
  HEIGHT=1&WIDTH=1&
  INFO_FORMAT=application/json&
  SRS=EPSG:4326&
  BBOX={lon},{lat},{lon},{lat}

Headers:
  User-Agent: WildFireMVP/1.0.0
  Accept: application/json
```

### Expected EFFIS Response Schema
```json
{
  "features": [
    {
      "properties": {
        "fwi": 15.234,
        "datetime": "2025-10-02T12:00:00Z"
      }
    }
  ]
}
```

### Error Response Handling
- **Empty features array**: Maps to `noDataError`
- **Missing fwi property**: Maps to `parseError`
- **Invalid datetime**: Maps to `parseError`  
- **HTTP 4xx**: Maps to `clientError`
- **HTTP 5xx**: Maps to `serverError`
- **Network timeout**: Maps to `networkError`

## Test Contract Requirements

### Unit Test Coverage
- All input validation boundaries
- FWI to RiskLevel mapping for all thresholds (4.99, 5.0, 11.99, 12.0, etc.)
- HTTP timeout scenarios
- Retry logic with exponential backoff
- All error type mappings
- JSON parsing edge cases

### Golden Test Requirements
- Valid EFFIS response samples for each UK test coordinate
- Error response samples (404, 503, malformed JSON)
- Empty features response sample
- Response with additional unknown fields (forward compatibility)

### Performance Test Requirements
- Successful request latency under load
- Timeout behavior verification
- Retry delay timing accuracy
- Memory usage during concurrent requests

## Breaking Change Policy

**Major Version Changes** (require dependency update):
- Method signature changes
- Return type modifications  
- Exception throwing behavior changes

**Minor Version Changes** (backward compatible):
- New optional parameters with defaults
- Additional fields in result objects
- New error types

**Patch Version Changes** (internal only):
- Bug fixes in error handling
- Performance improvements
- Internal refactoring

## Dependencies Contract

**Required at Runtime**:
- `http: ^1.1.0` (HTTP client)
- `dartz: ^0.10.1` (Either type)
- `equatable: ^2.0.5` (value equality)

**Required for Testing**:
- `mockito: ^5.4.2` (HTTP mocking)
- Standard Flutter test framework

**Stability Promise**: Dependency versions locked to prevent breaking changes in patch releases.