# A11: Burnt Area Polygon Visualization - Phase 1 Tasks

**Issue**: [#54](https://github.com/PD2015/wildfire_mvp_v3/issues/54)
**Branch**: `agent-b/map-fire-polygons`
**Phase**: 1 (Mock Data Implementation)
**Created**: 2025-12-03

---

## Task Overview

| Phase | Tasks | Est. Hours | Status |
|-------|-------|------------|--------|
| 1A | Data Model & Parsing | 2-3 | ✅ Complete |
| 1B | Mock Data Update | 1 | ✅ Complete |
| 1C | Custom Flame Markers | 2-3 | 🔲 Not Started |
| 1D | Polygon Rendering | 3-4 | 🔲 Not Started |
| 1E | Toggle Control | 1-2 | 🔲 Not Started |
| 1F | Testing | 3-4 | 🔲 Not Started |
| 1G | Documentation | 1 | 🔲 Not Started |
| **Total** | | **13-18** | |

---

## Phase 1A: Data Model & Parsing

### Task 1.1: Extend FireIncident Model
- [x] Add `boundaryPoints: List<LatLng>?` field to `FireIncident`
- [x] Update constructor with optional `boundaryPoints` parameter
- [x] Update `props` list for Equatable
- [x] Update `copyWith()` method
- [x] Add validation: if boundaryPoints provided, each must be valid coordinate
- [x] Add minimum 3 points validation for valid polygon

**File**: `lib/models/fire_incident.dart`

### Task 1.2: Update JSON Parsing (fromJson)
- [x] Detect geometry type: "Point" vs "Polygon"
- [x] For Point: existing behavior (boundaryPoints = null)
- [x] For Polygon: extract first ring coordinates
- [x] Handle GeoJSON [lon, lat] → LatLng(lat, lon) conversion
- [x] Ensure polygon ring is closed (first == last point)

**File**: `lib/models/fire_incident.dart`

### Task 1.3: Update Serialization
- [x] Update `toJson()` to include boundaryPoints
- [x] Update `fromCacheJson()` to deserialize boundaryPoints
- [x] Handle null/empty boundaryPoints gracefully

**File**: `lib/models/fire_incident.dart`

### Task 1.4: Update FireIncident.test() Factory
- [x] Add optional `boundaryPoints` parameter to test factory
- [x] Provide sensible defaults (null for point-only tests)

**File**: `lib/models/fire_incident.dart`

### Task 1.5: Add Unit Tests for Polygon Data
- [x] Test FireIncident constructor with boundaryPoints
- [x] Test fromJson with Polygon geometry
- [x] Test fromJson with Point geometry (null boundaryPoints)
- [x] Test toJson/fromCacheJson roundtrip with polygons
- [x] Test validation (invalid coordinates, < 3 points)
- [x] Test copyWith for boundaryPoints field

**File**: `test/unit/models/fire_incident_test.dart` (59 tests)

---

## Phase 1B: Mock Data Update

### Task 2.1: Update active_fires.json
- [x] Convert mock_fire_001 to Polygon geometry (Edinburgh area)
- [x] Convert mock_fire_002 to Polygon geometry (Glasgow area)
- [x] Convert mock_fire_003 to Polygon geometry (Aviemore area)
- [x] Ensure GeoJSON format is valid ([lon, lat] order)
- [x] Ensure all rings are closed (first == last coordinate)

**File**: `assets/mock/active_fires.json`

### Task 2.2: Add Polygon Variety
- [x] Add 1-2 additional polygon features for testing
- [x] Include small (< 5 ha), medium (5-20 ha), large (> 20 ha) examples
- [x] Mix of low, moderate, high intensities
- [x] Added mock_fire_004 as Point-only (for graceful degradation testing)

**File**: `assets/mock/active_fires.json`

---

## Phase 1C: Custom Flame Markers

### Task 3.1: Design Marker Assets
- [ ] Create flame icon design (based on Icons.local_fire_department)
- [ ] Generate PNG assets at 1x, 2x, 3x densities
- [ ] Create color variants: low (green), moderate (orange), high (red)
- [ ] Total: 9 PNG files (3 intensities × 3 densities)

**Files**: `assets/markers/flame_low_1x.png`, etc.

### Task 3.2: Create MarkerIconHelper
- [ ] Create `lib/features/map/utils/marker_icon_helper.dart`
- [ ] Implement icon caching to avoid repeated asset loading
- [ ] Provide `getFlameIcon(String intensity)` async method
- [ ] Handle loading errors gracefully (fallback to default pin)
- [ ] Pre-load all icons during initialization

**File**: `lib/features/map/utils/marker_icon_helper.dart`

### Task 3.3: Integrate Custom Markers in MapScreen
- [ ] Initialize MarkerIconHelper in MapScreen
- [ ] Pre-load icons in `initState` or first build
- [ ] Replace `_getMarkerIcon()` to use MarkerIconHelper
- [ ] Handle async icon loading (show placeholder until ready)

**File**: `lib/features/map/screens/map_screen.dart`

### Task 3.4: Update pubspec.yaml Assets
- [ ] Add `assets/markers/` to pubspec.yaml assets list

**File**: `pubspec.yaml`

---

## Phase 1D: Polygon Rendering

### Task 4.1: Create PolygonStyleHelper
- [ ] Create `lib/features/map/widgets/polygon_style.dart`
- [ ] Implement `getStrokeColor(String intensity)` using RiskPalette
- [ ] Implement `getFillColor(String intensity)` with 35% opacity
- [ ] Document color mappings

**File**: `lib/features/map/widgets/polygon_style.dart`

### Task 4.2: Track Zoom Level
- [ ] Add `double _currentZoom = 8.0` state variable
- [ ] Update zoom in `onCameraMove` callback
- [ ] Implement `_shouldShowPolygons()` helper (checks zoom ≥ 8 AND toggle)

**File**: `lib/features/map/screens/map_screen.dart`

### Task 4.3: Build Polygon Set
- [ ] Create `_buildBurntAreaPolygons(List<FireIncident> incidents)` method
- [ ] Filter incidents where `boundaryPoints != null && isNotEmpty`
- [ ] Convert `LatLng` (our model) → `google_maps_flutter.LatLng`
- [ ] Create `Polygon` objects with styling
- [ ] Enable `consumeTapEvents: true`

**File**: `lib/features/map/screens/map_screen.dart`

### Task 4.4: Add Polygons to GoogleMap
- [ ] Pass `polygons:` parameter to GoogleMap widget
- [ ] Conditionally include based on `_shouldShowPolygons()`
- [ ] Rebuild polygons when zoom changes past threshold

**File**: `lib/features/map/screens/map_screen.dart`

### Task 4.5: Handle Polygon Tap
- [ ] Add `onTap` callback to each Polygon
- [ ] Set `_selectedIncident` to tapped incident
- [ ] Show FireDetailsBottomSheet (reuse existing logic)

**File**: `lib/features/map/screens/map_screen.dart`

---

## Phase 1E: Toggle Control

### Task 5.1: Add Toggle State
- [ ] Add `bool _showPolygons = true` state variable
- [ ] Include in `_shouldShowPolygons()` logic

**File**: `lib/features/map/screens/map_screen.dart`

### Task 5.2: Create PolygonToggleChip Widget
- [ ] Create `lib/features/map/widgets/polygon_toggle_chip.dart`
- [ ] Design chip with icon (layers/visibility) and label
- [ ] Show current state (ON/OFF)
- [ ] Include onToggle callback

**File**: `lib/features/map/widgets/polygon_toggle_chip.dart`

### Task 5.3: Integrate Toggle in MapScreen
- [ ] Add PolygonToggleChip to map overlay (near other chips)
- [ ] Wire toggle to `_showPolygons` state
- [ ] Trigger rebuild on toggle

**File**: `lib/features/map/screens/map_screen.dart`

---

## Phase 1F: Testing

### Task 6.1: Unit Tests - PolygonStyleHelper
- [ ] Test stroke color mapping for each intensity
- [ ] Test fill color with opacity for each intensity
- [ ] Test unknown/invalid intensity fallback

**File**: `test/unit/features/map/widgets/polygon_style_test.dart`

### Task 6.2: Widget Tests - Polygon Rendering
- [ ] Test polygons render when zoom ≥ 8
- [ ] Test polygons hidden when zoom < 8
- [ ] Test polygons hidden when toggle OFF
- [ ] Test polygon count matches incidents with boundaryPoints

**File**: `test/widget/map_polygon_test.dart`

### Task 6.3: Widget Tests - Polygon Toggle
- [ ] Test toggle chip renders
- [ ] Test toggle ON/OFF state changes
- [ ] Test toggle affects polygon visibility

**File**: `test/widget/polygon_toggle_chip_test.dart`

### Task 6.4: Widget Tests - Polygon Tap Interaction
- [ ] Test tapping polygon shows bottom sheet
- [ ] Test correct incident passed to bottom sheet
- [ ] Test closing bottom sheet clears selection

**File**: `test/widget/map_polygon_test.dart`

### Task 6.5: Performance Testing
- [ ] Create test with 50 polygon incidents
- [ ] Measure render time / frame rate
- [ ] Measure memory usage
- [ ] Document results

**File**: `test/performance/map_polygon_performance_test.dart`

---

## Phase 1G: Documentation

### Task 7.1: Create Feature Documentation
- [ ] Create `docs/features/polygon-visualization.md`
- [ ] Document architecture and design decisions
- [ ] Include usage examples
- [ ] Document configuration options (zoom threshold, toggle)

**File**: `docs/features/polygon-visualization.md`

### Task 7.2: Update Copilot Instructions
- [ ] Add polygon implementation patterns section
- [ ] Document PolygonStyleHelper usage
- [ ] Document MarkerIconHelper usage

**File**: `.github/copilot-instructions.md`

### Task 7.3: Update README if Needed
- [ ] Add polygon feature to feature list (if applicable)
- [ ] Update screenshots (optional)

**File**: `README.md`

---

## Completion Checklist

### Functional Requirements
- [ ] `FireIncident` model extended with `boundaryPoints` field
- [ ] Mock data includes 3-5 polygon geometries for Scottish locations
- [ ] Polygons render on MapScreen alongside existing markers
- [ ] Markers use consistent flame icon (not default Google pins)
- [ ] Polygon fill/stroke colors differentiate by intensity
- [ ] Tapping a polygon shows incident details (bottom sheet)
- [ ] User can toggle polygon visibility (default: ON)
- [ ] Polygons only visible at zoom level ≥ 8

### Performance Requirements
- [ ] 50 polygons render without jank (60fps maintained)
- [ ] Memory usage ≤75MB on MapScreen
- [ ] Map remains responsive during pan/zoom with polygons visible

### Code Quality Requirements
- [ ] Unit tests for `FireIncident` with boundary points
- [ ] Unit tests for `PolygonStyleHelper`
- [ ] Widget tests for polygon rendering
- [ ] Code structured for easy extension to live EFFIS data
- [ ] Documentation updated

### Accessibility (C3)
- [ ] Polygon colors meet contrast requirements
- [ ] Screen reader announces polygon details on tap
- [ ] Touch targets meet minimum size requirements

---

## Notes

- Dependencies: None (uses mock data)
- Related issues: #53 (Date filtering - required for Phase 2)
- Phase 2 scope: Live EFFIS data, polygon simplification, clustering
