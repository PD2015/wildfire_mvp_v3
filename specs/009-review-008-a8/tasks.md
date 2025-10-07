# Tasks: A8 Debugging Tests

**Input**: Design documents from `/specs/009-review-008-a8/`
**Prerequisites**: plan.md (✓), research.md (✓), data-model.md (✓), contracts/ (✓), quickstart.md (✓)

## Execution Flow Summary
1. ✅ Loaded plan.md: Dart 3.0+ Flutter, flutter_test/mockito/coverage tools
2. ✅ Loaded data-model.md: TestScenario, CoverageTarget, DebuggingModification entities
3. ✅ Loaded contracts/: 4 test contracts (GPS bypass, cache clearing, integration, restoration)
4. ✅ Loaded quickstart.md: 6-step validation workflow with specific test scenarios
5. ✅ Generated tasks by category: Setup → Tests → Implementation → Integration → Polish
6. ✅ Applied TDD ordering: All tests before implementation
7. ✅ Marked [P] for independent files, sequential for shared files

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **Target Coverage**: 90%+ overall, 100% GPS bypass, 95% cache clearing

## Phase 3.1: Setup & Infrastructure
- [x] T001 [P] Configure test coverage analysis with lcov integration in `coverage/` directory
- [x] T002 [P] Set up mockito test infrastructure and mock generation in `test/` directory
- [x] T003 [P] Create test fixtures for debugging scenarios in `test/fixtures/debugging_test_data.dart`
- [x] T004 [P] Configure flutter_test environment with SharedPreferences testing support
- [x] T005 [P] Set up test reporting and coverage thresholds (90% target) in CI configuration

## Phase 3.2: Test Entity Models (TDD - Must fail first)
- [x] T006 [P] TestScenario model in `test/models/test_scenario.dart`
- [x] T007 [P] TestStep model in `test/models/test_step.dart`
- [x] T008 [P] CoverageTarget model in `test/models/coverage_target.dart`
- [x] T009 [P] DebuggingModification model in `test/models/debugging_modification.dart`
- [x] T010 [P] ExpectedOutcome model in `test/models/expected_outcome.dart`

## Phase 3.3: Contract Tests (TDD - Critical, must fail first)
**CRITICAL: These tests MUST be written and MUST FAIL before ANY debugging validation**

### GPS Bypass Contract Tests
- [x] T011 [P] GPS bypass activation test in `test/unit/services/location_resolver_gps_bypass_test.dart`
- [x] T012 [P] GPS service not called validation in `test/unit/services/location_resolver_gps_bypass_test.dart`
- [x] T013 [P] Bypass state validation test in `test/unit/services/location_resolver_gps_bypass_test.dart`
- [x] T014 [P] GPS bypass error handling test in `test/unit/services/location_resolver_gps_bypass_test.dart`

### Cache Clearing Contract Tests
- [x] T015 [P] Complete cache clearing test (5 keys) in `test/unit/main_cache_clearing_test.dart`
- [x] T016 [P] Cache state validation before/after clearing in `test/unit/main_cache_clearing_test.dart`
- [x] T017 [P] Test mode preservation during clearing in `test/unit/main_cache_clearing_test.dart`
- [x] T018 [P] SharedPreferences error handling in cache clearing in `test/unit/main_cache_clearing_test.dart`

### Integration Contract Tests
- [x] T019 [P] GPS bypass to FireRiskService integration test in `test/integration/debugging_scenarios_test.dart`
- [x] T020 [P] Cache clearing to LocationResolver integration test in `test/integration/debugging_scenarios_test.dart`
- [x] T021 [P] End-to-end debugging flow validation in `test/integration/debugging_scenarios_test.dart`

### Production Restoration Contract Tests
- [x] T022 [P] GPS bypass removal validation in `test/restoration/gps_restoration_test.dart`
- [x] T023 [P] Scotland centroid restoration validation in `test/restoration/coordinate_accuracy_test.dart`
- [x] T024 [P] Cache clearing restoration validation in `test/restoration/production_readiness_test.dart`
- [x] T025 [P] Debug logging removal validation in `test/restoration/production_readiness_test.dart`

## Phase 3.4: Widget Tests (TDD)
#### Phase 3.4: Widget Tests (T026-T029)
- [x] **T026**: Create home screen GPS bypass coordinate display widget tests
  - Description: Test widget displays debugging coordinates when GPS bypass is enabled
  - Dependencies: T011-T014 contract tests, TestScenario models (T006)
  - Coverage: HomeScreen debugging UI components

- [x] **T027**: Create cache clearing button widget tests
  - Description: Test cache clearing UI components and interactions
  - Dependencies: T015-T018 contract tests, DebuggingModification models (T008)
  - Coverage: Debug mode cache clearing widgets

- [x] **T028**: Create coordinate validation widget tests
  - Description: Test coordinate input validation and error display widgets
  - Dependencies: Location validation utilities, coordinate bounds checking
  - Coverage: Input validation components

- [x] **T029**: Create end-to-end debugging widget integration tests
  - Description: Test complete debugging workflow UI integration
  - Dependencies: T019-T021 integration tests, all widget components
  - Coverage: Full debugging flow widget integration

## Phase 3.5: Coverage Validation Implementation
**ONLY after all tests are failing**

### GPS Bypass Logic Validation
- [ ] T030 Validate GPS bypass returns Aviemore coordinates (57.2, -3.8) in `lib/services/location_resolver_impl.dart`
- [ ] T031 Validate no GPS service calls during bypass in `lib/services/location_resolver_impl.dart`
- [ ] T032 Validate bypass state reporting accuracy in `lib/services/location_resolver_impl.dart`
- [ ] T033 Validate bypass error recovery to Scotland centroid in `lib/services/location_resolver_impl.dart`

### Enhanced Cache Clearing Validation
- [ ] T034 Validate all 5 SharedPreferences keys cleared in `lib/main.dart`
- [ ] T035 Validate test mode settings preservation in `lib/main.dart`
- [ ] T036 Validate cache state logging before/after clearing in `lib/main.dart`
- [ ] T037 Validate error handling for SharedPreferences failures in `lib/main.dart`

### Integration Validation
- [ ] T038 Validate GPS bypass coordinates work with FireRiskService in service integration
- [ ] T039 Validate cache clearing integrates with LocationResolver fallback in service integration
- [ ] T040 Validate coordinate accuracy throughout service chain in service integration

## Phase 3.6: Production Restoration Implementation
- [ ] T041 [P] Implement GPS bypass clean removal procedure in restoration utilities
- [ ] T042 [P] Implement Scotland centroid restoration (55.8642, -4.2518) in restoration utilities
- [ ] T043 [P] Implement cache clearing behavior restoration in restoration utilities
- [ ] T044 [P] Implement debug logging removal procedure in restoration utilities

## Phase 3.7: Coverage Analysis & Polish
- [ ] T045 [P] Generate comprehensive coverage report with lcov analysis
- [ ] T046 [P] Validate 90%+ overall coverage achievement
- [ ] T047 [P] Validate 100% GPS bypass logic coverage achievement
- [ ] T048 [P] Validate 95% cache clearing coverage achievement
- [ ] T049 [P] Performance validation: test suite execution <5 minutes
- [ ] T050 [P] Cross-platform test validation (iOS, Android, Web)
- [ ] T051 [P] Update debugging session documentation with test results
- [ ] T052 [P] Create test execution runbook based on quickstart.md scenarios

## Dependencies
- **Setup** (T001-T005) before everything
- **Models** (T006-T010) before contract tests
- **Contract Tests** (T011-T025) before implementation (T030-T044)
- **Widget Tests** (T026-T029) before integration validation (T038-T040)
- **Implementation** (T030-T044) before coverage analysis (T045-T052)
- **T015-T018** require T034-T037 for cache clearing validation
- **T011-T014** require T030-T033 for GPS bypass validation
- **T022-T025** require T041-T044 for restoration validation

## Parallel Execution Examples

### Phase 3.2: Test Models (All parallel)
```bash
# Launch T006-T010 together (different files):
flutter create test/models/test_scenario.dart
flutter create test/models/test_step.dart  
flutter create test/models/coverage_target.dart
flutter create test/models/debugging_modification.dart
flutter create test/models/expected_outcome.dart
```

### Phase 3.3: Contract Tests by Category (Parallel within category)
```bash
# GPS Bypass Tests (T011-T014 - same file, sequential)
flutter test test/unit/services/location_resolver_gps_bypass_test.dart

# Cache Clearing Tests (T015-T018 - same file, sequential)  
flutter test test/unit/main_cache_clearing_test.dart

# Integration Tests (T019-T021 - same file, sequential)
flutter test test/integration/debugging_scenarios_test.dart

# Restoration Tests (T022-T025 - different files, parallel)
flutter test test/restoration/gps_restoration_test.dart &
flutter test test/restoration/coordinate_accuracy_test.dart &
flutter test test/restoration/production_readiness_test.dart &
wait
```

### Phase 3.7: Coverage Analysis (All parallel)
```bash
# Launch T045-T052 together (independent analysis tasks):
flutter test --coverage &
genhtml coverage/lcov.info -o coverage/html &
flutter test --platform=chrome &
flutter test --platform=android &
flutter test --platform=ios &
wait
```

## Validation Checklist
*GATE: Must verify before marking complete*

- [x] All 4 contracts have corresponding test tasks (T011-T025)
- [x] All 5 test entities have model tasks (T006-T010)
- [x] All contract tests come before implementation (T011-T025 → T030-T044)
- [x] Parallel tasks are truly independent (different files or analysis categories)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Coverage targets specified: 90% overall, 100% GPS bypass, 95% cache clearing
- [x] TDD ordering enforced: failing tests before implementation
- [x] Production restoration path clearly defined (T041-T044)

## Success Criteria
Upon completion of all tasks:
- ✅ **Coverage Achieved**: 90%+ overall, 100% GPS bypass, 95% cache clearing  
- ✅ **Functional Validation**: All debugging modifications tested and validated
- ✅ **Production Ready**: Clear restoration path documented and tested
- ✅ **Performance**: Test suite executes in <5 minutes
- ✅ **Cross-Platform**: Tests pass on iOS, Android, Web
- ✅ **Documentation**: Complete test coverage analysis and debugging session records

---
*52 tasks generated from 4 contracts, 5 entities, and comprehensive quickstart scenarios*