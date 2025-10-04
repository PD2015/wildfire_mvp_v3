
# Implementation Plan: A6 — Home (Risk Feed Container & Screen)

**Branch**: `006-a6-home-risk` | **Date**: 2025-10-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-a6-home-risk/spec.md`

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
Create the main home screen that displays fire risk information prominently to users. The screen integrates with LocationResolver and FireRiskService to show live, cached, or mock risk data with timestamp and source transparency. Features loading states, retry functionality, manual location entry, and graceful fallback handling. Must comply with accessibility guidelines and constitutional requirements (C1/C3/C4/C5).

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK  
**Primary Dependencies**: ChangeNotifier (preferred for HomeController), existing LocationResolver (A4), FireRiskService (A2), CacheService (A5)  
**Storage**: SharedPreferences for manual location persistence, existing cache system  
**Testing**: Flutter test framework, widget tests, integration tests with mocks  
**Target Platform**: iOS/Android mobile applications  
**Project Type**: Mobile - Flutter app with existing service layer  
**Performance Goals**: <200ms home screen load, smooth 60fps animations, immediate UI feedback  
**Constraints**: Must integrate with existing A1-A5 services, no new third-party state management libraries  
**Scale/Scope**: Single home screen with 6 test scenarios (EFFIS, SEPA, cache, mock, location denied→manual, retry)

**User Implementation Details**: 
- Exact APIs: HomeState, HomeController (ChangeNotifier preferred), HomeScreen props
- Lifecycle: load() runs on init, retry flow for failures, manual location flow with coordinate entry
- Test matrix: 6 scenarios covering all data sources and error states
- A11y + UI rules: source chip visible, "Updated {relative}" timestamp, Cached badge rule for stale data

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit/widget tests for HomeController and HomeScreen
- [x] CI enforcement approach specified - existing CI pipeline

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (uses existing service configurations)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision via existing GeographicUtils
- [x] Secret scanning integrated into existing CI pipeline

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (retry button, manual location button)
- [x] Semantic labels planned for screen readers (risk display, buttons, status indicators)
- [x] A11y verification included in widget testing approach

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (using existing color constants)
- [x] "Last Updated" timestamp visible in all data displays with relative time formatting
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design as chips/badges
- [x] Color validation approach planned - unit tests for color constants

### C5. Resilience & Test Coverage
- [x] Network calls handled by existing services with timeout and error handling
- [x] Services expose clear error states via HomeState enum (loading/success/error)
- [x] Retry/backoff strategies implemented in retry button functionality
- [x] Integration tests planned for error/fallback flows (6 test scenarios)

### Development Principles Alignment
- [x] "Fail visible, not silent" - HomeState exposes loading/error/cached states clearly
- [x] "Fallbacks, not blanks" - cached/mock fallbacks with clear source labels and badges
- [x] "Keep logs clean" - structured logging via existing patterns, no PII
- [x] "Single source of truth" - risk colors and display logic in constants with unit tests
- [x] "Mock-first dev" - HomeController accepts injectable services for testing

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
│   └── home_state.dart          # New: HomeState enum with loading/success/error states
├── controllers/
│   └── home_controller.dart     # New: ChangeNotifier-based HomeController
├── screens/
│   └── home_screen.dart         # New: Main home screen UI
├── widgets/
│   ├── risk_banner.dart         # Existing: A3 RiskBanner widget
│   ├── manual_location_dialog.dart  # New: Manual coordinate entry dialog
│   └── retry_button.dart        # New: Retry button with loading state
└── services/
    ├── fire_risk_service.dart   # Existing: A2 FireRiskService
    ├── location_resolver.dart   # Existing: A4 LocationResolver
    └── cache/                   # Existing: A5 CacheService
        └── fire_risk_cache_impl.dart

test/
├── unit/
│   ├── models/
│   │   └── home_state_test.dart
│   └── controllers/
│       └── home_controller_test.dart
├── widget/
│   ├── screens/
│   │   └── home_screen_test.dart
│   └── widgets/
│       ├── manual_location_dialog_test.dart
│       └── retry_button_test.dart
└── integration/
    └── home_flow_test.dart      # 6 test scenarios for data sources and error flows
```

**Structure Decision**: Flutter mobile app structure with existing services (A1-A5) integrated into new home screen. Uses standard Flutter patterns with lib/ for source code and test/ for all test types. New components follow existing naming conventions and integrate with established service layer.

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
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

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
