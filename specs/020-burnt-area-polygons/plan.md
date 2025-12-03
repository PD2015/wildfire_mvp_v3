# A11: Burnt Area Polygon Visualization - Implementation Plan

**Issue**: [#54](https://github.com/PD2015/wildfire_mvp_v3/issues/54)
**Branch**: `agent-b/map-fire-polygons`
**Phase**: 1 (Mock Data Implementation)
**Created**: 2025-12-03

---

## Executive Summary

This plan outlines the implementation of burnt area polygon visualization on the MapScreen. Phase 1 focuses on mock data integration, polygon rendering, and establishing patterns that will support future live EFFIS data integration (Phase 2).

Additionally, this implementation will standardize fire incident markers to use the `Icons.local_fire_department` flame icon consistent with the rest of the app.

---

## Current State Analysis

### Existing Architecture

| Component | Location | Purpose |
|-----------|----------|---------|
| `FireIncident` model | `lib/models/fire_incident.dart` | Stores fire data with centroid location |
| `MapScreen` | `lib/features/map/screens/map_screen.dart` | Renders Google Map with markers |
| `FireDetailsBottomSheet` | `lib/widgets/fire_details_bottom_sheet.dart` | Shows fire details on marker tap |
| Mock data | `assets/mock/active_fires.json` | GeoJSON FeatureCollection with Point geometries |
| `RiskPalette` | `lib/theme/risk_palette.dart` | Fire risk color tokens |

### Key Findings

1. **Marker Icons**: Currently using `BitmapDescriptor.defaultMarkerWithHue()` - standard Google Maps pins
   - App uses `Icons.local_fire_department` flame icon everywhere else (bottom nav, bottom sheet, risk check button)
   - Inconsistency between map markers and app branding

2. **Data Model**: `FireIncident` only stores `LatLng location` (centroid)
   - No support for polygon boundary coordinates
   - JSON parsing extracts only Point geometry

3. **Google Maps Flutter**: Natively supports `polygons:` parameter
   - `Polygon` class with `points`, `strokeColor`, `fillColor`, `onTap`
   - Works on Web, Android, iOS

4. **Color Palette**: `RiskPalette` has intensity colors but need mapping:
   - `high` → `RiskPalette.veryHigh` (red)
   - `moderate` → `RiskPalette.high` (orange)
   - `low` → `RiskPalette.low` (green)

---

## Design Decisions

### D1: Polygon Data Model

**Decision**: Add optional `boundaryPoints` field to `FireIncident`

```dart
class FireIncident extends Equatable {
  // Existing fields...
  final List<LatLng>? boundaryPoints;  // NEW: Polygon vertices (nullable)
}
```

**Rationale**:
- Optional field maintains backward compatibility
- Incidents without polygons (legacy data, point-only sources) work unchanged
- `null` or empty list = point marker only, non-empty = render polygon

### D2: Marker + Polygon Coexistence

**Decision**: Render BOTH markers AND polygons for incidents with boundary data

**Rationale**:
- Markers provide quick visual scan at all zoom levels
- Polygons show detail at higher zoom levels
- Consistent with CAL FIRE, NASA FIRMS patterns

### D3: Zoom Threshold

**Decision**: Show polygons only at zoom level ≥ 8

**Rationale**:
- Below zoom 8, polygons clutter regional view
- At zoom 8+, users are focused on local detail
- Issue specification aligns with this threshold

### D4: Custom Flame Markers

**Decision**: Replace default Google pins with custom flame icon markers

**Approach**:
- Use `BitmapDescriptor.asset()` or `BitmapDescriptor.bytes()` for custom icons
- Generate flame icons at 1x, 2x, 3x resolution for density support
- Color-code by intensity (matching polygon fill colors)

**Rationale**:
- Consistent branding with rest of app (`Icons.local_fire_department`)
- More intuitive than colored pins for wildfire context
- Improves user recognition and trust

### D5: Polygon Styling

**Decision**: Use RiskPalette colors with semi-transparent fills

| Intensity | Stroke Color | Fill Color | Fill Opacity |
|-----------|--------------|------------|--------------|
| low | `RiskPalette.low` | `RiskPalette.low` | 35% |
| moderate | `RiskPalette.high` | `RiskPalette.high` | 35% |
| high | `RiskPalette.veryHigh` | `RiskPalette.veryHigh` | 35% |

**Rationale**:
- Semantic colors from existing palette (C4 compliance)
- 35% opacity allows underlying map features to remain visible
- Stroke provides clear boundary definition

### D6: Toggle Control

**Decision**: Add "Show burnt areas" toggle to map controls (default: ON)

**Location**: AppBar action or floating chip similar to MapSourceChip

**Rationale**:
- Users may want cleaner map view
- Default ON for maximum situational awareness
- Easy to discover and toggle

---

## Implementation Tasks

### Phase 1A: Data Model & Parsing (Est: 2-3 hours)

1. **Extend FireIncident model**
   - Add `boundaryPoints: List<LatLng>?` field
   - Update constructor, props, copyWith
   - Update validation (boundary points should be valid coords if present)

2. **Update JSON parsing**
   - Handle both Point and Polygon geometry types in `fromJson`
   - For Polygon: extract first ring coordinates as boundary
   - For Point: boundaryPoints = null (existing behavior)

3. **Update serialization**
   - `toJson()`: include boundaryPoints if present
   - `fromCacheJson()`: deserialize boundaryPoints

4. **Update tests**
   - Unit tests for FireIncident with polygon data
   - JSON parsing tests for both Point and Polygon geometries

### Phase 1B: Mock Data Update (Est: 1 hour)

1. **Update active_fires.json**
   - Convert existing Point features to Polygon features
   - Add realistic polygon boundaries for Scottish locations
   - Maintain all existing properties

2. **Add variety**
   - 3-5 polygons with varying sizes (small, medium, large)
   - Mix of intensities (low, moderate, high)
   - Some overlapping areas for testing

### Phase 1C: Custom Flame Markers (Est: 2-3 hours)

1. **Generate marker assets**
   - Create flame icon PNGs at multiple densities
   - Color variants for each intensity level
   - Store in `assets/markers/` or `assets/icons/`

2. **Create MarkerIconHelper utility**
   - Cache loaded BitmapDescriptors
   - Provide `getFlameIcon(intensity)` method
   - Handle asset loading asynchronously

3. **Update MapScreen marker creation**
   - Replace `BitmapDescriptor.defaultMarkerWithHue()` with custom icons
   - Pre-load icons during initialization

### Phase 1D: Polygon Rendering (Est: 3-4 hours)

1. **Create PolygonStyleHelper**
   - `lib/features/map/widgets/polygon_style.dart`
   - Map intensity → colors from RiskPalette
   - Consistent with marker icon colors

2. **Track zoom level in MapScreen**
   - Add `_currentZoom` state variable
   - Update in `onCameraMove` callback

3. **Build polygon set**
   - Create `_buildBurntAreaPolygons()` method
   - Filter incidents with non-null boundaryPoints
   - Apply zoom threshold check

4. **Add polygons to GoogleMap**
   - Pass `polygons:` parameter
   - Enable tap events for polygon selection

5. **Handle polygon tap → bottom sheet**
   - Reuse existing FireDetailsBottomSheet
   - Set selectedIncident on polygon tap

### Phase 1E: Toggle Control (Est: 1-2 hours)

1. **Add state variable**
   - `_showPolygons = true` in MapScreen

2. **Create toggle UI**
   - PolygonToggleChip widget similar to MapSourceChip
   - Position in AppBar actions or floating overlay

3. **Wire toggle to polygon rendering**
   - Conditionally include polygons based on toggle state

### Phase 1F: Testing (Est: 3-4 hours)

1. **Unit tests**
   - FireIncident with boundaryPoints
   - PolygonStyleHelper color mapping
   - Zoom threshold logic

2. **Widget tests**
   - Polygon rendering on MapScreen
   - Toggle functionality
   - Polygon tap → bottom sheet

3. **Performance testing**
   - 50 polygon stress test
   - Pan/zoom responsiveness
   - Memory usage monitoring

### Phase 1G: Documentation (Est: 1 hour)

1. **Update copilot-instructions.md**
   - Add polygon implementation patterns
   - Document PolygonStyleHelper usage

2. **Create feature documentation**
   - `docs/features/polygon-visualization.md`
   - Usage examples, architecture decisions

---

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `lib/models/fire_incident.dart` | Modify | Add `boundaryPoints` field |
| `assets/mock/active_fires.json` | Modify | Add polygon geometry |
| `assets/markers/*.png` | Create | Flame icon assets (multiple sizes/colors) |
| `lib/features/map/utils/marker_icon_helper.dart` | Create | Custom marker icon loading |
| `lib/features/map/widgets/polygon_style.dart` | Create | Polygon styling utilities |
| `lib/features/map/widgets/polygon_toggle_chip.dart` | Create | Toggle UI component |
| `lib/features/map/screens/map_screen.dart` | Modify | Add polygon rendering, zoom tracking, toggle |
| `test/unit/models/fire_incident_test.dart` | Modify | Add polygon tests |
| `test/widget/map_polygon_test.dart` | Create | Polygon widget tests |
| `docs/features/polygon-visualization.md` | Create | Feature documentation |

---

## Questions for Clarification

1. **Marker Icon Generation**: Should we generate the flame marker icons programmatically using Canvas/CustomPainter, or create static PNG assets? 
   - Static PNGs are simpler but require multiple asset files
   - Programmatic generation is more flexible but adds complexity

2. **Toggle Persistence**: Should the "Show burnt areas" toggle state persist across sessions (SharedPreferences)?
   - Default behavior: reset to ON each launch
   - Persistent: remember user preference

3. **Polygon Tap Priority**: When a marker and polygon overlap, which should receive tap events?
   - Current design: marker takes priority (smaller, more precise)
   - Alternative: polygon takes priority, marker is decorative only

4. **Empty Polygon Handling**: If an incident has `boundaryPoints` but it's empty/invalid, should we:
   - Fall back to marker only (graceful degradation)
   - Log warning and skip entirely
   - Show marker with visual indicator of missing boundary data

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Custom marker icons slow to load | Medium | Low | Pre-load during map initialization, show default until ready |
| Polygon rendering performance | Low | Medium | Benchmark with 50+ polygons, implement clustering if needed |
| Touch target issues (small polygons) | Medium | Medium | Ensure minimum visual size, combine with marker taps |
| Web platform differences | Low | Low | Test on Chrome early, Google Maps Flutter Web has good polygon support |

---

## Success Criteria

1. ✅ Polygons render correctly at zoom ≥ 8
2. ✅ Markers use consistent flame icon throughout
3. ✅ Polygon colors match intensity (RiskPalette)
4. ✅ Tapping polygon shows bottom sheet
5. ✅ Toggle controls polygon visibility
6. ✅ 50 polygons render at 60fps
7. ✅ All existing tests pass
8. ✅ New tests cover polygon functionality

---

## References

- [Issue #54: Burnt Area Polygon Visualization](https://github.com/PD2015/wildfire_mvp_v3/issues/54)
- [Google Maps Flutter Polygon API](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/Polygon-class.html)
- [GeoJSON Polygon Specification](https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.6)
