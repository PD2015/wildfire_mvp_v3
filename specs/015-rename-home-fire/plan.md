
# Implementation Plan: Rename Home → Fire Risk Screen and Update Navigation Icon

**Branch**: `015-rename-home-fire` | **Date**: 2025-11-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-rename-home-fire/spec.md`

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
Rename the "Home" screen to "Fire Risk" across UI, routes, and navigation to better communicate the app's primary purpose. Update bottom navigation to use warning icon (Icons.warning_amber), add route alias '/fire-risk', and maintain all existing functionality while ensuring constitutional compliance and accessibility standards.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable
**Primary Dependencies**: Flutter SDK, go_router (navigation/routing), Material Design Icons (Icons.warning_amber)
**Storage**: No new storage requirements - UI/routing changes only
**Testing**: flutter_test (widget tests), integration_test (route navigation), golden tests (optional UI verification)
**Target Platform**: Mobile (iOS/Android) + Web, with Material Design icons supported across all platforms
**Project Type**: mobile - Flutter application with go_router navigation system
**Performance Goals**: No performance impact - icon/text changes only, <200ms navigation transitions maintained
**Constraints**: Constitutional gates (C1-C5), WCAG AA accessibility, ≥44dp touch targets, no breaking changes to existing functionality
**Scale/Scope**: Single screen rename affecting 3-5 UI components, route configuration, and navigation structure

**User Technical Specifications**:
- Route aliases: '/fire-risk' → FireRiskScreen, '/' remains primary
- Icons: Icons.warning_amber (primary), Icons.report_outlined (fallback)
- UI strings: AppBar "Wildfire Risk", bottom nav "Fire Risk" 
- Migration: Phase 1 (UI/routes), Phase 2 (optional class renames)## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers widget tests (nav components), route tests, and optional golden tests
- [x] CI enforcement approach specified (existing CI pipeline)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (UI/text changes only, no new secrets)
- [x] Logging design excludes PII (no new logging, existing patterns preserved)
- [x] Secret scanning integrated into CI plan (existing pipeline continues)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (bottom nav icon maintains size)
- [x] Semantic labels planned for screen readers ("Current wildfire risk is {LEVEL}..." format)
- [x] A11y verification included in testing approach (semantic label tests planned)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (no color changes, existing palette preserved)
- [x] "Last Updated" timestamp visible in all data displays (functionality unchanged)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (no changes to existing chips)
- [x] Color validation approach planned (icon contrast verification for warning_amber)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (no new network calls)
- [x] Services expose clear error states (no service layer changes)
- [x] Retry/backoff strategies specified where needed (no new network operations)
- [x] Integration tests planned for error/fallback flows (route navigation with different states)

### Development Principles Alignment
- [x] "Fail visible, not silent" - existing error states preserved, no new failure modes
- [x] "Fallbacks, not blanks" - existing fallback behavior unchanged
- [x] "Keep logs clean" - no new logging introduced
- [x] "Single source of truth" - UI strings and routes defined in constants
- [x] "Mock-first dev" - existing mock support unchanged, UI changes testable

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
├── app.dart                     # Main app with go_router configuration (route updates needed)
├── screens/
│   └── home_screen.dart         # Will become FireRiskScreen UI (title updates)
├── controllers/
│   └── home_controller.dart     # State management (may rename to FireRiskController in Phase 2)
├── models/
│   └── home_state.dart          # State models (may rename in Phase 2)
├── widgets/
│   └── bottom_nav.dart          # Navigation component (icon + label updates)
├── theme/                       # UI constants and strings
├── config/                      # Route constants

test/
├── widget/                      # Widget tests for navigation components
├── integration/                 # Route navigation tests
└── unit/                        # Model and controller tests

android/, ios/, web/, macos/     # Platform builds (all support Material Icons)
```

**Structure Decision**: Flutter mobile application with existing home-related files. Primary changes needed in `bottom_nav.dart` (icon/label), `app.dart` (routes), `home_screen.dart` (AppBar title), and theme constants. Class/file renaming is deferred to Phase 2 to minimize change scope.

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
- Generate tasks based on user's 6-step technical plan and research findings
- UI Constants: Create/update UIConstants with new strings and icons [P]
- Navigation Component: Update bottom_nav.dart with new icon and label [P]
- Route Configuration: Add '/fire-risk' alias and update go_router config
- Screen Updates: Update AppBar titles in home_screen.dart
- Accessibility: Add semantic labels and validate touch targets
- Testing: Widget tests for navigation, route tests, accessibility tests

**Ordering Strategy**:
- Constants first (other components depend on them)
- Navigation and routing changes (core functionality)
- Screen UI updates (depends on constants)
- Accessibility enhancements (depends on UI changes)
- Test updates (validates all changes)
- Documentation updates

**Task Categorization**:
- [P] Parallel tasks: Constants, individual widget updates, independent tests
- Sequential: Route configuration → Navigation updates → Screen updates
- Validation: All tests must pass before completion

**Estimated Output**: 12-15 focused tasks following user's migration strategy

**Risk Mitigation Tasks**:
- Icon fallback implementation (Icons.report_outlined)
- Route compatibility validation
- Rollback preparation documentation

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
