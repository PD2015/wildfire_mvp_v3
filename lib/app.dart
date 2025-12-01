import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'controllers/home_controller.dart';
import 'screens/home_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/map/controllers/map_controller.dart';
import 'features/report/screens/report_fire_screen.dart';
import 'features/location_picker/screens/location_picker_screen.dart';
import 'features/location_picker/models/location_picker_mode.dart';
import 'features/location_picker/services/what3words_service_impl.dart';
import 'features/location_picker/services/geocoding_service_impl.dart';
import 'services/location_resolver.dart';
import 'services/fire_location_service.dart';
import 'services/fire_risk_service.dart';
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
  final FireLocationService fireLocationService;
  final FireRiskService fireRiskService;

  WildFireApp({
    super.key,
    required this.homeController,
    required this.locationResolver,
    required this.fireLocationService,
    required this.fireRiskService,
  });

  /// Router configuration with go_router and bottom navigation
  late final GoRouter _router = GoRouter(
    routes: [
      // Full-screen location picker (no bottom nav)
      GoRoute(
        path: '/location-picker',
        name: 'location-picker',
        builder: (context, state) {
          final mode = state.extra as LocationPickerMode? ??
              LocationPickerMode.riskLocation;
          return LocationPickerScreen(
            mode: mode,
            what3wordsService: What3wordsServiceImpl(),
            geocodingService: GeocodingServiceImpl(),
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
              // Create MapController with required services
              final mapController = MapController(
                locationResolver: locationResolver,
                fireLocationService: fireLocationService,
                fireRiskService: fireRiskService,
              );
              return MapScreen(controller: mapController);
            },
          ),
          GoRoute(
            path: '/report',
            name: 'report',
            builder: (context, state) => const ReportFireScreen(),
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
