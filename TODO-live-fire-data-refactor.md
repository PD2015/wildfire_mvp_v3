# Live Fire Data Refactor - TODO List

**Branch:** `021-live-fire-data`  
**Goal:** Fix data flow so MapScreen renders from `Hotspot` and `BurntArea` models via live services, with mock fallback

---

## Phase 1: Clean Map Data Flow Architecture

### 1.1 Create Mock Services Matching Live API Structure
- [x] Create `MockGwisHotspotService` implementing `GwisHotspotService` interface ✅
- [x] Create `MockEffisBurntAreaService` implementing `EffisBurntAreaService` interface ✅
- [x] Create `assets/mock/hotspots.json` - matching GWIS WFS response structure ✅
- [x] Create `assets/mock/burnt_areas.json` - matching EFFIS WFS response structure ✅

### 1.2 Update MapScreen to Render from Controller's Live Data Collections
- [x] In hotspots mode: render markers from `_controller.hotspots` (List<Hotspot>) ✅
- [x] In burnt areas mode: render markers/polygons from `_controller.burntAreas` (List<BurntArea>) ✅
- [x] Remove `_updateMarkersForMode(MapSuccess state)` dependency on `state.incidents` ✅
- [x] Remove `_updatePolygonsForMode(MapSuccess state)` dependency on `state.incidents` ✅

### 1.3 Simplify Burnt Area Styling
- [x] All burnt areas render as single red color (no intensity grading) ✅
- [x] Update `PolygonStyleHelper` to return fixed red color for burnt areas ✅

---

## Phase 2: Wire Up Mock Fallback

### 2.1 Update MapController Fallback Behavior
- [x] When `GwisHotspotService` fails → use `MockGwisHotspotService` ✅
- [x] When `EffisBurntAreaService` fails → use `MockEffisBurntAreaService` ✅
- [x] Set `_isUsingMockData = true` appropriately ✅

### 2.2 Update App.dart Dependency Injection
- [x] Mock services initialized internally by MapController (no DI change needed) ✅

---

## Phase 3: Testing (Phase 1+2 Validation)

- [x] Unit tests for `MockGwisHotspotService` ✅ (7 tests)
- [x] Unit tests for `MockEffisBurntAreaService` ✅ (11 tests)
- [x] Unit tests for `Hotspot` model parsing ✅ (18 tests - pre-existing)
- [x] Unit tests for `BurntArea` model parsing ✅ (22 tests - pre-existing)
- [x] Integration test: fallback to mock when live fails ✅ (8 tests)
- [ ] Widget tests for MapScreen rendering from `Hotspot` and `BurntArea` models

---

## Phase 4: Fire Details Bottom Sheet Refactor

### 4.1 Create Hotspot Details Display
- [ ] Review `Hotspot` model fields and match to GWIS API response
- [ ] Create `HotspotDetailsBottomSheet` widget with:
  - FRP (Fire Radiative Power) in MW
  - Confidence level (high/nominal/low)
  - Detection timestamp
  - Coordinates
  - Intensity indicator (derived from FRP)

### 4.2 Create Burnt Area Details Display  
- [ ] Review `BurntArea` model fields and match to EFFIS API response
- [ ] Create `BurntAreaDetailsBottomSheet` widget with:
  - Area in hectares
  - Fire date
  - Land cover breakdown (if available)
  - Season year
  - Polygon info (number of vertices, simplified flag)

### 4.3 Update MapScreen to Use New Bottom Sheets
- [ ] Remove `FireIncident` conversion code
- [ ] Show `HotspotDetailsBottomSheet` when tapping hotspot marker
- [ ] Show `BurntAreaDetailsBottomSheet` when tapping burnt area marker/polygon
- [ ] Verify styling matches app theme

### 4.4 Write Tests for Bottom Sheet Components
- [ ] Widget tests for `HotspotDetailsBottomSheet`
- [ ] Widget tests for `BurntAreaDetailsBottomSheet`
- [ ] Integration tests for tap → details flow

---

## Phase 5: Cleanup Legacy Code (LAST)

### 5.1 Move Legacy Files to `lib/legacy/` folder
- [ ] Move `lib/models/fire_incident.dart` → `lib/legacy/models/`
- [ ] Move `lib/services/fire_location_service.dart` → `lib/legacy/services/`
- [ ] Move `lib/services/fire_location_service_impl.dart` → `lib/legacy/services/`
- [ ] Move `lib/services/mock_fire_service.dart` → `lib/legacy/services/`
- [ ] Move `lib/services/fire_incident_cache.dart` → `lib/legacy/services/`
- [ ] Move `lib/services/active_fires_service.dart` → `lib/legacy/services/`
- [ ] Move `assets/mock/active_fires.json` → `assets/mock/legacy/`
- [ ] Update all import paths in files that still need legacy code
- [ ] Add deprecation notices to legacy files

---

## Progress Tracking

| Phase | Status | Notes |
|-------|--------|-------|
| 1.1 Mock Services | ✅ Complete | Created mock services + JSON files |
| 1.2 MapScreen Update | ✅ Complete | Renders from controller.hotspots/burntAreas |
| 1.3 Burnt Area Styling | ✅ Complete | Single red color for all |
| 2.1 Controller Fallback | ✅ Complete | Fallback to mock when live fails |
| 2.2 App.dart DI | ✅ Complete | Mock services internal to MapController |
| 3 Testing (Phase 1+2) | ✅ Complete | 66 tests (mock services, models, fallback) |
| 4 Bottom Sheet Refactor | ⬜ Not Started | After Phase 3 tests pass |
| 5 Legacy Cleanup | ⬜ Not Started | LAST - after everything working |

---

## Key Decisions

1. **Burnt areas = single red color** (no intensity grading by size)
2. **Home screen is unaffected** (uses separate `FireRiskService` for FWI)
3. **Legacy files moved last** (after refactor is working)
4. **Mock data mirrors real API responses** (same JSON structure)
