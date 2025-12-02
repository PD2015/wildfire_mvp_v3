import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Icon keep-alive for tree-shaking prevention (Flutter Web production builds)
// ignore: unused_import
import 'package:wildfire_mvp_v3/utils/icon_keep_alive.dart';

// Service imports
import 'services/fire_risk_service.dart';
import 'services/fire_risk_service_impl.dart';
import 'services/location_resolver.dart';
import 'services/location_resolver_impl.dart';
import 'services/contracts/service_contracts.dart' as contracts;
import 'services/effis_service_impl.dart';
import 'services/mock_service.dart';
import 'services/fire_location_service.dart';
import 'services/fire_location_service_impl.dart';
import 'services/mock_fire_service.dart';
import 'services/fire_incident_cache.dart';
import 'services/cache/fire_incident_cache_impl.dart';

// Location picker services (A15 - what3words and geocoding)
import 'features/location_picker/services/what3words_service.dart';
import 'features/location_picker/services/what3words_service_impl.dart';
import 'features/location_picker/services/geocoding_service.dart';
import 'features/location_picker/services/geocoding_service_impl.dart';

// Model imports
import 'models/api_error.dart';
import 'models/effis_fwi_result.dart';

// Core imports
import 'package:dartz/dartz.dart'
    hide State; // Hide dartz State to avoid conflict with Flutter State

// App imports
import 'app.dart';
import 'controllers/home_controller.dart';
import 'config/feature_flags.dart';

/// Application entry point with composition root dependency injection
///
/// This function sets up all service dependencies and wires them together
/// using constructor injection (composition root pattern). No service locator
/// or global state is used to maintain testability and clean architecture.
///
/// Constitutional compliance:
/// - C1: Clean architecture with dependency injection
/// - C5: Resilient error handling with proper service orchestration
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Clear cached location for testing Portugal coordinates
  // await _clearCachedLocation(); // COMMENTED OUT: Cache clearing fixed, now disabled

  // Initialize services using composition root pattern
  final services = await _initializeServices();

  // Create home controller with injected services
  final homeController = HomeController(
    locationResolver: services.locationResolver,
    fireRiskService: services.fireRiskService,
    what3wordsService: services.what3wordsService,
    geocodingService: services.geocodingService,
  );

  // Create app lifecycle manager
  final lifecycleManager = AppLifecycleManager(homeController);

  // Start the app
  runApp(
    WildFireAppRoot(
      homeController: homeController,
      lifecycleManager: lifecycleManager,
      services: services,
    ),
  );
}

/// Service container for dependency injection
class ServiceContainer {
  final LocationResolver locationResolver;
  final FireRiskService fireRiskService;
  final FireLocationService fireLocationService;
  final What3wordsService? what3wordsService;
  final GeocodingService? geocodingService;

  ServiceContainer({
    required this.locationResolver,
    required this.fireRiskService,
    required this.fireLocationService,
    this.what3wordsService,
    this.geocodingService,
  });
}

/// Initialize all services with proper dependency wiring
Future<ServiceContainer> _initializeServices() async {
  // Initialize location resolver (A4)
  final LocationResolver locationResolver = LocationResolverImpl();

  // Initialize HTTP client for network requests
  final httpClient = http.Client();

  // Initialize EFFIS service implementation (A1)
  final effisServiceImpl = EffisServiceImpl(httpClient: httpClient);

  // Create adapter to match contract interface for FireRiskService
  final contracts.EffisService effisServiceAdapter = _EffisServiceAdapter(
    effisServiceImpl,
  );

  // Initialize mock service for fallback
  final MockService mockService = MockService.defaultStrategy();

  // DEBUG: Test the EFFIS service directly
  debugPrint('🔍 Testing EFFIS service directly...');
  try {
    final testResult = await effisServiceAdapter.getFwi(lat: 39.6, lon: -9.1);
    testResult.fold(
      (error) => debugPrint('🔍 EFFIS direct test FAILED: ${error.message}'),
      (result) => debugPrint(
        '🔍 EFFIS direct test SUCCESS: FWI=${result.fwi}, Risk=${result.riskLevel}',
      ),
    );
  } catch (e) {
    debugPrint('🔍 EFFIS direct test EXCEPTION: $e');
  }

  // Initialize full orchestrated fire risk service (A2)
  final FireRiskService fireRiskService = FireRiskServiceImpl(
    effisService: effisServiceAdapter,
    mockService: mockService,
    // TODO: Add SEPA service when implemented
    // TODO: Add cache service when implemented
  );

  // Initialize cache service for fire incidents (T018)
  final prefs = await SharedPreferences.getInstance();
  final FireIncidentCache fireIncidentCache = FireIncidentCacheImpl(
    prefs: prefs,
  );

  // Initialize fire location service (A10 - EFFIS WFS + Cache + Mock fallback)
  final mockFireService = MockFireService();
  final FireLocationService fireLocationService = FireLocationServiceImpl(
    effisService: effisServiceImpl,
    cache: fireIncidentCache,
    mockService: mockFireService,
    // TODO: Add SEPA service when implemented (T017)
  );

  // Initialize what3words service (A15 - optional, requires API key)
  What3wordsService? what3wordsService;
  const w3wApiKey = FeatureFlags.what3wordsApiKey;
  if (w3wApiKey.isNotEmpty) {
    what3wordsService = What3wordsServiceImpl(
      client: httpClient,
      apiKey: w3wApiKey,
    );
    debugPrint('✅ What3words service initialized');
  } else {
    debugPrint('⚠️ What3words service disabled (no API key)');
  }

  // Initialize geocoding service (A15 - uses dedicated geocoding API key)
  // The GeocodingServiceImpl constructor handles key selection:
  // 1. Prefers GOOGLE_MAPS_GEOCODING_API_KEY (no HTTP referrer restriction)
  // 2. Falls back to googleMapsApiKey if geocoding key not set
  GeocodingService? geocodingService;
  const geocodingApiKey = FeatureFlags.geocodingApiKey;
  final mapsApiKey = FeatureFlags.googleMapsApiKey;
  if (geocodingApiKey.isNotEmpty || mapsApiKey.isNotEmpty) {
    geocodingService = GeocodingServiceImpl(
      client: httpClient,
      // Let constructor use its default key selection logic
    );
    debugPrint('✅ Geocoding service initialized');
  } else {
    debugPrint('⚠️ Geocoding service disabled (no API key)');
  }

  return ServiceContainer(
    locationResolver: locationResolver,
    fireRiskService: fireRiskService,
    fireLocationService: fireLocationService,
    what3wordsService: what3wordsService,
    geocodingService: geocodingService,
  );
}

/// Root app widget with lifecycle management
class WildFireAppRoot extends StatefulWidget {
  final HomeController homeController;
  final AppLifecycleManager lifecycleManager;
  final ServiceContainer services;

  const WildFireAppRoot({
    super.key,
    required this.homeController,
    required this.lifecycleManager,
    required this.services,
  });

  @override
  State<WildFireAppRoot> createState() => _WildFireAppRootState();
}

class _WildFireAppRootState extends State<WildFireAppRoot>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.homeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.lifecycleManager.handleLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    return WildFireApp(
      homeController: widget.homeController,
      locationResolver: widget.services.locationResolver,
      fireLocationService: widget.services.fireLocationService,
      fireRiskService: widget.services.fireRiskService,
      what3wordsService: widget.services.what3wordsService,
      geocodingService: widget.services.geocodingService,
    );
  }
}

/// Manages app lifecycle events and debounced refresh
class AppLifecycleManager {
  final HomeController _homeController;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  AppLifecycleManager(this._homeController);

  /// Handle app lifecycle state changes
  void handleLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefresh();
    }
  }

  /// Schedule a debounced refresh to avoid excessive API calls
  void _scheduleRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _homeController.load();
    });
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Adapter to bridge EFFIS implementation with contract interface
class _EffisServiceAdapter implements contracts.EffisService {
  final EffisServiceImpl _impl;

  _EffisServiceAdapter(this._impl);

  @override
  Future<Either<ApiError, EffisFwiResult>> getFwi({
    required double lat,
    required double lon,
  }) async {
    // Call the implementation with default parameters
    return await _impl.getFwi(lat: lat, lon: lon);
  }
}
