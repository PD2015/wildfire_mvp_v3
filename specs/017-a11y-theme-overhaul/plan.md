
# Implementation Plan: A11y Theme Overhaul & Risk Palette Segregation

**Branch**: `017-a11y-theme-overhaul` | **Date**: 2025-11-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/017-a11y-theme-overhaul/spec.md`

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
Replace the current MaterialApp theme with WildfireA11yTheme providing WCAG 2.1 AA compliant light and dark modes. Introduce BrandPalette for app chrome (navigation, surfaces, backgrounds) with guaranteed contrast ratios, while preserving RiskPalette exclusively for fire risk visualization widgets. Eliminate ad-hoc Colors.* usage throughout the app, ensuring all critical components (buttons, inputs, chips, snackbars, outlines) meet ≥4.5:1 text contrast requirements.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable  
**Primary Dependencies**: Flutter SDK, Material 3 (useMaterial3: true)  
**Storage**: N/A (theme configuration only, no persistence)  
**Testing**: flutter_test (unit tests for contrast ratios), widget tests (golden snapshots), manual testing (T010 icon contrast)  
**Target Platform**: Cross-platform (iOS, Android, Web, macOS)
**Project Type**: Mobile + Web (Flutter single codebase)  
**Performance Goals**: Theme switching <16ms, no jank during mode transitions  
**Constraints**: WCAG 2.1 AA compliance (≥4.5:1 normal text, ≥3:1 large text/UI), Material 3 only, preserve RiskPalette unchanged  
**Scale/Scope**: ~15 UI screens, ~30 reusable widgets, complete theme overhaul

**User-Provided Implementation Details**:
- Files to add: `lib/theme/brand_palette.dart`, `lib/theme/wildfire_a11y_theme.dart`
- Files to update: `lib/app.dart` (wire light/dark themes), `lib/theme/wildfire_theme.dart` (deprecate with comment), `lib/features/map/screens/map_screen.dart` (replace Colors.green/grey), app-wide sweep for Colors.* usage
- Files to document: `docs/ux_cues.md` (BrandPalette vs RiskPalette), `scripts/allowed_colors.txt` (add brand tokens)
- Files unchanged: `lib/theme/risk_palette.dart`, `lib/widgets/risk_banner.dart`, `lib/features/map/widgets/risk_result_chip.dart`
- Testing: `contrast_test.dart` (unit), golden snapshots (widget), manual T010 verification

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit/widget tests for applicable components (contrast_test.dart, golden snapshots)
- [x] CI enforcement approach specified (existing CI pipeline)

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (theme uses compile-time constants only)
- [x] Logging design excludes PII (no user data in theme layer)
- [x] Secret scanning integrated into CI plan (N/A for theme - no secrets involved)

### C3. Accessibility (UI features only)
- [x] Interactive elements designed as ≥44dp touch targets (maintained in component themes)
- [x] Semantic labels planned for screen readers (preserved from existing widgets)
- [x] A11y verification included in testing approach (contrast_test.dart unit tests + manual T010)

### C4. Trust & Transparency
- [x] Only official Scottish wildfire risk colors specified (RiskPalette preserved unchanged, BrandPalette for app chrome only)
- [x] "Last Updated" timestamp visible in all data displays (unchanged - risk widgets preserved)
- [x] Source labeling (EFFIS/SEPA/Cache/Mock) included in UI design (unchanged - risk widgets preserved)
- [x] Color validation approach planned (scripts/allowed_colors.txt updated, contrast tests)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling (N/A - theme layer only)
- [x] Services expose clear error states (N/A - theme layer only)
- [x] Retry/backoff strategies specified where needed (N/A - theme layer only)
- [x] Integration tests planned for error/fallback flows (N/A - theme layer only)

### Development Principles Alignment
- [x] "Fail visible, not silent" - Theme switching failures would be visibly broken UI (testable via golden snapshots)
- [x] "Fallbacks, not blanks" - Theme provides complete fallback coverage for all Material components
- [x] "Keep logs clean" - No logging in theme layer (pure configuration)
- [x] "Single source of truth" - BrandPalette and RiskPalette are sole color constants, unit tested for contrast
- [x] "Mock-first dev" - Theme supports both light/dark modes for comprehensive testing

## Project Structure

### Documentation (this feature)
```
specs/017-a11y-theme-overhaul/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (WCAG 2.1 AA standards, contrast calculation)
├── data-model.md        # Phase 1 output (BrandPalette, WildfireA11yTheme structure)
├── quickstart.md        # Phase 1 output (manual theme verification steps)
├── contracts/           # Phase 1 output (theme API contracts)
│   └── theme-contracts.md
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/
├── app.dart                      # [UPDATE] Wire WildfireA11yTheme.light/dark to MaterialApp
├── theme/
│   ├── brand_palette.dart        # [NEW] App chrome color tokens (forest, mint, amber, on-colors)
│   ├── wildfire_a11y_theme.dart  # [NEW] WCAG 2.1 AA compliant theme (light/dark)
│   ├── risk_palette.dart         # [UNCHANGED] Official Scottish risk colors
│   └── wildfire_theme.dart       # [UPDATE] Deprecate with comment pointing to new theme
├── features/
│   └── map/
│       └── screens/
│           └── map_screen.dart   # [UPDATE] Replace Colors.green/grey with theme.colorScheme
└── widgets/
    └── risk_banner.dart          # [UNCHANGED] Continues using RiskPalette

test/
├── unit/
│   └── theme/
│       └── contrast_test.dart    # [NEW] Unit tests for WCAG AA contrast ratios
└── widget/
    └── theme/
        └── component_theme_test.dart  # [NEW] Golden snapshots for themed components

docs/
└── ux_cues.md                    # [UPDATE] Document BrandPalette vs RiskPalette usage

scripts/
└── allowed_colors.txt            # [UPDATE] Add BrandPalette tokens to color guard
```

**Structure Decision**: Mobile + Web single codebase (Flutter). Theme layer is pure configuration with no business logic or data persistence. Changes isolated to `lib/theme/` with minimal touch points in `lib/app.dart` and sweep for ad-hoc `Colors.*` usage. Risk widgets (`lib/widgets/risk_banner.dart`, `lib/features/map/widgets/risk_result_chip.dart`) remain unchanged per C4 constitutional gate.

## Phase 0: Outline & Research

**Status**: ✅ COMPLETE

### Research Tasks Completed

1. **R1: WCAG 2.1 AA Contrast Requirements**
   - Decision: Use Level AA as baseline (≥4.5:1 normal text, ≥3:1 UI components)
   - Contrast calculation formula defined
   - Documented in research.md

2. **R2: Material 3 ColorScheme Architecture**
   - Decision: Use Material 3 semantic color roles
   - 40+ color tokens mapped to BrandPalette
   - Light/dark mode support via ColorScheme

3. **R3: BrandPalette Color Selection**
   - Decision: Forest green gradient + mint/amber accents
   - All contrast ratios verified (≥AA compliance)
   - Complete palette documented with hex values

4. **R4: Component Theme Overrides**
   - Decision: Override ElevatedButton, OutlinedButton, TextButton, InputDecoration, Chip, SnackBar
   - Ensures ≥44dp touch targets (C3) and AA contrast
   - Override patterns documented

5. **R5: Dark Mode Contrast Strategy**
   - Decision: Invert luminance, preserve brand hues
   - Dark mode ColorScheme mappings defined
   - All pairings verified for AA compliance

6. **R6: Migration Strategy for Ad-Hoc Colors.***
   - Decision: Automated grep search + manual replacement
   - Semantic mapping defined (Colors.green → colorScheme.primary)
   - Risk widget exclusion list documented

**Output**: research.md with zero NEEDS CLARIFICATION markers ✅

## Phase 1: Design & Contracts

**Status**: ✅ COMPLETE

### Deliverables

1. **data-model.md** ✅
   - Entity 1: BrandPalette (15 color constants + onColorFor utility)
   - Entity 2: WildfireA11yTheme (light/dark ThemeData getters)
   - Entity 3: RiskPalette (preserved unchanged per C4)
   - Validation rules and testing contracts defined

2. **contracts/theme-contracts.md** ✅
   - Contract 1: BrandPalette API with unit tests (contrast verification)
   - Contract 2: WildfireA11yTheme API with unit tests (theme structure, touch targets)
   - Contract 3: MaterialApp integration test
   - Contract 4: Ad-hoc Colors elimination verification script
   - Contract 5: Color guard integration (allowed_colors.txt update)
   - All contract tests written (currently failing - TDD approach)

3. **quickstart.md** ✅
   - 9-step manual verification procedure
   - Light mode visual checks (8 components)
   - Dark mode visual checks (6 components)
   - Contrast ratio verification (8 pairs)
   - Accessibility screen reader tests (iOS/Android)
   - Theme mode switching performance test
   - Ad-hoc colors sweep verification
   - Documentation verification
   - CI/CD integration check
   - Complete acceptance checklist (21 requirements)

4. **Agent context update** ✅
   - User provided implementation details integrated into plan
   - File addition/update list documented
   - Testing strategy defined
   - Constitution gates compliance verified

**Phase 1 Constitution Re-check**: ✅ PASS (all gates verified in Constitution Check section above)

**Output**: Complete design documentation ready for task generation

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:

### Task Categories

1. **Contract Test Tasks** (P = parallel execution)
   - [P] Create `test/unit/theme/brand_palette_test.dart` (BrandPalette contract tests)
   - [P] Create `test/unit/theme/wildfire_a11y_theme_test.dart` (WildfireA11yTheme contract tests)
   - [P] Create `test/widget/theme/app_theme_integration_test.dart` (MaterialApp integration test)
   - [P] Create `scripts/verify_no_adhoc_colors.sh` (ad-hoc Colors.* verification script)

2. **Model Creation Tasks** (must complete before implementation)
   - Create `lib/theme/brand_palette.dart` (15 color constants + onColorFor method)
   - Create `lib/theme/wildfire_a11y_theme.dart` (light/dark ThemeData getters with component overrides)

3. **Integration Tasks** (depends on models)
   - Update `lib/app.dart` to wire WildfireA11yTheme.light/dark to MaterialApp
   - Update `lib/theme/wildfire_theme.dart` to add deprecation comment
   - Update `scripts/allowed_colors.txt` to include BrandPalette tokens

4. **Sweep Tasks** (ad-hoc Colors.* replacement)
   - Update `lib/features/map/screens/map_screen.dart` (replace Colors.green/grey with theme)
   - [P] Sweep all files in `lib/features/` for Colors.* usage (excluding risk widgets)
   - [P] Sweep all files in `lib/widgets/` for Colors.* usage (excluding risk_banner.dart)
   - [P] Sweep all files in `lib/screens/` for Colors.* usage

5. **Documentation Tasks** (P)
   - [P] Update `docs/ux_cues.md` to document BrandPalette vs RiskPalette segregation
   - [P] Add usage examples to BrandPalette dartdoc comments
   - [P] Add usage examples to WildfireA11yTheme dartdoc comments

6. **Verification Tasks** (final validation)
   - Run all unit tests and verify PASS
   - Run ad-hoc colors verification script and verify PASS
   - Run color guard script and verify PASS
   - Execute quickstart.md manual verification steps
   - Run flutter analyze and verify zero issues

**Ordering Strategy**:

```
Phase 2.1: Test Infrastructure (parallel)
├── Contract tests (all run in parallel)
└── Verification scripts

Phase 2.2: Core Implementation (sequential - models first)
├── BrandPalette implementation
├── WildfireA11yTheme implementation
└── Run tests (should PASS after implementation)

Phase 2.3: Integration (sequential)
├── MaterialApp wiring
├── Old theme deprecation
└── Color guard update

Phase 2.4: Sweep (parallel within categories)
├── Map screen update
└── All other lib/ files (parallel sweep)

Phase 2.5: Documentation (parallel)
├── ux_cues.md
└── Dartdoc comments

Phase 2.6: Final Verification (sequential)
├── All automated tests
├── Verification scripts
├── Manual quickstart
└── CI checks (analyze, format, test)
```

**Estimated Task Count**: 25-30 tasks

**Estimated Completion Time**: 
- Contract tests: 2 hours (parallel)
- Core implementation: 3 hours (critical path)
- Integration: 1 hour
- Sweep: 2 hours (parallel)
- Documentation: 1 hour (parallel)
- Verification: 1 hour
- **Total**: ~10 hours (with parallelization)

**Dependencies**:
- BrandPalette must complete before WildfireA11yTheme (color constant dependency)
- Both models must complete before MaterialApp integration
- All implementation must complete before sweep verification
- All tasks must complete before manual quickstart

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan. The /plan command STOPS here.

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

**No complexity deviations identified**. This feature:
- Uses standard Material 3 theming patterns
- No additional projects or architectural layers
- Pure configuration (no business logic)
- Isolated to theme layer with minimal touch points
- Follows Flutter best practices for ColorScheme and ThemeData

All constitutional gates passed without exceptions or justifications needed.


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) ✅
- [x] Phase 1: Design complete (/plan command) ✅
- [x] Phase 2: Task planning complete (/plan command - describe approach only) ✅
- [ ] Phase 3: Tasks generated (/tasks command - NEXT STEP)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS ✅
- [x] Post-Design Constitution Check: PASS ✅
- [x] All NEEDS CLARIFICATION resolved ✅
- [x] Complexity deviations documented (none identified) ✅

**Artifacts Generated**:
- [x] research.md (6 research tasks completed)
- [x] data-model.md (3 entities documented)
- [x] contracts/theme-contracts.md (5 contracts with tests)
- [x] quickstart.md (9-step verification procedure)
- [x] plan.md (this file)

**Next Command**: Run `/tasks` to generate tasks.md from this plan

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
