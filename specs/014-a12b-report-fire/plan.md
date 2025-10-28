
# Implementation Plan: A12b – Report Fire Screen (Descriptive)

**Branch**: `014-a12b-report-fire` | **Date**: 2025-10-28 | **Spec**: [specs/014-a12b-report-fire/spec.md](spec.md)
**Input**: Feature specification from `/specs/014-a12b-report-fire/spec.md`

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
Replace/extend the existing A12 MVP "Report a Fire" screen with enhanced Scotland-specific guidance while preserving existing emergency calling functionality. The descriptive version includes richer copy with examples of what to report, safety posture guidance, and movement advice, maintaining one-tap calling for 999 (Fire Service), 101 (Police Scotland), and 0800 555 111 (Crimestoppers). All content must be accessible, offline-capable, and privacy-preserving.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable  
**Primary Dependencies**: url_launcher ^6.3.0 (native dialer integration), go_router ^14.2.7 (navigation), flutter_test (testing)  
**Storage**: N/A (no data persistence required - static content only)  
**Testing**: flutter_test (widget tests), integration_test (accessibility testing), mockito ^5.4.2 (mocking)  
**Target Platform**: iOS 15+, Android API 21+, Web (Chrome/Safari), macOS (web mode only)
**Project Type**: mobile - Flutter cross-platform application with feature-based architecture  
**Performance Goals**: Instant screen load (<100ms), immediate button response (<50ms), zero network latency  
**Constraints**: Offline-capable, no network dependencies, WCAG AA contrast ratios, ≥48dp touch targets, Year 7-8 reading level  
**Scale/Scope**: Single enhanced screen with expanded guidance content, builds on existing A12 MVP Report Fire implementation

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers widget tests for UI components and accessibility 
- [x] CI enforcement approach specified (flutter analyze, flutter test)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (static content only, no API keys needed)
- [x] Logging design excludes PII (no user data collection per FR-018)
- [x] No secret scanning needed (no secrets in static UI feature)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥48dp touch targets (exceeds 44dp minimum)
- [x] Semantic labels planned for all buttons and guidance sections
- [x] A11y verification included in testing approach (VoiceOver/TalkBack compatibility)
- [x] AA contrast ratio compliance planned for light/dark themes

### C4. Trust & Transparency
- [x] Emergency contact buttons use official Scotland emergency numbers (999, 101, 0800 555 111)
- [x] No data displays requiring timestamps (static guidance content)
- [x] Clear source labeling for emergency services (Fire Service, Police Scotland, Crimestoppers)
- [x] Official emergency service branding preserved in button text

### C5. Resilience & Test Coverage
- [x] No network calls - purely offline functionality
- [x] Clear error states planned (SnackBar fallback for dialer failures)
- [x] No retry needed (static content, instant fallback notification)
- [x] Integration tests planned for offline/emulator scenarios

### Development Principles Alignment
- [x] "Fail visible, not silent" - SnackBar shows clear fallback message for dialer failures
- [x] "Fallbacks, not blanks" - manual dialing instructions shown when tel: URLs fail
- [x] "Keep logs clean" - debugPrint only, no PII (no user data collected)
- [x] "Single source of truth" - emergency contacts in constants with structured data model
- [x] "Mock-first dev" - static content supports test environments without dialer capability

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
│       │   └── report_fire_screen.dart        # Enhanced A12b screen (replaces A12 MVP)
│       ├── models/
│       │   ├── emergency_contact.dart         # Existing model (reused)
│       │   └── safety_guidance.dart           # New structured guidance content
│       └── widgets/
│           ├── emergency_button.dart          # Enhanced button with improved styling
│           ├── safety_tips_card.dart          # New safety guidance widget
│           └── guidance_section.dart          # New step-by-step guidance widget
├── utils/
│   └── url_launcher_utils.dart               # Existing utility (reused)
└── theme/
    └── emergency_colors.dart                 # Existing theme (reused)

test/
├── features/
│   └── report/
│       ├── screens/
│       │   └── report_fire_screen_test.dart  # Enhanced widget tests
│       ├── models/
│       │   └── safety_guidance_test.dart     # New model tests
│       └── widgets/
│           ├── safety_tips_card_test.dart    # New widget tests
│           └── guidance_section_test.dart    # New widget tests
└── integration/
    └── report/
        └── report_fire_integration_test.dart # Enhanced accessibility tests
```

**Structure Decision**: Flutter mobile application extending existing A12 Report Fire feature. The enhanced A12b version builds on the established feature-based architecture under `lib/features/report/`, reusing existing emergency contact models and url_launcher utilities while adding new structured guidance components. This maintains consistency with the existing codebase structure documented in copilot-instructions.md.

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
- Each SafetyGuidance/SafetyTipsCard model → model creation task [P]
- Each GuidanceSection/SafetyTipsCard widget → widget implementation task [P]
- Enhanced ReportFireScreen → screen implementation task (builds on existing A12)
- Each widget contract → widget test task [P]
- Each user story from quickstart.md → integration test task
- Accessibility compliance → accessibility test task

**Ordering Strategy**:
- TDD order: Tests before implementation (failing widget tests → implementation)
- Dependency order: Models → Widgets → Screen enhancement → Integration tests
- Mark [P] for parallel execution (independent files/components)
- Accessibility tests run after implementation to verify compliance

**Task Categories**:
1. **Models & Data** (2-3 tasks): SafetyGuidance, SafetyTip value objects
2. **Widget Components** (3-4 tasks): GuidanceSection, SafetyTipsCard, enhanced EmergencyButton styling
3. **Screen Enhancement** (1 task): Replace A12 ReportFireScreen with A12b descriptive version
4. **Widget Tests** (4-5 tasks): Test each new component independently
5. **Integration Tests** (2-3 tasks): Emergency call flows, accessibility navigation
6. **Content Validation** (1 task): Verify Scotland emergency service accuracy

**Estimated Output**: 18-22 numbered, ordered tasks in tasks.md

**Special Considerations for A12b**:
- Preserve existing A12 emergency calling functionality during enhancement
- Reuse existing EmergencyContact model and UrlLauncherUtils
- Focus on content structure and accessibility improvements over technical changes
- Ensure backwards compatibility with existing navigation and routing

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
