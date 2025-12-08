---
title: EFFIS API Endpoints Reference
status: active
last_updated: 2025-12-08
category: reference
subcategory: api
related:
  - ../DATA-SOURCES.md
  - ../guides/setup/google-maps.md
---

# EFFIS API Endpoints Reference

This document describes the EFFIS (European Forest Fire Information System) and related fire weather data API endpoints, their capabilities, and the migration from legacy to current endpoints.

## Executive Summary

As of December 2025, EFFIS has migrated from the legacy JRC endpoint to a new Copernicus emergency endpoint. Applications must update to use the new endpoint for live data access.

| Service | Legacy Endpoint (DEPRECATED) | Current Endpoint (USE THIS) |
|---------|------------------------------|----------------------------|
| **GWIS (FWI)** | `ies-ows.jrc.ec.europa.eu/gwis` | `maps.effis.emergency.copernicus.eu/gwis` |
| **EFFIS (Fires)** | `ies-ows.jrc.ec.europa.eu/effis` | `maps.effis.emergency.copernicus.eu/effis` |

## Endpoint Comparison

### Legacy Endpoint (DEPRECATED)

**Base URL:** `https://ies-ows.jrc.ec.europa.eu/`

| Aspect | Status | Notes |
|--------|--------|-------|
| FWI WMS Data | ❌ Stale | Last data: January 31, 2025 (~10 month gap) |
| WFS Fire Incidents | ❌ Broken | Oracle database connection failure |
| Documentation | ❌ Outdated | No longer referenced in official docs |

**Error observed on WFS:**
```
msOracleSpatialLayerOpen(): OracleSpatial error. 
Cannot create OCI Handlers. Connection failure.
```

### Current Endpoint (ACTIVE)

**Base URL:** `https://maps.effis.emergency.copernicus.eu/`

| Aspect | Status | Notes |
|--------|--------|-------|
| FWI WMS Data | ✅ Live | Current date data available |
| WFS Fire Incidents | ✅ Working | Active fire hotspots and burnt areas |
| Documentation | ✅ Official | Referenced at forest-fire.emergency.copernicus.eu |

**Official documentation:** https://forest-fire.emergency.copernicus.eu/downloads-instructions

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

### Available Layers

| Layer Name | Description | Data Type |
|------------|-------------|-----------|
| `ms:all.hs` | All active fire hotspots | Points |
| `ms:all.hs.query` | All hotspots (queryable) | Points |
| `ms:viirs.hs` | VIIRS satellite hotspots | Points |
| `ms:viirs.hs.query` | VIIRS hotspots (queryable) | Points |
| `ms:modis.hs` | MODIS satellite hotspots | Points |
| `ms:modis.hs.query` | MODIS hotspots (queryable) | Points |
| `ms:noaa.hs` | NOAA satellite hotspots | Points |
| `ms:modis.ba.poly` | MODIS burnt areas | Polygons |
| `ms:modis.ba.point` | MODIS burnt area centroids | Points |
| `ms:effis.nrt.ba.poly` | Near-real-time burnt areas | Polygons |
| `ms:effis.nrt.ba.point` | NRT burnt area centroids | Points |

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
