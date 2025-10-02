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
- [ ] T001 Create Flutter project structure per implementation plan
- [ ] T002 Add dependencies to pubspec.yaml: http ^1.1.0, dartz ^0.10.1, equatable ^2.0.5
- [ ] T003 [P] Add dev dependencies: mockito ^5.4.2, build_runner ^2.4.7 (C1: Code Quality)
- [ ] T004 [P] Configure flutter analyze and dart format in existing CI (C1: Code Quality)

## Phase 3.2: Test Fixtures & Golden Tests (TDD Setup)
**CRITICAL: Create test fixtures BEFORE implementation to enable TDD**
- [ ] T005 [P] Create test fixtures directory `test/fixtures/effis/`
- [ ] T006 [P] Create EFFIS success response fixture `test/fixtures/effis/edinburgh_success.json`
- [ ] T007 [P] Create EFFIS error fixtures: `404.json`, `503.json`, `malformed.json`, `empty_features.json`
- [ ] T008 [P] Create golden test file `test/golden/effis_responses_test.dart` with failing tests

## Phase 3.3: Models & Value Objects (TDD)
**CRITICAL: Write failing tests BEFORE implementing models**
- [ ] T009 [P] Create failing unit tests `test/unit/models/risk_level_test.dart` for FWI mapping boundaries
- [ ] T010 [P] Create failing unit tests `test/unit/models/api_error_test.dart` for error categorization  
- [ ] T011 [P] Create failing unit tests `test/unit/models/effis_fwi_result_test.dart` for validation
- [ ] T012 [P] Create failing unit tests `test/unit/models/coordinate_test.dart` for bounds checking

## Phase 3.4: Model Implementation (After Tests Fail)
- [ ] T013 [P] Implement `lib/models/risk_level.dart` with fromFwi() mapping (spec:A1)
- [ ] T014 [P] Implement `lib/models/api_error.dart` with error types and categorization (spec:A1)
- [ ] T015 [P] Implement `lib/models/effis_fwi_result.dart` with validation rules (spec:A1)
- [ ] T016 [P] Implement `lib/models/coordinate.dart` with bounds validation (spec:A1)

## Phase 3.5: Service Interface & Tests (TDD)
**CRITICAL: Service tests must fail before implementation**
- [ ] T017 Create failing contract tests `test/unit/services/effis_service_test.dart` using fixtures (C5: Resilience)
- [ ] T018 Create failing integration tests `test/integration/effis_service_integration_test.dart` for HTTP scenarios (C5: Resilience)

## Phase 3.6: Service Implementation
- [ ] T019 Implement `lib/services/effis_service.dart` abstract interface (spec:A1)
- [ ] T020 Implement `lib/services/effis_service_impl.dart` with HTTP client (spec:A1, gate:C5)
  - URL template construction for EFFIS WMS GetFeatureInfo
  - 30-second timeout implementation 
  - Exponential backoff retry logic with jitter (max 3 retries)
  - JSON parsing with schema validation
  - Coordinate precision limiting for logs (gate:C2)
  - Error categorization and ApiError mapping

## Phase 3.7: Integration & Validation
- [ ] T021 [P] Update `docs/data_sources.md` with implemented EFFIS endpoint details (spec:A1)
- [ ] T022 [P] Add usage examples in service code comments for integration guidance
- [ ] T023 Run `flutter analyze` and `flutter test` to ensure CI compliance (gate:C1)
- [ ] T024 Validate all constitutional gates: C1 (tests pass), C2 (safe logging), C5 (error handling)

---

## Dependencies
- Setup (T001-T004) before everything
- Fixtures (T005-T008) before tests and implementation  
- Model tests (T009-T012) before model implementation (T013-T016)
- Model implementation (T013-T016) before service tests (T017-T018)
- Service tests (T017-T018) before service implementation (T019-T020)
- Implementation before integration and validation (T021-T024)

## Parallel Execution Examples
```bash
# Phase 3.2: Create all fixtures simultaneously
Task: "Create EFFIS success response fixture test/fixtures/effis/edinburgh_success.json"
Task: "Create EFFIS error fixtures: 404.json, 503.json, malformed.json, empty_features.json"
Task: "Create golden test file test/golden/effis_responses_test.dart with failing tests"

# Phase 3.3: Write all model tests simultaneously  
Task: "Create failing unit tests test/unit/models/risk_level_test.dart for FWI mapping boundaries"
Task: "Create failing unit tests test/unit/models/api_error_test.dart for error categorization"
Task: "Create failing unit tests test/unit/models/effis_fwi_result_test.dart for validation"
Task: "Create failing unit tests test/unit/models/coordinate_test.dart for bounds checking"

# Phase 3.4: Implement all models simultaneously
Task: "Implement lib/models/risk_level.dart with fromFwi() mapping"  
Task: "Implement lib/models/api_error.dart with error types and categorization"
Task: "Implement lib/models/effis_fwi_result.dart with validation rules"
Task: "Implement lib/models/coordinate.dart with bounds validation"
```

## Constitutional Compliance Checkpoints

### Gate C1 (Code Quality & Tests)
- **T004**: flutter analyze and dart format configured
- **T009-T012**: Unit tests for all models
- **T017-T018**: Contract and integration tests
- **T023**: CI compliance validation

### Gate C2 (Secrets & Logging)
- **T020**: Coordinate precision limited to 3dp in logs
- **T024**: No hardcoded secrets (EFFIS requires no API keys)

### Gate C5 (Resilience & Test Coverage)  
- **T017-T018**: Error handling and timeout tests
- **T020**: Network timeout, retry logic, error categorization
- **T024**: All failure modes tested and handled

## Acceptance Criteria

### T001-T004 (Setup)
**Files Created**: `pubspec.yaml` updated, CI configuration
**Tests**: Dependencies resolve, linting passes

### T005-T008 (Fixtures)  
**Files Created**: `test/fixtures/effis/*.json`, `test/golden/effis_responses_test.dart`
**Tests**: Golden test file exists and fails appropriately

### T009-T016 (Models)
**Files Created**: `lib/models/*.dart`, `test/unit/models/*.dart`  
**Tests**: All model unit tests pass, FWI boundaries (4,5,12,21,38,50) validated

### T017-T020 (Service)
**Files Created**: `lib/services/effis_service*.dart`, `test/*/services/*.dart`
**Tests**: Contract tests pass, integration tests with real HTTP scenarios pass
**API**: `EffisService.getFwi({lat, lon, timeout, maxRetries})` working with Either<ApiError, EffisFwiResult>

### T021-T024 (Integration)
**Files Updated**: `docs/data_sources.md`
**Tests**: `flutter analyze` clean, `flutter test` 100% pass rate
**Validation**: All constitutional gates verified

## Notes
- Scope strictly limited to A1 EffisService - no caching, UI, or fallback orchestration
- Uses `lib/theme/risk_palette.dart` color constants if any color references needed (though service layer should avoid UI concerns)
- All network errors return structured ApiError, never throw exceptions
- FWI mapping follows official thresholds per docs/data_sources.md
- Test-driven development: tests must fail before implementation