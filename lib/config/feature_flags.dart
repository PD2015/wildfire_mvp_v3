/// Feature flags for A10 Google Maps MVP
///
/// Controls live data vs mock data usage and EFFIS WFS configuration.
class FeatureFlags {
  /// Development mode flag - enables hardcoded test coordinates
  ///
  /// When true (default for local development):
  /// - Default fallback location uses Aviemore (57.2, -3.8) which has fire data for testing
  /// - Useful for emulator/simulator testing where GPS may not work
  ///
  /// When false (production builds):
  /// - Default fallback location uses real Scotland centroid (55.8642, -4.2518)
  /// - This is the geographic center of Scotland
  ///
  /// Usage:
  /// ```bash
  /// # Development (uses Aviemore test coordinates)
  /// flutter run --dart-define=DEV_MODE=true
  /// flutter run --dart-define-from-file=env/dev.env.json
  ///
  /// # Production (uses real Scotland centroid)
  /// flutter run --dart-define=DEV_MODE=false
  /// flutter build apk --dart-define=DEV_MODE=false
  /// ```
  ///
  /// Note: This affects the fallback location when GPS is unavailable.
  /// It does NOT affect the TEST_REGION flag which controls which
  /// geographic region's fire data is fetched.
  static const bool devMode = bool.fromEnvironment(
    'DEV_MODE',
    defaultValue: true, // Default true for development convenience
  );

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
  /// Default: Copernicus emergency endpoint (migrated Dec 2025)
  /// Legacy: ies-ows.jrc.ec.europa.eu (deprecated, stale data)
  static const String effisBaseUrl = String.fromEnvironment(
    'EFFIS_BASE_URL',
    defaultValue: 'https://maps.effis.emergency.copernicus.eu/',
  );

  /// EFFIS WFS layer name for burnt areas
  /// Default: ms:modis.ba.poly.season (MODIS burnt area polygons, current fire season)
  static const String effisWfsLayerActive = String.fromEnvironment(
    'EFFIS_WFS_LAYER_ACTIVE',
    defaultValue: 'ms:modis.ba.poly.season',
  );

  /// NASA FIRMS API key for hotspot data
  ///
  /// Get free MAP_KEY from: https://firms.modaps.eosdis.nasa.gov/api/map_key/
  /// This key enables faster REST API access to VIIRS hotspot data.
  /// If empty, the app will use GWIS WMS as primary source instead.
  ///
  /// Usage:
  /// ```bash
  /// flutter run --dart-define=FIRMS_API_KEY=your_map_key_here
  /// flutter run --dart-define-from-file=env/dev.env.json
  /// ```
  static const String firmsApiKey = String.fromEnvironment(
    'FIRMS_API_KEY',
    defaultValue: '',
  );

  /// Whether FIRMS API is configured and should be used as primary hotspot source
  static bool get hasFirmsKey => firmsApiKey.isNotEmpty;

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

  /// Google Maps Geocoding API key (separate from Maps JS API key)
  ///
  /// This key is used for HTTP REST API calls (Geocoding, Places Autocomplete).
  /// It should have NO application restriction (not HTTP referrer) because
  /// it's used for server-style HTTP requests, not browser-loaded scripts.
  ///
  /// Security: Restrict this key to "Geocoding API" only in Google Cloud Console.
  ///
  /// Must be set via --dart-define or env file:
  /// ```bash
  /// flutter run --dart-define=GOOGLE_MAPS_GEOCODING_API_KEY=your_key
  /// ```
  static const String geocodingApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_GEOCODING_API_KEY',
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

  /// Use V2 Fire Details Bottom Sheet (improved UX)
  ///
  /// When true: Uses FireDetailsBottomSheetV2 with:
  /// - Dynamic header based on data type
  /// - Summary card with key info
  /// - Plain language descriptions
  /// - Progressive disclosure (land cover hidden by default)
  /// - "Learn More" links to help docs
  ///
  /// When false: Uses original FireDetailsBottomSheet
  ///
  /// Usage:
  /// ```bash
  /// flutter run --dart-define=USE_BOTTOM_SHEET_V2=true
  /// flutter run --dart-define-from-file=env/dev.env.json
  /// ```
  static const bool useBottomSheetV2 = bool.fromEnvironment(
    'USE_BOTTOM_SHEET_V2',
    defaultValue: false, // Default false until V2 is validated
  );
}
