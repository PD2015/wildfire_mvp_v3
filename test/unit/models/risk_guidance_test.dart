import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/risk_guidance.dart';

/// Unit tests for RiskGuidance model
///
/// Validates:
/// - Model creation with required fields only
/// - Model creation with all optional fields
/// - Equatable props comparison
/// - toString output
void main() {
  group('RiskGuidance', () {
    test('creates instance with required fields only', () {
      const guidance = RiskGuidance(
        title: 'Test Title',
        summary: 'Test summary',
        bulletPoints: ['Point 1', 'Point 2'],
      );

      expect(guidance.title, equals('Test Title'));
      expect(guidance.summary, equals('Test summary'));
      expect(guidance.bulletPoints, hasLength(2));
      expect(guidance.helpLinkLabel, isNull);
      expect(guidance.helpRoute, isNull);
      expect(guidance.disclaimer, isNull);
    });

    test('creates instance with all optional fields', () {
      const guidance = RiskGuidance(
        title: 'Test Title',
        summary: 'Test summary',
        bulletPoints: ['Point 1'],
        helpLinkLabel: 'Learn more',
        helpRoute: '/help/test',
        disclaimer: 'Test disclaimer',
      );

      expect(guidance.title, equals('Test Title'));
      expect(guidance.summary, equals('Test summary'));
      expect(guidance.bulletPoints, equals(['Point 1']));
      expect(guidance.helpLinkLabel, equals('Learn more'));
      expect(guidance.helpRoute, equals('/help/test'));
      expect(guidance.disclaimer, equals('Test disclaimer'));
    });

    test('supports const constructor', () {
      // This should compile without errors
      const guidance1 = RiskGuidance(
        title: 'Title',
        summary: 'Summary',
        bulletPoints: ['Point'],
      );

      const guidance2 = RiskGuidance(
        title: 'Title',
        summary: 'Summary',
        bulletPoints: ['Point'],
        helpRoute: '/help',
        disclaimer: 'Disclaimer',
      );

      expect(guidance1, isNotNull);
      expect(guidance2, isNotNull);
    });

    group('Equatable', () {
      test('instances with same required values are equal', () {
        const guidance1 = RiskGuidance(
          title: 'Same Title',
          summary: 'Same summary',
          bulletPoints: ['Same point'],
        );

        const guidance2 = RiskGuidance(
          title: 'Same Title',
          summary: 'Same summary',
          bulletPoints: ['Same point'],
        );

        expect(guidance1, equals(guidance2));
        expect(guidance1.hashCode, equals(guidance2.hashCode));
      });

      test('instances with same all values are equal', () {
        const guidance1 = RiskGuidance(
          title: 'Same Title',
          summary: 'Same summary',
          bulletPoints: ['Same point'],
          helpLinkLabel: 'Same label',
          helpRoute: '/same/route',
          disclaimer: 'Same disclaimer',
        );

        const guidance2 = RiskGuidance(
          title: 'Same Title',
          summary: 'Same summary',
          bulletPoints: ['Same point'],
          helpLinkLabel: 'Same label',
          helpRoute: '/same/route',
          disclaimer: 'Same disclaimer',
        );

        expect(guidance1, equals(guidance2));
      });

      test('instances with different titles are not equal', () {
        const guidance1 = RiskGuidance(
          title: 'Title A',
          summary: 'Summary',
          bulletPoints: ['Point'],
        );

        const guidance2 = RiskGuidance(
          title: 'Title B',
          summary: 'Summary',
          bulletPoints: ['Point'],
        );

        expect(guidance1, isNot(equals(guidance2)));
      });

      test('instances with different helpRoutes are not equal', () {
        const guidance1 = RiskGuidance(
          title: 'Title',
          summary: 'Summary',
          bulletPoints: ['Point'],
          helpRoute: '/route/a',
        );

        const guidance2 = RiskGuidance(
          title: 'Title',
          summary: 'Summary',
          bulletPoints: ['Point'],
          helpRoute: '/route/b',
        );

        expect(guidance1, isNot(equals(guidance2)));
      });

      test('instance with null helpRoute differs from non-null', () {
        const guidance1 = RiskGuidance(
          title: 'Title',
          summary: 'Summary',
          bulletPoints: ['Point'],
        );

        const guidance2 = RiskGuidance(
          title: 'Title',
          summary: 'Summary',
          bulletPoints: ['Point'],
          helpRoute: '/help',
        );

        expect(guidance1, isNot(equals(guidance2)));
      });
    });

    group('toString', () {
      test('includes title and summary', () {
        const guidance = RiskGuidance(
          title: 'Test Title',
          summary: 'Test summary',
          bulletPoints: ['Point 1', 'Point 2'],
        );

        final str = guidance.toString();
        expect(str, contains('Test Title'));
        expect(str, contains('Test summary'));
        expect(str, contains('2 items'));
      });

      test('includes helpRoute when provided', () {
        const guidance = RiskGuidance(
          title: 'Title',
          summary: 'Summary',
          bulletPoints: ['Point'],
          helpRoute: '/help/test',
        );

        final str = guidance.toString();
        expect(str, contains('/help/test'));
      });

      test('indicates disclaimer presence', () {
        const guidanceWithDisclaimer = RiskGuidance(
          title: 'Title',
          summary: 'Summary',
          bulletPoints: ['Point'],
          disclaimer: 'Test disclaimer',
        );

        const guidanceWithoutDisclaimer = RiskGuidance(
          title: 'Title',
          summary: 'Summary',
          bulletPoints: ['Point'],
        );

        expect(guidanceWithDisclaimer.toString(), contains('disclaimer: true'));
        expect(
          guidanceWithoutDisclaimer.toString(),
          contains('disclaimer: false'),
        );
      });
    });
  });
}
