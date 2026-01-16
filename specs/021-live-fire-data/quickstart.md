# Quickstart: Live Fire Data Display

**Feature Branch**: `021-live-fire-data`  
**Date**: 2025-12-09

---

## Quick Validation Steps

Run these commands to validate the implementation is working correctly.

### 1. Run All Feature Tests

```bash
cd /Users/lizstevenson/Desktop/WildFire-App/Documentation/wildfire_app_docs/apps/flutter/wildfire_mvp_v3

# Run all tests for this feature
flutter test test/unit/services/gwis_hotspot_service_test.dart
flutter test test/unit/services/effis_burnt_area_service_test.dart
flutter test test/unit/models/hotspot_test.dart
flutter test test/unit/models/burnt_area_test.dart
flutter test test/widget/map_fire_mode_toggle_test.dart
flutter test test/widget/hotspot_time_filter_test.dart

# Run contract tests (requires network)
flutter test test/contract/gwis_hotspot_service_contract_test.dart
flutter test test/contract/effis_burnt_area_service_contract_test.dart
```

### 2. Launch App with Live Data

```bash
# Run with live GWIS/EFFIS data
./scripts/run_web.sh

# Or manually with live data flag
flutter run -d chrome --dart-define=MAP_LIVE_DATA=true
```

### 3. Visual Validation Checklist

Open the Fire Map screen and verify:

#### Hotspot Mode (Default)
- [ ] Map shows orange/red 375m squares for active hotspots
- [ ] At zoom < 10, hotspots are clustered with count badges
- [ ] At zoom ≥ 10, individual squares are visible
- [ ] Tapping a hotspot shows bottom sheet with:
  - [ ] Detection time (relative format: "2 hours ago")
  - [ ] Satellite sensor (e.g., "VIIRS on NOAA-21")
  - [ ] Confidence level (e.g., "High 95%")
  - [ ] Fire intensity (e.g., "Strong - 45 MW")
  - [ ] Educational label about 375m accuracy
- [ ] "Today" filter shows last 24 hours
- [ ] "This Week" filter shows last 7 days

#### Burnt Areas Mode
- [ ] Toggle to "Burnt Areas" mode
- [ ] Map shows semi-transparent polygons at zoom ≥ 8
- [ ] Tapping a polygon shows bottom sheet with:
  - [ ] Official area in hectares
  - [ ] Fire date and last update
  - [ ] Land cover breakdown (if available)
  - [ ] Simplification notice (if simplified)
  - [ ] Educational label about verified perimeters
- [ ] Polygons use RiskPalette colors

#### Mode Toggle
- [ ] Switching modes clears previous data type
- [ ] Only one data type visible at a time
- [ ] Default mode is "Active Hotspots"

#### Empty States
- [ ] When no hotspots exist, shows "No active fires detected"
- [ ] Message includes hint to toggle for past fires

#### Error Fallback
- [ ] Disable network and refresh
- [ ] App falls back to mock data
- [ ] "Demo Data" indicator visible

### 4. Performance Validation

```bash
# Run performance tests
flutter test test/performance/polygon_rendering_test.dart
```

Expected results:
- 50 polygons render in < 100ms
- Hotspot clustering for 100 points completes in < 50ms

### 5. Constitution Gate Checks

```bash
# Run constitution gates
./.specify/scripts/bash/constitution-gates.sh

# Or manually:
flutter analyze
dart format --set-exit-if-changed lib/ test/
flutter test
```

All gates must pass:
- [ ] C1: No analyzer errors, code formatted
- [ ] C2: No PII in logs (coordinates at 2dp)
- [ ] C3: Touch targets ≥ 44dp
- [ ] C4: Timestamp visible, source labeled
- [ ] C5: Error handling with fallbacks

---

## Sample API Calls

### Test GWIS Hotspot API

```bash
# Today's hotspots for Scotland
curl -s "https://maps.effis.emergency.copernicus.eu/gwis?\
SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo\
&LAYERS=viirs.hs.today&QUERY_LAYERS=viirs.hs.today\
&CRS=EPSG:4326&BBOX=55.0,-5.0,58.0,-2.0\
&WIDTH=256&HEIGHT=256&I=128&J=128\
&INFO_FORMAT=application/vnd.ogc.gml\
&FEATURE_COUNT=10"
```

### Test EFFIS Burnt Area API

```bash
# Burnt areas for Scotland
curl -s "https://maps.effis.emergency.copernicus.eu/effis?\
SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature\
&TYPENAMES=ms:modis.ba.poly.season\
&BBOX=55.0,-5.0,58.0,-2.0,EPSG:4326\
&OUTPUTFORMAT=application/json\
&COUNT=10" | jq '.features | length'
```

---

## Troubleshooting

### No Hotspots Displaying
1. Check network connectivity
2. Verify `MAP_LIVE_DATA=true` is set
3. Check console for GWIS errors
4. Try "This Week" filter (more data)

### Polygons Not Rendering
1. Zoom to level ≥ 8
2. Switch to "Burnt Areas" mode
3. Check console for WFS errors
4. Verify polygon toggle is enabled

### Performance Issues
1. Check polygon point counts in console
2. Verify simplification is working
3. Reduce viewport size (zoom in)

---

**Quickstart Complete** ✓
