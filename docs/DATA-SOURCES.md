---
title: Data Sources Reference
status: active
last_updated: 2025-12-18
category: reference
subcategory: apis
related:
  - guides/setup/google-maps.md
  - reference/test-regions.md
  - reference/EFFIS_API_ENDPOINTS.md
---

# WildFire Prototype — Data Sources

> 📚 **See Also**: For detailed EFFIS/GWIS endpoint specifications, layer lists, and curl examples, see [EFFIS API Endpoints Reference](reference/EFFIS_API_ENDPOINTS.md).

## EFFIS (European Forest Fire Information System) 🎉 BREAKTHROUGH COMPLETE 2025-10-04
- **Service**: WMS `GetFeatureInfo` for Fire Weather Index (FWI)
- **Base URL**: `https://ies-ows.jrc.ec.europa.eu/gwis`
- **Input**: lat, lon (WGS84 coordinates)
- **Output**: text/plain format with FWI value
- **Timeout**: 30s default, configurable
- **Retry Policy**: Max 3 retries with exponential backoff + jitter
- **Fallback**: handled by `FireRiskService`
- **Status**: 🎉 100% COMPLETE - Real EFFIS data successfully integrated!

### 🚨 BREAKTHROUGH: Critical Requirements for EFFIS Access

**Essential Configuration Changes:**
1. **Coordinate System**: `EPSG:4326` (NOT EPSG:3857) - This was the breakthrough fix!
2. **Temporal Parameter**: `TIME=YYYY-MM-DD` (REQUIRED for data access)
3. **Geographic Coverage**: European/Mediterranean regions (Portugal confirmed working)
4. **Working Date**: `2024-08-15` (confirmed fire weather data available)

### ✅ VERIFIED Working Configuration (2025-10-04)

**Layer Names** (confirmed from GetCapabilities):
- **PRIMARY**: `nasa_geos5.fwi` ✅ NASA GEOS-5 Fire Weather Index
- **Alternative**: `nasa.fwi_gpm.fwi` ✅ NASA FWI with GPM precipitation
- **Regional**: `fwi_gadm_admin1.fwi` ✅ FWI on GADM Admin level 1
- **Regional**: `fwi_gadm_admin2.fwi` ✅ FWI on GADM Admin level 2

### WMS Parameters Used (🎯 BREAKTHROUGH CONFIGURATION)
- **SERVICE**: `WMS`
- **VERSION**: `1.3.0`
- **REQUEST**: `GetFeatureInfo`
- **LAYERS**: `nasa_geos5.fwi` ✅ **VERIFIED WORKING**
- **QUERY_LAYERS**: `nasa_geos5.fwi`
- **CRS**: `EPSG:4326` ✅ **BREAKTHROUGH FIX** (was EPSG:3857 - caused "no results")
- **BBOX**: Dynamic bounding box (±0.1 degrees ~11km buffer)
- **WIDTH/HEIGHT**: `256x256` pixels
- **I/J**: `128,128` (center query point)
- **INFO_FORMAT**: `text/plain` ✅ **VERIFIED WORKING**
- **FEATURE_COUNT**: `1`
- **TIME**: `2024-08-15` ✅ **BREAKTHROUGH FIX** (temporal parameter required)

### 🔍 Integration Research Results

**❌ Failed Layer Names** (returned LayerNotDefined):
- `ecmwf.fwi` ❌ Original assumption - not available
- `fwi` ❌ Generic name - not available
- `gwis.fwi.mosaics.c_1` ❌ Complex path - not available

**❌ Failed Response Formats** (returned Unsupported INFO_FORMAT):
- `application/json` ❌ Not supported (original assumption wrong)
- `text/xml` ❌ Not supported

**✅ Working Response Formats** (from GetCapabilities):
- `text/plain` ✅ **Implemented** - Simple text responses
- `text/html` ✅ Available - HTML formatted results
- `application/vnd.ogc.gml` ✅ Available - GML/XML structured format

### Current Response Handling

**Successful Connection**: Service accepts requests and responds properly

**Typical Response**:
```
GetFeatureInfo results:

  Search returned no results.
```

**⚠️ Current Limitation**: "Search returned no results"
- **Hypothesis**: Requires TIME parameter for temporal/current data
- **Alternative**: Coordinate coverage may be region-specific
- **Status**: Proper error handling implemented, falls back to mock data

### Testing Commands

**Verify Layer Availability**:
```bash
curl -s "https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities" | grep -A2 -B2 "nasa_geos5.fwi"
```

**Test GetFeatureInfo**:
```bash
curl -s "https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=nasa_geos5.fwi&QUERY_LAYERS=nasa_geos5.fwi&CRS=EPSG:4326&BBOX=40.3,2.1,40.5,2.3&WIDTH=256&HEIGHT=256&I=128&J=128&INFO_FORMAT=text/plain&FEATURE_COUNT=1"
```

### HTTP Headers
- **User-Agent**: `WildFire/0.1 (prototype)`
- **Accept**: `application/json,*/*;q=0.8`

### Content-Type Behavior ✅ UPDATED
- **Expected**: `text/plain; charset=UTF-8` ✅ **VERIFIED**
- **Parsing**: Plain text format with "GetFeatureInfo results:" header
- **FWI Extraction**: Regex parsing for numeric FWI values in response text
- **Timestamp**: UTC fallback to current time (original data timestamp not available in text format)
- **No Results Handling**: "Search returned no results" → graceful fallback to next service tier

### Error Handling & Retry Policy
- **Retryable Errors**: HTTP 5xx, network timeouts, temporary failures
- **Non-Retryable**: HTTP 4xx (client errors), malformed responses
- **Backoff Formula**: `base_delay * (2^attempt) + jitter`
- **Jitter Range**: ±25% to prevent thundering herd
- **Max Retries**: 3 attempts (configurable, capped at 10)

### FWI → Risk Mapping
- `< 5` → Very Low
- `5–11` → Low
- `12–20` → Moderate
- `21–37` → High
- `38–49` → Very High
- `≥ 50` → Extreme

## SEPA (Scottish Environment Protection Agency)
- **Service**: Fallback source for Scotland
- **Scope**: Only queried if user location in Scotland
- **Output**: risk level approximated to match app’s 6-level scale
- **Notes**: coverage limited; provide clear source tag in UI

## Cache
- **Service**: Local `FireRiskCache`
- **Storage**: SharedPreferences, key = geohash(lat,lon,precision=5)
- **TTL**: 6 hours
- **Notes**: must mark results as `freshness=cached`

## Mock
- **Service**: Fixed dummy response (level = Moderate)
- **Purpose**: Guarantees UI never blank; clearly labeled in UI

## Freshness & Transparency
- Every data object must include:
  - `updatedAt` (UTC)
  - `source` (effis|sepa|cache|mock)
  - `freshness` (live|cached)

## Error Handling
- Always fail visible:
  - Loading state
  - Error message with retry
  - Cached fallback (with badge)

## EFFIS Integration Lessons Learned 🎓

### Key Findings from 2025-10-04 Research

**1. Layer Discovery is Critical**
- ❌ **Never assume layer names** - documentation may be outdated
- ✅ **Always use GetCapabilities** to discover actual available layers
- ✅ **Test multiple candidates** - nasa_geos5.fwi worked when others failed

**2. Response Format Negotiation**
- ❌ **JSON assumption failed** - application/json not supported
- ✅ **Check supported formats** in GetCapabilities GetFeatureInfo section
- ✅ **text/plain works reliably** for basic FWI data extraction

**3. Service Architecture Validation**
- ✅ **Proper service orchestration** - EFFIS → SEPA → Cache → Mock
- ✅ **Error handling works** - graceful degradation to fallback services
- ✅ **Logging is essential** - debug output revealed exact error messages

**4. Temporal Data Challenges**
- ⚠️ **Static data queries often empty** - "Search returned no results"
- 🔍 **Next research**: TIME parameter syntax for current/forecast data
- 🔍 **Next research**: Coordinate coverage patterns and data availability

### Debugging Commands for Future Reference

**GetCapabilities Analysis**:
```bash
# Full capabilities document
curl -s "https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities" > effis_capabilities.xml

# Extract layer names
curl -s "https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities" | grep -E '<Name>.*fwi.*</Name>'

# Extract supported formats
curl -s "https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities" | grep -A5 -B5 "GetFeatureInfo"
```

**Layer Testing**:
```bash
# Test layer availability
curl -s "https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=nasa_geos5.fwi&QUERY_LAYERS=nasa_geos5.fwi&CRS=EPSG:4326&BBOX=50,0,52,2&WIDTH=256&HEIGHT=256&I=128&J=128&INFO_FORMAT=text/plain&FEATURE_COUNT=1"
```

**Format Testing**:
```bash
# Test different response formats
for format in "text/plain" "text/html" "application/vnd.ogc.gml"; do
  echo "Testing format: $format"
  curl -s "https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=nasa_geos5.fwi&QUERY_LAYERS=nasa_geos5.fwi&CRS=EPSG:4326&BBOX=50,0,52,2&WIDTH=256&HEIGHT=256&I=128&J=128&INFO_FORMAT=$format&FEATURE_COUNT=1"
  echo "\n---\n"
done
```

### Success Metrics
- ✅ **Service Connection**: HTTP 200 responses from EFFIS
- ✅ **Layer Recognition**: No more "LayerNotDefined" errors
- ✅ **Format Acceptance**: No more "Unsupported INFO_FORMAT" errors
- ✅ **Response Parsing**: Handles both data and "no results" cases
- ✅ **Fallback Chain**: Proper degradation to mock when no EFFIS data
- 🎯 **95% Complete**: Architecture solid, temporal data access next

## References
- `specs/001-spec-a1-effisservice/` - EFFIS service specification
- `specs/002-spec-a2-fireriskservice/` - Fire risk orchestration service
- Constitution v1.0
- EFFIS GetCapabilities: https://ies-ows.jrc.ec.europa.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities

---

## 🔥 Live Fire Data Investigation (2025-12-18)

### Overview

Investigation into EFFIS Burnt Areas API failures during live data mode testing. The FIRMS hotspot service was working correctly, but EFFIS burnt areas returned "Connection closed while receiving data" errors.

### Key Discoveries

#### 1. JRC Endpoint is DEPRECATED/BROKEN

**Endpoint**: `https://ies-ows.jrc.ec.europa.eu/effis`

```bash
# Returns database error
curl -s "https://ies-ows.jrc.ec.europa.eu/effis?service=WFS&version=1.1.0&request=GetFeature&typeName=effis:ba.curryear&outputFormat=json&maxFeatures=1"
# Response: {"type":"FeatureCollection","features":[]}
# Or: Server returned HTTP response code: 500 / database error

# Layer doesn't exist
curl -s "https://ies-ows.jrc.ec.europa.eu/effis?service=WFS&request=GetCapabilities" | grep "ba.curryear"
# Returns nothing - layer name is invalid
```

**Status**: ❌ Do not use. This endpoint is deprecated and returns database errors.

#### 2. Copernicus Endpoint is WORKING

**Endpoint**: `https://maps.effis.emergency.copernicus.eu/effis`

```bash
# Working WFS request for burnt areas
curl -s "https://maps.effis.emergency.copernicus.eu/effis?service=WFS&version=1.1.0&request=GetFeature&typeName=ms:modis.ba.poly.season&outputFormat=json&maxFeatures=5"
# Returns actual burnt area polygons for current fire season
```

**Status**: ✅ WORKING - Returns burnt area data for France, Italy, Portugal, Greece, etc.

#### 3. Correct Layer Names

| Layer Name | Description | Status |
|------------|-------------|--------|
| `ms:modis.ba.poly.season` | Current fire season burnt areas | ✅ Working |
| `ms:modis.ba.poly.lastseason` | Previous year burnt areas | ✅ Working |
| `effis:ba.curryear` | (JRC) Current year | ❌ INVALID |
| `ms:modis.ba.poly` | Generic (no season filter) | ⚠️ May work but unfiltered |

#### 4. WFS Version Matters

| WFS Version | Status | Notes |
|-------------|--------|-------|
| 1.1.0 | ✅ Working | Recommended |
| 2.0.0 | ❌ 502 errors | Causes issues with CQL_FILTER |
| 1.0.0 | ⚠️ Untested | May work |

#### 5. CQL_FILTER Issues

```bash
# ❌ BROKEN - 'year' attribute doesn't exist on ms:modis.ba.poly.season
curl "...&CQL_FILTER=year=2025"  # Returns 502 error

# ✅ WORKING - Use season-specific layers instead
# ms:modis.ba.poly.season already filters by current season
# ms:modis.ba.poly.lastseason already filters by previous season
```

### ✅ UK Burnt Area Data CONFIRMED Present (Updated 2025-12-18 13:00)

**CORRECTION**: UK data IS available! Earlier tests with `outputFormat=json` failed, but `outputFormat=GML3` works:

```bash
# ✅ WORKING - GML3 output returns UK data including fire 273772 (9,809 ha)
curl --http1.1 -s "https://maps.effis.emergency.copernicus.eu/effis?service=WFS&version=1.1.0&request=GetFeature&typeName=ms:modis.ba.poly.season&outputFormat=GML3&maxFeatures=50&bbox=57.0,-4.0,58.0,-3.0,EPSG:4326"

# Verified UK fires present:
# - Fire 273772: 2025-06-28, West Moray, 9,809 ha (largest UK fire in 2025)
# - Fire 256973: 2025-02-07, Scottish Highlands, 16 ha
# - Multiple fires: Feb 2025, Various UK locations
```

**Root cause of earlier "no data" results**: JSON output format (`outputFormat=json`) fails silently with bbox filters on this endpoint. Use GML3 instead.

### Implementation Fixes Applied

#### Config Files Updated

| File | Change |
|------|--------|
| `env/dev.env.json` | `EFFIS_BASE_URL` → Copernicus, `EFFIS_WFS_LAYER_ACTIVE` → `ms:modis.ba.poly.season` |
| `env/dev.env.json.template` | Layer name update |
| `env/prod.env.json.template` | Layer name update |
| `env/ci.env.json` | Layer name update |
| `lib/config/feature_flags.dart` | Default layer → `ms:modis.ba.poly.season` |

#### Service Implementation Updated

`lib/services/effis_burnt_area_service_impl.dart`:
- Changed WFS version from 2.0.0 to 1.1.0
- Removed invalid `CQL_FILTER=year=YYYY`
- Added season layer selection based on `BurntAreaSeasonFilter`
- Layer constants: `_currentSeasonLayer = 'ms:modis.ba.poly.season'`, `_lastSeasonLayer = 'ms:modis.ba.poly.lastseason'`
- ✅ **DONE**: Switched to GML3 output format (commit c3ee6b4) - JSON fails silently with bbox filters

### Working cURL Examples

```bash
# ✅ RECOMMENDED: GML3 output (most reliable)
curl --http1.1 -s "https://maps.effis.emergency.copernicus.eu/effis?service=WFS&version=1.1.0&request=GetFeature&typeName=ms:modis.ba.poly.season&outputFormat=GML3&maxFeatures=5"

# Get UK fires (Scottish Highlands bbox)
curl --http1.1 -s "https://maps.effis.emergency.copernicus.eu/effis?service=WFS&version=1.1.0&request=GetFeature&typeName=ms:modis.ba.poly.season&outputFormat=GML3&maxFeatures=50&bbox=57.0,-4.0,58.0,-3.0,EPSG:4326"

# Get last season burnt areas
curl --http1.1 -s "https://maps.effis.emergency.copernicus.eu/effis?service=WFS&version=1.1.0&request=GetFeature&typeName=ms:modis.ba.poly.lastseason&outputFormat=GML3&maxFeatures=5"

# Get capabilities to discover available layers
curl -s "https://maps.effis.emergency.copernicus.eu/effis?service=WFS&request=GetCapabilities" | grep -E "<Name>.*ba.*</Name>"
```

### Service Status Summary (2025-12-18)

| Service | Endpoint | Status | Notes |
|---------|----------|--------|-------|
| NASA FIRMS Hotspots | firms.modaps.eosdis.nasa.gov | ✅ Working | Returns 0 for Scotland (no current fires) |
| GWIS WMS Fallback | ies-ows.jrc.ec.europa.eu/gwis | ✅ Working | Hotspot fallback |
| EFFIS WFS Burnt Areas | maps.effis.emergency.copernicus.eu | ✅ Working | UK data available (use GML3) |
| JRC WFS (legacy) | ies-ows.jrc.ec.europa.eu/effis | ❌ Broken | Database errors, deprecated |

### Recommendations

1. **Use GML3 output format**: JSON output may fail silently with bbox filters. GML3 is more reliable.

2. **Fire 273772 verified**: West Moray fire (9,809 ha, June 28, 2025) is the largest UK fire in 2025 season.

3. **GWIS NRT layers available**: For near-real-time burnt areas, also check:
   - `nrt.ba.poly.season` - Current season NRT
   - `nrt.ba.poly.today` - Last 24 hours
   - `nrt.ba.poly.week` - Last 7 days

4. **Consider GML parsing**: May need to update service to parse GML3 response format instead of JSON.

---

## Burnt Area Caching Strategy (CachedBurntAreaService)

### Overview

The `CachedBurntAreaService` implements a **bundle-first caching strategy** for burnt area data. This provides instant data loading while maintaining freshness through automated updates.

**Implementation**: `lib/services/cached_burnt_area_service.dart`

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CachedBurntAreaService                       │
├─────────────────────────────────────────────────────────────────┤
│  Demo Mode (skipLiveApi=true)                                   │
│  ┌─────────────┐                                                │
│  │   Bundle    │ ─────────────────────────────────► Return data │
│  │   Assets    │                                                │
│  └─────────────┘                                                │
├─────────────────────────────────────────────────────────────────┤
│  Live Mode (skipLiveApi=false)                                  │
│  ┌─────────────┐    Fresh?     ┌─────────────┐                  │
│  │   Bundle    │ ─── Yes ────► │ Return data │                  │
│  │   Assets    │               └─────────────┘                  │
│  │             │                                                │
│  │ (generatedAt│    Stale?     ┌─────────────┐   Success?       │
│  │  timestamp) │ ─── Yes ────► │  Live EFFIS │ ─── Yes ───► Return live │
│  └─────────────┘               │     API     │                  │
│                                └─────────────┘                  │
│                                      │                          │
│                                   Failure?                      │
│                                      │                          │
│                                      ▼                          │
│                              Return stale bundle                │
│                              (graceful degradation)             │
└─────────────────────────────────────────────────────────────────┘
```

### Staleness Threshold

```dart
static const Duration stalenessThreshold = Duration(days: 9);
```

- Bundle's `generatedAt` timestamp is checked against this threshold
- **Fresh bundle (≤9 days)**: Return bundle data directly, no API call
- **Stale bundle (>9 days)**: Try live EFFIS API, fall back to stale bundle if API fails

### Bundle Assets

| Asset Path | Content | Count |
|------------|---------|-------|
| `assets/cache/burnt_areas_2025_uk.json` | Current year EFFIS fires | ~1,322 fires |
| `assets/cache/burnt_areas_2024_uk.json` | Previous year EFFIS fires | Variable |

Bundles are updated weekly via GitHub Actions CI/CD pipeline.

### Mode-Specific Behavior

| Mode | Flag | Burnt Areas Source | Hotspots Source |
|------|------|-------------------|-----------------|
| **Demo** | `_useLiveData=false` | Bundled real EFFIS data | Mock data (9 fires) |
| **Live** | `_useLiveData=true` | Bundle → Live API (if stale) | Live FIRMS/GWIS API |

**Note**: Demo mode uses **real bundled data** for burnt areas (1,322 fires) but **mock data** for hotspots (9 fires). This asymmetry exists because:
1. Burnt area data changes slowly (weekly updates sufficient)
2. Hotspot data is time-sensitive (near-real-time needed)

### Live Mode Fallback Logic

```dart
// Simplified logic from CachedBurntAreaService.getBurntAreas()

1. Load from bundled asset (instant)
   ↓
2. Check bundle timestamp (generatedAt field in JSON)
   ↓
3a. Bundle fresh (≤9 days)?
    → Return bundle data (NO API call)

3b. Bundle stale (>9 days)?
    → Try live EFFIS API
    → Success? Return live data
    → Failure? Return stale bundle (better than nothing)

3c. Bundle failed to load?
    → Try live EFFIS API directly
```

### Bundle JSON Format

```json
{
  "year": 2025,
  "region": "uk",
  "generatedAt": "2025-01-15T12:00:00Z",
  "features": [
    {
      "id": "273772",
      "geometry": { "type": "Polygon", "coordinates": [...] },
      "properties": {
        "firedate": "2025-06-28",
        "area_ha": 9809.5,
        "lastupdate": "2025-07-02"
      }
    }
  ]
}
```

### Key Implementation Details

1. **Memory caching**: Once loaded, bundle data is cached in `_dataCache` map by year
2. **Timestamp tracking**: `_bundleTimestamps` map stores `generatedAt` for staleness checks
3. **Season filtering**: Uses `BurntAreaSeasonFilter.year` to select correct bundle
4. **Bounds filtering**: Bundle data is filtered to requested `LatLngBounds`

### Testing Considerations

When writing tests for burnt area functionality:

```dart
// Demo mode: Uses bundle only
await service.getBurntAreas(
  bounds: testBounds,
  seasonFilter: BurntAreaSeasonFilter.thisSeason,
  skipLiveApi: true,  // Demo mode
);

// Live mode: May hit API if bundle is stale
await service.getBurntAreas(
  bounds: testBounds,
  seasonFilter: BurntAreaSeasonFilter.thisSeason,
  skipLiveApi: false,  // Live mode (default)
);
```

### Related Files

- `lib/services/cached_burnt_area_service.dart` - Main implementation
- `lib/services/effis_burnt_area_service.dart` - Interface definition
- `lib/services/effis_burnt_area_service_impl.dart` - Live API implementation
- `lib/features/map/controllers/map_controller.dart` - Mode switching logic
- `assets/cache/burnt_areas_*.json` - Bundled data files

---

