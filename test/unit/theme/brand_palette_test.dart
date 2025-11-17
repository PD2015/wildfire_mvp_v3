import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

// Contrast calculation helper
double contrastRatio(Color c1, Color c2) {
  final l1 = c1.computeLuminance();
  final l2 = c2.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('BrandPalette Color Constants', () {
    test('all forest gradient colors are defined', () {
      expect(BrandPalette.forest900, isA<Color>());
      expect(BrandPalette.forest800, isA<Color>());
      expect(BrandPalette.forest700, isA<Color>());
      expect(BrandPalette.forest600, isA<Color>());
      expect(BrandPalette.forest500, isA<Color>());
      expect(BrandPalette.forest400, isA<Color>());
    });

    test('all accent colors are defined', () {
      expect(BrandPalette.neutralGrey100, isA<Color>());
      expect(BrandPalette.neutralGrey200, isA<Color>());
      expect(BrandPalette.mint400, isA<Color>());
      expect(BrandPalette.amber500, isA<Color>());
    });

    test('all on-colors are defined', () {
      expect(BrandPalette.onDarkHigh, isA<Color>());
      expect(BrandPalette.onDarkMedium, isA<Color>());
      expect(BrandPalette.offWhite, isA<Color>());
      expect(BrandPalette.onLightHigh, isA<Color>());
      expect(BrandPalette.onLightMedium, isA<Color>());
    });
  });

  group('BrandPalette WCAG AA Contrast Compliance', () {
    test('forest600 + onDarkHigh >= 4.5:1', () {
      final ratio =
          contrastRatio(BrandPalette.forest600, BrandPalette.onDarkHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Primary color must have AA contrast on white');
    });

    test('mint400 + onLightHigh >= 4.5:1', () {
      final ratio =
          contrastRatio(BrandPalette.mint400, BrandPalette.onLightHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Secondary color must have AA contrast on black');
    });

    test('amber500 + onLightHigh >= 4.5:1', () {
      final ratio =
          contrastRatio(BrandPalette.amber500, BrandPalette.onLightHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Tertiary color must have AA contrast on black');
    });

    test('neutralGrey200 + offWhite >= 3:1 (UI component)', () {
      final ratio =
          contrastRatio(BrandPalette.neutralGrey200, BrandPalette.offWhite);
      expect(ratio, greaterThanOrEqualTo(3.0),
          reason: 'Outline borders must be visible against light surface');
    });

    test('forest900 + onDarkHigh >= 4.5:1', () {
      final ratio =
          contrastRatio(BrandPalette.forest900, BrandPalette.onDarkHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Dark surface must have AA contrast with white text');
    });

    test('forest400 + onDarkHigh >= 4.5:1', () {
      final ratio =
          contrastRatio(BrandPalette.forest400, BrandPalette.onDarkHigh);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Dark mode primary must have AA contrast on white');
    });
  });

  group('BrandPalette.onColorFor utility', () {
    test('returns onLightHigh for light backgrounds', () {
      final result = BrandPalette.onColorFor(BrandPalette.offWhite);
      expect(result, equals(BrandPalette.onLightHigh));
    });

    test('returns onDarkHigh for dark backgrounds', () {
      final result = BrandPalette.onColorFor(BrandPalette.forest900);
      expect(result, equals(BrandPalette.onDarkHigh));
    });

    test('luminance threshold is 0.5', () {
      const lightColor = Color(0xFFBCBCBC); // >0.5 luminance
      const darkColor = Color(0xFF404040); // <0.5 luminance

      expect(lightColor.computeLuminance(), greaterThan(0.5));
      expect(darkColor.computeLuminance(), lessThan(0.5));

      expect(BrandPalette.onColorFor(lightColor),
          equals(BrandPalette.onLightHigh));
      expect(
          BrandPalette.onColorFor(darkColor), equals(BrandPalette.onDarkHigh));
    });
  });
}
