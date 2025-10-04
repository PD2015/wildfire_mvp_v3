
# Implementation Plan: CacheService (6h TTL)

**Branch**: `005-a5-cacheservice-6h` | **Date**: 2025-10-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-a5-cacheservice-6h/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → CacheService (6h TTL) specification loaded successfully
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Mobile app project type detected from Flutter structure
   → User provided explicit implementation details in request
3. Fill the Constitution Check section based on the constitution document.
4. Evaluate Constitution Check section below
   → All constitutional gates applicable and addressed
   → Update Progress Tracking: Initial Constitution Check ✅
5. Execute Phase 0 → research.md
   → Technical decisions and approaches documented
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, .github/copilot-instructions.md
   → Design artifacts generated with concrete interfaces
7. Re-evaluate Constitution Check section
   → All gates maintained in design phase
   → Update Progress Tracking: Post-Design Constitution Check ✅
8. Plan Phase 2 → Task generation approach defined
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 8. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Implement a key-value cache service for FireRisk objects with 6-hour TTL, geohash-based spatial keying, and LRU eviction policy. Provides offline resilience by caching successful API responses with corruption-safe JSON serialization and graceful degradation. Integrates as tier 3 in FireRiskService fallback chain with explicit freshness marking.

## Technical Context
**Language/Version**: Dart 3.0+ with Flutter SDK  
**Primary Dependencies**: shared_preferences (persistence), dartz (Either types), equatable (value objects), crypto (geohash), existing FireRisk models  
**Storage**: SharedPreferences (native platform key-value store)  
**Testing**: flutter_test, mockito (mocking SharedPreferences)  
**Target Platform**: iOS 15+, Android API 21+, macOS, Windows (cross-platform)  
**Project Type**: mobile - Flutter application with service layer architecture  
**Performance Goals**: <200ms cache read operations, <100ms write operations, non-blocking UI thread  
**Constraints**: 6h TTL, max 100 entries, corruption-safe, geohash precision 5 (~4.9km resolution)  
**Scale/Scope**: Single-user cache, ~100 geographic locations, JSON serialization format

**User Implementation Requirements**:
- Exact Dart interfaces: CacheService<T>, FireRiskCache implementation
- JSON serialization with versioning field and corruption handling
- TTL enforcement on read; expired entries treated as cache miss
- LRU eviction strategy for size management (max 100 entries)
- Geohash(lat,lon, precision=5) as cache keys
- Results must mark freshness=cached on successful reads
- Out-of-scope: UI badges (A3), fallback orchestration (A2)

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
- [x] Testing strategy covers unit tests for cache operations, TTL expiry, corruption handling
- [x] CI enforcement through existing pipeline (.github/workflows/flutter.yml)

### C2. Secrets & Logging
- [x] No secrets involved in cache implementation
- [x] Logging design uses existing LocationUtils.logRedact for coordinate precision limiting
- [x] Cache keys (geohashes) inherently privacy-preserving at precision 5

### C3. Accessibility (UI features only)
- [x] N/A - CacheService is a headless service layer component
- [x] No UI components in this feature

### C4. Trust & Transparency  
- [x] Cache service preserves original source attribution in cached FireRisk objects
- [x] Freshness=cached flag clearly indicates stale data to consumers
- [x] No color handling in cache service (preserved from original data)
- [x] Cache doesn't modify timestamp or source labeling

### C5. Resilience & Test Coverage
- [x] Corruption handling: ignore malformed entries, log errors, continue operation
- [x] Storage failure handling: cache misses don't prevent fresh data retrieval
- [x] Clear error states: cache operations return Option/Either types
- [x] Integration tests planned for cache failure scenarios and TTL edge cases

### Development Principles Alignment
- [x] "Fail visible, not silent" - cache corruption logged, operation continues gracefully
- [x] "Fallbacks, not blanks" - cache miss returns None, allows fallback to fresh data
- [x] "Keep logs clean" - uses existing LocationUtils.logRedact for coordinates
- [x] "Single source of truth" - cache preserves original FireRisk data integrity
- [x] "Mock-first dev" - CacheService<T> generic interface supports test injection

## Project Structure

### Documentation (this feature)
```
specs/005-a5-cacheservice-6h/
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
├── models/
│   ├── fire_risk.dart           # Existing FireRisk model (from A2)
│   └── cache_models.dart        # CacheEntry, CacheMetadata
├── services/
│   ├── cache_service.dart       # Generic CacheService<T> interface
│   ├── fire_risk_cache.dart     # FireRiskCache implementation
│   └── geohash_utils.dart       # Geohash generation utilities
└── utils/
    └── location_utils.dart      # Existing privacy-compliant logging (from A4)

test/
├── contract/
│   └── cache_service_contract_test.dart    # Interface compliance tests
├── integration/
│   └── fire_risk_cache_integration_test.dart  # End-to-end cache scenarios
└── unit/
    ├── cache_service_test.dart
    ├── fire_risk_cache_test.dart
    └── geohash_utils_test.dart
```

**Structure Decision**: Flutter mobile project structure with service layer architecture. CacheService follows existing patterns from A4 LocationResolver and A2 FireRiskService. Uses lib/ for source and test/ for testing with contract/integration/unit subdivisions matching established conventions.

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
1. **Foundation Tasks**: GeohashUtils implementation with contract tests (precision 5 accuracy)
2. **Model Tasks**: CacheEntry<T>, CacheMetadata, error types with JSON serialization
3. **Interface Tasks**: CacheService<T> abstract interface with contract tests  
4. **Implementation Tasks**: FireRiskCacheImpl with SharedPreferences backend
5. **Feature Tasks**: TTL enforcement, LRU eviction, cache integration with FireRiskService
6. **Validation Tasks**: Integration tests, performance tests, privacy compliance verification

**Critical Task Dependencies**:
- GeohashUtils → CacheEntry → CacheService<T> → FireRiskCacheImpl → FireRiskService integration
- Contract tests can be created in parallel with implementation [P]
- Unit tests must exist before integration tests
- Performance tests run after implementation is complete

**TDD Task Ordering Principles**:
1. Contract tests first (define expected behavior)
2. Failing unit tests (red phase)  
3. Minimal implementation (green phase)
4. Refactoring and optimization (refactor phase)
5. Integration tests with real SharedPreferences
6. Performance validation and constitutional compliance

**Parallel Execution Opportunities [P]**:
- GeohashUtils tests + CacheEntry tests (different files)
- CacheMetadata model + CacheError model (independent entities)
- GeohashUtils implementation + CacheConstants file (no dependencies)
- Unit test files for different classes (test isolation)

**Task Size Guidelines**:
- Each task: 30-90 minutes implementation time
- Complex integration tasks split into setup + validation subtasks
- Performance and constitutional compliance as separate validation tasks

**Estimated Task Breakdown**:
```
Phase 1: Foundation (8-10 tasks)
- GeohashUtils contract tests, implementation, validation
- CacheEntry<T> model with JSON serialization
- Error type definitions and test coverage

Phase 2: Interface & Implementation (10-12 tasks)  
- CacheService<T> interface and contract tests
- FireRiskCacheImpl basic functionality
- SharedPreferences integration and persistence tests

Phase 3: Advanced Features (8-10 tasks)
- TTL enforcement and expiration logic
- LRU eviction policy and access tracking
- Cache size management and cleanup processes

Phase 4: Integration & Validation (6-8 tasks)
- FireRiskService cache integration (optional dependency)
- Privacy compliance verification (coordinate redaction)
- Performance testing and optimization
- Full integration test suite
```

**Output Format**: Numbered tasks in tasks.md with [P] parallel markers, dependency chains, and time estimates

**Constitutional Compliance Integration**:
- Each implementation task includes constitutional check requirement
- Privacy compliance (C2) validated in coordinate handling tasks
- Resilience (C5) verified in error handling and fallback tasks
- Code quality (C1) enforced through comprehensive test coverage requirements

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
- [x] Phase 0: Research complete (/plan command) - Created research.md with technology decisions
- [x] Phase 1: Design complete (/plan command) - Created data-model.md, contracts/, quickstart.md
- [x] Phase 2: Task planning complete (/plan command - describe approach only) - Detailed task generation strategy with TDD approach
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
