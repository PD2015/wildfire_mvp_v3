import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content/legal_content.dart';
import 'controllers/home_controller.dart';
import 'models/consent_record.dart';
import 'screens/home_screen.dart';
import 'screens/about_screen.dart';
import 'screens/legal_document_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/map/controllers/map_controller.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
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
import 'services/fire_location_service.dart';
import 'services/fire_risk_service.dart';
import 'services/onboarding_prefs.dart';
import 'services/onboarding_prefs_impl.dart';
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
  final SharedPreferences prefs;

  /// Shared location state manager for Report Fire screen
  /// Lazy-initialized to avoid unnecessary work on app startup
  late final LocationStateManager _reportLocationStateManager;

  /// Report fire controller for location helper state
  /// Created lazily to avoid unnecessary initialization
  late final ReportFireController _reportFireController;

  /// Onboarding preferences service
  late final OnboardingPrefsService _onboardingPrefsService;

  /// Optional geocoding services for location picker
  /// If null, LocationPickerScreen will create new instances with FeatureFlags defaults
  final What3wordsService? what3wordsService;
  final GeocodingService? geocodingService;

  WildFireApp({
    super.key,
    required this.homeController,
    required this.locationResolver,
    required this.fireLocationService,
    required this.fireRiskService,
    required this.prefs,
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

    // Create onboarding preferences service
    _onboardingPrefsService = OnboardingPrefsImpl(prefs);
  }

  /// Check if onboarding is required using synchronous prefs access
  bool _isOnboardingRequired() {
    final version = prefs.getInt(OnboardingConfig.keyOnboardingVersion) ?? 0;
    return version < OnboardingConfig.currentOnboardingVersion;
  }

  /// Router configuration with go_router and bottom navigation
  late final GoRouter _router = GoRouter(
    // Redirect logic for onboarding
    redirect: (context, state) {
      final isOnboarding = state.uri.path == '/onboarding';
      final isAboutPath = state.uri.path.startsWith('/about');
      final needsOnboarding = _isOnboardingRequired();

      // If onboarding is complete and user is on /onboarding, redirect to home
      if (!needsOnboarding && isOnboarding) {
        return '/';
      }

      // If onboarding is needed and user is NOT on /onboarding or /about/*,
      // redirect to onboarding
      if (needsOnboarding && !isOnboarding && !isAboutPath) {
        return '/onboarding';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Onboarding screen (no bottom nav, shown before main app)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => OnboardingScreen(
          prefsService: _onboardingPrefsService,
          onComplete: () {
            // Navigate to home after onboarding completes
            context.go('/');
          },
        ),
      ),

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

      // About and legal routes (no bottom nav)
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
        routes: [
          GoRoute(
            path: 'terms',
            name: 'terms',
            builder: (context, state) => LegalDocumentScreen(
              document: LegalContent.termsOfService,
            ),
          ),
          GoRoute(
            path: 'privacy',
            name: 'privacy',
            builder: (context, state) => LegalDocumentScreen(
              document: LegalContent.privacyPolicy,
            ),
          ),
          GoRoute(
            path: 'disclaimer',
            name: 'disclaimer',
            builder: (context, state) => LegalDocumentScreen(
              document: LegalContent.emergencyDisclaimer,
            ),
          ),
          GoRoute(
            path: 'data-sources',
            name: 'data-sources',
            builder: (context, state) => LegalDocumentScreen(
              document: LegalContent.dataSources,
            ),
          ),
        ],
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
