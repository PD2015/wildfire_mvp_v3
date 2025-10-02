# Research: EffisService (FWI Point Query)

**Created**: 2025-10-02  
**Phase**: 0 (Research & Decisions)

## Technical Decisions

### HTTP Client Choice
**Decision**: Use Flutter's built-in `http` package  
**Rationale**: 
- Standard Flutter HTTP client, well-maintained
- Supports timeouts, custom headers, and error handling
- Minimal dependencies, already used in Flutter ecosystem
**Alternatives considered**: 
- dio: More features but overkill for simple GET requests
- HttpClient directly: Too low-level, more error-prone

### Error Handling Pattern
**Decision**: Use dartz Either<ApiError, T> pattern  
**Rationale**:
- Forces explicit error handling at call sites
- Functional programming approach prevents forgotten error cases  
- Type-safe error propagation without exceptions
**Alternatives considered**:
- Exceptions: Can be forgotten, harder to test all paths
- Result<T> custom class: Reinventing existing dartz wheel

### FWI Mapping Strategy
**Decision**: Static constant thresholds with pure function mapping  
**Rationale**:
- Constitution requires single source of truth for thresholds
- Testable, predictable, no external dependencies
- Values are official EFFIS standards (unlikely to change)
**Alternatives considered**:
- Configuration file: Overkill for static scientific constants
- Database lookup: Service should be stateless

### Retry/Backoff Implementation
**Decision**: Exponential backoff with jitter, max 3 retries  
**Rationale**:
- Standard practice for HTTP APIs to prevent thundering herd
- Jitter prevents synchronized retry storms
- 3 retries gives reasonable reliability without excessive delays
**Alternatives considered**:
- Fixed delay: Can cause synchronized load spikes
- Linear backoff: Less effective than exponential for overloaded servers

### URL Template Approach
**Decision**: String interpolation with validation  
**Rationale**:
- EFFIS WMS GetFeatureInfo uses standard query parameters
- Simple to test and debug
- Validation prevents malformed requests
**Alternatives considered**:
- URI builder classes: Overkill for single endpoint
- Raw string concatenation: Prone to encoding errors

### Test Strategy for Network Layer
**Decision**: Golden test files with real EFFIS response samples  
**Rationale**:
- Captures real API behavior and schema
- Protects against upstream changes
- Enables reliable offline testing
**Alternatives considered**:
- Mock objects only: Doesn't catch schema changes
- Live API tests: Flaky, slow, requires network in CI

## EFFIS API Research

### Endpoint Pattern
```
https://effis.jrc.ec.europa.eu/applications/data.service/wms
?SERVICE=WMS
&VERSION=1.1.1
&REQUEST=GetFeatureInfo
&LAYERS=ecmwf.fwi.prd
&QUERY_LAYERS=ecmwf.fwi.prd
&X={screen_x}&Y={screen_y}
&HEIGHT=1&WIDTH=1
&INFO_FORMAT=application/json
&SRS=EPSG:4326
&BBOX={lon},{lat},{lon},{lat}
```

### Response Schema (from samples)
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

### Known Gotchas
1. **Coordinate System**: EFFIS uses EPSG:4326 (WGS84)
2. **Temporal Lag**: Data typically 2-6 hours behind real-time
3. **No Data Response**: Empty features array when outside coverage
4. **Rate Limiting**: No official limits documented, use respectful delays
5. **Schema Changes**: Properties may include additional fields in future

### Error Response Patterns
- **404**: Endpoint not found (service down)
- **400**: Malformed parameters (coordinate validation needed)
- **503**: Service temporarily unavailable (retry appropriate)
- **Timeout**: Network issues or overloaded service

## Performance Benchmarks

### Target Metrics (from spec)
- Successful requests: <3 seconds
- Timeout threshold: 30 seconds
- Retry attempts: Maximum 3
- Coordinate precision: 3 decimal places for logging

### Test Coordinates (UK Coverage)
1. Edinburgh: 55.953, -3.189 (urban)
2. Cairngorms: 57.066, -3.675 (highlands)
3. New Forest: 50.854, -1.623 (forest)
4. Dartmoor: 50.571, -3.988 (moorland)

All coordinates verified to be within EFFIS European coverage area.

## Dependencies Analysis

### Required Packages
- `http: ^1.1.0` - HTTP client
- `dartz: ^0.10.1` - Either type for error handling
- `equatable: ^2.0.5` - Value object equality

### Dev Dependencies  
- `mockito: ^5.4.2` - HTTP mocking for tests
- `build_runner: ^2.4.7` - Code generation for mocks

### No Additional Runtime Dependencies
Service is designed to be lightweight with minimal external dependencies to reduce version conflicts and improve reliability.