---
title: Map Tooltip Visual Examples
status: active
last_updated: 2025-11-24
category: reference
subcategory: map-features
related:
  - MAP_DATA_DISPLAY_REVIEW.md
  - lib/features/map/screens/map_screen.dart
---

# Map Tooltip Visual Examples

Visual examples of the enhanced InfoWindow tooltips after the November 24, 2025 improvements.

## Before (Old Format)

```
┌─────────────────────────────┐
│ Edinburgh - Holyrood Park  │
│ MODERATE - 12.5 ha         │
└─────────────────────────────┘
```

**Issues**:
- No data source shown
- No timestamp/freshness
- Terse format ("MODERATE - 12.5 ha")
- "?" shown for unknown area

## After (New Format)

### Example 1: Full Data Available
```
┌───────────────────────────────────────┐
│ Edinburgh - Holyrood Park            │
│ Risk: Moderate • Burnt area: 12.5 ha │
│ Source: MOCK • 2h ago                │
└───────────────────────────────────────┘
```

### Example 2: Unknown Area
```
┌───────────────────────────────────────┐
│ Glasgow - Campsie Fells              │
│ Risk: High • Burnt area: Unknown     │
│ Source: EFFIS • 15m ago              │
└───────────────────────────────────────┘
```

### Example 3: No Description (Uses Fire ID)
```
┌───────────────────────────────────────┐
│ Fire #ire_001                        │
│ Risk: Low • Burnt area: 5.7 ha       │
│ Source: Cached • 5d ago              │
└───────────────────────────────────────┘
```

### Example 4: Recent Fire
```
┌───────────────────────────────────────┐
│ Aviemore - Cairngorms                │
│ Risk: Low • Burnt area: 5.7 ha       │
│ Source: SEPA • Just now              │
└───────────────────────────────────────┘
```

## Improvements

### ✅ User-Friendly Labels
- **Before**: `MODERATE - 12.5 ha`
- **After**: `Risk: Moderate • Burnt area: 12.5 ha`

Clear labels help users understand what each value represents.

### ✅ Data Source Transparency (C4 Compliance)
- **Before**: No source shown (C4 violation)
- **After**: `Source: MOCK` (or EFFIS/SEPA/Cached)

Users can now assess data reliability at a glance.

### ✅ Freshness Indicator
- **Before**: No timestamp (C4 violation)
- **After**: `2h ago`, `Just now`, `5d ago`

Relative timestamps help users judge data currency.

### ✅ Consistent Unknown Handling
- **Before**: Shows `?` for unknown values
- **After**: Shows `Unknown` (professional, consistent)

### ✅ Better Title Fallback
- **Before**: `Fire Incident #mock_fire_001` (long UUID)
- **After**: `Fire #ire_001` (shortened, readable)

## Technical Implementation

### Helper Methods

```dart
// Title with smart fallback
String _buildInfoTitle(FireIncident incident) {
  if (incident.description?.isNotEmpty == true) {
    return incident.description!;
  }
  final shortId = incident.id.length > 7
      ? incident.id.substring(incident.id.length - 7)
      : incident.id;
  return 'Fire #$shortId';
}

// Two-line snippet with all data
String _buildInfoSnippet(FireIncident incident) {
  final intensityLabel = _formatIntensity(incident.intensity);
  final areaText = incident.areaHectares != null
      ? '${incident.areaHectares!.toStringAsFixed(1)} ha'
      : 'Unknown';
  final sourceLabel = _formatDataSource(incident.source);
  final freshnessText = _formatFreshness(incident.timestamp);

  return 'Risk: $intensityLabel • Burnt area: $areaText\n'
         'Source: $sourceLabel • $freshnessText';
}
```

### Relative Time Formatting

| Age | Display |
|-----|---------|
| < 1 minute | "Just now" |
| 1-59 minutes | "15m ago" |
| 1-23 hours | "2h ago" |
| 1+ days | "5d ago" |

## Testing Checklist

When testing on device/simulator:

- [ ] Tap each marker and verify tooltip appears
- [ ] Check title shows description or shortened ID
- [ ] Verify Line 1 shows risk and area
- [ ] Verify Line 2 shows source and freshness
- [ ] Test with all data sources (MOCK, EFFIS, SEPA, Cached)
- [ ] Test with unknown area (should show "Unknown")
- [ ] Test with various timestamps (Just now, minutes, hours, days)
- [ ] Verify bullet separator (•) renders correctly
- [ ] Check tooltip is readable on mobile (font size, spacing)

## Accessibility Notes

**Screen Reader Behavior**:
- Title is announced first: "Edinburgh - Holyrood Park"
- Snippet is announced as continuous text: "Risk: Moderate, Burnt area: 12.5 hectares, Source: MOCK, 2 hours ago"

**Visual Accessibility**:
- Two-line format improves readability on small screens
- Clear labels reduce cognitive load
- Bullet separator (•) provides visual grouping

## Related Documentation

- [Map Data Display Review](MAP_DATA_DISPLAY_REVIEW.md) - Comprehensive analysis
- [Implementation Commit](https://github.com/PD2015/wildfire_mvp_v3/commit/2107e41) - Code changes

---

**Last Updated**: November 24, 2025
**Status**: Active
**Feature**: Map InfoWindow Tooltips
**Constitutional Compliance**: ✅ C4 (Transparency)
