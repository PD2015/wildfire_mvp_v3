# Tasks: A3 RiskBanner Home Widget

**Input**: Design documents from `/specs/003-a3-riskbanner-home/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/

## Execution Summary
Creating a Flutter widget to display wildfire risk levels with Scottish Government official colors, accessibility compliance, and proper state management. No data fetching - consumes existing FireRisk model from A2 service.

**Key Constraints**:
- Use RiskPalette constants (no hex literals)
- Handle loading/success/error/cached states
- Accessibility: semantic labels, ≥44dp touch targets
- Constitution gates: C1 (tests), C3 (accessibility), C4 (transparency), C5 (resilience)

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **Labels**: spec:A3, gate:C1, gate:C3, gate:C4, gate:C5

## Phase 3.1: Widget & States Implementation
**Task T001: Core RiskBanner Widget with State Management** ✅ ✅
- **File**: `lib/widgets/risk_banner.dart`
- **Purpose**: Pure presentational widget displaying wildfire risk with proper state handling
- **Labels**: spec:A3, gate:C1, gate:C3, gate:C4, gate:C5
- **Requirements**:
  - StatelessWidget that accepts RiskBannerState state (no BlocBuilder inside). Parent decides state mgmt.
  - Four visual states: loading (spinner), success (colored risk display), error (retry UI), error+cached (cached badge + cached level colors)
  - Main text: "Wildfire Risk: {LEVEL}" using RiskPalette colors
  - Error state: when cached FireRisk provided, render cached badge and use RiskPalette.fromLevel(cached.level) for banner color
  - Source chip displaying data origin (EFFIS/SEPA/Cache/Mock)
  - Relative timestamp: "Updated {relative_time}"
  - Show Retry button only when onRetry != null; optional callback parameter
  - Accessibility: semantic labels, minimum 44dp touch targets
  - No direct data fetching - consumes FireRisk model only
- **Validation**:
  - Widget height ≥44dp in all states
  - Semantic labels present for screen readers
  - Uses RiskPalette constants (no hex literals)
  - Displays source transparency per C4
  - Error states provide retry mechanism per C5

## Phase 3.2: Time Formatting & UI Utilities  
**Task T002 [P]: Time Formatting and Badge Components**
- **Files**: `lib/utils/time_format.dart`, `lib/widgets/badges/cached_badge.dart`
- **Purpose**: UTC to local time conversion with relative formatting and cached data badges
- **Labels**: spec:A3, gate:C4
- **Requirements**:
  - Function: `formatRelativeTime({required DateTime nowUtc, required DateTime updatedUtc}) -> String`
  - Keep outputs short: "Just now", "2 min ago", "1 hour ago", "3 days ago" (document in function header)
  - Unit tests for boundary cases (59s, 60s, 59m, 60m, 23h, 24h)
  - CachedBadge component at `lib/widgets/badges/cached_badge.dart` for offline/stale data indication
  - Integrate with RiskBanner for timestamp display
- **Validation**:
  - Accurate relative time calculations
  - Proper UTC→local timezone handling
  - Clear cached data indication per C4 transparency

## Phase 3.3: Comprehensive Testing Suite
**Task T003 [P]: Widget Tests and Golden Tests**
- **Files**: 
  - `test/widgets/risk_banner_test.dart`
  - `test/goldens/risk_banner/` (golden images)
- **Purpose**: Ensure widget correctness, accessibility, and visual consistency
- **Labels**: spec:A3, gate:C1, gate:C3, gate:C5
- **Requirements**:
  - **Widget Tests**:
    - Assert widget background equals RiskPalette.fromLevel(level) (not literal Color values)
    - Error view shows Cached badge and uses RiskPalette.fromLevel(cached.level) for banner color when cached data provided
    - Timestamp visibility in all appropriate states
    - Accessibility: semantic label "Current wildfire risk {LEVEL}, updated {relative time}. Source {EFFIS|SEPA|Cache|Mock}."
    - Explicit RenderBox size assertion for Retry button and tappable chips (≥44dp)
    - Test Retry button absence/presence behavior (onRetry != null)
    - State transition testing (loading→success→error flows)
  - **Golden Tests**:
    - Light/dark theme variants for each risk level (Very Low→Very High→Extreme) - add {extreme_light.png, extreme_dark.png}
    - Store golden images under `test/goldens/risk_banner/`
    - Cached state visual verification
    - Error state with/without cached data
  - **Test Helpers**:
    - fakeFireRisk({level, source, freshness, observedAtUtc}) factory
    - fakeSuccessState(level, source, freshness) factory
- **Validation**:
  - All tests pass with proper mocking
  - Golden tests detect visual regressions
  - Accessibility requirements verified programmatically
  - Constitutional compliance validated per C1, C3, C5

## Phase 3.4: Documentation & CI Integration
**Task T004 [P]: Documentation Updates and CI Validation**
- **Files**: 
  - `docs/UX-CUES.md` (required for wording changes)
  - CI configuration validation
- **Purpose**: Sync documentation and ensure CI compliance
- **Labels**: spec:A3, gate:C1
- **Requirements**:
  - Explicitly update `docs/UX-CUES.md` with any wording changes ("Updated {relative}" phrase, source-chip text)
  - Confirm CI runs widget tests + goldens (goldens can be updated with --update-goldens locally)
  - Verify CI passes with new widget code
  - Ensure flutter analyze and dart format compliance
  - Validate accessibility testing integration in CI
  - Document widget integration patterns for other developers
- **Validation**:
  - CI pipeline passes all checks
  - Documentation accurately reflects implementation
  - Code quality gates satisfied per C1

## Dependencies & Execution Order
```
T002 (utils) ← T001 (widget) ← T003 (tests)
                                      ↓
                                T004 (docs/CI)
```

**Parallel Execution**: T002 and T003 can run in parallel after T001 completes
**Sequential**: T001 must complete before T003 (widget tests need widget implementation)

## Parallel Execution Example
```bash
# After T001 completes
Task T002 & Task T003:
  - T002: Implement time_format.dart utilities
  - T003: Write widget tests and golden tests
  
# Finally
Task T004: Update documentation and validate CI
```

## Success Criteria
- ✅ RiskBanner widget displays all risk levels with correct RiskPalette colors
- ✅ Accessibility compliance: ≥44dp targets, semantic labels
- ✅ Error states provide retry functionality with clear user feedback
- ✅ Cached data clearly indicated with badges and transparency
- ✅ No hex color literals - all colors from RiskPalette constants
- ✅ Time formatting shows relative timestamps in local timezone
- ✅ Comprehensive test coverage with golden test visual validation
- ✅ CI passes with flutter analyze and accessibility checks
- ✅ Constitutional gates C1, C3, C4, C5 fully satisfied

## File Structure Created
```
lib/
├── widgets/
│   └── risk_banner.dart          # Main widget (T001)
└── utils/
    └── time_format.dart          # Time utilities (T002)

test/
├── widgets/
│   └── risk_banner_test.dart     # Widget tests (T003)
└── goldens/
    └── risk_banner/              # Golden images (T003)
        ├── very_low_light.png
        ├── very_low_dark.png
        ├── low_light.png
        ├── low_dark.png
        ├── moderate_light.png
        ├── moderate_dark.png
        ├── high_light.png
        ├── high_dark.png
        ├── very_high_light.png
        ├── very_high_dark.png
        ├── cached_state.png
        └── error_state.png
```