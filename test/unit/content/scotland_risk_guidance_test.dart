import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/content/scotland_risk_guidance.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

/// Unit tests for Scotland-specific wildfire risk guidance content
///
/// Validates that guidance content:
/// - Exists for all 6 risk levels
/// - Contains non-empty titles, summaries, and bullet points
/// - Has emergency footer for all levels
/// - Provides fallback for null risk level
void main() {
  group('ScotlandRiskGuidance', () {
    group('guidanceByLevel map', () {
      test('contains all 6 risk levels', () {
        expect(ScotlandRiskGuidance.guidanceByLevel.length, equals(6));
        expect(
          ScotlandRiskGuidance.guidanceByLevel.keys,
          containsAll(RiskLevel.values),
        );
      });

      test('veryLow guidance has valid content', () {
        final guidance =
            ScotlandRiskGuidance.guidanceByLevel[RiskLevel.veryLow]!;

        expect(guidance.title, isNotEmpty);
        expect(guidance.summary, isNotEmpty);
        expect(guidance.bulletPoints.length, greaterThanOrEqualTo(3));
        expect(guidance.bulletPoints.every((p) => p.isNotEmpty), isTrue);
      });

      test('low guidance has valid content', () {
        final guidance = ScotlandRiskGuidance.guidanceByLevel[RiskLevel.low]!;

        expect(guidance.title, isNotEmpty);
        expect(guidance.summary, isNotEmpty);
        expect(guidance.bulletPoints.length, greaterThanOrEqualTo(3));
        expect(guidance.bulletPoints.every((p) => p.isNotEmpty), isTrue);
      });

      test('moderate guidance has valid content', () {
        final guidance =
            ScotlandRiskGuidance.guidanceByLevel[RiskLevel.moderate]!;

        expect(guidance.title, isNotEmpty);
        expect(guidance.summary, isNotEmpty);
        expect(guidance.bulletPoints.length, greaterThanOrEqualTo(3));
        expect(guidance.bulletPoints.every((p) => p.isNotEmpty), isTrue);
      });

      test('high guidance has valid content', () {
        final guidance = ScotlandRiskGuidance.guidanceByLevel[RiskLevel.high]!;

        expect(guidance.title, isNotEmpty);
        expect(guidance.summary, isNotEmpty);
        expect(guidance.bulletPoints.length, greaterThanOrEqualTo(3));
        expect(guidance.bulletPoints.every((p) => p.isNotEmpty), isTrue);
      });

      test('veryHigh guidance has valid content', () {
        final guidance =
            ScotlandRiskGuidance.guidanceByLevel[RiskLevel.veryHigh]!;

        expect(guidance.title, isNotEmpty);
        expect(guidance.summary, isNotEmpty);
        expect(guidance.bulletPoints.length, greaterThanOrEqualTo(3));
        expect(guidance.bulletPoints.every((p) => p.isNotEmpty), isTrue);
      });

      test('extreme guidance has valid content', () {
        final guidance =
            ScotlandRiskGuidance.guidanceByLevel[RiskLevel.extreme]!;

        expect(guidance.title, isNotEmpty);
        expect(guidance.summary, isNotEmpty);
        expect(guidance.bulletPoints.length, greaterThanOrEqualTo(3));
        expect(guidance.bulletPoints.every((p) => p.isNotEmpty), isTrue);
      });

      test('all guidance includes fire-related keywords', () {
        // Verify guidance is actually about wildfires, not placeholder text
        for (final entry in ScotlandRiskGuidance.guidanceByLevel.entries) {
          final guidance = entry.value;
          final allText =
              '${guidance.title} ${guidance.summary} ${guidance.bulletPoints.join(' ')}';
          final lowerText = allText.toLowerCase();

          // At least one fire-related term should appear
          expect(
            lowerText.contains('fire') ||
                lowerText.contains('bbq') ||
                lowerText.contains('burn') ||
                lowerText.contains('flame') ||
                lowerText.contains('spark'),
            isTrue,
            reason: 'Guidance for ${entry.key.name} should mention fire safety',
          );
        }
      });
    });

    group('genericGuidance fallback', () {
      test('has valid content', () {
        const guidance = ScotlandRiskGuidance.genericGuidance;

        expect(guidance.title, isNotEmpty);
        expect(guidance.summary, isNotEmpty);
        expect(guidance.bulletPoints.length, greaterThanOrEqualTo(3));
        expect(guidance.bulletPoints.every((p) => p.isNotEmpty), isTrue);
      });

      test('indicates unknown risk level in title or summary', () {
        const guidance = ScotlandRiskGuidance.genericGuidance;
        final combined = '${guidance.title} ${guidance.summary}'.toLowerCase();

        // Should communicate that risk level is unavailable
        expect(
          combined.contains('unable') ||
              combined.contains('cannot') ||
              combined.contains('unavailable') ||
              combined.contains('unknown'),
          isTrue,
        );
      });
    });

    group('emergencyFooter', () {
      test('mentions reporting wildfires', () {
        expect(
          ScotlandRiskGuidance.emergencyFooter.toLowerCase(),
          contains('report'),
        );
      });

      test('mentions fire or wildfire', () {
        expect(
          ScotlandRiskGuidance.emergencyFooter.toLowerCase(),
          contains('fire'),
        );
      });

      test('is non-empty', () {
        expect(ScotlandRiskGuidance.emergencyFooter, isNotEmpty);
      });
    });

    group('getGuidance() helper', () {
      test('returns correct guidance for veryLow', () {
        final guidance = ScotlandRiskGuidance.getGuidance(RiskLevel.veryLow);
        expect(
          guidance,
          equals(ScotlandRiskGuidance.guidanceByLevel[RiskLevel.veryLow]),
        );
      });

      test('returns correct guidance for low', () {
        final guidance = ScotlandRiskGuidance.getGuidance(RiskLevel.low);
        expect(
          guidance,
          equals(ScotlandRiskGuidance.guidanceByLevel[RiskLevel.low]),
        );
      });

      test('returns correct guidance for moderate', () {
        final guidance = ScotlandRiskGuidance.getGuidance(RiskLevel.moderate);
        expect(
          guidance,
          equals(ScotlandRiskGuidance.guidanceByLevel[RiskLevel.moderate]),
        );
      });

      test('returns correct guidance for high', () {
        final guidance = ScotlandRiskGuidance.getGuidance(RiskLevel.high);
        expect(
          guidance,
          equals(ScotlandRiskGuidance.guidanceByLevel[RiskLevel.high]),
        );
      });

      test('returns correct guidance for veryHigh', () {
        final guidance = ScotlandRiskGuidance.getGuidance(RiskLevel.veryHigh);
        expect(
          guidance,
          equals(ScotlandRiskGuidance.guidanceByLevel[RiskLevel.veryHigh]),
        );
      });

      test('returns correct guidance for extreme', () {
        final guidance = ScotlandRiskGuidance.getGuidance(RiskLevel.extreme);
        expect(
          guidance,
          equals(ScotlandRiskGuidance.guidanceByLevel[RiskLevel.extreme]),
        );
      });

      test('returns genericGuidance for null risk level', () {
        final guidance = ScotlandRiskGuidance.getGuidance(null);
        expect(guidance, equals(ScotlandRiskGuidance.genericGuidance));
      });
    });

    group('content quality checks', () {
      test('all guidance titles are consistent format', () {
        // All level-specific guidance should have similar title format
        for (final entry in ScotlandRiskGuidance.guidanceByLevel.entries) {
          final title = entry.value.title;
          expect(title, isNotEmpty);
          expect(title.length, greaterThan(5)); // Not just "Title"
        }
      });

      test('all bullet points are properly formatted sentences', () {
        for (final entry in ScotlandRiskGuidance.guidanceByLevel.entries) {
          for (final point in entry.value.bulletPoints) {
            // Bullet points should be reasonably long (not single words)
            expect(
              point.length,
              greaterThan(10),
              reason:
                  'Bullet point for ${entry.key.name} seems too short: "$point"',
            );

            // Should end with punctuation
            expect(
              point.endsWith('.') || point.endsWith('!') || point.endsWith('?'),
              isTrue,
              reason:
                  'Bullet point for ${entry.key.name} should end with punctuation: "$point"',
            );
          }
        }
      });

      test('generic guidance bullet points are properly formatted', () {
        for (final point in ScotlandRiskGuidance.genericGuidance.bulletPoints) {
          expect(point.length, greaterThan(10));
          expect(
            point.endsWith('.') || point.endsWith('!') || point.endsWith('?'),
            isTrue,
          );
        }
      });
    });
  });
}
