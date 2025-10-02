
# Implementation Plan: EffisService (FWI Point Query)

**Branch**: `001-spec-a1-effisservice` | **Date**: 2025-10-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-spec-a1-effisservice/spec.md`**Gate Status**:
- [x] Initial Constitution Check: PASS - All gates C1, C2, C5 addressed
- [x] Post-Design Constitution Check: PASS - Design maintains constitutional compliance  
- [x] All NEEDS CLARIFICATION resolved - Technical context complete
- [x] Complexity deviations documented - No violations identified

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*cution Flow (/plan command scope)
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
EffisService provides a minimal HTTP client for retrieving Fire Weather Index (FWI) data from EFFIS via WMS GetFeatureInfo for given coordinates. The service maps raw FWI values to standardized risk levels and handles network failures gracefully with timeouts and retries. This is the primary data source for the home screen risk indicator, with scope limited to point queries only (no caching, UI, or polygon processing).

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK  
**Primary Dependencies**: http package, dartz (Either type), equatable (value objects)  
**Storage**: N/A (no caching or persistence at service level)  
**Testing**: flutter test, mockito for HTTP mocking, golden test files for fixtures  
**Target Platform**: Flutter mobile (iOS 12+, Android API 21+)
**Project Type**: single Flutter project - mobile app structure  
**Performance Goals**: <3 seconds per successful request, <30 seconds timeout  
**Constraints**: Network-dependent, no offline capability, coordinate precision limited to 3dp for logging  
**Scale/Scope**: Single service class, ~5 methods, 4 UK test coordinates, EFFIS-only (no multi-provider)

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit tests for HTTP service, no widget tests needed (service-only)
- [x] CI enforcement approach specified

### C2. Secrets & Logging
- [x] No hardcoded secrets in design - EFFIS requires no API keys
- [x] Logging design excludes PII, coordinates limited to 3 dp precision in logs
- [x] Secret scanning integrated into CI plan (no secrets expected)

### C3. Accessibility (UI features only)
- [x] N/A - Service layer only, no UI components

### C4. Trust & Transparency
- [x] N/A for service layer - timestamp and source URI included in result model for upstream use
- [x] Risk level mapping uses official thresholds (constants will be validated by tests)

### C5. Resilience & Test Coverage
- [x] Network calls include 30s timeout and exponential backoff retry
- [x] Services expose structured ApiError for all failure modes (no silent failures)
- [x] Retry/backoff strategies specified with exponential backoff
- [x] Unit tests planned for timeout, 4xx/5xx, malformed JSON, network errors

### Development Principles Alignment
- [x] "Fail visible, not silent" - All errors returned as Either<ApiError, Result>
- [x] "Fallbacks, not blanks" - N/A at service layer (handled by caller A2)
- [x] "Keep logs clean" - Structured logging, coordinates rounded to 3dp
- [x] "Single source of truth" - FWI thresholds in constants with unit tests
- [x] "Mock-first dev" - HTTP responses will be mockable via dependency injection

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
│   ├── effis_fwi_result.dart
│   ├── api_error.dart
│   ├── risk_level.dart
│   └── coordinate.dart
├── services/
│   ├── effis_service.dart
│   └── effis_service_impl.dart
└── utils/
    └── fwi_mapper.dart

test/
├── fixtures/
│   └── effis/
│       ├── edinburgh_success.json
│       ├── cairngorms_success.json
│       ├── error_404.json
│       └── malformed_response.json
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── integration/
│   └── effis_service_test.dart
└── golden/
    └── effis_responses_test.dart
```

**Structure Decision**: Single Flutter project structure selected. Service-only feature with models, services, and utilities in lib/. Comprehensive test coverage with fixtures, unit tests, integration tests, and golden tests. No UI components needed for this service layer.

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
- Each entity in data-model.md → model creation task [P] (4 models: EffisFwiResult, ApiError, RiskLevel, Coordinate)
- Service contract → interface + implementation tasks
- HTTP client setup → network layer task
- FWI mapping logic → utility function task [P]
- Fixture creation → golden test setup tasks [P]
- Unit tests → one task per model/service [P]
- Integration tests → EFFIS API integration task
- Error handling → timeout, retry, parsing tests [P]

**Ordering Strategy**:
- Setup: Dependencies, project structure, fixtures
- TDD: All test files before implementation 
- Models first: Value objects with no dependencies [P]
- Utils: FWI mapping helper [P]
- Service: Interface then implementation
- Integration: HTTP client + EFFIS integration
- Validation: Error handling, performance, golden tests

**Estimated Output**: 18-22 numbered, ordered tasks focusing on service layer only

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*No constitutional violations identified - all gates pass.*

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - research.md created
- [x] Phase 1: Design complete (/plan command) - data-model.md, contracts/, quickstart.md created
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
