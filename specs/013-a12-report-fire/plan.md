
# Implementation Plan: A12 – Report Fire Screen (MVP)

**Branch**: `013-a12-report-fire` | **Date**: 28 October 2025 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-a12-report-fire/spec.md`

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
Create a minimal, accessible "Report a Fire" screen for Scotland with three emergency contact buttons (999 Fire Service, 101 Police Scotland, 0800 555 111 Crimestoppers). The screen must work offline, provide dialer fallback notifications for unsupported devices, and meet WCAG AA accessibility standards. No data collection or network dependencies required - purely static UI with native dialer integration via url_launcher.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable  
**Primary Dependencies**: url_launcher (native dialer integration), go_router (navigation), flutter_test (testing)  
**Storage**: N/A (no data persistence required)  
**Testing**: flutter_test (widget tests), integration_test (accessibility testing)  
**Target Platform**: iOS 15+, Android API 21+, Web (Chrome/Safari), macOS (web mode only)
**Project Type**: mobile - Flutter cross-platform application  
**Performance Goals**: Instant screen load (<100ms), immediate button response, zero network latency  
**Constraints**: Offline-capable, no network dependencies, WCAG AA contrast ratios, 44dp touch targets  
**Scale/Scope**: Single screen with 3 CTAs, minimal UI component, part of existing WildFire MVP app

**User-Provided Implementation Details**:
- P1: Setup & dependencies (url_launcher integration)
- P2: UI screen implementation (3 emergency contact buttons)  
- P3: Routing & navigation (go_router integration)
- P4: Tests (widget + accessibility validation)
- P5: QA checklist (contrast verification, emulator fallback testing)
- P6: Documentation & changelog
- Risk: tel: scheme failing on emulators → SnackBar fallback notification
- Risk: Theme token mismatch → use Material 3 ColorScheme with minimal overrides
- Mitigation: url_launcher stable API with device-only manual QA
- Mitigation: Reuse existing Material 3 colorScheme patterns

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements (P5 QA checklist phase)
- [x] Testing strategy covers unit/widget tests for applicable components (P4 phase)
- [x] CI enforcement approach specified (existing CI will validate)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (no secrets needed for static emergency contacts)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision (no location data collected)
- [x] Secret scanning integrated into CI plan (existing CI configuration applies)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (FR-006 requirement, verified in P4 tests)
- [x] Semantic labels planned for screen readers (FR-007 requirement, widget test validation)
- [x] A11y verification included in testing approach (P4 accessibility testing phase)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (emergency red styling for 999, standard for others)
- [x] "Last Updated" timestamp visible in all data displays (N/A - no dynamic data, static contacts only)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (N/A - official emergency contacts, not risk data)
- [x] Color validation approach planned (P5 QA checklist includes contrast verification)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (N/A - no network calls, offline-capable design)
- [x] Services expose clear error states (url_launcher failure handled with SnackBar notification)
- [x] Retry/backoff strategies specified where needed (N/A - no network operations)
- [x] Integration tests planned for error/fallback flows (P4 emulator fallback testing)

### Development Principles Alignment
- [x] "Fail visible, not silent" - SnackBar notification for dialer failures planned
- [x] "Fallbacks, not blanks" - manual dialing instructions provided when tel: scheme fails
- [x] "Keep logs clean" - no PII logging (no user data collected)
- [x] "Single source of truth" - emergency contact constants will be defined and tested
- [x] "Mock-first dev" - static UI requires no mock injection (emergency contacts are constants)

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
│   └── report/
│       ├── screens/
│       │   └── report_fire_screen.dart    # Main UI screen
│       ├── models/
│       │   └── emergency_contact.dart     # Emergency contact data model
│       └── widgets/
│           └── emergency_button.dart      # Reusable CTA button component
├── utils/
│   └── url_launcher_utils.dart           # Dialer integration utilities
└── theme/
    └── emergency_colors.dart             # Emergency styling constants

test/
├── features/
│   └── report/
│       ├── screens/
│       │   └── report_fire_screen_test.dart    # Widget tests
│       ├── models/
│       │   └── emergency_contact_test.dart     # Model tests
│       └── widgets/
│           └── emergency_button_test.dart      # Button component tests
├── utils/
│   └── url_launcher_utils_test.dart            # Utility function tests
└── integration/
    └── report/
        └── report_fire_integration_test.dart   # Full screen integration tests
```

**Structure Decision**: Flutter mobile application following existing feature-based organization. The report feature is self-contained within `lib/features/report/` following the established pattern in the codebase. Emergency contact models and reusable button widgets are separated for maintainability. Utility functions for url_launcher integration are placed in the global utils directory for potential reuse by other features.

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
- Generate tasks from Phase 1 design docs (data-model.md, contracts/, quickstart.md)
- EmergencyContact model → model creation + unit test tasks [P]
- EmergencyButton widget → widget creation + widget test tasks [P]
- ReportFireScreen → screen creation + widget test tasks
- url_launcher integration → utility function + unit test tasks [P]
- Route registration → navigation configuration task
- Integration tests → full user flow validation tasks
- Accessibility tests → semantic validation tasks
- Platform-specific tests → iOS/Android/Web behavior validation

**Ordering Strategy**:
- TDD order: Tests before implementation (create failing tests first)
- Dependency order: Models → Widgets → Screen → Integration → Navigation
- Mark [P] for parallel execution (models and utilities can be developed simultaneously)
- Critical path: Models → Widgets → Screen (required for functional testing)

**User-Provided Phase Breakdown Integration**:
- P1: Setup & dependencies → Add url_launcher dependency task
- P2: UI screen implementation → Screen and widget creation tasks  
- P3: Routing & navigation → go_router configuration tasks
- P4: Tests (widget + accessibility) → Comprehensive test suite tasks
- P5: QA checklist → Manual validation and contrast verification tasks
- P6: Documentation & changelog → Documentation update tasks

**Estimated Output**: 18-22 numbered, ordered tasks in tasks.md (smaller scope due to static UI nature)

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
- [x] Phase 0: Research complete (/plan command) - research.md generated
- [x] Phase 1: Design complete (/plan command) - data-model.md, contracts/, quickstart.md generated
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
