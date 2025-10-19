
# Implementation Plan: A10 – Google Maps MVP Map

**Branch**: `011-a10-google-maps` | **Date**: October 19, 2025 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-a10-google-maps/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Replace the A9 placeholder MapScreen with a production-ready Google Maps implementation that displays user location, active fire markers from EFFIS WFS, and provides point-based fire risk assessment via "Check risk here" action. Implements 4-tier service fallback (EFFIS → SEPA → Cache → Mock) with MapController state management mirroring HomeController pattern. Delivers core MVP value: "Open app → see fire locations and risk near me."

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK 3.35.5  
**Primary Dependencies**: google_maps_flutter ^2.5.0, go_router 14.8.1, http, dartz (Either), equatable, flutter_bloc (inherited from A2/A6)  
**Storage**: SharedPreferences for cache (inherited from A5 CacheService), no new storage requirements  
**Testing**: flutter_test, mockito for service mocks, widget tests for MapScreen UI, integration tests for fallback chains  
**Target Platform**: iOS 15+, Android 21+, macOS (development), web (deferred)  
**Project Type**: Single mobile application (Flutter)  
**Performance Goals**: ≤3s map interactive, ≤50 markers without jank, ≤8s service timeout per tier, memory ≤75MB on map screen  
**Constraints**: EFFIS WFS bbox queries only, no polygon risk overlays in A10, offline tiles deferred, GPS fallback via A4 LocationResolver  
**Scale/Scope**: Single MapScreen with MapController, 2 new services (FireLocationService for markers, risk assessment via existing FireRiskService), ~15-20 implementation tasks

**User-Provided Technical Details**:
- **UI Architecture**: MapScreen uses MapController (mirrors HomeController lifecycle) with MapState sealed classes
- **Service Orchestration**: EffisService (WMS/WFS) → FireLocationService (markers) + FireRiskService (point risk) with fallback to SEPA → Cache → Mock
- **Caching**: ≤6h TTL via existing CacheService (A5); surface "Cached" chip w/ timestamp
- **Logging**: ConstitutionLogger pattern; no raw coordinates in logs (use LocationUtils.logRedact())
- **API Keys**: Google Maps keys env-injected per platform; no secrets in repo; restrict by SHA-1 (Android)/bundle ID (iOS); cost alarms at 50% & 80% of free tier
- **Data Sources**: EFFIS WFS burnt areas (bbox → features) for markers; EFFIS WMS GetFeatureInfo for on-tap risk at point (chip only in A10, no overlay)
- **Roll-out**: Feature flag MAP_LIVE_DATA (default: off for tests); staged enablement; add runbook for EFFIS endpoint shifts

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements (CI enforcement specified in roll-out)
- [x] Testing strategy covers unit tests (services), widget tests (MapScreen UI), integration tests (fallback paths)
- [x] CI enforcement approach specified (gates C1-C5 enforced per constitution)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (Google Maps keys env-injected per platform)
- [x] Logging design excludes PII, coordinates use LocationUtils.logRedact() (2dp precision)
- [x] Secret scanning integrated into CI plan (keys restricted by SHA-1/bundle ID, no repo commits)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (marker info windows, zoom controls, "Check risk here" button)
- [x] Semantic labels planned for screen readers (map controls, markers, chips)
- [x] A11y verification included in testing approach (widget tests for semantics)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (inherited from existing theme, no new colors in A10)
- [x] "Last Updated" timestamp visible in all data displays (fire marker details, risk assessment chip)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (source chips on markers and risk chip)
- [x] Color validation approach planned (CI color_guard.sh script enforced)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (8s service timeout per tier, inherited from A2 pattern)
- [x] Services expose clear error states (MapError state with cached fallback display)
- [x] Retry/backoff strategies specified where needed (4-tier fallback: EFFIS → SEPA → Cache → Mock)
- [x] Integration tests planned for error/fallback flows (mock EFFIS responses and fallback paths)

### Development Principles Alignment
- [x] "Fail visible, not silent" - MapLoading/MapError/MapSuccess states with clear UI indicators
- [x] "Fallbacks, not blanks" - cached/mock fallbacks with "Cached"/"Demo Data" labels
- [x] "Keep logs clean" - ConstitutionLogger, no PII, structured logging via LocationUtils.logRedact()
- [x] "Single source of truth" - risk colors in WildfireTheme constants (inherited), no new constants
- [x] "Mock-first dev" - Feature flag MAP_LIVE_DATA (default: off) enables mock-first testing

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/
├── features/
│   └── map/
│       ├── screens/
│       │   └── map_screen.dart          # Enhanced from A9 placeholder
│       ├── controllers/
│       │   └── map_controller.dart      # NEW: State management
│       ├── models/
│       │   ├── map_state.dart           # NEW: Sealed state classes
│       │   └── fire_incident.dart       # NEW: Fire location entity
│       └── widgets/
│           ├── fire_marker_info.dart    # NEW: Marker info window
│           ├── risk_assessment_chip.dart # NEW: Point risk display
│           └── source_attribution_chip.dart # NEW: Data source label
├── services/
│   ├── fire_location_service.dart       # NEW: EFFIS WFS for markers
│   ├── fire_risk_service_impl.dart      # EXISTING: Enhanced for point queries
│   ├── effis_service.dart               # EXISTING: Add WFS support
│   ├── cache_service.dart               # EXISTING: From A5
│   └── location_resolver.dart           # EXISTING: From A4
├── models/
│   ├── fire_risk.dart                   # EXISTING: From A2
│   └── lat_lng.dart                     # EXISTING: From A4
├── utils/
│   ├── location_utils.dart              # EXISTING: logRedact() from A2
│   └── constitution_logger.dart         # NEW: Structured logging wrapper
└── theme/
    └── wildfire_theme.dart              # EXISTING: Colors from constitution

test/
├── unit/
│   ├── services/
│   │   ├── fire_location_service_test.dart  # NEW: WFS tests
│   │   └── effis_service_wfs_test.dart      # NEW: WFS endpoint tests
│   └── controllers/
│       └── map_controller_test.dart         # NEW: State management tests
├── widget/
│   └── map/
│       ├── map_screen_test.dart             # NEW: UI semantics
│       ├── fire_marker_info_test.dart       # NEW: Info window tests
│       └── risk_assessment_chip_test.dart   # NEW: Chip accessibility
└── integration/
    └── map/
        └── map_fallback_flow_test.dart      # NEW: EFFIS → SEPA → Cache → Mock

android/
└── app/
    └── src/
        └── main/
            └── AndroidManifest.xml          # ADD: Google Maps API key

ios/
└── Runner/
    └── AppDelegate.swift                    # ADD: Google Maps API key
```

**Structure Decision**: Single Flutter mobile application following existing feature-based architecture. A10 adds new `features/map/` module with MapController, services extend existing EFFIS/Cache/LocationResolver infrastructure. No new top-level directories; builds on A2 (FireRiskService), A4 (LocationResolver), A5 (CacheService), A9 (MapScreen scaffold) foundations.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh copilot`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each entity in data-model.md → model creation task [P]
- Each contract → contract test task [P]
- FireLocationService contract → service implementation task
- MapController contract → controller implementation task
- MapScreen enhancements → UI widget tasks
- Each acceptance scenario in quickstart → integration test task

**Ordering Strategy**:
- **Foundation First**: Models (FireIncident, MapState, LatLngBounds) before services
- **TDD Order**: Tests before implementation
  1. Write failing contract tests (FireLocationService, MapController)
  2. Implement services to pass tests
  3. Write failing widget tests (MapScreen, marker info, risk chip)
  4. Implement UI to pass tests
- **Dependency Order**: 
  1. Data models (no dependencies)
  2. Service layer (depends on models)
  3. Controller layer (depends on services)
  4. UI layer (depends on controller)
- **Mark [P] for parallel execution**: Independent files can be implemented simultaneously
  - All model classes [P]
  - Service tests [P] (after models)
  - Widget tests [P] (after models)

**Task Categories**:
1. **Setup Tasks** (1-2 tasks): Google Maps SDK integration, API key configuration
2. **Data Model Tasks** (5-6 tasks): FireIncident, MapState sealed classes, LatLngBounds, query/response models
3. **Service Layer Tasks** (8-10 tasks): FireLocationService interface, EFFIS WFS integration, service tests, fallback chain
4. **Controller Layer Tasks** (6-8 tasks): MapController implementation, state management, lifecycle tests
5. **UI Layer Tasks** (10-12 tasks): MapScreen enhancements, fire markers, info windows, risk assessment chip, accessibility
6. **Integration Tasks** (4-5 tasks): Fallback chain integration tests, performance tests, quickstart validation
7. **Documentation Tasks** (2-3 tasks): API key setup guide, runbook for EFFIS endpoint changes

**Estimated Output**: 35-45 numbered, ordered tasks in tasks.md

**Constitutional Compliance per Task**:
- Each task must specify which gates it addresses (C1-C5)
- Service tasks include timeout/error handling (C5)
- UI tasks include accessibility requirements (C3)
- All tasks must include test coverage (C1)
- Logging tasks must use LocationUtils.logRedact() (C2)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No complexity violations. All constitutional gates (C1-C5) passed.

**Design Justifications**:
- **4-tier service fallback**: Required for C5 resilience, mirrors existing A2 pattern (no new complexity)
- **Google Maps SDK**: Selected by ADR for MVP speed/stability, deferred Mapbox/offline to A11+
- **ChangeNotifier pattern**: Consistent with A6 HomeController, no additional state management libraries
- **Geohash cache keys**: Inherited from A5 CacheService, spatial optimization for bbox queries


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - research.md created
- [x] Phase 1: Design complete (/plan command) - data-model.md, contracts/, quickstart.md, copilot-instructions.md updated
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command) - tasks.md pending
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS (all C1-C5 gates satisfied)
- [x] Post-Design Constitution Check: PASS (no new violations introduced)
- [x] All NEEDS CLARIFICATION resolved (Phase 0 research.md)
- [x] Complexity deviations documented (none - all patterns consistent with A2-A9)

**Artifacts Generated**:
- ✅ research.md (Phase 0) - 8 research decisions documented
- ✅ data-model.md (Phase 1) - 5 entities, 3 enums, validation rules
- ✅ contracts/fire_location_service.md (Phase 1) - Service contract with EFFIS/SEPA/Cache/Mock tiers
- ✅ contracts/map_controller.md (Phase 1) - Controller contract with state management
- ✅ quickstart.md (Phase 1) - Setup guide with 7 acceptance scenarios
- ✅ .github/copilot-instructions.md (Phase 1) - Agent context updated with A10 technologies
- ⏳ tasks.md (Phase 2) - Awaiting /tasks command

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
