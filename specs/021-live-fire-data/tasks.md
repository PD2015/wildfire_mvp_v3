# Tasks: Live Fire Data Display

**Input**: Design documents from `/specs/021-live-fire-data/`  
**Prerequisites**: plan.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

## Execution Flow (main)
```
1. ✅ Loaded plan.md - Dart 3.9.2, Flutter 3.35.5, google_maps_flutter, http, dartz, xml
2. ✅ Loaded design documents:
   → data-model.md: 8 entities extracted
   → contracts/: GwisHotspotService, EffisBurntAreaService
   → research.md: GWIS WMS, Douglas-Peucker, clustering decisions
   → quickstart.md: Validation checklist
3. ✅ Generated 42 tasks across 5 phases
4. ✅ Applied task rules (TDD, parallel markers)
5. ✅ Validated task completeness
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- All paths relative to repository root

---

## Phase 2.0: Setup & Dependencies
*Prepare project for new feature development*

- [ ] T001 Add `xml: ^6.4.2` dependency to pubspec.yaml for GML parsing
- [ ] T002 [P] Create `lib/models/fire_data_mode.dart` with `FireDataMode` and `HotspotTimeFilter` enums
- [ ] T003 [P] Create `lib/models/hotspot.dart` with `Hotspot` value object per data-model.md
- [ ] T004 [P] Create `lib/models/burnt_area.dart` with `BurntArea` value object per data-model.md
- [ ] T005 [P] Create `lib/models/hotspot_cluster.dart` with `HotspotCluster` view model
- [ ] T006 Create mock data file `assets/mock/fire_data.json` with separate hotspots/burntAreas arrays

**Acceptance**: All new files created, `flutter analyze` passes

---

## Phase 2.1: Model Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 2.2
*Write failing tests for all new models*

- [ ] T007 [P] Create `test/unit/models/fire_data_mode_test.dart`
  - Test `FireDataMode.hotspots` is default
  - Test `HotspotTimeFilter` layer mapping (today → viirs.hs.today, thisWeek → viirs.hs.week)

- [ ] T008 [P] Create `test/unit/models/hotspot_test.dart`
  - Test `Hotspot` construction with required fields
  - Test `squareBoundary` calculates 375m square (4 vertices)
  - Test `toFireIncident()` conversion with correct `fireDataType: FireDataType.hotspot`
  - Test FRP → intensity mapping (< 10 → low, 10-50 → moderate, > 50 → high)
  - Test confidence string validation (high/nominal/low only)

- [ ] T009 [P] Create `test/unit/models/burnt_area_test.dart`
  - Test `BurntArea` construction with required fields
  - Test `toFireIncident()` conversion with correct `fireDataType: FireDataType.burntArea`
  - Test `landCover` map parsing
  - Test `isSimplified` flag propagation

- [ ] T010 [P] Create `test/unit/models/hotspot_cluster_test.dart`
  - Test cluster creation from list of hotspots
  - Test `center` calculation as centroid
  - Test `count` getter
  - Test `bounds` calculation for zoom-to-cluster

- [ ] T011 [P] Create `test/unit/models/fire_incident_extended_test.dart`
  - Test new fields: `fireDataType`, `isSimplified`, `landCoverBreakdown`
  - Test validation: hotspot implies no boundaryPoints
  - Test validation: burntArea implies boundaryPoints >= 3
  - Test `isSimplified` only valid for burntArea

**Acceptance**: All tests written and FAILING (no implementation yet)

---

## Phase 2.2: Model Implementation
*Implement models to make tests pass*

- [ ] T012 Extend `lib/models/fire_incident.dart`:
  - Add `FireDataType? fireDataType` field (nullable for backward compat)
  - Add `bool isSimplified = false` field
  - Add `Map<String, double>? landCoverBreakdown` field
  - Update validation in `_validate()` method
  - Update `fromJson()`, `toJson()`, `fromCacheJson()`, `copyWith()`

- [ ] T013 Implement `lib/models/hotspot.dart`:
  - Add 375m square calculation: `List<LatLng> get squareBoundary`
  - Implement `toFireIncident()` conversion method
  - Implement `_intensityFromFrp()` and `_confidenceToPercent()` helpers

- [ ] T014 Implement `lib/models/burnt_area.dart`:
  - Implement `toFireIncident()` conversion method
  - Add land cover map with standard keys
  - Add `isSimplified` property

- [ ] T015 Implement `lib/models/hotspot_cluster.dart`:
  - Implement centroid calculation
  - Implement bounds calculation using LatLngBounds

**Acceptance**: `flutter test test/unit/models/` passes (all green)

---

## Phase 2.3: Service Contract Tests (TDD)
*Write failing contract tests before service implementation*

- [ ] T016 [P] Create `test/contract/gwis_hotspot_service_contract_test.dart`:
  - Test `getHotspots()` returns list for Scotland viewport
  - Test correct layer used for `HotspotTimeFilter.today` (viirs.hs.today)
  - Test correct layer used for `HotspotTimeFilter.thisWeek` (viirs.hs.week)
  - Test empty list returned for Antarctic viewport (no fires)
  - Test GML response parsing
  - Test coordinate order swap (lon,lat → lat,lon)

- [ ] T017 [P] Create `test/contract/effis_burnt_area_service_contract_test.dart`:
  - Test `getBurntAreas()` returns list for Scotland viewport
  - Test polygon simplification to max 500 points
  - Test `isSimplified` flag set when points reduced
  - Test land cover parsing from GeoJSON properties
  - Test `areaHectares` preserved (not recalculated)

**Acceptance**: Contract tests written and FAILING

---

## Phase 2.4: Service Implementation

- [ ] T018 Create `lib/services/gwis_hotspot_service.dart` (interface):
  - Abstract class with `getHotspots()` method per contract

- [ ] T019 Create `lib/services/gwis_hotspot_service_impl.dart`:
  - Constructor injection of `http.Client`
  - Build WMS GetFeatureInfo URL with correct parameters
  - Parse GML response using `package:xml`
  - Handle coordinate order (lon,lat in GML → lat,lon in LatLng)
  - Implement error handling with `Either<ApiError, List<Hotspot>>`
  - Add retry logic (3x) for 408, 503, 504
  - Log coordinates at 2dp only (C2 compliance)

- [ ] T020 Create `lib/services/effis_burnt_area_service.dart` (interface):
  - Abstract class with `getBurntAreas()` method per contract

- [ ] T021 Create `lib/services/effis_burnt_area_service_impl.dart`:
  - Constructor injection of `http.Client`
  - Build WFS GetFeature URL with GeoJSON output
  - Parse GeoJSON response
  - Integrate `PolygonSimplifier` for large polygons
  - Parse land cover properties
  - Set `isSimplified` flag when simplification applied
  - Implement error handling with `Either<ApiError, List<BurntArea>>`

- [ ] T022 Create `lib/services/utils/polygon_simplifier.dart`:
  - Implement Douglas-Peucker algorithm
  - Parameters: tolerance = 0.0009 (~100m at 56°N), maxPoints = 500
  - Recursive implementation
  - Return simplified `List<LatLng>`

- [ ] T023 [P] Create `test/unit/services/polygon_simplifier_test.dart`:
  - Test no simplification when points ≤ 500
  - Test simplification applied when points > 500
  - Test tolerance parameter affects output
  - Test polygon remains valid (≥ 3 points)
  - Performance test: 22,000 points simplified in < 100ms

**Acceptance**: `flutter test test/unit/services/` and `flutter test test/contract/` pass

---

## Phase 3.0: UI Widget Tests (TDD)
*Write failing widget tests before implementation*

- [ ] T024 [P] Create `test/widget/fire_mode_toggle_test.dart`:
  - Test SegmentedButton renders with "Hotspots" and "Burnt Areas" labels
  - Test initial selection is "Hotspots" (default)
  - Test tap calls `onChanged` callback with correct mode
  - Test accessibility: semantic labels present
  - Test touch target ≥ 44dp (C3 compliance)

- [ ] T025 [P] Create `test/widget/hotspot_time_filter_test.dart`:
  - Test FilterChips render with "Today" and "This Week" labels
  - Test initial selection is "Today"
  - Test tap calls `onFilterChanged` callback
  - Test correct chip is visually selected
  - Test touch target ≥ 44dp (C3 compliance)

- [ ] T026 [P] Create `test/widget/hotspot_cluster_marker_test.dart`:
  - Test cluster badge shows correct count
  - Test badge color based on cluster size (1-5, 6-20, 21+)
  - Test tap handler triggers callback
  - Test accessibility label: "X fire detections, tap to zoom"

- [ ] T027 [P] Create `test/widget/fire_details_bottom_sheet_extended_test.dart`:
  - Test "Active Hotspot" educational label for hotspot type
  - Test "Verified Burnt Area" educational label for burntArea type
  - Test simplification notice displayed when `isSimplified = true`
  - Test land cover breakdown displayed as horizontal bars
  - Test "Detected X hours ago" relative time format

**Acceptance**: Widget tests written and FAILING

---

## Phase 3.1: UI Widget Implementation

- [ ] T028 Create `lib/features/map/widgets/fire_mode_toggle.dart`:
  - SegmentedButton with two segments
  - Icons: `Icons.local_fire_department` (hotspots), `Icons.layers` (burnt areas)
  - Semantic labels for accessibility
  - Use existing theme colors

- [ ] T029 Create `lib/features/map/widgets/hotspot_time_filter.dart`:
  - Row of FilterChips: "Today", "This Week"
  - Only visible when mode = hotspots
  - Selected chip uses primary color

- [ ] T030 Create `lib/features/map/utils/hotspot_style_helper.dart`:
  - `Color getFillColor(Hotspot hotspot)` - orange/red based on FRP
  - `Color getStrokeColor(Hotspot hotspot)` - darker variant
  - `const double fillOpacity = 0.5` - more opaque than burnt areas
  - Use RiskPalette colors (C4 compliance)

- [ ] T031 Create `lib/features/map/widgets/hotspot_square_builder.dart`:
  - Converts `Hotspot` to `Polygon` with 4 vertices
  - Uses `HotspotStyleHelper` for colors
  - Includes tap callback for bottom sheet

- [ ] T032 Create `lib/features/map/widgets/hotspot_cluster_marker.dart`:
  - Circular badge with count
  - Size scales with cluster size
  - Uses custom `BitmapDescriptor` for marker icon
  - Includes tap callback for zoom action

- [ ] T033 Extend `lib/widgets/fire_details_bottom_sheet.dart`:
  - Add conditional educational labels based on `fireDataType`
  - Add simplification notice when `isSimplified = true`
  - Add land cover horizontal bar chart
  - Add relative time formatting for detection time

**Acceptance**: `flutter test test/widget/` passes (all green)

---

## Phase 3.2: Controller Extension

- [ ] T034 [P] Create `test/unit/controllers/map_controller_mode_test.dart`:
  - Test mode switching clears previous data type
  - Test filter change triggers data refetch
  - Test clustering triggered at zoom < 10
  - Test individual hotspots at zoom ≥ 10

- [ ] T035 Extend `lib/features/map/controllers/map_controller.dart`:
  - Add `FireDataMode _fireDataMode = FireDataMode.hotspots`
  - Add `HotspotTimeFilter _hotspotTimeFilter = HotspotTimeFilter.today`
  - Add `List<Hotspot> _hotspots = []`
  - Add `List<BurntArea> _burntAreas = []`
  - Add `List<HotspotCluster> _clusters = []`
  - Add `setFireDataMode(FireDataMode mode)` method
  - Add `setHotspotTimeFilter(HotspotTimeFilter filter)` method
  - Add `_clusterHotspots(List<Hotspot> hotspots, double zoom)` method
  - Inject `GwisHotspotService` and `EffisBurntAreaService`

- [ ] T036 Create `lib/features/map/utils/hotspot_clusterer.dart`:
  - `List<HotspotCluster> cluster(List<Hotspot> hotspots, {double radius = 750})`
  - Distance-based clustering algorithm
  - Returns single-item clusters for isolated hotspots

**Acceptance**: `flutter test test/unit/controllers/` passes

---

## Phase 3.3: MapScreen Integration

- [ ] T037 Extend `lib/features/map/screens/map_screen.dart`:
  - Add `FireModeToggle` widget in top-left control area
  - Add `HotspotTimeFilter` chips below mode toggle (visible in hotspots mode)
  - Update `_buildMarkers()` to handle clustered vs individual hotspots
  - Update `_buildPolygons()` to render hotspot squares OR burnt areas based on mode
  - Add zoom change listener to trigger clustering/declustering
  - Handle mode toggle → refetch appropriate data

- [ ] T038 Update `_onCameraMove()` in map_screen.dart:
  - Track current zoom level
  - Trigger reclustering when crossing zoom threshold 10
  - Update `_showPolygons` based on zoom and mode

- [ ] T039 Create empty state handling for each mode:
  - Hotspots mode: "No active fires detected in the last 24 hours"
  - Burnt areas mode: "No verified burnt areas for this season"
  - Include hint to try other mode

**Acceptance**: Visual verification per quickstart.md checklist

---

## Phase 4.0: Integration Tests

- [ ] T040 [P] Create `test/integration/live_fire_hotspots_test.dart`:
  - Test GWIS service → MapController → MapScreen data flow
  - Test mode toggle switches data layer
  - Test time filter changes refetch data
  - Test clustering at low zoom
  - Test individual squares at high zoom
  - Test tap hotspot → bottom sheet with correct content

- [ ] T041 [P] Create `test/integration/live_fire_burnt_areas_test.dart`:
  - Test EFFIS service → MapController → MapScreen data flow
  - Test polygon simplification applied
  - Test tap polygon → bottom sheet with land cover
  - Test simplification notice displayed

- [ ] T042 Create `test/integration/fire_data_fallback_test.dart`:
  - Test service failure → mock data displayed
  - Test "Demo Data" indicator visible
  - Test pull-to-refresh retries live data

**Acceptance**: `flutter test test/integration/` passes

---

## Phase 5.0: Polish & Validation

- [ ] T043 [P] Create `test/performance/hotspot_clustering_test.dart`:
  - Test 100 hotspots clustered in < 50ms
  - Test 500 hotspots clustered in < 200ms

- [ ] T044 [P] Create `test/performance/polygon_rendering_test.dart`:
  - Test 50 simplified polygons render in < 100ms
  - Test 100 hotspot squares render in < 100ms

- [ ] T045 Run `flutter analyze` and fix any new issues

- [ ] T046 Run `dart format lib/ test/` and fix formatting

- [ ] T047 Execute quickstart.md validation checklist manually

- [ ] T048 Update `.github/copilot-instructions.md` with new patterns:
  - Document `FireDataType` usage
  - Document `GwisHotspotService` and `EffisBurntAreaService` patterns
  - Document clustering behavior
  - Document polygon simplification approach

---

## Dependencies Graph

```
Phase 2.0 Setup (T001-T006)
    │
    ▼
Phase 2.1 Model Tests (T007-T011) [parallel]
    │
    ▼
Phase 2.2 Model Implementation (T012-T015)
    │
    ├──────────────────────────────────┐
    ▼                                  ▼
Phase 2.3 Service Contract Tests   Phase 3.0 Widget Tests
(T016-T017) [parallel]             (T024-T027) [parallel]
    │                                  │
    ▼                                  ▼
Phase 2.4 Service Implementation   Phase 3.1 Widget Implementation
(T018-T023)                        (T028-T033)
    │                                  │
    └──────────────┬───────────────────┘
                   ▼
           Phase 3.2 Controller Extension
           (T034-T036)
                   │
                   ▼
           Phase 3.3 MapScreen Integration
           (T037-T039)
                   │
                   ▼
           Phase 4.0 Integration Tests
           (T040-T042) [parallel]
                   │
                   ▼
           Phase 5.0 Polish & Validation
           (T043-T048)
```

---

## Parallel Execution Examples

### Launch Model Tests (T007-T011):
```bash
# All model tests can run in parallel (different files)
flutter test test/unit/models/fire_data_mode_test.dart &
flutter test test/unit/models/hotspot_test.dart &
flutter test test/unit/models/burnt_area_test.dart &
flutter test test/unit/models/hotspot_cluster_test.dart &
flutter test test/unit/models/fire_incident_extended_test.dart &
wait
```

### Launch Contract Tests (T016-T017):
```bash
flutter test test/contract/gwis_hotspot_service_contract_test.dart &
flutter test test/contract/effis_burnt_area_service_contract_test.dart &
wait
```

### Launch Widget Tests (T024-T027):
```bash
flutter test test/widget/fire_mode_toggle_test.dart &
flutter test test/widget/hotspot_time_filter_test.dart &
flutter test test/widget/hotspot_cluster_marker_test.dart &
flutter test test/widget/fire_details_bottom_sheet_extended_test.dart &
wait
```

---

## Constitutional Compliance Checklist

| Gate | Tasks | Verification |
|------|-------|--------------|
| **C1: Code Quality** | T045, T046 | `flutter analyze` clean, code formatted |
| **C2: Secrets & Logging** | T019, T021 | Coordinates logged at 2dp |
| **C3: Accessibility** | T024, T025, T026, T028, T029 | Touch targets ≥ 44dp, semantic labels |
| **C4: Trust & Transparency** | T030, T033 | RiskPalette colors, timestamps, source labels |
| **C5: Resilience** | T019, T021, T042 | Error handling, mock fallback |

---

## Validation Checklist
*GATE: All must be checked before feature complete*

- [ ] All contracts have corresponding tests (T016, T017)
- [ ] All entities have model tasks (T002-T005, T012-T015)
- [ ] All tests come before implementation (TDD phases respected)
- [ ] Parallel tasks truly independent (different files)
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task
- [ ] Constitution gates C1-C5 addressed

---

## Notes

- **TDD Enforcement**: Phases 2.1, 2.3, 3.0 write tests FIRST, expect RED, then implement
- **Mock-First Development**: T006 creates mock data for development without live API
- **Coordinate Privacy**: All services log at 2dp precision per C2
- **Performance Targets**: 50 polygons < 100ms, 100 hotspot clustering < 50ms
- **Backward Compatibility**: `fireDataType` is nullable for existing data

---

*Generated from spec.md, plan.md, data-model.md, contracts/, and FIRE_INCIDENT_MAP_ACTION_PLAN.md*
