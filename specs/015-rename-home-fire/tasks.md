# Tasks: Rename Home → Fire Risk Screen and Update Navigation Icon

**Feature**: 015-rename-home-fire  
**Input**: Design documents from `/specs/015-rename-home-fire/`  
**Prerequisites**: plan.md (complete), research.md (complete), data-model.md (complete), contracts/ (complete)

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → COMPLETED: Tech stack (Dart 3.9.2, Flutter 3.35.5, go_router)
   → Extracted: UI/routing changes, phased migration strategy
2. Load optional design documents:
   → data-model.md: Navigation entities, route configuration, accessibility models
   → contracts/: Navigation component contracts identified
   → research.md: Icon decisions, route alias strategy, migration approach
3. Generate tasks by category:
   → Setup: Dependencies validation, route configuration
   → Tests: Widget tests (navigation), route tests, accessibility tests
   → Core: UI constants, navigation components, screen updates
   → Integration: Route aliases, semantic labels, theme validation
   → Polish: Documentation, changelog, golden tests
4. Apply task rules:
   → UI constants and navigation are parallel [P]
   → Route configuration sequential (shared go_router config)
   → Tests parallel [P] (independent test files)
5. Number tasks sequentially (T001-T015)
6. Validate constitutional compliance throughout
7. Return: SUCCESS (tasks ready for execution)
```

---

## Pre-Implementation Verification (Run First!)

Before starting task execution, verify current codebase state matches task assumptions:

### Current State Checklist
- [x] **AppBar title** in `lib/screens/home_screen.dart` line 57: Already shows "Wildfire Risk" ✅
- [x] **Route names** in `lib/app.dart` lines 50-62: Currently NO name fields (will add new) ✅
- [x] **Bottom nav** in `lib/widgets/bottom_nav.dart` line 44: Currently shows "Home" with Icons.home ✅
- [x] **UI constants file**: Does NOT exist at `lib/config/ui_constants.dart` (will create new) ✅
- [x] **Route alias** '/fire-risk': Does NOT exist (will add new) ✅

### Reality Check Commands
```bash
# Verify AppBar title (should show "Wildfire Risk")
grep -n "title:" lib/screens/home_screen.dart

# Check route names (should show no results or very few)
grep -n "name:" lib/app.dart

# Check bottom nav label (should show "Home")
grep -n "label:" lib/widgets/bottom_nav.dart

# Verify no ui_constants.dart exists (should error)
ls -la lib/config/ui_constants.dart 2>&1

# Check for '/fire-risk' route (should show no matches)
grep -n "fire-risk" lib/app.dart
```

### Findings Summary
- **✅ Already Complete**: AppBar title shows "Wildfire Risk" (T007 is verification only)
- **⏳ Main Work Remaining**: Bottom nav icon/label (T008), route alias (T002), UI constants (T001)
- **📊 Progress**: ~15% complete (AppBar done), ~85% remaining

---

## Implementation Status

### Pre-Completion Audit (2025-11-01)
Some work discovered already complete in codebase:

| Task | Status | Current State | Action Required |
|------|--------|---------------|-----------------|
| T007 | ✅ PRE-COMPLETE | AppBar shows "Wildfire Risk" | Verification only |
| T001 | ⏳ TO DO | No ui_constants.dart exists | Create new file |
| T002 | ⏳ TO DO | No route names/aliases | Add name fields + alias |
| T008 | ⏳ TO DO | Bottom nav shows "Home" | Update label + icon |
| T009 | ⏳ TO DO | No semantic labels | Add accessibility |

**Work Distribution**:
- ✅ Pre-complete: ~15% (AppBar title)
- ⏳ Remaining: ~85% (nav icon, routes, constants, tests, docs)

**Key Insight**: Focus implementation effort on bottom navigation (T008) and route configuration (T002) as primary deliverables.

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions
- Mark [TEST] for test-first TDD approach

---

## Phase 3.1: Setup & Configuration

### T001: Create NEW UI Constants File for Fire Risk Screen
**Type**: Core Setup [P]  
**Files**: `lib/config/ui_constants.dart` (NEW FILE - does not currently exist)  
**Description**: Create a new centralized constants file for all Fire Risk UI strings and icons.

**Prerequisites**:
- Verify `lib/config/` directory exists, create if needed: `mkdir -p lib/config`
- Create new file: `lib/config/ui_constants.dart`

**Requirements**:
- Define `fireRiskTitle = "Fire Risk"` for navigation label
- Define `fireRiskAppBarTitle = "Wildfire Risk"` for screen title
- Define `fireRiskIcon = Icons.warning_amber` for primary icon
- Define `fireRiskIconFallback = Icons.report_outlined` for fallback
- Define `fireRiskRoute = "/"` and `fireRiskRouteAlias = "/fire-risk"`
- Define semantic labels: `fireRiskNavSemantic = "Fire risk information tab"`
- Define screen semantic template: `"Current wildfire risk is {LEVEL}, updated {RELATIVE_TIME}. Source: {SOURCE}."`

**Validation**:
- All strings are const and exported
- No hardcoded "Home" strings remain
- Icons validated to exist in Material Design

**Constitutional Gates**:
- C1: Code must pass `flutter analyze`
- C2: No PII in strings or constants

---

### T002: Add '/fire-risk' Route Alias in go_router Configuration
**Type**: Core Implementation  
**Files**: `lib/app.dart` (lines 50-62 approximately)  
**Description**: Add route names and '/fire-risk' alias to existing routes. Current routes have NO name fields.

**Current State** (lib/app.dart, lines 50-62):
```dart
GoRoute(
  path: '/',
  // NO name field currently exists
  builder: (context, state) => HomeScreen(controller: homeController),
),
GoRoute(
  path: '/map',
  // NO name field
  builder: (context, state) { /* ... */ },
),
// ... other routes without names
```

**Target State**:
```dart
GoRoute(
  path: '/',
  name: 'fire-risk',  // ← NEW: Add name field
  builder: (context, state) => HomeScreen(controller: homeController),
),
GoRoute(
  path: '/fire-risk',  // ← NEW: Add alias route
  name: 'fire-risk-alias',
  builder: (context, state) => HomeScreen(controller: homeController),
),
GoRoute(
  path: '/map',
  name: 'map',  // ← OPTIONAL: Add name for consistency
  builder: (context, state) { /* ... */ },
),
// ... other routes
```

**Requirements**:
- ADD new `name: 'fire-risk'` field to existing '/' route
- ADD new route definition: `path: '/fire-risk'` with `name: 'fire-risk-alias'`
- Keep existing widget references unchanged (HomeScreen stays as-is)
- Ensure app starts on '/' but both routes load identical content
- Optionally add names to other routes for consistency

**Validation**:
- Both '/' and '/fire-risk' navigate to same screen
- No 404 or routing errors
- Deep links work for both paths
- Browser navigation (back/forward) functions correctly

**Constitutional Gates**:
- C1: Route configuration passes analyze

**Depends on**: None (standalone change) - T001 provides optional constants

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

### T003 [TEST]: Widget Test for Navigation to '/fire-risk' Shows Correct Content
**Type**: Widget Test [P]  
**Files**: `test/widget/fire_risk_navigation_test.dart` (new file)  
**Description**: Test that navigating to '/' and '/fire-risk' displays correct AppBar title and RiskBanner.

**⚠️ NOTE**: AppBar title is already "Wildfire Risk" in current code (line 57 of home_screen.dart).  
This test will **PASS immediately** for AppBar verification rather than fail-first. We keep it for regression protection.

**Requirements**:
- Test navigation to '/' shows HomeScreen with AppBar "Wildfire Risk" ✅ (existing)
- Test navigation to '/fire-risk' shows same HomeScreen ⏳ (route to be added in T002)
- Verify RiskBanner widget is present ✅ (existing)
- Verify no "Home" text appears ✅ (existing)
- **Test Status**: Will pass immediately for AppBar checks, will fail for '/fire-risk' route until T002 complete

**Test Structure**:
```dart
testWidgets('navigating to / shows FireRisk screen with correct title', (tester) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  router.go('/');
  await tester.pumpAndSettle();
  
  // These will PASS immediately (AppBar already correct)
  expect(find.text('Wildfire Risk'), findsOneWidget);
  expect(find.byType(RiskBanner), findsOneWidget);
  expect(find.text('Home'), findsNothing);
});

testWidgets('navigating to /fire-risk shows same screen', (tester) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  router.go('/fire-risk');  // This will FAIL until T002 adds route
  await tester.pumpAndSettle();
  
  expect(find.text('Wildfire Risk'), findsOneWidget);
  expect(find.byType(RiskBanner), findsOneWidget);
});
```

**Validation**:
- Test for '/' route passes immediately (AppBar already correct) ✅
- Test for '/fire-risk' route fails before T002 (route doesn't exist) ⏳
- Test for '/fire-risk' route passes after T002 complete ✅
- No flaky assertions

**Constitutional Gates**:
- C1: Test must be well-formed and runnable

---

### T004 [TEST]: Widget Test for Bottom Nav "Fire Risk" Selected State
**Type**: Widget Test [P]  
**Files**: `test/widget/bottom_nav_fire_risk_test.dart` (new file)  
**Description**: Test that bottom navigation shows "Fire Risk" label with warning icon and proper selected state.

**Requirements**:
- Verify bottom nav displays "Fire Risk" label (not "Home")
- Verify icon is Icons.warning_amber (not Icons.home)
- Verify selected state when on fire risk screen
- Verify unselected state when on other screens (if multiple tabs exist)
- Test semantic label: "Fire risk information tab"
- Test must FAIL initially (no implementation changes yet)

**Test Structure**:
```dart
testWidgets('bottom nav shows Fire Risk with warning icon', (tester) async {
  await tester.pumpWidget(MaterialApp(home: BottomNavigation()));
  
  expect(find.text('Fire Risk'), findsOneWidget);
  expect(find.text('Home'), findsNothing);
  expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  
  final semantics = tester.getSemantics(find.text('Fire Risk'));
  expect(semantics.label, contains('Fire risk'));
});
```

**Validation**:
- Test fails before implementation
- Test passes after T005 complete
- Icon renders correctly in test environment

**Constitutional Gates**:
- C1: Test must pass flutter analyze

---

### T005 [TEST]: Accessibility Test for Touch Targets and Semantic Labels
**Type**: Integration Test [P]  
**Files**: `test/widget/fire_risk_accessibility_test.dart` (new file)  
**Description**: Validate accessibility compliance for ≥44dp touch targets and proper semantic labels.

**Requirements**:
- Test bottom nav fire risk item has ≥44dp touch target
- Test "Set Location" button (if exists) has ≥44dp touch target
- Test RiskBanner has proper semantic description including level, time, source
- Verify semantic labels don't contain PII or raw coordinates
- Test must validate both light and dark theme contrast (if applicable)

**Test Structure**:
```dart
testWidgets('fire risk navigation has adequate touch target', (tester) async {
  await tester.pumpWidget(MaterialApp(home: BottomNavigation()));
  
  final navItem = tester.getSize(find.text('Fire Risk'));
  expect(navItem.height, greaterThanOrEqualTo(44.0));
  expect(navItem.width, greaterThanOrEqualTo(44.0));
});

testWidgets('RiskBanner has descriptive semantics', (tester) async {
  await tester.pumpWidget(MaterialApp(home: FireRiskScreen()));
  
  final semantics = tester.getSemantics(find.byType(RiskBanner));
  expect(semantics.label, contains('wildfire risk'));
  expect(semantics.label, contains('updated'));
  expect(semantics.label, contains('Source'));
  expect(semantics.label.contains(RegExp(r'\d{2}\.\d+')), isFalse); // No precise coords
});
```

**Validation**:
- All touch targets meet minimum size
- Semantic labels are descriptive and informative
- No PII or precise coordinates in accessibility text

**Constitutional Gates**:
- C3: Touch targets ≥44dp verified
- C2: No PII in semantic labels

---

### T006 [TEST]: Route Navigation Integration Test
**Type**: Integration Test [P]  
**Files**: `integration_test/fire_risk_route_test.dart` (new file)  
**Description**: Integration test for route navigation, deep linking, and browser compatibility.

**Requirements**:
- Test app starts on '/' and shows fire risk content
- Test direct navigation to '/fire-risk' works
- Test both routes show identical content
- Test browser back button works (web platform)
- Test deep link restoration after app backgrounding
- Test existing bookmarks don't break

**Test Structure**:
```dart
testWidgets('both / and /fire-risk routes show same screen', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to /
  router.go('/');
  await tester.pumpAndSettle();
  expect(find.text('Wildfire Risk'), findsOneWidget);
  
  // Navigate to /fire-risk
  router.go('/fire-risk');
  await tester.pumpAndSettle();
  expect(find.text('Wildfire Risk'), findsOneWidget);
  expect(find.byType(RiskBanner), findsOneWidget);
});
```

**Validation**:
- Route navigation is seamless
- No 404 errors or broken navigation
- State preservation works correctly

**Constitutional Gates**:
- C5: Error handling for invalid routes

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### T007: Verify AppBar Title in home_screen.dart (✅ ALREADY COMPLETE)
**Type**: Verification [P]  
**Status**: ✅ PRE-EXISTING - AppBar already displays "Wildfire Risk"  
**Files**: `lib/screens/home_screen.dart`  
**Description**: Confirm AppBar title is already set to "Wildfire Risk" and no additional changes needed.

**Current State** (line 57 of home_screen.dart):
```dart
appBar: AppBar(
  title: const Text('Wildfire Risk'),  // ✅ Already correct!
  centerTitle: true,
),
```

**Requirements**:
- [x] Verify AppBar displays "Wildfire Risk" (already done)
- [ ] Check for any other "Home" string references in file
- [ ] Confirm no additional title updates needed
- [ ] Optional: Refactor to use UIConstants.fireRiskAppBarTitle (if T001 creates it)

**Validation**:
- AppBar displays "Wildfire Risk" when screen loads ✅
- No "Home" text visible in AppBar ✅
- Existing AppBar functionality unchanged ✅

**Constitutional Gates**:
- C1: Code already passes flutter analyze (no changes needed)

**Note**: This work was completed prior to this feature branch. Task serves as verification checkpoint only. If T001 creates UIConstants, optionally refactor to use constant instead of hardcoded string.

**Depends on**: None (already complete) - Optional: T001 for constants refactor

---

### T008: Update Bottom Navigation Item Label and Icon
**Type**: Core Implementation [P]  
**Files**: `lib/widgets/bottom_nav.dart` (or equivalent navigation widget)  
**Description**: Change bottom navigation item from "Home" with house icon to "Fire Risk" with warning icon.

**Requirements**:
- Update BottomNavigationBarItem label to `UIConstants.fireRiskTitle` ("Fire Risk")
- Update icon to `Icon(UIConstants.fireRiskIcon)` (Icons.warning_amber)
- Update activeIcon if separate selected state icon needed
- Maintain existing selected/unselected visual states
- Preserve tap handlers and navigation logic

**Implementation**:
```dart
BottomNavigationBarItem(
  icon: Icon(UIConstants.fireRiskIcon), // Icons.warning_amber
  activeIcon: Icon(UIConstants.fireRiskIcon), // Same or emphasized
  label: UIConstants.fireRiskTitle, // "Fire Risk"
  tooltip: UIConstants.fireRiskNavSemantic, // Accessibility
)
```

**Validation**:
- Bottom nav shows "Fire Risk" label
- Warning/amber icon displays correctly
- Icon visible in both light and dark themes
- Touch target remains ≥44dp

**Constitutional Gates**:
- C1: Code passes flutter analyze
- C3: Touch target verified ≥44dp

**Depends on**: T001 (UI constants), T004 (test exists)

---

### T009: Add Semantic Labels for Screen Readers
**Type**: Core Implementation [P]  
**Files**: `lib/screens/home_screen.dart`, `lib/widgets/risk_banner.dart`  
**Description**: Update semantic labels to provide context-rich descriptions for screen reader users.

**Requirements**:
- Wrap bottom nav item with Semantics widget: `semanticsLabel: UIConstants.fireRiskNavSemantic`
- Update RiskBanner Semantics to dynamic format: `"Current wildfire risk is {level}, updated {relativeTime}. Source: {source}."`
- Ensure icon has descriptive label: "Warning symbol indicating fire risk information"
- Remove generic "Home" semantics
- Validate no PII or precise coordinates in semantic text

**Implementation**:
```dart
// Bottom navigation
Semantics(
  label: UIConstants.fireRiskNavSemantic,
  child: BottomNavigationBarItem(...)
)

// RiskBanner
Semantics(
  label: 'Current wildfire risk is ${riskLevel.name}, updated ${relativeTime}. Source: ${dataSource}.',
  child: RiskBanner(...)
)
```

**Validation**:
- Screen reader announces "Fire risk information tab" for nav item
- RiskBanner semantic description includes level, time, and source
- No raw coordinates in semantic labels

**Constitutional Gates**:
- C2: No PII in semantic labels
- C3: Semantic labels descriptive and helpful

**Depends on**: T001 (UI constants), T005 (accessibility test)

---

## Phase 3.4: Integration & Validation

### T010: Verify Icon Contrast in Light and Dark Themes
**Type**: Integration [P]  
**Files**: `lib/theme/app_theme.dart` (if exists), manual testing  
**Description**: Validate Icons.warning_amber has adequate contrast in both light and dark themes.

**Requirements**:
- Test icon visibility in light theme (should be clearly visible)
- Test icon visibility in dark theme (should be clearly visible)
- If contrast insufficient, adjust iconTheme or use custom color
- Prefer Material Design defaults unless accessibility issue found
- Document any custom color adjustments in comments

**Validation Steps**:
1. Run app with light theme: `flutter run --dart-define=THEME=light`
2. Visually inspect warning icon in bottom navigation
3. Run app with dark theme: `flutter run --dart-define=THEME=dark`
4. Visually inspect warning icon in bottom navigation
5. Use contrast checker tool if needed (WCAG AA minimum 4.5:1 for text, 3:1 for UI components)

**Validation**:
- Icon passes WCAG AA contrast requirements in both themes
- No custom colors needed unless Material defaults fail
- Icon is distinguishable and recognizable

**Constitutional Gates**:
- C4: Color compliance maintained
- C3: Visual accessibility verified

**Depends on**: T008 (icon implementation)

---

### T011: Run Linting and Analysis (CI Gates)
**Type**: Validation [P]  
**Files**: All modified files  
**Description**: Ensure all code changes pass flutter analyze and dart format checks.

**Requirements**:
- Run `flutter analyze` and fix any errors or warnings
- Run `dart format lib/ test/` and ensure consistent formatting
- Run `dart format --set-exit-if-changed lib/ test/` to verify formatting
- Address any new linter warnings introduced by changes

**Commands**:
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Verify formatting (CI check)
dart format --set-exit-if-changed lib/ test/

# Run all tests
flutter test
```

**Validation**:
- `flutter analyze` exits with code 0 (no errors)
- `dart format --set-exit-if-changed` exits with code 0 (properly formatted)
- All tests pass (T003-T006 should now pass)

**Constitutional Gates**:
- C1: Code quality and tests pass

**Depends on**: T007, T008, T009 (all core implementation complete)

---

## Phase 3.5: Polish & Documentation

### T012 [OPTIONAL]: Golden Test for RiskBanner in Very Low State
**Type**: Visual Regression Test [P]  
**Files**: `test/widget/golden/risk_banner_very_low_golden_test.dart`  
**Description**: Create golden test to capture visual snapshot of RiskBanner in Very Low risk state.

**Requirements**:
- Set up golden test for RiskBanner with Very Low risk data
- Capture screenshot of banner with new "Wildfire Risk" title context
- Use `matchesGoldenFile()` matcher
- Generate golden files with `flutter test --update-goldens`

**Implementation**:
```dart
testWidgets('RiskBanner very low state matches golden', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('Wildfire Risk')),
      body: RiskBanner(
        risk: FireRisk(level: RiskLevel.veryLow, fwi: 2.0, ...),
      ),
    ),
  ));
  
  await expectLater(
    find.byType(RiskBanner),
    matchesGoldenFile('golden/risk_banner_very_low.png'),
  );
});
```

**Validation**:
- Golden file generated successfully
- Visual regression test catches unintended UI changes
- Test passes on CI (golden files committed)

**Note**: This task is optional but recommended for visual regression protection.

**Depends on**: T007, T008 (UI changes complete)

---

### T013: Update Documentation (README, CONTRIBUTING)
**Type**: Documentation [P]  
**Files**: `README.md`, `CONTRIBUTING.md`, `docs/` (if exists)  
**Description**: Update any documentation that references "Home" screen to reflect "Fire Risk" rename.

**Requirements**:
- Search for "Home" references in documentation files
- Replace with "Fire Risk" or "Wildfire Risk" as appropriate
- Update screenshots if they show old "Home" label (or note they're outdated)
- Update feature descriptions to reflect fire risk focus
- Verify navigation instructions reference correct routes

**Commands**:
```bash
# Find "Home" references in docs
grep -r "Home" README.md CONTRIBUTING.md docs/ 2>/dev/null

# Update references (manual editing)
```

**Files to Check**:
- `README.md`: Feature descriptions, navigation examples
- `CONTRIBUTING.md`: Development setup, testing instructions
- `docs/`: Any architecture or design documentation

**Validation**:
- Documentation accurately reflects renamed screen
- No confusing "Home" references remain
- Navigation instructions up-to-date

**Depends on**: All core implementation complete

---

### T014: Add CHANGELOG Entry
**Type**: Documentation [P]  
**Files**: `CHANGELOG.md`  
**Description**: Document the Home → Fire Risk rename in the changelog.

**Requirements**:
- Add entry under "Unreleased" or next version section
- Use clear, user-facing language
- Mention navigation icon change
- Note backward compatibility for routes

**Entry Format**:
```markdown
## [Unreleased]

### Changed
- Renamed "Home" screen to "Fire Risk" to better communicate app purpose
- Updated navigation icon from house to warning symbol (Icons.warning_amber)
- Added '/fire-risk' route alias for semantic clarity (existing '/' route unchanged)
- Enhanced screen reader accessibility with context-rich semantic labels

### Migration
- No action required for users - existing bookmarks and navigation continue to work
- Developers: Update any documentation or internal references from "Home" to "Fire Risk"
```

**Validation**:
- Changelog entry is clear and informative
- Users understand what changed and why
- No breaking changes communicated

**Depends on**: All implementation complete

---

### T015: Manual Testing Checklist (Execute quickstart.md)
**Type**: Validation  
**Files**: `specs/015-rename-home-fire/quickstart.md` (reference)  
**Description**: Execute the quickstart validation scenarios to verify end-to-end functionality.

**Requirements**:
- Follow all scenarios in quickstart.md
- Test on at least 2 platforms (mobile + web recommended)
- Verify visual UI changes (Scenario 1)
- Verify navigation functionality (Scenario 2)
- Verify existing functionality preservation (Scenario 3)
- Verify cross-platform consistency (Scenario 4)
- Complete success criteria checklist

**Validation Checklist**:
- [ ] Bottom navigation shows "Fire Risk" label with warning icon
- [ ] App bar displays "Wildfire Risk"
- [ ] No "Home" text visible in UI
- [ ] Routes '/' and '/fire-risk' both work
- [ ] Fire risk data displays correctly (banner, timestamp, source)
- [ ] All existing features preserved (location, data refresh)
- [ ] Screen reader announces appropriate labels
- [ ] Touch targets responsive and ≥44dp
- [ ] Icon readable in light and dark themes
- [ ] All automated tests pass

**If Any Issues Found**:
- Document issues clearly
- Determine if blocker or minor
- Fix critical issues before completion
- Create follow-up tasks for minor issues

**Depends on**: All previous tasks complete

---

## Dependencies Graph

```
T001 (UI Constants) [P]
  ↓
T002 (Route Configuration)
  ↓
[Tests First - Must Fail]
T003 [TEST] Navigation Test [P]
T004 [TEST] Bottom Nav Test [P]
T005 [TEST] Accessibility Test [P]
T006 [TEST] Route Integration Test [P]
  ↓
[Core Implementation - Make Tests Pass]
T007 (AppBar Update) [P] ← depends on T001, T003
T008 (Bottom Nav Update) [P] ← depends on T001, T004
T009 (Semantic Labels) [P] ← depends on T001, T005
  ↓
[Integration & Validation]
T010 (Theme Verification) [P] ← depends on T008
T011 (Linting & Analysis) ← depends on T007, T008, T009
  ↓
[Polish]
T012 (Golden Tests) [P] [OPTIONAL] ← depends on T007, T008
T013 (Documentation) [P] ← depends on all core
T014 (CHANGELOG) [P] ← depends on all core
T015 (Manual Testing) ← depends on ALL previous tasks
```

---

## Parallel Execution Examples

### Batch 1: Setup (Parallel)
```bash
# All these tasks can run in parallel - different files
Task T001: "Create UI constants for fire risk strings and icons"
# Creates lib/config/ui_constants.dart

# No other parallel tasks in setup phase
```

### Batch 2: Write Tests (All Parallel - TDD)
```bash
# All test files are independent and can be written in parallel
Task T003: "Widget test for navigation to /fire-risk"
Task T004: "Widget test for bottom nav Fire Risk label and icon"
Task T005: "Accessibility test for touch targets and semantics"
Task T006: "Integration test for route navigation and deep linking"

# Run tests - should all FAIL at this point
flutter test
```

### Batch 3: Core Implementation (Parallel Where Possible)
```bash
# T002 must complete first (route configuration - single file)
Task T002: "Add /fire-risk route alias in go_router"

# Then these can run in parallel - different files
Task T007: "Update AppBar title in home_screen.dart"
Task T008: "Update bottom navigation in bottom_nav.dart"
Task T009: "Add semantic labels in multiple widgets"

# Run tests again - should all PASS now
flutter test
```

### Batch 4: Validation and Polish (Parallel)
```bash
# These can run in parallel - independent activities
Task T010: "Verify icon contrast in themes"
Task T012: "Create golden tests for RiskBanner"
Task T013: "Update documentation files"
Task T014: "Add CHANGELOG entry"

# T011 must complete before T015
Task T011: "Run flutter analyze and dart format"
Task T015: "Execute manual testing checklist"
```

---

## Constitutional Compliance Summary

### C1: Code Quality & Tests
- **T003-T006**: Widget and integration tests for all changes
- **T011**: Flutter analyze and dart format enforcement
- **Status**: ✅ All test tasks include TDD approach

### C2: Secrets & Logging
- **T001**: No secrets in UI constants
- **T009**: Semantic labels validated for no PII or precise coordinates
- **Status**: ✅ No new secrets, existing logging preserved

### C3: Accessibility
- **T005**: Touch target validation (≥44dp)
- **T009**: Enhanced semantic labels for screen readers
- **T010**: Icon contrast verification
- **Status**: ✅ Accessibility improved with better semantic descriptions

### C4: Trust & Transparency
- **T007**: AppBar title maintains clear branding
- **All tasks**: Preserve existing timestamp and source chip displays
- **Status**: ✅ No changes to trust indicators

### C5: Resilience & Test Coverage
- **T006**: Integration tests for navigation error handling
- **T011**: All tests must pass before completion
- **Status**: ✅ Existing error handling preserved, comprehensive test coverage

---

## Execution Summary

**Total Tasks**: 15 (14 required + 1 optional)  
**Parallel Tasks**: 10 tasks marked [P]  
**Test Tasks**: 4 tasks (T003-T006)  
**Estimated Time**: 
- Setup & Tests: 2-3 hours
- Core Implementation: 3-4 hours
- Validation & Polish: 1-2 hours
- **Total**: 6-9 hours

**Success Criteria**:
- All tests pass (T003-T006 go from failing → passing)
- Flutter analyze clean (T011)
- Manual testing checklist complete (T015)
- Constitutional gates satisfied (C1-C5)
- Zero regression in existing functionality

**Ready for Implementation**: ✅ All tasks are specific, have clear file paths, and can be executed by an LLM or developer without additional context.