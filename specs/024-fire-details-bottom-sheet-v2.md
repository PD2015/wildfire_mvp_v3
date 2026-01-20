# Plan: Create FireDetailsBottomSheetV2 Widget

Create a user-friendly V2 bottom sheet in a new file with feature flag toggle, summary-first layout, type-specific content ordering, and plain language labels. Maintains existing theme/styling patterns.

## Steps

### 1. Create new file `lib/widgets/fire_details_bottom_sheet_v2.dart`
- Copy existing structure, maintain factory constructors (`fromHotspot`, `fromBurntArea`)
- Same public API for drop-in replacement
- Use `Theme.of(context)` tokens throughout (no hardcoded colors/styles)

### 2. Add feature flag in `lib/config/feature_flags.dart`
- `static const useBottomSheetV2 = bool.fromEnvironment('USE_BOTTOM_SHEET_V2', defaultValue: false);`
- Toggle via `--dart-define=USE_BOTTOM_SHEET_V2=true`

### 3. Update MapScreen in `lib/features/map/screens/map_screen.dart`
- Import both V1 and V2 widgets
- Conditionally render based on `FeatureFlags.useBottomSheetV2`

### 4. Make header dynamic in `_buildHeader()`
- Hotspot: "Hotspot details" + `Icons.whatshot`
- Burnt area: "Burnt area details" + `Icons.layers`
- Incident: "Fire details" + `Icons.local_fire_department`

### 5. Create `_buildSummaryCard()` with type-specific ordering

**Hotspot order** (emphasis on recency and proximity):
- Status: "Possible active fire"
- Detected: "X ago (HH:MM UK time)"
- Distance from you (if GPS)
- Satellite confidence
- "Learn more" → `/help/doc/hotspots`

**Burnt area order** (emphasis on scale and historical context):
- Status: "Burnt area (past fire)"
- Estimated area: "X ha"
- Fire season/year
- Date detected
- Distance from you (if GPS, optional)
- "Learn more" → `/help/doc/burnt-area`

### 6. Rewrite `_buildEducationalLabel()` with plain language
- Hotspot: "A satellite detected unusual heat here. It could be wildfire, controlled burning, or another heat source."
- Burnt area: "This outline shows ground that appears burned from a fire earlier this season. It does not confirm an active fire right now."

### 7. Create `_buildMoreDetailsSection()` using `ExpansionTile`
- Collapsed by default, contains: Fire ID, coordinates, sensor, FRP, confidence, simplification notice, land cover bars
- Reuse existing `_InfoSection` pattern inside

### 8. Rename jargon labels with explanatory subtitles
- "Heat output (FRP)", "Satellite confidence", "Coordinates", "Satellite sensor"

### 9. Update `_formatRelativeTime()` to "X hours ago (14:30 UK time)"
- Use `DateTime.toLocal()` for BST/GMT handling

### 10. Add optional `onLearnMore` callback with default navigation
- Hybrid approach: `onLearnMore ?? () => context.push('/help/doc/${_helpDocId}')`
- Defaults to `hotspots` or `burnt-area` doc based on type

### 11. Add first-use map tip in `MapScreen`
- Check `SharedPreferences` for `'map_tip_shown'` flag
- Show themed SnackBar: "Tip: Tap a marker to view fire details"

### 12. Track cleanup as follow-up task
- After V2 validation: delete V1 file, remove flag, rename V2 → `FireDetailsBottomSheet`
- Add TODO comment in `feature_flags.dart` referencing cleanup

## Files Changed

| File | Change |
|------|--------|
| `lib/widgets/fire_details_bottom_sheet_v2.dart` | **New** — V2 widget implementation |
| `lib/config/feature_flags.dart` | Add `useBottomSheetV2` flag |
| `lib/features/map/screens/map_screen.dart` | Conditional V1/V2 rendering + SnackBar tip |

## Styling Guidelines (enforced throughout)

- **No hardcoded colors**: Use `colorScheme.primary`, `colorScheme.surfaceContainerHigh`, etc.
- **No hardcoded text styles**: Use `textTheme.titleMedium`, `textTheme.bodySmall`, etc.
- **Touch targets**: Minimum 48dp (use existing `constraints: BoxConstraints(minWidth: 48, minHeight: 48)`)
- **Semantics**: Wrap interactive elements in `Semantics` widgets
- **Reuse existing patterns**: `_InfoSection`, `_buildDetailRow()`, `MapSourceChip`
- **Corner radii**: Use existing 12dp/24dp tokens from current implementation

## Data Presentation Order Summary

| Position | Hotspot | Burnt Area |
|----------|---------|------------|
| **Header** | "Hotspot details" + whatshot icon | "Burnt area details" + layers icon |
| **Banner** | "Possible active fire" explanation | "Burnt area (past fire)" explanation |
| **Summary 1** | Detected time (relative + UK) | Estimated area (ha) |
| **Summary 2** | Distance from you | Fire season/year |
| **Summary 3** | Satellite confidence | Date detected |
| **Summary 4** | — | Distance (optional) |
| **Learn more** | Link to hotspots help | Link to burnt-area help |
| **Collapsed** | ID, coords, sensor, FRP | ID, coords, sensor, land cover, simplification |
| **Footer** | Safety text | Safety text |

## Testing Commands

```bash
# Run with V2 enabled
flutter run --dart-define=USE_BOTTOM_SHEET_V2=true

# Run with V1 (default)
flutter run

# Run tests
flutter test
```

## Follow-up Tasks

- [ ] After V2 validation: Delete V1 file (`fire_details_bottom_sheet.dart`)
- [ ] Remove `useBottomSheetV2` feature flag
- [ ] Rename V2 → `FireDetailsBottomSheet`
- [ ] Update all imports
