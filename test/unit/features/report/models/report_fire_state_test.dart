import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/models/report_fire_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart' as app;
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

void main() {
  group('ReportFireLocation', () {
    group('formattedCoordinates', () {
      test('formats coordinates with 5 decimal places', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(55.953251, -3.188267),
          selectedAt: DateTime.now(),
        );

        expect(location.formattedCoordinates, equals('55.95325, -3.18827'));
      });

      test('handles negative coordinates correctly', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(-33.86882, 151.20929),
          selectedAt: DateTime.now(),
        );

        expect(location.formattedCoordinates, equals('-33.86882, 151.20929'));
      });

      test('pads with zeros when needed', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(55.9, -3.1),
          selectedAt: DateTime.now(),
        );

        expect(location.formattedCoordinates, equals('55.90000, -3.10000'));
      });

      test('handles whole number coordinates', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(56.0, -4.0),
          selectedAt: DateTime.now(),
        );

        expect(location.formattedCoordinates, equals('56.00000, -4.00000'));
      });
    });

    group('toClipboardText', () {
      test('includes all fields when present', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          nearestPlaceName: 'Cairngorms National Park',
          what3words: What3wordsAddress.parse('slurs.this.name'),
          selectedAt: DateTime.now(),
        );

        final clipboardText = location.toClipboardText();

        expect(
          clipboardText,
          contains('Nearest place: Cairngorms National Park'),
        );
        expect(clipboardText, contains('Coordinates: 57.04850, -3.59620'));
        expect(clipboardText, contains('what3words: ///slurs.this.name'));
      });

      test('excludes place name when null', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          what3words: What3wordsAddress.parse('slurs.this.name'),
          selectedAt: DateTime.now(),
        );

        final clipboardText = location.toClipboardText();

        expect(clipboardText, isNot(contains('Nearest place')));
        expect(clipboardText, contains('Coordinates: 57.04850, -3.59620'));
        expect(clipboardText, contains('what3words: ///slurs.this.name'));
      });

      test('excludes what3words when null', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          nearestPlaceName: 'Aviemore',
          selectedAt: DateTime.now(),
        );

        final clipboardText = location.toClipboardText();

        expect(clipboardText, contains('Nearest place: Aviemore'));
        expect(clipboardText, contains('Coordinates: 57.04850, -3.59620'));
        expect(clipboardText, isNot(contains('what3words')));
      });

      test('includes only coordinates when no optional fields', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          selectedAt: DateTime.now(),
        );

        final clipboardText = location.toClipboardText();

        expect(clipboardText, equals('Coordinates: 57.04850, -3.59620'));
      });

      test('trims trailing whitespace', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          selectedAt: DateTime.now(),
        );

        final clipboardText = location.toClipboardText();

        expect(clipboardText.endsWith('\n'), isFalse);
        expect(clipboardText.endsWith(' '), isFalse);
      });
    });

    group('fromPickedLocation', () {
      test('parses valid what3words string', () {
        final location = ReportFireLocation.fromPickedLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          what3wordsRaw: 'filled.count.soap',
          placeName: 'Edinburgh',
        );

        expect(location.coordinates.latitude, equals(55.9533));
        expect(location.coordinates.longitude, equals(-3.1883));
        expect(location.what3words, isNotNull);
        expect(location.what3words!.words, equals('filled.count.soap'));
        expect(location.nearestPlaceName, equals('Edinburgh'));
      });

      test('handles what3words with slashes prefix', () {
        final location = ReportFireLocation.fromPickedLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          what3wordsRaw: '///filled.count.soap',
        );

        expect(location.what3words, isNotNull);
        expect(location.what3words!.words, equals('filled.count.soap'));
      });

      test('returns null what3words for invalid format', () {
        final location = ReportFireLocation.fromPickedLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          what3wordsRaw: 'invalid-format',
        );

        expect(location.what3words, isNull);
      });

      test('returns null what3words when input is null', () {
        final location = ReportFireLocation.fromPickedLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          what3wordsRaw: null,
        );

        expect(location.what3words, isNull);
      });

      test('sets selectedAt to current time', () {
        final before = DateTime.now();
        final location = ReportFireLocation.fromPickedLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
        );
        final after = DateTime.now();

        expect(
          location.selectedAt.isAfter(
            before.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          location.selectedAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    group('equality', () {
      test('equal locations have same props', () {
        final timestamp = DateTime(2025, 12, 3, 10, 30);
        final location1 = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          nearestPlaceName: 'Edinburgh',
          selectedAt: timestamp,
        );
        final location2 = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          nearestPlaceName: 'Edinburgh',
          selectedAt: timestamp,
        );

        expect(location1, equals(location2));
      });

      test('different coordinates are not equal', () {
        final timestamp = DateTime(2025, 12, 3, 10, 30);
        final location1 = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          selectedAt: timestamp,
        );
        final location2 = ReportFireLocation(
          coordinates: const app.LatLng(55.9534, -3.1883),
          selectedAt: timestamp,
        );

        expect(location1, isNot(equals(location2)));
      });
    });
  });

  group('ReportFireState', () {
    group('initial', () {
      test('has no fire location', () {
        const state = ReportFireState.initial();

        expect(state.fireLocation, isNull);
        expect(state.hasLocation, isFalse);
      });
    });

    group('hasLocation', () {
      test('returns true when location is set', () {
        final state = ReportFireState(
          fireLocation: ReportFireLocation(
            coordinates: const app.LatLng(55.9533, -3.1883),
            selectedAt: DateTime.now(),
          ),
        );

        expect(state.hasLocation, isTrue);
      });

      test('returns false when location is null', () {
        const state = ReportFireState();

        expect(state.hasLocation, isFalse);
      });
    });

    group('copyWith', () {
      test('updates fireLocation', () {
        const state = ReportFireState.initial();
        final newLocation = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          selectedAt: DateTime.now(),
        );

        final updated = state.copyWith(fireLocation: newLocation);

        expect(updated.fireLocation, equals(newLocation));
      });

      test('preserves fireLocation when not provided', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          selectedAt: DateTime.now(),
        );
        final state = ReportFireState(fireLocation: location);

        final updated = state.copyWith();

        expect(updated.fireLocation, equals(location));
      });

      test('clears location when clearLocation is true', () {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          selectedAt: DateTime.now(),
        );
        final state = ReportFireState(fireLocation: location);

        final updated = state.copyWith(clearLocation: true);

        expect(updated.fireLocation, isNull);
      });

      test('clearLocation takes precedence over new location', () {
        final oldLocation = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          selectedAt: DateTime.now(),
        );
        final newLocation = ReportFireLocation(
          coordinates: const app.LatLng(56.0, -4.0),
          selectedAt: DateTime.now(),
        );
        final state = ReportFireState(fireLocation: oldLocation);

        final updated = state.copyWith(
          fireLocation: newLocation,
          clearLocation: true,
        );

        expect(updated.fireLocation, isNull);
      });
    });

    group('equality', () {
      test('equal states have same props', () {
        final timestamp = DateTime(2025, 12, 3, 10, 30);
        final location = ReportFireLocation(
          coordinates: const app.LatLng(55.9533, -3.1883),
          selectedAt: timestamp,
        );
        final state1 = ReportFireState(fireLocation: location);
        final state2 = ReportFireState(fireLocation: location);

        expect(state1, equals(state2));
      });

      test('initial states are equal', () {
        const state1 = ReportFireState.initial();
        const state2 = ReportFireState.initial();

        expect(state1, equals(state2));
      });
    });
  });
}
