
# Implementation Plan: A9: Add blank Map screen and navigation

**Branch**: `010-a9-add-blank` | **Date**: 2025-10-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-a9-add-blank/spec.md`

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
Create a blank Map screen with AppBar titled 'Map' and navigation from Home screen via go_router '/map' route. Feature-based module architecture in lib/features/map/screens/map_screen.dart with temporary ElevatedButton on HomeScreen. Ensures accessibility compliance and widget test coverage while serving as placeholder for future map functionality.

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK (existing project setup)  
**Primary Dependencies**: go_router (routing), flutter_test (testing)  
**Storage**: N/A (UI navigation feature only)  
**Testing**: flutter_test for widget tests, flutter analyzer for code quality  
**Target Platform**: Flutter multi-platform (macOS, iOS, Android, web)
**Project Type**: Mobile (Flutter app with existing architecture)  
**Performance Goals**: 60 fps UI rendering, instant navigation transitions  
**Constraints**: Constitution guardrails C1-C5, accessibility requirements (≥44dp targets + semantic labels)  
**Scale/Scope**: Single screen addition to existing wildfire risk app

**User-provided Architecture**: Feature-based module (lib/features/map/screens/map_screen.dart); route registered in app_router; temporary ElevatedButton on HomeScreen opens MapScreen.

**User-provided Integration**: Connects with existing Home screen (A6) navigation; conforms to app_router pattern from earlier specs.

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements (enforced by CI)
- [x] Testing strategy covers unit/widget tests for applicable components (MapScreen widget test)
- [x] CI enforcement approach specified (existing CI pipeline)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (navigation feature only, no external services)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision (N/A for navigation)
- [x] Secret scanning integrated into CI plan (existing CI configuration)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (ElevatedButton follows Flutter defaults)
- [x] Semantic labels planned for screen readers (semanticsLabel for navigation button)
- [x] A11y verification included in testing approach (widget test semantics verification)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (N/A - blank screen, no risk data)
- [x] "Last Updated" timestamp visible in all data displays (N/A - no data display)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (N/A - placeholder screen)
- [x] Color validation approach planned (N/A - using default Flutter/Material colors only)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (N/A - no network calls in this feature)
- [x] Services expose clear error states (N/A - UI navigation only)
- [x] Retry/backoff strategies specified where needed (N/A - no external services)
- [x] Integration tests planned for error/fallback flows (widget test covers navigation flow)

### Development Principles Alignment
- [x] "Fail visible, not silent" - loading/error/cached states planned (N/A - simple navigation)
- [x] "Fallbacks, not blanks" - cached/mock fallbacks with clear labels (N/A - no data)
- [x] "Keep logs clean" - structured logging, no PII (N/A - navigation logging minimal)
- [x] "Single source of truth" - colors/thresholds in constants with tests (using Flutter theme)
- [x] "Mock-first dev" - UI components support mock data injection (N/A - static screen)

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
│       └── screens/
│           └── map_screen.dart     # New MapScreen widget
├── app.dart                        # Update with route registration
├── main.dart                       # Existing entry point
├── screens/
│   └── home/
│       └── home_screen.dart        # Update with navigation button
└── theme/                          # Existing theme resources

test/
├── widget/
│   └── features/
│       └── map/
│           └── map_screen_test.dart # New widget tests
└── integration/                    # Existing integration tests
```

**Structure Decision**: Flutter mobile app with feature-based architecture. The Map feature follows the established pattern of organizing screens by feature under lib/features/. Navigation integration with existing Home screen and router configuration.

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
- Generate tasks from Phase 1 design docs (data-model.md, quickstart.md)
- Focus on UI component creation and navigation integration
- Widget test tasks before implementation tasks (TDD approach)
- Integration with existing Home screen and router config

**Specific Task Categories for A9**:
1. **Widget Test Creation**: MapScreen widget test [P]
2. **MapScreen Implementation**: Create blank Map screen widget [P]
3. **Route Registration**: Add '/map' route to app router configuration
4. **Home Screen Integration**: Add navigation button to existing HomeScreen
5. **Navigation Test**: Widget test for navigation functionality
6. **Accessibility Test**: Verify semantic labels and touch targets
7. **Integration Test**: End-to-end navigation flow validation

**Ordering Strategy**:
- Test-Driven Development: Widget tests before implementations
- Dependency order: MapScreen → Route registration → Home integration
- Mark [P] for parallel execution where files are independent
- Final integration and validation tasks depend on all components

**Estimated Output**: 8-10 numbered, ordered tasks in tasks.md

**Flutter-Specific Considerations**:
- Widget testing with flutter_test framework
- go_router route configuration patterns
- Material Design accessibility compliance
- Feature-based file organization under lib/features/map/

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
- [x] All NEEDS CLARIFICATION resolved (none found)
- [x] Complexity deviations documented (none required)

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
