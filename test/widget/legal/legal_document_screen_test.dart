import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/content/legal_content.dart';
import 'package:wildfire_mvp_v3/screens/legal_document_screen.dart';

void main() {
  group('LegalDocumentScreen', () {
    testWidgets('displays document title in AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.termsOfService,
          ),
        ),
      );

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('displays version and effective date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.termsOfService,
          ),
        ),
      );

      // Look for the specific version info container text
      expect(find.text('Version 1.0 • Effective 10 December 2025'),
          findsOneWidget);
    });

    testWidgets('displays document content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.termsOfService,
          ),
        ),
      );

      // Check that key content sections appear (may appear in TOC and content)
      expect(find.textContaining('Introduction'), findsAtLeastNWidgets(1));
    });

    testWidgets('content is scrollable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.termsOfService,
          ),
        ),
      );

      // Find the scrollable
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);
    });

    testWidgets('has AppBar with back navigation capability', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.termsOfService,
          ),
        ),
      );

      // AppBar is present and allows navigation
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders all legal documents', (tester) async {
      for (final doc in LegalContent.allDocuments) {
        await tester.pumpWidget(
          MaterialApp(
            home: LegalDocumentScreen(document: doc),
          ),
        );

        expect(find.text(doc.title), findsOneWidget);
        expect(find.textContaining('Version ${doc.version}'), findsOneWidget);
      }
    });

    testWidgets('privacy policy displays correct content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.privacyPolicy,
          ),
        ),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
      // UK GDPR appears multiple times in the content (in different sections)
      expect(find.textContaining('UK GDPR'), findsAtLeastNWidgets(1));
    });

    testWidgets('disclaimer displays emergency guidance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.emergencyDisclaimer,
          ),
        ),
      );

      expect(find.text('Emergency & Accuracy Disclaimer'), findsOneWidget);
      // 999 may appear multiple times in emergency guidance content
      expect(find.textContaining('999'), findsAtLeastNWidgets(1));
    });

    testWidgets('data sources displays attribution', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.dataSources,
          ),
        ),
      );

      expect(find.text('Data Sources & Attribution'), findsOneWidget);
      // EFFIS may appear multiple times in the content
      expect(find.textContaining('EFFIS'), findsAtLeastNWidgets(1));
    });

    testWidgets('content is selectable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: LegalContent.termsOfService,
          ),
        ),
      );

      // Content is rendered in multiple sections, each with SelectableText
      expect(find.byType(SelectableText), findsAtLeastNWidgets(1));
    });
  });
}
