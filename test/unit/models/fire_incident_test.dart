import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  group('FireIncident', () {
    // Test data
    const validLocation = LatLng(55.9533, -3.1883); // Edinburgh
    final pastTimestamp = DateTime.now().subtract(const Duration(hours: 1));
    const validBoundaryPoints = [
      LatLng(55.95, -3.19),
      LatLng(55.96, -3.18),
      LatLng(55.95, -3.17),
      LatLng(55.94, -3.18),
    ];

    group('Constructor', () {
      test('creates instance with all required fields', () {
        final incident = FireIncident(
          id: 'fire-001',
          location: validLocation,
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'moderate',
        );

        expect(incident.id, 'fire-001');
        expect(incident.location, validLocation);
        expect(incident.source, DataSource.effis);
        expect(incident.freshness, Freshness.live);
        expect(incident.timestamp, pastTimestamp);
        expect(incident.intensity, 'moderate');
      });

      test('creates instance with all optional fields', () {
        final detectedAt = pastTimestamp.subtract(const Duration(minutes: 30));
        final lastUpdate = pastTimestamp;

        final incident = FireIncident(
          id: 'fire-002',
          location: validLocation,
          source: DataSource.effis,
          freshness: Freshness.cached,
          timestamp: pastTimestamp,
          intensity: 'high',
          description: 'Test fire near Edinburgh',
          areaHectares: 25.5,
          boundaryPoints: validBoundaryPoints,
          detectedAt: detectedAt,
          sensorSource: 'VIIRS',
          confidence: 85.0,
          frp: 120.5,
          lastUpdate: lastUpdate,
        );

        expect(incident.description, 'Test fire near Edinburgh');
        expect(incident.areaHectares, 25.5);
        expect(incident.boundaryPoints, validBoundaryPoints);
        expect(incident.detectedAt, detectedAt);
        expect(incident.sensorSource, 'VIIRS');
        expect(incident.confidence, 85.0);
        expect(incident.frp, 120.5);
        expect(incident.lastUpdate, lastUpdate);
      });

      test('defaults detectedAt to timestamp when not provided', () {
        final incident = FireIncident(
          id: 'fire-003',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
        );

        expect(incident.detectedAt, pastTimestamp);
      });

      test('defaults sensorSource to UNKNOWN when not provided', () {
        final incident = FireIncident(
          id: 'fire-004',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
        );

        expect(incident.sensorSource, 'UNKNOWN');
      });

      test('accepts all valid intensity values', () {
        for (final intensity in ['low', 'moderate', 'high']) {
          final incident = FireIncident(
            id: 'fire-intensity-$intensity',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: intensity,
          );
          expect(incident.intensity, intensity);
        }
      });

      test('accepts boundary confidence values 0 and 100', () {
        final incident0 = FireIncident(
          id: 'fire-conf-0',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          confidence: 0.0,
        );
        expect(incident0.confidence, 0.0);

        final incident100 = FireIncident(
          id: 'fire-conf-100',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          confidence: 100.0,
        );
        expect(incident100.confidence, 100.0);
      });

      test('accepts frp value of 0', () {
        final incident = FireIncident(
          id: 'fire-frp-0',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          frp: 0.0,
        );
        expect(incident.frp, 0.0);
      });
    });

    group('Validation', () {
      test('throws on empty id', () {
        expect(
          () => FireIncident(
            id: '',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('id must be non-empty'),
          )),
        );
      });

      test('throws on invalid location', () {
        expect(
          () => FireIncident(
            id: 'fire-invalid-loc',
            location: const LatLng(91.0, 0.0), // Invalid latitude
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('valid coordinates'),
          )),
        );
      });

      test('throws on future timestamp', () {
        expect(
          () => FireIncident(
            id: 'fire-future',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: DateTime.now().add(const Duration(hours: 1)),
            intensity: 'low',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('timestamp must not be in the future'),
          )),
        );
      });

      test('throws on future detectedAt', () {
        expect(
          () => FireIncident(
            id: 'fire-future-detected',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            detectedAt: DateTime.now().add(const Duration(hours: 1)),
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('detectedAt must not be in the future'),
          )),
        );
      });

      test('throws on invalid intensity', () {
        expect(
          () => FireIncident(
            id: 'fire-invalid-intensity',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'extreme', // Invalid
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('intensity must be'),
          )),
        );
      });

      test('throws on non-positive areaHectares', () {
        expect(
          () => FireIncident(
            id: 'fire-zero-area',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            areaHectares: 0.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('areaHectares must be > 0'),
          )),
        );

        expect(
          () => FireIncident(
            id: 'fire-negative-area',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            areaHectares: -5.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('areaHectares must be > 0'),
          )),
        );
      });

      test('throws on empty sensorSource', () {
        expect(
          () => FireIncident(
            id: 'fire-empty-sensor',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            sensorSource: '',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('sensorSource must be non-empty'),
          )),
        );
      });

      test('throws on confidence outside 0-100 range', () {
        expect(
          () => FireIncident(
            id: 'fire-conf-negative',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            confidence: -1.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('confidence must be between 0-100'),
          )),
        );

        expect(
          () => FireIncident(
            id: 'fire-conf-over',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            confidence: 100.1,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('confidence must be between 0-100'),
          )),
        );
      });

      test('throws on negative frp', () {
        expect(
          () => FireIncident(
            id: 'fire-negative-frp',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            frp: -0.1,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('frp must be non-negative'),
          )),
        );
      });

      test('throws on lastUpdate before detectedAt', () {
        final detectedAt = pastTimestamp;
        final lastUpdateBefore = detectedAt.subtract(const Duration(hours: 1));

        expect(
          () => FireIncident(
            id: 'fire-lastupdate-before',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            detectedAt: detectedAt,
            lastUpdate: lastUpdateBefore,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('lastUpdate must be >= detectedAt'),
          )),
        );
      });
    });

    group('Boundary Points Validation', () {
      test('accepts null boundaryPoints', () {
        final incident = FireIncident(
          id: 'fire-no-boundary',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: null,
        );
        expect(incident.boundaryPoints, isNull);
        expect(incident.hasValidPolygon, isFalse);
      });

      test('accepts empty boundaryPoints list', () {
        final incident = FireIncident(
          id: 'fire-empty-boundary',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: const [],
        );
        expect(incident.boundaryPoints, isEmpty);
        expect(incident.hasValidPolygon, isFalse);
      });

      test('throws on boundaryPoints with less than 3 points', () {
        expect(
          () => FireIncident(
            id: 'fire-2-points',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            boundaryPoints: const [
              LatLng(55.95, -3.19),
              LatLng(55.96, -3.18),
            ],
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('at least 3 points'),
          )),
        );
      });

      test('accepts boundaryPoints with exactly 3 points', () {
        const trianglePoints = [
          LatLng(55.95, -3.19),
          LatLng(55.96, -3.18),
          LatLng(55.95, -3.17),
        ];

        final incident = FireIncident(
          id: 'fire-triangle',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: trianglePoints,
        );

        expect(incident.boundaryPoints, trianglePoints);
        expect(incident.hasValidPolygon, isTrue);
      });

      test('throws on boundaryPoints with invalid coordinates', () {
        expect(
          () => FireIncident(
            id: 'fire-invalid-boundary',
            location: validLocation,
            source: DataSource.mock,
            freshness: Freshness.live,
            timestamp: pastTimestamp,
            intensity: 'low',
            boundaryPoints: const [
              LatLng(55.95, -3.19),
              LatLng(91.0, -3.18), // Invalid latitude
              LatLng(55.95, -3.17),
            ],
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('invalid coordinates'),
          )),
        );
      });

      test('accepts complex polygon with many points', () {
        final complexPolygon = [
          for (int i = 0; i < 20; i++)
            LatLng(55.9 + (i * 0.01), -3.2 + (i % 2) * 0.01),
        ];

        final incident = FireIncident(
          id: 'fire-complex',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'high',
          boundaryPoints: complexPolygon,
        );

        expect(incident.boundaryPoints!.length, 20);
        expect(incident.hasValidPolygon, isTrue);
      });
    });

    group('hasValidPolygon', () {
      test('returns false for null boundaryPoints', () {
        final incident = FireIncident(
          id: 'fire-null',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: null,
        );
        expect(incident.hasValidPolygon, isFalse);
      });

      test('returns false for empty boundaryPoints', () {
        final incident = FireIncident(
          id: 'fire-empty',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: const [],
        );
        expect(incident.hasValidPolygon, isFalse);
      });

      test('returns true for 3+ valid points', () {
        final incident = FireIncident(
          id: 'fire-valid',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: validBoundaryPoints,
        );
        expect(incident.hasValidPolygon, isTrue);
      });
    });

    group('FireIncident.test() factory', () {
      test('creates instance with minimal required fields', () {
        final incident = FireIncident.test(
          id: 'test-001',
          location: validLocation,
        );

        expect(incident.id, 'test-001');
        expect(incident.location, validLocation);
        expect(incident.source, DataSource.mock);
        expect(incident.freshness, Freshness.live);
        expect(incident.intensity, 'moderate');
        expect(incident.sensorSource, 'VIIRS');
      });

      test('allows overriding all optional fields', () {
        final incident = FireIncident.test(
          id: 'test-002',
          location: validLocation,
          source: DataSource.effis,
          freshness: Freshness.cached,
          intensity: 'high',
          sensorSource: 'MODIS',
          description: 'Custom description',
          areaHectares: 50.0,
          boundaryPoints: validBoundaryPoints,
          confidence: 90.0,
          frp: 200.0,
        );

        expect(incident.source, DataSource.effis);
        expect(incident.freshness, Freshness.cached);
        expect(incident.intensity, 'high');
        expect(incident.sensorSource, 'MODIS');
        expect(incident.description, 'Custom description');
        expect(incident.areaHectares, 50.0);
        expect(incident.boundaryPoints, validBoundaryPoints);
        expect(incident.confidence, 90.0);
        expect(incident.frp, 200.0);
      });

      test('generates current UTC timestamp when not provided', () {
        final before = DateTime.now().toUtc();
        final incident = FireIncident.test(
          id: 'test-003',
          location: validLocation,
        );
        final after = DateTime.now().toUtc();

        expect(
            incident.timestamp
                .isAfter(before.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(
            incident.timestamp.isBefore(after.add(const Duration(seconds: 1))),
            isTrue);
      });
    });

    group('fromJson - Point Geometry', () {
      test('parses EFFIS WFS Point GeoJSON format', () {
        final json = {
          'id': 'effis-123',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.1883, 55.9533], // [lon, lat] GeoJSON order
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'area_ha': 15.5,
            'country': 'United Kingdom',
            'sensor': 'VIIRS',
            'confidence': 80.0,
            'frp': 150.0,
          },
        };

        final incident = FireIncident.fromJson(json);

        expect(incident.id, 'effis-123');
        expect(incident.location.latitude, closeTo(55.9533, 0.0001));
        expect(incident.location.longitude, closeTo(-3.1883, 0.0001));
        expect(incident.boundaryPoints, isNull);
        expect(incident.intensity, 'moderate'); // 15.5 ha → moderate
        expect(incident.areaHectares, 15.5);
        expect(incident.sensorSource, 'VIIRS');
        expect(incident.confidence, 80.0);
        expect(incident.frp, 150.0);
      });

      test('calculates intensity from area_ha correctly', () {
        // Low: area_ha < 10
        const lowJson = {
          'id': 'low-1',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'area_ha': 5.0,
          },
        };
        expect(FireIncident.fromJson(lowJson).intensity, 'low');

        // Moderate: 10 <= area_ha < 30
        final modJson = {
          'id': 'mod-1',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'area_ha': 25.0,
          },
        };
        expect(FireIncident.fromJson(modJson).intensity, 'moderate');

        // High: area_ha >= 30
        final highJson = {
          'id': 'high-1',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'area_ha': 50.0,
          },
        };
        expect(FireIncident.fromJson(highJson).intensity, 'high');
      });

      test('uses explicit intensity field when provided', () {
        final json = {
          'id': 'mock-1',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'intensity': 'high',
            'area_ha': 5.0, // Would be 'low' but explicit intensity wins
          },
        };
        expect(FireIncident.fromJson(json).intensity, 'high');
      });

      test('handles timestamp field fallbacks', () {
        // Uses 'lastupdate' when 'timestamp' not present
        final lastUpdateJson = {
          'id': 'ts-1',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {'lastupdate': '2024-02-20T15:00:00Z'},
        };
        final incident1 = FireIncident.fromJson(lastUpdateJson);
        expect(incident1.timestamp.year, 2024);
        expect(incident1.timestamp.month, 2);

        // Uses 'firedate' when others not present
        final firedateJson = {
          'id': 'ts-2',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {'firedate': '2024-03-10T08:00:00Z'},
        };
        final incident2 = FireIncident.fromJson(firedateJson);
        expect(incident2.timestamp.year, 2024);
        expect(incident2.timestamp.month, 3);
      });

      test('handles sensor field fallbacks', () {
        // Uses 'sensor_source' when 'sensor' not present
        final sensorSourceJson = {
          'id': 'sensor-1',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'sensor_source': 'SENTINEL',
          },
        };
        expect(
            FireIncident.fromJson(sensorSourceJson).sensorSource, 'SENTINEL');

        // Defaults to 'MODIS' when no sensor field
        final noSensorJson = {
          'id': 'sensor-2',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {'timestamp': '2024-01-15T10:30:00Z'},
        };
        expect(FireIncident.fromJson(noSensorJson).sensorSource, 'MODIS');
      });

      test('extracts id from various sources', () {
        // Uses top-level 'id'
        final topId = {
          'id': 'top-123',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {'timestamp': '2024-01-15T10:30:00Z'},
        };
        expect(FireIncident.fromJson(topId).id, 'top-123');

        // Falls back to 'fid' in properties
        final fidJson = {
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'fid': 456,
          },
        };
        expect(FireIncident.fromJson(fidJson).id, '456');

        // Falls back to 'unknown'
        final noIdJson = {
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.0, 55.0]
          },
          'properties': {'timestamp': '2024-01-15T10:30:00Z'},
        };
        expect(FireIncident.fromJson(noIdJson).id, 'unknown');
      });
    });

    group('fromJson - Polygon Geometry', () {
      test('parses Polygon GeoJSON and extracts boundary points', () {
        final json = {
          'id': 'polygon-001',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-3.20, 55.94], // [lon, lat]
                [-3.18, 55.94],
                [-3.18, 55.96],
                [-3.20, 55.96],
                [-3.20, 55.94], // Closed ring
              ]
            ],
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'intensity': 'high',
          },
        };

        final incident = FireIncident.fromJson(json);

        expect(incident.id, 'polygon-001');
        expect(incident.boundaryPoints, isNotNull);
        expect(incident.boundaryPoints!.length, 5);
        expect(incident.hasValidPolygon, isTrue);

        // Check first boundary point (converted from [lon, lat] to LatLng)
        expect(incident.boundaryPoints![0].latitude, closeTo(55.94, 0.001));
        expect(incident.boundaryPoints![0].longitude, closeTo(-3.20, 0.001));
      });

      test('calculates centroid from polygon points', () {
        final json = {
          'id': 'centroid-test',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-3.0, 55.0],
                [-3.0, 56.0],
                [-4.0, 56.0],
                [-4.0, 55.0],
                [-3.0, 55.0],
              ]
            ],
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
          },
        };

        final incident = FireIncident.fromJson(json);

        // Centroid should be average of all points
        // Average lat: (55 + 56 + 56 + 55 + 55) / 5 = 55.4
        // Average lon: (-3 + -3 + -4 + -4 + -3) / 5 = -3.4
        expect(incident.location.latitude, closeTo(55.4, 0.001));
        expect(incident.location.longitude, closeTo(-3.4, 0.001));
      });

      test('handles polygon with multiple properties', () {
        final json = {
          'id': 'full-polygon',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-3.19, 55.95],
                [-3.17, 55.95],
                [-3.17, 55.96],
                [-3.19, 55.96],
                [-3.19, 55.95],
              ]
            ],
          },
          'properties': {
            'timestamp': '2024-01-15T10:30:00Z',
            'area_ha': 45.0,
            'country': 'Scotland',
            'sensor': 'VIIRS',
            'confidence': 95.0,
            'frp': 250.0,
          },
        };

        final incident = FireIncident.fromJson(json);

        expect(incident.intensity, 'high'); // 45 ha
        expect(incident.areaHectares, 45.0);
        expect(incident.description, 'Scotland');
        expect(incident.sensorSource, 'VIIRS');
        expect(incident.confidence, 95.0);
        expect(incident.frp, 250.0);
        expect(incident.hasValidPolygon, isTrue);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final detectedAt = pastTimestamp.subtract(const Duration(hours: 2));
        final lastUpdate = pastTimestamp;

        final incident = FireIncident(
          id: 'serialize-001',
          location: validLocation,
          source: DataSource.effis,
          freshness: Freshness.cached,
          timestamp: pastTimestamp,
          intensity: 'high',
          description: 'Test fire',
          areaHectares: 30.0,
          boundaryPoints: validBoundaryPoints,
          detectedAt: detectedAt,
          sensorSource: 'VIIRS',
          confidence: 85.0,
          frp: 150.0,
          lastUpdate: lastUpdate,
        );

        final json = incident.toJson();

        expect(json['id'], 'serialize-001');
        expect(json['location']['latitude'], 55.9533);
        expect(json['location']['longitude'], -3.1883);
        expect(json['source'], 'effis');
        expect(json['freshness'], 'cached');
        expect(json['timestamp'], pastTimestamp.toIso8601String());
        expect(json['intensity'], 'high');
        expect(json['description'], 'Test fire');
        expect(json['areaHectares'], 30.0);
        expect(json['sensorSource'], 'VIIRS');
        expect(json['confidence'], 85.0);
        expect(json['frp'], 150.0);
      });

      test('serializes boundaryPoints as list of lat/lon objects', () {
        final incident = FireIncident(
          id: 'boundary-serial',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: validBoundaryPoints,
        );

        final json = incident.toJson();
        final points = json['boundaryPoints'] as List<dynamic>;

        expect(points.length, validBoundaryPoints.length);
        expect(points[0]['latitude'], validBoundaryPoints[0].latitude);
        expect(points[0]['longitude'], validBoundaryPoints[0].longitude);
      });

      test('serializes null boundaryPoints as null', () {
        final incident = FireIncident(
          id: 'no-boundary',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
          boundaryPoints: null,
        );

        final json = incident.toJson();
        expect(json['boundaryPoints'], isNull);
      });

      test('serializes null optional fields correctly', () {
        final incident = FireIncident(
          id: 'minimal',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
        );

        final json = incident.toJson();

        expect(json['description'], isNull);
        expect(json['areaHectares'], isNull);
        expect(json['confidence'], isNull);
        expect(json['frp'], isNull);
        expect(json['lastUpdate'], isNull);
      });
    });

    group('fromCacheJson', () {
      test('deserializes all fields correctly', () {
        final cacheJson = {
          'id': 'cache-001',
          'location': {'latitude': 55.9533, 'longitude': -3.1883},
          'source': 'effis',
          'freshness': 'cached',
          'timestamp': '2024-01-15T10:30:00.000Z',
          'intensity': 'high',
          'description': 'Cached fire',
          'areaHectares': 25.0,
          'detectedAt': '2024-01-15T08:00:00.000Z',
          'sensorSource': 'MODIS',
          'confidence': 90.0,
          'frp': 180.0,
          'lastUpdate': '2024-01-15T12:00:00.000Z',
          'boundaryPoints': null,
        };

        final incident = FireIncident.fromCacheJson(cacheJson);

        expect(incident.id, 'cache-001');
        expect(incident.location.latitude, 55.9533);
        expect(incident.location.longitude, -3.1883);
        expect(incident.source, DataSource.effis);
        expect(incident.freshness, Freshness.cached);
        expect(incident.intensity, 'high');
        expect(incident.description, 'Cached fire');
        expect(incident.areaHectares, 25.0);
        expect(incident.sensorSource, 'MODIS');
        expect(incident.confidence, 90.0);
        expect(incident.frp, 180.0);
      });

      test('deserializes boundaryPoints correctly', () {
        final cacheJson = {
          'id': 'cache-boundary',
          'location': {'latitude': 55.95, 'longitude': -3.19},
          'source': 'mock',
          'freshness': 'live',
          'timestamp': '2024-01-15T10:30:00.000Z',
          'intensity': 'moderate',
          'detectedAt': '2024-01-15T10:30:00.000Z',
          'sensorSource': 'VIIRS',
          'boundaryPoints': [
            {'latitude': 55.95, 'longitude': -3.19},
            {'latitude': 55.96, 'longitude': -3.18},
            {'latitude': 55.95, 'longitude': -3.17},
          ],
        };

        final incident = FireIncident.fromCacheJson(cacheJson);

        expect(incident.boundaryPoints, isNotNull);
        expect(incident.boundaryPoints!.length, 3);
        expect(incident.boundaryPoints![0].latitude, 55.95);
        expect(incident.boundaryPoints![0].longitude, -3.19);
        expect(incident.hasValidPolygon, isTrue);
      });

      test('handles unknown source/freshness with defaults', () {
        final cacheJson = {
          'id': 'unknown-enums',
          'location': {'latitude': 55.0, 'longitude': -3.0},
          'source': 'invalid_source',
          'freshness': 'invalid_freshness',
          'timestamp': '2024-01-15T10:30:00.000Z',
          'intensity': 'low',
          'detectedAt': '2024-01-15T10:30:00.000Z',
          'sensorSource': 'UNKNOWN',
        };

        final incident = FireIncident.fromCacheJson(cacheJson);

        expect(incident.source, DataSource.mock); // Default fallback
        expect(incident.freshness, Freshness.live); // Default fallback
      });
    });

    group('Roundtrip Serialization', () {
      test('toJson -> fromCacheJson preserves all data', () {
        final original = FireIncident(
          id: 'roundtrip-001',
          location: validLocation,
          source: DataSource.effis,
          freshness: Freshness.cached,
          timestamp: pastTimestamp,
          intensity: 'high',
          description: 'Roundtrip test',
          areaHectares: 42.5,
          boundaryPoints: validBoundaryPoints,
          detectedAt: pastTimestamp.subtract(const Duration(hours: 1)),
          sensorSource: 'VIIRS',
          confidence: 87.5,
          frp: 165.0,
          lastUpdate: pastTimestamp,
        );

        final json = original.toJson();
        final restored = FireIncident.fromCacheJson(json);

        expect(restored.id, original.id);
        expect(restored.location, original.location);
        expect(restored.source, original.source);
        expect(restored.freshness, original.freshness);
        expect(restored.intensity, original.intensity);
        expect(restored.description, original.description);
        expect(restored.areaHectares, original.areaHectares);
        expect(restored.sensorSource, original.sensorSource);
        expect(restored.confidence, original.confidence);
        expect(restored.frp, original.frp);
        expect(
            restored.boundaryPoints!.length, original.boundaryPoints!.length);
        expect(restored.hasValidPolygon, original.hasValidPolygon);
      });

      test('roundtrip preserves incident without optional fields', () {
        final original = FireIncident(
          id: 'minimal-roundtrip',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'low',
        );

        final json = original.toJson();
        final restored = FireIncident.fromCacheJson(json);

        expect(restored.id, original.id);
        expect(restored.location, original.location);
        expect(restored.intensity, original.intensity);
        expect(restored.boundaryPoints, isNull);
        expect(restored.hasValidPolygon, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated single field', () {
        final original = FireIncident.test(
          id: 'copy-001',
          location: validLocation,
          intensity: 'low',
        );

        final updated = original.copyWith(intensity: 'high');

        expect(updated.id, original.id);
        expect(updated.location, original.location);
        expect(updated.intensity, 'high');
        expect(updated.source, original.source);
      });

      test('creates copy with updated multiple fields', () {
        final original = FireIncident.test(
          id: 'copy-002',
          location: validLocation,
        );

        const newLocation = LatLng(56.0, -4.0);
        final updated = original.copyWith(
          id: 'copy-002-updated',
          location: newLocation,
          intensity: 'high',
          source: DataSource.effis,
        );

        expect(updated.id, 'copy-002-updated');
        expect(updated.location, newLocation);
        expect(updated.intensity, 'high');
        expect(updated.source, DataSource.effis);
      });

      test('creates copy with added boundaryPoints', () {
        final original = FireIncident.test(
          id: 'copy-boundary',
          location: validLocation,
          boundaryPoints: null,
        );

        final updated = original.copyWith(boundaryPoints: validBoundaryPoints);

        expect(original.boundaryPoints, isNull);
        expect(updated.boundaryPoints, validBoundaryPoints);
        expect(updated.hasValidPolygon, isTrue);
      });

      test('creates copy with removed boundaryPoints', () {
        final original = FireIncident.test(
          id: 'copy-remove-boundary',
          location: validLocation,
          boundaryPoints: validBoundaryPoints,
        );

        // Note: copyWith can't set to null, it keeps original if null passed
        // To remove, you'd need to create new instance directly
        final updated = original.copyWith();

        expect(updated.boundaryPoints, validBoundaryPoints); // Unchanged
      });

      test('copyWith preserves all other fields', () {
        final original = FireIncident(
          id: 'preserve-test',
          location: validLocation,
          source: DataSource.effis,
          freshness: Freshness.cached,
          timestamp: pastTimestamp,
          intensity: 'moderate',
          description: 'Original description',
          areaHectares: 20.0,
          boundaryPoints: validBoundaryPoints,
          detectedAt: pastTimestamp.subtract(const Duration(hours: 1)),
          sensorSource: 'VIIRS',
          confidence: 75.0,
          frp: 100.0,
          lastUpdate: pastTimestamp,
        );

        final updated = original.copyWith(intensity: 'high');

        expect(updated.id, original.id);
        expect(updated.location, original.location);
        expect(updated.source, original.source);
        expect(updated.freshness, original.freshness);
        expect(updated.timestamp, original.timestamp);
        expect(updated.description, original.description);
        expect(updated.areaHectares, original.areaHectares);
        expect(updated.boundaryPoints, original.boundaryPoints);
        expect(updated.detectedAt, original.detectedAt);
        expect(updated.sensorSource, original.sensorSource);
        expect(updated.confidence, original.confidence);
        expect(updated.frp, original.frp);
        expect(updated.lastUpdate, original.lastUpdate);
      });
    });

    group('Equality and HashCode', () {
      test('identical instances are equal', () {
        final incident1 = FireIncident(
          id: 'equal-001',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'moderate',
          boundaryPoints: validBoundaryPoints,
        );

        final incident2 = FireIncident(
          id: 'equal-001',
          location: validLocation,
          source: DataSource.mock,
          freshness: Freshness.live,
          timestamp: pastTimestamp,
          intensity: 'moderate',
          boundaryPoints: validBoundaryPoints,
        );

        expect(incident1, equals(incident2));
        expect(incident1.hashCode, equals(incident2.hashCode));
      });

      test('different id makes instances unequal', () {
        final incident1 =
            FireIncident.test(id: 'id-1', location: validLocation);
        final incident2 =
            FireIncident.test(id: 'id-2', location: validLocation);

        expect(incident1, isNot(equals(incident2)));
      });

      test('different location makes instances unequal', () {
        final incident1 = FireIncident.test(
          id: 'loc-test',
          location: const LatLng(55.0, -3.0),
        );
        final incident2 = FireIncident.test(
          id: 'loc-test',
          location: const LatLng(56.0, -4.0),
        );

        expect(incident1, isNot(equals(incident2)));
      });

      test('different source makes instances unequal', () {
        final incident1 = FireIncident.test(
          id: 'source-test',
          location: validLocation,
          source: DataSource.mock,
        );
        final incident2 = FireIncident.test(
          id: 'source-test',
          location: validLocation,
          source: DataSource.effis,
        );

        expect(incident1, isNot(equals(incident2)));
      });

      test('different intensity makes instances unequal', () {
        final incident1 = FireIncident.test(
          id: 'intensity-test',
          location: validLocation,
          intensity: 'low',
        );
        final incident2 = FireIncident.test(
          id: 'intensity-test',
          location: validLocation,
          intensity: 'high',
        );

        expect(incident1, isNot(equals(incident2)));
      });

      test('different boundaryPoints makes instances unequal', () {
        final incident1 = FireIncident.test(
          id: 'boundary-test',
          location: validLocation,
          boundaryPoints: validBoundaryPoints,
        );
        final incident2 = FireIncident.test(
          id: 'boundary-test',
          location: validLocation,
          boundaryPoints: const [
            LatLng(55.0, -3.0),
            LatLng(55.1, -3.1),
            LatLng(55.0, -3.2),
          ],
        );

        expect(incident1, isNot(equals(incident2)));
      });

      test('null vs non-null boundaryPoints makes instances unequal', () {
        final incident1 = FireIncident.test(
          id: 'null-boundary',
          location: validLocation,
          boundaryPoints: null,
        );
        final incident2 = FireIncident.test(
          id: 'null-boundary',
          location: validLocation,
          boundaryPoints: validBoundaryPoints,
        );

        expect(incident1, isNot(equals(incident2)));
      });
    });
  });
}
