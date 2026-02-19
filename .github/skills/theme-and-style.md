# Skill: Theme & Style — WildFire MVP

> Teaches the agent how to write theme-correct, accessible, Material 3 compliant UI code in this project.

## Theme System Overview

The app uses a **three-file theme system**:

| File | Purpose | When to use |
|------|---------|-------------|
| `lib/theme/wildfire_a11y_theme.dart` | Material 3 `ThemeData` (light + dark) | `Theme.of(context)` — always use this for semantic colors |
| `lib/theme/brand_palette.dart` | Brand color tokens (forest, mint, amber) | Direct brand references only; prefer `colorScheme` |
| `lib/theme/risk_palette.dart` | Fire risk level colors (C4 segregated) | Risk indicators ONLY (risk chips, risk banners, risk scale) |

## Color Rules (Critical)

### ✅ DO — Use theme semantic tokens

```dart
final cs = Theme.of(context).colorScheme;

// Surfaces and backgrounds
Container(color: cs.surface)
Container(color: cs.surfaceContainerLow)   // Cards
Container(color: cs.surfaceContainerHighest) // Input fills

// Text
Text('Title', style: TextStyle(color: cs.onSurface))
Text('Secondary', style: TextStyle(color: cs.onSurfaceVariant))

// Primary actions
ElevatedButton(...)  // Automatically themed
FilledButton(...)    // Automatically themed

// Borders and dividers
Border.all(color: cs.outline)
Border.all(color: cs.outlineVariant)  // Subtle borders

// Errors
Text('Error', style: TextStyle(color: cs.error))
```

### ✅ DO — Use BrandPalette for explicit brand tokens

```dart
// Only when you need a specific brand token that isn't in colorScheme
AppBar(backgroundColor: BrandPalette.forest600)  // Already in theme, prefer theme
```

### ✅ DO — Use RiskPalette ONLY for risk indicators

```dart
// Risk-specific widgets (RiskBanner, RiskScale, risk chips)
Container(color: RiskPalette.fromLevel(risk.level))
```

### ❌ NEVER — Use Colors.* directly

```dart
// BAD — will fail color_guard.sh
Container(color: Colors.red)
Text('Error', style: TextStyle(color: Colors.grey))
Icon(Icons.warning, color: Colors.orange)

// EXCEPTION: Colors.transparent is allowed
Container(color: Colors.transparent)
```

### ❌ NEVER — Hardcode hex colors

```dart
// BAD — will fail color_guard.sh
Container(color: Color(0xFF123456))

// GOOD — use palette constants
Container(color: BrandPalette.forest600)
```

## Field Decorations

Use the theme helper for consistent field containers:

```dart
Container(
  decoration: WildfireA11yTheme.fieldDecoration(context),
  child: ...,
)
```

This automatically adapts to light/dark mode with correct fills and borders.

## Corner Radius Tokens

Use the standard tokens — never hardcode radius values:

```dart
// Cards and large containers
BorderRadius.circular(WildfireA11yTheme.radiusCard)      // 16dp

// Buttons and controls
BorderRadius.circular(WildfireA11yTheme.radiusControl)   // 12dp

// Input fields
BorderRadius.circular(WildfireA11yTheme.radiusInput)     // 12dp
```

## Accessibility Requirements (C3)

### Touch Targets

All interactive elements must be ≥44dp. The theme enforces this for buttons, but custom widgets must comply:

```dart
// GOOD — explicit minimum size
SizedBox(
  height: 44,
  child: InkWell(
    onTap: () {},
    child: ...,
  ),
)

// GOOD — Material chip (theme sets padding for ≥44dp)
FilterChip(label: Text('Option'), onSelected: (_) {})
```

### Semantic Labels

All interactive or informational widgets must have screen reader support:

```dart
// GOOD — Semantics wrapper
Semantics(
  label: 'Fire risk level: moderate',
  child: RiskChip(level: RiskLevel.moderate),
)

// GOOD — built-in semantics
Icon(Icons.location_on, semanticLabel: 'Location')
Image.asset('fire.png', semanticLabel: 'Active fire indicator')

// GOOD — button already has semantics via child text
ElevatedButton(
  onPressed: () {},
  child: Text('Check Risk'),  // Screen reader reads this
)
```

### Contrast Ratios

All text must meet WCAG 2.1 AA (≥4.5:1 normal text, ≥3:1 large text/UI). Using `colorScheme` tokens guarantees compliance — only check manually if using `BrandPalette` directly.

## Dark Mode

All widgets must work in both light and dark mode:

```dart
// GOOD — adapts automatically
final cs = Theme.of(context).colorScheme;
Container(color: cs.surface)  // offWhite in light, forest700 in dark

// GOOD — check brightness when needed
final isDark = Theme.of(context).brightness == Brightness.dark;

// BAD — hardcoded for one mode only
Container(color: Colors.white)  // Broken in dark mode
```

## Material 3 Component Patterns

Prefer Material 3 components — they're already themed:

```dart
// Buttons (all ≥44dp, 12dp radius via theme)
FilledButton(onPressed: () {}, child: Text('Primary CTA'))
OutlinedButton(onPressed: () {}, child: Text('Secondary'))
TextButton(onPressed: () {}, child: Text('Tertiary'))

// Chips (already have padding for ≥44dp)
FilterChip(label: Text('Filter'), onSelected: (_) {})
ChoiceChip(label: Text('Choice'), selected: true, onSelected: (_) {})

// Cards (16dp radius, subtle border via theme)
Card(child: ...)

// SnackBars (forest900 bg, mint400 action, already themed)
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message'), action: SnackBarAction(label: 'Undo', onPressed: () {})),
)

// NavigationBar (forest700 bg, mint400 indicator, already themed)
// Defined in app.dart ShellRoute — don't recreate
```

## Data Display Requirements (C4)

Every screen that shows data must include:

1. **Timestamp**: "Last updated: [time]" — visible to user
2. **Source label**: chip or badge showing data origin (EFFIS, SEPA, Cache, Mock)
3. **Freshness**: visual indicator if data is cached or stale

```dart
// Example: timestamp chip
IncidentsTimestampChip(lastUpdated: state.lastUpdated)

// Example: source chip
MapSourceChip(source: state.freshness)
```

## Anti-Patterns (Will Fail CI)

| Pattern | Problem | Fix |
|---------|---------|-----|
| `Colors.red` | Ad-hoc color | `cs.error` |
| `Color(0xFF...)` | Hardcoded hex | Use palette constant |
| `BorderRadius.circular(8)` | Magic number | `WildfireA11yTheme.radiusControl` |
| `SizedBox(height: 32)` for buttons | Too small | `minimumSize: Size(64, 44)` |
| `Text('Error')` without contrast | May fail WCAG | Use `cs.error` on `cs.surface` |
| Missing `Semantics` on icons | Inaccessible | Add `semanticLabel` |
| `Colors.white` background | Breaks dark mode | `cs.surface` |
