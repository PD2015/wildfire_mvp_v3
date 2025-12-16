import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'config/feature_flags.dart';
import 'controllers/home_controller.dart';
import 'screens/home_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/map/controllers/map_controller.dart';
import 'features/report/screens/report_fire_screen.dart';
import 'features/report/controllers/report_fire_controller.dart';
import 'features/location_picker/screens/location_picker_screen.dart';
import 'features/location_picker/models/location_picker_mode.dart';
import 'features/location_picker/services/what3words_service.dart';
import 'features/location_picker/services/what3words_service_impl.dart';
import 'features/location_picker/services/geocoding_service.dart';
import 'features/location_picker/services/geocoding_service_impl.dart';
import 'services/location_resolver.dart';
import 'services/location_state_manager.dart';
import 'services/fire_risk_service.dart';
import 'services/hotspot_service_orchestrator.dart';
import 'services/firms_hotspot_service.dart';
import 'services/gwis_wms_hotspot_service.dart';
import 'services/mock_gwis_hotspot_service.dart';
import 'services/effis_burnt_area_service_impl.dart';
import 'theme/wildfire_a11y_theme.dart';
import 'widgets/bottom_nav.dart';

/// WildFire application root widget
///
/// This widget configures the MaterialApp with proper theme settings and
/// routing. It receives the HomeController via dependency injection from
/// main.dart to maintain clean architecture and testability.
///
/// Constitutional compliance:
/// - C1: Clean architecture with dependency injection
/// - C4: Official Scottish wildfire theme colors
/// - C3: Accessibility support via theme configuration
class WildFireApp extends StatelessWidget {
  /// Home controller with injected services
  final HomeController homeController;
  final LocationResolver locationResolver;
  final FireRiskService fireRiskService;

  /// Shared location state manager for Report Fire screen
  /// Lazy-initialized to avoid unnecessary work on app startup
  late final LocationStateManager _reportLocationStateManager;

  /// Report fire controller for location helper state
  /// Created lazily to avoid unnecessary initialization
  late final ReportFireController _reportFireController;

  /// Optional geocoding services for location picker
  /// If null, LocationPickerScreen will create new instances with FeatureFlags defaults
  final What3wordsService? what3wordsService;
  final GeocodingService? geocodingService;

  WildFireApp({
    super.key,
    required this.homeController,
    required this.locationResolver,
    required this.fireRiskService,
    this.what3wordsService,
    this.geocodingService,
  }) {
    // Create shared location state manager for Report Fire screen
    _reportLocationStateManager = LocationStateManager(
      locationResolver: locationResolver,
      what3wordsService: what3wordsService ?? What3wordsServiceImpl(),
      geocodingService: geocodingService ?? GeocodingServiceImpl(),
    );

    // Create ReportFireController with shared location manager
    _reportFireController = ReportFireController(
      locationStateManager: _reportLocationStateManager,
    );
  }

  /// Router configuration with go_router and bottom navigation
  late final GoRouter _router = GoRouter(
    routes: [
      // Full-screen location picker (no bottom nav)
      GoRoute(
        path: '/location-picker',
        name: 'location-picker',
        builder: (context, state) {
          final extras = state.extra as LocationPickerExtras? ??
              const LocationPickerExtras(mode: LocationPickerMode.riskLocation);

          return LocationPickerScreen(
            mode: extras.mode,
            initialLocation: extras.initialLocation,
            initialPlaceName: extras.initialPlaceName,
            what3wordsService: what3wordsService ?? What3wordsServiceImpl(),
            geocodingService: geocodingService ?? GeocodingServiceImpl(),
            locationResolver: locationResolver,
          );
        },
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: AppBottomNav(currentPath: state.uri.path),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'fire-risk',
            builder: (context, state) => HomeScreen(controller: homeController),
          ),
          GoRoute(
            path: '/fire-risk',
            name: 'fire-risk-alias',
            builder: (context, state) => HomeScreen(controller: homeController),
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) {
              // Create HTTP client for fire data services
              final httpClient = http.Client();

              // Create hotspot services for orchestrator fallback chain
              // FIRMS is primary (if API key available), GWIS WMS is fallback
              final firmsService = FeatureFlags.hasFirmsKey
                  ? FirmsHotspotService(
                      apiKey: FeatureFlags.firmsApiKey,
                      httpClient: httpClient,
                    )
                  : null;
              final gwisService = GwisWmsHotspotService(httpClient: httpClient);
              final mockService = MockHotspotService();

              // Create orchestrator: FIRMS → GWIS WMS → Mock
              final hotspotOrchestrator = HotspotServiceOrchestrator(
                firmsService: firmsService,
                gwisService: gwisService,
                mockService: mockService,
              );

              // Burnt area service (EFFIS WFS - working)
              final burntAreaService =
                  EffisBurntAreaServiceImpl(httpClient: httpClient);

              // Create MapController with orchestrator
              final mapController = MapController(
                locationResolver: locationResolver,
                fireRiskService: fireRiskService,
                hotspotOrchestrator: hotspotOrchestrator,
                burntAreaService: burntAreaService,
              );
              return MapScreen(controller: mapController);
            },
          ),
          GoRoute(
            path: '/report',
            name: 'report',
            builder: (context, state) {
              // Initialize location on first navigation to Report Fire screen
              // The initialize() method is idempotent (safe to call multiple times)
              _reportFireController.initialize();
              return ReportFireScreen(controller: _reportFireController);
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WildFire Risk Assessment',

      // WCAG 2.1 AA compliant theme (C3 constitutional gate)
      // Uses BrandPalette for app chrome, RiskPalette for risk widgets (C4)
      theme: WildfireA11yTheme.light,
      darkTheme: WildfireA11yTheme.dark,
      themeMode: ThemeMode.system,

      // Accessibility and localization
      debugShowCheckedModeBanner: false,

      // Router configuration
      routerConfig: _router,

      // Error handling for navigation
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
