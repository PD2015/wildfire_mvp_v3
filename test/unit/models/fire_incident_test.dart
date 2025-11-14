import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  group('FireIncident Constructor', () {
    test('creates valid instance with all required fields', () {
      final now = DateTime.now().toUtc();
      final incident = FireIncident(
        id: 'test-001',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now.subtract(const Duration(hours: 2)),
        sensorSource: 'VIIRS',
      );

      expect(incident.id, 'test-001');
      expect(incident.location.latitude, 55.9533);
      expect(incident.location.longitude, -3.1883);
      expect(incident.source, DataSource.effis);
      expect(incident.freshness, Freshness.live);
      expect(incident.timestamp, now);
      expect(incident.intensity, 'moderate');
      expect(incident.detectedAt, now.subtract(const Duration(hours: 2)));
      expect(incident.sensorSource, 'VIIRS');
    });

    test('creates instance with all optional fields', () {
      final now = DateTime.now().toUtc();
      final detected = now.subtract(const Duration(hours: 2));
      final updated = now.subtract(const Duration(hours: 1));
      
      final incident = FireIncident(
        id: 'test-002',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'high',
        detectedAt: detected,
        sensorSource: 'MODIS',
        description: 'Large wildfire in Scotland',
        areaHectares: 45.5,
        confidence: 85.0,
        frp: 125.3,
        lastUpdate: updated,
      );

      expect(incident.description, 'Large wildfire in Scotland');
      expect(incident.areaHectares, 45.5);
      expect(incident.confidence, 85.0);
      expect(incident.frp, 125.3);
      expect(incident.lastUpdate, updated);
    });

    test('throws ArgumentError for empty id', () {
      expect(
        () => FireIncident(
          id: '',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for invalid location', () {
      expect(
        () => FireIncident(
          id: 'test-003',
          location: const LatLng(91.0, 0.0), // Invalid latitude
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for future timestamp', () {
      final futureTime = DateTime.now().toUtc().add(const Duration(hours: 1));
      expect(
        () => FireIncident(
          id: 'test-004',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: futureTime,
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for future detectedAt', () {
      final futureTime = DateTime.now().toUtc().add(const Duration(hours: 1));
      expect(
        () => FireIncident(
          id: 'test-005',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: futureTime,
          sensorSource: 'VIIRS',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for invalid intensity', () {
      expect(
        () => FireIncident(
          id: 'test-006',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'extreme', // Invalid value
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for negative areaHectares', () {
      expect(
        () => FireIncident(
          id: 'test-007',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
          areaHectares: -5.0,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for zero areaHectares', () {
      expect(
        () => FireIncident(
          id: 'test-008',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
          areaHectares: 0.0,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for empty sensorSource', () {
      expect(
        () => FireIncident(
          id: 'test-009',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: '',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for confidence < 0', () {
      expect(
        () => FireIncident(
          id: 'test-010',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
          confidence: -1.0,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for confidence > 100', () {
      expect(
        () => FireIncident(
          id: 'test-011',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
          confidence: 101.0,
        ),
        throwsArgumentError,
      );
    });

    test('accepts confidence at boundary values 0 and 100', () {
      final now = DateTime.now().toUtc();
      
      final zeroConfidence = FireIncident(
        id: 'test-012',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
        confidence: 0.0,
      );
      expect(zeroConfidence.confidence, 0.0);

      final maxConfidence = FireIncident(
        id: 'test-013',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
        confidence: 100.0,
      );
      expect(maxConfidence.confidence, 100.0);
    });

    test('throws ArgumentError for negative frp', () {
      expect(
        () => FireIncident(
          id: 'test-014',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: DateTime.now().toUtc(),
          intensity: 'moderate',
          detectedAt: DateTime.now().toUtc(),
          sensorSource: 'VIIRS',
          frp: -10.0,
        ),
        throwsArgumentError,
      );
    });

    test('accepts zero frp', () {
      final now = DateTime.now().toUtc();
      final incident = FireIncident(
        id: 'test-015',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
        frp: 0.0,
      );
      expect(incident.frp, 0.0);
    });

    test('throws ArgumentError for lastUpdate before detectedAt', () {
      final now = DateTime.now().toUtc();
      final detected = now.subtract(const Duration(hours: 2));
      final updated = detected.subtract(const Duration(hours: 1));
      
      expect(
        () => FireIncident(
          id: 'test-016',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: now,
          intensity: 'moderate',
          detectedAt: detected,
          sensorSource: 'VIIRS',
          lastUpdate: updated,
        ),
        throwsArgumentError,
      );
    });

    test('accepts lastUpdate equal to detectedAt', () {
      final now = DateTime.now().toUtc();
      final incident = FireIncident(
        id: 'test-017',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
        lastUpdate: now,
      );
      expect(incident.lastUpdate, now);
    });

    test('accepts all valid intensity values', () {
      final now = DateTime.now().toUtc();
      
      for (final intensity in ['low', 'moderate', 'high']) {
        final incident = FireIncident(
          id: 'test-intensity-$intensity',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          freshness: Freshness.live,
          timestamp: now,
          intensity: intensity,
          detectedAt: now,
          sensorSource: 'VIIRS',
        );
        expect(incident.intensity, intensity);
      }
    });
  });

  group('FireIncident.test Factory', () {
    test('creates test instance with minimal parameters', () {
      final incident = FireIncident.test(
        id: 'test-018',
        location: const LatLng(55.9533, -3.1883),
      );

      expect(incident.id, 'test-018');
      expect(incident.location.latitude, 55.9533);
      expect(incident.source, DataSource.mock);
      expect(incident.freshness, Freshness.live);
      expect(incident.intensity, 'moderate');
      expect(incident.sensorSource, 'VIIRS');
    });

    test('creates test instance with custom parameters', () {
      final customTimestamp = DateTime(2024, 1, 15, 10, 30).toUtc();
      final customDetected = DateTime(2024, 1, 15, 8, 0).toUtc();
      final customUpdated = DateTime(2024, 1, 15, 10, 0).toUtc();
      
      final incident = FireIncident.test(
        id: 'test-019',
        location: const LatLng(56.0, -4.0),
        source: DataSource.effis,
        freshness: Freshness.cached,
        timestamp: customTimestamp,
        intensity: 'high',
        detectedAt: customDetected,
        sensorSource: 'MODIS',
        description: 'Test fire',
        areaHectares: 100.0,
        confidence: 90.0,
        frp: 200.0,
        lastUpdate: customUpdated,
      );

      expect(incident.id, 'test-019');
      expect(incident.source, DataSource.effis);
      expect(incident.freshness, Freshness.cached);
      expect(incident.timestamp, customTimestamp);
      expect(incident.intensity, 'high');
      expect(incident.detectedAt, customDetected);
      expect(incident.sensorSource, 'MODIS');
      expect(incident.description, 'Test fire');
      expect(incident.areaHectares, 100.0);
      expect(incident.confidence, 90.0);
      expect(incident.frp, 200.0);
      expect(incident.lastUpdate, customUpdated);
    });

    test('auto-generates timestamps if not provided', () {
      final before = DateTime.now().toUtc();
      final incident = FireIncident.test(
        id: 'test-020',
        location: const LatLng(55.9533, -3.1883),
      );
      final after = DateTime.now().toUtc();

      expect(incident.timestamp.isAfter(before) || incident.timestamp.isAtSameMomentAs(before), true);
      expect(incident.timestamp.isBefore(after) || incident.timestamp.isAtSameMomentAs(after), true);
      expect(incident.detectedAt.isAfter(before) || incident.detectedAt.isAtSameMomentAs(before), true);
      expect(incident.detectedAt.isBefore(after) || incident.detectedAt.isAtSameMomentAs(after), true);
    });
  });

  group('FireIncident JSON Serialization', () {
    test('toJson serializes all fields', () {
      final now = DateTime.now().toUtc();
      final detected = now.subtract(const Duration(hours: 2));
      final updated = now.subtract(const Duration(hours: 1));
      
      final incident = FireIncident(
        id: 'test-021',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'high',
        detectedAt: detected,
        sensorSource: 'MODIS',
        description: 'Test fire',
        areaHectares: 75.5,
        confidence: 85.0,
        frp: 150.0,
        lastUpdate: updated,
      );

      final json = incident.toJson();

      expect(json['id'], 'test-021');
      expect(json['location']['latitude'], 55.9533);
      expect(json['location']['longitude'], -3.1883);
      expect(json['source'], 'effis');
      expect(json['freshness'], 'live');
      expect(json['timestamp'], now.toIso8601String());
      expect(json['intensity'], 'high');
      expect(json['detectedAt'], detected.toIso8601String());
      expect(json['sensorSource'], 'MODIS');
      expect(json['description'], 'Test fire');
      expect(json['areaHectares'], 75.5);
      expect(json['confidence'], 85.0);
      expect(json['frp'], 150.0);
      expect(json['lastUpdate'], updated.toIso8601String());
    });

    test('toJson handles null optional fields', () {
      final now = DateTime.now().toUtc();
      final incident = FireIncident(
        id: 'test-022',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.mock,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'low',
        detectedAt: now,
        sensorSource: 'VIIRS',
      );

      final json = incident.toJson();

      expect(json['description'], null);
      expect(json['areaHectares'], null);
      expect(json['confidence'], null);
      expect(json['frp'], null);
      expect(json['lastUpdate'], null);
    });

    test('fromCacheJson deserializes all fields', () {
      final json = {
        'id': 'test-023',
        'location': {
          'latitude': 55.9533,
          'longitude': -3.1883,
        },
        'source': 'effis',
        'freshness': 'cached',
        'timestamp': '2024-01-15T10:30:00.000Z',
        'intensity': 'moderate',
        'detectedAt': '2024-01-15T08:00:00.000Z',
        'sensorSource': 'MODIS',
        'description': 'Cache test',
        'areaHectares': 50.0,
        'confidence': 75.0,
        'frp': 100.0,
        'lastUpdate': '2024-01-15T10:00:00.000Z',
      };

      final incident = FireIncident.fromCacheJson(json);

      expect(incident.id, 'test-023');
      expect(incident.location.latitude, 55.9533);
      expect(incident.location.longitude, -3.1883);
      expect(incident.source, DataSource.effis);
      expect(incident.freshness, Freshness.cached);
      expect(incident.timestamp, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(incident.intensity, 'moderate');
      expect(incident.detectedAt, DateTime.parse('2024-01-15T08:00:00.000Z').toUtc());
      expect(incident.sensorSource, 'MODIS');
      expect(incident.description, 'Cache test');
      expect(incident.areaHectares, 50.0);
      expect(incident.confidence, 75.0);
      expect(incident.frp, 100.0);
      expect(incident.lastUpdate, DateTime.parse('2024-01-15T10:00:00.000Z').toUtc());
    });

    test('fromCacheJson handles null optional fields', () {
      final json = {
        'id': 'test-024',
        'location': {
          'latitude': 56.0,
          'longitude': -4.0,
        },
        'source': 'mock',
        'freshness': 'live',
        'timestamp': '2024-01-15T10:30:00.000Z',
        'intensity': 'low',
        'detectedAt': '2024-01-15T10:30:00.000Z',
        'sensorSource': 'VIIRS',
        'description': null,
        'areaHectares': null,
        'confidence': null,
        'frp': null,
        'lastUpdate': null,
      };

      final incident = FireIncident.fromCacheJson(json);

      expect(incident.description, null);
      expect(incident.areaHectares, null);
      expect(incident.confidence, null);
      expect(incident.frp, null);
      expect(incident.lastUpdate, null);
    });

    test('roundtrip serialization preserves data', () {
      final now = DateTime.now().toUtc();
      final original = FireIncident(
        id: 'test-025',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'high',
        detectedAt: now.subtract(const Duration(hours: 2)),
        sensorSource: 'MODIS',
        description: 'Roundtrip test',
        areaHectares: 120.0,
        confidence: 95.0,
        frp: 250.0,
        lastUpdate: now.subtract(const Duration(hours: 1)),
      );

      final json = original.toJson();
      final restored = FireIncident.fromCacheJson(json);

      expect(restored.id, original.id);
      expect(restored.location.latitude, original.location.latitude);
      expect(restored.location.longitude, original.location.longitude);
      expect(restored.source, original.source);
      expect(restored.freshness, original.freshness);
      expect(restored.timestamp, original.timestamp);
      expect(restored.intensity, original.intensity);
      expect(restored.detectedAt, original.detectedAt);
      expect(restored.sensorSource, original.sensorSource);
      expect(restored.description, original.description);
      expect(restored.areaHectares, original.areaHectares);
      expect(restored.confidence, original.confidence);
      expect(restored.frp, original.frp);
      expect(restored.lastUpdate, original.lastUpdate);
    });
  });

  group('FireIncident fromJson (GeoJSON/EFFIS)', () {
    test('parses EFFIS GeoJSON with all fields', () {
      final json = {
        'id': 'effis-001',
        'geometry': {
          'coordinates': [-3.1883, 55.9533], // GeoJSON uses [lon, lat]
        },
        'properties': {
          'fid': 'effis-fid-001',
          'timestamp': '2024-01-15T10:30:00.000Z',
          'area_ha': 25.5,
          'description': 'Scotland fire',
          'detected_at': '2024-01-15T08:00:00.000Z',
          'sensor': 'MODIS',
          'confidence': 88.0,
          'frp': 175.0,
          'last_update': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);

      expect(incident.id, 'effis-001');
      expect(incident.location.latitude, 55.9533);
      expect(incident.location.longitude, -3.1883);
      expect(incident.intensity, 'moderate'); // Calculated from area_ha
      expect(incident.areaHectares, 25.5);
      expect(incident.description, 'Scotland fire');
      expect(incident.detectedAt, DateTime.parse('2024-01-15T08:00:00.000Z').toUtc());
      expect(incident.sensorSource, 'MODIS');
      expect(incident.confidence, 88.0);
      expect(incident.frp, 175.0);
      expect(incident.lastUpdate, DateTime.parse('2024-01-15T10:00:00.000Z').toUtc());
    });

    test('calculates intensity from area_ha: low', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-026',
          'area_ha': 5.0, // Low < 10
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.intensity, 'low');
      expect(incident.areaHectares, 5.0);
    });

    test('calculates intensity from area_ha: moderate', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-027',
          'area_ha': 20.0, // Moderate 10-30
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.intensity, 'moderate');
      expect(incident.areaHectares, 20.0);
    });

    test('calculates intensity from area_ha: high', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-028',
          'area_ha': 50.0, // High >= 30
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.intensity, 'high');
      expect(incident.areaHectares, 50.0);
    });

    test('uses explicit intensity from mock data', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-029',
          'intensity': 'high', // Explicit intensity
          'area_ha': 5.0, // Would calculate to low, but explicit wins
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.intensity, 'high');
    });

    test('defaults to moderate intensity when no area data', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-030',
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.intensity, 'moderate');
      expect(incident.areaHectares, null);
    });

    test('falls back to fid for id', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'fallback-id',
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.id, 'fallback-id');
    });

    test('uses MODIS as default sensor', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-031',
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.sensorSource, 'MODIS');
    });

    test('supports sensor_source field', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-032',
          'sensor_source': 'VIIRS',
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.sensorSource, 'VIIRS');
    });

    test('supports multiple timestamp field names', () {
      final timestampFields = ['timestamp', 'lastupdate', 'firedate'];
      
      for (final field in timestampFields) {
        final json = {
          'geometry': {'coordinates': [-3.1883, 55.9533]},
          'properties': {
            'fid': 'test-timestamp-$field',
            field: '2024-01-15T10:00:00.000Z',
            'detected_at': '2024-01-15T08:00:00.000Z',
          },
        };

        final incident = FireIncident.fromJson(json);
        expect(incident.timestamp, DateTime.parse('2024-01-15T10:00:00.000Z'));
      }
    });

    test('supports multiple detected_at field names', () {
      final detectedFields = ['detected_at', 'timestamp', 'firedate'];
      
      for (final field in detectedFields) {
        final json = {
          'geometry': {'coordinates': [-3.1883, 55.9533]},
          'properties': {
            'fid': 'test-detected-$field',
            field: '2024-01-15T08:00:00.000Z',
          },
        };

        final incident = FireIncident.fromJson(json);
        expect(incident.detectedAt, DateTime.parse('2024-01-15T08:00:00.000Z').toUtc());
      }
    });

    test('supports both area_ha and areaHectares', () {
      final json1 = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-033',
          'area_ha': 30.0,
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident1 = FireIncident.fromJson(json1);
      expect(incident1.areaHectares, 30.0);

      final json2 = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-034',
          'areaHectares': 40.0,
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident2 = FireIncident.fromJson(json2);
      expect(incident2.areaHectares, 40.0);
    });

    test('uses country as description fallback', () {
      final json = {
        'geometry': {'coordinates': [-3.1883, 55.9533]},
        'properties': {
          'fid': 'test-035',
          'country': 'United Kingdom',
          'detected_at': '2024-01-15T10:00:00.000Z',
        },
      };

      final incident = FireIncident.fromJson(json);
      expect(incident.description, 'United Kingdom');
    });
  });

  group('FireIncident copyWith', () {
    late FireIncident original;

    setUp(() {
      final now = DateTime.now().toUtc();
      original = FireIncident(
        id: 'test-036',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now.subtract(const Duration(hours: 2)),
        sensorSource: 'VIIRS',
        description: 'Original',
        areaHectares: 50.0,
        confidence: 80.0,
        frp: 120.0,
        lastUpdate: now.subtract(const Duration(hours: 1)),
      );
    });

    test('returns identical instance when no parameters provided', () {
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.location, original.location);
      expect(copy.source, original.source);
      expect(copy.freshness, original.freshness);
      expect(copy.timestamp, original.timestamp);
      expect(copy.intensity, original.intensity);
      expect(copy.detectedAt, original.detectedAt);
      expect(copy.sensorSource, original.sensorSource);
      expect(copy.description, original.description);
      expect(copy.areaHectares, original.areaHectares);
      expect(copy.confidence, original.confidence);
      expect(copy.frp, original.frp);
      expect(copy.lastUpdate, original.lastUpdate);
    });

    test('updates id', () {
      final copy = original.copyWith(id: 'new-id');
      expect(copy.id, 'new-id');
      expect(copy.location, original.location);
    });

    test('updates location', () {
      const newLocation = LatLng(56.0, -4.0);
      final copy = original.copyWith(location: newLocation);
      expect(copy.location, newLocation);
      expect(copy.id, original.id);
    });

    test('updates source', () {
      final copy = original.copyWith(source: DataSource.mock);
      expect(copy.source, DataSource.mock);
      expect(copy.freshness, original.freshness);
    });

    test('updates freshness', () {
      final copy = original.copyWith(freshness: Freshness.cached);
      expect(copy.freshness, Freshness.cached);
      expect(copy.source, original.source);
    });

    test('updates timestamp', () {
      final newTime = DateTime.now().toUtc();
      final copy = original.copyWith(timestamp: newTime);
      expect(copy.timestamp, newTime);
      expect(copy.detectedAt, original.detectedAt);
    });

    test('updates intensity', () {
      final copy = original.copyWith(intensity: 'high');
      expect(copy.intensity, 'high');
      expect(copy.id, original.id);
    });

    test('updates detectedAt', () {
      final newDetected = DateTime.now().toUtc().subtract(const Duration(hours: 3));
      final copy = original.copyWith(detectedAt: newDetected);
      expect(copy.detectedAt, newDetected);
      expect(copy.timestamp, original.timestamp);
    });

    test('updates sensorSource', () {
      final copy = original.copyWith(sensorSource: 'MODIS');
      expect(copy.sensorSource, 'MODIS');
      expect(copy.id, original.id);
    });

    test('updates description', () {
      final copy = original.copyWith(description: 'Updated description');
      expect(copy.description, 'Updated description');
      expect(copy.id, original.id);
    });

    test('updates areaHectares', () {
      final copy = original.copyWith(areaHectares: 100.0);
      expect(copy.areaHectares, 100.0);
      expect(copy.id, original.id);
    });

    test('updates confidence', () {
      final copy = original.copyWith(confidence: 95.0);
      expect(copy.confidence, 95.0);
      expect(copy.id, original.id);
    });

    test('updates frp', () {
      final copy = original.copyWith(frp: 200.0);
      expect(copy.frp, 200.0);
      expect(copy.id, original.id);
    });

    test('updates lastUpdate', () {
      final newUpdate = DateTime.now().toUtc();
      final copy = original.copyWith(lastUpdate: newUpdate);
      expect(copy.lastUpdate, newUpdate);
      expect(copy.id, original.id);
    });

    test('updates multiple fields at once', () {
      final copy = original.copyWith(
        intensity: 'high',
        confidence: 99.0,
        frp: 300.0,
        areaHectares: 150.0,
      );

      expect(copy.intensity, 'high');
      expect(copy.confidence, 99.0);
      expect(copy.frp, 300.0);
      expect(copy.areaHectares, 150.0);
      expect(copy.id, original.id);
      expect(copy.sensorSource, original.sensorSource);
    });
  });

  group('FireIncident Equality', () {
    test('equal instances have same hashCode', () {
      final now = DateTime.now().toUtc();
      final incident1 = FireIncident(
        id: 'test-037',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
      );

      final incident2 = FireIncident(
        id: 'test-037',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
      );

      expect(incident1, incident2);
      expect(incident1.hashCode, incident2.hashCode);
    });

    test('different ids produce different instances', () {
      final now = DateTime.now().toUtc();
      final incident1 = FireIncident(
        id: 'test-038',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
      );

      final incident2 = FireIncident(
        id: 'test-039',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
      );

      expect(incident1, isNot(incident2));
      expect(incident1.hashCode, isNot(incident2.hashCode));
    });

    test('different confidence values produce different instances', () {
      final now = DateTime.now().toUtc();
      final incident1 = FireIncident(
        id: 'test-040',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
        confidence: 80.0,
      );

      final incident2 = FireIncident(
        id: 'test-040',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
        confidence: 90.0,
      );

      expect(incident1, isNot(incident2));
    });

    test('null vs non-null optional fields produce different instances', () {
      final now = DateTime.now().toUtc();
      final incident1 = FireIncident(
        id: 'test-041',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
      );

      final incident2 = FireIncident(
        id: 'test-041',
        location: const LatLng(55.9533, -3.1883),
        source: DataSource.effis,
        freshness: Freshness.live,
        timestamp: now,
        intensity: 'moderate',
        detectedAt: now,
        sensorSource: 'VIIRS',
        confidence: 85.0,
      );

      expect(incident1, isNot(incident2));
    });
  });
}
