import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/widgets/bottom_nav.dart';
import 'package:wildfire_mvp_v3/config/ui_constants.dart';

void main() {
  group('T004: Bottom nav Fire Risk selected state', () {
    testWidgets('bottom nav shows Fire Risk with warning icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // Verify "Fire Risk" label is displayed (not "Home")
      expect(find.text('Fire Risk'), findsOneWidget);
      expect(find.text(UIConstants.fireRiskTitle), findsOneWidget);

      // Verify "Home" text does NOT appear anywhere
      expect(find.text('Home'), findsNothing);

      // Verify warning icon is present (Icons.warning_amber when selected)
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);

      // Verify old home icon is NOT present
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('fire risk destination has proper semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // Find the semantic label for the fire risk navigation item
      final semanticsHandle = tester.getSemantics(
        find.byIcon(Icons.warning_amber),
      );

      // Verify semantic label contains "fire risk" and "warning"
      expect(semanticsHandle.label, contains('Warning'));
      expect(semanticsHandle.label, contains('fire risk'));
    });

    testWidgets('fire risk destination is selected when on / route', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // Verify fire risk is selected (index 0)
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);

      // Verify warning_amber (filled) icon is shown for selected state
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('fire risk destination is selected when on /fire-risk alias', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(currentPath: '/fire-risk'),
          ),
        ),
      );

      // Verify fire risk is selected (index 0)
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);

      // Verify warning_amber (filled) icon is shown for selected state
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('fire risk destination is NOT selected when on /map route', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(currentPath: '/map'),
          ),
        ),
      );

      // Verify map is selected (index 1), not fire risk (index 0)
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);

      // Verify warning_amber_outlined (unselected) icon is shown
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      // Verify filled warning_amber (selected) is NOT shown
      expect(find.byIcon(Icons.warning_amber), findsNothing);
    });

    testWidgets('fire risk destination is NOT selected when on /report route', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(currentPath: '/report'),
          ),
        ),
      );

      // Verify report is selected (index 2), not fire risk (index 0)
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);

      // Verify warning_amber_outlined (unselected) icon is shown
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      // Verify filled warning_amber (selected) is NOT shown
      expect(find.byIcon(Icons.warning_amber), findsNothing);
    });

    testWidgets('fire risk label uses UIConstants.fireRiskTitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // Verify the label matches UIConstants value
      expect(UIConstants.fireRiskTitle, 'Fire Risk');
      expect(find.text(UIConstants.fireRiskTitle), findsOneWidget);
    });

    testWidgets('all navigation destinations are present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // Verify all three destinations exist
      expect(find.text('Fire Risk'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Report Fire'), findsOneWidget);

      // Verify NavigationBar has exactly 3 destinations
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 3);
    });
  });
}
