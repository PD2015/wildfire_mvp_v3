import 'dart:async';
import 'package:flutter/material.dart';

// Service imports
import 'services/fire_risk_service.dart';
import 'services/location_resolver.dart';
import 'services/location_resolver_impl.dart';

// Model imports
import 'models/api_error.dart';
import 'models/risk_level.dart';
import 'services/models/fire_risk.dart';

// Core imports
import 'package:dartz/dartz.dart' hide State; // Hide dartz State to avoid conflict with Flutter State

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

/// Initialize all services with proper dependency wiring
Future<ServiceContainer> _initializeServices() async {
    // Initialize location resolver (A4)
  final LocationResolver locationResolver = LocationResolverImpl();
  
  // Initialize fire risk service (A2) - simplified for T004
  // TODO: Wire full orchestrated FireRiskService in T005
  final FireRiskService fireRiskService = _SimplifiedFireRiskService();
  
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

class _WildFireAppRootState extends State<WildFireAppRoot> with WidgetsBindingObserver {
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

/// Simplified FireRiskService for T004 initial integration
/// TODO: Replace with full orchestrated FireRiskService in T005
class _SimplifiedFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    // Simple mock implementation for app integration
    return Right(FireRisk(
      level: RiskLevel.moderate,
      fwi: 5.0,
      source: DataSource.mock,
      observedAt: DateTime.now().toUtc(),
      freshness: Freshness.live,
    ));
  }
}
