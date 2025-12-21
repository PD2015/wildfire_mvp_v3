import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';

void main() {
  group('FireDataMode', () {
    test('hotspots is first value (default in UI)', () {
      expect(FireDataMode.values.first, equals(FireDataMode.hotspots));
    });

    test('has exactly two variants', () {
      expect(FireDataMode.values.length, equals(2));
      expect(FireDataMode.values, contains(FireDataMode.hotspots));
      expect(FireDataMode.values, contains(FireDataMode.burntAreas));
    });
  });

  group('HotspotTimeFilter', () {
    test('today maps to viirs.hs.today layer', () {
      expect(HotspotTimeFilter.today.gwisLayerName, equals('viirs.hs.today'));
    });

    test('thisWeek maps to viirs.hs.week layer', () {
      expect(HotspotTimeFilter.thisWeek.gwisLayerName, equals('viirs.hs.week'));
    });

    test('today display label is "Today"', () {
      expect(HotspotTimeFilter.today.displayLabel, equals('Today'));
    });

    test('thisWeek display label is "This Week"', () {
      expect(HotspotTimeFilter.thisWeek.displayLabel, equals('This Week'));
    });
  });

  group('BurntAreaSeasonFilter', () {
    test('thisSeason returns current year', () {
      final currentYear = DateTime.now().year;
      expect(BurntAreaSeasonFilter.thisSeason.year, equals(currentYear));
    });

    test('lastSeason returns previous year', () {
      final lastYear = DateTime.now().year - 1;
      expect(BurntAreaSeasonFilter.lastSeason.year, equals(lastYear));
    });

    test('thisSeason display label is "This Season"', () {
      expect(
          BurntAreaSeasonFilter.thisSeason.displayLabel, equals('This Season'));
    });

    test('lastSeason display label is "Last Season"', () {
      expect(
          BurntAreaSeasonFilter.lastSeason.displayLabel, equals('Last Season'));
    });

    group('seasonStart', () {
      test('returns March 1 of the filter year', () {
        final start = BurntAreaSeasonFilter.thisSeason.seasonStart;
        expect(start.month, equals(3));
        expect(start.day, equals(1));
        expect(start.year, equals(DateTime.now().year));
      });
    });

    group('seasonEnd', () {
      test('returns September 30 of the filter year', () {
        final end = BurntAreaSeasonFilter.thisSeason.seasonEnd;
        expect(end.month, equals(9));
        expect(end.day, equals(30));
        expect(end.year, equals(DateTime.now().year));
      });
    });

    group('containsDate', () {
      test('returns true for date within season', () {
        final midSeason = DateTime(DateTime.now().year, 6, 15);
        expect(
          BurntAreaSeasonFilter.thisSeason.containsDate(midSeason),
          isTrue,
        );
      });

      test('returns true for season start date', () {
        final startDate = DateTime(DateTime.now().year, 3, 1);
        expect(
          BurntAreaSeasonFilter.thisSeason.containsDate(startDate),
          isTrue,
        );
      });

      test('returns true for season end date', () {
        final endDate = DateTime(DateTime.now().year, 9, 30);
        expect(
          BurntAreaSeasonFilter.thisSeason.containsDate(endDate),
          isTrue,
        );
      });

      test('returns false for date before season', () {
        final beforeSeason = DateTime(DateTime.now().year, 2, 28);
        expect(
          BurntAreaSeasonFilter.thisSeason.containsDate(beforeSeason),
          isFalse,
        );
      });

      test('returns false for date after season', () {
        final afterSeason = DateTime(DateTime.now().year, 10, 1);
        expect(
          BurntAreaSeasonFilter.thisSeason.containsDate(afterSeason),
          isFalse,
        );
      });
    });
  });
}
