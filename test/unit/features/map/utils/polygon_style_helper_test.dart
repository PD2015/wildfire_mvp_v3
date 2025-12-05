import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

void main() {
  group('PolygonStyleHelper', () {
    group('getStrokeColor', () {
      test('returns veryHigh color for high intensity', () {
        final color = PolygonStyleHelper.getStrokeColor('high');
        expect(color, equals(RiskPalette.veryHigh));
      });

      test('returns high color for moderate intensity', () {
        final color = PolygonStyleHelper.getStrokeColor('moderate');
        expect(color, equals(RiskPalette.high));
      });

      test('returns low color for low intensity', () {
        final color = PolygonStyleHelper.getStrokeColor('low');
        expect(color, equals(RiskPalette.low));
      });

      test('returns midGray for unknown intensity', () {
        final color = PolygonStyleHelper.getStrokeColor('unknown');
        expect(color, equals(RiskPalette.midGray));
      });

      test('handles case-insensitive intensity', () {
        expect(PolygonStyleHelper.getStrokeColor('HIGH'),
            equals(RiskPalette.veryHigh));
        expect(PolygonStyleHelper.getStrokeColor('High'),
            equals(RiskPalette.veryHigh));
        expect(PolygonStyleHelper.getStrokeColor('high'),
            equals(RiskPalette.veryHigh));
      });
    });

    group('getFillColor', () {
      test('returns semi-transparent color for high intensity', () {
        final color = PolygonStyleHelper.getFillColor('high');
        expect(color.r, equals(RiskPalette.veryHigh.r));
        expect(color.g, equals(RiskPalette.veryHigh.g));
        expect(color.b, equals(RiskPalette.veryHigh.b));
        expect(color.a, closeTo(PolygonStyleHelper.fillOpacity, 0.01));
      });

      test('returns semi-transparent color for moderate intensity', () {
        final color = PolygonStyleHelper.getFillColor('moderate');
        expect(color.r, equals(RiskPalette.high.r));
        expect(color.g, equals(RiskPalette.high.g));
        expect(color.b, equals(RiskPalette.high.b));
        expect(color.a, closeTo(PolygonStyleHelper.fillOpacity, 0.01));
      });

      test('returns semi-transparent color for low intensity', () {
        final color = PolygonStyleHelper.getFillColor('low');
        expect(color.r, equals(RiskPalette.low.r));
        expect(color.g, equals(RiskPalette.low.g));
        expect(color.b, equals(RiskPalette.low.b));
        expect(color.a, closeTo(PolygonStyleHelper.fillOpacity, 0.01));
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
