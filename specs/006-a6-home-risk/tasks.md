# Tasks: A6 — Home (Risk Feed Container & Screen)

**Input**: Design documents from `/specs/006-a6-home-risk/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
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

### T001: HomeState Model and HomeController Implementation
**Purpose**: Create the foundational state management with ChangeNotifier pattern
**Files**: 
- `lib/models/home_state.dart` (HomeState sealed class hierarchy)
- `lib/controllers/home_controller.dart` (ChangeNotifier-based controller)

**Requirements**:
- HomeState sealed class with Loading/Success/Error states
- HomeController with ChangeNotifier extending pattern
- Service injection for LocationResolver and FireRiskService
- load(), retry(), setManualLocation() methods
- Proper error handling and state transitions
- Constitutional compliance: C5 (error states visible, no silent failures)

**Acceptance Criteria**:
- HomeState compiles with Equatable support
- HomeController manages state transitions correctly
- Service integration via constructor injection
- State changes trigger notifyListeners()
- Error states include retry capability

---

### T002: HomeScreen UI Implementation  
**Purpose**: Create main screen widget with RiskBanner integration and user controls
**Files**:
- `lib/screens/home_screen.dart` (Main screen widget)
- `lib/widgets/manual_location_dialog.dart` (Coordinate entry dialog)

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

### T003: Integration Tests with Service Fakes
**Purpose**: Implement 6 test scenarios covering all data sources and error flows
**Files**:
- `test/integration/home_flow_test.dart` (6 integration scenarios)
- `test/widget/screens/home_screen_test.dart` (Widget accessibility tests)

**Requirements**:
- **Scenario 1**: EFFIS success flow (live data)
- **Scenario 2**: SEPA success flow (Scotland location)
- **Scenario 3**: Cache fallback flow (services fail, cache available)
- **Scenario 4**: Mock fallback flow (all services fail, mock data)
- **Scenario 5**: Location denied → manual entry flow
- **Scenario 6**: Retry after error flow
- Accessibility tests: semantic labels, 44dp touch targets
- Service mocks for controlled testing environment

**Acceptance Criteria**:
- All 6 scenarios pass with proper state transitions
- Accessibility tests verify WCAG compliance
- Service mocks allow independent testing
- Error handling validated for each failure mode
- Performance tests verify <200ms load times

---

### T004: App Entry Point and Navigation Setup
**Purpose**: Configure main app entry with home screen as initial route
**Files**:
- `lib/main.dart` (App initialization and theme)
- `lib/app.dart` (MaterialApp configuration)

**Requirements**:
- MaterialApp with HomeScreen as initial route
- Theme configuration with official Scottish risk colors (C4 compliance)
- Service locator setup for production HomeController
- Proper dependency injection for A1-A5 services
- Error boundary for unhandled exceptions

**Acceptance Criteria**:
- App launches to HomeScreen successfully
- Theme uses approved color palette
- Services properly injected and available
- Navigation structure supports future screens
- Error handling prevents app crashes

---

### T005: Documentation and CI Validation
**Purpose**: Update documentation and run CI validation for constitutional compliance
**Files**:
- `docs/CONTEXT.md` (Update with A6 home screen details)
- Existing CI pipeline validation

**Requirements**:
- Update CONTEXT.md with A6 HomeScreen architecture
- Document state management patterns and service integration
- Run `flutter analyze` for code quality (C1)
- Run `flutter test` for test coverage validation
- Verify constitutional compliance (C1, C3, C4, C5)
- Performance validation (<200ms load, 60fps)

**Acceptance Criteria**:
- Documentation reflects current architecture
- All CI checks pass (analyze, format, test)
- Constitutional gates verified
- Performance benchmarks met
- Code coverage targets achieved

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

### C1: Code Quality & Tests
- `flutter analyze` passes with zero issues
- `flutter test` achieves >90% coverage
- Code formatted with `dart format`

### C3: Accessibility (UI features only)
- Interactive elements ≥44dp touch targets
- Semantic labels for screen readers
- Color contrast meets WCAG AA standards

### C4: Trust & Transparency
- Official Scottish wildfire risk colors only
- "Last Updated" timestamp visible
- Data source labeling (Live/Cached/Mock)
- Cached data badges when using stale data

### C5: Resilience & Test Coverage
- Network timeouts handled by service layer
- Error states visible with retry options
- Fallback data shown when available
- Integration tests cover error flows

## Success Criteria

**Feature Complete When**:
- [x] HomeController manages state with ChangeNotifier
- [x] HomeScreen renders with RiskBanner integration
- [x] All 6 test scenarios pass consistently
- [x] App launches to home screen successfully
- [x] Constitutional compliance verified (C1, C3, C4, C5)
- [x] Documentation updated with architecture details

**Performance Targets**:
- Home screen load: <200ms
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