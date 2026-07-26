import 'package:flutter_tweakcn_generator/src/parser/shadow_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ShadowParser', () {
    test('parses single shadow with rgba', () {
      final result = ShadowParser.parse('0 1px 3px 0px rgba(0, 0, 0, 0.1)');
      expect(result, hasLength(1));
      expect(result[0].offsetX, 0);
      expect(result[0].offsetY, 1);
      expect(result[0].blurRadius, 3);
      expect(result[0].spreadRadius, 0);
      // Alpha should be ~26 (0.1 * 255)
      expect((result[0].color >> 24) & 0xFF, closeTo(26, 1));
    });

    test('parses multiple shadows separated by comma', () {
      final result = ShadowParser.parse(
        '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
      );
      expect(result, hasLength(2));
      expect(result[0].offsetY, 1);
      expect(result[0].blurRadius, 3);
      expect(result[1].offsetY, 1);
      expect(result[1].blurRadius, 2);
      expect(result[1].spreadRadius, -1);
    });

    test('parses shadow with hex color', () {
      final result = ShadowParser.parse('0 2px 4px #000000');
      expect(result, hasLength(1));
      expect(result[0].blurRadius, 4);
      expect(result[0].color, 0xFF000000);
    });

    test('parses shadow with hsl color', () {
      final result = ShadowParser.parse('0 1px 2px 0 hsl(0 0% 0% / 0.05)');
      expect(result, hasLength(1));
      expect(result[0].offsetY, 1);
      expect(result[0].blurRadius, 2);
    });

    test('parses shadow without color (defaults to black)', () {
      final result = ShadowParser.parse('0 1px 2px 0');
      expect(result, hasLength(1));
      expect(result[0].color, 0xFF000000);
    });

    test('returns empty for "none"', () {
      expect(ShadowParser.parse('none'), isEmpty);
    });

    test('returns empty for empty string', () {
      expect(ShadowParser.parse(''), isEmpty);
    });

    test('parses shadow-2xs format (2 values + color)', () {
      final result = ShadowParser.parse('0 1px rgba(0, 0, 0, 0.05)');
      expect(result, hasLength(1));
      expect(result[0].offsetX, 0);
      expect(result[0].offsetY, 1);
    });

    test('handles negative spread radius', () {
      final result = ShadowParser.parse('0 4px 6px -1px rgba(0, 0, 0, 0.1)');
      expect(result, hasLength(1));
      expect(result[0].spreadRadius, -1);
    });
  });

  group('ShadowParser length units', () {
    test('converts a shadow expressed entirely in rem', () {
      final result = ShadowParser.parse(
        '0 0.25rem 0.5rem 0.125rem hsl(0 0% 0% / 0.1)',
      );

      expect(result, hasLength(1));
      expect(result[0].offsetX, 0);
      expect(result[0].offsetY, 4);
      expect(result[0].blurRadius, 8);
      expect(result[0].spreadRadius, 2);
    });

    test('converts a mixed-unit shadow', () {
      final result = ShadowParser.parse(
        '1px 0.25rem 8px 0.125em hsl(0 0% 0% / 0.1)',
      );

      expect(result, hasLength(1));
      expect(result[0].offsetX, 1);
      expect(result[0].offsetY, 4);
      expect(result[0].blurRadius, 8);
      expect(result[0].spreadRadius, 2);
    });

    test('converts negative offsets and spreads', () {
      final result = ShadowParser.parse(
        '-0.25rem -0.5rem 0 -0.125rem hsl(0 0% 0% / 0.1)',
      );

      expect(result, hasLength(1));
      expect(result[0].offsetX, -4);
      expect(result[0].offsetY, -8);
      expect(result[0].blurRadius, 0);
      expect(result[0].spreadRadius, -2);
    });

    test('leaves px and unitless values unchanged', () {
      final result = ShadowParser.parse('0 4px 6px -1px rgba(0, 0, 0, 0.1)');

      expect(result[0].offsetX, 0);
      expect(result[0].offsetY, 4);
      expect(result[0].blurRadius, 6);
      expect(result[0].spreadRadius, -1);
    });

    test('converts every shadow in a multi-shadow value', () {
      final result = ShadowParser.parse(
        '0 0.0625rem 0.125rem hsl(0 0% 0% / 0.1), '
        '0 0.125rem 0.25rem hsl(0 0% 0% / 0.1)',
      );

      expect(result, hasLength(2));
      expect(result[0].offsetY, 1);
      expect(result[0].blurRadius, 2);
      expect(result[1].offsetY, 2);
      expect(result[1].blurRadius, 4);
    });

    test('converts units regardless of case, as the radius token does', () {
      final result = ShadowParser.parse('0 2REM 1PX hsl(0 0% 0% / 0.1)');

      expect(result[0].offsetY, 32);
      expect(result[0].blurRadius, 1);
    });

    test('a rem radius and a rem shadow agree on what a rem is', () {
      final shadow = ShadowParser.parse('0 0.5rem 0 hsl(0 0% 0% / 0.1)');

      // The radius token converts 0.5rem to 8px; the shadow must match.
      expect(shadow[0].offsetY, 8);
    });
  });
}
