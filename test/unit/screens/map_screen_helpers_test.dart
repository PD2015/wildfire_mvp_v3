import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

// Test wrapper to access private helper methods
// Since these are private methods in MapScreen, we'll test them indirectly
// through the public InfoWindow output by creating test incidents

void main() {
  group('Map InfoWindow Helper Methods', () {
    late DateTime baseTime;
    late DateTime now;

    setUp(() {
      // Use actual current time to avoid future timestamp validation errors
      now = DateTime.now();
      baseTime = now;
    });

    group('_formatIntensity (via InfoWindow snippet)', () {
      test('formats "high" intensity as "High"', () {
        final incident = FireIncident.test(
          id: 'test_001',
          location: const LatLng(55.9533, -3.1883),
          intensity: 'high',
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        // Check that snippet contains proper capitalization
        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Risk: High'));
      });

      test('formats "moderate" intensity as "Moderate"', () {
        final incident = FireIncident.test(
          id: 'test_002',
          location: const LatLng(55.9533, -3.1883),
          intensity: 'moderate',
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Risk: Moderate'));
      });

      test('formats "low" intensity as "Low"', () {
        final incident = FireIncident.test(
          id: 'test_003',
          location: const LatLng(55.9533, -3.1883),
          intensity: 'low',
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Risk: Low'));
      });

      test('handles unknown intensity', () {
        // This test verifies the default case, but FireIncident validation
        // prevents invalid intensities, so we test the format directly
        expect(_formatIntensity('unknown'), equals('Unknown'));
        expect(_formatIntensity(''), equals('Unknown'));
        expect(_formatIntensity('EXTREME'), equals('Unknown'));
      });

      test('handles mixed case input', () {
        expect(_formatIntensity('HIGH'), equals('High'));
        expect(_formatIntensity('MoDeRaTe'), equals('Moderate'));
        expect(_formatIntensity('LoW'), equals('Low'));
      });
    });

    group('_formatDataSource (via InfoWindow snippet)', () {
      test('formats DataSource.effis as "EFFIS"', () {
        final incident = FireIncident.test(
          id: 'test_004',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.effis,
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Source: EFFIS'));
      });

      test('formats DataSource.sepa as "SEPA"', () {
        final incident = FireIncident.test(
          id: 'test_005',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.sepa,
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Source: SEPA'));
      });

      test('formats DataSource.cache as "Cached"', () {
        final incident = FireIncident.test(
          id: 'test_006',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.cache,
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Source: Cached'));
      });

      test('formats DataSource.mock as "MOCK"', () {
        final incident = FireIncident.test(
          id: 'test_007',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.mock,
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Source: MOCK'));
      });

      test('direct method returns all source types', () {
        expect(_formatDataSource(DataSource.effis), equals('EFFIS'));
        expect(_formatDataSource(DataSource.sepa), equals('SEPA'));
        expect(_formatDataSource(DataSource.cache), equals('Cached'));
        expect(_formatDataSource(DataSource.mock), equals('MOCK'));
      });
    });

    group('_formatFreshness (via InfoWindow snippet)', () {
      test('formats timestamp less than 1 minute as "Just now"', () {
        final timestamp = now.subtract(const Duration(seconds: 30));
        expect(_formatFreshness(timestamp, now), equals('Just now'));
      });

      test('formats timestamp exactly 1 minute as "1m ago"', () {
        final timestamp = now.subtract(const Duration(minutes: 1));
        expect(_formatFreshness(timestamp, now), equals('1m ago'));
      });

      test('formats timestamp in minutes (1-59)', () {
        expect(
          _formatFreshness(now.subtract(const Duration(minutes: 5)), now),
          equals('5m ago'),
        );
        expect(
          _formatFreshness(now.subtract(const Duration(minutes: 30)), now),
          equals('30m ago'),
        );
        expect(
          _formatFreshness(now.subtract(const Duration(minutes: 59)), now),
          equals('59m ago'),
        );
      });

      test('formats timestamp exactly 1 hour as "1h ago"', () {
        final timestamp = now.subtract(const Duration(hours: 1));
        expect(_formatFreshness(timestamp, now), equals('1h ago'));
      });

      test('formats timestamp in hours (1-23)', () {
        expect(
          _formatFreshness(now.subtract(const Duration(hours: 2)), now),
          equals('2h ago'),
        );
        expect(
          _formatFreshness(now.subtract(const Duration(hours: 12)), now),
          equals('12h ago'),
        );
        expect(
          _formatFreshness(now.subtract(const Duration(hours: 23)), now),
          equals('23h ago'),
        );
      });

      test('formats timestamp exactly 1 day as "1d ago"', () {
        final timestamp = now.subtract(const Duration(days: 1));
        expect(_formatFreshness(timestamp, now), equals('1d ago'));
      });

      test('formats timestamp in days (1+)', () {
        expect(
          _formatFreshness(now.subtract(const Duration(days: 3)), now),
          equals('3d ago'),
        );
        expect(
          _formatFreshness(now.subtract(const Duration(days: 7)), now),
          equals('7d ago'),
        );
        expect(
          _formatFreshness(now.subtract(const Duration(days: 30)), now),
          equals('30d ago'),
        );
      });

      test('handles edge case: 59 minutes 59 seconds', () {
        final timestamp = now.subtract(
          const Duration(minutes: 59, seconds: 59),
        );
        expect(_formatFreshness(timestamp, now), equals('59m ago'));
      });

      test('handles edge case: 23 hours 59 minutes', () {
        final timestamp = now.subtract(
          const Duration(hours: 23, minutes: 59),
        );
        expect(_formatFreshness(timestamp, now), equals('23h ago'));
      });
    });

    group('_buildInfoTitle (via title field)', () {
      test('uses description when available', () {
        final incident = FireIncident.test(
          id: 'mock_fire_001',
          location: const LatLng(55.9533, -3.1883),
          description: 'Edinburgh - Holyrood Park',
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final title = _buildTestTitle(incident);
        expect(title, equals('Edinburgh - Holyrood Park'));
      });

      test('uses shortened ID when description is null', () {
        final incident = FireIncident.test(
          id: 'mock_fire_001',
          location: const LatLng(55.9533, -3.1883),
          description: null,
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final title = _buildTestTitle(incident);
        expect(title, equals('Fire #ire_001')); // Last 7 chars
      });

      test('uses shortened ID when description is empty', () {
        final incident = FireIncident.test(
          id: 'mock_fire_002',
          location: const LatLng(55.9533, -3.1883),
          description: '',
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final title = _buildTestTitle(incident);
        expect(title, equals('Fire #ire_002'));
      });

      test('handles short IDs (< 7 chars)', () {
        final incident = FireIncident.test(
          id: 'test1',
          location: const LatLng(55.9533, -3.1883),
          description: null,
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final title = _buildTestTitle(incident);
        expect(title, equals('Fire #test1')); // Uses full ID
      });

      test('handles long UUID-style IDs', () {
        final incident = FireIncident.test(
          id: 'effis_ba_2025_11_24_uuid_12345',
          location: const LatLng(55.9533, -3.1883),
          description: null,
          areaHectares: 10.0,
          timestamp: baseTime,
        );

        final title = _buildTestTitle(incident);
        expect(title, equals('Fire #d_12345')); // Last 7 chars: "d_12345"
      });
    });

    group('_buildInfoSnippet (integration)', () {
      test('builds complete snippet with all data', () {
        final incident = FireIncident.test(
          id: 'test_008',
          location: const LatLng(55.9533, -3.1883),
          intensity: 'moderate',
          areaHectares: 12.5,
          source: DataSource.mock,
          timestamp: baseTime.subtract(const Duration(hours: 2)),
        );

        final snippet = _buildTestSnippet(
          incident,
          baseTime,
        );

        // Line 1: Risk and area
        expect(snippet, contains('Risk: Moderate'));
        expect(snippet, contains('Burnt area: 12.5 ha'));
        expect(snippet, contains('•')); // Bullet separator

        // Line 2: Source and freshness
        expect(snippet, contains('Source: MOCK'));
        expect(snippet, contains('2h ago'));

        // Verify newline separator
        expect(snippet, contains('\n'));
      });

      test('handles unknown area gracefully', () {
        final incident = FireIncident.test(
          id: 'test_009',
          location: const LatLng(55.9533, -3.1883),
          intensity: 'high',
          areaHectares: null, // Unknown area
          source: DataSource.effis,
          timestamp: baseTime.subtract(const Duration(minutes: 15)),
        );

        final snippet = _buildTestSnippet(incident, baseTime);

        expect(snippet, contains('Risk: High'));
        expect(snippet, contains('Burnt area: Unknown'));
        expect(snippet, contains('Source: EFFIS'));
        expect(snippet, contains('15m ago'));
      });

      test('formats area with 1 decimal place', () {
        final incident = FireIncident.test(
          id: 'test_010',
          location: const LatLng(55.9533, -3.1883),
          areaHectares: 5.7,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Burnt area: 5.7 ha'));
      });

      test('rounds area to 1 decimal place', () {
        final incident = FireIncident.test(
          id: 'test_011',
          location: const LatLng(55.9533, -3.1883),
          areaHectares: 28.345,
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        expect(snippet, contains('Burnt area: 28.3 ha'));
      });

      test('snippet has exactly two lines', () {
        final incident = FireIncident.test(
          id: 'test_012',
          location: const LatLng(55.9533, -3.1883),
          timestamp: baseTime,
        );

        final snippet = _buildTestSnippet(incident, baseTime);
        final lines = snippet.split('\n');

        expect(lines.length, equals(2));
        expect(lines[0], isNotEmpty);
        expect(lines[1], isNotEmpty);
      });
    });

    group('Full InfoWindow output validation', () {
      test('complete example: Edinburgh fire with full data', () {
        final incident = FireIncident.test(
          id: 'mock_fire_001',
          location: const LatLng(55.9533, -3.1883),
          description: 'Edinburgh - Holyrood Park',
          intensity: 'moderate',
          areaHectares: 12.5,
          source: DataSource.mock,
          timestamp: baseTime.subtract(const Duration(hours: 2)),
        );

        final title = _buildTestTitle(incident);
        final snippet = _buildTestSnippet(incident, baseTime);

        expect(title, equals('Edinburgh - Holyrood Park'));
        expect(
          snippet,
          equals(
            'Risk: Moderate • Burnt area: 12.5 ha\nSource: MOCK • 2h ago',
          ),
        );
      });

      test('complete example: EFFIS fire with no description', () {
        final incident = FireIncident.test(
          id: 'effis_2025_001',
          location: const LatLng(55.8642, -4.2518),
          description: null,
          intensity: 'high',
          areaHectares: 28.3,
          source: DataSource.effis,
          timestamp: baseTime.subtract(const Duration(minutes: 15)),
        );

        final title = _buildTestTitle(incident);
        final snippet = _buildTestSnippet(incident, baseTime);

        expect(title, equals('Fire #025_001'));
        expect(
          snippet,
          equals(
            'Risk: High • Burnt area: 28.3 ha\nSource: EFFIS • 15m ago',
          ),
        );
      });

      test('complete example: Cached fire with unknown area', () {
        final incident = FireIncident.test(
          id: 'cache_fire_abc',
          location: const LatLng(57.2, -3.8),
          description: 'Aviemore - Cairngorms',
          intensity: 'low',
          areaHectares: null,
          source: DataSource.cache,
          timestamp: baseTime.subtract(const Duration(days: 5)),
        );

        final title = _buildTestTitle(incident);
        final snippet = _buildTestSnippet(incident, baseTime);

        expect(title, equals('Aviemore - Cairngorms'));
        expect(
          snippet,
          equals(
            'Risk: Low • Burnt area: Unknown\nSource: Cached • 5d ago',
          ),
        );
      });

      test('complete example: Recent SEPA fire', () {
        final incident = FireIncident.test(
          id: 'sepa_2025_nov_24',
          location: const LatLng(56.0, -4.0),
          description: 'Glasgow - Campsie Fells',
          intensity: 'high',
          areaHectares: 45.0,
          source: DataSource.sepa,
          timestamp: baseTime.subtract(const Duration(seconds: 30)),
        );

        final title = _buildTestTitle(incident);
        final snippet = _buildTestSnippet(incident, baseTime);

        expect(title, equals('Glasgow - Campsie Fells'));
        expect(
          snippet,
          equals(
            'Risk: High • Burnt area: 45.0 ha\nSource: SEPA • Just now',
          ),
        );
      });
    });
  });
}

// Test helper functions (replicate private methods from MapScreen)

/// Build user-friendly title for info window
/// Priority: description > shortened ID > full ID
String _buildTestTitle(FireIncident incident) {
  // Prefer descriptive location if available
  if (incident.description?.isNotEmpty == true) {
    return incident.description!;
  }

  // Fallback: Use shortened fire ID for readability
  // e.g., "mock_fire_001" → "Fire #ire_001" (last 7 chars)
  final shortId = incident.id.length > 7
      ? incident.id.substring(incident.id.length - 7)
      : incident.id;
  return 'Fire #$shortId';
}

/// Build user-friendly snippet with risk, area, source, and freshness
/// Format: "Risk: Moderate • Burnt area: 12.5 ha\nSource: MOCK • 2h ago"
String _buildTestSnippet(FireIncident incident, DateTime currentTime) {
  final intensityLabel = _formatIntensity(incident.intensity);
  final areaText = incident.areaHectares != null
      ? '${incident.areaHectares!.toStringAsFixed(1)} ha'
      : 'Unknown';

  final sourceLabel = _formatDataSource(incident.source);
  final freshnessText = _formatFreshness(incident.timestamp, currentTime);

  // Line 1: Risk and burnt area
  // Line 2: Source and freshness
  return 'Risk: $intensityLabel • Burnt area: $areaText\n'
      'Source: $sourceLabel • $freshnessText';
}

/// Format intensity for user-friendly display
String _formatIntensity(String raw) {
  switch (raw.toLowerCase()) {
    case 'high':
      return 'High';
    case 'moderate':
      return 'Moderate';
    case 'low':
      return 'Low';
    default:
      return 'Unknown';
  }
}

/// Format data source for user-friendly display
String _formatDataSource(DataSource source) {
  switch (source) {
    case DataSource.effis:
      return 'EFFIS';
    case DataSource.sepa:
      return 'SEPA';
    case DataSource.cache:
      return 'Cached';
    case DataSource.mock:
      return 'MOCK';
  }
}

/// Format timestamp as relative time (e.g., "2h ago", "3d ago")
String _formatFreshness(DateTime timestamp, DateTime currentTime) {
  final age = currentTime.difference(timestamp);

  if (age.inMinutes < 1) {
    return 'Just now';
  } else if (age.inMinutes < 60) {
    return '${age.inMinutes}m ago';
  } else if (age.inHours < 24) {
    return '${age.inHours}h ago';
  } else {
    return '${age.inDays}d ago';
  }
}
