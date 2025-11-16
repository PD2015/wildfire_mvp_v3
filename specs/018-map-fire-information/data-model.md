# Data Model: Map Fire Information Sheet

## Core Entities

### FireIncident (Enhanced)
**Purpose**: Represents active fire detection with comprehensive satellite sensor data
**Relationships**: Associated with RiskAssessment via coordinates, cached by spatial location

**Fields**:
```dart
class FireIncident extends Equatable {
  final String id;                    // Unique incident identifier
  final LatLng location;             // Geographic coordinates
  final DateTime detectedAt;        // When fire was first detected (NEW)
  final String source;               // Satellite sensor: VIIRS, MODIS, etc (NEW)  
  final double confidence;           // Detection confidence percentage 0-100 (NEW)
  final double? frp;                 // Fire Radiative Power in MW (NEW)
  final DateTime lastUpdate;        // Most recent data update (NEW)
  final DataSource dataSource;      // EFFIS, SEPA, Cache, Mock (existing)
  final Freshness freshness;        // Live, Cached, Stale (existing)
  final String? description;        // Optional fire description (existing)
  final double? areaHectares;       // Burned area if available (existing)
}
```

**Validation Rules**:
- `id` must be non-empty string
- `location` must have valid lat/lon coordinates  
- `detectedAt` must be in past, not future
- `confidence` must be 0.0-100.0 range
- `frp` must be positive if provided
- `lastUpdate` must be >= detectedAt
- `source` must be valid sensor identifier (VIIRS, MODIS, LANDSAT, etc)

**State Transitions**: 
- Fresh → Cached (when stored for repeat access)
- Live → Stale (when age > 6 hours)

### RiskAssessment  
**Purpose**: Wildfire risk evaluation for fire incident location
**Relationships**: One-to-one with FireIncident coordinates, sourced from EffisService

**Fields**:
```dart
class RiskAssessment extends Equatable {
  final LatLng location;            // Assessment coordinates
  final RiskLevel level;            // Very Low to Extreme classification
  final double fwiValue;            // Raw Fire Weather Index value
  final DateTime assessmentTime;    // When risk was calculated
  final DataSource source;          // EFFIS, SEPA, Cache, Mock
  final Freshness freshness;        // Data recency indicator
}
```

**Validation Rules**:
- `location` coordinates must match fire incident
- `level` must correspond to fwiValue thresholds
- `assessmentTime` must be recent (< 24 hours for live data)
- `fwiValue` must be non-negative

### DistanceCalculation
**Purpose**: User location to fire incident distance and bearing
**Relationships**: Calculated from user location and FireIncident coordinates

**Fields**:
```dart
class DistanceCalculation extends Equatable {
  final double distanceKm;          // Great circle distance in kilometers
  final String bearing;             // Cardinal direction (e.g., "Northeast")
  final double bearingDegrees;      // Precise bearing 0-360 degrees
  final DateTime calculatedAt;      // When calculation performed
  final bool isLocationPermitted;   // Whether user granted location access
}
```

**Validation Rules**:
- `distanceKm` must be non-negative
- `bearingDegrees` must be 0.0-360.0 range
- `bearing` must be valid cardinal/intercardinal direction

### ActiveFiresResponse
**Purpose**: API response wrapper for viewport fire incident queries
**Relationships**: Contains list of FireIncident objects within bounds

**Fields**:
```dart
class ActiveFiresResponse extends Equatable {
  final List<FireIncident> incidents;    // Fire incidents in viewport
  final LatLngBounds queriedBounds;     // Requested geographic bounds
  final Duration timeWindow;            // Query time range (e.g., 24 hours)
  final DateTime responseTime;          // When response was generated
  final DataSource source;              // API source identifier
  final int totalCount;                 // Total incidents (may exceed list if limited)
  final bool hasMoreResults;            // Whether additional results available
}
```

**Validation Rules**:
- `incidents` list must not be null (empty allowed)
- All incidents must fall within `queriedBounds`
- `responseTime` must be recent
- `totalCount` must be >= incidents.length

### FireMarkerState
**Purpose**: UI state for map marker display and interaction
**Relationships**: One-to-one with FireIncident, manages selection and display state

**Fields**:
```dart
class FireMarkerState extends Equatable {
  final String incidentId;           // Reference to FireIncident
  final bool isSelected;             // Whether marker is currently selected  
  final bool isVisible;              // Whether marker should be displayed
  final MarkerSize size;             // Small, Medium, Large based on FRP/confidence
  final Color color;                 // Marker color based on age/confidence
  final String semanticLabel;        // Accessibility label for screen readers
}
```

**Validation Rules**:
- `incidentId` must reference valid FireIncident
- Only one marker can be selected at a time
- `semanticLabel` must describe fire details for accessibility

### BottomSheetState
**Purpose**: UI state management for fire details bottom sheet
**Relationships**: Contains FireIncident, RiskAssessment, and DistanceCalculation

**Fields**:  
```dart
class BottomSheetState extends Equatable {
  final FireIncident? incident;           // Currently displayed fire incident
  final RiskAssessment? riskAssessment;   // Associated risk data
  final DistanceCalculation? distance;    // Distance from user location
  final bool isVisible;                   // Whether sheet is displayed
  final bool isLoading;                   // Loading risk/distance data
  final String? errorMessage;             // Error state description
  final bool canRetry;                    // Whether retry action available
}
```

**State Transitions**:
- Hidden → Loading (when marker tapped, loading risk/distance)
- Loading → Displayed (when all data loaded successfully)  
- Loading → Error (when risk lookup or distance calculation fails)
- Error → Loading (when user taps retry)
- Displayed → Hidden (when user dismisses sheet)

**Validation Rules**:
- `incident` required when visible unless in error state
- `errorMessage` required when in error state
- Cannot be both loading and error simultaneously

## Data Flow Patterns

### Fire Incident Loading
1. **Viewport Change**: User pans/zooms map
2. **Debounced Query**: Wait 300ms for camera to settle  
3. **Cache Check**: Look for existing incidents in bounds
4. **API Request**: Fetch fresh data if cache miss/stale
5. **Marker Update**: Display fire markers on map
6. **Cache Store**: Store results for future viewport queries

### Bottom Sheet Display
1. **Marker Tap**: User selects fire marker
2. **Sheet Open**: Display basic fire incident data immediately
3. **Risk Lookup**: Parallel fetch of risk assessment for coordinates
4. **Distance Calc**: Calculate distance/bearing from user location
5. **Data Merge**: Combine fire + risk + distance into complete display
6. **Error Handling**: Show retry options for failed lookups

### Cache Management
- **Spatial Indexing**: Use geohash for efficient viewport queries
- **TTL Policy**: 6-hour expiration for live data freshness
- **LRU Eviction**: Remove oldest when storage limit reached
- **Offline Support**: Display cached incidents when network unavailable

## Constitutional Compliance

### C1. Code Quality & Tests
- All models use Equatable for value comparison
- Immutable objects with copyWith methods
- Comprehensive validation rules with unit tests
- JSON serialization/deserialization with error handling

### C2. Secrets & Logging  
- No secrets in model definitions
- Coordinate logging via GeographicUtils.logRedact (2-3 dp precision)
- Structured logging with incident IDs, not raw coordinates

### C3. Accessibility
- Semantic labels included in marker and bottom sheet state
- Screen reader descriptions for all fire data fields
- Color-independent information display (text + icons)

### C4. Trust & Transparency
- Data source tracking at model level (EFFIS/SEPA/Cache/Mock)
- Timestamp fields for data freshness indicators
- Freshness enumeration for UI transparency
- Demo data indicators via DataSource.mock

### C5. Resilience & Test Coverage  
- Optional fields for partial data scenarios
- Error state modeling in BottomSheetState
- Retry capability built into state management
- Fallback values for missing sensor data