# Tasks: A9: Add blank Map screen and navigation

**Input**: Design documents from `/specs/010-a9-add-blank/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Tech stack: Dart 3.0+ with Flutter SDK, go_router, flutter_test
   → Structure: Feature-based module in lib/features/map/
2. Load design documents:
   → data-model.md: UI navigation feature, no data entities
   → contracts/: Widget interface contracts only  
   → research.md: go_router patterns, Material Design components
3. Generate tasks by category:
   → Setup: Feature structure, widget scaffolding
   → Tests: Widget tests for MapScreen and navigation
   → Core: MapScreen widget, route registration, Home integration
   → Polish: Constitutional compliance, formatting, final validation
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Widget tests before widget implementation (TDD)
   → Route registration before Home integration
5. Number tasks sequentially (T001-T006)
6. Focus on constitutional compliance (C1, C3, C5)
7. Return: SUCCESS (6 tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
**Flutter Project Structure** (from plan.md):
```
lib/
├── features/map/screens/map_screen.dart    # New MapScreen widget
├── app.dart                                # Route registration
└── screens/home/home_screen.dart           # Navigation button addition

test/
└── widget/features/map/map_screen_test.dart # Widget tests
```

## Phase 3.1: Setup & Scaffold
- [ ] **T001** Create MapScreen widget scaffold with AppBar('Map'), placeholder body text, and accessibility semantic label in `lib/features/map/screens/map_screen.dart`

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before route registration**
- [ ] **T004** [P] Write widget test confirming MapScreen renders correctly, validates AppBar title 'Map', checks semantic labels, and verifies accessibility compliance (≥44dp touch targets) in `test/widget/features/map/map_screen_test.dart`

## Phase 3.3: Core Implementation (ONLY after tests exist)
- [ ] **T002** Register MapScreen route '/map' in app_router using go_router configuration in `lib/app.dart` (or router config file)
- [ ] **T003** Add temporary navigation control from Home to Map screen ensuring ≥44dp touch target, semantic label, and Material Design ElevatedButton in `lib/screens/home/home_screen.dart`

## Phase 3.4: Constitutional Compliance & Polish
- [ ] **T005** [P] Run constitutional gates: `flutter analyze` (C1), `dart format --set-exit-if-changed .` (C1), and `flutter test` (C1) to ensure code quality compliance
- [ ] **T006** Commit implementation with proper message, create PR with linked issue A9 and labels (type:feature, area:navigation, phase:Phase0) following project contribution guidelines

## Dependencies
- **T001** (MapScreen scaffold) must complete before **T004** (widget test)
- **T004** (widget test) must complete and fail before **T002** (route registration)
- **T002** (route registration) must complete before **T003** (Home integration)
- **T005** (constitutional gates) requires all implementation complete (**T001-T003**)
- **T006** (commit/PR) requires **T005** passing

## Parallel Execution Groups

### Group 1: Independent Setup (can run together)
```bash
# After T001 completes, these can run in parallel:
Task: "Write widget test for MapScreen in test/widget/features/map/map_screen_test.dart"
# T004 is parallel-eligible once T001 scaffold exists
```

### Group 2: Validation Tasks (can run together)  
```bash
# After T003 completes, these can run in parallel:
Task: "Run flutter analyze, dart format, flutter test for constitutional compliance"
# T005 constitutional gates can be run independently
```

## Flutter-Specific Implementation Notes

### T001: MapScreen Scaffold
- Use `Scaffold` with `AppBar(title: Text('Map'))`
- Include `Semantics` widget for accessibility
- Add placeholder `Center(child: Text('Map placeholder'))`
- Follow Material Design guidelines

### T002: go_router Registration  
- Add route `GoRoute(path: '/map', builder: (context, state) => MapScreen())`
- Ensure route is accessible from existing navigation structure
- Test route navigation in widget tests

### T003: Home Screen Navigation
- Add `ElevatedButton` or `TextButton` with proper semantics
- Use `context.go('/map')` for navigation
- Ensure button meets ≥44dp touch target requirement (Material default: 48dp)
- Include `semanticsLabel` property

### T004: Widget Testing
- Test `MapScreen` renders without errors
- Verify `AppBar` title displays "Map"
- Check semantic properties for accessibility
- Test navigation functionality with `WidgetTester`

### T005: Constitutional Compliance
```bash
flutter analyze                           # C1: Code quality
dart format --set-exit-if-changed .      # C1: Formatting  
flutter test                             # C1: Test coverage
# C2: No secrets (N/A for UI feature)
# C3: Accessibility verified in T004
# C4: Standard colors only (Material theme)
# C5: Standard navigation error handling
```

## Task Validation Checklist
*Applied to each task completion*

- [ ] All widget contracts have corresponding tests (T004 → T001)
- [ ] MapScreen widget follows Material Design patterns  
- [ ] Navigation tests verify go_router integration
- [ ] Accessibility requirements validated (semantic labels, touch targets)
- [ ] Each task specifies exact file path
- [ ] Constitutional gates (C1, C3, C5) integrated throughout
- [ ] Tests written before implementation (TDD approach)

## Success Criteria

✅ **T001-T003 Complete**: Navigation flow Home → Map → Back working
✅ **T004 Complete**: Widget tests pass, accessibility verified  
✅ **T005 Complete**: All constitutional gates pass (analyze, format, test)
✅ **T006 Complete**: Code committed, PR created with proper labels

The blank Map screen serves as a placeholder for future map functionality while establishing the navigation architecture and constitutional compliance patterns.