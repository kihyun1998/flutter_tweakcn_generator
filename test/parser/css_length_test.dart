import 'package:flutter_tweakcn_generator/src/parser/css_length.dart';
import 'package:test/test.dart';

void main() {
  group('CssLength.toPixels', () {
    test('converts rem against the root font size', () {
      expect(CssLength.toPixels('1rem'), 16.0);
      expect(CssLength.toPixels('0.25rem'), 4.0);
      expect(CssLength.toPixels('0.625rem'), 10.0);
    });

    test('converts em the same way as rem', () {
      expect(CssLength.toPixels('1em'), 16.0);
      expect(CssLength.toPixels('0.5em'), 8.0);
    });

    test('leaves px values alone', () {
      expect(CssLength.toPixels('2px'), 2.0);
      expect(CssLength.toPixels('0px'), 0.0);
    });

    test('treats a unitless number as pixels', () {
      expect(CssLength.toPixels('4'), 4.0);
      expect(CssLength.toPixels('0'), 0.0);
      expect(CssLength.toPixels('1.5'), 1.5);
    });

    test('carries the sign through the conversion', () {
      expect(CssLength.toPixels('-0.5rem'), -8.0);
      expect(CssLength.toPixels('-3px'), -3.0);
      expect(CssLength.toPixels('-2'), -2.0);
      expect(CssLength.toPixels('-0.125rem'), -2.0);
    });

    test('accepts surrounding whitespace', () {
      expect(CssLength.toPixels('  0.5rem  '), 8.0);
    });

    test('matches units case-insensitively, as CSS does', () {
      expect(CssLength.toPixels('1REM'), 16.0);
      expect(CssLength.toPixels('2PX'), 2.0);
    });

    test('accepts the leading plus CSS numbers allow', () {
      expect(CssLength.toPixels('+1rem'), 16.0);
      expect(CssLength.toPixels('+2'), 2.0);
      expect(CssLength.toPixels('+0.5px'), 0.5);
    });

    test('accepts exponent notation', () {
      expect(CssLength.toPixels('1e-2rem'), closeTo(0.16, 1e-9));
      expect(CssLength.toPixels('1e3'), 1000.0);
      expect(CssLength.toPixels('1E2px'), 100.0);
    });

    test('accepts a leading point', () {
      expect(CssLength.toPixels('.5rem'), 8.0);
      expect(CssLength.toPixels('-.25rem'), -4.0);
    });

    test('refuses lengths it cannot convert', () {
      expect(CssLength.toPixels('50%'), isNull);
      expect(CssLength.toPixels('auto'), isNull);
      expect(CssLength.toPixels(''), isNull);
      expect(CssLength.toPixels('1.2.3'), isNull);
      expect(CssLength.toPixels('10pt'), isNull);
      expect(CssLength.toPixels('rem'), isNull);
      expect(CssLength.toPixels('.'), isNull);
    });
  });

  group('CssLength.findAll', () {
    test('converts every length in order', () {
      expect(CssLength.findAll('0 0.25rem 8px -0.125em'), [0, 4, 8, -2]);
    });

    test('agrees with toPixels on units and case', () {
      expect(CssLength.findAll('1REM 2Px'), [16, 2]);
    });

    test('finds nothing in a value with no lengths', () {
      expect(CssLength.findAll('none'), isEmpty);
      expect(CssLength.findAll(''), isEmpty);
    });

    test('does not read a bare point as a length', () {
      expect(CssLength.findAll('0 . 4px'), [0, 4]);
    });
  });
}
