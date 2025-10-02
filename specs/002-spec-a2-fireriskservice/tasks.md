# Tasks: FireRiskService (Fallback Orchestrator)

**Input**: Design documents from `/specs/002-spec-a2-fireriskservice/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Flutter project**: `lib/`, `test/` at repository root
- Paths aligned with plan.md structure

---

## Scope & Constraints
- **Orchestrator only**: Implement fallback logic, do not implement cache internals (A5) or EFFIS client (A1)
- **Dependencies**: Use existing EffisService (A1), mock SEPA/Cache services for testing
- **Constitutional Gates**: C1 (quality), C2 (privacy), C5 (resilience)
- **Never-fail design**: Mock service provides guaranteed fallback

---

## Phase 1: Models & Service Interface (TDD Setup)
**Target**: Define public API and data structures

### T001 [P] Create FireRisk data model and service interface (spec:A2, gate:C2)
**File**: `lib/services/models/fire_risk.dart`
- Implement FireRisk value object with equatable
- Fields: level (String), fwi (double?), source (String), updatedAt (DateTime), freshness (String)
- Validation: level must be valid risk level, source in [effis, sepa, cache, mock]
- Factory constructors: FireRisk.fromEffis(), FireRisk.fromSepa(), etc.
- UTC timestamp handling for updatedAt field

**File**: `lib/services/fire_risk_service.dart`
- Abstract FireRiskService interface
- Method: getCurrent({required double lat, required double lon})
- Return type: Future<Either<ApiError, FireRisk>>
- Documentation: fallback chain behavior, never-fail guarantee

**File**: `test/unit/models/fire_risk_test.dart`
- Unit tests for FireRisk validation and factory constructors
- Test invalid level/source rejection
- Test UTC timestamp parsing and formatting

### T002 [P] Create failing contract tests for FireRiskService (spec:A2, gate:C1)
**File**: `test/unit/services/fire_risk_service_test.dart`
- Contract tests using mock dependencies (EffisService, SepaService, CacheService)
- Test input validation (lat/lon boundaries)
- Test Never-fail guarantee (always returns Right() or validation Left())
- Test source attribution correctness
- Test freshness indicators (live vs cached)
**Note**: Tests must FAIL initially - implement after T003

---

## Phase 2: Scotland Boundary & Decision Logic
**Target**: Geographic routing and orchestration logic

### T003 Implement geographic utilities and fallback orchestration (spec:A2, gate:C2, gate:C5)
**File**: `lib/services/utils/geo_utils.dart`
- Implement GeographicUtils.isInScotland(lat, lon)
- Scotland boundary: 54.6°N-60.9°N, 8.2°W-1.0°E (simplified bounding box)
- Privacy method: anonymizeCoordinates(lat, lon) -> rounds to 2 decimal places
- Geohash generation for cache keys (5-character precision)

**File**: `lib/services/fire_risk_service_impl.dart`
- Implement FireRiskService with constructor injection
- Dependencies: EffisService, SepaService?, CacheService?, MockService
- Fallback chain logic:
  1. EFFIS (always attempted first)
  2. SEPA (only if isInScotland() == true AND EFFIS failed)
  3. Cache (only if previous services failed AND cache available)
  4. Mock (guaranteed fallback, never fails)
- Input validation: lat [-90,90], lon [-180,180]
- Error handling: Only return Left() for validation errors
- Logging: Use anonymized coordinates, no PII (gate:C2)
- Telemetry: Record service attempts and fallback depth

**File**: `lib/services/mock_service.dart`
- Simple MockService implementation for guaranteed fallback
- Deterministic risk based on coordinate hash
- Always returns "moderate" risk with source="mock", freshness="live"
- Response time <100ms

---

## Phase 3: Integration Tests & Fallback Scenarios
**Target**: Validate end-to-end fallback behavior

### T004 [P] Create comprehensive integration tests (spec:A2, gate:C5)
**File**: `test/integration/fire_risk_service_integration_test.dart`
- **Scenario 1**: EFFIS success (non-Scotland) -> should skip SEPA
- **Scenario 2**: EFFIS fail -> SEPA success (Scotland) -> should use SEPA
- **Scenario 3**: EFFIS + SEPA fail -> Cache success -> should use cached data
- **Scenario 4**: All services fail -> Mock success -> should use mock (never-fail guarantee)
- **Boundary Tests**: Test Scotland edge cases (54.6°N, 60.9°N, 8.2°W, 1.0°E)
- **Validation Tests**: Invalid coordinates return Left(ApiError.invalidCoordinates)
- **Source Attribution**: Verify correct source/freshness in all scenarios
- **Privacy Compliance**: Verify no raw coordinates in logs (gate:C2)

**File**: `test/unit/utils/geo_utils_test.dart`
- Test isInScotland() boundary detection accuracy
- Test coordinate anonymization (rounds to 2dp)
- Test geohash generation consistency
- Edge cases: International boundaries, coordinate precision

**Test Doubles Setup**:
- MockEffisService: Controllable success/failure responses
- MockSepaService: Scotland-only mock implementation  
- MockCacheService: TTL simulation and hit/miss control
- Use existing ApiError from A1 for consistent error handling

---

## Phase 4: Documentation & CI Compliance
**Target**: Ensure production readiness

### T005 [P] Update documentation and ensure CI compliance (spec:A2, gate:C1)
**File**: `docs/CONTEXT.md` (if exists)
- Update with FireRiskService fallback decision tree
- Document Scotland boundary detection logic
- Add privacy compliance notes (coordinate anonymization)

**File**: `lib/services/fire_risk_service_impl.dart` (comments)
- Add comprehensive usage examples in service documentation
- Document fallback chain behavior and timing expectations
- Include error handling patterns and telemetry usage

**CI Validation**:
- Run `flutter analyze` (must show "No issues found")
- Run `flutter test` (all tests must pass)
- Run `dart format --set-exit-if-changed` (code must be formatted)
- Verify constitutional compliance: C1, C2, C5

**File**: Update `.github/copilot-instructions.md` (if exists)
- Add FireRiskService implementation guidance
- Document testing patterns for orchestration services
- Include privacy-compliant logging examples

---

## Dependencies
- **T001**: Models and interface definition (can run in parallel)
- **T002**: Contract tests (requires T001 interfaces)
- **T003**: Implementation (requires T001, makes T002 tests pass)
- **T004**: Integration tests (requires T003 implementation)
- **T005**: Documentation (can run in parallel with T004)

**CRITICAL**: Must use existing EffisService from A1 - do not reimplement

## Parallel Execution Examples
```bash
# Phase 1: Setup models and tests in parallel
Task: "Create FireRisk data model and service interface"
Task: "Create failing contract tests for FireRiskService"

# Phase 3: Write integration and unit tests in parallel  
Task: "Create comprehensive integration tests"
Task: "Create unit tests for geographic utilities"

# Phase 4: Documentation tasks in parallel
Task: "Update documentation and ensure CI compliance"
```

## Constitutional Compliance Checkpoints

### Gate C1 (Code Quality & Tests)
- **T002**: Contract tests with mock dependencies
- **T004**: Integration tests covering all fallback scenarios
- **T005**: CI compliance validation (analyze, test, format)

### Gate C2 (Privacy & Logging)
- **T001**: No PII in FireRisk data model
- **T003**: Coordinate anonymization in logging (2dp precision)
- **T004**: Verify no raw coordinates in test logs

### Gate C5 (Resilience & Coverage)
- **T003**: Never-fail design with guaranteed mock fallback
- **T004**: All error scenarios tested (service failures, timeouts)
- **T004**: Fallback chain resilience validation

## Acceptance Criteria

### T001 (Models & Interface)
**Files Created**: `lib/services/models/fire_risk.dart`, `lib/services/fire_risk_service.dart`, `test/unit/models/fire_risk_test.dart`
**API**: FireRiskService.getCurrent({lat, lon}) returns Future<Either<ApiError, FireRisk>>
**Models**: FireRisk with validation, factory constructors, UTC timestamps
**Tests**: Unit tests for data model validation and serialization

### T002 (Contract Tests)
**Files Created**: `test/unit/services/fire_risk_service_test.dart`
**Tests**: Contract tests with mocked dependencies (initially failing)
**Coverage**: Input validation, never-fail guarantee, source attribution
**Dependencies**: Mock EffisService, SepaService, CacheService

### T003 (Implementation)
**Files Created**: `lib/services/utils/geo_utils.dart`, `lib/services/fire_risk_service_impl.dart`, `lib/services/mock_service.dart`
**Logic**: Scotland boundary detection, fallback orchestration
**Privacy**: Coordinate anonymization, no PII logging
**Resilience**: Guaranteed mock fallback, proper error handling
**Integration**: Uses existing EffisService from A1

### T004 (Integration Tests)
**Files Created**: `test/integration/fire_risk_service_integration_test.dart`, `test/unit/utils/geo_utils_test.dart`
**Scenarios**: All fallback combinations (EFFIS/SEPA/Cache/Mock)
**Boundaries**: Scotland edge cases and coordinate validation
**Coverage**: Source attribution, freshness indicators, privacy compliance

### T005 (Documentation & CI)
**Files Updated**: `docs/CONTEXT.md`, service documentation, `.github/copilot-instructions.md`
**CI**: flutter analyze clean, flutter test 100% pass, dart format compliant
**Documentation**: Usage examples, fallback behavior, privacy compliance

## Notes
- **Scope Limited**: Orchestrator only - uses existing EffisService (A1), mocks SEPA/Cache
- **Never-Fail Design**: Mock service guarantees successful response in all scenarios
- **Privacy First**: All coordinate logging uses 2dp anonymization (gate:C2)
- **Constitutional**: Strict adherence to C1 (quality), C2 (privacy), C5 (resilience)
- **Testing**: TDD approach with contract tests failing before implementation
- **Dependencies**: Injectable services for testability and loose coupling