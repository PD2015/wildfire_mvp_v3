# Data Model: EffisService

**Created**: 2025-10-02  
**Phase**: 1 (Design)

## Core Entities

### EffisFwiResult
**Purpose**: Contains processed FWI data with risk level mapping and metadata  
**Fields**:
- `fwi: double` - Raw Fire Weather Index value (0..100+)
- `level: RiskLevel` - Mapped risk category 
- `observedAt: DateTime` - UTC timestamp from EFFIS
- `source: Uri` - EFFIS endpoint used for the request

**Validation Rules**:
- `fwi` must be >= 0 (negative values invalid)
- `observedAt` must be valid UTC DateTime
- `source` must be valid URI

**State Transitions**: Immutable value object (no state changes)

### RiskLevel (Enum)
**Purpose**: Standardized wildfire risk categories  
**Values**:
- `veryLow` - FWI < 5
- `low` - FWI 5-11.99
- `moderate` - FWI 12-20.99  
- `high` - FWI 21-37.99
- `veryHigh` - FWI 38-49.99
- `extreme` - FWI >= 50

**Mapping Logic**: Static function `RiskLevel.fromFwi(double fwi)`

### ApiError
**Purpose**: Structured error information for all failure cases  
**Fields**:
- `type: ApiErrorType` - Categorized error type
- `message: String` - Human-readable error description
- `statusCode: int?` - HTTP status code (null for network errors)
- `retryAfter: Duration?` - Suggested retry delay (null if not retryable)
- `context: Map<String, dynamic>` - Additional debugging info

**Error Types**:
- `networkError` - Connection, timeout, DNS issues
- `serverError` - HTTP 5xx responses
- `clientError` - HTTP 4xx responses  
- `parseError` - Invalid JSON or unexpected schema
- `noDataError` - Valid response but no FWI data for coordinates

### Coordinate (Value Object)
**Purpose**: Validated latitude/longitude pair  
**Fields**:
- `latitude: double` - Latitude (-90 to 90)
- `longitude: double` - Longitude (-180 to 180)

**Validation Rules**:
- Latitude in range [-90, 90]
- Longitude in range [-180, 180]
- Values rounded to 6 decimal places (precision limit)

## Relationships

```
EffisService 
    ↓ uses
Coordinate → HTTP Request → EFFIS API
    ↓ processes response  
EffisFwiResult (success) OR ApiError (failure)
    ↓ maps FWI value
RiskLevel (enum value)
```

## Data Flow

1. **Input**: `Coordinate` object with validated lat/lon
2. **Request**: HTTP GET to EFFIS with coordinate parameters  
3. **Response Processing**:
   - Success: Parse JSON → Extract FWI → Map to RiskLevel → Return EffisFwiResult
   - Failure: Categorize error → Return ApiError with retry info
4. **Output**: `Either<ApiError, EffisFwiResult>`

## Validation Strategy

### Input Validation
- Coordinate bounds checking before HTTP request
- Parameter encoding validation (no injection attacks)

### Response Validation  
- JSON schema validation (features array exists)
- FWI value type and range checking
- DateTime parsing with timezone handling
- Graceful handling of unexpected additional fields

### Error Validation
- HTTP status code categorization
- Timeout vs connection error distinction
- Retry-safe error identification (5xx vs 4xx)

## Serialization

### Request Serialization
- Coordinates formatted to 6 decimal places
- URL encoding for query parameters
- UTF-8 encoding for HTTP requests

### Response Deserialization
- JSON parsing with null safety
- DateTime parsing from ISO 8601 strings
- Graceful handling of missing optional fields
- Schema version tolerance (ignore unknown fields)

No persistence layer - service is stateless and ephemeral.