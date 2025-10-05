import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Service imports
import 'services/fire_risk_service.dart';
import 'services/fire_risk_service_impl.dart';
import 'services/location_resolver.dart';
import 'services/location_resolver_impl.dart';
import 'services/contracts/service_contracts.dart';
import 'services/effis_service_impl.dart';
import 'services/mock_service.dart';

// Model imports
import 'models/api_error.dart';
import 'models/effis_fwi_result.dart';

// Core imports
import 'package:dartz/dartz.dart'
    hide State; // Hide dartz State to avoid conflict with Flutter State

// App imports
import 'app.dart';
import 'controllers/home_controller.dart';

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
  // await _clearCachedLocation(); // COMMENTED OUT: Test mode disabled - uncomment to force Portugal coords
  
  // Initialize services using composition root pattern
  final services = await _initializeServices();

  // Create home controller with injected services
  final homeController = HomeController(
    locationResolver: services.locationResolver,
    fireRiskService: services.fireRiskService,
  );

  // Create app lifecycle manager
  final lifecycleManager = AppLifecycleManager(homeController);

  // Start the app
  runApp(WildFireAppRoot(
    homeController: homeController,
    lifecycleManager: lifecycleManager,
  ));
}

/// Service container for dependency injection
class ServiceContainer {
  final LocationResolver locationResolver;
  final FireRiskService fireRiskService;

  ServiceContainer({
    required this.locationResolver,
    required this.fireRiskService,
  });
}

/// Clear cached location for testing (currently commented out in main())
Future<void> _clearCachedLocation() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('manual_location_lat');
  await prefs.remove('manual_location_lon');
  await prefs.remove('manual_location_place');
  print('🧹 Cleared cached location - will use Portugal coordinates');
}

/// Initialize all services with proper dependency wiring
Future<ServiceContainer> _initializeServices() async {
  // Initialize location resolver (A4)
  final LocationResolver locationResolver = LocationResolverImpl();

  // Initialize HTTP client for network requests
  final httpClient = http.Client();

  // Initialize EFFIS service implementation (A1)
  final effisServiceImpl = EffisServiceImpl(httpClient: httpClient);

  // Create adapter to match contract interface
  final EffisService effisService = _EffisServiceAdapter(effisServiceImpl);

  // Initialize mock service for fallback
  final MockService mockService = MockService.defaultStrategy();

  // DEBUG: Test the EFFIS service directly
  print('🔍 Testing EFFIS service directly...');
  try {
    final testResult = await effisService.getFwi(lat: 39.6, lon: -9.1);
    testResult.fold(
      (error) => print('🔍 EFFIS direct test FAILED: ${error.message}'),
      (result) => print(
          '🔍 EFFIS direct test SUCCESS: FWI=${result.fwi}, Risk=${result.riskLevel}'),
    );
  } catch (e) {
    print('🔍 EFFIS direct test EXCEPTION: $e');
  }

  // Initialize full orchestrated fire risk service (A2)
  final FireRiskService fireRiskService = FireRiskServiceImpl(
    effisService: effisService,
    mockService: mockService,
    // TODO: Add SEPA service when implemented
    // TODO: Add cache service when implemented
  );

  return ServiceContainer(
    locationResolver: locationResolver,
    fireRiskService: fireRiskService,
  );
}

/// Root app widget with lifecycle management
class WildFireAppRoot extends StatefulWidget {
  final HomeController homeController;
  final AppLifecycleManager lifecycleManager;

  const WildFireAppRoot({
    super.key,
    required this.homeController,
    required this.lifecycleManager,
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
    return WildFireApp(homeController: widget.homeController);
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
class _EffisServiceAdapter implements EffisService {
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
