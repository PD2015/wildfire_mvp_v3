# Contract: FireRiskService Interface

## API Contract

### Method: getCurrent
```
Future<Either<ApiError, FireRisk>> getCurrent({
  required double lat,
  required double lon,
})
```

#### Input Parameters
- **lat**: Latitude in decimal degrees (required)
  - Range: -90.0 to 90.0
  - Precision: Up to 6 decimal places accepted
- **lon**: Longitude in decimal degrees (required)  
  - Range: -180.0 to 180.0
  - Precision: Up to 6 decimal places accepted

#### Return Types
**Success Case**: `Right(FireRisk)`
**Error Case**: `Left(ApiError)`

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

## Testing Contracts

### Integration Test Requirements
- Simulate EFFIS failure → SEPA success scenario
- Simulate both EFFIS and SEPA failure → cache success scenario  
- Simulate all services failure → mock success scenario
- Verify Scotland boundary edge cases
- Validate cache TTL expiration behavior

### Unit Test Requirements
- Test coordinate validation boundaries
- Test fallback chain logic with all combinations
- Test cache hit/miss scenarios
- Test geographic boundary detection accuracy
- Test error mapping and message clarity