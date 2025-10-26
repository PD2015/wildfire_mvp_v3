# Phase 1: Data Model

**Feature**: A10 – Google Maps MVP Map  
**Date**: October 19, 2025  
**Status**: Complete

## Entity Definitions

### 1. FireIncident

**Purpose**: Represents a single active fire location extracted from EFFIS WFS burnt areas data.

**Fields**:
```dart
class FireIncident extends Equatable {
  final String id;                    // Unique identifier (EFFIS feature ID)
  final LatLng location;              // Fire coordinates
  final DataSource source;            // effis, sepa, mock (enum)
  final Freshness freshness;          // live, cached, mock (enum)
  final DateTime timestamp;           // Detection/last update time
  final String intensity;             // "low", "moderate", "high" (from EFFIS properties)
  final String? description;          // Optional fire details (from EFFIS properties)
  final double? areaHectares;         // Optional burnt area size
  
  const FireIncident({
    required this.id,
    required this.location,
    required this.source,
    required this.freshness,
    required this.timestamp,
    required this.intensity,
    this.description,
    this.areaHectares,
  });
  
  @override
  List<Object?> get props => [id, location, source, freshness, timestamp, intensity, description, areaHectares];
}
```

**Validation Rules**:
- `id` must be non-empty
- `location` must have valid coordinates (-90 ≤ lat ≤ 90, -180 ≤ lon ≤ 180)
- `timestamp` must not be in the future
- `intensity` must be one of: "low", "moderate", "high"
- `areaHectares` (if present) must be > 0

**Relationships**:
- Uses `LatLng` from existing models (A4)
- Uses `DataSource` enum from existing FireRisk model (A2)
- Uses `Freshness` enum from existing FireRisk model (A2)

**State Transitions**:
- Live → Cached (when 6h TTL expires but data still in cache)
- Live → Mock (when all services fail, fallback to mock)
- Cached → Live (when fresh EFFIS data fetched)

---

### 2. MapState (Sealed Class Hierarchy)

**Purpose**: Represents the current state of the MapScreen UI and data loading.

**Sealed Base**:
```dart
sealed class MapState extends Equatable {
  const MapState();
}
```

**Concrete States**:

#### MapLoading
```dart
class MapLoading extends MapState {
  const MapLoading();
  
  @override
  List<Object?> get props => [];
}
```
**When Used**: Initial map load, location resolution in progress, no data to display yet.

---

#### MapSuccess
```dart
class MapSuccess extends MapState {
  final List<FireIncident> incidents;
  final LatLng centerLocation;
  final Freshness freshness;
  final DateTime lastUpdated;
  
  const MapSuccess({
    required this.incidents,
    required this.centerLocation,
    required this.freshness,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [incidents, centerLocation, freshness, lastUpdated];
}
```
**When Used**: Data successfully loaded (EFFIS/SEPA/Cache/Mock), map displaying markers.

**Validation Rules**:
- `incidents` can be empty (no fires in visible region)
- `centerLocation` must be valid coordinates
- `lastUpdated` must not be in the future

---

#### MapError
```dart
class MapError extends MapState {
  final String message;
  final List<FireIncident>? cachedIncidents;  // Optional cached fallback data
  final LatLng? lastKnownLocation;
  
  const MapError({
    required this.message,
    this.cachedIncidents,
    this.lastKnownLocation,
  });
  
  @override
  List<Object?> get props => [message, cachedIncidents, lastKnownLocation];
}
```
**When Used**: All services failed (after EFFIS → SEPA → Cache → Mock chain), but may have stale cached data to display.

**Validation Rules**:
- `message` must be non-empty
- If `cachedIncidents` present, must display with "Outdated Data" warning

---

### 3. LatLngBounds

**Purpose**: Represents the visible region of the map for bbox queries.

**Fields**:
```dart
class LatLngBounds extends Equatable {
  final LatLng southwest;  // Bottom-left corner
  final LatLng northeast;  // Top-right corner
  
  const LatLngBounds({
    required this.southwest,
    required this.northeast,
  });
  
  // Computed properties
  LatLng get center => LatLng(
    (southwest.latitude + northeast.latitude) / 2,
    (southwest.longitude + northeast.longitude) / 2,
  );
  
  double get width => northeast.longitude - southwest.longitude;
  double get height => northeast.latitude - southwest.latitude;
  
  // Format for EFFIS WFS bbox query
  String toBboxString() {
    return '${southwest.longitude},${southwest.latitude},${northeast.longitude},${northeast.latitude}';
  }
  
  @override
  List<Object?> get props => [southwest, northeast];
}
```

**Validation Rules**:
- `southwest.latitude` < `northeast.latitude`
- `southwest.longitude` < `northeast.longitude`
- Width and height must be > 0

**Relationships**:
- Constructed from GoogleMapController.getVisibleRegion()
- Passed to FireLocationService.getActiveFires()

---

### 4. FireLocationQuery

**Purpose**: Request object for fetching active fires in a specific region.

**Fields**:
```dart
class FireLocationQuery extends Equatable {
  final LatLngBounds bounds;
  final DateTime? since;         // Optional: only fetch fires after this timestamp
  final int? maxResults;         // Optional: limit results (default: 50)
  final Duration? timeout;       // Optional: service timeout (default: 8s)
  
  const FireLocationQuery({
    required this.bounds,
    this.since,
    this.maxResults = 50,
    this.timeout = const Duration(seconds: 8),
  });
  
  @override
  List<Object?> get props => [bounds, since, maxResults, timeout];
}
```

**Validation Rules**:
- `bounds` must be valid
- `since` (if present) must not be in the future
- `maxResults` (if present) must be > 0 and ≤ 100
- `timeout` must be > 0

---

### 5. RiskAssessmentResult

**Purpose**: Response from point-based fire risk check ("Check risk here" action).

**Fields**:
```dart
class RiskAssessmentResult extends Equatable {
  final LatLng location;
  final double fwiValue;             // Fire Weather Index raw value
  final RiskLevel riskLevel;         // Computed: Low/Moderate/High/VeryHigh/Extreme
  final DataSource source;           // effis, sepa, cache, mock
  final Freshness freshness;         // live, cached, mock
  final DateTime timestamp;
  
  const RiskAssessmentResult({
    required this.location,
    required this.fwiValue,
    required this.riskLevel,
    required this.source,
    required this.freshness,
    required this.timestamp,
  });
  
  @override
  List<Object?> get props => [location, fwiValue, riskLevel, source, freshness, timestamp];
}
```

**Relationships**:
- Reuses existing FireRiskService (A2) for data fetching
- Uses existing RiskLevel enum (from A2)

**Validation Rules**:
- `fwiValue` must be ≥ 0
- `riskLevel` must match fwiValue thresholds (from A2)
- `timestamp` must not be in the future

---

## Enums

### DataSource (Existing from A2)
```dart
enum DataSource {
  effis,   // European Forest Fire Information System
  sepa,    // Scottish Environment Protection Agency
  cache,   // Cached data from previous fetch
  mock,    // Fallback demo data
}
```

### Freshness (Existing from A2)
```dart
enum Freshness {
  live,    // Real-time data from API
  cached,  // Data from cache (< 6h old)
  mock,    // Demo/fallback data
}
```

### RiskLevel (Existing from A2)
```dart
enum RiskLevel {
  low,         // FWI 0-5.2
  moderate,    // FWI 5.2-11.2
  high,        // FWI 11.2-21.3
  veryHigh,    // FWI 21.3-38
  extreme,     // FWI 38+
}
```

---

## Domain Rules

### Fire Incident Staleness
- **Live Data**: Timestamp within last 6 hours, freshness = live
- **Cached Data**: Timestamp 6-24 hours old, freshness = cached (display "Cached" badge)
- **Stale Data**: Timestamp > 24 hours old, do not display (fetch fresh or fallback to mock)

### Map Refresh Triggers
1. **Initial Load**: On MapScreen mounted → fetch center location + fires in default bbox
2. **Camera Idle**: 1 second after user stops panning/zooming → fetch fires in new bbox
3. **Manual Refresh**: User pulls down to refresh → force fetch (bypass cache)
4. **Background Refresh**: Every 10 minutes if app in foreground → silent refresh

### Service Fallback Chain
1. **EFFIS WFS** (primary): Timeout 8s, retry once on 5xx errors
2. **SEPA API** (Scotland only): If location in Scotland bounds, timeout 8s
3. **Cache** (A5): Fetch cached incidents for bbox geohash key
4. **Mock**: Static demo data, never fails

---

## Persistence

### Cache Storage (via A5 CacheService)

**Key Format**:
```
fire_incidents:{geohash}:{zoomLevel}
```
Example: `fire_incidents:gcpue:10`

**Value Format** (JSON):
```json
{
  "version": "1.0",
  "timestamp": "2025-10-19T14:32:00Z",
  "geohash": "gcpue",
  "bbox": "55.9,56.1,-3.3,-3.1",
  "incidents": [
    {
      "id": "effis_12345",
      "lat": 55.9533,
      "lon": -3.1883,
      "source": "effis",
      "freshness": "live",
      "timestamp": "2025-10-19T14:30:00Z",
      "intensity": "moderate",
      "areaHectares": 12.5
    }
  ]
}
```

**TTL**: 6 hours (21600 seconds)

**Eviction**: LRU when cache size > 100 entries (inherited from A5)

---

### API Keys Storage (Platform-Specific)

**Android** (`android/local.properties`):
```properties
GOOGLE_MAPS_API_KEY=AIza....(dev key)
```

**iOS** (`ios/Flutter/Release.xcconfig`):
```
GOOGLE_MAPS_API_KEY=AIza....(prod key)
```

**Note**: Keys restricted by SHA-1 (Android) / bundle ID (iOS), never committed to repo.

---

## Data Flow Diagrams

### Fire Incident Fetch Flow
```
MapController.loadMapData()
  → LocationResolver.getLatLng() (A4)
  → GoogleMapController.getVisibleRegion()
  → FireLocationService.getActiveFires(bounds)
      [Try EFFIS WFS]
        → Success: Parse GeoJSON → List<FireIncident> (freshness=live)
        → Failure: Try SEPA (if Scotland)
      [Try SEPA]
        → Success: Parse JSON → List<FireIncident> (freshness=live)
        → Failure: Try Cache
      [Try Cache (A5)]
        → Hit: Load cached incidents (freshness=cached)
        → Miss: Use Mock
      [Use Mock]
        → Return static incidents (freshness=mock)
  → MapController.setState(MapSuccess(incidents, location, freshness))
  → MapScreen rebuilds with markers
```

### Risk Assessment Flow
```
User taps map at (lat, lon)
  → MapScreen.onMapTap(lat, lon)
  → FireRiskService.getCurrent(lat, lon) (A2)
      [Existing fallback: EFFIS → SEPA → Cache → Mock]
  → Parse FWI value → RiskLevel
  → Show RiskAssessmentChip with source label + timestamp
```

---

## Testing Data

### Mock Fire Incidents (for tests)
```dart
final mockFireIncidents = [
  FireIncident(
    id: 'mock_edinburgh_1',
    location: LatLng(55.9533, -3.1883),  // Edinburgh
    source: DataSource.mock,
    freshness: Freshness.mock,
    timestamp: DateTime.now().subtract(Duration(hours: 2)),
    intensity: 'moderate',
    areaHectares: 8.5,
  ),
  FireIncident(
    id: 'mock_glasgow_1',
    location: LatLng(55.8642, -4.2518),  // Glasgow
    source: DataSource.mock,
    freshness: Freshness.mock,
    timestamp: DateTime.now().subtract(Duration(hours: 5)),
    intensity: 'high',
    areaHectares: 23.2,
  ),
  FireIncident(
    id: 'mock_highlands_1',
    location: LatLng(57.4778, -4.2247),  // Inverness
    source: DataSource.mock,
    freshness: Freshness.mock,
    timestamp: DateTime.now().subtract(Duration(hours: 1)),
    intensity: 'low',
    areaHectares: 3.1,
  ),
];
```

---

## Phase 1 Complete

**Artifacts Generated**:
- ✅ Data model defined (5 entities, 3 enums)
- ✅ Validation rules documented
- ✅ Relationships mapped to existing A2/A4/A5 models
- ✅ Persistence strategy specified
- ✅ Mock test data provided

**Next Phase**: Generate API contracts (Phase 1 continued) → contracts/
