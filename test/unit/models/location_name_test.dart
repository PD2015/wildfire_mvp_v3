import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_name.dart';

void main() {
  group('LocationName', () {
    group('construction', () {
      test('creates with all required fields', () {
        const name = LocationName(
          displayName: 'Edinburgh',
          detailLevel: LocationNameDetailLevel.locality,
        );

        expect(name.displayName, equals('Edinburgh'));
        expect(name.rawAddress, isNull);
        expect(name.detailLevel, equals(LocationNameDetailLevel.locality));
      });

      test('creates with optional rawAddress', () {
        const name = LocationName(
          displayName: 'Edinburgh',
          rawAddress: 'Edinburgh, Scotland, UK',
          detailLevel: LocationNameDetailLevel.locality,
        );

        expect(name.rawAddress, equals('Edinburgh, Scotland, UK'));
      });
    });

    group('fromCoordinates factory', () {
      test('creates fallback name with rounded coordinates', () {
        final name = LocationName.fromCoordinates(55.9533, -3.1883);

        expect(name.displayName, equals('55.95, -3.19'));
        expect(name.rawAddress, isNull);
        expect(name.detailLevel,
            equals(LocationNameDetailLevel.coordinatesFallback));
      });

      test('rounds coordinates to 2 decimal places for privacy', () {
        final name = LocationName.fromCoordinates(55.95337654, -3.18834567);

        expect(name.displayName, equals('55.95, -3.19'));
      });
    });

    group('convenience getters', () {
      test('isSpecific returns true for locality', () {
        const name = LocationName(
          displayName: 'Edinburgh',
          detailLevel: LocationNameDetailLevel.locality,
        );

        expect(name.isSpecific, isTrue);
        expect(name.isNaturalFeature, isFalse);
        expect(name.isAdminAreaFallback, isFalse);
        expect(name.isCoordinatesFallback, isFalse);
      });

      test('isSpecific returns true for postalTown', () {
        const name = LocationName(
          displayName: 'Aviemore',
          detailLevel: LocationNameDetailLevel.postalTown,
        );

        expect(name.isSpecific, isTrue);
      });

      test('isSpecific returns true for sublocality', () {
        const name = LocationName(
          displayName: 'Leith',
          detailLevel: LocationNameDetailLevel.sublocality,
        );

        expect(name.isSpecific, isTrue);
      });

      test('isNaturalFeature returns true for naturalFeature', () {
        const name = LocationName(
          displayName: 'Near Ben Wyvis',
          detailLevel: LocationNameDetailLevel.naturalFeature,
        );

        expect(name.isSpecific, isFalse);
        expect(name.isNaturalFeature, isTrue);
      });

      test('isAdminAreaFallback returns true for adminArea', () {
        const name = LocationName(
          displayName: 'Highland',
          detailLevel: LocationNameDetailLevel.adminArea,
        );

        expect(name.isSpecific, isFalse);
        expect(name.isAdminAreaFallback, isTrue);
      });

      test('isCoordinatesFallback returns true for coordinatesFallback', () {
        const name = LocationName(
          displayName: '55.95, -3.19',
          detailLevel: LocationNameDetailLevel.coordinatesFallback,
        );

        expect(name.isCoordinatesFallback, isTrue);
      });
    });

    group('equality', () {
      test('equal instances have same hash code', () {
        const name1 = LocationName(
          displayName: 'Edinburgh',
          rawAddress: 'Edinburgh, UK',
          detailLevel: LocationNameDetailLevel.locality,
        );
        const name2 = LocationName(
          displayName: 'Edinburgh',
          rawAddress: 'Edinburgh, UK',
          detailLevel: LocationNameDetailLevel.locality,
        );

        expect(name1, equals(name2));
        expect(name1.hashCode, equals(name2.hashCode));
      });

      test('different displayName creates inequality', () {
        const name1 = LocationName(
          displayName: 'Edinburgh',
          detailLevel: LocationNameDetailLevel.locality,
        );
        const name2 = LocationName(
          displayName: 'Glasgow',
          detailLevel: LocationNameDetailLevel.locality,
        );

        expect(name1, isNot(equals(name2)));
      });

      test('different detailLevel creates inequality', () {
        const name1 = LocationName(
          displayName: 'Highland',
          detailLevel: LocationNameDetailLevel.locality,
        );
        const name2 = LocationName(
          displayName: 'Highland',
          detailLevel: LocationNameDetailLevel.adminArea,
        );

        expect(name1, isNot(equals(name2)));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const name = LocationName(
          displayName: 'Edinburgh',
          detailLevel: LocationNameDetailLevel.locality,
        );

        expect(name.toString(), contains('Edinburgh'));
        expect(name.toString(), contains('locality'));
      });
    });
  });

  group('LocationNameDetailLevel', () {
    test('has expected values', () {
      expect(LocationNameDetailLevel.values, hasLength(6));
      expect(
          LocationNameDetailLevel.values,
          containsAll([
            LocationNameDetailLevel.locality,
            LocationNameDetailLevel.postalTown,
            LocationNameDetailLevel.sublocality,
            LocationNameDetailLevel.naturalFeature,
            LocationNameDetailLevel.adminArea,
            LocationNameDetailLevel.coordinatesFallback,
          ]));
    });
  });
}
