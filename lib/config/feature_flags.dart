/// Feature flags for A10 Google Maps MVP
///
/// Controls live data vs mock data usage and EFFIS WFS configuration.
class FeatureFlags {
  /// Control live EFFIS data vs mock data
  /// Default: false (mock-first development per C5)
  ///
  /// Usage:
  /// ```bash
  /// flutter run --dart-define=MAP_LIVE_DATA=true
  /// flutter run --dart-define-from-file=env/dev.env.json
  /// ```
  static const bool mapLiveData = bool.fromEnvironment(
    'MAP_LIVE_DATA',
    defaultValue: false,
  );

  /// Test region for EFFIS data (for regions with typical fire activity)
  /// Options: 'scotland' (default), 'portugal', 'spain', 'greece', 'california'
  ///
  /// Usage:
  /// ```bash
  /// flutter run --dart-define=TEST_REGION=portugal --dart-define=MAP_LIVE_DATA=true
  /// flutter run --dart-define=TEST_REGION=spain --dart-define=MAP_LIVE_DATA=true
  /// ```
  static const String testRegion = String.fromEnvironment(
    'TEST_REGION',
    defaultValue: 'scotland',
  );

  /// EFFIS base URL for WFS queries
  /// Default: European Commission JRC endpoint
  static const String effisBaseUrl = String.fromEnvironment(
    'EFFIS_BASE_URL',
    defaultValue: 'https://ies-ows.jrc.ec.europa.eu/',
  );

  /// EFFIS WFS layer name for burnt areas
  /// Default: effis:ba.curryear (current year burnt areas)
  static const String effisWfsLayerActive = String.fromEnvironment(
    'EFFIS_WFS_LAYER_ACTIVE',
    defaultValue: 'effis:ba.curryear',
  );

  /// Google Maps API key for Android
  /// Must be set via --dart-define-from-file=env/dev.env.json
  static const String googleMapsApiKeyAndroid = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_ANDROID',
    defaultValue: '',
  );

  /// Google Maps API key for iOS
  /// Must be set via --dart-define-from-file=env/dev.env.json
  static const String googleMapsApiKeyIos = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_IOS',
    defaultValue: '',
  );

  /// Google Maps API key for Web
  /// Must be set via --dart-define-from-file=env/dev.env.json
  static const String googleMapsApiKeyWeb = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_WEB',
    defaultValue: '',
  );

  /// what3words API key for location picker
  /// Must be set via --dart-define-from-file=env/dev.env.json
  /// Get free API key from: https://what3words.com/select-plan
  static const String what3wordsApiKey = String.fromEnvironment(
    'WHAT3WORDS_API_KEY',
    defaultValue: '',
  );

  /// Returns the appropriate Google Maps API key for the current platform
  ///
  /// For Static Maps API (HTTP requests), we need to use the Android/iOS key
  /// because Web keys have HTTP referrer restrictions that don't work for
  /// mobile app requests.
  static String get googleMapsApiKey {
    // For HTTP-based APIs (Static Maps, Geocoding), prefer Android/iOS keys
    // as they use package name restrictions, not HTTP referrers
    if (googleMapsApiKeyAndroid.isNotEmpty) return googleMapsApiKeyAndroid;
    if (googleMapsApiKeyIos.isNotEmpty) return googleMapsApiKeyIos;
    if (googleMapsApiKeyWeb.isNotEmpty) return googleMapsApiKeyWeb;
    return '';
  }
}
