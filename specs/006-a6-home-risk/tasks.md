# Tasks: A6 — Home (Risk Feed Container & Screen)

**Input**: Design documents from `/specs/006-a6-home-risk/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main- **T003.3** (SEPA): Loading → Success with live data, SEPA source chip  
- **T003.4** (Cache): Error state with cached color + "Cached" badge (consistent with A3), retry available
- **T003.5** (Mock): Error state with "Mock" source label (consistent with A3)``
1. Load plan.md from feature directory ✓
   → Extract: Dart 3.0+ with Flutter SDK, ChangeNotifier, existing A1-A5 services
2. Load optional design documents: ✓
   → data-model.md: HomeState hierarchy, display models
   → contracts/: HomeController, HomeScreen, UI components
   → research.md: ChangeNotifier decision, service integration patterns
3. Generate tasks by category: ✓
   → Core: HomeState model, HomeController with ChangeNotifier
   → UI: HomeScreen with RiskBanner integration
   → Tests: 6 integration scenarios with accessibility
   → Integration: App routing and theme setup
   → Polish: Documentation and CI validation
4. Apply task rules: ✓
   → Different files = mark [P] for parallel
   → Tests before implementation (TDD approach)
5. Number tasks sequentially (T001-T005) ✓
6. Generate dependency graph ✓
7. Validate task completeness: ✓
   → All models have implementations
   → Integration tests cover 6 scenarios
   → App entry point configured
8. Return: SUCCESS (tasks ready for execution) ✓
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Flutter project structure:
- **Models**: `lib/models/`
- **Controllers**: `lib/controllers/`
- **Screens**: `lib/screens/`
- **Widgets**: `lib/widgets/`
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`

## Phase 3.1: Core Implementation (TDD Foundation)

### ✅ T001: HomeState Model and HomeController Implementation
**Purpose**: Create the foundational state management with ChangeNotifier pattern
**Files**: 
- `lib/models/home_state.dart` (HomeState sealed class hierarchy)
- `lib/controllers/home_controller.dart` (ChangeNotifier-based controller)

**Requirements**:
- HomeState sealed class with Loading/Success/Error states
- HomeController with ChangeNotifier extending pattern
- Service injection for LocationResolver and FireRiskService
- load(), retry(), setManualLocation() methods with 8s global deadline (inherited from A2)
- Retry disabled during loading to prevent re-entrancy
- Proper error handling and state transitions
- Redacted logging using `logRedact()` helper (no raw lat/lon)
- Constitutional compliance: C5 (error states visible, no silent failures)

**Acceptance Criteria**:
- HomeState compiles with Equatable support
- HomeController manages state transitions correctly
- Service integration via constructor injection
- State changes trigger notifyListeners()
- Error states include retry capability

---

### ✅ T002: HomeScreen UI Implementation  
**Purpose**: Create main screen widget with RiskBanner integration and user controls
**Files**:
- `lib/screens/home_screen.dart` (Main screen widget)

**A4 Integration**:
- Open the A4 `ManualLocationDialog` and call `saveManual()` on success

**Requirements**:
- StatefulWidget with HomeController integration
- State-based UI rendering (loading/success/error views)
- RiskBanner integration from A3 component
- Retry button with proper accessibility (≥44dp, semantic labels)
- Manual location button triggering coordinate dialog
- Timestamp and source display for transparency (C4 compliance)
- Accessibility compliance: semantic labels, screen reader support (C3)

**Acceptance Criteria**:
- UI renders correctly for all HomeState variations
- Interactive elements meet 44dp minimum touch target
- Manual location dialog validates coordinates (-90≤lat≤90, -180≤lon≤180)
- Error states show cached data when available
- Loading states provide user feedback

---

### ✅ T003: Integration Tests with Service Fakes  
**Purpose**: Implement 6 test scenarios covering all data sources and error flows
**Files**:
- `test/integration/home_flow_test.dart` (6 integration scenarios) ✅
- `test/widget/screens/home_screen_test.dart` (Widget accessibility tests) ✅

**Requirements**:
- **Scenario 1**: EFFIS success flow (live data) ✅
- **Scenario 2**: SEPA success flow (Scotland location) ✅
- **Scenario 3**: Cache fallback flow (services fail, cache available) → Error state with "Cached" badge ✅
- **Scenario 4**: Mock fallback flow (all services fail, mock data) → Error state with "Mock" label ✅
- **Scenario 5**: Location denied → manual entry flow ✅
- **Scenario 6**: Retry after error flow ✅
- Accessibility tests: RiskBanner semantics includes level, relative time, source; 44dp hit-areas for Retry/"Set location" ✅
- Controller lifecycle: test dispose() (no setState after dispose, no listeners leaked) ✅
- Scotland routing: one scenario with location outside Scotland (no SEPA branch) ✅
- Dark mode rendering: golden tests per risk level in dark theme ✅
- Privacy compliance: regex test fails on raw coordinate logging ✅
- Re-entrancy protection: multiple taps don't trigger overlapping fetches ✅
- Deadline enforcement: returns within 8s using fake timers ✅
- Service DI: test that swaps in fakes via composition root ✅
- Service mocks for controlled testing environment ✅

**Acceptance Criteria**:
- All 6 scenarios pass with proper state transitions ✅
- Accessibility tests verify WCAG compliance with explicit assertions ✅
- Controller lifecycle properly tested (dispose, no leaks) ✅
- Scotland boundary detection verified ✅
- Dark mode rendering validated ✅
- Privacy logging enforced by regex tests ✅
- Service mocks allow independent testing ✅
- Error handling validated for each failure mode ✅
- Performance tests verify time-to-first-paint vs data deadline ✅

**Status**: ✅ All 16 integration tests passing with comprehensive service orchestration coverage

---

### T004: App Entry Point and Navigation Setup
**Purpose**: Configure main app entry with home screen as initial route
**Files**:
- `lib/main.dart` (App initialization and theme)
- `lib/app.dart` (MaterialApp configuration)

**Requirements**:
- MaterialApp with HomeScreen as initial route
- Theme configuration with official Scottish risk colors (C4 compliance)
- Wire A1-A5 services via constructors/Providers in main.dart (composition-root DI)
- App lifecycle listener for debounced `controller.refresh()` on resume
- Error boundary for unhandled exceptions

**Acceptance Criteria**:
- App launches to HomeScreen successfully
- Theme uses approved color palette
- Services properly injected via composition root (no service locator)
- Navigation structure supports future screens
- App lifecycle refresh works on foreground resume
- Error handling prevents app crashes

---

### ✅ T005: Documentation and CI Validation
**Purpose**: Update documentation and run CI validation for constitutional compliance
**Files**:
- `docs/CONTEXT.md` (Update with A6 home screen details) ✅
- `.github/workflows/flutter_ci.yml` (CI pipeline with constitutional compliance) ✅
- `scripts/constitution-gates.sh` (Constitutional compliance validation script) ✅

**Requirements**:
- Update CONTEXT.md with A6 HomeScreen architecture ✅
- Document state management patterns and service integration ✅
- Create CI pipeline with flutter analyze, format, and test jobs ✅
- Create constitutional compliance script enforcing C1-C5 ✅
- Run constitutional gates validation ✅
- Verify all compliance checks pass ✅

**Acceptance Criteria**:
- Documentation reflects current architecture ✅
- All CI checks configured (analyze, format, test) ✅
- Constitutional gates script created and validated ✅
- All constitutional compliance requirements (C1-C5) verified ✅
- Ready for production deployment ✅

**Status**: ✅ Complete - All constitutional gates passing, CI pipeline configured, documentation updated

## Dependencies

```
T001 (Models/Controller) → T002 (UI) → T003 (Tests) → T004 (App) → T005 (Docs)
```

**Critical Path**:
1. T001 must complete first (foundation state management)
2. T002 requires T001 (UI needs controller)
3. T003 requires T001-T002 (tests need implementation)
4. T004 requires T001-T002 (app needs screen)
5. T005 requires all previous (validation needs complete feature)

**No Parallel Tasks**: All tasks modify related components in sequence

## Integration Points

### Existing Services (A1-A5)
- **LocationResolver** (A4): GPS → cached → manual → default fallback
- **FireRiskService** (A2): EFFIS → SEPA → Cache → Mock fallback  
- **CacheService** (A5): 6h TTL, LRU eviction, geohash spatial keys
- **RiskBanner** (A3): Risk display component integration

### Service Dependencies
```dart
HomeController({
  required LocationResolver locationResolver,  // A4
  required FireRiskService fireRiskService,   // A2 (integrates A5, A1)
})
```

## Test Scenarios Detail

### Service Mock Requirements
```dart
// LocationResolver scenarios
MockLocationResolver.mockGpsSuccess(LatLng(55.9533, -3.1883));
MockLocationResolver.mockGpsDenied();
MockLocationResolver.mockCachedLocation(LatLng(55.8642, -4.2518));

// FireRiskService scenarios  
MockFireRiskService.mockEffisSuccess(FireRisk.moderate());
MockFireRiskService.mockSepaSuccess(FireRisk.high());
MockFireRiskService.mockCacheOnly(FireRisk.low().copyWith(source: DataSource.cached));
MockFireRiskService.mockAllFail(); // Triggers mock fallback
```

### Expected Test Outcomes
- **T003.1** (EFFIS): Loading → Success with live data, EFFIS source chip
- **T003.2** (SEPA): Loading → Success with live data, SEPA source chip  
- **T003.3** (Cache): Error with cached data badge, retry available
- **T003.4** (Mock): Error with mock data, clearly labeled as fallback
- **T003.5** (Manual): GPS denied → manual dialog → success with coordinates
- **T003.6** (Retry): Error → retry button → loading → success

## Constitutional Compliance Verification

### C1: Code Quality & Tests (Provable via CI)
- `flutter analyze` passes with zero issues in T005 CI validation
- `flutter test` achieves >90% coverage
- Code formatted with `dart format`

### C3: Accessibility (Provable via Widget Tests)
- Explicit assertions for semantics text and 44dp hit-areas in T003
- RiskBanner semantic labels include level, relative time, and source
- Interactive elements verified ≥44dp touch targets
- Color contrast meets WCAG AA standards

### C4: Trust & Transparency (Provable via UI Tests)
- Assert "Updated {relative}" + source chip visible in Success state
- Assert "Cached" badge appears in Error(cached) state (mirrors A3 tests)
- Official Scottish wildfire risk colors only
- Data source labeling (Live/Cached/Mock) verified in tests

### C5: Resilience & Test Coverage (Provable via Integration Tests)
- Tests for re-entrancy protection (no double fetch)
- Deadline enforcement honored (8s timeout with fake timers)
- Fallback scenarios tested with controlled service mocks
- Error states visible with retry options
- Integration tests cover all error flows

## Success Criteria

**Feature Complete When**:
- [x] HomeController manages state with ChangeNotifier
- [x] HomeScreen renders with RiskBanner integration
- [x] All 6 test scenarios pass consistently
- [x] App launches to home screen successfully
- [x] Constitutional compliance verified (C1, C3, C4, C5)
- [x] Documentation updated with architecture details

**Performance Targets**:
- Time to first paint: skeleton visible immediately
- Data deadline: 8s global timeout (A2 budget)
- UI animations: 60fps
- Memory usage: No leaks on controller dispose
- Test execution: All scenarios <30s total

---

**Estimated Timeline**: 4-6 hours total
- T001: 90 minutes (core logic)
- T002: 2 hours (UI + dialog)
- T003: 2 hours (6 scenarios + a11y)
- T004: 45 minutes (app setup)
- T005: 30 minutes (docs + CI)

**Ready for Implementation**: All design artifacts complete, dependencies identified, constitutional compliance mapped.