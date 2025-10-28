# Tasks: A12 – Report Fire Screen (MVP)

**Input**: Design documents from `/specs/013-a12-report-fire/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory ✓
   → Tech stack: Dart 3.9.2, Flutter 3.35.5, url_launcher, go_router, flutter_test
   → Structure: Flutter mobile app with feature-based organization
2. Load optional design documents: ✓
   → data-model.md: EmergencyContact, EmergencyPriority, CallResult entities
   → contracts/: Platform contracts for url_launcher integration and widget testing
   → research.md: url_launcher strategy, Material 3 ColorScheme approach, accessibility testing
3. Generate tasks by category: ✓
   → Setup: dependencies, directory structure
   → Tests: widget tests, integration tests, accessibility tests
   → Core: models, widgets, screen, utilities
   → Integration: routing, navigation
   → Polish: manual QA, documentation
4. Apply task rules: ✓
   → Different files = marked [P] for parallel execution
   → Same file = sequential (no [P])
   → Tests before implementation (TDD approach)
5. Number tasks sequentially (T001, T002...) ✓
6. Generate dependency graph ✓
7. Create parallel execution examples ✓
8. Validate task completeness: ✓
   → All contracts have corresponding tests
   → All entities have model implementation tasks
   → All widgets have test coverage
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Flutter mobile application structure:
- **Core**: `lib/features/report/` for feature implementation
- **Tests**: `test/features/report/` for unit/widget tests
- **Integration**: `test/integration/report/` for full flow tests
- **Utilities**: `lib/utils/` for shared functionality

## Phase 3.1: Setup & Dependencies
- [x] **T001** Add url_launcher dependency to pubspec.yaml and run flutter pub get
- [x] **T002** [P] Create feature directory structure: lib/features/report/{screens,models,widgets}
- [x] **T003** [P] Create test directory structure: test/features/report/{screens,models,widgets}
- [x] **T004** [P] Create integration test directory: test/integration/report/
- [x] **T005** [P] Configure flutter analyze and dart format validation (C1: Code Quality)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] **T006** [P] Create EmergencyContact model test in test/features/report/models/emergency_contact_test.dart
- [ ] **T007** [P] Create EmergencyButton widget test in test/features/report/widgets/emergency_button_test.dart  
- [ ] **T008** [P] Create URL launcher utility test in test/utils/url_launcher_utils_test.dart
- [ ] **T009** Create ReportFireScreen widget test in test/features/report/screens/report_fire_screen_test.dart
- [ ] **T010** [P] Create integration test for full user flow in test/integration/report/report_fire_integration_test.dart
- [ ] **T011** [P] Create accessibility validation tests for ≥44dp touch targets and semantic labels (C3: Accessibility)

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] **T012** [P] Create EmergencyContact model with EmergencyPriority and CallResult enums in lib/features/report/models/emergency_contact.dart
- [ ] **T013** [P] Create URL launcher utility with error handling in lib/utils/url_launcher_utils.dart
- [ ] **T014** Create EmergencyButton widget with Material 3 ColorScheme styling in lib/features/report/widgets/emergency_button.dart
- [ ] **T015** Create ReportFireScreen with three emergency contact buttons in lib/features/report/screens/report_fire_screen.dart
- [ ] **T016** [P] Implement emergency contact constants for Scotland fire reporting
- [ ] **T017** [P] Add SnackBar fallback handling for unsupported platforms (tel: scheme failures)
- [ ] **T018** [P] Implement semantic labels and accessibility features (C3: Accessibility)

## Phase 3.4: Integration & Navigation
- [ ] **T019** Add "/report" route to go_router configuration
- [ ] **T020** Add navigation link from Home screen to Report Fire screen
- [ ] **T021** Verify deep-link functionality for web platform
- [ ] **T022** [P] Implement error state handling with visible feedback (C5: Resilience)
- [ ] **T023** [P] Add Material 3 theme compliance with emergency styling (C4: Trust & Transparency)

## Phase 3.5: Quality Assurance & Polish
- [ ] **T024** [P] Run manual QA on Android emulator to verify SnackBar fallback behavior
- [ ] **T025** [P] Run manual QA on iOS simulator to verify SnackBar fallback behavior  
- [ ] **T026** [P] Run manual QA on real device to verify dialer integration
- [ ] **T027** [P] Verify WCAG AA contrast ratios in both light and dark themes (C4: Trust & Transparency)
- [ ] **T028** [P] Performance validation: screen load <200ms, button response <100ms
- [ ] **T029** [P] Cross-platform validation on iOS, Android, Web, macOS web mode
- [ ] **T030** [P] Update feature documentation in docs/ or README
- [ ] **T031** [P] Update CHANGELOG.md with A12 feature addition

## Dependencies
- **Setup** (T001-T005) before everything
- **Tests** (T006-T011) before implementation (T012-T018)  
- **T006** (EmergencyContact test) blocks **T012** (EmergencyContact model)
- **T007** (EmergencyButton test) blocks **T014** (EmergencyButton widget)
- **T008** (URL launcher test) blocks **T013** (URL launcher utility)
- **T009** (ReportFireScreen test) blocks **T015** (ReportFireScreen implementation)
- **T012-T018** (Core implementation) before **T019-T023** (Integration)
- **T019-T023** (Integration) before **T024-T031** (QA & Polish)

## Parallel Execution Examples

### Setup Phase (5 minutes)
```bash
# T002-T004 can run in parallel:
mkdir -p lib/features/report/{screens,models,widgets}
mkdir -p test/features/report/{screens,models,widgets} 
mkdir -p test/integration/report/
```

### TDD Test Creation Phase (15 minutes)
```bash
# T006-T008, T010-T011 can run in parallel:
Task: "Create EmergencyContact model test in test/features/report/models/emergency_contact_test.dart"
Task: "Create EmergencyButton widget test in test/features/report/widgets/emergency_button_test.dart" 
Task: "Create URL launcher utility test in test/utils/url_launcher_utils_test.dart"
Task: "Create integration test for full user flow in test/integration/report/report_fire_integration_test.dart"
Task: "Create accessibility validation tests for ≥44dp touch targets and semantic labels"
```

### Core Implementation Phase (30 minutes)
```bash
# T012-T013, T016-T018 can run in parallel:
Task: "Create EmergencyContact model with enums in lib/features/report/models/emergency_contact.dart"
Task: "Create URL launcher utility with error handling in lib/utils/url_launcher_utils.dart"
Task: "Implement emergency contact constants for Scotland fire reporting"
Task: "Add SnackBar fallback handling for unsupported platforms"
Task: "Implement semantic labels and accessibility features"
```

### QA & Polish Phase (20 minutes)
```bash
# T024-T031 can run in parallel:
Task: "Run manual QA on Android emulator to verify SnackBar fallback behavior"
Task: "Run manual QA on iOS simulator to verify SnackBar fallback behavior"
Task: "Run manual QA on real device to verify dialer integration" 
Task: "Verify WCAG AA contrast ratios in both light and dark themes"
Task: "Performance validation: screen load <200ms, button response <100ms"
Task: "Update feature documentation and CHANGELOG.md"
```

## Constitutional Compliance Integration

### C1. Code Quality & Tests
- **T005**: Configure flutter analyze and dart format validation
- **T006-T011**: Comprehensive test coverage before implementation
- All implementation tasks require passing tests

### C2. Secrets & Logging  
- **T013**: URL launcher utility with no PII logging
- **T016**: Static emergency contacts (no secrets required)
- No coordinate logging (feature doesn't collect location data)

### C3. Accessibility (UI features only)
- **T011**: Accessibility validation tests for ≥44dp touch targets and semantic labels
- **T018**: Implement semantic labels and accessibility features
- **T027**: WCAG AA contrast ratio verification

### C4. Trust & Transparency
- **T016**: Official Scottish emergency contact constants
- **T023**: Material 3 theme compliance with emergency styling
- **T027**: Color validation in light and dark themes

### C5. Resilience & Test Coverage
- **T010**: Integration tests for error/fallback flows
- **T017**: SnackBar fallback handling for unsupported platforms
- **T022**: Error state handling with visible feedback
- **T024-T026**: Manual QA for platform-specific behavior

## Development Principles Alignment

### "Fail visible, not silent"
- **T017**: SnackBar notifications for dialer failures
- **T022**: Visible error states for all failure modes

### "Fallbacks, not blanks"  
- **T017**: Manual dialing instructions when tel: scheme fails
- **T024-T026**: Emulator fallback behavior validation

### "Keep logs clean"
- **T013**: URL launcher utility with structured logging, no PII

### "Single source of truth"
- **T016**: Emergency contact constants with validation
- **T023**: Theme constants for consistent styling

### "Mock-first dev" 
- **T016**: Static emergency contacts (no mock injection needed)
- **T006-T011**: Test-first approach with const test data

## Task Validation Checklist
*GATE: Verified before execution*

- [x] All contracts have corresponding tests (T006-T011 cover platform and widget contracts)
- [x] All entities have model tasks (T012 implements EmergencyContact, EmergencyPriority, CallResult)
- [x] All tests come before implementation (T006-T011 before T012-T018)
- [x] Parallel tasks truly independent (different files, no shared dependencies)
- [x] Each task specifies exact file path (all tasks include absolute paths)
- [x] No task modifies same file as another [P] task (verified no conflicts)

## Expected Timeline
- **Total Estimated Time**: 70-90 minutes
- **Setup**: 5 minutes (T001-T005)
- **TDD Tests**: 15 minutes (T006-T011)
- **Core Implementation**: 30 minutes (T012-T018)
- **Integration**: 10 minutes (T019-T023)
- **QA & Polish**: 20 minutes (T024-T031)

**Success Criteria**: All tests pass, manual QA validates dialer integration and fallback behavior, constitutional compliance verified, accessibility standards met.