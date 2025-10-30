---
title: UX Design Cues
status: active
last_updated: 2025-10-30
category: reference
subcategory: design
related:
  - accessibility-statement.md
  - privacy-compliance.md
---

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

