import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';
import 'package:wildfire_mvp_v3/screens/about_screen.dart';
import 'package:wildfire_mvp_v3/screens/legal_document_screen.dart';

void main() {
  group('AboutScreen', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/about',
        routes: [
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
            routes: [
              GoRoute(
                path: 'terms',
                builder: (context, state) => LegalDocumentScreen(
                  document: LegalContent.termsOfService,
                ),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => LegalDocumentScreen(
                  document: LegalContent.privacyPolicy,
                ),
              ),
              GoRoute(
                path: 'disclaimer',
                builder: (context, state) => LegalDocumentScreen(
                  document: LegalContent.emergencyDisclaimer,
                ),
              ),
              GoRoute(
                path: 'data-sources',
                builder: (context, state) => LegalDocumentScreen(
                  document: LegalContent.dataSources,
                ),
              ),
            ],
          ),
        ],
      );
    });

    Widget buildApp() {
      return MaterialApp.router(
        routerConfig: router,
      );
    }

    testWidgets('displays About title in AppBar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays app name and description', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('WildFire'), findsOneWidget);
      expect(find.text('Scottish Wildfire Tracker'), findsOneWidget);
    });

    testWidgets('displays version number', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('displays all legal document links', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Emergency & Accuracy Disclaimer'), findsOneWidget);
      expect(find.text('Data Sources & Attribution'), findsOneWidget);
    });

    testWidgets('displays legal section header', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Legal'), findsOneWidget);
    });

    testWidgets('displays emergency disclaimer footer', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll down to see the footer
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.textContaining('999'), findsOneWidget);
      expect(find.textContaining('emergency'), findsOneWidget);
    });

    testWidgets('tapping Terms navigates to terms screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      // Use findsWidgets because SelectableText creates multiple text instances
      expect(find.textContaining('Introduction'), findsWidgets);
    });

    testWidgets('tapping Privacy navigates to privacy screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      // Use findsWidgets because SelectableText creates multiple text instances
      expect(find.textContaining('UK GDPR'), findsWidgets);
    });

    testWidgets('tapping Disclaimer navigates to disclaimer screen',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emergency & Accuracy Disclaimer'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      // Use findsWidgets because SelectableText creates multiple text instances
      // Look for content that appears in disclaimer
      expect(find.textContaining('Emergency Guidance'), findsWidgets);
    });

    testWidgets('tapping Data Sources navigates to data sources screen',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data Sources & Attribution'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      // Use findsWidgets because SelectableText creates multiple text instances
      expect(find.textContaining('EFFIS'), findsWidgets);
    });

    testWidgets('displays content version', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll down to see the version info
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Content v${LegalContent.contentVersion}'),
        findsOneWidget,
      );
    });

    testWidgets('all list tiles have chevron icons', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // There should be 4 chevron icons (one per legal document)
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    });
  });
}
