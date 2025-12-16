---
title: EFFIS API Endpoints Reference
status: active
last_updated: 2025-12-16
category: reference
subcategory: api
related:
  - ../DATA-SOURCES.md
  - ../guides/setup/google-maps.md
  - ../../lib/models/fire_incident.dart
  - ../../test/fixtures/scotland_fire_273772_fixture.dart
changelog:
  - 2025-12-16: 🐛 ROOT CAUSE FOUND - GwisHotspotServiceImpl incorrectly uses WFS instead of WMS. Hotspots require WMS GetFeatureInfo, not WFS GetFeature!
  - 2025-12-16: Verified endpoints ARE working - WMS returns live hotspot data, WFS returns 502 (not supported for hotspots)
  - 2025-12-16: Added "Correct Service Types" section documenting WMS vs WFS requirements per layer
  - 2025-12-16: Earlier "outage" was actually us testing wrong service type (WFS instead of WMS)
  - 2025-12-16: Burnt areas via WFS on /effis confirmed working
  - 2025-12-09: Added hotspot data lifecycle section (time windows, archive retention, historical access)
  - 2025-12-09: Added hotspot pixel limitations section explaining why area estimation from hotspots is inaccurate
  - 2025-12-09: Documented Scotland Wildfire Tracker (Strathclyde) as alternative data source with analysis
  - 2025-12-09: Added satellite sensor comparison (VIIRS vs MODIS vs NOAA) and map implementation recommendations
  - 2025-12-09: Discovered working real-time hotspot layers on GWIS endpoint (viirs.hs.today, etc.)
  - 2025-12-09: Documented EFFIS vs GWIS endpoint differences for hotspot data
  - 2025-12-08: Added "Understanding FIREDATE and LASTUPDATE" section explaining date semantics
  - 2025-12-08: Added historical fire data queries with CQL filters and sorting
  - 2025-12-08: Documented ms:modis.ba.poly.season layer and response schema
---

# EFFIS API Endpoints Reference

This document describes the EFFIS (European Forest Fire Information System) and related fire weather data API endpoints, their capabilities, and the migration from legacy to current endpoints.

## Executive Summary

> 🐛 **BUG IDENTIFIED (2025-12-16)**: Our `GwisHotspotServiceImpl` was incorrectly using **WFS** for hotspot queries. The GWIS endpoint only supports **WMS** for hotspots. This is why "live data" wasn't working - it's a code bug, not an endpoint issue!

As of December 2025, EFFIS provides data via the Copernicus emergency endpoint.

| Service | Current Endpoint | Protocol | Status |
|---------|------------------|----------|--------|
| **Hotspots** | `maps.effis.emergency.copernicus.eu/gwis` | **WMS** (not WFS!) | ✅ Working |
| **FWI** | `maps.effis.emergency.copernicus.eu/gwis` | **WMS** | ✅ Working |
| **Burnt Areas** | `maps.effis.emergency.copernicus.eu/effis` | **WFS** | ✅ Working |

---

## ⚠️ CRITICAL: Correct Service Types (WMS vs WFS)

This is the **root cause** of our "live data not working" issue. Different layers require different OGC service types:

| Data Type | Endpoint | Service Type | Status | Notes |
|-----------|----------|--------------|--------|-------|
| **Hotspots** | `/gwis` | ⚠️ **WMS only** | ✅ Works | WFS returns 502! |
| **FWI** | `/gwis` | **WMS** | ✅ Works | Use GetFeatureInfo |
| **Burnt Areas** | `/effis` | **WFS** | ✅ Works | GML response |

### Bug in GwisHotspotServiceImpl

Our current implementation incorrectly uses WFS:

```dart
// ❌ WRONG - Returns 502 error
'$_baseUrl?service=WFS&version=2.0.0&request=GetFeature&typeName=viirs.hs.today&outputFormat=application/json'

// ✅ CORRECT - Returns live hotspot data
'$_baseUrl?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=viirs.hs.today&QUERY_LAYERS=viirs.hs.today&INFO_FORMAT=application/vnd.ogc.gml'
```

### Verified Test Results (2025-12-16 ~16:00 UTC)

```bash
# ❌ WFS for hotspots - FAILS with 502
curl "https://maps.effis.emergency.copernicus.eu/gwis?service=WFS&version=2.0.0&request=GetFeature&typeName=viirs.hs.today&outputFormat=application/json"
# HTTP 502

# ✅ WMS GetFeatureInfo for hotspots - WORKS
curl "https://maps.effis.emergency.copernicus.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=viirs.hs.today&QUERY_LAYERS=viirs.hs.today&CRS=EPSG:4326&BBOX=-20,-10,20,40&WIDTH=256&HEIGHT=256&I=128&J=128&INFO_FORMAT=application/vnd.ogc.gml&STYLES=&FEATURE_COUNT=50"
# Returns live hotspots from Dec 15-16, 2025!

# ✅ WFS for burnt areas - WORKS
curl "https://maps.effis.emergency.copernicus.eu/effis?service=WFS&version=1.1.0&request=GetFeature&typeName=ms:modis.ba.poly.season&bbox=54.5,-9.0,61.0,0.0,EPSG:4326&count=2"
# Returns Scottish fires with polygon boundaries
```

---

### ⚠️ Important: Hotspot Data Requires WMS, Not WFS

Real-time active fire hotspots are **only available via WMS GetFeatureInfo**, not WFS GetFeature:

| Data Type | Endpoint | Protocol | Layer Example | Status |
|-----------|----------|----------|---------------|--------|
| **Real-time Hotspots** | `/gwis` | **WMS** | `viirs.hs.today` | ✅ Working |
| **Historical Hotspots** | `/effis` | WFS | `viirs.hs` | ❌ Stale (Oct 2021) |
| **Burnt Areas** | `/effis` | **WFS** | `modis.ba.poly.season` | ✅ Working |
| **FWI Data** | `/gwis` | **WMS** | `ecmwf.query` | ✅ Working |

---

## Endpoint Comparison

### Current Endpoint (ACTIVE)

**Base URL:** `https://maps.effis.emergency.copernicus.eu/`

| Aspect | Status | Notes |
|--------|--------|-------|
| Hotspot WMS (`/gwis`) | ✅ Working | Use WMS GetFeatureInfo, NOT WFS |
| FWI WMS (`/gwis`) | ✅ Working | Use WMS GetFeatureInfo |
| Burnt Area WFS (`/effis`) | ✅ Working | Use WFS GetFeature |

**Official documentation:** https://forest-fire.emergency.copernicus.eu/downloads-instructions

### Legacy Endpoint (DEPRECATED)

**Base URL:** `https://ies-ows.jrc.ec.europa.eu/`

| Aspect | Status | Notes |
|--------|--------|-------|
| FWI WMS Data | ⚠️ Partial | Historical only (Mar-Sep 2024), no current data |
| WFS Fire Incidents | ❌ Broken | Oracle database connection failure |

---

## Implementation Fix Plan (GwisHotspotServiceImpl)

> **Issue**: Service uses WFS which returns 502 for hotspots. Must migrate to WMS GetFeatureInfo.

### Current Implementation (BROKEN)

```dart
// lib/services/gwis_hotspot_service_impl.dart
String _buildWfsUrl(LatLngBounds bounds, HotspotTimeFilter timeFilter) {
  return '$_baseUrl?'
      'service=WFS&'           // ❌ GWIS doesn't support WFS for hotspots
      'version=2.0.0&'
      'request=GetFeature&'
      'typeName=${timeFilter.gwisLayerName}&'
      'outputFormat=application/json&'
      'srsName=EPSG:4326&'
      'bbox=${sw.longitude},${sw.latitude},${ne.longitude},${ne.latitude},EPSG:4326';
}
```

### Required Fix

Rewrite to use WMS GetFeatureInfo:

```dart
String _buildWmsUrl(LatLngBounds bounds, HotspotTimeFilter timeFilter) {
  final sw = bounds.southwest;
  final ne = bounds.northeast;
  
  return '$_baseUrl?'
      'SERVICE=WMS&'
      'VERSION=1.3.0&'
      'REQUEST=GetFeatureInfo&'
      'LAYERS=${timeFilter.gwisLayerName}&'
      'QUERY_LAYERS=${timeFilter.gwisLayerName}&'
      'CRS=EPSG:4326&'
      'BBOX=${sw.latitude},${sw.longitude},${ne.latitude},${ne.longitude}&'
      'WIDTH=256&'
      'HEIGHT=256&'
      'I=128&'
      'J=128&'
      'INFO_FORMAT=application/vnd.ogc.gml&'
      'STYLES=&'
      'FEATURE_COUNT=100';  // Limit results
}
```

### Key Challenges

1. **WMS GetFeatureInfo is point-based**: Designed for clicking on a map, not viewport queries
   - Returns features at a specific pixel (I,J) in the rendered image
   - May need multiple queries or WMTS tiles approach for full viewport coverage

2. **Response format**: GML instead of GeoJSON
   - Need to parse GML response format
   - Update `_parseResponse` method to handle GML structure

3. **Viewport coverage strategy options**:
   - **Option A**: Grid of GetFeatureInfo queries across viewport (many requests)
   - **Option B**: Use WMTS tiles + UTFGrid for feature detection
   - **Option C**: Accept limitation - only show fires in center of viewport

### Files to Modify

1. `lib/services/gwis_hotspot_service_impl.dart` - Main fix
2. `lib/models/hotspot.dart` - May need `fromGml()` factory
3. `test/unit/services/gwis_hotspot_service_test.dart` - Update tests

### Estimated Effort

- **Simple fix** (Option C - center query only): 2-4 hours
- **Full fix** (Option A - grid queries): 4-8 hours
- **Optimal fix** (Option B - WMTS): 8-16 hours (requires research)

---

## Fire Weather Index (FWI) - WMS Service

### Available Layers

The GWIS WMS service provides Fire Weather Index data from two primary sources:

#### 1. NASA GEOS-5 Layers (Recommended)

| Layer Name | Description | Query Support |
|------------|-------------|---------------|
| `nasa_geos5.query` | FWI query layer - returns numeric values | ✅ GetFeatureInfo |
| `nasa_geos5.fwi` | FWI visualization layer | Map display only |
| `nasa_geos5.ffmc` | Fine Fuel Moisture Code | Map display only |
| `nasa_geos5.dmc` | Duff Moisture Code | Map display only |
| `nasa_geos5.dc` | Drought Code | Map display only |
| `nasa_geos5.isi` | Initial Spread Index | Map display only |
| `nasa_geos5.bui` | Build-Up Index | Map display only |

**Data source:** NASA GEOS-5 atmospheric model
**Update frequency:** Daily
**Coverage:** Global

#### 2. ECMWF Layers (European focus)

| Layer Name | Description | Query Support |
|------------|-------------|---------------|
| `ecmwf.query` | FWI query layer | ✅ GetFeatureInfo |
| `ecmwf.fwi` | FWI visualization | Map display only |
| `ecmwf.ffmc` | Fine Fuel Moisture Code | Map display only |
| `ecmwf.dmc` | Duff Moisture Code | Map display only |
| `ecmwf.dc` | Drought Code | Map display only |
| `ecmwf.isi` | Initial Spread Index | Map display only |
| `ecmwf.bui` | Build-Up Index | Map display only |
| `ecmwf.anomaly` | FWI anomaly from climatology | Map display only |
| `ecmwf.ranking` | FWI percentile ranking | Map display only |

**Data source:** ECMWF weather model
**Update frequency:** Daily  
**Coverage:** Europe and Mediterranean

### GetFeatureInfo Request Format

```
https://maps.effis.emergency.copernicus.eu/gwis
  ?SERVICE=WMS
  &VERSION=1.3.0
  &REQUEST=GetFeatureInfo
  &LAYERS=nasa_geos5.query
  &QUERY_LAYERS=nasa_geos5.query
  &CRS=EPSG:4326
  &BBOX={minLat},{minLon},{maxLat},{maxLon}
  &WIDTH=256
  &HEIGHT=256
  &I=128
  &J=128
  &INFO_FORMAT=application/vnd.ogc.gml
  &STYLES=
  &TIME={YYYY-MM-DD}
```

### Response Structure (GML)

```xml
<msGMLOutput>
  <nasa_geos5.query_layer>
    <gml:name>nasa_geos5.fwi</gml:name>
    <nasa_geos5.query_feature>
      <x>-3.75</x>
      <y>57</y>
      <value_0>6.5485239</value_0>   <!-- FFMC -->
      <value_1>84.985176</value_1>   <!-- DMC -->
      <value_2>8.1582823</value_2>   <!-- DC -->
      <value_3>350.96088</value_3>   <!-- ISI -->
      <value_4>4.7553449</value_4>   <!-- BUI -->
      <value_5>15.420424</value_5>   <!-- FWI -->
      <value_list>6.55,84.99,8.16,350.96,4.76,15.42</value_list>
    </nasa_geos5.query_feature>
  </nasa_geos5.query_layer>
</msGMLOutput>
```

**Value interpretation:**
- `value_0`: FFMC (Fine Fuel Moisture Code)
- `value_1`: DMC (Duff Moisture Code)  
- `value_2`: DC (Drought Code)
- `value_3`: ISI (Initial Spread Index)
- `value_4`: BUI (Build-Up Index)
- `value_5`: **FWI (Fire Weather Index)** - primary risk indicator

---

## Fire Incidents - WFS Service

> ⚠️ **Warning**: The hotspot layers (`ms:viirs.hs`, `ms:modis.hs`, etc.) on the EFFIS WFS endpoint contain **stale data from October 2021**. For real-time hotspots, use the GWIS WMS endpoint with `.today` layers instead. See [Real-Time Hotspots via GWIS](#real-time-hotspots-via-gwis) section.

### Available Layers

| Layer Name | Description | Data Type | Status |
|------------|-------------|-----------|--------|
| `ms:all.hs` | All active fire hotspots | Points | ⚠️ Stale (Oct 2021) |
| `ms:viirs.hs` | VIIRS satellite hotspots | Points | ⚠️ Stale (Oct 2021) |
| `ms:modis.hs` | MODIS satellite hotspots | Points | ⚠️ Stale (Oct 2021) |
| `ms:noaa.hs` | NOAA satellite hotspots | Points | ⚠️ Stale (Oct 2021) |
| `ms:modis.ba.poly` | MODIS burnt areas | Polygons | ✅ Current |
| `ms:modis.ba.point` | MODIS burnt area centroids | Points | ✅ Current |
| `ms:effis.nrt.ba.poly` | Near-real-time burnt areas | Polygons | ✅ Current |
| `ms:effis.nrt.ba.point` | NRT burnt area centroids | Points | ✅ Current |
| `ms:modis.ba.poly.season` | Seasonal burnt areas (current fire season) | Polygons | ✅ Current |

### WFS GetFeature Request

```
https://maps.effis.emergency.copernicus.eu/effis
  ?SERVICE=WFS
  &VERSION=2.0.0
  &REQUEST=GetFeature
  &TYPENAME=ms:modis.ba.poly
  &OUTPUTFORMAT=GML3
  &COUNT=100
```

**Supported output formats:**
- `GML3` (recommended)
- `SHAPEZIP` (for download)
- `SPATIALITEZIP` (for download)

**Note:** JSON output format is NOT supported on this endpoint.

---

## Real-Time Hotspots via GWIS

> 🔥 **Key Discovery (Dec 2025)**: Real-time active fire hotspots require the GWIS endpoint with time-filtered layers (`.today`, `.week`). The base hotspot layers on EFFIS WFS are stale.

### Working Endpoint for Real-Time Hotspots

**Base URL:** `https://maps.effis.emergency.copernicus.eu/gwis`

### Available Time-Filtered Layers

| Layer | Coverage | Satellite | Status |
|-------|----------|-----------|--------|
| `viirs.hs.today` | Last 24 hours | All VIIRS | ✅ Current |
| `viirs.hs.week` | Last 7 days | All VIIRS | ✅ Current |
| `viirs.hs.n20.today` | Last 24 hours | NOAA-20 | ✅ Current |
| `viirs.hs.n21.today` | Last 24 hours | NOAA-21 | ✅ Current |
| `viirs.hs.suomi.today` | Last 24 hours | Suomi NPP | ✅ Current |
| `modis.hs.today` | Last 24 hours | Terra/Aqua | ✅ Current |
| `modis.hs.week` | Last 7 days | Terra/Aqua | ✅ Current |
| `s3.hs.today` | Last 24 hours | Sentinel-3 | ✅ Current |
| `all.hs.today` | Last 24 hours | All sources | ✅ Current |
| `all.hs.week` | Last 7 days | All sources | ✅ Current |

### WMS GetFeatureInfo Request

```
https://maps.effis.emergency.copernicus.eu/gwis
  ?SERVICE=WMS
  &VERSION=1.3.0
  &REQUEST=GetFeatureInfo
  &LAYERS=viirs.hs.today
  &QUERY_LAYERS=viirs.hs.today
  &CRS=EPSG:4326
  &BBOX={minLat},{minLon},{maxLat},{maxLon}
  &WIDTH=256
  &HEIGHT=256
  &I=128
  &J=128
  &INFO_FORMAT=application/vnd.ogc.gml
  &STYLES=
  &FEATURE_COUNT=10
```

### Response Structure (GML)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<msGMLOutput>
  <viirs.hs.today_layer>
    <gml:name>viirs.hs.today</gml:name>
    <viirs.hs.today_feature>
      <gml:boundedBy>
        <gml:Box srsName="EPSG:4326">
          <gml:coordinates>0.085720,10.495960 0.085720,10.495960</gml:coordinates>
        </gml:Box>
      </gml:boundedBy>
      <id>41646136449</id>
      <acq_at>2025-12-08 01:17:00</acq_at>
      <CLASS>1DAY_2</CLASS>
    </viirs.hs.today_feature>
  </viirs.hs.today_layer>
</msGMLOutput>
```

### Hotspot Field Definitions

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique hotspot identifier | `41646136449` |
| `acq_at` | Acquisition timestamp (UTC) | `2025-12-08 01:17:00` |
| `CLASS` | Time classification | `1DAY_2` (within last 24h) |
| `gml:coordinates` | Point location (lon,lat) | `0.085720,10.495960` |

**Note:** The `.today` layers provide minimal fields. For full hotspot details (FRP, confidence, brightness temps), you may need to use the base layers with TIME parameter, though these may have stale WFS data.

### WMTS Tiles for Map Display

For map tile display (not data queries), use WMTS:

```
https://maps.effis.emergency.copernicus.eu/gwist/wmts
  ?layer=viirs.hs.today
  &style=default
  &tilematrixset=EPSG3857
  &Service=WMTS
  &Request=GetTile
  &Version=1.0.0
  &Format=image/png
  &TileMatrix={z}
  &TileCol={x}
  &TileRow={y}
```

WMTS tiles are updated regularly (observed: Last-Modified timestamp within hours of current time).

### Comparing EFFIS vs GWIS for Hotspots

| Aspect | EFFIS Endpoint (`/effis`) | GWIS Endpoint (`/gwis`) |
|--------|---------------------------|-------------------------|
| **Hotspot WFS** | ❌ Stale (Oct 2021) | N/A (no WFS for hotspots) |
| **Hotspot WMS `.today`** | ❌ Not available | ✅ Current data |
| **Hotspot WMTS** | ❌ Not available | ✅ Current tiles |
| **Burnt Area WFS** | ✅ Current | N/A |
| **FWI WMS** | Via `/gwis` only | ✅ Current |

**Recommendation:** Use GWIS for FWI and real-time hotspots, EFFIS for burnt area polygons.

---

## Historical Fire Data Queries (WFS)

The EFFIS WFS service provides access to historical burnt area data through the seasonal layer. This is useful for:
- Analyzing past fire patterns
- Creating test fixtures with real data
- Validating polygon rendering with actual fire boundaries

### Seasonal Burnt Areas Layer

**Layer:** `ms:modis.ba.poly.season`

Contains all fires detected during the current fire season (typically January to present).

### Query by Geographic Bounding Box

Use the `bbox` parameter to filter fires by region. Format: `minLat,minLon,maxLat,maxLon,CRS`

**Scotland BBOX:** `54.5,-9.0,61.0,0.0,EPSG:4326`

```bash
# Query all Scotland fires (2025 season)
curl -s "https://maps.effis.emergency.copernicus.eu/effis?\
service=WFS&\
version=1.1.0&\
request=GetFeature&\
typeName=ms:modis.ba.poly.season&\
bbox=54.5,-9.0,61.0,0.0,EPSG:4326&\
count=1000"
```

### Query by Date Range (CQL Filter)

Use CQL filters for date-specific queries:

```bash
# Fires on a specific date
curl -s "https://maps.effis.emergency.copernicus.eu/effis?\
service=WFS&\
version=1.1.0&\
request=GetFeature&\
typeName=ms:modis.ba.poly.season&\
cql_filter=FIREDATE='2025-06-28'"

# Fires in date range
curl -s "https://maps.effis.emergency.copernicus.eu/effis?\
service=WFS&\
version=1.1.0&\
request=GetFeature&\
typeName=ms:modis.ba.poly.season&\
cql_filter=FIREDATE>='2025-06-01' AND FIREDATE<='2025-06-30'"

# Combine with BBOX for region + date
curl -s "https://maps.effis.emergency.copernicus.eu/effis?\
service=WFS&\
version=1.1.0&\
request=GetFeature&\
typeName=ms:modis.ba.poly.season&\
bbox=54.5,-9.0,61.0,0.0,EPSG:4326&\
cql_filter=FIREDATE>='2025-06-01'"
```

### Response Schema (GML)

The response contains detailed fire incident data:

| Field | Type | Description |
|-------|------|-------------|
| `ms:id` | Integer | Unique fire identifier |
| `ms:FIREDATE` | DateTime | Detection timestamp (UTC) |
| `ms:LASTUPDATE` | Date | Most recent data update |
| `ms:COUNTRY` | String | Country code (e.g., "UK") |
| `ms:PROVINCE` | String | Administrative region |
| `ms:COMMUNE` | String | Local area name |
| `ms:AREA_HA` | Float | Burnt area in hectares |
| `ms:BROADLEAVED` | Float | % broadleaved forest |
| `ms:CONIFEROUS` | Float | % coniferous forest |
| `ms:MIXED` | Float | % mixed forest |
| `ms:SCLEROPHYLLOUS` | Float | % sclerophyllous vegetation |
| `ms:TRANSITIONAL` | Float | % transitional woodland |
| `ms:OTHER_NATURAL` | Float | % other natural (moorland, heath) |
| `ms:OTHER` | Float | % other land cover |
| `gml:posList` | Coordinates | Polygon boundary points (lat lon pairs) |

### Sort by Date

Use `sortBy` parameter for chronological ordering:

```bash
# Most recent fires first
sortBy=FIREDATE+D

# Oldest fires first
sortBy=FIREDATE+A

# Example: Latest 10 fires in Scotland
curl -s "https://maps.effis.emergency.copernicus.eu/effis?\
service=WFS&\
version=1.1.0&\
request=GetFeature&\
typeName=ms:modis.ba.poly.season&\
bbox=54.5,-9.0,61.0,0.0,EPSG:4326&\
sortBy=FIREDATE+D&\
count=10"
```

### Example: June 28, 2025 Scotland Fire

Query that discovered fire ID 273772 (9,809 hectare moorland fire):

```bash
curl -s "https://maps.effis.emergency.copernicus.eu/effis?\
service=WFS&\
version=1.1.0&\
request=GetFeature&\
typeName=ms:modis.ba.poly.season&\
bbox=54.5,-9.0,61.0,0.0,EPSG:4326&\
count=1000" | grep -E "2025-06-28|AREA_HA|COMMUNE"
```

**Result:**
- Fire ID: 273772
- Date: 2025-06-28T11:53:00
- Location: West Moray, Inverness & Nairn and Moray, Badenoch & Strathspey
- Area: 9,809.46 hectares
- Land cover: 93.24% moorland (OTHER_NATURAL), 4.24% transitional woodland

### Multi-Polygon Fires

Large fires may contain multiple polygon rings representing:
1. **Outer ring**: Main fire boundary
2. **Inner rings**: Unburnt islands within the fire perimeter

The June 28 Scotland fire contains **24 polygon rings** with **22,020 total coordinate points**.

### Test Fixtures

A pre-parsed fixture is available at:
- **JSON**: `assets/mock/scotland_fire_273772.json`
- **Dart fixture**: `test/fixtures/scotland_fire_273772_fixture.dart`

---

## Understanding FIREDATE and LASTUPDATE

### Why Fires Only Appear on One Date

A common question: *"Why does a large fire show on June 28 but not on June 27 or 29?"*

The answer lies in understanding what EFFIS date fields actually represent:

| Field | Meaning | Fire 273772 Example |
|-------|---------|---------------------|
| `FIREDATE` | **First satellite detection** timestamp | `2025-06-28T11:53:00` |
| `LASTUPDATE` | When polygon boundary was last refined | `2025-07-09T13:28:59` |

### The EFFIS Burnt Area Timeline

```
June 27        June 28         June 29-July 1      July 9
    |              |                |                 |
    v              v                v                 v
No detection → FIRST THERMAL → Fire continues → Polygon
               DETECTION        burning           finalized
               (11:53 UTC)      (NO new polygon)  (LASTUPDATE)
               
               FIREDATE         Still one         Final boundary
               assigned         polygon with      with all 9,809 ha
                               FIREDATE=28th
```

### Key Insights

1. **FIREDATE = First Detection, Not Fire Duration**
   - The Dava Moor fire burned for **4 days** (June 28 - July 1)
   - But EFFIS assigns only ONE `FIREDATE`: when it was first detected
   - Querying June 29, 30, or July 1 returns nothing - the fire already has its date

2. **Burnt Areas vs Active Fires**
   - **Burnt area polygons** (`ms:modis.ba.poly.*`): Created AFTER fire ends
   - **Active fire hotspots** (`ms:modis.hs`, `ms:viirs.hs`): Near-real-time during fire

3. **To Query "What Was Burning on Date X"**
   - Use **active fire hotspots** for fires burning on a specific date
   - Use **burnt area polygons** for historical damage assessment after fires end

### Practical Query Examples

```bash
# Find fires DETECTED on a specific date (first detection only)
cql_filter=FIREDATE='2025-06-28'

# Find fires UPDATED after a date (includes polygon refinements)
cql_filter=LASTUPDATE>='2025-07-01'

# Find fires that burned ≥1000 hectares (regardless of date)
cql_filter=AREA_HA>=1000

# Scottish Wildfire Forum noted: "Main fire run 28 June - 1 July 2025"
# But EFFIS shows: FIREDATE=28, LASTUPDATE=July 9 (single polygon, 9,809 ha)
```

### Active Fire Layers for Real-Time Tracking

If you need to track fires **while they're burning**, use hotspot layers:

| Layer | Source | Update Frequency |
|-------|--------|------------------|
| `ms:viirs.hs` | VIIRS (Suomi NPP, NOAA-20) | ~3 hours |
| `ms:modis.hs` | MODIS (Terra, Aqua) | ~4 hours |
| `ms:noaa.hs` | NOAA satellites | ~6 hours |
| `ms:all.hs` | Combined all sources | Rolling |

**Note:** Hotspot layers are ephemeral - they show current thermal anomalies, not historical records.

---

## Satellite Sensor Comparison

Understanding the differences between satellite sensors helps choose the right data for your use case.

### VIIRS vs MODIS vs NOAA

| Aspect | VIIRS | MODIS | NOAA (AVHRR) |
|--------|-------|-------|--------------|
| **Resolution** | **375m** (best) | 1km | 1.1km |
| **Satellites** | Suomi NPP, NOAA-20, NOAA-21 | Terra, Aqua | NOAA-18, NOAA-19 |
| **Orbit** | Polar, 14 passes/day | Polar, 4 passes/day | Polar, ~4 passes/day |
| **First Launch** | 2011 | 1999 | 1978 (legacy) |
| **Fire Detection** | 375m I-band thermal | 1km thermal | 1.1km thermal |
| **Best For** | Small fires, precision | Historical continuity | Backup/validation |

### Why VIIRS is Recommended

1. **4x Better Resolution**: 375m vs 1km means VIIRS can detect fires ~16x smaller in area
2. **More Satellites**: 3 VIIRS satellites (Suomi NPP, NOAA-20, NOAA-21) vs 2 MODIS (Terra, Aqua)
3. **More Frequent Passes**: ~14 observations/day globally vs ~4 for MODIS
4. **Better Night Detection**: Improved I-band sensor for low-light conditions
5. **Reduced False Positives**: Better algorithms reject industrial heat sources

### Sensor Resolution Visual Comparison

```
VIIRS (375m pixel)         MODIS (1km pixel)
┌───┬───┬───┐              ┌─────────────────┐
│ 🔥│   │   │              │                 │
├───┼───┼───┤              │       🔥        │
│   │   │   │              │    (entire      │
├───┼───┼───┤              │     pixel)      │
│   │   │   │              │                 │
└───┴───┴───┘              └─────────────────┘
9 pixels = same area        1 pixel

A 500m fire:
- VIIRS: Detected in 1-2 pixels with precise location
- MODIS: Detected in 1 pixel, location uncertainty ±500m
```

### When to Use Each Sensor

| Use Case | Recommended Sensor | Reason |
|----------|-------------------|--------|
| **Real-time alerts** | VIIRS | Best resolution, most frequent |
| **Small fires (<1km²)** | VIIRS | Only sensor that can detect |
| **Historical analysis (pre-2012)** | MODIS | VIIRS not available before 2011 |
| **Validation/cross-check** | All sensors | Compare for confidence |
| **UK/Scotland fires** | VIIRS | Small moorland fires need resolution |

### Hotspot Data Fields

When querying hotspot data via WFS, these fields are available:

| Field | Description | Example Value |
|-------|-------------|---------------|
| `id` | Unique hotspot identifier | `41646539755` |
| `acq_at` | Detection timestamp (UTC) | `2025-12-08 02:08:00` |
| `lat` / `lon` | Coordinates | `57.2`, `-3.8` |
| `frp` | Fire Radiative Power (MW) | `15.3` (intensity) |
| `confidence` | Detection confidence | `high`, `nominal`, `low` |
| `night` | Night-time detection | `true` / `false` |
| `satellite` | Source satellite | `N20` (NOAA-20) |
| `bright_mir` | Mid-infrared brightness (K) | `342.5` |
| `bright_tir` | Thermal infrared brightness (K) | `298.1` |
| `scan` / `track` | Pixel dimensions (km) | `0.39`, `0.45` |
| `CLASS` | Temporal classification | `1DAY_1` = today |

**Note:** Hotspots are **points only** - they do NOT have area data. For area measurements, use burnt area polygons (`AREA_HA` field).

---

## Map Implementation Recommendations

### Recommended Layer Strategy

For a user-friendly fire map application, use this layered approach:

| Layer Type | Endpoint | Layer | User Toggle Label |
|------------|----------|-------|-------------------|
| **Today's Fires** | GWIS WMS | `viirs.hs.today` | "Active Fires (24h)" |
| **Recent Fires** | GWIS WMS | `viirs.hs.week` | "Recent Activity (7d)" |
| **Burnt Areas** | EFFIS WFS | `modis.ba.poly.season` | "Fire Damage" |

### Endpoint URLs for Implementation

```dart
// 1. WMTS Tiles - Fast raster display for zoomed-out view
const wmtsTileUrl = 'https://maps.effis.emergency.copernicus.eu/gwist/wmts'
    '?SERVICE=WMTS&VERSION=1.0.0&REQUEST=GetTile'
    '&LAYER=viirs.hs.today'  // or viirs.hs.week
    '&FORMAT=image/png'
    '&TILEMATRIXSET=EPSG:3857'
    '&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}';

// 2. WMS GetFeatureInfo - Tap hotspot for details
const wmsInfoUrl = 'https://maps.effis.emergency.copernicus.eu/gwis'
    '?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo'
    '&LAYERS=viirs.hs.today&QUERY_LAYERS=viirs.hs.today'
    '&CRS=EPSG:4326&BBOX={bbox}'
    '&WIDTH=256&HEIGHT=256&I={pixelX}&J={pixelY}'
    '&INFO_FORMAT=application/vnd.ogc.gml';

// 3. WFS Burnt Areas - Polygon overlay with area data
const wfsBurntUrl = 'https://maps.effis.emergency.copernicus.eu/effis'
    '?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature'
    '&TYPENAMES=ms:modis.ba.poly.season'
    '&BBOX={bbox},EPSG:4326'
    '&OUTPUTFORMAT=geojson';
```

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        MAP DISPLAY                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐   ┌─────────────────┐   ┌───────────────┐ │
│  │ Google Maps     │ + │ WMTS Hotspot    │ + │ Burnt Area    │ │
│  │ Base Map        │   │ Tile Overlay    │   │ Polygons      │ │
│  └─────────────────┘   └─────────────────┘   └───────────────┘ │
│                                                                 │
│  Zoom < 8:  Show WMTS tiles only (clustered view)              │
│  Zoom ≥ 8:  Show individual markers + polygons                 │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Filter:  [🔥 Today] [📅 This Week] [🗺️ Burnt Areas]        ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘

Data Flow:
• Tiles:    GWIST WMTS → viirs.hs.today (raster for overview)
• Details:  GWIS WMS GetFeatureInfo → viirs.hs.today (tap info)
• Areas:    EFFIS WFS → modis.ba.poly.season (polygon + AREA_HA)
```

### User-Friendly Display Guidelines

| Data Element | Show to User | Hide from User |
|--------------|--------------|----------------|
| Detection time | "Detected 2 hours ago" | Raw UTC timestamp |
| Confidence | "High confidence" icon | Numeric value |
| Fire intensity | 🔥🔥🔥 icons by FRP | Raw MW value |
| Satellite | "VIIRS satellite" | "N20" code |
| Coordinates | On tap only | Not in list view |
| Burnt area | "950 hectares affected" | AREA_HA field name |

### Zoom-Based Visibility

| Zoom Level | Display |
|------------|---------|
| 0-5 | Country-level WMTS tile overlay only |
| 6-7 | Regional WMTS tiles, no individual markers |
| 8-10 | Individual hotspot markers appear |
| 11+ | Burnt area polygons + detailed markers |

This prevents visual clutter at low zoom levels while providing detail when users zoom in.

---

## Alternative Data Sources

### NASA FIRMS

**URL:** `https://firms.modaps.eosdis.nasa.gov/`

NASA Fire Information for Resource Management System provides active fire hotspot data globally.

| Aspect | Details |
|--------|---------|
| Data Type | Active fire hotspots (points only) |
| Resolution | VIIRS: 375m, MODIS: 1km |
| Latency | Near-real-time (~3 hours) |
| API | REST/CSV with MAP_KEY |
| Burnt Areas | ❌ Not provided (hotspots only) |

**API Example:**
```
https://firms.modaps.eosdis.nasa.gov/api/area/csv/{MAP_KEY}/VIIRS_SNPP_NRT/{bbox}/{days}
```

Requires free registration for MAP_KEY.

### EFFIS vs NASA FIRMS

| Feature | EFFIS | NASA FIRMS |
|---------|-------|------------|
| FWI Forecast | ✅ Yes | ❌ No |
| Active Fires | ✅ Yes | ✅ Yes |
| Burnt Area Polygons | ✅ Yes | ❌ No |
| European Focus | ✅ Yes | Global |
| Resolution | ~1km | 375m-1km |
| Registration Required | No | Yes (free) |

---

## Understanding Hotspot Pixel Limitations

### Why Hotspots Cannot Accurately Measure Fire Area

From the **NASA FIRMS FAQ**:

> "It is not recommended to use active fire locations to estimate burned area as determining burned area to an acceptable degree of accuracy is not possible due to nontrivial spatial and temporal sampling issues."

### The Problem: Pixels Are Not Fire Boundaries

Each hotspot detection represents a **pixel center**, not the actual fire location or extent:

```
What the satellite sees:        What the fire actually is:
┌─────────────────┐             
│                 │                    🔥🔥
│        •        │  ← Pixel          🔥🔥🔥
│    (center)     │    center           🔥
│                 │                    
└─────────────────┘             
     375m × 375m                   ~200m actual
     
Reported: 0.14 km²              Actual: ~0.04 km²
```

### Pixel Size Varies by Satellite Position

The `scan` and `track` fields in hotspot data show actual pixel size:

| Satellite Position | Nominal Size | Actual Pixel Size |
|-------------------|--------------|-------------------|
| Nadir (directly below) | 375m × 375m | ~375m × 375m |
| Edge of swath | 375m × 375m | **~800m × 800m** |

This "bow-tie effect" causes pixels at the swath edge to be larger and overlap:

```
Nadir (accurate)              Edge of swath (distorted)
┌───┬───┬───┐                 ╱▔▔▔▔▔▔▔▔▔▔▔╲
│   │   │   │                ╱    ╱    ╲    ╲
├───┼───┼───┤               ╱    ╱      ╲    ╲
│   │   │   │              ╱    ╱   🔥   ╲    ╲
└───┴───┴───┘             ╱____╱__________╲____╲
Regular grid              Distorted pixels overlap
```

### Multiple Passes = Duplicated Detections

A fire detected on multiple satellite passes can appear "bigger" due to pixel center shifts:

```
Pass 1 (1:30 AM):  Fire at (57.1234, -3.4567)
Pass 2 (1:30 PM):  Fire at (57.1256, -3.4589)  ← Shifted ~200m

If naively merged as separate pixels:
→ Estimated area: 2 × 0.14 km² = 0.28 km²
→ Actual fire: might be only 0.05 km²
```

### Large Fire Example: Dava Moor (9,809 hectares)

For a fire of ~98 km²:
- **Theoretical pixels needed**: ~700 pixels (at 375m resolution)
- **But**: Fire burns over 4 days, satellite passes ~4 times/day
- **Each pass**: Only captures actively burning portion at that moment
- **Cumulative pixels**: Could massively overcount if merged naively

### What Each Data Type Actually Represents

| Data Type | What It Measures | Accuracy |
|-----------|------------------|----------|
| **Hotspot point** | "A fire exists somewhere in this ~375m pixel" | ±200m location |
| **Clustered hotspots** | Cumulative thermal detections over time | Overestimates area |
| **EFFIS Burnt Area** | Verified post-fire damage polygon | ±30m boundary |
| **FRP (Fire Radiative Power)** | Energy output in megawatts | Fire intensity, not size |

### Recommendation for Applications

| Use Case | Recommended Data | Avoid |
|----------|------------------|-------|
| "Where are fires burning now?" | Hotspot points | - |
| "How big is the fire?" | EFFIS burnt areas (`AREA_HA`) | Clustered hotspots |
| "How intense is the fire?" | FRP (megawatts) | - |
| "Show fire history" | EFFIS burnt area polygons | Accumulated hotspots |

**If displaying hotspot clusters**, label clearly:
- ✅ "Estimated active fire extent"
- ❌ "Fire area" or "Burnt area"

---

## Hotspot Data Lifecycle: Persistence and Time Windows

### How Hotspots "Age Out" of Views

Hotspots are **not deleted** - they're organized into **time-windowed layers**:

| Layer | Time Window | Use Case |
|-------|-------------|----------|
| `viirs.hs.today` | Rolling 24 hours | "What's burning now?" |
| `viirs.hs.week` | Rolling 7 days | "Recent fire activity" |
| `viirs.hs` (archive) | All historical data | Research, analysis |

**Lifecycle example**:
```
Day 1: Fire detected
  → Appears in: .today ✓, .week ✓, archive ✓

Day 2: Fire still burning, new hotspots added
  → Day 1 hotspots: .today ✗, .week ✓, archive ✓
  → Day 2 hotspots: .today ✓, .week ✓, archive ✓

Day 8: Fire extinguished
  → All hotspots: .today ✗, .week ✗, archive ✓
```

### NASA FIRMS Historical Data Retention

All hotspot data is **permanently archived**:

| Sensor | Data Available From | Archive Access |
|--------|---------------------|----------------|
| MODIS (Terra/Aqua) | November 2000 | Full archive |
| VIIRS S-NPP | January 2012 | Full archive |
| VIIRS NOAA-20 | April 2018 | Full archive |
| VIIRS NOAA-21 | January 2024 | Full archive |
| Landsat | June 2022 | Full archive |

### Accessing Historical Hotspot Data

**Option 1: NASA FIRMS Map Viewer** (interactive, no login for viewing)

URL format: `https://firms.modaps.eosdis.nasa.gov/map/#d:{DATE};@{LON},{LAT},{ZOOM}z`

Example for Dava Moor fire (June 28 - July 1, 2025):
- June 28: `https://firms.modaps.eosdis.nasa.gov/map/#d:2025-06-28;@-3.7,57.4,10.0z`
- June 29: `https://firms.modaps.eosdis.nasa.gov/map/#d:2025-06-29;@-3.7,57.4,10.0z`
- June 30: `https://firms.modaps.eosdis.nasa.gov/map/#d:2025-06-30;@-3.7,57.4,10.0z`
- July 1: `https://firms.modaps.eosdis.nasa.gov/map/#d:2025-07-01;@-3.7,57.4,10.0z`

To view cumulative spread:
1. Click "Advanced" in time selector
2. Set custom date range

**Option 2: NASA FIRMS Archive Download** (requires Earthdata login)

URL: `https://firms.modaps.eosdis.nasa.gov/download/`

- Download as: Shapefile, CSV, or JSON
- Filter by: Date range, geographic area, satellite
- Standard quality data available ~5 months after NRT

**Option 3: GWIS/EFFIS Viewers**

- GWIS: `https://gwis.jrc.ec.europa.eu/apps/gwis.statistics/currentSituation`
- EFFIS: `https://effis.jrc.ec.europa.eu/apps/effis.statistics/currentSituation`

Use the date picker to navigate to historical dates.

### Satellite Pass Frequency

Understanding pass frequency helps interpret hotspot data:

| Sensor | Satellites | Passes/Day (mid-latitudes) | Orbit Type |
|--------|------------|---------------------------|------------|
| VIIRS | 3 (S-NPP, NOAA-20, NOAA-21) | ~6-8 | Polar, ~14 orbits/day |
| MODIS | 2 (Terra, Aqua) | ~4 | Polar |
| GOES | 2 (GOES-16, GOES-19) | Continuous | Geostationary |

**For Scotland** (latitude ~57°N):
- VIIRS: ~3-4 daytime + 3-4 nighttime passes per day
- Each pass captures a "snapshot" - actively burning area only
- Large fires detected on multiple passes show fire spread over time

### Why You See Multiple Hotspots for One Fire

```
Pass 1 (02:00 UTC)    Pass 2 (13:30 UTC)    Pass 3 (14:20 UTC)
      🔥                   🔥🔥                  🔥🔥🔥
                           🔥                    🔥🔥

Fire is spreading, each pass captures current state.
Cumulative view shows "fire progression" not "simultaneous extent".
```

---

## Alternative Tracker: Scotland Wildfire Tracker (Strathclyde)

**URL:** `https://ee-eif-uni-of-strathclyde.projects.earthengine.app/view/scotland-wildfire-tracker`

This Google Earth Engine application provides an alternative view of Scottish wildfires.

### Data Sources Used

| Data Type | Source | Resolution |
|-----------|--------|------------|
| Active Fires | `NASA/LANCE/SNPP_VIIRS/C2` | 375m |
| Before/After Imagery | `COPERNICUS/S2_HARMONIZED` (Sentinel-2) | 10m |
| Admin Boundaries | `FAO/GAUL_SIMPLIFIED_500m/2015/level2` | 500m |

### How They Calculate "Fire Area"

The tracker derives area by **clustering hotspot pixels** - NOT from verified burnt area data:

```javascript
// Their algorithm (simplified):
// 1. Mosaic VIIRS hotspots from last 3 days
viirsMosaic = firesCollection.qualityMosaic('confidence');

// 2. Convert hotspot pixels to polygons at 375m scale
fireVectors = viirsMosaic.reduceToVectors({
  scale: 375,              // VIIRS resolution
  geometryType: 'polygon', // Merge adjacent pixels
  eightConnected: true     // Include diagonal neighbors
});

// 3. Calculate area from merged polygon geometry
area = feature.geometry().area();  // Returns m²
```

### Limitations of This Approach

| Issue | Impact |
|-------|--------|
| Multi-day accumulation | Fire on Day 1 + Day 2 = larger polygon (overcounts) |
| Pixel shift between passes | Same fire detected at different locations |
| Sub-pixel fires | 100m fire triggers full 375m pixel |
| No verification | Purely algorithmic, no analyst review |

### Comparison: Strathclyde vs EFFIS

| Aspect | Strathclyde Tracker | EFFIS |
|--------|---------------------|-------|
| Area Source | Derived from hotspot clustering | Verified burnt area polygons |
| Update Speed | Real-time (last 3 days) | Post-fire (days to weeks) |
| Before/After | ✅ Sentinel-2 comparison | ❌ Not available |
| Geographic Focus | Scotland/UK only | Europe/Global |
| API Access | Earth Engine only (no REST) | WMS/WFS/WMTS (open) |
| Area Accuracy | Rough estimate | Verified (±30m boundary) |

### Key Feature: Before/After Imagery

The tracker's compelling feature is Sentinel-2 split-view comparison:
- **Before**: Composite from 60-14 days before fire
- **After**: Latest imagery from past 3 days
- **Visualization**: RGB, NIR, and SWIR false color options

This could be replicated using:
- Sentinel Hub API (commercial)
- Copernicus Data Space (free, requires registration)
- Google Earth Engine (requires GEE account)

---

## How EFFIS Derives Burnt Area Data

EFFIS processes raw satellite imagery to derive burnt area polygons - they do NOT use pre-processed NASA products.

### Data Processing Pipeline

1. **Raw Input:**
   - MODIS 250m surface reflectance imagery
   - Sentinel-2 20m multispectral imagery (since 2018)
   - VIIRS active fire hotspots

2. **EFFIS Processing (at JRC):**
   - Semi-automatic classification algorithms
   - Unsupervised spectral classification
   - Visual verification by analysts

3. **Output Products:**
   - MODIS-derived burnt areas: Used for official EU statistics (≥30 ha)
   - VIIRS-derived perimeters: Display only, automatically generated
   - Sentinel-2 enhanced: Higher detail for fires since 2018

### Why EFFIS, Not NASA MCD64A1?

| Product | Resolution | Temporal | Use Case |
|---------|-----------|----------|----------|
| EFFIS Burnt Areas | 250m-20m | Near-real-time | Emergency response |
| NASA MCD64A1 | 500m | Monthly | Climate research |

EFFIS prioritizes rapid assessment over global consistency.

---

## Troubleshooting

### Common Issues

#### "No FWI data available"
- **Cause:** Using legacy endpoint OR future date
- **Fix:** Use `maps.effis.emergency.copernicus.eu` and current/past dates

#### "Oracle connection failure" on WFS
- **Cause:** Using legacy endpoint `ies-ows.jrc.ec.europa.eu`
- **Fix:** Migrate to `maps.effis.emergency.copernicus.eu`

#### Empty GML response for FWI
- **Cause:** Query layer doesn't support `application/json` format
- **Fix:** Use `INFO_FORMAT=application/vnd.ogc.gml` or `text/plain`

#### FWI values all zeros
- **Cause:** Normal in winter for northern regions (Scotland, Scandinavia)
- **Not a bug:** Low fire risk during cold/wet seasons

### Testing Endpoints

```bash
# Test FWI (Scotland - expect low values in winter)
DATE=$(date -u +%Y-%m-%d)
curl -s "https://maps.effis.emergency.copernicus.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=nasa_geos5.query&QUERY_LAYERS=nasa_geos5.query&CRS=EPSG:4326&BBOX=56.9,-3.9,57.1,-3.7&WIDTH=256&HEIGHT=256&I=128&J=128&INFO_FORMAT=application/vnd.ogc.gml&STYLES=&TIME=${DATE}"

# Test WFS burnt areas
curl -s "https://maps.effis.emergency.copernicus.eu/effis?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAME=ms:modis.ba.poly&OUTPUTFORMAT=GML3&COUNT=5"
```

---

## Migration Checklist

When migrating from legacy to current endpoint:

- [ ] Update base URL from `ies-ows.jrc.ec.europa.eu` to `maps.effis.emergency.copernicus.eu`
- [ ] Verify WMS layer names match (same on both endpoints)
- [ ] Update WFS layer names if using deprecated names
- [ ] Use `INFO_FORMAT=application/vnd.ogc.gml` (not `application/json`)
- [ ] Add `STYLES=` parameter (required on new endpoint)
- [ ] Test with current date to verify data availability
- [ ] Update error handling for new error formats

---

## References

- **EFFIS Official:** https://forest-fire.emergency.copernicus.eu/
- **Data & Services:** https://forest-fire.emergency.copernicus.eu/applications/data-and-services
- **Download Instructions:** https://forest-fire.emergency.copernicus.eu/downloads-instructions
- **Data License:** https://forest-fire.emergency.copernicus.eu/about-effis/data-license
- **NASA FIRMS:** https://firms.modaps.eosdis.nasa.gov/
- **Copernicus EMS:** https://emergency.copernicus.eu/

---

*Document created: 2025-12-08*
*Based on API testing and official EFFIS documentation*
