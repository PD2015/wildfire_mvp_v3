---
title: UX Design Cues
status: active
last_updated: 2025-11-14
category: reference
subcategory: design
related:
  - accessibility-statement.md
  - privacy-compliance.md
---

# WildFire Prototype — UX Cues

## Color System Architecture

### Two-Palette System
WildFire uses a **dual-palette architecture** to maintain clear semantic separation:

| Palette | Purpose | Components | File |
|---------|---------|------------|------|
| **BrandPalette** | App chrome, navigation, surfaces, backgrounds, generic UI states | AppBar, NavigationBar, Buttons, TextFields, Cards, Chips, SnackBars, Dialogs | `lib/theme/brand_palette.dart` |
| **RiskPalette** | Fire risk visualization **ONLY** | RiskBanner, RiskResultChip, risk-specific indicators | `lib/theme/risk_palette.dart` |

### BrandPalette (App Chrome)
Scottish-themed professional colors with WCAG 2.1 AA compliance:

```dart
// Forest gradient (primary brand identity)
forest900: 0xFF0D4F48  // Deep forest (primary dark)
forest800: 0xFF165E56
forest700: 0xFF1F6E63
forest600: 0xFF287D71  // Primary brand color
forest500: 0xFF318D7F
forest400: 0xFF39928A  // Primary light

// Accent colors
mint400: 0xFF64C8BB    // Success, positive states
amber500: 0xFFF5A623   // Warning, attention states

// Neutral surfaces
offWhite: 0xFFF5F5F5   // Light mode background
neutralGrey: 0xFF2C2C2C // Dark mode background

// On-colors (text/icons on colored backgrounds)
onDarkHigh: 0xFFFFFFFF      // 100% white
onDarkMedium: 0xB3FFFFFF    // 70% white
onLightHigh: 0xFF111111     // Near-black
onLightMedium: 0x99000000   // 60% black
```

**Contrast Ratios** (all ≥4.5:1 for text, ≥3:1 for UI components):
- `forest600` on `offWhite`: 5.2:1 ✅
- `onDarkHigh` on `forest900`: 11.3:1 ✅
- `mint400` on `forest900`: 4.6:1 ✅
- `amber500` on `forest900`: 7.1:1 ✅

### RiskPalette (Risk Visualization Only)
Official wildfire risk scale colors (preserved from original design):

```dart
// Risk levels (same as scripts/allowed_colors.txt)
veryLow: 0xFF00B3FF     // #00B3FF
low: 0xFF2ECC71         // #2ECC71
moderate: 0xFFF1C40F    // #F1C40F
high: 0xFFE67E22        // #E67E22
veryHigh: 0xFFE74C3C    // #E74C3C
extreme: 0xFFC0392B     // #C0392B
```

**Constitutional Compliance (C4)**:
- RiskPalette colors **ONLY** used in risk widgets: `RiskBanner`, `RiskResultChip`
- All other UI components use `BrandPalette` or `theme.colorScheme.*`
- Enforced by `scripts/verify_no_adhoc_colors.sh` (C1 gate)

### WildfireA11yTheme (Material 3 Theme System)
Implements Material 3 `ColorScheme` with BrandPalette tokens:

```dart
// Light theme ColorScheme mapping
primary: BrandPalette.forest600           // Primary actions, AppBar
onPrimary: BrandPalette.onDarkHigh        // Text/icons on primary
secondary: BrandPalette.forest500         // Secondary actions
tertiary: BrandPalette.amber500           // Accent actions, warnings
error: Colors.red.shade700                // Error states
surface: BrandPalette.offWhite            // Card/sheet backgrounds
onSurface: BrandPalette.onLightHigh       // Text on surfaces
```

**Usage in Widgets**:
```dart
// ✅ CORRECT: Use theme.colorScheme for app chrome
Icon(Icons.home, color: Theme.of(context).colorScheme.primary)
Text('Welcome', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))

// ✅ CORRECT: Use RiskPalette ONLY for risk widgets
Container(color: RiskPalette.forLevel(RiskLevel.high)) // In RiskBanner only

// ❌ WRONG: Ad-hoc Colors.* violates C4
Icon(Icons.home, color: Colors.green) // Use colorScheme.primary instead
```

## Visual Language
- **Primary indicator**: Risk level displayed as text + background color block (RiskPalette only)
- **Color Palette**: Two-tier system (see Color System Architecture above)
  - **BrandPalette**: All app chrome (navigation, buttons, surfaces)
  - **RiskPalette**: Fire risk visualization only (RiskBanner, RiskResultChip)
- **Brand accent**: Forest green gradient (forest900 → forest400) for professional Scottish theme
- **Neutrals**: offWhite (light mode), neutralGrey (dark mode)
- **WCAG 2.1 AA Compliance**: All text ≥4.5:1 contrast, UI components ≥3:1 contrast

## Theme System (Material 3)
- **Light Theme**: `WildfireA11yTheme.light` - forest600 primary, offWhite surfaces
- **Dark Theme**: `WildfireA11yTheme.dark` - forest400 primary, neutralGrey surfaces
- **System Preference**: Automatically detects via `MediaQuery.platformBrightness`
- **Color Access**: Use `Theme.of(context).colorScheme.*` in widgets
- **Component Theming**: ElevatedButton, OutlinedButton, TextButton, InputDecoration, Chip, SnackBar
- **Touch Targets**: All interactive elements ≥44dp (iOS) / ≥48dp (Android)

## Required Elements
- **Last Updated** timestamp must always be visible when data is displayed, using format "Updated X ago" (e.g., "Updated 5 min ago", "Updated 2 hours ago").
- **Source Label** chip/badge must indicate origin (`EFFIS`, `SEPA`, `Cache`, `Mock`) as a rounded chip with contrasting background.
- **Cached State**: badge explicitly shows "Cached" when cached data is displayed (using CachedBadge component).
- **Error State**: descriptive message + Retry button (≥44dp) when onRetry callback provided.
- **Loading State**: circular progress indicator with "Loading wildfire risk..." text.

## Accessibility
- Interactive elements (Retry button, etc.) must:
  - Be at least 44dp target size (validated in widget tests).
  - Have semantic labels (e.g., "Retry loading wildfire risk data").
- Banner semantic label must announce: "Current wildfire risk {LEVEL}, Updated {relative_time}, data from {SOURCE}".
- Loading state semantic label: "Loading wildfire risk data".
- Support dark mode (contrast minimum 4.5:1 for body text).

## UX Principles
- **Fail visible, not silent** → always show some state (loading, error, cached).
- **Transparency builds trust** → timestamp + source visible at all times.
- **Consistency** → single-source colors and text, no ad hoc hex values.
- **Simplicity** → minimal copy; large, clear typography.

## Widget Integration (RiskBanner Implementation)
- **Main Display Text**: "Wildfire Risk: {LEVEL}" where {LEVEL} is uppercase risk level name
- **Time Format**: formatRelativeTime() produces "Just now", "2 min ago", "1 hour ago", "3 days ago"
- **Source Chip**: Rounded chip with semi-transparent background showing source name
- **Cached Badge**: Uses CachedBadge component (`lib/widgets/badges/cached_badge.dart`) with semantic label "Cached result"
- **State Management**: Accepts RiskBannerState (Loading/Success/Error) - no internal data fetching
- **Error Handling**: Shows cached data with error indication when available, otherwise shows retry UI

## Constitutional Gate Compliance
- **C1 (Code Quality)**: Widget tests validate all states, golden tests prevent visual regressions
- **C3 (Accessibility)**: ≥44dp touch targets verified, semantic labels tested programmatically  
- **C4 (Transparency)**: Source attribution and timestamps always visible when data displayed
- **C5 (Resilience)**: Error states tested, cached fallback behavior verified, retry mechanisms implemented

## References
- Constitution v1.0.0 (Trust & Transparency gate C4)
- `scripts/allowed_colors.txt`
- `lib/theme/risk_palette.dart` (implemented)
- Spec A3 — RiskBanner (tasks T001-T004 complete)

