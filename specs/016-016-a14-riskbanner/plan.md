
# Implementation Plan: RiskBanner Visual Refresh

**Branch**: `016-016-a14-riskbanner` | **Date**: 2025-11-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-016-a14-riskbanner/spec.md`

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
Visual-only refresh of the RiskBanner component on Home screen with enhanced styling (16dp corner radius, 16dp padding, elevation 2), integrated location display with coordinates, internal timestamp and data source labeling, plus scaffolded weather panel behind config flag. No service or model changes - purely UI enhancement following accessibility and constitutional requirements.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable
**Primary Dependencies**: Flutter SDK, Material Design, existing RiskPalette, CachedBadge widget
**Storage**: N/A (UI-only changes, no data persistence)
**Testing**: flutter_test (widget tests), golden tests for visual regression, existing test infrastructure
**Target Platform**: iOS, Android, Web (cross-platform Flutter)
**Project Type**: mobile (Flutter app with cross-platform support)
**Performance Goals**: 60fps UI rendering, <16ms frame budget for animations
**Constraints**: Visual-only changes (no service modifications), preserve existing accessibility (≥44dp touch targets), maintain dark mode support with luminance-based text colors, keep existing RiskPalette and FireRisk model unchanged
**Scale/Scope**: Single widget refactor (lib/widgets/risk_banner.dart), 2 screen updates (home_screen.dart), comprehensive golden test coverage, estimated 8-12 widget test updates

**User-Provided Implementation Details**:
- Local tokens: kBannerRadius=16.0, kBannerPadding=EdgeInsets.all(16), kBannerElevation=2.0
- Card/Material container with specified styling for all states (success/loading/error)
- Location row: Icon(Icons.location_on) + formatted coordinates when provided
- Internal timestamp and data source text display
- RiskBannerConfig class for weather panel toggle (showWeatherPanel: false default)
- Weather panel scaffolding: nested rounded sub-card with Temperature/Humidity/Wind Speed columns
- Golden tests for each risk level (light mode) plus one dark mode test (Moderate level)
- Error state uses warning_amber_rounded or error_outline_rounded icons (avoid fire icon)## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit/widget tests for applicable components (existing logic tests preserved, golden tests added, widget tests for location row)
- [x] CI enforcement approach specified (existing CI pipeline enforces analyze/format/test)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (UI-only changes, no new secrets)
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision (location display uses existing coordinate formatting to 2 decimals)
- [x] Secret scanning integrated into CI plan (existing CI pipeline includes secret scanning)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (FR-013: maintain minimum 44dp touch target size)
- [x] Semantic labels planned for screen readers (FR-014: preserve existing semantic information)
- [x] A11y verification included in testing approach (widget tests will verify semantic labels and touch targets)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (FR-005: preserve existing RiskPalette mapping)
- [x] "Last Updated" timestamp visible in all data displays (FR-008: timestamp inside banner)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (FR-007: "Data Source: {SOURCE}" inside banner)
- [x] Color validation approach planned (golden tests will verify correct RiskPalette colors per risk level)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (N/A: UI-only changes, no new network calls)
- [x] Services expose clear error states (no silent failures) (N/A: no service changes, error state UI enhanced with proper icons)
- [x] Retry/backoff strategies specified where needed (N/A: UI-only changes)
- [x] Integration tests planned for error/fallback flows (error state widget tests verify proper icon usage and onRetry functionality)

### Development Principles Alignment
- [x] "Fail visible, not silent" - loading/error/cached states planned (all three states get consistent styling, error state uses clear warning icons)
- [x] "Fallbacks, not blanks" - cached/mock fallbacks with clear labels (CachedBadge preserved, data source clearly labeled)
- [x] "Keep logs clean" - structured logging, no PII (coordinate display limited to 2 decimals as per existing patterns)
- [x] "Single source of truth" - colors/thresholds in constants with tests (RiskPalette preserved, local styling tokens defined as constants)
- [x] "Mock-first dev" - UI components support mock data injection (existing mock support preserved, golden tests use mock data)

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
├── widgets/
│   └── risk_banner.dart        # Primary target: visual refresh with config
├── screens/
│   └── home_screen.dart        # Secondary: pass coordinates, remove external timestamp
├── models/                     # No changes (preserved FireRisk model)
├── services/                   # No changes (preserved service contracts)
├── theme/                      # No changes (preserved RiskPalette)
└── config/
    └── feature_flags.dart      # Potential addition for weather panel config

test/
├── widget/
│   ├── risk_banner_test.dart   # Updated expectations, location row tests
│   └── golden/
│       └── risk_banner_*.dart  # New golden test files
├── goldens/
│   └── risk_banner/
│       └── *.png               # New golden reference images
└── integration/                # No changes expected

assets/
└── mock/                       # No changes (existing mock data preserved)
```

**Structure Decision**: Flutter mobile app structure with cross-platform support. Focus on `lib/widgets/risk_banner.dart` as primary target with supporting changes to `home_screen.dart` for coordinate passing and timestamp removal. Comprehensive golden test coverage added to prevent visual regressions.

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
- RiskBannerConfig class creation → model creation task [P]
- Each golden test → visual regression test task [P]
- Widget contract → widget enhancement task
- Test contract → test update tasks [P]
- HomeScreen integration → coordinate passing task

**Ordering Strategy**:
- TDD order: Golden tests and widget tests before implementation
- Dependency order: Configuration class → Widget changes → Integration updates
- Mark [P] for parallel execution (independent golden test files)
- Sequence: Config class → Widget styling → Location integration → Weather scaffolding → Test updates

**Estimated Output**: 15-20 numbered, ordered tasks in tasks.md
- 1 config class task
- 7 golden test tasks (6 light + 1 dark)
- 3-4 widget enhancement tasks
- 2-3 test update tasks
- 1-2 integration tasks

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
- [x] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS (all contracts preserve constitutional requirements)
- [x] All NEEDS CLARIFICATION resolved (no unclear areas in technical context)
- [x] Complexity deviations documented (none required - straightforward UI refresh)

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
