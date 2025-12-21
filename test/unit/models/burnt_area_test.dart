import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

void main() {
  group('BurntArea', () {
    final testBoundary = [
      const LatLng(55.9510, -3.1920),
      const LatLng(55.9520, -3.1900),
      const LatLng(55.9530, -3.1870),
      const LatLng(55.9510, -3.1920), // closed ring
    ];
    final testFireDate = DateTime.utc(2025, 5, 15);

    group('construction', () {
      test('creates instance with all required fields', () {
        final burntArea = BurntArea(
          id: 'test_ba_001',
          boundaryPoints: testBoundary,
          areaHectares: 45.5,
          fireDate: testFireDate,
          seasonYear: 2025,
        );

        expect(burntArea.id, equals('test_ba_001'));
        expect(burntArea.boundaryPoints.length, equals(4));
        expect(burntArea.areaHectares, equals(45.5));
        expect(burntArea.fireDate, equals(testFireDate));
        expect(burntArea.seasonYear, equals(2025));
      });

      test('test factory creates valid instance with defaults', () {
        final burntArea = BurntArea.test(boundaryPoints: testBoundary);

        expect(burntArea.boundaryPoints, equals(testBoundary));
        expect(burntArea.areaHectares, equals(50.0)); // default
        expect(burntArea.isSimplified, isFalse);
      });
    });

    group('validated factory', () {
      test('throws for empty id', () {
        expect(
          () => BurntArea.validated(
            id: '',
            boundaryPoints: testBoundary,
            areaHectares: 50.0,
            fireDate: testFireDate,
            seasonYear: 2025,
          ),
          throwsArgumentError,
        );
      });

      test('throws for less than 3 boundary points', () {
        expect(
          () => BurntArea.validated(
            id: 'test',
            boundaryPoints: const [LatLng(55.0, -3.0), LatLng(55.1, -3.1)],
            areaHectares: 50.0,
            fireDate: testFireDate,
            seasonYear: 2025,
          ),
          throwsArgumentError,
        );
      });

      test('throws for negative area', () {
        expect(
          () => BurntArea.validated(
            id: 'test',
            boundaryPoints: testBoundary,
            areaHectares: -10.0,
            fireDate: testFireDate,
            seasonYear: 2025,
          ),
          throwsArgumentError,
        );
      });

      test('throws for invalid season year', () {
        expect(
          () => BurntArea.validated(
            id: 'test',
            boundaryPoints: testBoundary,
            areaHectares: 50.0,
            fireDate: testFireDate,
            seasonYear: 1990, // too old
          ),
          throwsArgumentError,
        );
      });
    });

    group('centroid', () {
      test('calculates average of boundary points', () {
        final burntArea = BurntArea.test(
          boundaryPoints: const [
            LatLng(55.0, -3.0),
            LatLng(56.0, -3.0),
            LatLng(56.0, -4.0),
            LatLng(55.0, -4.0),
          ],
        );

        final centroid = burntArea.centroid;

        expect(centroid.latitude, closeTo(55.5, 0.001));
        expect(centroid.longitude, closeTo(-3.5, 0.001));
      });

      test('returns (0,0) for empty boundary', () {
        final burntArea = BurntArea(
          id: 'empty',
          boundaryPoints: const [],
          areaHectares: 0,
          fireDate: testFireDate,
          seasonYear: 2025,
        );

        expect(burntArea.centroid.latitude, equals(0));
        expect(burntArea.centroid.longitude, equals(0));
      });
    });

    group('intensity from area', () {
      test('area < 10 ha returns low intensity', () {
        final burntArea = BurntArea.test(
          boundaryPoints: testBoundary,
          areaHectares: 5.0,
        );
        expect(burntArea.intensity, equals('low'));
      });

      test('area = 10 ha returns moderate intensity', () {
        final burntArea = BurntArea.test(
          boundaryPoints: testBoundary,
          areaHectares: 10.0,
        );
        expect(burntArea.intensity, equals('moderate'));
      });

      test('area = 99 ha returns moderate intensity', () {
        final burntArea = BurntArea.test(
          boundaryPoints: testBoundary,
          areaHectares: 99.0,
        );
        expect(burntArea.intensity, equals('moderate'));
      });

      test('area = 100 ha returns high intensity', () {
        final burntArea = BurntArea.test(
          boundaryPoints: testBoundary,
          areaHectares: 100.0,
        );
        expect(burntArea.intensity, equals('high'));
      });

      test('area > 100 ha returns high intensity', () {
        final burntArea = BurntArea.test(
          boundaryPoints: testBoundary,
          areaHectares: 500.0,
        );
        expect(burntArea.intensity, equals('high'));
      });
    });

    group('fromJson', () {
      test('parses GeoJSON polygon structure', () {
        final json = {
          'id': 'MODIS.BA.12345',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-3.192, 55.951],
                [-3.190, 55.952],
                [-3.187, 55.953],
                [-3.192, 55.951],
              ],
            ],
          },
          'properties': {
            'area_ha': 45.7,
            'firedate': '2025-07-15',
            'year': 2025,
          },
        };

        final burntArea = BurntArea.fromJson(json);

        expect(burntArea.id, equals('MODIS.BA.12345'));
        expect(burntArea.boundaryPoints.length, equals(4));
        expect(burntArea.areaHectares, equals(45.7));
        expect(burntArea.seasonYear, equals(2025));
      });

      test('parses land cover breakdown', () {
        final json = {
          'id': 'test',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-3.0, 55.0],
                [-3.1, 55.1],
                [-3.2, 55.0],
                [-3.0, 55.0],
              ],
            ],
          },
          'properties': {
            'area_ha': 50.0,
            'firedate': '2025-05-15',
            'year': 2025,
            'lc_forest': 0.45,
            'lc_shrub': 0.30,
            'lc_grass': 0.15,
            'lc_agri': 0.05,
            'lc_other': 0.05,
          },
        };

        final burntArea = BurntArea.fromJson(json);

        expect(burntArea.landCoverBreakdown, isNotNull);
        expect(burntArea.landCoverBreakdown!['forest'], equals(0.45));
        expect(burntArea.landCoverBreakdown!['shrubland'], equals(0.30));
      });

      test('handles missing geometry gracefully', () {
        final json = {
          'id': 'no_geom',
          'properties': {
            'area_ha': 25.0,
            'firedate': '2025-05-15',
            'year': 2025,
          },
        };

        final burntArea = BurntArea.fromJson(json);

        expect(burntArea.boundaryPoints, isEmpty);
      });

      test('uses fireDate year if season year not provided', () {
        final json = {
          'id': 'test',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-3.0, 55.0],
                [-3.1, 55.1],
                [-3.2, 55.0],
                [-3.0, 55.0],
              ],
            ],
          },
          'properties': {'area_ha': 50.0, 'firedate': '2024-05-15'},
        };

        final burntArea = BurntArea.fromJson(json);

        expect(burntArea.seasonYear, equals(2024));
      });
    });

    group('toJson', () {
      test('serializes to valid JSON structure', () {
        final burntArea = BurntArea(
          id: 'test_001',
          boundaryPoints: testBoundary,
          areaHectares: 45.5,
          fireDate: testFireDate,
          seasonYear: 2025,
        );

        final json = burntArea.toJson();

        expect(json['id'], equals('test_001'));
        expect(json['geometry']['type'], equals('Polygon'));
        expect(json['geometry']['coordinates'][0].length, equals(4));
        expect(json['properties']['area_ha'], equals(45.5));
        expect(json['properties']['year'], equals(2025));
      });

      test('roundtrip: toJson -> fromJson preserves data', () {
        final original = BurntArea(
          id: 'roundtrip_test',
          boundaryPoints: testBoundary,
          areaHectares: 75.0,
          fireDate: testFireDate,
          seasonYear: 2025,
          landCoverBreakdown: const {'forest': 0.5, 'shrubland': 0.5},
        );

        final json = original.toJson();
        final restored = BurntArea.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.areaHectares, equals(original.areaHectares));
        expect(restored.seasonYear, equals(original.seasonYear));
        expect(
          restored.boundaryPoints.length,
          equals(original.boundaryPoints.length),
        );
      });
    });

    group('copyWithSimplified', () {
      test('creates simplified copy with new points', () {
        final original = BurntArea(
          id: 'test',
          boundaryPoints: testBoundary,
          areaHectares: 50.0,
          fireDate: testFireDate,
          seasonYear: 2025,
        );

        final simplifiedPoints = [
          const LatLng(55.95, -3.19),
          const LatLng(55.96, -3.18),
          const LatLng(55.95, -3.19),
        ];

        final simplified = original.copyWithSimplified(
          simplifiedPoints: simplifiedPoints,
        );

        expect(simplified.isSimplified, isTrue);
        expect(simplified.originalPointCount, equals(4));
        expect(simplified.boundaryPoints.length, equals(3));
        // Preserves other fields
        expect(simplified.id, equals(original.id));
        expect(simplified.areaHectares, equals(original.areaHectares));
      });
    });

    group('Equatable', () {
      test('two burnt areas with same props are equal', () {
        final ba1 = BurntArea(
          id: 'same',
          boundaryPoints: testBoundary,
          areaHectares: 50.0,
          fireDate: testFireDate,
          seasonYear: 2025,
        );
        final ba2 = BurntArea(
          id: 'same',
          boundaryPoints: testBoundary,
          areaHectares: 50.0,
          fireDate: testFireDate,
          seasonYear: 2025,
        );

        expect(ba1, equals(ba2));
        expect(ba1.hashCode, equals(ba2.hashCode));
      });

      test('burnt areas with different IDs are not equal', () {
        final ba1 = BurntArea.test(id: 'a', boundaryPoints: testBoundary);
        final ba2 = BurntArea.test(id: 'b', boundaryPoints: testBoundary);

        expect(ba1, isNot(equals(ba2)));
      });
    });
  });
}
