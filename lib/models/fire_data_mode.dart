// Fire data display modes and filters for map visualization
//
// Part of 021-live-fire-data feature implementation.
// Defines mutually exclusive display modes and their respective time filters.

/// Display mode for fire data - mutually exclusive selection
///
/// Controls which type of fire data is displayed on the map.
/// Hotspots and burnt areas cannot be shown simultaneously.
enum FireDataMode {
  /// Active fire hotspots from GWIS WMS (VIIRS sensor data)
  hotspots,

  /// Historical burnt area polygons from EFFIS WFS (MODIS sensor data)
  burntAreas,
}

/// Time filter for hotspot data
///
/// Maps to GWIS WMS layer names for VIIRS hotspot queries.
enum HotspotTimeFilter {
  /// Last 24 hours of detections
  /// GWIS layer: viirs.hs.today
  today,

  /// Last 7 days of detections
  /// GWIS layer: viirs.hs.week
  thisWeek,
}

/// Extension to get GWIS WMS layer names for hotspot filters
extension HotspotTimeFilterX on HotspotTimeFilter {
  /// Returns the GWIS WMS layer name for this filter
  String get gwisLayerName {
    switch (this) {
      case HotspotTimeFilter.today:
        return 'viirs.hs.today';
      case HotspotTimeFilter.thisWeek:
        return 'viirs.hs.week';
    }
  }

  /// Returns human-readable label for UI display
  String get displayLabel {
    switch (this) {
      case HotspotTimeFilter.today:
        return 'Today';
      case HotspotTimeFilter.thisWeek:
        return 'This Week';
    }
  }
}

/// Season filter for burnt area data
///
/// UK/Scotland fire season runs March 1 - September 30.
/// Maps to EFFIS WFS layer queries with year parameters.
enum BurntAreaSeasonFilter {
  /// Current fire season (current year if within season, or current calendar year)
  thisSeason,

  /// Previous fire season (last year)
  lastSeason,
}

/// Extension to get year values for burnt area queries
extension BurntAreaSeasonFilterX on BurntAreaSeasonFilter {
  /// Returns the year for this season filter
  ///
  /// Fire season is March 1 - September 30.
  /// "This Season" uses current year.
  /// "Last Season" uses previous year.
  int get year {
    final now = DateTime.now();
    switch (this) {
      case BurntAreaSeasonFilter.thisSeason:
        return now.year;
      case BurntAreaSeasonFilter.lastSeason:
        return now.year - 1;
    }
  }

  /// Returns human-readable label for UI display
  String get displayLabel {
    switch (this) {
      case BurntAreaSeasonFilter.thisSeason:
        return 'This Season';
      case BurntAreaSeasonFilter.lastSeason:
        return 'Last Season';
    }
  }

  /// Returns the start date of the fire season for this filter
  ///
  /// UK fire season starts March 1.
  DateTime get seasonStart => DateTime(year, 3, 1);

  /// Returns the end date of the fire season for this filter
  ///
  /// UK fire season ends September 30.
  DateTime get seasonEnd => DateTime(year, 9, 30, 23, 59, 59);

  /// Returns true if the given date falls within this filter's season
  bool containsDate(DateTime date) {
    return !date.isBefore(seasonStart) && !date.isAfter(seasonEnd);
  }
}
