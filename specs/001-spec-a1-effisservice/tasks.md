# Tasks: EffisService (FWI Point Query)

**Input**: Design documents from `/specs/001-spec-a1-effisservice/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Flutter project**: `lib/`, `test/` at repository root
- Paths aligned with plan.md structure

---

## Phase 3.1: Setup & Dependencies
- [X] T001 Initialize complete Flutter project structure and validate functionality
  **CRITICAL**: Run `flutter create --project-name wildfire_mvp_v3 --description "Scottish wildfire risk assessment mobile app with EFFIS integration" .` from repository root
  **VALIDATION**: 
  - Run `flutter doctor` (ensure no critical issues)
  - Run `flutter analyze` (must show "No issues found")
  - Run `flutter test` (must show "All tests passed")
  - Test app functionality: `flutter run` (verify app launches successfully)
  - Verify multi-platform support: iOS/, Android/, Web/, macOS/, Linux/, Windows/ directories created
  - Confirm INTERNET permission in android/app/src/main/AndroidManifest.xml for EFFIS API calls
  (✅ COMPLETE: Complete Flutter project with multi-platform support validated)
- [X] T002 Add dependencies to pubspec.yaml: http ^1.1.0, dartz ^0.10.1, equatable ^2.0.5
- [X] T003 [P] Add dev dependencies: mockito ^5.4.2, build_runner ^2.4.7 (C1: Code Quality)
- [X] T004 [P] Configure flutter analyze and dart format in existing CI (C1: Code Quality)

## Phase 3.2: Test Fixtures & Contract Tests (TDD Setup)
**CRITICAL: Create test fixtures BEFORE implementation to enable TDD**
- [X] T005 [P] Create test fixtures directory `test/fixtures/effis/`
- [X] T006 [P] Create EFFIS success response fixture `test/fixtures/effis/edinburgh_success.json`
- [X] T007 [P] Create EFFIS error fixtures: `404.json`, `503.json`, `malformed.json`, `empty_features.json`
- [X] T008 [P] Create fixture-based contract test file `test/contract/effis_responses_contract_test.dart` with failing tests

## Phase 3.3: Models & Value Objects (TDD)
**CRITICAL: Write failing tests BEFORE implementing models**
- [ ] T009 [P] Create failing unit tests `test/unit/models/risk_level_test.dart` for FWI mapping boundaries
- [ ] T010 [P] Create failing unit tests `test/unit/models/api_error_test.dart` for error categorization with reason codes
- [ ] T011 [P] Create failing unit tests `test/unit/models/effis_fwi_result_test.dart` for validation and timezone handling

## Phase 3.4: Model Implementation (After Tests Fail)
- [ ] T012 [P] Implement `lib/models/risk_level.dart` with fromFwi() mapping (spec:A1)
- [ ] T013 [P] Implement `lib/models/api_error.dart` with error types, categorization, and reason codes (timeout, rateLimited, serverError, malformed) (spec:A1)
- [ ] T014 [P] Implement `lib/models/effis_fwi_result.dart` with validation rules and UTC timezone parsing (spec:A1)

## Phase 3.5: Service Interface & Tests (TDD)
**CRITICAL: Service tests must fail before implementation**
- [ ] T015 Create failing contract tests `test/unit/services/effis_service_test.dart` using mocked http.Client and fixtures (C5: Resilience)
- [ ] T016 Create failing unit tests for retry/backoff behavior with deterministic mocked http.Client (C5: Resilience)

## Phase 3.6: Service Implementation
- [ ] T017 Implement `lib/services/effis_service.dart` abstract interface with constructor injection (spec:A1)
- [ ] T018 Implement `lib/services/effis_service_impl.dart` with injected http.Client (spec:A1, gate:C5)
  - Constructor injection of http.Client for testability
  - URL template construction for EFFIS WMS GetFeatureInfo with correct lat/lon order
  - Required WMS params: layer, info_format, query point validation
  - HTTP headers: User-Agent and Accept: application/json
  - 30-second timeout implementation
  - Exponential backoff retry logic with jitter (max 3 retries)
  - JSON parsing with schema validation
  - UTC timezone parsing for observedAt
  - Error categorization with reason codes and ApiError mapping

## Phase 3.7: Integration & Validation
- [X] T019 [P] Update `docs/DATA-SOURCES.md` with implemented EFFIS endpoint details (spec:A1)
  ✅ COMPLETE: Added comprehensive EFFIS WMS documentation including base URL, parameters, headers, retry policy
- [X] T020 [P] Add usage examples in service code comments for integration guidance
  ✅ COMPLETE: Added detailed usage example with error handling patterns in EffisServiceImpl
- [X] T021 Run `flutter analyze` and `flutter test` to ensure CI compliance (gate:C1)
  ✅ COMPLETE: dart format (4 files formatted), flutter analyze (No issues found!), flutter test (56/56 passed)
- [X] T022 Validate all constitutional gates: C1 (tests pass), C2 (safe logging), C5 (error handling)
  ✅ COMPLETE: All gates validated - C1: 100% test pass rate, C2: No secrets/PII in logs, C5: Comprehensive error handling

## Phase 3.8: Test Coverage Analysis & Documentation
**CRITICAL: Coverage analysis ensures production readiness and replicability**
- [X] T023 Generate test coverage report using `flutter test --coverage` command
- [X] T024 [P] Install lcov tools for coverage analysis (`brew install lcov` on macOS)
- [X] T025 [P] Generate detailed coverage summary using `lcov --summary coverage/lcov.info`
- [X] T026 [P] Create HTML coverage report using `genhtml coverage/lcov.info -o coverage/html`
- [X] T027 [P] Document coverage analysis in `docs/TEST_COVERAGE.md` with:
  - Overall coverage percentage and line counts
  - File-by-file coverage breakdown
  - Coverage thresholds and production readiness assessment
  - Instructions for generating and viewing coverage reports
  - Recommendations for improving coverage
- [X] T028 [P] Update README.md with coverage tooling section documenting:
  - Required tools (lcov/genhtml)
  - Coverage generation commands
  - How to access HTML reports
  - Link to detailed coverage documentation

---

## Dependencies
- **T001 FIRST**: Flutter project creation with validation - MANDATORY before any other tasks
- **T002-T004**: Complete setup and dependencies after T001
- Fixtures (T005-T008) before tests and implementation  
- Model tests (T009-T011) before model implementation (T012-T014)
- Model implementation (T012-T014) before service tests (T015-T016)
- Service tests (T015-T016) before service implementation (T017-T018)
- Implementation before integration and validation (T019-T022)

**CRITICAL SEQUENCE**: T001 (flutter create) → T002-T004 (dependencies) → All other phases

## Parallel Execution Examples
```bash
# Phase 3.2: Create all fixtures simultaneously
Task: "Create EFFIS success response fixture test/fixtures/effis/edinburgh_success.json"
Task: "Create EFFIS error fixtures: 404.json, 503.json, malformed.json, empty_features.json"
Task: "Create fixture-based contract test file test/contract/effis_responses_contract_test.dart with failing tests"

# Phase 3.3: Write all model tests simultaneously  
Task: "Create failing unit tests test/unit/models/risk_level_test.dart for FWI mapping boundaries"
Task: "Create failing unit tests test/unit/models/api_error_test.dart for error categorization with reason codes"
Task: "Create failing unit tests test/unit/models/effis_fwi_result_test.dart for validation and timezone handling"

# Phase 3.4: Implement all models simultaneously
Task: "Implement lib/models/risk_level.dart with fromFwi() mapping"  
Task: "Implement lib/models/api_error.dart with error types, categorization, and reason codes"
Task: "Implement lib/models/effis_fwi_result.dart with validation rules and UTC timezone parsing"
```

## Constitutional Compliance Checkpoints

### Gate C1 (Code Quality & Tests)
- **T004**: flutter analyze and dart format configured
- **T009-T012**: Unit tests for all models
- **T017-T018**: Contract and integration tests
- **T023**: CI compliance validation

### Gate C2 (Secrets & Logging)
- **T018**: Safe logging practices with no sensitive data
- **T022**: No hardcoded secrets (EFFIS requires no API keys)

### Gate C5 (Resilience & Test Coverage)  
- **T015-T016**: Error handling, timeout, and retry tests with mocked HTTP
- **T018**: Network timeout, retry logic, error categorization with reason codes
- **T022**: All failure modes tested and handled deterministically

## Acceptance Criteria

### T001-T004 (Setup)
**Project Created**: Complete Flutter project with `flutter create` command executed
**Platform Support**: iOS, Android, Web, macOS, Linux, Windows directories present
**Files Created**: `pubspec.yaml` with dependencies, `lib/main.dart`, `test/widget_test.dart`, platform configurations
**Validation Passed**: 
- `flutter doctor`: No critical issues
- `flutter analyze`: No issues found  
- `flutter test`: All tests passed
- `flutter run`: App launches successfully
- Dependencies resolve correctly with `flutter pub get`
- INTERNET permission configured for API calls

### T005-T008 (Fixtures)  
**Files Created**: `test/fixtures/effis/*.json`, `test/contract/effis_responses_contract_test.dart`
**Tests**: Contract test file exists and fails appropriately with fixture data

### T009-T014 (Models)
**Files Created**: `lib/models/*.dart`, `test/unit/models/*.dart`  
**Tests**: All model unit tests pass, FWI boundaries (4,5,12,21,38,50) validated, reason codes tested, UTC timezone handling verified

### T015-T018 (Service)
**Files Created**: `lib/services/effis_service*.dart`, `test/unit/services/*.dart`
**Tests**: Contract tests pass with mocked HTTP client, retry/backoff behavior tested deterministically
**API**: `EffisService.getFwi(lat, lon, {timeout, maxRetries})` with constructor-injected http.Client and Either<ApiError, EffisFwiResult>
**HTTP**: Correct WMS params, headers (User-Agent, Accept), lat/lon order validation

### T019-T022 (Integration)
**Files Updated**: `docs/DATA-SOURCES.md`
**Tests**: `flutter analyze` clean, `flutter test` 100% pass rate (no live HTTP in CI)
**Validation**: All constitutional gates verified

### T023-T028 (Coverage Analysis)
**Tools Required**: lcov/genhtml (install via `brew install lcov` on macOS)
**Files Created**: `docs/TEST_COVERAGE.md`, HTML coverage report at `coverage/html/index.html`
**Coverage Generated**: 
- `flutter test --coverage`: Generate lcov.info file
- `lcov --summary coverage/lcov.info`: Display coverage summary
- `genhtml coverage/lcov.info -o coverage/html`: Create browsable HTML report
**Documentation**: 
- Detailed coverage analysis with file-by-file breakdown
- Production readiness assessment (target: >80% coverage)
- Tooling instructions for replication in other projects
- README.md updated with coverage workflow and commands

## Notes
- **CRITICAL T001**: Must run `flutter create` command to generate complete project structure before any other tasks
- **Project Validation**: Always run `flutter doctor`, `flutter analyze`, `flutter test`, and `flutter run` to ensure project is functional
- Scope strictly limited to A1 EffisService - no caching, UI, fallback orchestration, or coordinate validation (moved to A4)
- Service accepts raw double lat, lon parameters for simplicity
- Constructor injection of http.Client enables deterministic testing without live HTTP
- All network errors return structured ApiError with reason codes, never throw exceptions  
- FWI mapping follows official thresholds per docs/DATA-SOURCES.md
- Test-driven development: tests must fail before implementation
- No live HTTP integration tests in CI - use mocked http.Client for deterministic results
- Manual live sanity checks can be done outside CI pipeline
- **Multi-platform**: Project supports iOS, Android, Web, macOS, Linux, Windows (generated by flutter create)