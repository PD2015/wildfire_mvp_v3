import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart' as bounds;
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/hotspot_service_orchestrator.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/mock_effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/mock_gwis_hotspot_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/features/map/utils/hotspot_clusterer.dart';

/// MapController manages state for MapScreen
///
/// Orchestrates location resolution, fire data fetching, and risk assessment.
/// Extended with fire data mode support for 021-live-fire-data feature.
///
/// **Fallback Architecture**: Uses HotspotServiceOrchestrator which automatically
/// falls back through: FIRMS (primary) → GWIS WMS (fallback) → Mock (offline).
/// The `hotspotDataSource` indicates which service provided the current data.
class MapController extends ChangeNotifier {
  final LocationResolver _locationResolver;
  final FireRiskService _fireRiskService;
  final HotspotServiceOrchestrator _hotspotOrchestrator;
  final EffisBurntAreaService? _burntAreaService;

  // Fallback mock services (always available for MAP_LIVE_DATA=false)
  late final MockEffisBurntAreaService _mockBurntAreaService;
  late final MockHotspotService _mockHotspotService;

  MapState _state = const MapLoading();

  /// User's actual GPS location (null if GPS unavailable)
  /// This is set once during initialization and never changes with viewport
  LatLng? _userGpsLocation;

  /// Whether a manual location is being used (from location picker)
  bool _isManualLocation = false;

  // Fire data mode state (021-live-fire-data)
  FireDataMode _fireDataMode = FireDataMode.hotspots;
  HotspotTimeFilter _hotspotTimeFilter = HotspotTimeFilter.today;
  BurntAreaSeasonFilter _burntAreaSeasonFilter =
      BurntAreaSeasonFilter.thisSeason;

  // Fire data collections
  List<Hotspot> _hotspots = [];
  List<BurntArea> _burntAreas = [];
  List<HotspotCluster> _clusters = [];

  // Zoom level for clustering decisions
  double _currentZoom = 8.0;

  // Whether live data is available or using mock fallback
  bool _isUsingMockData = false;

  // Which service provided the hotspot data (FIRMS, GWIS, or Mock)
  HotspotDataSource _hotspotDataSource = HotspotDataSource.mock;

  // Whether the app is offline (live API failed with MAP_LIVE_DATA=true)
  // When offline, no data is shown rather than falling back to mock
  bool _isOffline = false;

  // Runtime toggle for live vs demo data mode
  // Initialized from compile-time flag but can be toggled at runtime
  // This allows testers to switch between live and demo data in the UI
  bool _useLiveData = FeatureFlags.mapLiveData;

  // Loading state for burnt area data fetches
  // Used to show loading indicator in UI
  bool _isFetchingBurntAreas = false;

  // Timestamp of last successful data fetch
  DateTime _lastUpdated = DateTime.now();

  // Request counters for cancelling stale async requests
  // When filter or mode changes, we increment these to invalidate in-flight requests
  int _burntAreaRequestId = 0;
  int _hotspotRequestId = 0;

  MapState get state => _state;

  /// Whether there is fire data to display (mode-aware)
  bool get hasFireData {
    if (_fireDataMode == FireDataMode.hotspots) {
      return _hotspots.isNotEmpty || _clusters.isNotEmpty;
    } else {
      return _burntAreas.isNotEmpty;
    }
  }

  /// Count of fire data items currently displayed
  int get fireDataCount {
    if (_fireDataMode == FireDataMode.hotspots) {
      return _hotspots.length;
    } else {
      return _burntAreas.length;
    }
  }

  /// Get freshness based on mock data flag and offline state
  ///
  /// Returns:
  /// - Freshness.live: Live API data successfully fetched
  /// - Freshness.mock: Deliberate demo mode (MAP_LIVE_DATA=false)
  /// - Freshness.cached: Future - cached live data when offline
  Freshness get dataFreshness {
    if (_isOffline) return Freshness.cached; // Indicates offline state
    if (_isUsingMockData) return Freshness.mock;
    return Freshness.live;
  }

  /// Whether the app is offline (live API failed with MAP_LIVE_DATA=true)
  bool get isOffline => _isOffline;

  /// Get last updated timestamp for current data
  DateTime get lastUpdated => _lastUpdated;

  /// Get user's actual GPS location (for distance calculations)
  /// Returns null if GPS was unavailable during initialization
  LatLng? get userGpsLocation => _userGpsLocation;

  /// Whether the current center is from a manual location selection
  bool get isManualLocation => _isManualLocation;

  // Fire data mode getters
  FireDataMode get fireDataMode => _fireDataMode;
  HotspotTimeFilter get hotspotTimeFilter => _hotspotTimeFilter;
  BurntAreaSeasonFilter get burntAreaSeasonFilter => _burntAreaSeasonFilter;
  List<Hotspot> get hotspots => _hotspots;
  List<BurntArea> get burntAreas => _burntAreas;
  List<HotspotCluster> get clusters => _clusters;
  bool get isUsingMockData => _isUsingMockData;

  /// Whether burnt area data is currently being fetched
  /// Used to show loading indicator in UI
  bool get isFetchingBurntAreas => _isFetchingBurntAreas;

  /// Which service provided the current hotspot data
  HotspotDataSource get hotspotDataSource => _hotspotDataSource;

  /// Whether live data mode is currently enabled
  /// Can be toggled at runtime for testing purposes
  bool get useLiveData => _useLiveData;

  /// Toggle between live and demo data mode at runtime
  /// Triggers a fresh data fetch with the new mode
  void setUseLiveData(bool value) {
    if (_useLiveData == value) return;
    _useLiveData = value;
    debugPrint(
      '🗺️ MapController: Switched to ${value ? "LIVE" : "DEMO"} data mode',
    );
    // Clear current data and refresh with new mode
    _hotspots = [];
    _burntAreas = [];
    _clusters = [];
    _isOffline = false;
    _isUsingMockData = !value;
    notifyListeners();
    // Fetch fresh data with new mode
    if (_currentBounds != null) {
      _fetchDataForCurrentMode();
    }
  }

  MapController({
    required LocationResolver locationResolver,
    required FireRiskService fireRiskService,
    required HotspotServiceOrchestrator hotspotOrchestrator,
    EffisBurntAreaService? burntAreaService,
  })  : _locationResolver = locationResolver,
        _fireRiskService = fireRiskService,
        _hotspotOrchestrator = hotspotOrchestrator,
        _burntAreaService = burntAreaService {
    // Initialize mock services for MAP_LIVE_DATA=false direct use
    _mockBurntAreaService = MockEffisBurntAreaService();
    _mockHotspotService = MockHotspotService();
  }

  /// Get test region coordinates based on TEST_REGION environment variable
  static LatLng _getTestRegionCenter() {
    final region = FeatureFlags.testRegion.toLowerCase();

    switch (region) {
      case 'portugal':
        return const LatLng(39.6, -9.1); // Lisbon area
      case 'spain':
        return const LatLng(40.4, -3.7); // Madrid area
      case 'greece':
        return const LatLng(37.9, 23.7); // Athens area
      case 'california':
        return const LatLng(36.7, -119.4); // Central California
      case 'australia':
        return const LatLng(-33.8, 151.2); // Sydney area
      case 'scotland':
      default:
        return const LatLng(57.2, -3.8); // Aviemore, Scotland
    }
  }

  /// Initialize controller and load initial map data
  Future<void> initialize() async {
    _state = const MapLoading();
    notifyListeners();

    try {
      // Step 1: Check for cached manual location first (from location picker)
      // This takes priority over GPS for map centering
      final cachedManual = await _locationResolver.loadCachedManualLocation();

      LatLng centerLocation;

      if (cachedManual != null) {
        // Manual location exists - use it for map center
        final (location, placeName) = cachedManual;
        centerLocation = location;
        _isManualLocation = true;
        debugPrint(
          '🗺️ Using manual location: ${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}${placeName != null ? ' ($placeName)' : ''}',
        );

        // Still try to get GPS for distance calculations (but don't use for centering)
        final gpsResult = await _locationResolver.getLatLon();
        gpsResult.fold(
          (error) {
            _userGpsLocation = null;
            debugPrint(
              '🗺️ GPS unavailable - distance calculations will be disabled',
            );
          },
          (resolved) {
            _userGpsLocation = resolved.coordinates;
            debugPrint(
              '🗺️ GPS also available at: ${resolved.coordinates.latitude.toStringAsFixed(2)}, ${resolved.coordinates.longitude.toStringAsFixed(2)} (source: ${resolved.source.name})',
            );
          },
        );
      } else {
        // No manual location - use GPS or test region fallback
        _isManualLocation = false;
        final locationResult = await _locationResolver.getLatLon();

        centerLocation = locationResult.fold(
          (error) {
            // GPS unavailable - use test region but don't set as user GPS location
            _userGpsLocation = null;
            final testCenter = _getTestRegionCenter();
            debugPrint(
              '🗺️ Using test region: ${FeatureFlags.testRegion} at ${testCenter.latitude},${testCenter.longitude}',
            );
            debugPrint(
              '🗺️ GPS unavailable - distance calculations will be disabled',
            );
            return testCenter;
          },
          (resolved) {
            // GPS available - store as user's actual location
            _userGpsLocation = resolved.coordinates;
            debugPrint(
              '🗺️ Location acquired: ${resolved.coordinates.latitude},${resolved.coordinates.longitude} (source: ${resolved.source.name})',
            );
            return resolved.coordinates;
          },
        );
      }

      // Step 2: Create default bbox around location (~220km radius to cover all of Scotland)
      final mapBounds = bounds.LatLngBounds(
        southwest: LatLng(
          centerLocation.latitude - 2.0,
          centerLocation.longitude - 2.0,
        ),
        northeast: LatLng(
          centerLocation.latitude + 2.0,
          centerLocation.longitude + 2.0,
        ),
      );

      // Store bounds and set initial success state
      _currentBounds = mapBounds;
      _lastUpdated = DateTime.now();

      // Set success state with empty incidents (fire data comes from hotspots/burntAreas)
      _state = MapSuccess(
        incidents: const [], // Legacy field - no longer used for display
        centerLocation: centerLocation,
        freshness: Freshness.live, // Will be overridden by dataFreshness getter
        lastUpdated: _lastUpdated,
      );

      // Step 3: Fetch fire data for current mode (hotspots or burnt areas)
      debugPrint(
        '🗺️ MapController: Fetching fire data for bounds: SW(${mapBounds.southwest.latitude},${mapBounds.southwest.longitude}) NE(${mapBounds.northeast.latitude},${mapBounds.northeast.longitude})',
      );
      _fetchDataForCurrentMode();

      notifyListeners();
    } catch (e) {
      _state = MapError(message: 'Initialization failed: $e');
      notifyListeners();
    }
  }

  /// Refresh fire data for visible map region
  Future<void> refreshMapData(bounds.LatLngBounds visibleBounds) async {
    final previousState = _state;

    // Store bounds for mode-specific data fetching
    _currentBounds = visibleBounds;

    // DON'T set state to loading during viewport refresh - causes map widget unmount
    // Just fetch data in background and update markers when ready

    try {
      // Update last updated timestamp
      _lastUpdated = DateTime.now();

      // Keep success state with current center
      if (previousState is MapSuccess) {
        _state = MapSuccess(
          incidents: const [], // Legacy field - no longer used for display
          centerLocation: visibleBounds.center,
          freshness:
              Freshness.live, // Will be overridden by dataFreshness getter
          lastUpdated: _lastUpdated,
        );
      } else {
        _state = MapSuccess(
          incidents: const [],
          centerLocation: visibleBounds.center,
          freshness: Freshness.live,
          lastUpdated: _lastUpdated,
        );
      }

      // Fetch mode-specific data (hotspots or burnt areas)
      _fetchDataForCurrentMode();

      notifyListeners();
    } catch (e) {
      _state = MapError(
        message: 'Refresh failed: $e',
        cachedIncidents:
            previousState is MapSuccess ? previousState.incidents : null,
        lastKnownLocation:
            previousState is MapSuccess ? previousState.centerLocation : null,
      );
      notifyListeners();
    }
  }

  /// Check fire risk at specific location
  Future<Either<String, dynamic>> checkRiskAt(LatLng location) async {
    try {
      final riskResult = await _fireRiskService.getCurrent(
        lat: location.latitude,
        lon: location.longitude,
      );

      return riskResult.fold(
        (error) => Left('Risk check failed: ${error.message}'),
        (fireRisk) => Right(fireRisk),
      );
    } catch (e) {
      return Left('Risk check error: $e');
    }
  }

  // === Fire Data Mode Methods (021-live-fire-data) ===

  /// Set the fire data display mode
  ///
  /// Clears data from the previous mode and triggers refetch for the new mode.
  void setFireDataMode(FireDataMode mode) {
    if (_fireDataMode == mode) return;

    _fireDataMode = mode;

    // Clear data from previous mode
    if (mode == FireDataMode.hotspots) {
      _burntAreas = [];
    } else {
      _hotspots = [];
      _clusters = [];
    }

    // Fetch data for the new mode
    _fetchDataForCurrentMode();

    notifyListeners();
  }

  /// Set the hotspot time filter
  ///
  /// Only applicable when in hotspots mode. Triggers data refetch.
  /// Clears existing data immediately to prevent showing stale data during fetch.
  void setHotspotTimeFilter(HotspotTimeFilter filter) {
    if (_hotspotTimeFilter == filter) return;

    _hotspotTimeFilter = filter;
    // Clear existing data immediately to prevent showing stale data
    if (_fireDataMode == FireDataMode.hotspots) {
      _hotspots = [];
      _clusters = [];
      _fetchHotspotsForCurrentBounds();
    }
    notifyListeners();
  }

  /// Set the burnt area season filter
  ///
  /// Only applicable when in burnt areas mode. Triggers data refetch.
  /// Clears existing data immediately to prevent showing stale data during fetch.
  void setBurntAreaSeasonFilter(BurntAreaSeasonFilter filter) {
    if (_burntAreaSeasonFilter == filter) return;

    _burntAreaSeasonFilter = filter;
    // Clear existing data immediately to prevent showing stale data
    if (_fireDataMode == FireDataMode.burntAreas) {
      _burntAreas = [];
      _fetchBurntAreasForCurrentBounds();
    }
    notifyListeners();
  }

  /// Current viewport bounds for data fetching
  bounds.LatLngBounds? _currentBounds;

  /// Update viewport bounds and fetch appropriate data
  ///
  /// Called when map viewport changes significantly.
  void updateBounds(bounds.LatLngBounds newBounds) {
    _currentBounds = newBounds;
    _fetchDataForCurrentMode();
  }

  /// Fetch data for the current mode using current bounds
  void _fetchDataForCurrentMode() {
    if (_currentBounds == null) return;

    if (_fireDataMode == FireDataMode.hotspots) {
      _fetchHotspotsForCurrentBounds();
    } else {
      _fetchBurntAreasForCurrentBounds();
    }
  }

  /// Fetch hotspots for current viewport
  ///
  /// **Behavior based on MAP_LIVE_DATA flag:**
  /// - `MAP_LIVE_DATA=false`: Skip live APIs, use mock data directly (demo mode)
  /// - `MAP_LIVE_DATA=true`: Try FIRMS → GWIS WMS → show offline state if all fail
  /// **Cancellation**: Uses request ID to discard stale results when filter changes.
  Future<void> _fetchHotspotsForCurrentBounds() async {
    if (_currentBounds == null) return;

    // Increment request ID to invalidate any in-flight requests
    final currentRequestId = ++_hotspotRequestId;

    debugPrint(
      '🗺️ MapController: Fetching hotspots for bounds '
      'SW(${_currentBounds!.southwest.latitude.toStringAsFixed(2)},${_currentBounds!.southwest.longitude.toStringAsFixed(2)}) '
      'NE(${_currentBounds!.northeast.latitude.toStringAsFixed(2)},${_currentBounds!.northeast.longitude.toStringAsFixed(2)}) '
      'filter: ${_hotspotTimeFilter.name} '
      'useLiveData: $_useLiveData',
    );

    // Demo mode: Skip all live APIs, use mock data directly
    if (!_useLiveData) {
      debugPrint('🗺️ MapController: MAP_LIVE_DATA=false, using mock hotspots');
      final mockResult = await _mockHotspotService.getHotspots(
        bounds: _currentBounds!,
        timeFilter: _hotspotTimeFilter,
      );

      // Check if this request is still current
      if (currentRequestId != _hotspotRequestId) {
        debugPrint(
          '🗺️ MapController: Discarding stale mock hotspot result (request $currentRequestId, current $_hotspotRequestId)',
        );
        return;
      }

      _hotspots = mockResult.getOrElse(() => []);
      _hotspotDataSource = HotspotDataSource.mock;
      _isUsingMockData = true;
      _isOffline = false;

      debugPrint(
        '🗺️ MapController: Loaded ${_hotspots.length} hotspots from mock',
      );
      _reclusterHotspots();
      notifyListeners();
      return;
    }

    // MAP_LIVE_DATA=true: Use orchestrator for live API fallback chain
    final result = await _hotspotOrchestrator.getHotspots(
      bounds: _currentBounds!,
      timeFilter: _hotspotTimeFilter,
    );

    // Check if this request is still current
    if (currentRequestId != _hotspotRequestId) {
      debugPrint(
        '🗺️ MapController: Discarding stale hotspot result (request $currentRequestId, current $_hotspotRequestId)',
      );
      return;
    }

    _hotspots = result.hotspots;
    _hotspotDataSource = result.source;
    _isUsingMockData = result.isMockData;
    _isOffline = false;

    // If all live APIs failed (fell back to mock), show offline state instead
    if (result.isMockData) {
      debugPrint(
        '🗺️ MapController: All live APIs failed, showing offline state',
      );
      _hotspots = [];
      _clusters = [];
      _isOffline = true;
      _isUsingMockData = false;
    } else {
      debugPrint(
        '🗺️ MapController: Loaded ${result.hotspots.length} hotspots from ${result.source.displayName}',
      );
      _reclusterHotspots();
    }

    notifyListeners();
  }

  /// Fetch burnt areas from EFFIS service for current viewport
  ///
  /// **Fallback**: If live EFFIS fails or service is null, falls back to mock data.
  /// **Cancellation**: Uses request ID to discard stale results when filter changes.
  Future<void> _fetchBurntAreasForCurrentBounds() async {
    if (_currentBounds == null) return;

    // Increment request ID to invalidate any in-flight requests
    final currentRequestId = ++_burntAreaRequestId;

    // Set loading state and notify UI
    _isFetchingBurntAreas = true;
    notifyListeners();

    debugPrint(
      '🗺️ MapController: Fetching burnt areas for bounds '
      'SW(${_currentBounds!.southwest.latitude.toStringAsFixed(2)},${_currentBounds!.southwest.longitude.toStringAsFixed(2)}) '
      'NE(${_currentBounds!.northeast.latitude.toStringAsFixed(2)},${_currentBounds!.northeast.longitude.toStringAsFixed(2)}) '
      'filter: ${_burntAreaSeasonFilter.name} '
      'useLiveData: $_useLiveData',
    );

    // Try live service first if available AND live data is enabled
    if (_useLiveData && _burntAreaService != null) {
      // Determine maxFeatures limit based on zoom and filter
      // Service now uses smart sorting: thisSeason=DESC, lastSeason=ASC
      // - thisSeason: Results sorted by date DESC, newest first, 2025 at top
      // - lastSeason: Results sorted by date ASC, oldest first, 2024 before 2025
      // Both can use same maxFeatures since target data is near the start
      // - High zoom (detail): no limit (smaller bbox = fewer features anyway)
      final int? maxFeatures;
      if (_currentZoom >= 9.0) {
        // At high zoom, bbox is small enough that we don't need limits
        maxFeatures = null;
      } else {
        // Both season filters: 500 is enough since sorting ensures target year is first
        maxFeatures = 500;
      }

      final result = await _burntAreaService!.getBurntAreas(
        bounds: _currentBounds!,
        seasonFilter: _burntAreaSeasonFilter,
        maxFeatures: maxFeatures,
        timeout: const Duration(seconds: 15), // Longer timeout for polygon data
      );

      // Check if this request is still current (not superseded by newer request)
      if (currentRequestId != _burntAreaRequestId) {
        debugPrint(
          '🗺️ MapController: Discarding stale burnt area result (request $currentRequestId, current $_burntAreaRequestId)',
        );
        _isFetchingBurntAreas = false;
        return;
      }

      final success = result.fold(
        (error) {
          debugPrint(
            '🗺️ MapController: Live EFFIS failed: ${error.message}, falling back to mock',
          );
          return false;
        },
        (areas) {
          debugPrint(
            '🗺️ MapController: Loaded ${areas.length} burnt areas from live EFFIS',
          );
          _burntAreas = areas;
          _isUsingMockData = false;
          _isOffline = false;
          return true;
        },
      );

      if (success) {
        _isFetchingBurntAreas = false;
        notifyListeners();
        return;
      }
    } else {
      if (!_useLiveData) {
        debugPrint('🗺️ MapController: Demo mode, using mock burnt areas');
      } else {
        debugPrint(
          '🗺️ MapController: Burnt area service not available, using mock',
        );
      }
    }

    // Check again if this request is still current before setting fallback state
    if (currentRequestId != _burntAreaRequestId) {
      debugPrint(
        '🗺️ MapController: Discarding stale burnt area fallback (request $currentRequestId, current $_burntAreaRequestId)',
      );
      _isFetchingBurntAreas = false;
      return;
    }

    // Fallback behavior depends on live data mode
    if (_useLiveData) {
      // Option C: When live data expected but API failed, show offline state
      // Don't fall back to mock - that would be misleading for safety-critical app
      debugPrint(
        '🗺️ MapController: Live API failed, showing offline state (no mock fallback)',
      );
      _burntAreas = [];
      _isOffline = true;
      _isUsingMockData = false;
    } else {
      // Demo mode: Fall back to mock service for development/testing
      final mockResult = await _mockBurntAreaService.getBurntAreas(
        bounds: _currentBounds!,
        seasonFilter: _burntAreaSeasonFilter,
      );

      // Check once more after mock fetch
      if (currentRequestId != _burntAreaRequestId) {
        debugPrint(
          '🗺️ MapController: Discarding stale mock burnt area result (request $currentRequestId, current $_burntAreaRequestId)',
        );
        _isFetchingBurntAreas = false;
        return;
      }

      mockResult.fold(
        (error) {
          debugPrint(
            '🗺️ MapController: Mock burnt area service also failed: ${error.message}',
          );
          _burntAreas = [];
          _isUsingMockData = true;
        },
        (areas) {
          debugPrint(
            '🗺️ MapController: Loaded ${areas.length} burnt areas from mock',
          );
          _burntAreas = areas;
          _isUsingMockData = true;
          _isOffline = false;
        },
      );
    }

    _isFetchingBurntAreas = false;
    notifyListeners();
  }

  /// Update current zoom level and recluster hotspots if needed
  ///
  /// Clustering radius is zoom-aware (like Mapbox Supercluster):
  /// - At low zoom, clusters cover larger geographic areas
  /// - At high zoom (>= 12), shows individual hotspots
  /// - Reclusters when zoom changes significantly (by 0.5 or more)
  void updateZoom(double zoom) {
    final previousZoom = _currentZoom;
    _currentZoom = zoom;

    // Debug: log zoom level changes
    debugPrint(
      '🔍 Zoom: ${zoom.toStringAsFixed(1)} (clusters: ${zoom < HotspotClusterer.maxClusterZoom ? "ON" : "OFF"})',
    );

    // Recluster if zoom changed significantly (0.5 zoom levels)
    // This balances responsiveness with performance
    if ((zoom - previousZoom).abs() >= 0.5) {
      _reclusterHotspots();
    }
  }

  /// Recluster hotspots based on current zoom level
  ///
  /// Uses zoom-aware clustering where the radius in pixels stays constant
  /// but the geographic coverage changes with zoom level.
  void _reclusterHotspots() {
    if (_fireDataMode != FireDataMode.hotspots) return;

    // Always cluster with zoom-aware radius
    // HotspotClusterer handles maxClusterZoom internally (zoom >= 12 = no clustering)
    _clusters = HotspotClusterer.cluster(_hotspots, zoom: _currentZoom);

    notifyListeners();
  }

  /// Whether to show clusters or individual hotspots based on zoom
  ///
  /// At zoom < 12: show cluster badges (for multi-hotspot clusters) and pins (for singles)
  /// At zoom >= 12: show individual flame pins only
  bool get shouldShowClusters =>
      _fireDataMode == FireDataMode.hotspots &&
      _currentZoom < HotspotClusterer.maxClusterZoom;

  @override
  void dispose() {
    // Clean up any listeners or resources
    super.dispose();
  }
}
