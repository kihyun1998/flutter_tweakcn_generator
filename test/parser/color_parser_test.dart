import 'package:flutter_tweakcn_generator/src/parser/color_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ColorParser', () {
    group('hex', () {
      test('parses #RRGGBB', () {
        expect(ColorParser.parse('#ffffff'), 0xFFFFFFFF);
        expect(ColorParser.parse('#000000'), 0xFF000000);
        expect(ColorParser.parse('#0a0a0a'), 0xFF0A0A0A);
        expect(ColorParser.parse('#171717'), 0xFF171717);
      });

      test('parses #RGB shorthand', () {
        expect(ColorParser.parse('#fff'), 0xFFFFFFFF);
        expect(ColorParser.parse('#000'), 0xFF000000);
        expect(ColorParser.parse('#f00'), 0xFFFF0000);
      });

      test('parses #RRGGBBAA', () {
        expect(ColorParser.parse('#ff000080'), 0x80FF0000);
        expect(ColorParser.parse('#000000ff'), 0xFF000000);
      });

      test('parses #RGBA shorthand', () {
        expect(ColorParser.parse('#f008'), 0x88FF0000);
      });

      test('handles case insensitivity', () {
        expect(ColorParser.parse('#FFFFFF'), 0xFFFFFFFF);
        expect(ColorParser.parse('#AbCdEf'), 0xFFABCDEF);
      });
    });

    group('rgb', () {
      test('parses rgb(r, g, b) with commas', () {
        expect(ColorParser.parse('rgb(255, 255, 255)'), 0xFFFFFFFF);
        expect(ColorParser.parse('rgb(0, 0, 0)'), 0xFF000000);
        expect(ColorParser.parse('rgb(255, 0, 0)'), 0xFFFF0000);
      });

      test('parses rgb(r g b) with spaces', () {
        expect(ColorParser.parse('rgb(255 255 255)'), 0xFFFFFFFF);
        expect(ColorParser.parse('rgb(0 0 0)'), 0xFF000000);
      });

      test('parses rgba with alpha', () {
        expect(ColorParser.parse('rgba(0, 0, 0, 0.5)'), 0x80000000);
        expect(ColorParser.parse('rgba(255, 255, 255, 1)'), 0xFFFFFFFF);
      });

      test('parses rgb with slash alpha', () {
        expect(ColorParser.parse('rgb(0 0 0 / 0.5)'), 0x80000000);
        expect(ColorParser.parse('rgb(0 0 0 / 0.1)'), 0x1A000000);
      });

      test('parses percentage alpha', () {
        expect(ColorParser.parse('rgb(0 0 0 / 50%)'), 0x80000000);
      });
    });

    group('hsl', () {
      test('parses pure white', () {
        expect(ColorParser.parse('hsl(0 0% 100%)'), 0xFFFFFFFF);
      });

      test('parses pure black', () {
        expect(ColorParser.parse('hsl(0 0% 0%)'), 0xFF000000);
      });

      test('parses gray', () {
        final result = ColorParser.parse('hsl(0 0% 50%)');
        expect(result, isNotNull);
        // Should be approximately 0xFF808080
        expect((result! >> 16) & 0xFF, closeTo(128, 1)); // R
        expect((result >> 8) & 0xFF, closeTo(128, 1)); // G
        expect(result & 0xFF, closeTo(128, 1)); // B
      });

      test('parses pure red', () {
        final result = ColorParser.parse('hsl(0 100% 50%)');
        expect(result, isNotNull);
        expect((result! >> 16) & 0xFF, 255); // R
        expect((result >> 8) & 0xFF, 0); // G
        expect(result & 0xFF, 0); // B
      });

      test('parses with alpha', () {
        final result = ColorParser.parse('hsl(0 0% 100% / 0.5)');
        expect(result, isNotNull);
        expect((result! >> 24) & 0xFF, closeTo(128, 1)); // Alpha
      });

      test('parses hsl(0 0% 4%) for near-black', () {
        final result = ColorParser.parse('hsl(0 0% 4%)');
        expect(result, isNotNull);
        final r = (result! >> 16) & 0xFF;
        expect(r, closeTo(10, 1)); // 4% of 255 ≈ 10
      });
    });

    group('oklch', () {
      test('parses white (L=1, C=0)', () {
        final result = ColorParser.parse('oklch(1 0 0)');
        expect(result, isNotNull);
        expect((result! >> 16) & 0xFF, closeTo(255, 1));
        expect((result >> 8) & 0xFF, closeTo(255, 1));
        expect(result & 0xFF, closeTo(255, 1));
      });

      test('parses black (L=0, C=0)', () {
        final result = ColorParser.parse('oklch(0 0 0)');
        expect(result, isNotNull);
        expect((result! >> 16) & 0xFF, 0);
        expect((result >> 8) & 0xFF, 0);
        expect(result & 0xFF, 0);
      });

      test('parses with alpha', () {
        final result = ColorParser.parse('oklch(1 0 0 / 0.5)');
        expect(result, isNotNull);
        expect((result! >> 24) & 0xFF, closeTo(128, 1));
      });

      test('parses a chromatic color', () {
        // A reddish color
        final result = ColorParser.parse('oklch(0.6 0.2 30)');
        expect(result, isNotNull);
        // Should produce a valid color with R > G, R > B
        final r = (result! >> 16) & 0xFF;
        final g = (result >> 8) & 0xFF;
        final b = result & 0xFF;
        expect(r, greaterThan(g));
        expect(r, greaterThan(b));
      });
    });

    group('edge cases', () {
      test('returns null for empty string', () {
        expect(ColorParser.parse(''), isNull);
      });

      test('returns null for unknown format', () {
        expect(ColorParser.parse('red'), isNull);
        expect(ColorParser.parse('not-a-color'), isNull);
      });

      test('handles whitespace', () {
        expect(ColorParser.parse('  #ffffff  '), 0xFFFFFFFF);
        expect(ColorParser.parse('  rgb(0, 0, 0)  '), 0xFF000000);
      });
    });
  });
}
