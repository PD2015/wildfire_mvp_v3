import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/feature_flags.dart';
import 'content/legal_content.dart';
import 'controllers/home_controller.dart';
import 'models/consent_record.dart';
import 'screens/home_screen.dart';
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
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/notifications_settings_screen.dart';
import 'features/settings/screens/about_settings_screen.dart';
import 'features/settings/screens/advanced_settings_screen.dart';
import 'features/help/screens/help_info_screen.dart';
import 'features/help/screens/help_document_screen.dart';
import 'features/help/screens/about_help_screen.dart';
import 'features/help/content/help_content.dart';
import 'services/location_resolver.dart';
import 'services/location_state_manager.dart';
import 'services/fire_risk_service.dart';
import 'services/hotspot_service_orchestrator.dart';
import 'services/firms_hotspot_service.dart';
import 'services/gwis_wms_hotspot_service.dart';
import 'services/mock_gwis_hotspot_service.dart';
import 'services/effis_burnt_area_service_impl.dart';
import 'services/cached_burnt_area_service.dart';
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
      final isLegalPath =
          state.uri.path.startsWith('/about') ||
          state.uri.path.startsWith('/settings/about');
      final needsOnboarding = _isOnboardingRequired();

      // If onboarding is complete and user is on /onboarding, redirect to home
      if (!needsOnboarding && isOnboarding) {
        return '/';
      }

      // If onboarding is needed and user is NOT on /onboarding or legal paths,
      // redirect to onboarding
      if (needsOnboarding && !isOnboarding && !isLegalPath) {
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
          final extras =
              state.extra as LocationPickerExtras? ??
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

      // About and legal routes (legacy - redirect to new locations)
      // Keep for backwards compatibility with any deep links
      GoRoute(
        path: '/about',
        name: 'about',
        redirect: (context, state) => '/help/about',
      ),
      GoRoute(
        path: '/about/terms',
        name: 'terms',
        redirect: (context, state) => '/settings/about/terms',
      ),
      GoRoute(
        path: '/about/privacy',
        name: 'privacy',
        redirect: (context, state) => '/settings/about/privacy',
      ),
      GoRoute(
        path: '/about/disclaimer',
        name: 'disclaimer',
        redirect: (context, state) => '/settings/about/disclaimer',
      ),
      GoRoute(
        path: '/about/data-sources',
        name: 'data-sources',
        redirect: (context, state) => '/settings/about/data-sources',
      ),

      // Settings hub (no bottom nav)
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          // Notifications settings
          GoRoute(
            path: 'notifications',
            name: 'settings-notifications',
            builder: (context, state) => const NotificationsSettingsScreen(),
          ),
          // About section (legal documents hub)
          GoRoute(
            path: 'about',
            name: 'settings-about',
            builder: (context, state) => const AboutSettingsScreen(),
            routes: [
              GoRoute(
                path: 'terms',
                name: 'settings-about-terms',
                builder: (context, state) =>
                    LegalDocumentScreen(document: LegalContent.termsOfService),
              ),
              GoRoute(
                path: 'privacy',
                name: 'settings-about-privacy',
                builder: (context, state) =>
                    LegalDocumentScreen(document: LegalContent.privacyPolicy),
              ),
              GoRoute(
                path: 'disclaimer',
                name: 'settings-about-disclaimer',
                builder: (context, state) => LegalDocumentScreen(
                  document: LegalContent.emergencyDisclaimer,
                ),
              ),
              GoRoute(
                path: 'data-sources',
                name: 'settings-about-data-sources',
                builder: (context, state) =>
                    LegalDocumentScreen(document: LegalContent.dataSources),
              ),
            ],
          ),
          // Advanced settings (developer options)
          GoRoute(
            path: 'advanced',
            name: 'settings-advanced',
            builder: (context, state) => const AdvancedSettingsScreen(),
          ),
        ],
      ),

      // Help & Info hub (no bottom nav)
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpInfoScreen(),
        routes: [
          // Dynamic document route - single source of truth
          // Documents are looked up by ID from HelpContent
          GoRoute(
            path: 'doc/:id',
            name: 'help-document',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final document = HelpContent.findById(id);
              if (document == null) {
                // Fallback to help hub if document not found
                return const HelpInfoScreen();
              }
              return HelpDocumentScreen(document: document);
            },
          ),
          // About section (special screen, not a document)
          GoRoute(
            path: 'about',
            name: 'help-about',
            builder: (context, state) => const AboutHelpScreen(),
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

              // Burnt area service with caching for historical data
              // 2024 data is bundled as asset, 2025+ fetched live
              final liveService = EffisBurntAreaServiceImpl(
                httpClient: httpClient,
              );
              final burntAreaService = CachedBurntAreaService(
                liveService: liveService,
              );

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
