
# Implementation Plan: Map Fire Information Sheet

**Branch**: `018-map-fire-information` | **Date**: 2025-11-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/018-map-fire-information/spec.md`

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
Primary requirement: Implement a tap-for-details bottom sheet that displays comprehensive fire incident information (detection time, data source, confidence, FRP, distance/bearing, risk level) when users tap map markers. Must integrate with existing EFFIS risk service, support MAP_LIVE_DATA feature flag for live vs demo data, and maintain accessibility standards with clear error handling and retry mechanisms.

Technical approach: Extend existing Flutter map infrastructure with new FireIncident model and ActiveFiresService, implement custom bottom sheet widget with EffisService integration for risk assessment, and add comprehensive test coverage for all interaction flows.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable  
**Primary Dependencies**: google_maps_flutter ^2.5.0, http (EFFIS API), dartz (error handling), equatable (models), geolocator (distance calculation)  
**Storage**: SharedPreferences for caching fire incidents, existing cache infrastructure  
**Testing**: flutter_test (unit/widget), integration_test (map interactions), mockito (service mocking)  
**Target Platform**: Android/iOS primary, Web secondary (Google Maps support via google_maps_flutter_web)  
**Project Type**: Mobile (Flutter application with map integration)  
**Performance Goals**: <200ms fire details sheet load, debounced viewport queries, cached repeat access  
**Constraints**: MAP_LIVE_DATA feature flag compliance, constitutional accessibility requirements, EFFIS API rate limits  
**Scale/Scope**: Support viewing details for hundreds of fire markers per viewport, 24-hour time window for active fires

**User-provided Implementation Details**: 
- Objective: Deliver bottom sheet with reliable fire incident details and risk level, integrated with MAP_LIVE_DATA, robust tests and accessibility
- Milestones: (1) Data layer - FireIncident model, ActiveFiresService with viewport query; (2) UI layer - markers, FireDetailsBottomSheet, chips; (3) Integration - EffisService risk fetch, error handling; (4) Testing and documentation
- Dependencies: EffisService (existing), geolocator for distance/bearing, MAP_LIVE_DATA flag
- Performance: Fetch on cameraIdle with debounce, responsive sheet, avoid main thread blocking
- Deliverables: New model/service files, bottom sheet widget, home_screen integration, tests, docs, screenshots

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements (CI enforcement specified)
- [x] Testing strategy covers unit tests (models/services), widget tests (bottom sheet), integration tests (map interactions)
- [x] CI enforcement approach specified (existing CI infrastructure)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (MAP_LIVE_DATA flag, existing env configuration)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision (existing GeographicUtils.logRedact)
- [x] Secret scanning integrated into CI plan (existing infrastructure)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (bottom sheet controls, markers)
- [x] Semantic labels planned for screen readers (fire details, risk levels)
- [x] A11y verification included in testing approach (widget tests with semantics)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (existing RiskPalette integration)
- [x] "Last Updated" timestamp visible in all data displays (fire detection time, risk assessment time)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (data source chips)
- [x] Color validation approach planned (existing risk level color constants)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (EFFIS service integration, ActiveFiresService)
- [x] Services expose clear error states (Either<ApiError, T> pattern, retry functionality)
- [x] Retry/backoff strategies specified where needed (bottom sheet retry button)
- [x] Integration tests planned for error/fallback flows (network failures, stale data)

### Development Principles Alignment
- [x] "Fail visible, not silent" - loading/error/cached states planned for bottom sheet
- [x] "Fallbacks, not blanks" - cached/mock fire data with clear DEMO DATA labels
- [x] "Keep logs clean" - structured logging via existing GeographicUtils, no PII
- [x] "Single source of truth" - risk colors via RiskPalette, fire thresholds in constants
- [x] "Mock-first dev" - ActiveFiresService supports mock data injection via MAP_LIVE_DATA

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
├── models/
│   ├── fire_incident.dart           # Enhanced with detectedAt, source, confidence, frp fields
│   └── active_fires_response.dart   # New - API response wrapper
├── services/
│   ├── active_fires_service.dart    # New - interface
│   ├── active_fires_service_impl.dart # New - implementation with live/mock support
│   └── cache/
│       └── fire_incident_cache_impl.dart # Enhanced for viewport-based caching
├── widgets/
│   ├── fire_details_bottom_sheet.dart # New - main bottom sheet widget
│   ├── fire_marker.dart             # New - custom marker widget
│   └── chips/
│       ├── data_source_chip.dart    # New - EFFIS/SEPA/Mock indicators
│       └── demo_data_chip.dart      # New - DEMO DATA warning
├── screens/
│   └── home_screen.dart             # Enhanced - marker tap handling, sheet integration
├── controllers/
│   └── map_controller.dart          # Enhanced - fire incident management
└── utils/
    ├── distance_calculator.dart     # New - bearing and distance calculations
    └── fire_incident_mapper.dart    # New - JSON to model mapping

test/
├── unit/
│   ├── models/fire_incident_test.dart
│   ├── services/active_fires_service_test.dart
│   └── utils/distance_calculator_test.dart
├── widget/
│   ├── fire_details_bottom_sheet_test.dart
│   └── chips/data_source_chip_test.dart
└── integration/
    └── map/
        └── fire_marker_interaction_test.dart
```

**Structure Decision**: Enhanced existing Flutter mobile structure with new fire incident management components. Integrates with existing map infrastructure (google_maps_flutter), service patterns (dartz Either, equatable models), and constitutional requirements (accessibility, caching, error handling).

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
- Each contract → contract test task [P] (parallel execution)
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Specific Task Categories**:

1. **Model Tasks** [P] (can run parallel):
   - Update FireIncident model with new fields (detectedAt, source, confidence, frp, lastUpdate)
   - Create ActiveFiresResponse model for API responses
   - Create DistanceCalculation model for bearing/distance
   - Create BottomSheetState for UI state management

2. **Service Contract Tests** [P]:
   - ActiveFiresService contract test (viewport queries, error handling)
   - FireIncidentCache contract test (enhanced for viewport caching)
   - Distance calculation utility contract test

3. **Service Implementation Tasks**:
   - Implement ActiveFiresServiceImpl with live/mock data support
   - Enhance FireIncidentCache with geohash-based viewport caching
   - Create DistanceCalculator utility for bearing/distance calculations
   - Integrate MAP_LIVE_DATA feature flag support

4. **UI Component Tasks**:
   - Create FireDetailsBottomSheet widget with accessibility support
   - Create DataSourceChip widget for EFFIS/SEPA/Mock indicators  
   - Create DemoDataChip widget for demo mode warnings
   - Enhance fire markers with custom styling

5. **Integration Tasks**:
   - Update HomeScreen/MapScreen with marker tap handling
   - Integrate EffisService risk lookup in bottom sheet
   - Add viewport-based fire incident loading with debounce
   - Wire up complete marker tap → sheet open → risk load flow

6. **Testing Tasks**:
   - Widget tests for FireDetailsBottomSheet accessibility
   - Integration test for marker tap → bottom sheet flow
   - Performance tests for viewport query debouncing
   - Error handling tests for network failures

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models → Services → UI → Integration
- Mark [P] for parallel execution (independent files)
- Critical path: Models → ActiveFiresService → BottomSheet → Integration

**Constitutional Compliance Tasks**:
- C1: Add flutter analyze/format checks to CI
- C2: Implement coordinate logging via GeographicUtils.logRedact  
- C3: Accessibility audit and fixes for ≥44dp targets + semantic labels
- C4: Risk color validation + timestamp display verification
- C5: Error state testing + retry mechanism validation

**Estimated Output**: 28-32 numbered, ordered tasks in tasks.md with clear dependencies and parallel execution markers

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


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
- [x] Complexity deviations documented (none required)

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
