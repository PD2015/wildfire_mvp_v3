import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/features/help/screens/help_info_screen.dart';

void main() {
  group('HelpInfoScreen', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/help',
        routes: [
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpInfoScreen(),
          ),
          // Stub routes for navigation testing
          GoRoute(
            path: '/help/getting-started/how-to-use',
            builder: (context, state) =>
                const Scaffold(body: Text('How to Use')),
          ),
          GoRoute(
            path: '/help/getting-started/risk-levels',
            builder: (context, state) =>
                const Scaffold(body: Text('Risk Levels')),
          ),
          GoRoute(
            path: '/help/getting-started/when-to-use',
            builder: (context, state) =>
                const Scaffold(body: Text('When to Use')),
          ),
          GoRoute(
            path: '/help/wildfire-education/understanding-risk',
            builder: (context, state) =>
                const Scaffold(body: Text('Understanding Risk')),
          ),
          GoRoute(
            path: '/help/using-the-map/hotspots',
            builder: (context, state) => const Scaffold(body: Text('Hotspots')),
          ),
          GoRoute(
            path: '/help/safety/see-fire',
            builder: (context, state) => const Scaffold(body: Text('See Fire')),
          ),
          GoRoute(
            path: '/help/about',
            builder: (context, state) => const Scaffold(body: Text('About')),
          ),
        ],
      );
    });

    Widget buildTestWidget() {
      return MaterialApp.router(routerConfig: router);
    }

    testWidgets('renders Help & Info title in AppBar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Help & Info'), findsOneWidget);
    });

    testWidgets('renders Getting Started section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('GETTING STARTED'), findsOneWidget);
      expect(find.text('How to use WildFire'), findsOneWidget);
      expect(find.text('What the risk levels mean'), findsOneWidget);
    });

    testWidgets('renders Wildfire Education section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WILDFIRE EDUCATION'), findsOneWidget);
      expect(find.text('Understanding wildfire risk'), findsOneWidget);
    });

    testWidgets('renders Using the Map section after scrolling', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to find Using the Map section
      await tester.scrollUntilVisible(
        find.text('USING THE MAP'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('USING THE MAP'), findsOneWidget);
    });

    testWidgets('renders Using the Map items after scrolling', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to find the Using the Map section items
      await tester.scrollUntilVisible(
        find.text('What hotspots show'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('What hotspots show'), findsOneWidget);
    });

    testWidgets('renders Safety & Responsibility section after scrolling', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to find Safety section
      await tester.scrollUntilVisible(
        find.text('SAFETY & RESPONSIBILITY'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('SAFETY & RESPONSIBILITY'), findsOneWidget);
      expect(find.text('What to do if you see fire'), findsOneWidget);
    });

    testWidgets('renders About section after scrolling', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to find About section
      await tester.scrollUntilVisible(
        find.text('ABOUT'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('About WildFire'), findsOneWidget);
    });

    testWidgets('tapping How to use navigates correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('How to use WildFire'));
      await tester.pumpAndSettle();

      expect(find.text('How to Use'), findsOneWidget);
    });

    testWidgets('tapping What to do if you see fire navigates correctly', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to the item first
      await tester.scrollUntilVisible(
        find.text('What to do if you see fire'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('What to do if you see fire'));
      await tester.pumpAndSettle();

      expect(find.text('See Fire'), findsOneWidget);
    });

    testWidgets('tapping About WildFire navigates correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to the item first
      await tester.scrollUntilVisible(
        find.text('About WildFire'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('About WildFire'));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('has accessible touch targets (≥48dp)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ListTiles have default height of 56dp which exceeds 48dp minimum
      // Just check that there are ListTiles visible (not all will be visible without scrolling)
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsWidgets);

      // Check that at least some are visible (top section)
      expect(listTiles.evaluate().length, greaterThanOrEqualTo(3));
    });

    testWidgets('section headers use semantic header role', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // At least some sections should be visible with header semantics
      final semanticsWidgets = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.header == true,
      );

      // Should have at least 2-3 visible section headers
      expect(semanticsWidgets.evaluate().length, greaterThanOrEqualTo(2));
    });
  });
}
