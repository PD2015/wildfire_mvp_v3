
# Implementation Plan: A3 RiskBanner Home Widget

**Branch**: `003-a3-riskbanner-home` | **Date**: 2025-01-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-a3-riskbanner-home/spec.md`

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
Primary requirement: Create a RiskBanner widget for the home screen that displays current wildfire risk level using Scottish Government official colors (Very Low=Green, Low=Yellow, Moderate=Orange, High=Red, Very High=Purple). The widget must fetch data from A2 FireRiskService, handle loading/error/cached states, include accessibility features (semantic labels, 44dp+ touch targets), and display clear data provenance ("Last Updated", source labels). Technical approach: Stateful Flutter widget with BLoC pattern for state management, integrating with existing FireRiskService, using official color constants, and comprehensive testing coverage.

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK  
**Primary Dependencies**: flutter_bloc, equatable, http (inherited from A2), dartz (Either type from A2)  
**Storage**: N/A (widget consumes A2 FireRiskService data)  
**Testing**: flutter_test for widget tests, mockito for service mocking, bloc_test for BLoC testing  
**Target Platform**: iOS/Android multi-platform mobile  
**Project Type**: mobile - Flutter app with widget architecture  
**Performance Goals**: <500ms initial load, smooth 60fps animations for state transitions  
**Constraints**: Widget must work offline with cached data, accessibility compliant, official colors only  
**Scale/Scope**: Single reusable widget component, ~5-10 files (widget, BLoC, tests, constants)

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit/widget tests for applicable components (BLoC, widget, integration)
- [x] CI enforcement approach specified (existing GitHub Actions)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (widget consumes existing A2 service)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision (inherits A2 compliance)
- [x] Secret scanning integrated into CI plan (existing setup)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (F5 requirement)
- [x] Semantic labels planned for screen readers (F3 requirement)
- [x] A11y verification included in testing approach (widget testing with semantics)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (F1, F6 requirements)
- [x] "Last Updated" timestamp visible in all data displays (F7 requirement)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (F7 requirement)
- [x] Color validation approach planned (constants with tests)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (inherited from A2 FireRiskService)
- [x] Services expose clear error states (F8, F9 requirements for error/loading states)
- [x] Retry/backoff strategies specified where needed (A2 service handles this)
- [x] Integration tests planned for error/fallback flows (F10 cached data handling)

### Development Principles Alignment
- [x] "Fail visible, not silent" - loading/error/cached states planned (F8, F9, F10)
- [x] "Fallbacks, not blanks" - cached/mock fallbacks with clear labels (F10)
- [x] "Keep logs clean" - structured logging, no PII (widget-level logging minimal)
- [x] "Single source of truth" - colors/thresholds in constants with tests (F6)
- [x] "Mock-first dev" - UI components support mock data injection (testable design)

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
│   └── risk_banner/
│       ├── data/
│       │   └── models/
│       ├── domain/
│       │   ├── entities/
│       │   └── repositories/
│       └── presentation/
│           ├── bloc/
│           ├── widgets/
│           └── pages/
├── shared/
│   ├── constants/
│   │   └── wildfire_colors.dart
│   ├── utils/
│   └── widgets/
└── core/
    ├── error/
    └── usecases/

test/
├── features/
│   └── risk_banner/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
└── integration_test/
```

**Structure Decision**: Flutter clean architecture with feature-based organization. The RiskBanner is implemented as a feature module under `lib/features/risk_banner/` following the presentation-domain-data layer pattern. Shared constants (wildfire colors) are centralized in `lib/shared/constants/` for reuse across features. Tests mirror the source structure under `test/` with additional integration tests.

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
- Generate tasks from Phase 1 design docs (contracts, data-model.md, quickstart.md)
- Each contract test specification → failing test creation task [P]
- Each entity in data-model.md → model/state class creation task [P] 
- Each widget contract → widget implementation task
- Each BLoC contract → cubit implementation task
- Repository interface → repository implementation task
- Constants validation → color constants creation task [P]
- Integration tests from quickstart user stories

**Ordering Strategy**:
1. **Foundation [P]**: Constants, models, states (parallel - no dependencies)
2. **Interfaces**: Repository abstractions, failure classes  
3. **Tests First**: All contract tests must be created and failing
4. **Core Logic**: Repository implementation, BLoC/Cubit logic
5. **UI Layer**: Widget implementation, semantic integration
6. **Integration**: End-to-end tests, accessibility validation
7. **Documentation**: Code comments, README updates

**Parallel Execution Markers [P]**:
- WildfireColors constants creation
- State class implementations (RiskBannerState hierarchy)
- Contract test file creation (different test files)
- Data model entity definitions

**Dependency Chain**:
```
Constants → States → Repository Interface → BLoC Logic → Widget → Integration Tests
     ↓         ↓              ↓                ↓           ↓
 Color Tests → State Tests → Repo Tests → BLoC Tests → Widget Tests
```

**Estimated Output**: 20-25 numbered, ordered tasks in tasks.md
- 5 Foundation tasks (constants, models, states)
- 6 Test creation tasks (contract tests must fail initially)
- 4 Core implementation tasks (repository, BLoC logic)
- 3 UI implementation tasks (widget, accessibility, styling)
- 3 Integration tasks (end-to-end tests, quickstart validation)
- 2 Documentation tasks (comments, context updates)

**Quality Gates**:
- All contract tests created and failing before implementation starts
- Each implementation task includes making specific tests pass
- Accessibility requirements validated at widget level
- Official color compliance verified through constants tests

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
- [x] Complexity deviations documented: None required

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
