# Test Regions for EFFIS Fire Data

This document describes how to test the map with different geographic regions that typically have varying levels of wildfire activity.

## Overview

The `TEST_REGION` environment variable allows you to test EFFIS integration with regions known for wildfire activity. This is useful for:
- Verifying EFFIS WFS integration works correctly
- Testing with real fire data (when available)
- Demonstrating the app in different geographic contexts

## Available Test Regions

| Region | Coordinates | Typical Fire Season | Notes |
|--------|-------------|---------------------|-------|
| **scotland** (default) | 57.2, -3.8 (Aviemore) | Spring/Summer | Low fire activity - good for testing empty states |
| **portugal** | 39.6, -9.1 (Lisbon area) | June-September | High summer fire activity |
| **spain** | 40.4, -3.7 (Madrid area) | June-September | High summer fire activity |
| **greece** | 37.9, 23.7 (Athens area) | June-September | High summer fire activity, especially islands |
| **california** | 36.7, -119.4 (Central CA) | June-November | High fire activity, year-round risk |
| **australia** | -33.8, 151.2 (Sydney area) | December-February | Southern Hemisphere summer fires |

## Usage

### Command Line

```bash
# Test with Portugal (typically has more fires)
flutter run -d android \
  --dart-define=MAP_LIVE_DATA=true \
  --dart-define=TEST_REGION=portugal

# Test with Spain
flutter run -d ios \
  --dart-define=MAP_LIVE_DATA=true \
  --dart-define=TEST_REGION=spain

# Test with California
flutter run -d chrome \
  --dart-define=MAP_LIVE_DATA=true \
  --dart-define=TEST_REGION=california

# Default Scotland (no TEST_REGION needed)
flutter run -d android \
  --dart-define=MAP_LIVE_DATA=true
```

### Environment File

Add to `env/dev.env.json`:

```json
{
  "MAP_LIVE_DATA": "true",
  "TEST_REGION": "portugal",
  "GOOGLE_MAPS_API_KEY_ANDROID": "YOUR_KEY",
  "GOOGLE_MAPS_API_KEY_IOS": "YOUR_KEY"
}
```

Then run:
```bash
flutter run -d android --dart-define-from-file=env/dev.env.json
```

## Fire Data Availability

### When You'll See Fires

**EFFIS Dataset**: `burnt_areas_current_year`
- Contains areas that have **actually burned** in 2025
- Updated daily
- Empty results are normal for low-risk regions/seasons

**Best Times to Test**:
- **Mediterranean regions** (Portugal, Spain, Greece): June-September
- **California**: July-November  
- **Australia**: December-February (Southern Hemisphere summer)
- **Scotland**: April-May (rare, but possible)

### When You Won't See Fires

- **Off-season**: Outside typical fire seasons
- **Wet weather**: After recent rainfall
- **Low-risk regions**: Scotland, Northern Europe (most of the year)
- **Good fire management**: Some years have fewer incidents

## Testing Scenarios

### Scenario 1: Test Empty State (Scotland)
```bash
flutter run -d android \
  --dart-define=MAP_LIVE_DATA=true \
  --dart-define=TEST_REGION=scotland
```

**Expected**: 
- 🔥 EFFIS WFS called successfully
- ✅ 0 fires returned
- UI shows: "No Active Fires Detected" message
- Source chip: "LIVE"

### Scenario 2: Test With Fire Data (Portugal - Summer)
```bash
flutter run -d android \
  --dart-define=MAP_LIVE_DATA=true \
  --dart-define=TEST_REGION=portugal
```

**Expected** (during fire season):
- 🔥 EFFIS WFS called successfully
- ✅ 1+ fires returned (varies)
- Map shows fire markers
- Source chip: "LIVE"

### Scenario 3: Test Fallback Chain (Invalid Region)
```bash
flutter run -d android \
  --dart-define=MAP_LIVE_DATA=true \
  --dart-define=TEST_REGION=invalid
```

**Expected**:
- Falls back to Scotland (default)
- Behaves like Scenario 1

## Debugging Logs

With the debug prints added, you'll see:

```
flutter: 🗺️ Using test region: portugal at 39.6,-9.1
flutter: 🗺️ MapController: Fetching fires for bounds: SW(37.6,-11.1) NE(41.6,-7.1)
flutter: 🔥 FireLocationService: Starting fallback chain for bbox center 39.60,-9.10
flutter: 🔥 Tier 1: Attempting EFFIS WFS for bbox -11.1,37.6,-7.1,41.6
flutter: 🔥 Tier 1 (EFFIS WFS) success: 5 fires
flutter: 🗺️ MapController: Loaded 5 fire incidents
flutter: 🔥 Cached EFFIS result at geohash eyck4
```

## Platform Support

| Platform | GoogleMap Support | Test Region Support |
|----------|------------------|---------------------|
| Android | ✅ Yes | ✅ Yes |
| iOS | ✅ Yes | ✅ Yes |
| Web | ✅ Yes (JavaScript API) | ✅ Yes |
| macOS | ❌ No (v2.5.0 limitation) | ⚠️ Data loads, but no map display |

**macOS Behavior**: 
- Map widget not supported
- Falls back to list view showing fire data
- Test region still works for data fetching
- Use Android/iOS/Web for full map testing

## Implementation

### Code Location
- Feature flag: `lib/config/feature_flags.dart`
- Region mapping: `lib/features/map/controllers/map_controller.dart:_getTestRegionCenter()`
- EFFIS service: `lib/services/effis_service_impl.dart:getActiveFires()`

### Adding New Test Regions

Edit `lib/features/map/controllers/map_controller.dart`:

```dart
static LatLng _getTestRegionCenter() {
  final region = FeatureFlags.testRegion.toLowerCase();
  
  switch (region) {
    case 'portugal':
      return const LatLng(39.6, -9.1);
    case 'your_new_region':  // Add here
      return const LatLng(LAT, LON);
    default:
      return const LatLng(57.2, -3.8); // Scotland fallback
  }
}
```

## Constitutional Compliance

- **C2 (Privacy)**: Coordinates logged at 2dp precision via `GeographicUtils.logRedact()`
- **C4 (Transparency)**: Source chip shows LIVE/CACHED/MOCK
- **C5 (Resilience)**: 3-tier fallback (EFFIS → Cache → Mock)

## Troubleshooting

### No Fires Showing (But Expected)

1. Check the season - fires are seasonal
2. Verify `MAP_LIVE_DATA=true` is set
3. Check logs for EFFIS WFS response
4. Try a different region known for current fires

### EFFIS API Errors

```
flutter: 🔥 Tier 1 (EFFIS WFS) failed: Network error
flutter: 🔥 Tier 2: Attempting cache lookup...
```

**Solutions**:
- Check internet connection
- Verify EFFIS service is operational: https://effis.jrc.ec.europa.eu/
- Cache will serve stale data (6h TTL)
- Mock will provide fallback data

### Wrong Region Loading

Check environment variable is spelled correctly:
```bash
# Correct
--dart-define=TEST_REGION=portugal

# Wrong (will use default scotland)
--dart-define=TEST_REGION=portugl  # Typo
--dart-define=REGION=portugal       # Wrong variable name
```

## Related Documentation

- [Google Maps Setup](google-maps-setup.md) - API key configuration
- [EFFIS Monitoring Runbook](runbooks/effis-monitoring.md) - Operational procedures
- [Privacy Compliance](privacy-compliance.md) - Coordinate logging

## Future Enhancements

Potential improvements for A11+:
- Add more test regions (Canada, Siberia, Amazon)
- Support custom coordinates via `--dart-define=TEST_LAT=X --dart-define=TEST_LON=Y`
- Add UI picker for region selection
- Historical data comparison mode
