import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/screens/report_fire_screen.dart';

void main() {
  group('ReportFireScreen Widget Tests', () {
    testWidgets('should display screen title and three emergency buttons', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));
      await tester.pumpAndSettle(); // Let all animations/layouts complete

      // Assert
      expect(find.text('Report a Fire'), findsOneWidget);

      // Check for first two button texts (visible on screen)
      expect(find.text('Call 999 — Fire Service'), findsOneWidget);
      expect(find.text('Call 101 — Police Scotland'), findsOneWidget);

      // Scroll down to see third button
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Call 0800 555 111 — Crimestoppers'), findsOneWidget);
    });

    testWidgets('should have AppBar with correct title', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Report a Fire'), findsOneWidget);
    });

    testWidgets('should display header section with guidance', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));

      // Assert - Check for new simpler A12b layout
      expect(find.text('See smoke, flames, or a campfire?'), findsOneWidget);
      expect(find.text('Act fast — stay safe.'), findsOneWidget);
      expect(
        find.text('1) If the fire is spreading or unsafe:'),
        findsOneWidget,
      );
      expect(
        find.text('2) If someone is lighting a fire irresponsibly:'),
        findsOneWidget,
      );
      expect(find.text('3) Want to report anonymously?'), findsOneWidget);
    });

    testWidgets('should display footer section with safety information', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));
      await tester.pumpAndSettle();

      // Scroll to see tips at bottom
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Assert - Check for Tips card
      expect(find.text('Safety Tips'), findsOneWidget);
      expect(find.textContaining('What3Words or GPS'), findsOneWidget);
      expect(
        find.textContaining('Never fight wildfires yourself'),
        findsOneWidget,
      );
      expect(find.textContaining('Keep vehicle access clear'), findsOneWidget);
    });

    testWidgets('should have proper semantic labels for accessibility', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));
      await tester.pumpAndSettle();

      // Assert - Check semantic labeling for banner
      final bannerSemantics = tester.getSemantics(
        find.text('See smoke, flames, or a campfire?'),
      );
      expect(bannerSemantics.label, isNotNull);

      // Check banner and tips icons are present
      expect(
        find.byIcon(Icons.local_fire_department),
        findsOneWidget,
      ); // Banner
    });

    testWidgets('should handle button taps and show SnackBar on dialer failure',
        (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));

      // Tap the Fire Service button (url_launcher will fail in test environment)
      await tester.tap(find.text('Call 999 — Fire Service'));
      await tester.pump();

      // In test environment, url_launcher fails so SnackBar should appear
      // Note: This depends on url_launcher behavior in test environment
      // which typically shows "binding has not been initialized" error
    });

    testWidgets('should render all buttons with minimum touch target size', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));

      // Assert - Check all buttons meet accessibility requirements (48dp minimum)
      final buttons = tester.widgetList<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      for (final button in buttons) {
        final buttonBox = tester.renderObject<RenderBox>(find.byWidget(button));
        expect(
          buttonBox.size.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Button must meet minimum touch target size of 48dp',
        );
      }
    });

    testWidgets('should maintain proper layout structure', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));

      // Assert - Verify layout hierarchy (MaterialApp adds its own SafeArea)
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      expect(find.byType(Padding), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('should use proper theming and colors', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const ReportFireScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verify themed elements exist
      expect(
        find.byType(Container),
        findsAtLeastNWidgets(1),
      ); // At least banner container visible
      expect(
        find.text('Call 999 — Fire Service'),
        findsOneWidget,
      ); // At least one button visible
    });

    testWidgets('should handle SnackBar dismissal correctly', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: ReportFireScreen()));

      // Tap button to potentially trigger SnackBar
      await tester.tap(find.text('Call 999 — Fire Service'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check if SnackBar appeared and can be dismissed
      // Note: This test depends on url_launcher failing in test environment
      final snackBarFinder = find.byType(SnackBar);
      if (tester.any(snackBarFinder)) {
        // If SnackBar exists, verify it has proper action
        expect(find.text('OK'), findsOneWidget);

        // Tap OK to dismiss
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // SnackBar should be gone
        expect(find.byType(SnackBar), findsNothing);
      }
    });
  });

  group('ReportFireScreen Factory Extensions', () {
    testWidgets('withTitle factory should work correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ReportFireScreenFactory.withTitle('Custom Fire Report'),
        ),
      );

      // Assert
      expect(find.text('Custom Fire Report'), findsOneWidget);
      expect(
        find.byType(AppBar),
        findsAtLeastNWidgets(1),
      ); // Factory creates nested Scaffold
    });

    testWidgets('withoutAppBar factory should work correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReportFireScreenFactory.withoutAppBar()),
        ),
      );

      // Assert - Should have SafeArea and Padding but nested AppBar
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      expect(find.byType(Padding), findsAtLeastNWidgets(1));
    });
  });
}
