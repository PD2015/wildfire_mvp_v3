# Pre-Implementation TODO: 015-rename-home-fire

**Created**: 2025-11-01  
**Purpose**: Address review findings before running implementation  
**Status**: Ready for execution

---

## 📋 Critical Issues to Fix

### ✅ ISSUE-1: AppBar Title Already Updated (T007 Outdated)
**Problem**: `lib/screens/home_screen.dart` line 57 already shows `title: const Text('Wildfire Risk')`  
**Impact**: T007 description is misleading, TDD tests will pass immediately instead of failing first  
**Priority**: HIGH

**Actions**:
- [ ] Update T007 in `tasks.md` to reflect current state
- [ ] Change T007 from "Update AppBar title" to "Verify AppBar title (already complete)"
- [ ] Update T003 test expectations to acknowledge AppBar is already correct
- [ ] Document that ~15% of UI work is pre-complete

**Updated T007 Text**:
```markdown
### T007: Verify AppBar Title in home_screen.dart (ALREADY COMPLETE)
**Type**: Verification [P]  
**Files**: `lib/screens/home_screen.dart`  
**Status**: ✅ Pre-existing - AppBar already displays "Wildfire Risk"

**Description**: Confirm AppBar title is already set to "Wildfire Risk" and no additional changes needed.

**Current State** (line 57):
```dart
appBar: AppBar(
  title: const Text('Wildfire Risk'),  // ✅ Already correct
  centerTitle: true,
),
```

**Validation**:
- [x] AppBar displays "Wildfire Risk" 
- [ ] No other title references in home_screen.dart need updating
- [ ] Tests confirm existing behavior

**Constitutional Gates**:
- C1: No changes needed, existing code already compliant

**Note**: This work was completed prior to this feature branch. Task serves as verification checkpoint.
```

---

### ⚠️ ISSUE-2: UI Constants File Doesn't Exist (T001 Unclear)
**Problem**: T001 suggests "Create or update" but `lib/config/ui_constants.dart` doesn't exist  
**Impact**: Task description ambiguous about file creation vs. modification  
**Priority**: MEDIUM

**Actions**:
- [ ] Update T001 to explicitly state "Create NEW file"
- [ ] Remove "or update" language from T001 description
- [ ] Add note that `lib/config/` directory may need creation
- [ ] Specify exact file path: `lib/config/ui_constants.dart`

**Updated T001 Opening**:
```markdown
### T001: Create NEW UI Constants File for Fire Risk Screen
**Type**: Core Setup [P]  
**Files**: `lib/config/ui_constants.dart` (NEW FILE - does not currently exist)  
**Description**: Create a new centralized constants file for all Fire Risk UI strings and icons.

**Prerequisites**:
- Create `lib/config/` directory if it doesn't exist: `mkdir -p lib/config`
- Create new file `lib/config/ui_constants.dart`
```

---

### ℹ️ ISSUE-3: Route Names Currently Absent (T002 Assumption)
**Problem**: Current go_router routes have NO `name:` field at all  
**Impact**: T002 assumes changing from `'home'` to `'fire-risk'`, but needs to ADD name fields  
**Priority**: MEDIUM

**Actions**:
- [ ] Update T002 to clarify adding NEW `name:` fields (not modifying existing)
- [ ] Update implementation example in T002 to show current state → target state
- [ ] Note that this is additive change, not replacement

**Updated T002 Implementation Section**:
```markdown
**Current State** (lib/app.dart, lines 50-62):
```dart
GoRoute(
  path: '/',
  // NO name field currently exists
  builder: (context, state) => HomeScreen(controller: homeController),
),
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
```
```

---

## 🔧 Recommended Improvements

### IMPROVE-1: Add Pre-Implementation Verification Checklist
**Purpose**: Catch reality drift before starting work  
**Location**: Add to top of `tasks.md` after "Prerequisites" section

**Action**:
- [ ] Add verification checklist section to `tasks.md`
- [ ] Include steps to verify current state matches assumptions
- [ ] Document findings for future reference

**Text to Add**:
```markdown
## Pre-Implementation Verification (Run First!)

Before starting task execution, verify current codebase state:

### Current State Checklist
- [x] AppBar title in `lib/screens/home_screen.dart` line 57: Already shows "Wildfire Risk" ✅
- [ ] Route names in `lib/app.dart` lines 50-62: Currently NO name fields (will add new)
- [ ] Bottom nav in `lib/widgets/bottom_nav.dart` line 44: Currently shows "Home" with Icons.home ✅
- [ ] UI constants file: Does NOT exist (will create new file) ✅
- [ ] Route alias '/fire-risk': Does NOT exist (will add new) ✅

### Reality Check Commands
```bash
# Verify AppBar title
grep -n "title:" lib/screens/home_screen.dart

# Check route names
grep -n "name:" lib/app.dart

# Check bottom nav label
grep -n "label:" lib/widgets/bottom_nav.dart

# Verify no ui_constants.dart exists
ls -la lib/config/ui_constants.dart 2>&1
```

### Findings Summary
- **Already Complete**: AppBar title (T007 is verification only)
- **Main Work Remaining**: Bottom nav icon/label (T008), route alias (T002), UI constants (T001)
- **Estimated Completion**: ~85% of work remains (AppBar was ~15% of UI changes)
```

---

### IMPROVE-2: Update TDD Test Expectations (T003)
**Purpose**: Tests should acknowledge AppBar is already correct  
**Impact**: Tests won't fail-first as true TDD expects, but will validate existing behavior

**Action**:
- [ ] Update T003 test description to note AppBar verification vs. change
- [ ] Add comment explaining why this test passes immediately
- [ ] Keep test for regression protection

**Text to Update in T003**:
```markdown
### T003 [TEST]: Widget Test for Navigation Shows Correct Content
**Type**: Widget Test [P]  
**Files**: `test/widget/fire_risk_navigation_test.dart` (new file)  
**Description**: Test that navigating to '/' and '/fire-risk' displays correct AppBar title and RiskBanner.

**NOTE**: AppBar title is already "Wildfire Risk" in current code (line 57 of home_screen.dart).  
This test will PASS immediately rather than fail-first. We keep it for regression protection.

**Requirements**:
- Test navigation to '/' shows HomeScreen with AppBar "Wildfire Risk" ✅ (existing)
- Test navigation to '/fire-risk' shows same HomeScreen ⏳ (to be added in T002)
- Verify RiskBanner widget is present ✅ (existing)
- Verify no "Home" text appears ✅ (existing)
- **Test Status**: Will pass immediately for AppBar, fail for '/fire-risk' route until T002 complete
```

---

### IMPROVE-3: Add Status Tracking Section to tasks.md
**Purpose**: Track which tasks are pre-complete vs. remaining  
**Location**: Add after execution flow, before task list

**Action**:
- [ ] Add implementation status section
- [ ] Mark T007 as pre-complete
- [ ] Calculate remaining work percentage

**Text to Add**:
```markdown
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
```

---

### IMPROVE-4: Add Quick Start Command Reference
**Purpose**: Easy copy-paste commands for common verification steps  
**Location**: Add to `quickstart.md` or beginning of `tasks.md`

**Action**:
- [ ] Create command reference section
- [ ] Include reality check commands
- [ ] Add test execution shortcuts

**Text to Add**:
```markdown
## Quick Command Reference

### Reality Check (Before Starting)
```bash
# Verify current state matches task assumptions
grep -n "title:" lib/screens/home_screen.dart     # Should show "Wildfire Risk"
grep -n "label:" lib/widgets/bottom_nav.dart       # Should show "Home" 
grep -n "name:" lib/app.dart                       # Should show no results
ls lib/config/ui_constants.dart 2>&1               # Should show "No such file"
```

### Development Workflow
```bash
# 1. Create UI constants (T001)
mkdir -p lib/config
touch lib/config/ui_constants.dart
# Edit file with constants from T001

# 2. Run tests first (TDD - T003-T006)
flutter test test/widget/fire_risk_navigation_test.dart    # Should fail
flutter test test/widget/bottom_nav_fire_risk_test.dart    # Should fail

# 3. Implement changes (T002, T008, T009)
# Edit files as specified in tasks

# 4. Verify tests pass
flutter test                                                # All should pass

# 5. Lint and format (T011)
flutter analyze
dart format lib/ test/
```

### Post-Implementation Verification
```bash
# Visual check
flutter run -d chrome --dart-define=MAP_LIVE_DATA=false

# Full test suite
flutter test

# Check for regressions
flutter test test/integration/
```
```

---

### IMPROVE-5: Document Screenshot/Visual Reference
**Purpose**: Show what's done vs. remaining visually  
**Location**: Add to `research.md` or create visual reference doc

**Action**:
- [ ] Add visual reference section to research.md
- [ ] Note which UI elements are complete vs. remaining
- [ ] Help future developers understand scope

**Text to Add to research.md**:
```markdown
## Visual Implementation Status

### Current State (2025-11-01)
```
┌─────────────────────────────────┐
│ Wildfire Risk              ✅  │  ← AppBar: ALREADY CORRECT
├─────────────────────────────────┤
│                                 │
│   [RiskBanner Component]        │
│                                 │
│   [Timestamp Display]           │
│                                 │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ 🏠 Home  | 🗺️ Map | 🔥 Report  │  ← Bottom Nav: NEEDS CHANGE
└─────────────────────────────────┘
      ⬆️ Change to: ⚠️ Fire Risk
```

### Target State (After Implementation)
```
┌─────────────────────────────────┐
│ Wildfire Risk              ✅  │  ← AppBar: Already done
├─────────────────────────────────┤
│                                 │
│   [RiskBanner Component]        │
│                                 │
│   [Timestamp Display]           │
│                                 │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ ⚠️ Fire Risk | 🗺️ Map | 🔥 Report│  ← Bottom Nav: NEW (T008)
└─────────────────────────────────┘
```

**Key Changes Remaining**:
- Icon: `Icons.home` → `Icons.warning_amber`
- Label: `"Home"` → `"Fire Risk"`
- Tooltip: `"Navigate to home screen"` → `"Navigate to fire risk screen"`
```

---

## 🎯 Implementation Checklist

### Before Starting Implementation
- [ ] Read this entire TODO document
- [ ] Run reality check commands (see IMPROVE-1)
- [ ] Update `tasks.md` with all corrections (ISSUE-1, ISSUE-2, ISSUE-3)
- [ ] Update `tasks.md` with improvements (IMPROVE-1 through IMPROVE-5)
- [ ] Commit updated tasks.md: `git commit -m "docs: update tasks.md with pre-implementation review findings"`

### During Implementation
- [ ] Follow updated task order with corrected descriptions
- [ ] Mark T007 as "verification only" when reached
- [ ] Use updated TDD test expectations (acknowledge AppBar pre-complete)
- [ ] Refer to command reference for common operations

### After Implementation
- [ ] Verify all tests pass (including pre-existing AppBar test)
- [ ] Run visual verification (flutter run)
- [ ] Update this TODO with "COMPLETED" status
- [ ] Archive to `specs/015-rename-home-fire/history/`

---

## 📝 Files to Update

| File | Section | Action | Priority |
|------|---------|--------|----------|
| `tasks.md` | T007 description | Rewrite as verification task | HIGH |
| `tasks.md` | T001 description | Clarify "CREATE NEW file" | HIGH |
| `tasks.md` | T002 implementation | Show current state (no names) → target | MEDIUM |
| `tasks.md` | After prerequisites | Add pre-implementation checklist (IMPROVE-1) | HIGH |
| `tasks.md` | After execution flow | Add status tracking section (IMPROVE-3) | MEDIUM |
| `tasks.md` | T003 description | Update TDD expectations (IMPROVE-2) | MEDIUM |
| `tasks.md` | Top of file | Add quick command reference (IMPROVE-4) | LOW |
| `research.md` | End of file | Add visual implementation status (IMPROVE-5) | LOW |

---

## 🚀 Next Actions

**Immediate (Before Implementation)**:
1. ✅ Run verification commands to confirm findings
2. ⏳ Update `tasks.md` with all HIGH priority corrections
3. ⏳ Commit updated documentation
4. ⏳ Proceed with implementation starting at T001

**Execution Order**:
```
1. Apply ISSUE-1, ISSUE-2, ISSUE-3 fixes → Commit
2. Apply IMPROVE-1 (verification checklist) → Commit  
3. Apply IMPROVE-2, IMPROVE-3 (test/status updates) → Commit
4. Apply IMPROVE-4, IMPROVE-5 (optional enhancements) → Commit or defer
5. Begin implementation with updated tasks.md
```

**Estimated Time**:
- Documentation updates: 30-45 minutes
- Implementation (with corrected scope): 2-3 hours
- Testing and polish: 1-2 hours
- **Total**: 4-6 hours (reduced from original estimate due to AppBar pre-completion)

---

## ✅ Validation

**This TODO is complete when**:
- [ ] All HIGH priority file updates applied
- [ ] tasks.md accurately reflects current codebase state
- [ ] Pre-implementation verification checklist added
- [ ] Implementation scope correctly understood (AppBar done, focus on bottom nav)
- [ ] Ready to run implementation with confidence

---

**Created by**: GitHub Copilot (AI Review)  
**Review Date**: 2025-11-01  
**Feature**: 015-rename-home-fire  
**Status**: Ready for execution
