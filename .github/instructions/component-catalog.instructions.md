# WildFire Component Catalog

> **Auto-attached to**: `lib/widgets/**`, `lib/features/**/widgets/**`, `lib/screens/**`, `lib/theme/**`
>
> When implementing or modifying UI code, you MUST use existing shared widgets
> and theme tokens from this catalog. Never create private duplicates of these
> components. If a widget doesn't exist for your need, propose adding it to
> `lib/widgets/` as a shared component.

---

## Shared Widgets (`lib/widgets/`)

### SectionHeader
**File**: `lib/widgets/section_header.dart`
**Purpose**: Uppercase section title for grouped lists (settings, help, about screens).

```dart
const SectionHeader({
  required String title,     // Auto-uppercased
  Color? color,              // Defaults to colorScheme.primary
})
```
- ✅ `Semantics(header: true)` for screen reader heading navigation
- Used in: `help_info_screen.dart`, `settings_screen.dart`

---

### AppNavigationTile
**File**: `lib/widgets/app_navigation_tile.dart`
**Purpose**: Consistent navigation ListTile with icon, title, subtitle, and trailing chevron.

```dart
const AppNavigationTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  bool enabled = true,       // false → 50% alpha, disabled tap
  Color? iconColor,          // Defaults to onSurfaceVariant
})
```
- Used in: `help_info_screen.dart`, `settings_screen.dart`, `about_screen.dart`, `about_settings_screen.dart`

---

### AdaptiveColorCalculator
**File**: `lib/widgets/adaptive_color_calculator.dart`
**Purpose**: Calculates accessible color sets based on parent background luminance.

```dart
// Utility class — not a widget
static AdaptiveColors getColors({
  required Color parentBackgroundColor,
  bool embeddedInRiskBanner = false,
})

// Returns:
typedef AdaptiveColors = ({
  Color surface, Color text, Color textMuted, Color icon, Color divider,
});
```
- Two modes: **risk banner** (white-on-translucent) and **default** (luminance threshold 0.5)
- C4: Uses `BrandPalette` tokens exclusively — no ad-hoc hex colors
- Used in: `LocationChip`, `ExpandableLocationPanel`

---

### RiskBanner
**File**: `lib/widgets/risk_banner.dart`
**Purpose**: Primary wildfire risk display card consuming `RiskBannerState`.

```dart
const RiskBanner({
  required RiskBannerState state,  // sealed: Loading | Success | Error
  VoidCallback? onRetry,
  String? locationLabel,
  RiskBannerConfig config = const RiskBannerConfig(),
  Widget? locationChip,            // Slot for LocationChipWithPanel
})
```
- Constants: `kBannerRadius = 16.0`, `kBannerPadding = EdgeInsets.all(16.0)`, `kBannerElevation = 2.0`
- C3: `minHeight: 44.0` constraint, `Semantics` labels on all states

---

### RiskScale
**File**: `lib/widgets/risk_scale.dart`
**Purpose**: Horizontal bar chart showing all six risk levels with current level highlighted.

```dart
const RiskScale({
  required RiskLevel currentLevel,
  required Color textColor,
  double barHeight = 8.0,
  double barSpacing = 4.0,
  bool showLabels = true,
  VoidCallback? onTap,
})
```
- Active level: full opacity + 1.25× height + border; others: 65% opacity
- When tappable: `InkWell` with `Semantics(button: true)`, ≥44dp min height

---

### RiskGuidanceCard
**File**: `lib/widgets/risk_guidance_card.dart`
**Purpose**: Scotland-specific wildfire safety guidance based on current risk level.

```dart
const RiskGuidanceCard({
  RiskLevel? level,
  RiskGuidance? guidance,  // Falls back to ScotlandRiskGuidance.getGuidance(level)
})
```
- 12px rounded corners, 2px border colored by risk level
- Emergency footer button navigates to `/report`

---

### LocationChip
**File**: `lib/widgets/location_chip.dart`
**Purpose**: Compact tappable chip showing location summary: `📍 Name · Source ˅`

```dart
const LocationChip({
  required String locationName,
  LocationSource? locationSource,
  required Color parentBackgroundColor,
  VoidCallback? onTap,
  bool isExpanded = false,
  bool isLoading = false,
  String? coordinates,
  bool embeddedInRiskBanner = false,
})
```
- Uses `AdaptiveColorCalculator` for contrast on risk-colored backgrounds
- Source: GPS / Manual / Cached / Default (displayed inline after dot separator)

---

### LocationChipWithPanel
**File**: `lib/widgets/location_chip_with_panel.dart`
**Purpose**: Composite of `LocationChip` + `ExpandableLocationPanel` with expand/collapse animation.

```dart
const LocationChipWithPanel({
  required String locationName,
  required Color parentBackgroundColor,
  String? coordinatesLabel,
  String? what3words,
  bool isWhat3wordsLoading = false,
  String? formattedLocation,
  bool isGeocodingLoading = false,
  String? staticMapUrl,
  bool isMapLoading = false,
  LocationSource? locationSource,
  bool isLoading = false,
  VoidCallback? onChangeLocation,
  VoidCallback? onUseGps,
  VoidCallback? onCopyWhat3words,
  VoidCallback? onCopyCoordinates,
  bool showMapPreview = true,
  bool showActions = true,
  bool initiallyExpanded = false,
  ValueChanged<bool>? onExpandedChanged,
  bool embeddedInRiskBanner = false,
})
```
- 250ms slide + fade animation with `Curves.easeInOut`

---

### ExpandableLocationPanel
**File**: `lib/widgets/expandable_location_panel.dart`
**Purpose**: Full location details panel (coordinates, what3words, map preview, actions).

```dart
const ExpandableLocationPanel({
  required Color parentBackgroundColor,
  String? formattedLocation,
  String? coordinatesLabel,
  String? what3words,
  String? staticMapUrl,
  LocationSource? locationSource,
  VoidCallback? onChangeLocation,
  VoidCallback? onUseGps,
  VoidCallback? onCopyWhat3words,
  VoidCallback? onCopyCoordinates,
  VoidCallback? onClose,
  bool embeddedInRiskBanner = false,
  // + loading flags: isGeocodingLoading, isWhat3wordsLoading, isMapLoading
  // + toggles: showMapPreview, showActions
})
```
- Uses `AdaptiveColorCalculator` for color consistency

---

### LocationCard
**File**: `lib/widgets/location_card.dart`
**Purpose**: Enhanced location card with progressive enhancement (basic → what3words → map preview).

```dart
const LocationCard({
  required String? coordinatesLabel,
  required String subtitle,
  bool isLoading = false,
  VoidCallback? onChangeLocation,
  LocationSource? locationSource,
  String? what3words,
  String? formattedLocation,
  String? staticMapUrl,
  VoidCallback? onCopyWhat3words,
  VoidCallback? onUseGps,
  // + loading flags: isWhat3wordsLoading, isGeocodingLoading
})
```
- `_getLocationSourceIcon()` returns distinct icon per `LocationSource`

---

### LocationMiniMapPreview
**File**: `lib/widgets/location_mini_map_preview.dart`
**Purpose**: Static Google Maps API image preview (loading spinner, error state, tap overlay).

```dart
const LocationMiniMapPreview({
  required String? staticMapUrl,
  bool isLoading = false,
  VoidCallback? onTap,
  double height = 140,
})
```

---

### ManualLocationDialog
**File**: `lib/widgets/manual_location_dialog.dart`
**Purpose**: Coordinate entry dialog with real-time validation.

```dart
const ManualLocationDialog({super.key})

// Usage:
final location = await ManualLocationDialog.show(context);
```
- Test keys: `Key('latitude_field')`, `Key('longitude_field')`, `Key('save_button')`, `Key('cancel_button')`

---

### FireDetailsBottomSheet
**File**: `lib/widgets/fire_details_bottom_sheet.dart`
**Purpose**: V2 draggable bottom sheet for fire incident/hotspot/burnt area details.

```dart
const FireDetailsBottomSheet({
  FireIncident? incident,
  LatLng? userLocation,
  VoidCallback? onClose,
  VoidCallback? onRetry,
  FireDataDisplayType displayType = FireDataDisplayType.incident,
  Hotspot? hotspot,
  BurntArea? burntArea,
  bool isLoading = false,
  String? errorMessage,
  VoidCallback? onLearnMore,
  bool isManualLocation = false,
})

// Prefer factory constructors:
FireDetailsBottomSheet.fromHotspot(required Hotspot hotspot, ...)
FireDetailsBottomSheet.fromBurntArea(required BurntArea burntArea, ...)
```
- `DraggableScrollableSheet`: initial 0.45, min 0.2, max 0.85

---

### AppBottomNav
**File**: `lib/widgets/bottom_nav.dart`
**Purpose**: Bottom navigation bar (Fire Risk, Map, Report Fire).

```dart
const AppBottomNav({required String currentPath})
```
- Destinations: Fire Risk (`Icons.warning_amber`), Map (`Icons.map`), Report Fire (`Icons.local_fire_department`)

---

### AppBarActions
**File**: `lib/widgets/app_bar_actions.dart`
**Purpose**: Settings and Help icon buttons for AppBar.

```dart
const AppBarActions({
  VoidCallback? onSettingsTap,
  VoidCallback? onHelpTap,
})
```
- Icons toggle filled/outlined based on current route
- C3: `minimumSize: Size(48, 48)` on both buttons

---

### CachedBadge
**File**: `lib/widgets/badges/cached_badge.dart`
**Purpose**: Small pill badge indicating cached data.

```dart
const CachedBadge({super.key})
```
- `RiskPalette.midGray` @ 80% background, `RiskPalette.white` text, 12px

---

## Map Feature Widgets (`lib/features/map/widgets/`)

These are map-specific and should NOT be duplicated outside the map feature.

| Widget | Purpose |
|--------|---------|
| `FireDataModeToggle` | Segmented toggle: Hotspots ↔ Burnt Areas |
| `MapSourceChip` | Data freshness indicator (LIVE · DEMO · OFFLINE · CACHED) |
| `HotspotClusterMarker` | Static builder for clustered hotspot map markers |
| `HotspotSquareBuilder` | Static builder for VIIRS ~375m² square polygon overlays |
| `IncidentsTimestampChip` | "Incidents updated X ago" with auto-refresh timer |
| `MapTypeSelector` | Popup menu: terrain/satellite/hybrid/normal |
| `MapZoomControls` | Theme-aware zoom +/- buttons |
| `TimeFilterChips` | Context-sensitive: Today/This Week (hotspots) or This Season/Last Season (burnt areas) |

---

## Theme Tokens

### Design Radii (from `WildfireA11yTheme`)
| Token | Value | Use |
|-------|-------|-----|
| `radiusCard` | `16.0` | Cards, banners, large containers |
| `radiusControl` | `12.0` | Buttons, chips, controls |
| `radiusInput` | `12.0` | Text fields, inputs |

### BrandPalette (`lib/theme/brand_palette.dart`)
| Token | Purpose |
|-------|---------|
| `forest600` | Primary color (light mode) |
| `forest400` | Primary color (dark mode) |
| `mint400` | Secondary accent |
| `amber500` | Tertiary accent |
| `offWhite` | Light mode surface |
| `outline` | UI component outlines |
| `onDarkHigh` / `onDarkMedium` / `onDarkLow` | Text on dark backgrounds |
| `onLightHigh` / `onLightMedium` | Text on light backgrounds |
| `onColorFor(Color bg)` | Helper: returns appropriate text color for any background |

### RiskPalette (`lib/theme/risk_palette.dart`)
| Token | Risk Level |
|-------|------------|
| `veryLow` | 🟢 Green |
| `low` | 🟡 Light green |
| `moderate` | 🟡 Yellow |
| `high` | 🟠 Orange |
| `veryHigh` | 🔴 Red |
| `extreme` | 🔴 Dark red |
| `fromLevel(String)` | Maps string → Color |

---

## Rules for AI Agents

1. **ALWAYS check this catalog before creating a new widget.** If a shared widget exists for your need, use it.

2. **NEVER create private `_SectionHeader`, `_NavigationTile`, `_LegalTile` etc.** Use `SectionHeader` and `AppNavigationTile` instead.

3. **NEVER use ad-hoc hex colors.** Use `BrandPalette`, `RiskPalette`, or `Theme.of(context).colorScheme` tokens.

4. **NEVER hardcode border radius.** Use `radiusCard` (16), `radiusControl` (12), or `radiusInput` (12) from `WildfireA11yTheme`.

5. **For contrast on dynamic backgrounds**, use `AdaptiveColorCalculator.getColors()` — never compute luminance manually.

6. **For location source icons**, use `LocationCard._getLocationSourceIcon()` pattern — never hardcode icon assignments.

7. **Touch targets must be ≥44dp (iOS) / ≥48dp (Android).** Use `minimumSize: Size(48, 48)` on buttons.

8. **All interactive elements need `Semantics` labels.** Headers need `Semantics(header: true)`.

9. **When adding a new shared widget**, add it to `lib/widgets/`, update this catalog, and add tests in `test/widget/`.

10. **Map widgets stay in `lib/features/map/widgets/`** — they are feature-specific, not app-wide shared.
