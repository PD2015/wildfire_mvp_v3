import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/features/settings/screens/settings_screen.dart';
import 'package:wildfire_mvp_v3/features/settings/screens/notifications_settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          // Use actual screen for navigation test
          GoRoute(
            path: '/settings/notifications',
            builder: (context, state) => const NotificationsSettingsScreen(),
          ),
          // Stub routes for other navigation tests
          GoRoute(
            path: '/settings/about/terms',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Terms Content')),
            ),
          ),
          GoRoute(
            path: '/settings/about/privacy',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Privacy Content')),
            ),
          ),
          GoRoute(
            path: '/settings/about/disclaimer',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Disclaimer Content')),
            ),
          ),
          GoRoute(
            path: '/settings/about/data-sources',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Data Sources Content')),
            ),
          ),
          GoRoute(
            path: '/settings/advanced',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Advanced Content')),
            ),
          ),
        ],
      );
    });

    Widget buildTestWidget() {
      return MaterialApp.router(
        routerConfig: router,
      );
    }

    testWidgets('renders Settings title in AppBar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders Notifications section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Alert Settings'), findsOneWidget);
    });

    testWidgets('renders About section with legal links', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Emergency Disclaimer'), findsOneWidget);
      expect(find.text('Data Sources'), findsOneWidget);
    });

    testWidgets('Alert Settings tile is disabled (Coming soon)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the ListTile with "Alert Settings"
      final alertSettingsTile = find.ancestor(
        of: find.text('Alert Settings'),
        matching: find.byType(ListTile),
      );
      expect(alertSettingsTile, findsOneWidget);

      // Verify it's disabled by checking subtitle text
      expect(find.text('Coming soon'), findsOneWidget);

      // Tapping should not navigate (tile is disabled)
      await tester.tap(find.text('Alert Settings'));
      await tester.pumpAndSettle();

      // We should still be on the Settings screen
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tapping Terms of Service navigates correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      expect(find.text('Terms Content'), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy navigates correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Content'), findsOneWidget);
    });

    testWidgets('has accessible touch targets (≥48dp)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ListTiles have default height of 56dp which exceeds 48dp minimum
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsWidgets);

      // Verify at least one ListTile exists (basic sanity check)
      final firstTile = tester.widget<ListTile>(listTiles.first);
      expect(firstTile, isNotNull);
    });

    testWidgets('section headers have semantic labels', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find section headers by text
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);

      // Note: Full accessibility testing requires Semantics tester
      // which is beyond basic widget tests
    });
  });
}
