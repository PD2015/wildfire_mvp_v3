# Data Source Attribution Guide

**Generated:** 2026-01-26  
**Purpose:** Correct source attribution for wildfire data in the app

---

## Current Implementation vs Correct Attribution

### ❌ Problem: Misleading "NASA FIRMS" Attribution

The app currently shows **"NASA FIRMS"** for hotspot data, but this is **INCORRECT** for the production implementation. Here's why:

---

## 🔥 **1. Hotspots (VIIRS Satellite Detections)**

### What Users See Now (INCORRECT)
```
"NASA FIRMS"
```

### What It Should Be (CORRECT)
```
"EFFIS/GWIS"
or
"European Commission EFFIS"
```

### Why the Confusion?

The codebase has **TWO hotspot service implementations**:

#### Option A: `FirmsHotspotService` (NOT CURRENTLY USED)
- **URL:** `https://firms.modaps.eosdis.nasa.gov/api/area`
- **Provider:** NASA FIRMS (Fire Information for Resource Management System)
- **Status:** ⚠️ **Code exists but is NOT instantiated in production**
- **Reason:** Requires API key that's not configured (no FIRMS_API_KEY in env files)

#### Option B: `GwisHotspotServiceImpl` (ACTUALLY USED) ✅
- **URL:** `https://maps.effis.emergency.copernicus.eu/gwis`
- **Provider:** EFFIS (European Forest Fire Information System) via GWIS (Global Wildfire Information System)
- **Status:** ✅ **This is what's actually running in production**
- **Layers:** `viirs.hs.today` (last 24h), `viirs.hs.week` (last 7 days)

### The Fallback Chain (from `HotspotServiceOrchestrator`)

```dart
// Current fallback order:
1. FIRMS (if API key available) → SKIPPED (no key)
2. GWIS WMS → ACTUALLY USED ✅
3. Mock data → Offline fallback
```

The orchestrator **tries** FIRMS first, but since `FeatureFlags.hasFirmsKey` is `false`, it falls through to GWIS immediately.

### Underlying Data Source

**Both services use the same satellite data:**
- **VIIRS** (Visible Infrared Imaging Radiometer Suite) on NASA/NOAA satellites
- **Suomi NPP** and **NOAA-20** polar-orbiting satellites
- Data collected by NASA → distributed through multiple channels:
  - NASA FIRMS (direct REST API)
  - EFFIS/GWIS (European integration with WFS protocol)

**Key Point:** The **satellite is NASA**, but the **API/service provider is EFFIS** in our implementation.

---

## 📍 **2. Fire Weather Index (FWI)**

### Current Attribution (CORRECT)
```
"EFFIS"
```

### Full Details
- **API:** `https://maps.effis.emergency.copernicus.eu/gwis`
- **Provider:** EFFIS (European Forest Fire Information System)
- **Data Model:** NASA GEOS-5 (Goddard Earth Observing System Model)
- **Layer:** `nasa_geos5.query`
- **Protocol:** WMS GetFeatureInfo

### Correct Attribution Options

**Option 1 (Simple):**
```
"EFFIS"
```

**Option 2 (Full credit chain):**
```
"EFFIS (NASA GEOS-5 model)"
```

**Option 3 (Academic style):**
```
"European Commission EFFIS, using NASA GEOS-5 atmospheric model"
```

---

## 🔥 **3. Burnt Areas (MODIS Polygons)**

### Current Attribution (CORRECT)
```
"EFFIS"
```

### Full Details
- **API:** `https://maps.effis.emergency.copernicus.eu/effis`
- **Provider:** EFFIS
- **Satellite:** NASA Terra/Aqua MODIS (Moderate Resolution Imaging Spectroradiometer)
- **Layer:** `ms:modis.ba.poly`
- **Protocol:** WFS GetFeature (GML3 format)

### Correct Attribution Options

**Option 1 (Simple):**
```
"EFFIS"
```

**Option 2 (Full credit chain):**
```
"EFFIS (MODIS satellite data)"
```

**Option 3 (Academic style):**
```
"European Commission EFFIS, using NASA MODIS burnt area product"
```

---

## 📊 **Recommended UI Source Labels**

### For User-Facing Display

| Data Type | Short Label | Long Label | Technical Details |
|-----------|-------------|------------|-------------------|
| **Hotspots** | `EFFIS` | `European Commission EFFIS` | Via GWIS WFS, VIIRS satellite detections |
| **FWI** | `EFFIS` | `European Commission EFFIS` | NASA GEOS-5 atmospheric model via GWIS WMS |
| **Burnt Areas** | `EFFIS` | `European Commission EFFIS` | MODIS satellite burnt area product via WFS |

### For Settings → About → Data Sources Page

```markdown
## Data Sources

### Wildfire Data Provider
All wildfire data is provided by the **European Commission's European Forest Fire 
Information System (EFFIS)** through the Global Wildfire Information System (GWIS).

**EFFIS/GWIS Endpoints:**
- Fire Weather Index: https://maps.effis.emergency.copernicus.eu/gwis
- Hotspot Detections: https://maps.effis.emergency.copernicus.eu/gwis
- Burnt Area Polygons: https://maps.effis.emergency.copernicus.eu/effis

### Underlying Satellite Data

While EFFIS provides the API infrastructure, the underlying observations come from:

**Hotspot Detections:**
- **VIIRS** (Visible Infrared Imaging Radiometer Suite)
- NASA/NOAA Suomi NPP and NOAA-20 satellites
- 375m spatial resolution, twice-daily coverage

**Burnt Area Mapping:**
- **MODIS** (Moderate Resolution Imaging Spectroradiometer)  
- NASA Terra and Aqua satellites
- 500m spatial resolution, daily coverage

**Fire Weather Index:**
- **NASA GEOS-5** atmospheric model
- Temperature, humidity, wind speed, rainfall forecasts
- Used to calculate Canadian Forest Fire Weather Index (FWI)

### Attribution
This application uses Copernicus Emergency Management Service information. 
Neither the European Commission nor ECMWF is responsible for any use that 
may be made of the information it contains.
```

---

## 🔧 **Code Changes Needed**

### 1. Fix `HotspotServiceOrchestrator` Display Names

**File:** `lib/services/hotspot_service_orchestrator.dart`

```dart
// CURRENT (INCORRECT):
enum HotspotDataSource {
  firms('NASA FIRMS'),  // ❌ Wrong - this service is never used!
  gwis('GWIS'),
  mock('Demo');
}

// SHOULD BE:
enum HotspotDataSource {
  firms('NASA FIRMS'),        // Only shown if FIRMS API key configured
  gwis('EFFIS/GWIS'),         // ✅ This is what users actually see
  mock('Demo');
}
```

### 2. Update Service `serviceName` Properties

**File:** `lib/services/gwis_hotspot_service_impl.dart`

```dart
class GwisHotspotServiceImpl implements GwisHotspotService {
  // Add this property:
  @override
  String get serviceName => 'EFFIS/GWIS';
}
```

### 3. Update Documentation Comments

Remove references to "NASA FIRMS as primary" in:
- `lib/services/hotspot_service_orchestrator.dart` (lines 42-44)
- `lib/features/map/controllers/map_controller.dart` (line 24)

Replace with: "EFFIS/GWIS via WFS (primary data source for hotspots)"

---

## 🎯 **Summary: What to Show Users**

### Simple Approach (Recommended)
Just use **"EFFIS"** for everything. It's the actual API provider and keeps the UI clean.

### Transparent Approach (More Accurate)
- **Hotspots:** "EFFIS/GWIS (VIIRS satellite)"
- **FWI:** "EFFIS (NASA GEOS-5 model)"  
- **Burnt Areas:** "EFFIS (MODIS satellite)"

### Academic/Research Approach
Include full attribution in Settings → About → Data Sources with complete credit chain.

---

## 🚨 **Why This Matters**

1. **Legal Compliance:** EFFIS terms of use require proper attribution
2. **User Trust:** Accurate source information builds credibility
3. **Debugging:** Correct labels help diagnose issues ("Is EFFIS down?" vs "Is NASA FIRMS down?")
4. **Documentation Accuracy:** Current docs mention NASA FIRMS as primary source, but it's not used

---

## 📝 **Next Steps**

1. **Update `HotspotDataSource.gwis` display name** to `'EFFIS/GWIS'`
2. **Add `serviceName` getter** to `GwisHotspotServiceImpl`
3. **Create comprehensive Data Sources page** in Settings → About
4. **Update API_ENDPOINTS_SUMMARY.md** to clarify FIRMS vs GWIS usage
5. **Consider adding feature flag toggle** to switch between FIRMS and GWIS if/when FIRMS API key is obtained
