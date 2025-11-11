# Tasks: RiskBanner Visual Refresh

**Input**: Design documents from `/specs/016-016-a14-riskbanner/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Extract: Flutter/Dart tech stack, Material Design, widget contracts
2. Load design documents:
   → data-model.md: RiskBannerConfig entity → model tasks
   → contracts/: Widget interface and test contracts → test tasks
   → research.md: Material Card approach → styling tasks
3. Generate tasks by category:
   → Setup: Visual tokens and Material Card foundation
   → Tests: Golden tests and widget tests (TDD approach)
   → Core: Widget enhancements, layout changes
   → Integration: HomeScreen coordinate passing
   → Polish: Documentation updates
4. Apply task rules:
   → Different files = mark [P] for parallel (golden tests, documentation)
   → Same file = sequential (lib/widgets/risk_banner.dart changes)
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All visual states (success/loading/error) enhanced?
   → All golden tests cover risk levels?
   → Widget contracts implemented?
   → HomeScreen integration complete?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Flutter app structure:
- **Widgets**: `lib/widgets/` 
- **Screens**: `lib/screens/`
- **Models**: `lib/models/` (if config class needs separate file)
- **Tests**: `test/widget/`, `test/widget/golden/`, `test/goldens/`
- **Documentation**: `specs/`, `docs/`

## Phase 3.1: Setup & Foundation

- [X] **T001** [P] Add visual tokens in RiskBanner: Add local constants kBannerRadius=16.0, kBannerPadding=EdgeInsets.all(16), kBannerElevation=2.0 in `lib/widgets/risk_banner.dart`; refactor success/loading/error states to use Material Card with these tokens

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [X] **T002** [P] Golden test (VeryLow light): Create `test/widget/golden/risk_banner_very_low_light_test.dart` with VeryLow risk level, light theme, fixed timestamp, source=EFFIS for reproducibility

- [X] **T003** [P] Golden test (Low light): Create `test/widget/golden/risk_banner_low_light_test.dart` with Low risk level, light theme, fixed timestamp, source=EFFIS for reproducibility

- [X] **T004** [P] Golden test (Moderate light): Create `test/widget/golden/risk_banner_moderate_light_test.dart` with Moderate risk level, light theme, fixed timestamp, source=EFFIS for reproducibility

- [X] **T005** [P] Golden test (High light): Create `test/widget/golden/risk_banner_high_light_test.dart` with High risk level, light theme, fixed timestamp, source=EFFIS for reproducibility

- [X] **T006** [P] Golden test (VeryHigh light): Create `test/widget/golden/risk_banner_very_high_light_test.dart` with VeryHigh risk level, light theme, fixed timestamp, source=EFFIS for reproducibility

- [X] **T007** [P] Golden test (Extreme light): Create `test/widget/golden/risk_banner_extreme_light_test.dart` with Extreme risk level, light theme, fixed timestamp, source=EFFIS for reproducibility

- [X] **T008** [P] Golden test (Moderate dark): Create `test/widget/golden/risk_banner_moderate_dark_test.dart` with Moderate risk level, dark theme, fixed timestamp, source=EFFIS for reproducibility

- [X] **T010**: Update success layout with location row
  - [X] Wrap location Text in `Expanded` widget to prevent overflow
  - [X] Add `overflow: TextOverflow.ellipsis` and `maxLines: 1` for long location names
  - [X] Apply same fix to error state with cached data (line ~355)
  - [X] Regenerate golden test images with `--update-goldens`
  - **Result**: Overflow fixed ✅, all 7 golden tests passing ✅

## Phase 3.3: Core Implementation (ONLY after tests are failing)

- [ ] **T010** Update success layout: In `lib/widgets/risk_banner.dart`, keep existing title "Wildfire Risk: {LEVEL}"; add location row with Icon(Icons.location_on) + locationLabel text when provided; show "Updated {relative time}" and "Data Source: {EFFIS|SEPA|Cache|Mock}" as plain text inside banner; preserve CachedBadge when freshness == cached; remove any chip widget usage

- [X] **T011** [P] Add RiskBannerConfig: Create RiskBannerConfig class with bool showWeatherPanel=false default; in `lib/widgets/risk_banner.dart`, when config.showWeatherPanel == true, render nested rounded container with three columns (Temperature, Humidity, Wind Speed) and placeholder values; when false/null, no weather panel

- [X] **T012** Wire coordinates in HomeScreen: In `lib/screens/home_screen.dart` success state branch, build coordsLabel using '(${LocationUtils.logRedact(location.latitude, location.longitude)})' format and pass to RiskBanner(locationLabel: coordsLabel, ...) (C2: Logging compliance with 2-decimal precision)

- [X] **T013** Remove external elements from HomeScreen: In `lib/screens/home_screen.dart`, remove external timestamp row and source chip usage to avoid duplication with internal banner display; preserve other external info (e.g., cached indicator card) as needed

## Phase 3.4: Integration & Polish

- [X] **T014** [P] Update RiskBanner quickstart docs: Add note to `specs/003-a3-riskbanner-home/quickstart.md` about new golden tests and internal banner timestamp/source display changes

- [X] **T015** [P] Update testing documentation: Add documentation about new golden test coverage and visual regression prevention in relevant testing docs

## Dependencies
- Setup (T001) before everything else
- Golden tests (T002-T008) must be created and failing before implementation (T010-T013)
- T009 (widget test updates) must complete before T010 (success layout changes)
- T010 (success layout) before T012 (HomeScreen coordinates integration)
- T011 (RiskBannerConfig) can run in parallel with T010 as it's additive
- T013 (remove external elements) after T010-T012 to avoid breaking changes
- Documentation updates (T014-T015) can run in parallel after core implementation

## Parallel Execution Examples

### Phase 3.2 - All Golden Tests (Parallel)
```bash
# All golden tests can run in parallel (different files)
flutter test test/widget/golden/risk_banner_very_low_light_test.dart &
flutter test test/widget/golden/risk_banner_low_light_test.dart &
flutter test test/widget/golden/risk_banner_moderate_light_test.dart &
flutter test test/widget/golden/risk_banner_high_light_test.dart &
flutter test test/widget/golden/risk_banner_very_high_light_test.dart &
flutter test test/widget/golden/risk_banner_extreme_light_test.dart &
flutter test test/widget/golden/risk_banner_moderate_dark_test.dart &
wait
```

### Phase 3.4 - Documentation Updates (Parallel)
```bash
# Documentation updates can run in parallel
# Task T014: Update quickstart.md &
# Task T015: Update testing docs &
wait
```

## Constitutional Compliance Integration

### C1: Code Quality & Tests
- T001: Follows dart format and flutter analyze standards
- T002-T008: Comprehensive golden test coverage
- T009: Widget test coverage preservation and enhancement

### C2: Secrets & Logging  
- T012: Uses LocationUtils.logRedact() for 2-decimal coordinate precision
- No new secrets introduced (UI-only changes)

### C3: Accessibility (UI features)
- T009: Verifies ≥44dp touch targets maintained
- T010: Preserves semantic labels and screen reader compatibility
- All interactive elements maintain accessibility standards

### C4: Trust & Transparency
- T010: Preserves official RiskPalette colors, adds "Last Updated" timestamp and data source labeling inside banner
- Golden tests verify correct color application per risk level

### C5: Resilience & Test Coverage
- T002-T008: Visual regression prevention through golden tests  
- T009: Error state testing with proper onRetry functionality
- Enhanced error state icons (warning_amber_rounded) instead of fire icons

## Development Principles Alignment
- **"Fail visible, not silent"**: Error states enhanced with clear warning icons
- **"Fallbacks, not blanks"**: Cached data clearly labeled with preserved CachedBadge
- **"Keep logs clean"**: Coordinate logging uses LocationUtils.logRedact()
- **"Single source of truth"**: RiskPalette colors preserved, local styling constants
- **"Mock-first dev"**: Golden tests use consistent mock data for reproducibility

## Rollback Strategy
If any issues arise:
1. **T001-T009**: Revert `lib/widgets/risk_banner.dart` and remove golden test files
2. **T010-T013**: Revert HomeScreen changes and restore external timestamp/chip
3. **T014-T015**: Revert documentation updates

## Validation Criteria
- [ ] All golden tests pass with updated banner design
- [ ] Widget tests verify location row conditional rendering  
- [ ] Accessibility standards maintained (≥44dp, semantic labels)
- [ ] No visual regressions in risk level color mapping
- [ ] HomeScreen integration complete with coordinate display
- [ ] Documentation reflects new internal timestamp/source approach