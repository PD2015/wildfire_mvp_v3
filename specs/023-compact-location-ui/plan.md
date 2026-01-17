# Implementation Plan: Compact Location UI

**Feature Branch**: `023-compact-location-ui`  
**Created**: 2026-01-12  
**Spec**: [spec.md](./spec.md)

---

## Implementation Strategy

### Approach: Incremental Widget Extraction

Rather than refactoring existing widgets in-place, we'll create new focused widgets that:
1. Extract reusable patterns from existing `LocationCard`
2. Compose existing services/controllers (no new data layer)
3. Integrate incrementally (Risk screen first, then Report screen)

This approach:
- Keeps existing widgets stable during development
- Allows parallel testing of old vs new layouts
- Reduces risk of breaking changes

---

## Phase 1: Shared Components (Foundation)

### Task 1.1: Create `LocationChip` Widget
**File**: `lib/widgets/location_chip.dart`

A compact, tappable widget showing location summary:
- Place name (or coordinates fallback)
- Source badge (GPS/Manual/Cached)
- Expand/collapse chevron

**Props**:
```dart
class LocationChip extends StatelessWidget {
  final String? placeName;
  final String? coordinatesLabel;
  final LocationSource? locationSource;
  final bool isExpanded;
  final bool isLoading;
  final VoidCallback? onTap;
}
```

**Dependencies**: 
- `LocationSource` enum (existing)
- Theme tokens from `wildfire_a11y_theme.dart`

**Acceptance**:
- [ ] Displays place name when available, coordinates when not
- [ ] Shows source badge (GPS/MANUAL/CACHED)
- [ ] Chevron rotates based on `isExpanded`
- [ ] Loading state shows shimmer/spinner
- [ ] ≥48dp touch target
- [ ] Semantic label for screen readers

---

### Task 1.2: Create `ExpandableLocationPanel` Widget
**File**: `lib/widgets/expandable_location_panel.dart`

Full location details panel that animates open/closed:
- Coordinates display (lat/lng)
- what3words row (with tester badge)
- Static map preview
- Action buttons (Update location, Copy location)

**Props**:
```dart
class ExpandableLocationPanel extends StatelessWidget {
  final String? coordinatesLabel;
  final String? what3words;
  final bool isWhat3wordsLoading;
  final String? staticMapUrl;
  final VoidCallback? onUpdateLocation;
  final VoidCallback? onCopyLocation;
  final VoidCallback? onUseGps;
  final bool showUseGpsButton; // true when manual location active
}
```

**Dependencies**:
- `LocationMiniMapPreview` (existing)
- Theme tokens

**Acceptance**:
- [ ] Shows lat/lng in styled row
- [ ] what3words row with "Tester preview" badge when unavailable
- [ ] Map preview (reuse existing `LocationMiniMapPreview`)
- [ ] Action buttons use theme's `OutlinedButton`/`FilledButton` styles
- [ ] Copy button copies coordinates to clipboard with feedback
- [ ] ≥48dp touch targets on all buttons

---

### Task 1.3: Create `LocationChipWithPanel` Composite Widget
**File**: `lib/widgets/location_chip_with_panel.dart`

Combines chip + panel with expand/collapse state and animation:

```dart
class LocationChipWithPanel extends StatefulWidget {
  // Combines all props from LocationChip + ExpandableLocationPanel
  final bool initiallyExpanded;
  final Duration animationDuration; // default 250ms
}
```

**Acceptance**:
- [ ] Tapping chip toggles panel visibility
- [ ] Smooth height animation (AnimatedCrossFade or AnimatedSize)
- [ ] Animation completes in ≤300ms
- [ ] Collapsed by default

---

## Phase 2: Risk Screen Integration

### Task 2.1: Add Location Chip to RiskBanner
**File**: `lib/widgets/risk_banner.dart`

Modify `RiskBanner` to accept and display a location chip below the risk scale.

**Changes**:
```dart
class RiskBanner extends StatelessWidget {
  // Existing props...
  
  // New: Optional location chip widget (passed in, not created here)
  final Widget? locationChip;
}
```

In `_buildSuccessState()`, add after `RiskScale`:
```dart
// After RiskScale
if (locationChip != null) ...[
  const SizedBox(height: 12.0),
  locationChip!,
],
```

**Acceptance**:
- [ ] Location chip appears below risk scale
- [ ] Chip styling fits within banner's color scheme
- [ ] Existing banner tests still pass

---

### Task 2.2: Update HomeScreen Layout
**File**: `lib/screens/home_screen.dart`

Remove standalone `LocationCard`, pass `LocationChipWithPanel` to `RiskBanner`.

**Changes**:
1. Remove `_buildLocationCard()` call from layout
2. Create `LocationChipWithPanel` in `_buildRiskBanner()`
3. Pass as `locationChip` prop to `RiskBanner`
4. Wire up existing callbacks (`onChangeLocation`, `onCopyLocation`, etc.)

**Acceptance**:
- [ ] Location card no longer appears as standalone widget
- [ ] Location chip visible inside risk banner
- [ ] Tapping chip expands panel with full details
- [ ] "Update location" opens location picker (same as before)
- [ ] "Copy location" copies to clipboard (same as before)
- [ ] "Use GPS" appears when manual location active

---

### Task 2.3: Add Widget Tests for Risk Screen Integration
**File**: `test/widget/risk_banner_location_chip_test.dart`

**Test cases**:
- [ ] Location chip renders inside risk banner
- [ ] Chip shows correct place name / coordinates
- [ ] Tap expands panel
- [ ] Panel shows coordinates, w3w, map preview
- [ ] Action buttons call correct callbacks
- [ ] Accessibility: semantic labels present

---

## Phase 3: Report Screen Refactor

### Task 3.1: Create `EmergencyHeroCard` Widget
**File**: `lib/features/report/widgets/emergency_hero_card.dart`

Combines emergency header + buttons + disclaimer into single card:

```dart
class EmergencyHeroCard extends StatelessWidget {
  final VoidCallback? onCall999;
  final VoidCallback? onCall101;
  final VoidCallback? onCallCrimestoppers;
}
```

**Layout** (from React reference):
1. Icon + "See smoke, flames, or a campfire?" header
2. "If it's spreading or unsafe, call 999..." subtitle
3. 999 Fire Service button (prominent - filled/elevated)
4. Row: 101 Police | Crimestoppers buttons (secondary - outlined)
5. Disclaimer text

**Dependencies**:
- `EmergencyButton` (existing) - reuse for consistent button styling
- `EmergencyContact` enum (existing)

**Acceptance**:
- [ ] Layout matches React screenshot
- [ ] 999 button is visually prominent (filled style)
- [ ] 101/Crimestoppers are secondary (outlined style)
- [ ] Disclaimer text present
- [ ] ≥48dp touch targets
- [ ] Semantic labels on all buttons

---

### Task 3.2: Create `CollapsibleLocationCard` Widget
**File**: `lib/features/report/widgets/collapsible_location_card.dart`

Report-specific location card optimized for emergency UX:

```dart
class CollapsibleLocationCard extends StatefulWidget {
  final LocationDisplayState locationState;
  final VoidCallback? onCopyForCall;
  final VoidCallback? onUpdateLocation;
  final VoidCallback? onUseGps;
  final bool initiallyExpanded; // default: false
}
```

**Layout**:
- Header: "Your location for the call"
- Summary: Place name · GPS badge
- **Always visible**: Copy for your call, Update location buttons
- **Expandable**: Lat/lng, what3words, map preview

**Difference from Risk screen**:
- Copy + Update buttons always visible (not in expanded panel)
- Emergency-focused copy: "Copy for your call"
- Collapsed by default

**Acceptance**:
- [ ] Header reads "Your location for the call"
- [ ] Place name and source badge visible when collapsed
- [ ] Copy + Update buttons visible when collapsed
- [ ] Expand reveals lat/lng, w3w, map
- [ ] Copy formats location for emergency services

---

### Task 3.3: Update ReportFireScreen Layout
**File**: `lib/features/report/screens/report_fire_screen.dart`

Replace existing layout with new hierarchy:

**New layout order**:
1. `EmergencyHeroCard` (combines banner + emergency contacts)
2. `CollapsibleLocationCard` (replaces `ReportFireLocationCard`)
3. `_TipsCard` (unchanged)

**Changes**:
1. Remove `_Banner` widget usage
2. Remove emergency contacts Card (merged into hero)
3. Replace `ReportFireLocationCard` with `CollapsibleLocationCard`
4. Remove `_buildLocationCard()` method
5. Wire up callbacks to controller

**Acceptance**:
- [ ] Emergency hero is first major element
- [ ] Location card is below emergency hero
- [ ] Safety tips card unchanged
- [ ] All emergency calling functionality preserved
- [ ] All location functionality preserved

---

### Task 3.4: Add Widget Tests for Report Screen
**File**: `test/widget/emergency_hero_card_test.dart`
**File**: `test/widget/collapsible_location_card_test.dart`

**EmergencyHeroCard tests**:
- [ ] Renders header and subtitle
- [ ] 999 button calls onCall999
- [ ] 101 button calls onCall101
- [ ] Crimestoppers button calls onCallCrimestoppers
- [ ] Disclaimer text present
- [ ] Accessibility semantics

**CollapsibleLocationCard tests**:
- [ ] Shows place name when collapsed
- [ ] Copy/Update buttons visible when collapsed
- [ ] Expand reveals details
- [ ] Copy callback called with correct data
- [ ] Loading state handled

---

## Phase 4: Cleanup & Polish

### Task 4.1: Update Existing Tests
**Files**: Various test files

Verify and update tests affected by layout changes:
- [ ] `test/widget/screens/home_screen_test.dart`
- [ ] `test/features/report/screens/report_fire_screen_test.dart`
- [ ] `test/widget/location_card_test.dart` (keep for backward compat)
- [ ] `test/widget/risk_banner_test.dart`

---

### Task 4.2: Deprecation Comments
**Files**: `location_card.dart`, `report_fire_location_card.dart`

Add deprecation notices for widgets that may be removed in future:
```dart
/// @Deprecated('Use LocationChipWithPanel instead. Will be removed in v2.0')
```

Keep for now in case of rollback needs.

---

### Task 4.3: Documentation Update
**File**: `.github/copilot-instructions.md`

Add section documenting new components and patterns:
- LocationChip usage
- ExpandableLocationPanel usage
- EmergencyHeroCard usage
- CollapsibleLocationCard usage

---

## Task Summary

| Phase | Task | Priority | Estimated Effort |
|-------|------|----------|------------------|
| 1.1 | LocationChip widget | High | 1-2 hours |
| 1.2 | ExpandableLocationPanel widget | High | 2-3 hours |
| 1.3 | LocationChipWithPanel composite | High | 1 hour |
| 2.1 | Add location chip to RiskBanner | High | 1 hour |
| 2.2 | Update HomeScreen layout | High | 2 hours |
| 2.3 | Risk screen widget tests | Medium | 1-2 hours |
| 3.1 | EmergencyHeroCard widget | High | 2 hours |
| 3.2 | CollapsibleLocationCard widget | High | 2-3 hours |
| 3.3 | Update ReportFireScreen layout | High | 2 hours |
| 3.4 | Report screen widget tests | Medium | 2 hours |
| 4.1 | Update existing tests | Medium | 1-2 hours |
| 4.2 | Deprecation comments | Low | 30 mins |
| 4.3 | Documentation update | Low | 30 mins |

**Total estimated effort**: 16-22 hours

---

## Implementation Order

Recommended sequence for incremental delivery:

```
1. Phase 1 (Foundation)     → Can be reviewed independently
   └── 1.1 → 1.2 → 1.3

2. Phase 2 (Risk Screen)    → First visible change
   └── 2.1 → 2.2 → 2.3

3. Phase 3 (Report Screen)  → Second visible change
   └── 3.1 → 3.2 → 3.3 → 3.4

4. Phase 4 (Cleanup)        → Final polish
   └── 4.1 → 4.2 → 4.3
```

Each phase can be a separate PR if desired for easier review.

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing tests | Run full test suite after each phase |
| Theme inconsistency | Use only theme tokens, no hardcoded values |
| Accessibility regression | Include semantic tests in each task |
| Animation performance | Use standard Flutter animation widgets |
| Rollback needed | Keep old widgets with deprecation notices |

---

## Success Metrics

After implementation:
- [ ] `flutter test` passes with no regressions
- [ ] `flutter analyze` shows no new warnings
- [ ] Risk screen shows risk level first (manual visual check)
- [ ] Report screen shows emergency actions first (manual visual check)
- [ ] All existing location functionality works
- [ ] New widget tests provide coverage for expand/collapse behavior
