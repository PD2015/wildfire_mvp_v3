# Service Contract: FireLocationService

**Purpose**: Fetch active fire incidents within a geographic bounding box from EFFIS WFS API.

**Implementation**: `lib/services/fire_location_service.dart`

---

## Interface Definition

```dart
abstract class FireLocationService {
  /// Fetches active fire incidents within the specified bounding box.
  ///
  /// Implements fallback chain: EFFIS WFS → SEPA → Cache → Mock
  ///
  /// Returns Either<ServiceError, List<FireIncident>>
  ///   - Right: List of fire incidents (may be empty if no fires in region)
  ///   - Left: ServiceError if all services fail (should never happen with mock fallback)
  ///
  /// Throws: Never (mock fallback guarantees success)
  Future<Either<ServiceError, List<FireIncident>>> getActiveFires({
    required LatLngBounds bounds,
    Duration? timeout,
  });
}
```

---

## Request Specification

### Method: `getActiveFires`

**Parameters**:
- `bounds` (LatLngBounds, required): Geographic bounding box for query
  - Validation: southwest must be < northeast in both dimensions
  - Format for EFFIS: `{minLon},{minLat},{maxLon},{maxLat}`
- `timeout` (Duration?, optional): Service call timeout per tier
  - Default: 8 seconds
  - Applies to each service in fallback chain independently

**Example Call**:
```dart
final service = FireLocationServiceImpl(
  effisService: effisService,
  sepaService: sepaService,
  cacheService: cacheService,
  mockService: mockService,
);

final bounds = LatLngBounds(
  southwest: LatLng(55.9, -3.3),
  northeast: LatLng(56.1, -3.1),
);

final result = await service.getActiveFires(
  bounds: bounds,
  timeout: Duration(seconds: 8),
);

result.fold(
  (error) => print('Error: ${error.message}'),
  (incidents) => print('Found ${incidents.length} fires'),
);
```

---

## Response Specification

### Success Response: `Right(List<FireIncident>)`

**Shape**:
```dart
List<FireIncident> [
  FireIncident(
    id: 'effis_12345',
    location: LatLng(55.9533, -3.1883),
    source: DataSource.effis,
    freshness: Freshness.live,
    timestamp: DateTime.parse('2025-10-19T14:30:00Z'),
    intensity: 'moderate',
    description: 'Forest fire near Edinburgh',
    areaHectares: 12.5,
  ),
  // ... more incidents
]
```

**Guarantees**:
- List may be empty (no fires in region)
- All incidents have valid coordinates within `bounds`
- Timestamps are in UTC
- `source` field indicates which service provided the data (effis, sepa, cache, mock)
- `freshness` field indicates data age (live < 6h, cached 6-24h, mock = fallback)

---

### Error Response: `Left(ServiceError)`

**Note**: With mock fallback, this should **never occur** in production. If it does, indicates critical system failure.

**Shape**:
```dart
ServiceError(
  message: 'All services failed: EFFIS timeout, SEPA unavailable, Cache miss',
  source: DataSource.mock,  // Last attempted service
  originalError: Exception('Network timeout'),
)
```

---

## EFFIS WFS API Contract (Tier 1)

### Endpoint
```
GET https://ies-ows.jrc.ec.europa.eu/wfs
```

### Query Parameters
- `service=WFS`
- `version=2.0.0`
- `request=GetFeature`
- `typeName=burnt_areas_current_year`
- `outputFormat=application/json` (GeoJSON)
- `bbox={minLon},{minLat},{maxLon},{maxLat},EPSG:4326`
- `srsName=EPSG:4326`

### Example Request
```
GET https://ies-ows.jrc.ec.europa.eu/wfs?service=WFS&version=2.0.0&request=GetFeature&typeName=burnt_areas_current_year&outputFormat=application/json&bbox=-3.3,55.9,-3.1,56.1,EPSG:4326&srsName=EPSG:4326
```

### Expected Response (200 OK)
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "burnt_areas_current_year.12345",
      "geometry": {
        "type": "Point",
        "coordinates": [-3.1883, 55.9533]
      },
      "properties": {
        "id": "12345",
        "timestamp": "2025-10-19T14:30:00Z",
        "intensity": "moderate",
        "area_hectares": 12.5,
        "description": "Forest fire near Edinburgh"
      }
    }
  ]
}
```

### Error Responses
- **408 Request Timeout**: Service taking >8s, proceed to tier 2 (SEPA)
- **500 Internal Server Error**: EFFIS unavailable, proceed to tier 2
- **503 Service Unavailable**: EFFIS maintenance, proceed to tier 2
- **Invalid GeoJSON**: Parse error, proceed to tier 2

---

## SEPA API Contract (Tier 2 - Scotland Only)

**Note**: Only called if `bounds.center` is within Scotland geographic boundaries.

### Endpoint
```
GET https://api.sepa.org.uk/v1/wildfires/active
```

### Query Parameters
- `bbox={minLon},{minLat},{maxLon},{maxLat}`
- `format=json`

### Expected Response (200 OK)
```json
{
  "fires": [
    {
      "id": "sepa_67890",
      "lat": 55.9533,
      "lon": -3.1883,
      "severity": "moderate",
      "detected_at": "2025-10-19T14:30:00Z",
      "area_ha": 12.5
    }
  ]
}
```

**Transformation**:
```dart
FireIncident(
  id: json['id'],
  location: LatLng(json['lat'], json['lon']),
  source: DataSource.sepa,
  freshness: Freshness.live,
  timestamp: DateTime.parse(json['detected_at']),
  intensity: json['severity'],
  areaHectares: json['area_ha'],
)
```

---

## Cache Contract (Tier 3 - via CacheService A5)

### Cache Key Format
```
fire_incidents:{geohash}:{zoomLevel}
```

**Geohash Precision**:
- Zoom 5-8: precision 3 (~150km)
- Zoom 9-11: precision 4 (~40km)
- Zoom 12-15: precision 5 (~5km)
- Zoom 16+: precision 6 (~1.2km)

### Cache Lookup
```dart
final geohash = GeohashUtils.encode(bounds.center.lat, bounds.center.lon, precision: 5);
final key = 'fire_incidents:$geohash:$zoomLevel';

final cached = await cacheService.get<List<FireIncident>>(key);

if (cached.isSome() && cached.value.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 6)))) {
  return Right(cached.value.incidents.map((i) => i.copyWith(freshness: Freshness.cached)).toList());
}
```

### Cache Storage
```dart
await cacheService.set(
  key: key,
  value: incidents,
  ttl: Duration(hours: 6),
);
```

---

## Mock Contract (Tier 4 - Never Fails)

**Purpose**: Fallback demo data when all services fail.

### Mock Data Response
```dart
final mockIncidents = [
  FireIncident(
    id: 'mock_edinburgh_1',
    location: LatLng(55.9533, -3.1883),
    source: DataSource.mock,
    freshness: Freshness.mock,
    timestamp: DateTime.now().subtract(Duration(hours: 2)),
    intensity: 'moderate',
    areaHectares: 8.5,
  ),
  // ... 2-3 more mock incidents
];

return Right(mockIncidents.where((i) => bounds.contains(i.location)).toList());
```

**Guarantees**:
- Always returns successfully within 50ms
- Returns 0-3 incidents depending on `bounds`
- All incidents marked with `source: DataSource.mock` and `freshness: Freshness.mock`

---

## Service Orchestration Logic

### Fallback Chain Implementation
```dart
Future<Either<ServiceError, List<FireIncident>>> getActiveFires({
  required LatLngBounds bounds,
  Duration? timeout,
}) async {
  final deadline = timeout ?? Duration(seconds: 8);
  
  // Tier 1: EFFIS WFS
  try {
    final effisResult = await _effisService.getActiveFires(bounds).timeout(deadline);
    if (effisResult.isRight()) {
      ConstitutionLogger.logService('FireLocationService', 'EFFIS_SUCCESS', bounds);
      return effisResult;
    }
  } catch (e) {
    ConstitutionLogger.logService('FireLocationService', 'EFFIS_FAILED', bounds, error: e);
  }
  
  // Tier 2: SEPA (Scotland only)
  if (GeographicUtils.isInScotland(bounds.center.latitude, bounds.center.longitude)) {
    try {
      final sepaResult = await _sepaService?.getActiveFires(bounds).timeout(deadline);
      if (sepaResult != null && sepaResult.isRight()) {
        ConstitutionLogger.logService('FireLocationService', 'SEPA_SUCCESS', bounds);
        return sepaResult;
      }
    } catch (e) {
      ConstitutionLogger.logService('FireLocationService', 'SEPA_FAILED', bounds, error: e);
    }
  }
  
  // Tier 3: Cache
  final cached = await _tryCache(bounds);
  if (cached.isRight()) {
    ConstitutionLogger.logService('FireLocationService', 'CACHE_HIT', bounds);
    return cached;
  }
  
  // Tier 4: Mock (never fails)
  ConstitutionLogger.logService('FireLocationService', 'MOCK_FALLBACK', bounds);
  return _mockService.getActiveFires(bounds);
}
```

---

## Performance Requirements

- **Total call duration**: ≤9s for complete fallback chain (8s × 3 tiers + 50ms mock)
- **EFFIS timeout**: 8s per attempt, 1 retry on 5xx
- **SEPA timeout**: 8s (only if Scotland)
- **Cache timeout**: 200ms (local storage)
- **Mock response**: < 50ms (synchronous)

---

## Testing Requirements

### Unit Tests
1. ✅ EFFIS success → returns live incidents
2. ✅ EFFIS timeout → falls back to SEPA
3. ✅ SEPA success (Scotland) → returns live incidents
4. ✅ SEPA skipped (non-Scotland) → goes to cache
5. ✅ Cache hit → returns cached incidents (freshness=cached)
6. ✅ Cache miss → uses mock fallback
7. ✅ Mock fallback → always succeeds with 0-3 incidents
8. ✅ Geohash cache key generation → correct precision per zoom
9. ✅ Coordinate redaction in logs → LocationUtils.logRedact() called

### Integration Tests
1. ✅ Full fallback chain with mock services
2. ✅ EFFIS WFS API contract (live call to real endpoint, CI=weekly)
3. ✅ Performance: <9s for complete chain

---

## Constitutional Compliance

- **C1 (Code Quality)**: Unit tests required for all fallback paths
- **C2 (Secrets & Logging)**: No API keys in code, coordinates redacted in logs
- **C3 (Accessibility)**: N/A (service layer)
- **C4 (Transparency)**: Source field always populated (effis/sepa/cache/mock)
- **C5 (Resilience)**: Never-fail guarantee via mock fallback, timeout on all tiers

---

**Contract Version**: 1.0  
**Last Updated**: October 19, 2025  
**Status**: Ready for implementation
