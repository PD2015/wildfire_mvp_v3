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

### [X] T001 [P] Create FireRisk data model and service interface (spec:A2, gate:C2)
**File**: `lib/services/models/fire_risk.dart`
- Implement FireRisk value object with equatable
- Fields: level: RiskLevel (reuse A1's enum), fwi: double?, source: DataSource, observedAt: DateTime (UTC), freshness: Freshness
- Enums: DataSource {effis, sepa, cache, mock}, Freshness {live, cached, mock}
- Validation: level ∈ RiskLevel, source ∈ DataSource, observedAt.isUtc == true
- Factory constructors: FireRisk.fromEffis(), FireRisk.fromSepa(), etc.
- UTC timestamp handling for observedAt field (consistent with A1 naming)

**File**: `lib/services/fire_risk_service.dart`
- Abstract FireRiskService interface with deadline parameter
- Method: getCurrent({required double lat, required double lon, Duration? deadline})
- Default deadline: 8 seconds total budget
- Return type: Future<Either<ApiError, FireRisk>>
- Documentation: fallback chain behavior, never-fail guarantee, timing budget

**File**: `lib/services/contracts/service_contracts.dart`
- Stable dependency interfaces for orchestrator:
```dart
abstract class EffisService {
  Future<Either<ApiError, EffisFwiResult>> getFwi({required double lat, required double lon});
}
abstract class SepaService {
  Future<Either<ApiError, FireRisk>> getCurrent({required double lat, required double lon});
}
abstract class CacheService {
  Future<Option<FireRisk>> get({required String key});
  Future<void> set({required String key, required FireRisk value, Duration ttl});
}
```

**File**: `test/unit/models/fire_risk_test.dart`
- Unit tests for FireRisk validation and factory constructors
- Test enum validation (RiskLevel, DataSource, Freshness)
- Test UTC timestamp parsing and observedAt consistency
- Test invalid coordinates: NaN, ±Infinity, out-of-range -> Left(ApiError.invalidCoordinates)

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

### [X] T003 Implement geographic utilities and fallback orchestration (spec:A2, gate:C2, gate:C5)
**File**: `lib/services/utils/geo_utils.dart`
- Implement GeographicUtils.isInScotland(lat, lon)
- Scotland boundary: 54.6°N-60.9°N, 9.0°W-1.0°E (includes St Kilda)
- Add unit tests for Orkney/Shetland and border towns (Gretna/Berwick)
- Privacy method: logRedact(lat, lon) -> rounds to 2 decimal places for logging
- Geohash generation for cache keys (5-character precision)

**File**: `lib/services/fire_risk_service_impl.dart`
- Implement FireRiskService with constructor injection
- Dependencies: EffisService, SepaService?, CacheService?, MockService, OrchestratorTelemetry
- Add deadline parameter (default 8s). Enforce per-leg timeouts:
  - EFFIS: 3s maximum
  - SEPA: 2s maximum  
  - Cache: 1s maximum
  - Mock: ≤100ms guaranteed
- Fallback chain logic with timing enforcement:
  1. EFFIS (always attempted first, 3s timeout)
  2. SEPA (only if isInScotland() == true AND EFFIS failed, 2s timeout)
  3. Cache (only if previous services failed AND cache available, 1s timeout)
  4. Mock (guaranteed fallback, never fails, <100ms)
- Input validation: lat [-90,90], lon [-180,180], reject NaN/±Infinity
- Error handling: Only return Left() for validation errors
- Logging: Use logRedact(lat, lon), assert no raw coordinates or place names (gate:C2)
- Telemetry: Emit OrchestratorTelemetry events (attempts, durations, fallbackDepth)

**File**: `lib/services/mock_service.dart`
- MockService with configurable strategy
- MockStrategy.fixed(RiskLevel.moderate) - default for production
- MockStrategy.deterministicFromGeohash(precision: 5) - for tests
- Deterministic and testable with fixed seed
- Response time ≤100ms guaranteed
- Returns source=DataSource.mock, freshness=Freshness.mock

**File**: `lib/services/telemetry/orchestrator_telemetry.dart`
- Define OrchestratorTelemetry interface for attempt tracking
- Record service attempt order, durations, fallback depth
- Enable test verification of exact fallback sequence

---

## Phase 3: Integration Tests & Fallback Scenarios
**Target**: Validate end-to-end fallback behavior

### T004 [X] Create comprehensive integration tests (spec:A2, gate:C5)
**File**: `test/integration/fire_risk_service_integration_test.dart`
- **Scenario 1**: EFFIS success (non-Scotland) -> should skip SEPA
- **Scenario 2**: EFFIS fail -> SEPA success (Scotland) -> should use SEPA
- **Scenario 3**: EFFIS + SEPA fail -> Cache success -> should use cached data
- **Scenario 4**: All services fail -> Mock success -> should use mock (never-fail guarantee)
- **Scenario 5**: EFFIS hangs >3s (timeout) -> SEPA success (Scotland) within deadline
- **Scenario 6**: All upstream fail/timeout but global deadline still met with Mock result
- **Boundary Tests**: Test Scotland edge cases (54.6°N, 60.9°N, 9.0°W, 1.0°E)
- **Validation Tests**: Invalid coordinates (NaN, ±Infinity, out-of-range) return Left(ApiError.invalidCoordinates)
- **Timing Tests**: Global deadline enforcement (8s max), per-leg timeout validation
- **Source Attribution**: Verify correct source/freshness in all scenarios
- **Privacy Compliance**: Assert logs never contain raw lat/lon or place names (gate:C2)
- **Telemetry Validation**: Inject spy and assert exact sequence (EFFIS → SEPA → Cache → Mock) and timings

**File**: `test/unit/utils/geo_utils_test.dart`
- Test isInScotland() boundary detection accuracy
- Test logRedact() coordinate anonymization (rounds to 2dp)
- Test geohash generation consistency
- Edge cases: Orkney/Shetland, border towns (Gretna/Berwick), St Kilda inclusion
- Assert no raw coordinates in any log outputs

**Test Doubles Setup**:
- MockEffisService: Controllable success/failure/timeout responses
- MockSepaService: Scotland-only mock with timing control  
- MockCacheService: TTL simulation, hit/miss control, timing simulation
- SpyTelemetryService: Records and verifies orchestrator behavior
- Use existing ApiError from A1 for consistent error handling

---

## Phase 4: Documentation & CI Compliance
**Target**: Ensure production readiness

### T005 [P] Update documentation and ensure CI compliance (spec:A2, gate:C1)
**File**: `docs/CONTEXT.md` (if exists)
- Update with FireRiskService fallback decision tree
- Document Scotland boundary detection logic (9.0°W-1.0°E, 54.6°N-60.9°N)
- Add privacy compliance notes (logRedact coordinate anonymization)
- Explicitly reference A1's EFFIS decision - link to EFFIS spec excerpt
- Explain why EFFIS is first in chain and what it returns

**File**: `lib/services/fire_risk_service_impl.dart` (comments)
- Add comprehensive usage examples in service documentation
- Document fallback chain behavior and timing expectations (8s budget)
- Include error handling patterns and telemetry usage
- Reference A1's EffisService integration points

**CI Validation**:
- Run `flutter analyze` (must show "No issues found")
- Run `flutter test` (all tests must pass)
- Run `dart format --set-exit-if-changed` (code must be formatted)
- Verify constitutional compliance with test assertions:
  - C1: Code quality gates enforced
  - C2: Log redaction assertions pass (no raw coordinates/place names)
  - C5: Global deadline tests and never-fail guarantee proven

**File**: Update `.github/copilot-instructions.md` (if exists)
- Add FireRiskService implementation guidance
- Document testing patterns for orchestration services
- Include privacy-compliant logging examples with logRedact usage
- Reference stable dependency contracts pattern

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
**Files Created**: `lib/services/models/fire_risk.dart`, `lib/services/fire_risk_service.dart`, `lib/services/contracts/service_contracts.dart`, `test/unit/models/fire_risk_test.dart`
**API**: FireRiskService.getCurrent({lat, lon, deadline?}) returns Future<Either<ApiError, FireRisk>>
**Models**: FireRisk with enum typing (RiskLevel, DataSource, Freshness), observedAt (UTC) consistency
**Contracts**: Stable dependency interfaces (EffisService, SepaService, CacheService)
**Tests**: Unit tests for enum validation, NaN/±Infinity rejection, UTC timestamp handling

### T002 (Contract Tests)
**Files Created**: `test/unit/services/fire_risk_service_test.dart`
**Tests**: Contract tests with mocked dependencies (initially failing)
**Coverage**: Input validation, never-fail guarantee, source attribution
**Dependencies**: Mock EffisService, SepaService, CacheService

### T003 (Implementation)
**Files Created**: `lib/services/utils/geo_utils.dart`, `lib/services/fire_risk_service_impl.dart`, `lib/services/mock_service.dart`, `lib/services/telemetry/orchestrator_telemetry.dart`
**Logic**: Scotland boundary detection (9.0°W-1.0°E, includes St Kilda), fallback orchestration with timing budget
**Timing**: Global deadline (8s), per-leg timeouts (EFFIS 3s, SEPA 2s, Cache 1s, Mock <100ms)
**Privacy**: logRedact() coordinate anonymization, no PII logging with test assertions
**Resilience**: Guaranteed mock fallback, proper error handling, deterministic MockStrategy
**Telemetry**: OrchestratorTelemetry tracking attempts, durations, fallback depth
**Integration**: Uses existing EffisService from A1 via stable contracts

### T004 (Integration Tests)
**Files Created**: `test/integration/fire_risk_service_integration_test.dart`, `test/unit/utils/geo_utils_test.dart`
**Scenarios**: All fallback combinations (EFFIS/SEPA/Cache/Mock) + timeout scenarios
**Timing**: Global deadline enforcement (8s), per-leg timeout validation, fast-failing chains
**Boundaries**: Scotland edge cases (Orkney/Shetland, St Kilda, border towns), coordinate validation
**Telemetry**: SpyTelemetryService verification of exact sequence and timings
**Coverage**: Source attribution, freshness indicators, privacy compliance with log assertions
**Validation**: NaN/±Infinity handling, never-fail guarantee under all conditions

### T005 (Documentation & CI)
**Files Updated**: `docs/CONTEXT.md`, service documentation, `.github/copilot-instructions.md`
**CI**: flutter analyze clean, flutter test 100% pass, dart format compliant
**Constitutional**: C1/C2/C5 gates proven by test assertions (not just docs)
**Documentation**: Usage examples, fallback behavior, A1 EFFIS integration reference
**Privacy**: logRedact examples, coordinate anonymization patterns
**Integration**: Explicit A1 EffisService decision rationale and return types

## Notes
- **Scope Limited**: Orchestrator only - uses existing EffisService (A1) via stable contracts, mocks SEPA/Cache
- **Never-Fail Design**: Mock service guarantees successful response <100ms in all scenarios
- **Timing Budget**: Global deadline (8s) with per-leg timeouts - EFFIS 3s, SEPA 2s, Cache 1s, Mock <100ms
- **Geography**: Scotland boundary updated to 9.0°W-1.0°E (includes St Kilda), tested with Orkney/Shetland/borders
- **Privacy First**: logRedact() for all coordinate logging, test assertions verify no raw coordinates/place names (gate:C2)
- **Constitutional**: C1/C2/C5 gates enforced by test assertions, not just documentation
- **Enum Typing**: RiskLevel (reuse A1), DataSource {effis,sepa,cache,mock}, Freshness {live,cached,mock}
- **Naming Consistency**: observedAt (UTC) matches A1 naming across all services
- **Mock Strategy**: Configurable - MockStrategy.fixed() for production, .deterministicFromGeohash() for tests
- **Telemetry**: OrchestratorTelemetry tracking with test verification of exact fallback sequence
- **Testing**: TDD approach with contract tests failing before implementation
- **Dependencies**: Injectable services via stable contracts for testability and loose coupling