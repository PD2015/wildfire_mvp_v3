import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/effis_fwi_result.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

/// Unit tests for EffisFwiResult model validation
///
/// Tests verify correct parsing and validation of EFFIS API response data
/// per docs/data-model.md specifications:
/// - UTC timestamp parsing (2023-09-13T00:00:00Z format)
/// - FWI value validation (must be non-negative double)
/// - Coordinate validation (latitude/longitude)
/// - GeoJSON geometry parsing
void main() {
  group('EffisFwiResult', () {
    group('fromJson() parsing from fixture data', () {
      test('should parse valid Edinburgh success fixture', () {
        // Parse data from our edinburgh_success.json fixture
        final jsonData = {
          "type": "Feature",
          "properties": {
            "fwi": 12.0,
            "dc": 156.8,
            "dmc": 18.6,
            "ffmc": 88.5,
            "isi": 4.8,
            "bui": 25.4,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [-3.1883, 55.9533]
          }
        };

        final result = EffisFwiResult.fromJson(jsonData);
        expect(result.fwi, equals(12.0));
        expect(result.dc, equals(156.8));
        expect(result.dmc, equals(18.6));
        expect(result.ffmc, equals(88.5));
        expect(result.isi, equals(4.8));
        expect(result.bui, equals(25.4));
        expect(result.longitude, equals(-3.1883));
        expect(result.latitude, equals(55.9533));
        expect(result.datetime, equals(DateTime.parse("2023-09-13T00:00:00Z")));
        expect(result.riskLevel, equals(RiskLevel.moderate)); // FWI=12.0
      });

      test('should handle different FWI values and risk levels', () {
        final testCases = [
          {"fwi": 3.0, "expectedRisk": "veryLow"},
          {"fwi": 8.0, "expectedRisk": "low"},
          {"fwi": 15.0, "expectedRisk": "moderate"},
          {"fwi": 30.0, "expectedRisk": "high"},
          {"fwi": 45.0, "expectedRisk": "veryHigh"},
          {"fwi": 60.0, "expectedRisk": "extreme"},
        ];

        for (final testCase in testCases) {
          final jsonData = {
            "type": "Feature",
            "properties": {
              "fwi": testCase["fwi"],
              "dc": 150.0,
              "dmc": 20.0,
              "ffmc": 85.0,
              "isi": 5.0,
              "bui": 25.0,
              "datetime": "2023-09-13T00:00:00Z"
            },
            "geometry": {
              "type": "Point",
              "coordinates": [-3.0, 55.0]
            }
          };

          final result = EffisFwiResult.fromJson(jsonData);
          expect(result.fwi, equals(testCase["fwi"]));
          RiskLevel expectedRisk;
          switch (testCase["expectedRisk"]) {
            case "veryLow":
              expectedRisk = RiskLevel.veryLow;
              break;
            case "low":
              expectedRisk = RiskLevel.low;
              break;
            case "moderate":
              expectedRisk = RiskLevel.moderate;
              break;
            case "high":
              expectedRisk = RiskLevel.high;
              break;
            case "veryHigh":
              expectedRisk = RiskLevel.veryHigh;
              break;
            case "extreme":
              expectedRisk = RiskLevel.extreme;
              break;
            default:
              throw ArgumentError(
                  'Unknown risk level: ${testCase["expectedRisk"]}');
          }
          expect(result.riskLevel, equals(expectedRisk));
        }
      });
    });

    group('datetime parsing validation', () {
      test('should parse UTC datetime correctly', () {
        final jsonData = {
          "type": "Feature",
          "properties": {
            "fwi": 10.0,
            "dc": 150.0,
            "dmc": 20.0,
            "ffmc": 85.0,
            "isi": 5.0,
            "bui": 25.0,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [-3.0, 55.0]
          }
        };

        final result = EffisFwiResult.fromJson(jsonData);
        final expectedDateTime = DateTime.parse("2023-09-13T00:00:00Z").toUtc();
        expect(result.datetime, equals(expectedDateTime));
        expect(result.datetime.isUtc, isTrue);
      });

      test('should handle different valid UTC formats', () {
        final testFormats = [
          "2023-09-13T00:00:00Z",
          "2023-09-13T12:30:45Z",
          "2023-12-31T23:59:59Z",
        ];

        for (final dateTimeStr in testFormats) {
          final jsonData = {
            "type": "Feature",
            "properties": {
              "fwi": 10.0,
              "dc": 150.0,
              "dmc": 20.0,
              "ffmc": 85.0,
              "isi": 5.0,
              "bui": 25.0,
              "datetime": dateTimeStr
            },
            "geometry": {
              "type": "Point",
              "coordinates": [-3.0, 55.0]
            }
          };

          final result = EffisFwiResult.fromJson(jsonData);
          final expectedDateTime = DateTime.parse(dateTimeStr).toUtc();
          expect(result.datetime, equals(expectedDateTime));
        }
      });

      test('should reject invalid datetime formats', () {
        final invalidDateTimes = [
          "2023-09-13", // Missing time
          "2023-09-13T00:00:00", // Missing Z
          "invalid-date", // Not a date
          "", // Empty string
        ];

        for (final invalidDateTime in invalidDateTimes) {
          final jsonData = {
            "type": "Feature",
            "properties": {
              "fwi": 10.0,
              "dc": 150.0,
              "dmc": 20.0,
              "ffmc": 85.0,
              "isi": 5.0,
              "bui": 25.0,
              "datetime": invalidDateTime
            },
            "geometry": {
              "type": "Point",
              "coordinates": [-3.0, 55.0]
            }
          };

          expect(() => EffisFwiResult.fromJson(jsonData), throwsArgumentError,
              reason: 'Should reject invalid datetime: $invalidDateTime');
        }
      });
    });

    group('FWI validation', () {
      test('should accept valid FWI values', () {
        final validFwiValues = [0.0, 5.5, 12.0, 25.7, 50.0, 100.0];

        for (final fwi in validFwiValues) {
          final jsonData = {
            "type": "Feature",
            "properties": {
              "fwi": fwi,
              "dc": 150.0,
              "dmc": 20.0,
              "ffmc": 85.0,
              "isi": 5.0,
              "bui": 25.0,
              "datetime": "2023-09-13T00:00:00Z"
            },
            "geometry": {
              "type": "Point",
              "coordinates": [-3.0, 55.0]
            }
          };

          final result = EffisFwiResult.fromJson(jsonData);
          expect(result.fwi, equals(fwi));
        }
      });

      test('should reject negative FWI values', () {
        final jsonData = {
          "type": "Feature",
          "properties": {
            "fwi": -5.0, // Invalid negative FWI
            "dc": 150.0,
            "dmc": 20.0,
            "ffmc": 85.0,
            "isi": 5.0,
            "bui": 25.0,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [-3.0, 55.0]
          }
        };

        expect(() => EffisFwiResult.fromJson(jsonData), throwsArgumentError,
            reason: 'Should reject negative FWI values');
      });
    });

    group('coordinate validation', () {
      test('should accept valid latitude/longitude coordinates', () {
        final validCoordinates = [
          [-3.1883, 55.9533], // Edinburgh
          [0.0, 0.0], // Equator/Prime Meridian
          [-180.0, -90.0], // Southwest corner
          [180.0, 90.0], // Northeast corner
        ];

        for (final coords in validCoordinates) {
          final jsonData = {
            "type": "Feature",
            "properties": {
              "fwi": 12.0,
              "dc": 150.0,
              "dmc": 20.0,
              "ffmc": 85.0,
              "isi": 5.0,
              "bui": 25.0,
              "datetime": "2023-09-13T00:00:00Z"
            },
            "geometry": {"type": "Point", "coordinates": coords}
          };

          final result = EffisFwiResult.fromJson(jsonData);
          expect(result.longitude, equals(coords[0]));
          expect(result.latitude, equals(coords[1]));
        }
      });

      test('should reject invalid coordinate ranges', () {
        final invalidCoordinates = [
          [-181.0, 0.0], // Longitude too low
          [181.0, 0.0], // Longitude too high
          [0.0, -91.0], // Latitude too low
          [0.0, 91.0], // Latitude too high
        ];

        for (final coords in invalidCoordinates) {
          final jsonData = {
            "type": "Feature",
            "properties": {
              "fwi": 12.0,
              "dc": 150.0,
              "dmc": 20.0,
              "ffmc": 85.0,
              "isi": 5.0,
              "bui": 25.0,
              "datetime": "2023-09-13T00:00:00Z"
            },
            "geometry": {"type": "Point", "coordinates": coords}
          };

          expect(() => EffisFwiResult.fromJson(jsonData), throwsArgumentError,
              reason: 'Should reject invalid coordinates: $coords');
        }
      });
    });

    group('missing fields validation', () {
      test('should require all mandatory fields', () {
        final baseJson = {
          "type": "Feature",
          "properties": {
            "fwi": 12.0,
            "dc": 150.0,
            "dmc": 20.0,
            "ffmc": 85.0,
            "isi": 5.0,
            "bui": 25.0,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [-3.0, 55.0]
          }
        };

        final mandatoryFields = [
          'fwi',
          'dc',
          'dmc',
          'ffmc',
          'isi',
          'bui',
          'datetime'
        ];

        for (final field in mandatoryFields) {
          final incompleteJson = Map<String, dynamic>.from(baseJson);
          (incompleteJson['properties'] as Map<String, dynamic>).remove(field);

          expect(() => EffisFwiResult.fromJson(incompleteJson),
              throwsArgumentError,
              reason: 'Should require field: $field');
        }
      });

      test('should require geometry coordinates', () {
        final jsonWithoutCoords = {
          "type": "Feature",
          "properties": {
            "fwi": 12.0,
            "dc": 150.0,
            "dmc": 20.0,
            "ffmc": 85.0,
            "isi": 5.0,
            "bui": 25.0,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point"
            // Missing coordinates
          }
        };

        expect(() => EffisFwiResult.fromJson(jsonWithoutCoords),
            throwsArgumentError,
            reason: 'Should require geometry coordinates');
      });
    });

    group('equatable behavior', () {
      test('should be equal when all properties match', () {
        final jsonData = {
          "type": "Feature",
          "properties": {
            "fwi": 12.0,
            "dc": 156.8,
            "dmc": 18.6,
            "ffmc": 88.5,
            "isi": 4.8,
            "bui": 25.4,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [-3.1883, 55.9533]
          }
        };

        final result1 = EffisFwiResult.fromJson(jsonData);
        final result2 = EffisFwiResult.fromJson(jsonData);
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final jsonData1 = {
          "type": "Feature",
          "properties": {
            "fwi": 12.0,
            "dc": 156.8,
            "dmc": 18.6,
            "ffmc": 88.5,
            "isi": 4.8,
            "bui": 25.4,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [-3.1883, 55.9533]
          }
        };

        final jsonData2 = {
          "type": "Feature",
          "properties": {
            "fwi": 15.0, // Different FWI
            "dc": 156.8,
            "dmc": 18.6,
            "ffmc": 88.5,
            "isi": 4.8,
            "bui": 25.4,
            "datetime": "2023-09-13T00:00:00Z"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [-3.1883, 55.9533]
          }
        };

        final result1 = EffisFwiResult.fromJson(jsonData1);
        final result2 = EffisFwiResult.fromJson(jsonData2);
        expect(result1, isNot(equals(result2)));
      });
    });
  });
}
