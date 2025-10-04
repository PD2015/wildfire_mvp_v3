
# Implementation Plan: LocationResolver (Low-Friction Location)

**Branch**: `004-a4-locationresolver-low` | **Date**: 2025-10-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-a4-locationresolver-low/spec.md`

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
LocationResolver provides low-friction location access for wildfire risk assessment through a fallback strategy: GPS → cached → manual entry → Scotland centroid. Core API is `getLatLon()` with comprehensive permission handling, manual location persistence via SharedPreferences, and simple dialog-based entry with basic validation. No permission barriers block wildfire safety information access.

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK  
**Primary Dependencies**: geolocator (GPS/permissions), shared_preferences (persistence), geocoding (optional place search), permission_handler (runtime permissions)  
**Storage**: SharedPreferences for manual location persistence, no database required  
**Testing**: flutter_test for unit/widget tests, mockito for service mocking, golden tests for dialog UI  
**Target Platform**: iOS 15+, Android API 23+ (location permission models)
**Project Type**: Mobile (single Flutter project)  
**Performance Goals**: <500ms location resolution, <200ms SharedPreferences access, <2s GPS timeout  
**Constraints**: No background location, no complex geocoding UI, minimal permission friction, must work offline  
**Scale/Scope**: Single service class + dialog widget, ~5-7 methods, basic coordinate validation, Scotland centroid constant

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit/widget tests for applicable components (service mocking, dialog validation, permission flows)
- [x] CI enforcement approach specified (same as existing A1-A3 pattern)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (no API keys required for basic location services)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision for privacy
- [x] Secret scanning integrated into CI plan (inherited from existing setup)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (dialog buttons, text fields)
- [x] Semantic labels planned for screen readers (location input fields, action buttons)
- [x] A11y verification included in testing approach (widget tests verify target sizes and labels)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (N/A - location service doesn't display risk colors)
- [x] "Last Updated" timestamp visible in all data displays (N/A - coordinates don't have staleness)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (N/A - location source is GPS/manual/default)
- [x] Color validation approach planned (N/A - no risk colors in location resolution)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (GPS timeout 2s, optional geocoding timeout 5s)
- [x] Services expose clear error states (LocationError enum with specific failure modes)
- [x] Retry/backoff strategies specified where needed (GPS single attempt, no retry for location)
- [x] Integration tests planned for error/fallback flows (permission denied → manual → default)

### Development Principles Alignment
- [x] "Fail visible, not silent" - location errors exposed as Either<LocationError, LatLng>
- [x] "Fallbacks, not blanks" - Scotland centroid default ensures app never lacks coordinates
- [x] "Keep logs clean" - coordinate logging at 2dp precision only
- [x] "Single source of truth" - Scotland centroid constant, validation ranges in constants
- [x] "Mock-first dev" - LocationResolver interface enables easy mocking for dependent services

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
├── services/
│   ├── location_resolver.dart          # LocationResolver service interface
│   ├── location_resolver_impl.dart     # Concrete implementation with GPS→manual→default
│   └── contracts/
│       └── location_contracts.dart     # LatLng, LocationError, persistence contracts
├── models/
│   └── location_models.dart            # LatLng, LocationError, ManualLocation entities
├── widgets/
│   └── dialogs/
│       └── manual_location_dialog.dart # Simple coordinate entry dialog
├── utils/
│   └── location_constants.dart         # Scotland centroid, validation ranges
└── [existing A1-A3 structure continues...]

test/
├── unit/
│   ├── services/
│   │   └── location_resolver_test.dart # Unit tests for all fallback scenarios
│   └── models/
│       └── location_models_test.dart   # Validation and factory tests
├── widget/
│   └── dialogs/
│       └── manual_location_dialog_test.dart # Dialog UI and validation tests
└── integration/
    └── location_flow_test.dart         # End-to-end permission flows
```

**Structure Decision**: Single Flutter mobile project structure. A4 LocationResolver follows established lib/services pattern from A1-A3, with location-specific models, simple dialog widget, and comprehensive testing. No API backend required as location resolution is device-local with optional geocoding.

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

### Task Generation Strategy for A4 LocationResolver

**Core Service Architecture** (8-10 tasks):
- LocationResolver interface with Either<LocationError, LatLng> signature
- LocationResolverImpl with 4-tier fallback chain (GPS → cache → manual → default)
- LatLng, LocationError, ManualLocation value objects with validation
- Service registration and dependency injection setup

**GPS and Permission Layer** (6-8 tasks):
- GPS service wrapper with 2-second timeout enforcement
- Permission handler with graceful denial/revocation flows
- LocationServices availability checking and error handling
- Mid-session permission change resilience testing

**Manual Entry UI** (4-6 tasks):
- ManualLocationDialog widget with coordinate input validation
- Real-time latitude/longitude range validation (-90 to 90, -180 to 180)
- Accessibility compliance (≥44dp touch targets, semantic labels)
- Optional geocoding integration for place name search

**SharedPreferences Persistence** (3-4 tasks):
- Cache read/write operations with coordinate validation
- Corruption handling and graceful cache degradation
- Persistence performance testing (< 200ms operations)
- Cache key management and data migration strategies

**Testing and Integration** (6-8 tasks):
- Unit tests for all fallback scenarios and edge cases
- Widget tests for dialog validation and accessibility compliance
- Integration tests for permission flows and GPS timeout scenarios
- Performance validation for GPS operations and cache persistence

**Task Ordering Strategy**:
- **Foundation First**: Interfaces and data models before implementations
- **Layer by Layer**: GPS → Persistence → Manual Entry → Integration
- **TDD Approach**: Contract tests before implementation tasks
- **Risk Mitigation**: Complex GPS/permission logic validated early
- **Parallel Execution**: Independent components marked [P] for efficiency

**Constitutional Compliance Integration**:
- C1: Every implementation task paired with comprehensive test task
- C2: Coordinate logging redaction built into service foundation
- C3: UI accessibility requirements specified upfront in dialog tasks
- C5: Error handling verification integrated into each service layer task

**Expected Task Structure**:
1. **T001-T010**: Core interfaces, data models, and service contracts
2. **T011-T018**: GPS layer implementation and permission handling
3. **T019-T024**: Manual entry dialog and coordinate validation
4. **T025-T028**: SharedPreferences persistence and cache management
5. **T029-T034**: Integration testing and performance validation

**Estimated Output**: 28-34 numbered, ordered tasks with clear dependencies and parallel execution opportunities

**IMPORTANT**: This task generation will be executed by the /tasks command, NOT by /plan

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

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
- [ ] Phase 3: Tasks generated (/tasks command) - READY FOR EXECUTION
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none required)

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
