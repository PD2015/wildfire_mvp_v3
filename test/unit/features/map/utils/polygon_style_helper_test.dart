import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

void main() {
  group('PolygonStyleHelper', () {
    // Note: All burnt areas now use a single red color (RiskPalette.veryHigh)
    // for visual clarity. Intensity-based coloring was removed in the refactor.

    group('burntAreaStrokeColor', () {
      test('returns veryHigh red color', () {
        expect(
          PolygonStyleHelper.burntAreaStrokeColor,
          equals(RiskPalette.veryHigh),
        );
      });
    });

    group('getStrokeColor (deprecated)', () {
      test('returns veryHigh color for any intensity', () {
        // All intensities now return the same red color
        expect(
          PolygonStyleHelper.getStrokeColor('high'),
          equals(RiskPalette.veryHigh),
        );
        expect(
          PolygonStyleHelper.getStrokeColor('moderate'),
          equals(RiskPalette.veryHigh),
        );
        expect(
          PolygonStyleHelper.getStrokeColor('low'),
          equals(RiskPalette.veryHigh),
        );
        expect(
          PolygonStyleHelper.getStrokeColor('unknown'),
          equals(RiskPalette.veryHigh),
        );
      });
    });

    group('burntAreaFillColor', () {
      test('returns semi-transparent veryHigh red color', () {
        final color = PolygonStyleHelper.burntAreaFillColor;
        expect(color.r, equals(RiskPalette.veryHigh.r));
        expect(color.g, equals(RiskPalette.veryHigh.g));
        expect(color.b, equals(RiskPalette.veryHigh.b));
        expect(color.a, closeTo(PolygonStyleHelper.fillOpacity, 0.01));
      });
    });

    group('getFillColor (deprecated)', () {
      test('returns semi-transparent veryHigh color for any intensity', () {
        // All intensities now return the same red fill color
        for (final intensity in ['high', 'moderate', 'low', 'unknown']) {
          final color = PolygonStyleHelper.getFillColor(intensity);
          expect(color.r, equals(RiskPalette.veryHigh.r));
          expect(color.g, equals(RiskPalette.veryHigh.g));
          expect(color.b, equals(RiskPalette.veryHigh.b));
          expect(color.a, closeTo(PolygonStyleHelper.fillOpacity, 0.01));
        }
      });

      test('fill opacity is 35%', () {
        expect(PolygonStyleHelper.fillOpacity, equals(0.35));
      });
    });

    group('shouldShowPolygonsAtZoom', () {
      test('returns false for zoom level below threshold', () {
        expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(7.0), isFalse);
        expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(5.0), isFalse);
        expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(0.0), isFalse);
      });

      test('returns true for zoom level at threshold', () {
        expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(8.0), isTrue);
      });

      test('returns true for zoom level above threshold', () {
        expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(9.0), isTrue);
        expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(12.0), isTrue);
        expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(20.0), isTrue);
      });

      test('minimum zoom for polygons is 8.0', () {
        expect(PolygonStyleHelper.minZoomForPolygons, equals(8.0));
      });
    });

    group('strokeWidth', () {
      test('has reasonable default value', () {
        expect(PolygonStyleHelper.strokeWidth, equals(2));
      });
    });
  });
}
