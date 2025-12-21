# EffisBurntAreaService Contract

**Feature Branch**: `021-live-fire-data`  
**Date**: 2025-12-09

---

## Service Interface

```dart
/// Service for fetching verified burnt area polygons from EFFIS WFS
abstract class EffisBurntAreaService {
  /// Fetch burnt areas within viewport for current fire season
  ///
  /// [bounds] - Geographic viewport (southwest/northeast corners)
  /// [simplify] - Apply Douglas-Peucker simplification (default: true)
  /// [deadline] - Request timeout (default: 15s for larger payloads)
  ///
  /// Returns:
  /// - Right(List<BurntArea>) on success
  /// - Left(ApiError) on failure
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    bool simplify = true,
    Duration? deadline,
  });
}
```

---

## API Contract

### Endpoint

```
GET https://maps.effis.emergency.copernicus.eu/effis
```

### Request Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| SERVICE | WFS | Web Feature Service |
| VERSION | 2.0.0 | WFS version |
| REQUEST | GetFeature | Fetch features |
| TYPENAMES | ms:modis.ba.poly.season | Seasonal burnt areas |
| BBOX | minLat,minLon,maxLat,maxLon,EPSG:4326 | Viewport bounds |
| OUTPUTFORMAT | application/json | GeoJSON response |
| COUNT | 100 | Max features returned |

### Example Request

```
https://maps.effis.emergency.copernicus.eu/effis?
  SERVICE=WFS&
  VERSION=2.0.0&
  REQUEST=GetFeature&
  TYPENAMES=ms:modis.ba.poly.season&
  BBOX=55.0,-5.0,58.0,-2.0,EPSG:4326&
  OUTPUTFORMAT=application/json&
  COUNT=100
```

### Response (GeoJSON)

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "modis.ba.poly.season.273772",
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [-3.622999, 57.472033],
            [-3.622877, 57.472131],
            ...
          ]
        ]
      },
      "properties": {
        "id": 273772,
        "FIREDATE": "2025-06-28T11:53:00",
        "LASTUPDATE": "2025-07-09",
        "COUNTRY": "UK",
        "PROVINCE": "Inverness & Nairn and Moray, Badenoch & Strathspey",
        "COMMUNE": "West Moray",
        "AREA_HA": 9809.46,
        "BROADLEAVED": 0.0,
        "CONIFEROUS": 0.0,
        "MIXED": 0.0,
        "SCLEROPHYLLOUS": 0.0,
        "TRANSITIONAL": 4.24,
        "OTHER_NATURAL": 93.24,
        "OTHER": 2.52
      }
    }
  ]
}
```

### Response Field Mapping

| JSON Field | Dart Field | Type | Notes |
|------------|------------|------|-------|
| id | id | String | Fire ID |
| geometry.coordinates | boundary | List<LatLng> | GeoJSON is lon,lat |
| FIREDATE | fireDate | DateTime | First detection |
| LASTUPDATE | lastUpdate | DateTime | Polygon update |
| AREA_HA | areaHectares | double | Official area |
| COUNTRY | - | - | Not used |
| PROVINCE | province | String? | Region name |
| COMMUNE | commune | String? | Local area |
| BROADLEAVED | landCover['broadleaved'] | double | % |
| CONIFEROUS | landCover['coniferous'] | double | % |
| MIXED | landCover['mixed'] | double | % |
| SCLEROPHYLLOUS | landCover['sclerophyllous'] | double | % |
| TRANSITIONAL | landCover['transitional'] | double | % |
| OTHER_NATURAL | landCover['otherNatural'] | double | % |
| OTHER | landCover['other'] | double | % |

---

## Polygon Simplification

### Algorithm: Douglas-Peucker

```dart
/// Simplify polygon using Douglas-Peucker algorithm
/// 
/// [points] - Original polygon points
/// [tolerance] - Distance tolerance (100m = ~0.0009° at 56°N)
/// [maxPoints] - Maximum points after simplification (500)
List<LatLng> simplifyPolygon(List<LatLng> points, {
  double tolerance = 0.0009,
  int maxPoints = 500,
});
```

### Simplification Rules

| Original Points | Action | isSimplified |
|-----------------|--------|--------------|
| ≤ 500 | No simplification | false |
| > 500 | Apply Douglas-Peucker | true |
| > 500 after DP | Increase tolerance, retry | true |

---

## Error Handling

| HTTP Status | ApiError Type | Retry? |
|-------------|---------------|--------|
| 200 + empty | No data in viewport | No |
| 200 + parse error | Parsing error | No |
| 408, 504 | Timeout | Yes (2x) |
| 503 | Service unavailable | Yes (2x) |
| 4xx | Client error | No |
| 5xx | Server error | Yes (2x) |

---

## Contract Tests

```dart
// test/contract/effis_burnt_area_service_contract_test.dart

group('EffisBurntAreaService Contract', () {
  test('returns burnt areas for Scotland viewport', () async {
    final bounds = LatLngBounds(
      southwest: LatLng(55.0, -5.0),
      northeast: LatLng(58.0, -2.0),
    );
    
    final result = await service.getBurntAreas(bounds: bounds);
    
    result.fold(
      (error) => fail('Expected success, got: ${error.message}'),
      (areas) {
        for (final area in areas) {
          expect(area.id, isNotEmpty);
          expect(area.boundary.length, greaterThanOrEqualTo(3));
          expect(area.areaHectares, greaterThan(0));
          expect(area.fireDate.isBefore(DateTime.now()), isTrue);
        }
      },
    );
  });
  
  test('simplifies large polygons to max 500 points', () async {
    final result = await service.getBurntAreas(
      bounds: scotlandBounds,
      simplify: true,
    );
    
    result.fold(
      (error) => fail('Expected success'),
      (areas) {
        for (final area in areas) {
          expect(area.boundary.length, lessThanOrEqualTo(500));
          if (area.isSimplified) {
            // Simplified polygons should have significantly fewer points
            expect(area.boundary.length, lessThan(500));
          }
        }
      },
    );
  });
  
  test('preserves official AREA_HA after simplification', () async {
    // The official area should NOT be recalculated from simplified polygon
    final result = await service.getBurntAreas(
      bounds: scotlandBounds,
      simplify: true,
    );
    
    result.fold(
      (error) => fail('Expected success'),
      (areas) {
        for (final area in areas.where((a) => a.isSimplified)) {
          // AREA_HA is from EFFIS, not calculated
          expect(area.areaHectares, greaterThan(0));
        }
      },
    );
  });
  
  test('parses land cover breakdown correctly', () async {
    final result = await service.getBurntAreas(bounds: scotlandBounds);
    
    result.fold(
      (error) => fail('Expected success'),
      (areas) {
        for (final area in areas) {
          final total = area.landCover.values.fold<double>(
            0, (sum, val) => sum + val,
          );
          expect(total, lessThanOrEqualTo(100.01)); // Allow floating point
        }
      },
    );
  });
});
```

---

## Implementation Notes

1. **Coordinate Order**: GeoJSON is lon,lat; swap when parsing to LatLng
2. **Large Polygons**: Fire 273772 has 22,020 points - MUST simplify
3. **Multi-Polygon**: Large fires may have multiple rings (holes)
4. **Timeout**: Use 15s (larger payloads than hotspots)
5. **Privacy**: Log coordinates at 2dp only (C2 compliance)
6. **AREA_HA**: Use official value, never recalculate from polygon
