# API Endpoints Summary

**Generated:** 2026-01-26  
**Purpose:** Verify API calls for hotspots, burnt areas, and FWI data

---

## 1. Fire Weather Index (FWI)

### Service
**File:** `lib/services/effis_service_impl.dart`  
**Class:** `EffisServiceImpl`

### Base URL
```
https://maps.effis.emergency.copernicus.eu/gwis
```

### Request Details
**Protocol:** WMS GetFeatureInfo  
**Layer:** `nasa_geos5.query`  
**Format:** `text/plain`  
**Coordinate System:** EPSG:4326 (WGS84)

### Full Request URL Pattern
```
https://maps.effis.emergency.copernicus.eu/gwis?
  SERVICE=WMS&
  VERSION=1.3.0&
  REQUEST=GetFeatureInfo&
  LAYERS=nasa_geos5.query&
  QUERY_LAYERS=nasa_geos5.query&
  CRS=EPSG:4326&
  BBOX={minLat},{minLon},{maxLat},{maxLon}&
  WIDTH=256&
  HEIGHT=256&
  STYLES=&
  I=128&
  J=128&
  INFO_FORMAT=text/plain&
  FEATURE_COUNT=1&
  TIME={currentDate}
```

### Parameters
- **BBOX:** Small bounding box around point (±0.1 degrees ~ 11km buffer)
- **TIME:** Current date in YYYY-MM-DD format (e.g., `2026-01-26`)
- **I/J:** Query point coordinates (128,128 = center of 256x256 grid)

### Retry Configuration
- **Timeout:** 30 seconds (default)
- **Max Retries:** 3 (default)
- **Backoff:** Exponential with jitter

### Example Call
For Edinburgh (55.9533, -3.1883):
```
https://maps.effis.emergency.copernicus.eu/gwis?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=nasa_geos5.query&QUERY_LAYERS=nasa_geos5.query&CRS=EPSG:4326&BBOX=55.8533,-3.2883,56.0533,-3.0883&WIDTH=256&HEIGHT=256&STYLES=&I=128&J=128&INFO_FORMAT=text/plain&FEATURE_COUNT=1&TIME=2026-01-26
```

---

## 2. Hotspots (VIIRS Satellite Detections)

### Service
**File:** `lib/services/gwis_hotspot_service_impl.dart`  
**Class:** `GwisHotspotServiceImpl`

### Base URL
```
https://maps.effis.emergency.copernicus.eu/gwis
```

### Request Details
**Protocol:** WFS GetFeature  
**Format:** GeoJSON (`application/json`)  
**Coordinate System:** EPSG:4326

### Available Layers
| Layer Name | Time Filter | Description |
|------------|-------------|-------------|
| `viirs.hs.today` | Today | Last 24 hours |
| `viirs.hs.week` | This Week | Last 7 days |

### Full Request URL Pattern
```
https://maps.effis.emergency.copernicus.eu/gwis?
  service=WFS&
  version=2.0.0&
  request=GetFeature&
  typeName={layer}&
  outputFormat=application/json&
  srsName=EPSG:4326&
  bbox={swLon},{swLat},{neLon},{neLat},EPSG:4326
```

### Parameters
- **typeName:** Layer name (e.g., `viirs.hs.today`)
- **bbox:** Bounding box as `{swLon},{swLat},{neLon},{neLat},EPSG:4326`
- **outputFormat:** `application/json` (GeoJSON)

### Retry Configuration
- **Timeout:** 8 seconds (default)
- **Max Retries:** 3 (default)
- **Backoff:** Exponential with jitter

### Response Format
GeoJSON FeatureCollection with properties:
- **frp:** Fire Radiative Power (MW)
- **confidence:** Detection confidence (0-100%)
- **acq_date:** Acquisition date/time

### Example Call
For Scotland bounds (54.0°N to 61.0°N, -8.0°W to 0.0°E):
```
https://maps.effis.emergency.copernicus.eu/gwis?service=WFS&version=2.0.0&request=GetFeature&typeName=viirs.hs.today&outputFormat=application/json&srsName=EPSG:4326&bbox=-8.0,54.0,0.0,61.0,EPSG:4326
```

---

## 3. Burnt Areas (MODIS Polygons)

### Service
**File:** `lib/services/effis_burnt_area_service_impl.dart`  
**Class:** `EffisBurntAreaServiceImpl`

### Base URL
```
https://maps.effis.emergency.copernicus.eu/effis
```

### Request Details
**Protocol:** WFS GetFeature  
**Layer:** `ms:modis.ba.poly`  
**Format:** GML3 (XML) - **NOT JSON** (JSON fails with bbox filters)  
**Coordinate System:** EPSG:4326

### Full Request URL Pattern
```
https://maps.effis.emergency.copernicus.eu/effis?
  service=WFS&
  version=2.0.0&
  request=GetFeature&
  typeName=ms:modis.ba.poly&
  outputFormat=text/xml;subtype=gml/3.1.1&
  srsName=EPSG:4326&
  bbox={swLon},{swLat},{neLon},{neLat}&
  sortBy=firedate {A|D}&
  maxFeatures={limit}
```

### Parameters
- **typeName:** `ms:modis.ba.poly` (generic layer for all years)
- **outputFormat:** `text/xml;subtype=gml/3.1.1` (GML3 format)
- **bbox:** Bounding box as `{swLon},{swLat},{neLon},{neLat}`
- **sortBy:** 
  - `firedate A` (Ascending) for last season - oldest first
  - `firedate D` (Descending) for this season - newest first
- **maxFeatures:** Optional limit (1-2000) to prevent large responses

### Retry Configuration
- **Timeout:** 10 seconds (default)
- **Max Retries:** 3 (default)
- **Backoff:** Exponential with jitter

### Important Notes
1. **No Pre-filtered Season Layers:** EFFIS doesn't provide separate layers for different years
2. **Client-side Year Filtering:** After parsing GML, we filter by `fireDate.year`
3. **Non-standard Content-Type:** Server returns `text/xml; subtype=gml/3.1.1; charset=UTF-8` which causes Dart's http parser to fail - we use `bodyBytes` + `utf8.decode()` to bypass
4. **Sorting Strategy:** 
   - This Season (2026): Sort descending to get newest data first
   - Last Season (2025): Sort ascending so older data appears within maxFeatures limit

### Response Format
GML3 XML with polygon geometries:
- **firedate:** Fire detection date
- **area_ha:** Area in hectares
- **landcover:** Land cover breakdown (optional)
- **polygon coordinates:** List of lat/lng points (≥3 required)

### Example Call
For Scotland bounds, this season (2026), max 100 features:
```
https://maps.effis.emergency.copernicus.eu/effis?service=WFS&version=2.0.0&request=GetFeature&typeName=ms:modis.ba.poly&outputFormat=text/xml;subtype=gml/3.1.1&srsName=EPSG:4326&bbox=-8.0,54.0,0.0,61.0&sortBy=firedate D&maxFeatures=100
```

---

## Summary Table

| Data Type | Base URL | Protocol | Layer/Query | Format | Default Timeout |
|-----------|----------|----------|-------------|--------|-----------------|
| **FWI** | maps.effis.emergency.copernicus.eu/**gwis** | WMS GetFeatureInfo | nasa_geos5.query | text/plain | 30s |
| **Hotspots** | maps.effis.emergency.copernicus.eu/**gwis** | WFS GetFeature | viirs.hs.{today\|week} | GeoJSON | 8s |
| **Burnt Areas** | maps.effis.emergency.copernicus.eu/**effis** | WFS GetFeature | ms:modis.ba.poly | GML3 (XML) | 10s |

---

## Key Differences

### Endpoints
- **FWI & Hotspots:** Use `/gwis` endpoint (Global Wildfire Information System)
- **Burnt Areas:** Use `/effis` endpoint (European Forest Fire Information System)

### Protocols
- **FWI:** WMS (Web Map Service) GetFeatureInfo - point query
- **Hotspots & Burnt Areas:** WFS (Web Feature Service) GetFeature - bbox query

### Response Formats
- **FWI:** Plain text (contains FWI value)
- **Hotspots:** GeoJSON (easy to parse, standard format)
- **Burnt Areas:** GML3 XML (complex, requires special handling for non-standard content-type)

### Time Filters
- **FWI:** Current date via `TIME` parameter
- **Hotspots:** Pre-filtered layers (today/week)
- **Burnt Areas:** Client-side year filtering after fetch (no server-side year filter available)

---

## User Agent & Headers

All services use consistent headers:
```dart
'User-Agent': 'WildFire/0.1 (prototype)'
'Accept': 'application/json,*/*;q=0.8' (FWI, Hotspots)
'Accept': 'application/xml,*/*;q=0.8' (Burnt Areas)
```

---

## Logging & Privacy

All services use privacy-compliant coordinate logging via `GeographicUtils.logRedact()`:
- Coordinates logged at 2 decimal places only (e.g., `55.95,-3.19`)
- Full URLs logged with domain only for security
- Complies with C2 constitutional gate
