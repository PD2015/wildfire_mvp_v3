# Research: Live Fire Data Display

**Feature Branch**: `021-live-fire-data`  
**Date**: 2025-12-09  
**Status**: Complete

---

## Research Topics

### 1. GWIS Hotspot API (viirs.hs.today, viirs.hs.week)

**Decision**: Use GWIS WMS endpoint for real-time hotspot display

**Rationale**:
- GWIS endpoint (`maps.effis.emergency.copernicus.eu/gwis`) provides current data
- Legacy EFFIS hotspot layers (`ms:viirs.hs`) contain stale data from October 2021
- WMS GetFeatureInfo returns hotspot details on tap
- WMTS tiles available for clustered display at low zoom

**Alternatives Considered**:
1. NASA FIRMS API - Requires registration, no burnt area data
2. EFFIS WFS hotspots - Data stale since October 2021
3. Direct EFFIS WFS - Only burnt areas current, not hotspots

**API Endpoints**:
```
# Real-time hotspots (WMS)
https://maps.effis.emergency.copernicus.eu/gwis
  ?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo
  &LAYERS=viirs.hs.today&QUERY_LAYERS=viirs.hs.today
  &CRS=EPSG:4326&BBOX={bbox}&INFO_FORMAT=application/vnd.ogc.gml

# WMTS tiles for clustered display
https://maps.effis.emergency.copernicus.eu/gwist/wmts
  ?SERVICE=WMTS&VERSION=1.0.0&REQUEST=GetTile
  &LAYER=viirs.hs.today&TILEMATRIXSET=EPSG:3857
```

**Response Fields**:
| Field | Description | Example |
|-------|-------------|---------|
| id | Unique hotspot ID | `41646136449` |
| acq_at | Detection time (UTC) | `2025-12-08 01:17:00` |
| CLASS | Time classification | `1DAY_2` |
| lat/lon | Coordinates | `57.2, -3.8` |
| frp | Fire Radiative Power (MW) | `15.3` |
| confidence | Detection confidence | `high` |
| satellite | Source satellite | `N20` |

---

### 2. EFFIS Burnt Area API (modis.ba.poly.season)

**Decision**: Use EFFIS WFS endpoint for burnt area polygon data

**Rationale**:
- WFS returns GeoJSON with polygon boundaries and AREA_HA
- Current seasonal data maintained and updated
- Land cover breakdown available (broadleaved, coniferous, moorland, etc.)
- Existing fixture data (fire 273772) proves API works

**Alternatives Considered**:
1. GWIS for burnt areas - Not available on GWIS endpoint
2. NRT layer (effis.nrt.ba.poly) - Less detailed, for near-real-time
3. Cumulative layer (modis.ba.poly) - Too large, includes all history

**API Endpoint**:
```
https://maps.effis.emergency.copernicus.eu/effis
  ?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature
  &TYPENAMES=ms:modis.ba.poly.season
  &BBOX={minLat},{minLon},{maxLat},{maxLon},EPSG:4326
  &OUTPUTFORMAT=geojson&COUNT=100
```

**Response Fields**:
| Field | Description | Example |
|-------|-------------|---------|
| ms:id | Fire ID | `273772` |
| ms:FIREDATE | First detection | `2025-06-28T11:53:00` |
| ms:LASTUPDATE | Polygon update date | `2025-07-09` |
| ms:AREA_HA | Burnt area (hectares) | `9809.46` |
| ms:COUNTRY | Country code | `UK` |
| ms:PROVINCE | Region | `Inverness & Nairn` |
| ms:OTHER_NATURAL | Moorland % | `93.24` |
| gml:posList | Polygon coordinates | `57.47 -3.62 ...` |

---

### 3. Hotspot Display as 375m Squares

**Decision**: Render hotspots as 375m × 375m squares using Google Maps `Polygon` with 4 vertices

**Rationale**:
- VIIRS satellite pixel size is 375m nominal resolution
- Pin markers would misrepresent detection accuracy
- Square visualization educates users about satellite limitations
- Consistent with scientific representation

**Implementation Approach**:
```dart
// Calculate square corners from center point
List<LatLng> calculateHotspotSquare(LatLng center) {
  // 375m ≈ 0.00337° latitude at Scottish latitudes (~56°)
  // Longitude correction: 375m ÷ cos(56°) ≈ 0.00602°
  const halfSizeLat = 0.001685;  // ~187.5m
  const halfSizeLon = 0.00301;   // ~187.5m at 56°
  
  return [
    LatLng(center.latitude - halfSizeLat, center.longitude - halfSizeLon),
    LatLng(center.latitude - halfSizeLat, center.longitude + halfSizeLon),
    LatLng(center.latitude + halfSizeLat, center.longitude + halfSizeLon),
    LatLng(center.latitude + halfSizeLat, center.longitude - halfSizeLon),
  ];
}
```

---

### 4. Hotspot Clustering Strategy

**Decision**: Cluster hotspots within 750m at zoom < 10, show individuals at zoom ≥ 10

**Rationale**:
- 750m = 2× pixel size prevents overlap display
- Zoom 10 ≈ 150m/pixel - individual squares visible
- Clustering reduces render overhead at regional view
- Consistent with Google Maps marker clustering patterns

**Implementation Approach**:
- Use simple distance-based clustering (no library)
- Cluster badge shows count (e.g., "5 detections")
- Tap cluster → zoom to level 10 centered on cluster
- At zoom ≥ 10, dissolve clusters into individual squares

---

### 5. Polygon Simplification Algorithm

**Decision**: Use Douglas-Peucker algorithm at 100m tolerance, max 500 points

**Rationale**:
- Fire 273772 has 22,020 points - too many for mobile rendering
- Douglas-Peucker is standard, proven algorithm
- 100m tolerance preserves shape at map display scales
- 500 point cap ensures render performance

**Implementation Approach**:
```dart
// Douglas-Peucker simplification
List<LatLng> simplifyPolygon(List<LatLng> points, double tolerance) {
  if (points.length <= 500) return points;
  
  // Recursive Douglas-Peucker algorithm
  // tolerance = 100m = ~0.0009° at Scottish latitudes
  return douglasPeucker(points, 0.0009);
}
```

**Performance Target**:
- 50 polygons must render in < 100ms (existing test)
- Simplified polygon (500 points) renders in < 5ms

---

### 6. Mode Toggle UX (Hotspots vs Burnt Areas)

**Decision**: Mutually exclusive toggle using SegmentedButton

**Rationale**:
- Overlapping hotspots and burnt areas would be visually confusing
- SegmentedButton provides clear state indication
- Default to hotspots (what's burning now = primary concern)
- Session-based state (resets on app restart)

**Implementation**:
```dart
enum FireDataMode {
  hotspots,   // Default - what's burning now
  burntAreas, // Historical - what burned this season
}
```

---

### 7. Time Filter Implementation

**Decision**: Chip-based filters for Today/This Week/This Season

**Rationale**:
- FilterChip is accessible (44dp) and familiar
- Different filters for each mode makes sense contextually
- Hotspots: Today (24h), This Week (7d)
- Burnt Areas: This Season (March-September for fire season)

**Filter Behavior**:
| Mode | Default Filter | Options |
|------|---------------|---------|
| Hotspots | Today | Today, This Week |
| Burnt Areas | This Season | This Season only |

---

### 8. FireDataType Enum Extension

**Decision**: Add `fireDataType` field to FireIncident model

**Rationale**:
- Distinguish hotspot points from burnt area polygons
- Enable proper rendering (square vs polygon)
- Support filtering in UI
- Maintain backward compatibility with existing code

**Schema Change**:
```dart
enum FireDataType {
  hotspot,    // Real-time thermal detection
  burntArea,  // Verified post-fire perimeter
}

// Add to FireIncident
final FireDataType? fireDataType;  // null = legacy (treat as burntArea)
```

---

### 9. Simplification Status Flag

**Decision**: Add `isSimplified` flag to FireIncident model

**Rationale**:
- Users should know when polygon is approximate
- Display notice: "Boundary simplified for display. Official size: X hectares."
- Original AREA_HA is authoritative, not calculated from simplified polygon
- Transparency builds trust (C4 compliance)

**Schema Change**:
```dart
// Add to FireIncident
final bool isSimplified;  // default false
```

---

### 10. Error Handling and Fallback Strategy

**Decision**: Fallback to mock data with visible indicator

**Rationale**:
- Constitution C5: "Fallbacks, not blanks"
- User should never see empty map due to service failure
- Mock data labeled clearly as "Demo Data"
- Retry available via pull-to-refresh

**Fallback Chain**:
1. GWIS/EFFIS live data (primary)
2. Cached data (if available, marked as cached)
3. Mock data (last resort, marked as demo)

---

## Resolved Unknowns

All technical unknowns from the specification have been resolved:

| Unknown | Resolution |
|---------|------------|
| GWIS API endpoint | `maps.effis.emergency.copernicus.eu/gwis` (WMS) |
| Hotspot layer | `viirs.hs.today`, `viirs.hs.week` |
| Burnt area layer | `ms:modis.ba.poly.season` |
| Square size calculation | 375m = ~0.00337° lat × 0.00602° lon at 56° |
| Clustering threshold | 750m at zoom < 10 |
| Simplification algorithm | Douglas-Peucker, 100m tolerance, 500 max points |
| Mode toggle widget | SegmentedButton (Material 3) |
| Time filter widget | FilterChip |

---

**Result**: All research complete. Ready for Phase 1 design.
