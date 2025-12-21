import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

void main() {
  group('Hotspot', () {
    const testLocation = LatLng(55.9533, -3.1883);
    final testDetectedAt = DateTime.utc(2025, 7, 15, 13, 45);

    group('construction', () {
      test('creates instance with all required fields', () {
        final hotspot = Hotspot(
          id: 'test_001',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 25.5,
          confidence: 80.0,
        );

        expect(hotspot.id, equals('test_001'));
        expect(hotspot.location, equals(testLocation));
        expect(hotspot.detectedAt, equals(testDetectedAt));
        expect(hotspot.frp, equals(25.5));
        expect(hotspot.confidence, equals(80.0));
      });

      test('test factory creates valid instance with defaults', () {
        final hotspot = Hotspot.test(
          location: testLocation,
        );

        expect(hotspot.location, equals(testLocation));
        expect(hotspot.frp, equals(25.0)); // default
        expect(hotspot.confidence, equals(50.0)); // default
      });
    });

    group('intensity from FRP', () {
      test('FRP < 10 returns low intensity', () {
        final hotspot = Hotspot.test(
          location: testLocation,
          frp: 5.0,
        );
        expect(hotspot.intensity, equals('low'));
      });

      test('FRP = 0 returns low intensity', () {
        final hotspot = Hotspot.test(
          location: testLocation,
          frp: 0.0,
        );
        expect(hotspot.intensity, equals('low'));
      });

      test('FRP = 9.99 returns low intensity', () {
        final hotspot = Hotspot.test(
          location: testLocation,
          frp: 9.99,
        );
        expect(hotspot.intensity, equals('low'));
      });

      test('FRP = 10 returns moderate intensity', () {
        final hotspot = Hotspot.test(
          location: testLocation,
          frp: 10.0,
        );
        expect(hotspot.intensity, equals('moderate'));
      });

      test('FRP = 49.99 returns moderate intensity', () {
        final hotspot = Hotspot.test(
          location: testLocation,
          frp: 49.99,
        );
        expect(hotspot.intensity, equals('moderate'));
      });

      test('FRP = 50 returns high intensity', () {
        final hotspot = Hotspot.test(
          location: testLocation,
          frp: 50.0,
        );
        expect(hotspot.intensity, equals('high'));
      });

      test('FRP > 50 returns high intensity', () {
        final hotspot = Hotspot.test(
          location: testLocation,
          frp: 150.0,
        );
        expect(hotspot.intensity, equals('high'));
      });
    });

    group('fromJson', () {
      test('parses GeoJSON with geometry', () {
        final json = {
          'id': 'viirs_12345',
          'geometry': {
            'type': 'Point',
            'coordinates': [-3.5, 56.2],
          },
          'properties': {
            'acq_date': '2025-07-15',
            'acq_time': '1345',
            'frp': 25.5,
            'confidence': 'nominal',
          },
        };

        final hotspot = Hotspot.fromJson(json);

        expect(hotspot.id, equals('viirs_12345'));
        expect(hotspot.location.latitude, closeTo(56.2, 0.001));
        expect(hotspot.location.longitude, closeTo(-3.5, 0.001));
        expect(hotspot.frp, equals(25.5));
        expect(hotspot.confidence, equals(50.0)); // nominal -> 50
      });

      test('parses flat properties with lat/lon', () {
        final json = {
          'id': 'viirs_67890',
          'properties': {
            'latitude': 55.9533,
            'longitude': -3.1883,
            'acq_date': '2025-07-15',
            'acq_time': '1400',
            'frp': 10.0,
            'confidence': 85.0,
          },
        };

        final hotspot = Hotspot.fromJson(json);

        expect(hotspot.location.latitude, closeTo(55.9533, 0.001));
        expect(hotspot.location.longitude, closeTo(-3.1883, 0.001));
        expect(hotspot.confidence, equals(85.0));
      });

      test('parses confidence string values', () {
        final lowConfidence = Hotspot.fromJson(const {
          'id': 'test',
          'properties': {
            'latitude': 55.0,
            'longitude': -3.0,
            'acq_date': '2025-07-15',
            'acq_time': '1200',
            'frp': 10.0,
            'confidence': 'low',
          },
        });
        expect(lowConfidence.confidence, equals(25.0));

        final highConfidence = Hotspot.fromJson(const {
          'id': 'test2',
          'properties': {
            'latitude': 55.0,
            'longitude': -3.0,
            'acq_date': '2025-07-15',
            'acq_time': '1200',
            'frp': 10.0,
            'confidence': 'high',
          },
        });
        expect(highConfidence.confidence, equals(85.0));
      });

      test('generates ID if not provided', () {
        final json = {
          'properties': {
            'latitude': 55.9533,
            'longitude': -3.1883,
            'acq_date': '2025-07-15',
            'acq_time': '1400',
            'frp': 10.0,
            'confidence': 50.0,
          },
        };

        final hotspot = Hotspot.fromJson(json);

        expect(hotspot.id, startsWith('hotspot_'));
        expect(hotspot.id, contains('55.9533'));
      });

      test('handles missing acq_date gracefully', () {
        final json = {
          'id': 'test',
          'properties': {
            'latitude': 55.0,
            'longitude': -3.0,
            'frp': 10.0,
          },
        };

        final hotspot = Hotspot.fromJson(json);
        expect(hotspot.detectedAt, isNotNull);
      });
    });

    group('toJson', () {
      test('serializes to valid JSON structure', () {
        final hotspot = Hotspot(
          id: 'test_001',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 25.5,
          confidence: 80.0,
        );

        final json = hotspot.toJson();

        expect(json['id'], equals('test_001'));
        expect(json['geometry']['type'], equals('Point'));
        expect(json['geometry']['coordinates'][0], equals(-3.1883));
        expect(json['geometry']['coordinates'][1], equals(55.9533));
        expect(json['properties']['frp'], equals(25.5));
        expect(json['properties']['confidence'], equals(80.0));
      });

      test('roundtrip: toJson -> fromJson preserves data', () {
        final original = Hotspot(
          id: 'roundtrip_test',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 35.0,
          confidence: 75.0,
        );

        final json = original.toJson();
        final restored = Hotspot.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.location.latitude,
            closeTo(original.location.latitude, 0.0001));
        expect(restored.location.longitude,
            closeTo(original.location.longitude, 0.0001));
        expect(restored.frp, equals(original.frp));
        expect(restored.confidence, equals(original.confidence));
      });
    });

    group('Equatable', () {
      test('two hotspots with same props are equal', () {
        final h1 = Hotspot(
          id: 'same',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 25.0,
          confidence: 50.0,
        );
        final h2 = Hotspot(
          id: 'same',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 25.0,
          confidence: 50.0,
        );

        expect(h1, equals(h2));
        expect(h1.hashCode, equals(h2.hashCode));
      });

      test('hotspots with different IDs are not equal', () {
        final h1 = Hotspot.test(id: 'a', location: testLocation);
        final h2 = Hotspot.test(id: 'b', location: testLocation);

        expect(h1, isNot(equals(h2)));
      });
    });

    group('copyWith', () {
      test('returns identical copy when no parameters specified', () {
        final original = Hotspot(
          id: 'test_001',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 25.5,
          confidence: 80.0,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.location, equals(original.location));
        expect(copy.detectedAt, equals(original.detectedAt));
        expect(copy.frp, equals(original.frp));
        expect(copy.confidence, equals(original.confidence));
      });

      test('overrides only detectedAt when specified', () {
        final original = Hotspot(
          id: 'test_001',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 25.5,
          confidence: 80.0,
        );

        final newDate = DateTime.utc(2025, 8, 20, 15, 30);
        final copy = original.copyWith(detectedAt: newDate);

        expect(copy.id, equals(original.id));
        expect(copy.location, equals(original.location));
        expect(copy.detectedAt, equals(newDate)); // Changed
        expect(copy.frp, equals(original.frp));
        expect(copy.confidence, equals(original.confidence));
      });

      test('overrides multiple fields when specified', () {
        final original = Hotspot(
          id: 'test_001',
          location: testLocation,
          detectedAt: testDetectedAt,
          frp: 25.5,
          confidence: 80.0,
        );

        final copy = original.copyWith(
          id: 'test_002',
          frp: 50.0,
        );

        expect(copy.id, equals('test_002')); // Changed
        expect(copy.location, equals(original.location));
        expect(copy.detectedAt, equals(original.detectedAt));
        expect(copy.frp, equals(50.0)); // Changed
        expect(copy.confidence, equals(original.confidence));
      });

      test('can copy with new location', () {
        final original = Hotspot.test(location: testLocation);
        const newLocation = LatLng(56.0, -4.0);

        final copy = original.copyWith(location: newLocation);

        expect(copy.location, equals(newLocation));
        expect(copy.id, equals(original.id));
      });
    });
  });
}
