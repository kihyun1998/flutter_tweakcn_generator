import 'package:flutter_tweakcn_generator/src/models/tweakcn_theme_data.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:flutter_tweakcn_generator/src/parser/shadow_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ShadowData.toLayer', () {
    test('carries every field across as a primitive', () {
      const shadow = ShadowData(
        offsetX: 1,
        offsetY: 4,
        blurRadius: 5,
        spreadRadius: -1,
        color: 0x08000000,
      );

      expect(shadow.toLayer(), (
        offsetX: 1.0,
        offsetY: 4.0,
        blurRadius: 5.0,
        spreadRadius: -1.0,
        color: 0x08000000,
      ));
    });
  });

  group('ThemeModeData.shadowLayers', () {
    ThemeModeData modeFrom(String css) => CssParser.parse(css).light;

    test('converts every level the theme declares', () {
      final mode = modeFrom('''
:root {
  --shadow-sm: 1px 4px 5px 0px rgba(0, 0, 0, 0.03);
  --shadow-md: 0 2px 4px -1px rgba(0, 0, 0, 0.1);
}
''');

      expect(
        mode.shadowLayers.keys,
        unorderedEquals(['shadow-sm', 'shadow-md']),
      );
      expect(mode.shadowLayers['shadow-md']!.single, (
        offsetX: 0.0,
        offsetY: 2.0,
        blurRadius: 4.0,
        spreadRadius: -1.0,
        color: 0x1A000000,
      ));
    });

    test('keeps the layers of a level in the order the CSS lists them', () {
      // Every field differs between the two layers, including the colour, so
      // a conversion that paired the wrong ones up cannot pass.
      final mode = modeFrom('''
:root {
  --shadow-sm: 1px 4px 5px 0px rgba(0, 0, 0, 0.03),
               2px 8px 9px 1px rgba(255, 0, 0, 0.5);
}
''');

      expect(mode.shadowLayers['shadow-sm'], [
        (
          offsetX: 1.0,
          offsetY: 4.0,
          blurRadius: 5.0,
          spreadRadius: 0.0,
          color: 0x08000000,
        ),
        (
          offsetX: 2.0,
          offsetY: 8.0,
          blurRadius: 9.0,
          spreadRadius: 1.0,
          color: 0x80FF0000,
        ),
      ]);
    });

    test('is empty for a theme that declares no shadows', () {
      expect(modeFrom(':root { --radius: 0.5rem; }').shadowLayers, isEmpty);
    });

    test('names no type from this package, so it needs no import to read', () {
      // The whole point of the shape: a consumer can hold it, and the
      // generated file can take it, without either naming ShadowData.
      final List<
        ({
          double offsetX,
          double offsetY,
          double blurRadius,
          double spreadRadius,
          int color,
        })
      >
      layers =
          modeFrom(
            ':root { --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05); }',
          ).shadowLayers['shadow-sm']!;

      expect(layers.single.blurRadius, 2.0);
    });
  });
}
