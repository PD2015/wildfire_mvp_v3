# GwisHotspotService Contract

**Feature Branch**: `021-live-fire-data`  
**Date**: 2025-12-09

---

## Service Interface

```dart
/// Service for fetching real-time fire hotspot data from GWIS
abstract class GwisHotspotService {
  /// Fetch hotspots within viewport for specified time period
  ///
  /// [bounds] - Geographic viewport (southwest/northeast corners)
  /// [timeFilter] - Today (24h) or ThisWeek (7d)
  /// [deadline] - Request timeout (default: 10s)
  ///
  /// Returns:
  /// - Right(List<Hotspot>) on success
  /// - Left(ApiError) on failure
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration? deadline,
  });
}
```

---

## API Contract

### Endpoint

```
GET https://maps.effis.emergency.copernicus.eu/gwis
```

### Request Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| SERVICE | WMS | Web Map Service |
| VERSION | 1.3.0 | WMS version |
| REQUEST | GetFeatureInfo | Query point/region |
| LAYERS | viirs.hs.today | or viirs.hs.week |
| QUERY_LAYERS | viirs.hs.today | Same as LAYERS |
| CRS | EPSG:4326 | WGS84 coordinates |
| BBOX | minLat,minLon,maxLat,maxLon | Viewport bounds |
| WIDTH | 256 | Tile width |
| HEIGHT | 256 | Tile height |
| I | 128 | Query pixel X |
| J | 128 | Query pixel Y |
| FEATURE_COUNT | 100 | Max features returned |
| INFO_FORMAT | application/vnd.ogc.gml | GML response |

### Layer Mapping

| TimeFilter | Layer Name |
|------------|------------|
| today | viirs.hs.today |
| thisWeek | viirs.hs.week |

### Response (GML)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<msGMLOutput>
  <viirs.hs.today_layer>
    <gml:name>viirs.hs.today</gml:name>
    <viirs.hs.today_feature>
      <gml:boundedBy>
        <gml:Box srsName="EPSG:4326">
          <gml:coordinates>-3.8,57.2 -3.8,57.2</gml:coordinates>
        </gml:Box>
      </gml:boundedBy>
      <id>41646136449</id>
      <acq_at>2025-12-08 01:17:00</acq_at>
      <CLASS>1DAY_2</CLASS>
      <satellite>N21</satellite>
      <confidence>high</confidence>
      <frp>25.3</frp>
    </viirs.hs.today_feature>
  </viirs.hs.today_layer>
</msGMLOutput>
```

### Response Field Mapping

| GML Field | Dart Field | Type | Notes |
|-----------|------------|------|-------|
| id | id | String | Unique hotspot ID |
| gml:coordinates | location | LatLng | lon,lat order in GML |
| acq_at | acquisitionTime | DateTime | Parse as UTC |
| satellite | satellite | String | N20, N21, SUOMI |
| confidence | confidence | String | high/nominal/low |
| frp | frp | double? | May be absent |
| CLASS | - | - | Not used (time info) |

---

## Error Handling

| HTTP Status | ApiError Type | Retry? |
|-------------|---------------|--------|
| 200 + empty | No data in viewport | No |
| 200 + parse error | Parsing error | No |
| 408, 504 | Timeout | Yes (3x) |
| 503 | Service unavailable | Yes (3x) |
| 4xx | Client error | No |
| 5xx | Server error | Yes (3x) |

---

## Contract Tests

```dart
// test/contract/gwis_hotspot_service_contract_test.dart

group('GwisHotspotService Contract', () {
  test('returns hotspots for Scotland viewport with Today filter', () async {
    final bounds = LatLngBounds(
      southwest: LatLng(55.0, -5.0),
      northeast: LatLng(58.0, -2.0),
    );
    
    final result = await service.getHotspots(
      bounds: bounds,
      timeFilter: HotspotTimeFilter.today,
    );
    
    result.fold(
      (error) => fail('Expected success, got: ${error.message}'),
      (hotspots) {
        for (final hotspot in hotspots) {
          expect(hotspot.id, isNotEmpty);
          expect(hotspot.location.isValid, isTrue);
          expect(hotspot.acquisitionTime.isBefore(DateTime.now()), isTrue);
          expect(['high', 'nominal', 'low'], contains(hotspot.confidence));
          if (hotspot.frp != null) {
            expect(hotspot.frp, greaterThanOrEqualTo(0));
          }
        }
      },
    );
  });
  
  test('returns empty list when no hotspots in viewport', () async {
    // Remote Antarctic region - no fires expected
    final bounds = LatLngBounds(
      southwest: LatLng(-75.0, -60.0),
      northeast: LatLng(-70.0, -50.0),
    );
    
    final result = await service.getHotspots(
      bounds: bounds,
      timeFilter: HotspotTimeFilter.today,
    );
    
    result.fold(
      (error) => fail('Expected success, got: ${error.message}'),
      (hotspots) => expect(hotspots, isEmpty),
    );
  });
  
  test('uses viirs.hs.week layer for ThisWeek filter', () async {
    // Verify correct layer is used (via URL inspection in integration test)
    final result = await service.getHotspots(
      bounds: testBounds,
      timeFilter: HotspotTimeFilter.thisWeek,
    );
    
    expect(result.isRight(), isTrue);
  });
});
```

---

## Implementation Notes

1. **Coordinate Order**: GWIS returns lon,lat but Dart uses lat,lon
2. **FRP Field**: May be absent for some detections - handle null
3. **Rate Limiting**: No known limits, but respect 10s timeout
4. **Caching**: Cache responses for 5 minutes (hotspots update ~hourly)
5. **Privacy**: Log coordinates at 2dp only (C2 compliance)
