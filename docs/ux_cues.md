# WildFire Prototype — UX Cues

## Visual Language
- **Primary indicator**: Risk level displayed as text + background color block.
- **Color Palette**: Only use official wildfire risk scale (see `scripts/allowed_colors.txt`).
  - Very Low → `#00B3FF`
  - Low → `#2ECC71`
  - Moderate → `#F1C40F`
  - High → `#E67E22`
  - Very High → `#E74C3C`
  - Extreme → `#C0392B`
- **Brand accent**: Deep forest green `#0B3D2E` for titles/logos.
- **Neutrals**: Greys/whites as listed in allowed palette.

## Required Elements
- **Last Updated** timestamp must always be visible when data is displayed.
- **Source Label** chip/badge must indicate origin (`EFFIS`, `SEPA`, `Cache`, `Mock`).
- **Cached State**: badge explicitly says `Cached` when TTL data is shown.
- **Error State**: message + Retry button (≥44dp).
- **Loading State**: skeleton shimmer or progress indicator.

## Accessibility
- Interactive elements (Retry, manual location entry, etc.) must:
  - Be at least 44dp target size.
  - Have semantic labels (e.g., "Retry fetching wildfire risk").
- Banner text must announce level and freshness: e.g., "Current wildfire risk: High, updated 10 minutes ago".
- Support dark mode (contrast minimum 4.5:1 for body text).

## UX Principles
- **Fail visible, not silent** → always show some state (loading, error, cached).
- **Transparency builds trust** → timestamp + source visible at all times.
- **Consistency** → single-source colors and text, no ad hoc hex values.
- **Simplicity** → minimal copy; large, clear typography.

## References
- Constitution v1.0 (Trust & Transparency gate C4)
- `scripts/allowed_colors.txt`
- Planned: `lib/theme/risk_palette.dart`
- Spec A3 — RiskBanner

