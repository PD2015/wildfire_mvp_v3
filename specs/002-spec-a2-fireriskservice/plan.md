
# Implementation Plan: FireRiskService (Fallback Orchestrator)

**Branch**: `002-spec-a2-fireriskservice` | **Date**: 2 October 2025 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-spec-a2-fireriskservice/spec.md`

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
FireRiskService implements a fallback orchestration system that ensures users always receive fire risk data through a sequential fallback chain: EFFIS → SEPA (Scotland only) → Cache (≤6h) → Mock. The service returns normalized FireRisk objects with source attribution and freshness indicators, maintaining 99.9% availability while respecting privacy constraints through coordinate anonymization and secure logging practices.

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK  
**Primary Dependencies**: dartz (Either type), http (network), equatable (value objects), mockito (testing)  
**Storage**: Cache service abstraction (implementation in A5), no direct database access  
**Testing**: flutter test with mockito for unit tests, integration tests for fallback scenarios  
**Target Platform**: Multi-platform Flutter (iOS 15+, Android API 21+, Web, Desktop)
**Project Type**: Mobile - single Flutter project with service layer architecture  
**Performance Goals**: <10s total response time including all fallbacks, <1s cache lookup  
**Constraints**: No PII persistence, coordinate rounding to 2-3dp, 6h cache TTL, sequential fallback only  
**Scale/Scope**: Service layer component, ~5 classes, extensive fallback testing, geographic boundary utilities

**User-Provided Context**: Implementation focuses on getCurrent({lat, lon}) with strict EFFIS → SEPA → Cache → Mock fallback chain, normalized FireRisk responses with source attribution, Scotland boundary detection utility (isInScotland), structured telemetry interface, privacy-compliant logging, and comprehensive integration testing scenarios.

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit/widget tests for applicable components
- [x] CI enforcement approach specified

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (use .env/runtime config) - N/A, no secrets required
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision
- [x] Secret scanning integrated into CI plan

### C3. Accessibility (UI features only)
- [x] N/A - This is a service layer component with no UI elements

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified - N/A, no UI colors in service layer
- [x] "Last Updated" timestamp included in FireRisk data model (updatedAt field)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in FireRisk response (source field)
- [x] N/A - No color validation needed in service layer

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (delegated to underlying services)
- [x] Services expose clear error states via Either<ApiError, FireRisk> pattern
- [x] Retry/backoff strategies delegated to underlying services as specified
- [x] Integration tests planned for all fallback scenarios and error flows

### Development Principles Alignment
- [x] "Fail visible, not silent" - Either pattern exposes all errors, no silent failures
- [x] "Fallbacks, not blanks" - Guaranteed mock fallback ensures data always available
- [x] "Keep logs clean" - Coordinate rounding to 2-3dp, structured telemetry interface
- [x] "Single source of truth" - Risk level mappings centralized, geographic boundaries tested
- [x] "Mock-first dev" - Service designed with mock fallback as guaranteed final option

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
│   ├── fire_risk.dart                    # FireRisk data model
│   ├── geographic_context.dart           # Location context for routing
│   └── service_attempt.dart              # Telemetry tracking model
├── services/
│   ├── fire_risk_service.dart            # Abstract interface
│   ├── fire_risk_service_impl.dart       # Orchestration implementation
│   └── cache_service.dart                # Cache abstraction (interface only)
├── utils/
│   ├── geographic_utils.dart             # Scotland boundary detection
│   └── telemetry_service.dart            # Telemetry interface
└── main.dart

test/
├── contract/
│   └── fire_risk_service_contract_test.dart    # API contract validation
├── integration/
│   ├── fallback_chain_test.dart               # End-to-end fallback scenarios  
│   └── geographic_boundary_test.dart          # Scotland edge cases
└── unit/
    ├── models/
    │   ├── fire_risk_test.dart
    │   ├── geographic_context_test.dart
    │   └── service_attempt_test.dart
    ├── services/
    │   └── fire_risk_service_impl_test.dart
    └── utils/
        ├── geographic_utils_test.dart
        └── telemetry_service_test.dart
```

**Structure Decision**: Flutter mobile project structure with service layer architecture. All FireRiskService components in lib/services/ with supporting utilities in lib/utils/ and models in lib/models/. Comprehensive test coverage across contract, integration, and unit test levels to validate fallback behavior and geographic edge cases.

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
- [ ] Phase 0: Research complete (/plan command)
- [ ] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
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
