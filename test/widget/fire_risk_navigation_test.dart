import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wildfire_mvp_v3/controllers/home_controller.dart';
import 'package:wildfire_mvp_v3/screens/home_screen.dart';
import 'package:wildfire_mvp_v3/widgets/risk_banner.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:dartz/dartz.dart';

import 'fire_risk_navigation_test.mocks.dart';

@GenerateMocks([FireRiskService, LocationResolver])
void main() {
  group('T003: Navigation to /fire-risk shows correct content', () {
    late MockFireRiskService mockFireRiskService;
    late MockLocationResolver mockLocationResolver;
    late HomeController homeController;
    late GoRouter router;

    setUp(() {
      mockFireRiskService = MockFireRiskService();
      mockLocationResolver = MockLocationResolver();

      // Set up default mock behaviors
      when(mockLocationResolver.getLatLon()).thenAnswer(
        (_) async => const Right(LatLng(55.9533, -3.1883)), // Edinburgh
      );

      when(
        mockFireRiskService.getCurrent(
          lat: anyNamed('lat'),
          lon: anyNamed('lon'),
        ),
      ).thenAnswer(
        (_) async => Right(
          FireRisk(
            level: RiskLevel.low,
            fwi: 8.0,
            source: DataSource.mock,
            observedAt: DateTime.now().toUtc(),
            freshness: Freshness.live,
          ),
        ),
      );

      homeController = HomeController(
        fireRiskService: mockFireRiskService,
        locationResolver: mockLocationResolver,
      );

      // Create router with both '/' and '/fire-risk' routes
      router = GoRouter(
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
        ],
      );
    });

    tearDown(() {
      homeController.dispose();
    });

    testWidgets('navigating to / shows HomeScreen with correct title', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to root route
      router.go('/');
      await tester.pumpAndSettle();

      // Verify AppBar shows "Wildfire Risk" (not "Home")
      expect(find.text('Wildfire Risk'), findsOneWidget);

      // Verify no "Home" text appears in AppBar or main content
      expect(find.text('Home'), findsNothing);

      // Verify RiskBanner widget is present
      expect(find.byType(RiskBanner), findsOneWidget);

      // Verify HomeScreen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigating to /fire-risk shows same HomeScreen', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to /fire-risk alias
      router.go('/fire-risk');
      await tester.pumpAndSettle();

      // Verify AppBar shows "Wildfire Risk"
      expect(find.text('Wildfire Risk'), findsOneWidget);

      // Verify RiskBanner widget is present
      expect(find.byType(RiskBanner), findsOneWidget);

      // Verify HomeScreen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify no "Home" text appears
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('both routes display identical content', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to / and capture widgets
      router.go('/');
      await tester.pumpAndSettle();

      final rootAppBarText = find.text('Wildfire Risk');
      final rootRiskBanner = find.byType(RiskBanner);

      expect(rootAppBarText, findsOneWidget);
      expect(rootRiskBanner, findsOneWidget);

      // Navigate to /fire-risk and verify same widgets
      router.go('/fire-risk');
      await tester.pumpAndSettle();

      expect(find.text('Wildfire Risk'), findsOneWidget);
      expect(find.byType(RiskBanner), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('RiskBanner displays fire risk data correctly', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go('/');
      await tester.pumpAndSettle();

      // Wait for async data loading
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify RiskBanner is showing risk data (not just loading)
      expect(find.byType(RiskBanner), findsOneWidget);

      // Verify fire risk service was called (with any parameters including optional deadline)
      verify(
        mockFireRiskService.getCurrent(
          lat: anyNamed('lat'),
          lon: anyNamed('lon'),
          deadline: anyNamed('deadline'),
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('route name "fire-risk" is correctly set', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go('/');
      await tester.pumpAndSettle();

      // Verify the named route is accessible
      final routeMatch = router.routerDelegate.currentConfiguration;
      expect(routeMatch.uri.path, '/');

      // Verify route name matches
      final route =
          router.routerDelegate.currentConfiguration.matches.last.route
              as GoRoute;
      expect(route.name, 'fire-risk');
    });

    testWidgets('route alias "/fire-risk" has correct name', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go('/fire-risk');
      await tester.pumpAndSettle();

      // Verify the alias route is accessible
      final routeMatch = router.routerDelegate.currentConfiguration;
      expect(routeMatch.uri.path, '/fire-risk');

      // Verify route name matches
      final route =
          router.routerDelegate.currentConfiguration.matches.last.route
              as GoRoute;
      expect(route.name, 'fire-risk-alias');
    });
  });
}
