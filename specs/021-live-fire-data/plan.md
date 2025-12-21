# Implementation Plan: Live Fire Data Display

**Branch**: `021-live-fire-data` | **Date**: 2025-12-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/021-live-fire-data/spec.md`

## Execution Flow (/plan command scope)
```
1. ✅ Load feature spec from Input path
2. ✅ Fill Technical Context (no NEEDS CLARIFICATION)
3. ✅ Fill Constitution Check section
4. ✅ Evaluate Constitution Check - PASS
5. ✅ Execute Phase 0 → research.md
6. ✅ Execute Phase 1 → contracts, data-model.md, quickstart.md
7. ✅ Re-evaluate Constitution Check - PASS
8. ✅ Plan Phase 2 → Task generation approach described
9. ✅ STOP - Ready for /tasks command
```

## Summary

Enable users to view real-time and historical fire activity on the map through two distinct data layers:
- **Active Hotspots**: GWIS WMS `viirs.hs.today`/`viirs.hs.week` - 375m squares representing satellite thermal detections
- **Verified Burnt Areas**: EFFIS WFS `modis.ba.poly.season` - simplified polygons with official AREA_HA data

Technical approach: Create two new services (`GwisHotspotService`, `EffisBurntAreaService`), extend `FireIncident` model with `FireDataType` enum and `isSimplified` flag, implement mode toggle and time filters, add clustering for hotspots at low zoom.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable  
**Primary Dependencies**: google_maps_flutter ^2.5.0, http, dartz (Either type), equatable, xml (GML parsing)  
**Storage**: N/A (API-based, optional caching via existing CacheService)  
**Testing**: flutter test (unit, widget, contract, integration)  
**Target Platform**: Web, iOS, Android  
**Project Type**: Mobile/Web (Flutter multi-platform)  
**Performance Goals**: 50 polygons render < 100ms, clustering 100 hotspots < 50ms  
**Constraints**: Polygon max 500 points, coordinates logged at 2dp, 44dp touch targets  
**Scale/Scope**: Scotland regional viewport, ~100 hotspots, ~50 burnt areas typical

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit/widget tests for applicable components
- [x] CI enforcement approach specified

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (use .env/runtime config)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision
- [x] Secret scanning integrated into CI plan

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets
- [x] Semantic labels planned for screen readers
- [x] A11y verification included in testing approach

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (RiskPalette)
- [x] "Last Updated" timestamp visible in all data displays
- [x] Source labeling (EFFIS/GWIS/Cache/Mock) included in UI design
- [x] Color validation approach planned

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling
- [x] Services expose clear error states (no silent failures)
- [x] Retry/backoff strategies specified where needed
- [x] Integration tests planned for error/fallback flows

### Development Principles Alignment
- [x] "Fail visible, not silent" - loading/error/cached states planned
- [x] "Fallbacks, not blanks" - mock data fallbacks with clear labels
- [x] "Keep logs clean" - structured logging, no PII
- [x] "Single source of truth" - colors/thresholds in constants with tests
- [x] "Mock-first dev" - UI components support mock data injection

## Project Structure

### Documentation (this feature)
```
specs/021-live-fire-data/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command) ✓
├── data-model.md        # Phase 1 output (/plan command) ✓
├── quickstart.md        # Phase 1 output (/plan command) ✓
├── contracts/           # Phase 1 output (/plan command) ✓
│   ├── gwis_hotspot_service.md
│   └── effis_burnt_area_service.md
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/
├── models/
│   ├── fire_incident.dart           # EXTEND: Add FireDataType, isSimplified, landCoverBreakdown
│   ├── hotspot.dart                 # NEW: Hotspot value object
│   ├── burnt_area.dart              # NEW: BurntArea value object  
│   ├── hotspot_cluster.dart         # NEW: HotspotCluster view model
│   └── fire_data_mode.dart          # NEW: FireDataMode, HotspotTimeFilter enums
├── services/
│   ├── gwis_hotspot_service.dart    # NEW: Interface
│   ├── gwis_hotspot_service_impl.dart # NEW: Implementation
│   ├── effis_burnt_area_service.dart  # NEW: Interface
│   ├── effis_burnt_area_service_impl.dart # NEW: Implementation
│   └── utils/
│       └── polygon_simplifier.dart  # NEW: Douglas-Peucker algorithm
├── features/map/
│   ├── controllers/
│   │   └── map_controller.dart      # EXTEND: Add mode/filter state
│   ├── screens/
│   │   └── map_screen.dart          # EXTEND: Mode toggle, time filters, clustering
│   ├── widgets/
│   │   ├── fire_mode_toggle.dart    # NEW: SegmentedButton for mode
│   │   ├── hotspot_time_filter.dart # NEW: FilterChips for Today/ThisWeek
│   │   ├── hotspot_square_builder.dart # NEW: Build 375m squares
│   │   └── hotspot_cluster_marker.dart # NEW: Cluster badge marker
│   └── utils/
│       ├── polygon_style_helper.dart # EXISTING: Already implemented
│       └── hotspot_style_helper.dart # NEW: Hotspot square styling

test/
├── unit/
│   ├── models/
│   │   ├── hotspot_test.dart
│   │   ├── burnt_area_test.dart
│   │   └── fire_incident_extended_test.dart
│   └── services/
│       ├── gwis_hotspot_service_test.dart
│       ├── effis_burnt_area_service_test.dart
│       └── polygon_simplifier_test.dart
├── widget/
│   ├── fire_mode_toggle_test.dart
│   ├── hotspot_time_filter_test.dart
│   └── hotspot_cluster_marker_test.dart
├── contract/
│   ├── gwis_hotspot_service_contract_test.dart
│   └── effis_burnt_area_service_contract_test.dart
└── integration/
    └── live_fire_data_integration_test.dart
```

**Structure Decision**: Flutter mobile/web project using existing feature-based architecture. New services follow existing patterns from `effis_service_impl.dart`. New widgets integrate with existing map screen infrastructure.

## Phase 0: Outline & Research
✅ **COMPLETE** - See [research.md](./research.md)

Key decisions:
1. GWIS WMS for real-time hotspots (EFFIS WFS hotspots are stale)
2. Douglas-Peucker simplification at 100m tolerance, 500 max points
3. 375m squares for hotspots using Polygon with 4 vertices
4. Cluster hotspots within 750m at zoom < 10
5. SegmentedButton for mutually exclusive mode toggle
6. FilterChip for time filters

## Phase 1: Design & Contracts
✅ **COMPLETE** - See artifacts:
- [data-model.md](./data-model.md) - Entity definitions with validation rules
- [contracts/gwis_hotspot_service.md](./contracts/gwis_hotspot_service.md) - GWIS API contract
- [contracts/effis_burnt_area_service.md](./contracts/effis_burnt_area_service.md) - EFFIS WFS contract
- [quickstart.md](./quickstart.md) - Validation checklist

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models → Services → Controller → UI
- Mark [P] for parallel execution (independent files)

**Estimated Task Breakdown**:

| Phase | Tasks | Description |
|-------|-------|-------------|
| Models | 5 | FireDataType enum, Hotspot, BurntArea, HotspotCluster, FireIncident extension |
| Services | 4 | GwisHotspotService interface+impl, EffisBurntAreaService interface+impl |
| Utils | 2 | PolygonSimplifier, HotspotStyleHelper |
| Controller | 2 | MapController state extension, mode/filter logic |
| Widgets | 4 | FireModeToggle, HotspotTimeFilter, HotspotSquareBuilder, ClusterMarker |
| MapScreen | 3 | Mode toggle integration, clustering logic, rendering |
| Tests | 8 | Unit, widget, contract, integration tests |
| **Total** | **~28 tasks** | |

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*No Constitution Check violations requiring justification*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | - | - |

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none)

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
