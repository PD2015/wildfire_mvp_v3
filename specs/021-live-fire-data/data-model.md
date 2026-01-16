# Data Model: Live Fire Data Display

**Feature Branch**: `021-live-fire-data`  
**Date**: 2025-12-09  
**Status**: Complete

---

## Entity Definitions

### 1. FireDataType (NEW Enum)

**Purpose**: Distinguish between hotspot detections and verified burnt areas.

```dart
/// Type of fire data for rendering and display decisions
enum FireDataType {
  /// Real-time satellite thermal detection (375m pixel)
  hotspot,
  
  /// Verified post-fire burnt area perimeter
  burntArea,
}
```

**Usage**:
- Hotspots → render as 375m squares, show detection time
- Burnt areas → render as polygons, show official AREA_HA

---

### 2. FireIncident (EXTENDED)

**Purpose**: Extended with new fields for hotspot/burnt area distinction.

**New Fields**:
| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `fireDataType` | `FireDataType?` | Hotspot or burnt area | Optional for backward compat |
| `isSimplified` | `bool` | Polygon was simplified | Default: false |
| `landCoverBreakdown` | `Map<String, double>?` | Land cover percentages | Values 0-100 |

**Existing Fields (unchanged)**:
| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier |
| `location` | `LatLng` | Centroid coordinates |
| `source` | `DataSource` | effis, sepa, cache, mock |
| `freshness` | `Freshness` | live, cached |
| `timestamp` | `DateTime` | When data was recorded |
| `intensity` | `String` | low, moderate, high |
| `description` | `String?` | Location description |
| `areaHectares` | `double?` | Official EFFIS area (authoritative) |
| `boundaryPoints` | `List<LatLng>?` | Polygon vertices |
| `detectedAt` | `DateTime?` | First detection time |
| `sensorSource` | `String?` | Satellite sensor name |
| `confidence` | `double?` | Detection confidence 0-100 |
| `frp` | `double?` | Fire Radiative Power (MW) |
| `lastUpdate` | `DateTime?` | Last data update |

**Validation Rules**:
- `fireDataType == hotspot` implies `boundaryPoints == null` (point data)
- `fireDataType == burntArea` implies `boundaryPoints?.length >= 3` if polygon
- `isSimplified == true` implies `fireDataType == burntArea`
- `landCoverBreakdown` values must sum to ≤ 100

---

### 3. Hotspot (VALUE OBJECT)

**Purpose**: Represents a single satellite thermal detection.

```dart
class Hotspot extends Equatable {
  final String id;
  final LatLng location;
  final DateTime acquisitionTime;
  final String satellite;        // N20, N21, SUOMI
  final String confidence;       // high, nominal, low
  final double? frp;             // Fire Radiative Power (MW)
  final bool isNightDetection;
  final double? brightnessMir;   // Mid-infrared temperature (K)
  final double? brightnessTir;   // Thermal infrared temperature (K)
  
  // Calculated from location
  List<LatLng> get squareBoundary => calculateSquare(location);
}
```

**Conversion to FireIncident**:
```dart
FireIncident toFireIncident() => FireIncident(
  id: id,
  location: location,
  source: DataSource.effis,
  freshness: Freshness.live,
  timestamp: acquisitionTime,
  intensity: _intensityFromFrp(frp),
  detectedAt: acquisitionTime,
  sensorSource: satellite,
  confidence: _confidenceToPercent(confidence),
  frp: frp,
  fireDataType: FireDataType.hotspot,
  isSimplified: false,
);

String _intensityFromFrp(double? frp) {
  if (frp == null || frp < 10) return 'low';
  if (frp < 50) return 'moderate';
  return 'high';
}
```

---

### 4. BurntArea (VALUE OBJECT)

**Purpose**: Represents a verified burnt area perimeter.

```dart
class BurntArea extends Equatable {
  final String id;
  final LatLng centroid;
  final List<LatLng> boundary;
  final double areaHectares;      // Official EFFIS value
  final DateTime fireDate;        // First detection date
  final DateTime lastUpdate;      // Polygon update date
  final String? province;
  final String? commune;
  final Map<String, double> landCover;  // broadleaved, coniferous, etc.
  final bool isSimplified;
}
```

**Land Cover Keys**:
| Key | Description |
|-----|-------------|
| `broadleaved` | Broadleaved forest |
| `coniferous` | Coniferous forest |
| `mixed` | Mixed forest |
| `sclerophyllous` | Sclerophyllous vegetation |
| `transitional` | Transitional woodland |
| `otherNatural` | Moorland, heathland |
| `other` | Other land cover |

**Conversion to FireIncident**:
```dart
FireIncident toFireIncident() => FireIncident(
  id: id,
  location: centroid,
  source: DataSource.effis,
  freshness: Freshness.live,
  timestamp: fireDate,
  intensity: _intensityFromArea(areaHectares),
  areaHectares: areaHectares,
  boundaryPoints: boundary,
  detectedAt: fireDate,
  sensorSource: 'MODIS',
  lastUpdate: lastUpdate,
  fireDataType: FireDataType.burntArea,
  isSimplified: isSimplified,
  landCoverBreakdown: landCover,
  description: commune ?? province,
);
```

---

### 5. HotspotCluster (VIEW MODEL)

**Purpose**: Groups nearby hotspots for display at low zoom.

```dart
class HotspotCluster extends Equatable {
  final LatLng center;
  final List<Hotspot> hotspots;
  final double radius;  // meters
  
  int get count => hotspots.length;
  
  /// Bounds for zoom-to-cluster action
  LatLngBounds get bounds => _calculateBounds(hotspots);
}
```

**Clustering Rules**:
- Group hotspots within 750m (2× pixel size)
- Center = centroid of all hotspots in cluster
- Display as single marker with count badge
- Tap → zoom to bounds at level 10

---

### 6. FireDataMode (UI STATE)

**Purpose**: Currently selected display mode.

```dart
enum FireDataMode {
  hotspots,   // Active fire detections
  burntAreas, // Verified burnt perimeters
}
```

---

### 7. HotspotTimeFilter (UI STATE)

**Purpose**: Time filter for hotspot display.

```dart
enum HotspotTimeFilter {
  today,      // Last 24 hours (viirs.hs.today)
  thisWeek,   // Last 7 days (viirs.hs.week)
}
```

**Layer Mapping**:
| Filter | GWIS Layer |
|--------|------------|
| today | `viirs.hs.today` |
| thisWeek | `viirs.hs.week` |

---

### 8. MapControllerState (EXTENDED)

**Purpose**: Extended MapSuccess with mode and filter state.

**New Fields in MapSuccess**:
| Field | Type | Description |
|-------|------|-------------|
| `fireDataMode` | `FireDataMode` | Current display mode |
| `hotspotTimeFilter` | `HotspotTimeFilter` | Current time filter |
| `hotspots` | `List<Hotspot>` | Raw hotspot data |
| `burntAreas` | `List<BurntArea>` | Raw burnt area data |
| `clusters` | `List<HotspotCluster>` | Computed clusters |

---

## Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                      MapController                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ FireDataMode │  │ TimeFilter   │  │ zoom level       │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                    │            │
│         ▼                 ▼                    ▼            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   Data Selection                      │  │
│  │  mode=hotspots → GwisHotspotService.fetch()          │  │
│  │  mode=burntAreas → EffisBurntAreaService.fetch()     │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Rendering                          │  │
│  │  zoom < 10 + hotspots → HotspotCluster markers       │  │
│  │  zoom ≥ 10 + hotspots → 375m Square polygons         │  │
│  │  zoom ≥ 8 + burntAreas → Simplified polygons         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## State Transitions

### Mode Toggle

```
User taps "Burnt Areas" segment
  → fireDataMode = FireDataMode.burntAreas
  → Clear hotspots from display
  → Fetch burnt areas for viewport
  → Render burnt area polygons
```

### Time Filter Change

```
User taps "This Week" filter chip
  → hotspotTimeFilter = HotspotTimeFilter.thisWeek
  → Fetch from viirs.hs.week layer
  → Re-cluster hotspots
  → Render updated display
```

### Zoom Change (Clustering)

```
User zooms from 8 → 10
  → zoom >= 10 detected
  → Dissolve clusters into individual hotspots
  → Render 375m squares for each hotspot
```

---

## Validation Rules Summary

| Entity | Rule | Error Message |
|--------|------|---------------|
| FireIncident | `fireDataType == hotspot` → `boundaryPoints == null` | "Hotspots cannot have polygon boundaries" |
| FireIncident | `isSimplified` → `fireDataType == burntArea` | "Only burnt areas can be simplified" |
| Hotspot | `confidence ∈ {high, nominal, low}` | "Invalid confidence level" |
| Hotspot | `frp >= 0` if present | "FRP must be non-negative" |
| BurntArea | `boundary.length >= 3` | "Polygon requires at least 3 points" |
| BurntArea | `areaHectares > 0` | "Area must be positive" |
| HotspotCluster | `hotspots.isNotEmpty` | "Cluster must contain hotspots" |
| LandCover | `values.sum <= 100` | "Land cover percentages cannot exceed 100%" |

---

**Result**: Data model design complete. Ready for contract generation.
