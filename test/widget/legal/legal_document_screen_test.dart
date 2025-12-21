import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';
import 'package:wildfire_mvp_v3/screens/legal_document_screen.dart';

void main() {
  group('LegalDocumentScreen', () {
    testWidgets('displays document title in AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.termsOfService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('displays version and effective date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.termsOfService),
        ),
      );
      await tester.pumpAndSettle();

      // Look for the specific version info container text
      expect(
        find.text('Version 1.0 • Effective 10 December 2025'),
        findsOneWidget,
      );
    });

    testWidgets('displays document content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.termsOfService),
        ),
      );
      await tester.pumpAndSettle();

      // Check that key content sections appear
      expect(find.textContaining('Introduction'), findsWidgets);
    });

    testWidgets('content is scrollable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.termsOfService),
        ),
      );
      await tester.pumpAndSettle();

      // Find the scrollable
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);
    });

    testWidgets('has AppBar with back navigation capability', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.termsOfService),
        ),
      );
      await tester.pumpAndSettle();

      // AppBar is present and allows navigation
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders all legal documents', (tester) async {
      for (final doc in LegalContent.allDocuments) {
        await tester.pumpWidget(
          MaterialApp(home: LegalDocumentScreen(document: doc)),
        );
        await tester.pumpAndSettle();

        expect(find.text(doc.title), findsOneWidget);
        expect(find.textContaining('Version ${doc.version}'), findsOneWidget);
      }
    });

    testWidgets('privacy policy displays correct content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.privacyPolicy),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.textContaining('UK GDPR'), findsWidgets);
    });

    testWidgets('disclaimer displays emergency guidance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.emergencyDisclaimer),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency & Accuracy Disclaimer'), findsOneWidget);
      expect(find.textContaining('999'), findsWidgets);
    });

    testWidgets('data sources displays attribution', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.dataSources),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Sources & Attribution'), findsOneWidget);
      expect(find.textContaining('EFFIS'), findsWidgets);
      expect(find.text('Contents'), findsOneWidget);
    });

    testWidgets('content is selectable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.termsOfService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsWidgets);
    });

    testWidgets('table of contents renders and toggles for rich documents', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(document: LegalContent.termsOfService),
        ),
      );
      await tester.pumpAndSettle();

      // Contents panel renders collapsed by default
      final toggle = find.text('Contents');
      expect(toggle, findsOneWidget);
      var crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);

      // Expand TOC
      await tester.tap(toggle);
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);

      // Entries appear with indentation for subsections
      final entry = find.descendant(
        of: find.byType(AnimatedCrossFade),
        matching: find.text('2. Purpose of the App'),
      );
      expect(entry, findsOneWidget);

      // Tapping an entry collapses panel again
      await tester.tap(entry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);
    });
  });
}
