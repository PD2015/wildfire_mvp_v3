import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/widgets/app_bar_actions.dart';

void main() {
  group('AppBarActions', () {
    /// Helper to build a test widget with proper GoRouter context
    Widget buildTestWidget({
      VoidCallback? onSettingsTap,
      VoidCallback? onHelpTap,
      String initialLocation = '/',
    }) {
      final router = GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                title: const Text('Test'),
                actions: [
                  AppBarActions(
                    onSettingsTap: onSettingsTap,
                    onHelpTap: onHelpTap,
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
                actions: [
                  AppBarActions(
                    onSettingsTap: onSettingsTap,
                    onHelpTap: onHelpTap,
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                title: const Text('Help'),
                actions: [
                  AppBarActions(
                    onSettingsTap: onSettingsTap,
                    onHelpTap: onHelpTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      return MaterialApp.router(
        routerConfig: router,
      );
    }

    testWidgets('renders settings and help icons', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSettingsTap: () {},
        onHelpTap: () {},
      ));
      await tester.pumpAndSettle();

      // Find the settings and help icons (outlined when not on those pages)
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('settings icon tap triggers callback', (tester) async {
      bool settingsTapped = false;

      await tester.pumpWidget(buildTestWidget(
        onSettingsTap: () => settingsTapped = true,
        onHelpTap: () {},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();

      expect(settingsTapped, isTrue);
    });

    testWidgets('help icon tap triggers callback', (tester) async {
      bool helpTapped = false;

      await tester.pumpWidget(buildTestWidget(
        onSettingsTap: () {},
        onHelpTap: () => helpTapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pump();

      expect(helpTapped, isTrue);
    });

    testWidgets('icons have accessible touch targets (≥48dp)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSettingsTap: () {},
        onHelpTap: () {},
      ));
      await tester.pumpAndSettle();

      // IconButtons have minimum size of 48x48 by default in Material 3
      final iconButtons = find.byType(IconButton);
      expect(iconButtons.evaluate().length, equals(2));

      // Verify each IconButton has adequate touch target
      for (final element in iconButtons.evaluate()) {
        final size = element.size;
        expect(size!.width, greaterThanOrEqualTo(48.0),
            reason: 'IconButton width should be at least 48dp');
        expect(size.height, greaterThanOrEqualTo(48.0),
            reason: 'IconButton height should be at least 48dp');
      }
    });

    testWidgets('icons have semantic labels for accessibility', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSettingsTap: () {},
        onHelpTap: () {},
      ));
      await tester.pumpAndSettle();

      // Find IconButtons and verify they have tooltips (which provide semantic labels)
      final settingsButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip != null &&
            widget.tooltip!.contains('Settings'),
      );
      final helpButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip != null &&
            widget.tooltip!.contains('Help'),
      );

      expect(settingsButton, findsOneWidget);
      expect(helpButton, findsOneWidget);
    });

    testWidgets('shows filled settings icon when on settings page',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSettingsTap: () {},
        onHelpTap: () {},
        initialLocation: '/settings',
      ));
      await tester.pumpAndSettle();

      // Settings icon should be filled when on /settings
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      // Help should still be outlined
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('shows filled help icon when on help page', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSettingsTap: () {},
        onHelpTap: () {},
        initialLocation: '/help',
      ));
      await tester.pumpAndSettle();

      // Help icon should be filled when on /help
      expect(find.byIcon(Icons.help), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsNothing);
      // Settings should still be outlined
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
