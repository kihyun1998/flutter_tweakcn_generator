import 'package:flutter_tweakcn_generator/src/models/tweakcn_theme_data.dart';
import 'package:test/test.dart';

void main() {
  TweakcnThemeData themeWith({String? light, String? dark}) => TweakcnThemeData(
    light: ThemeModeData(colors: const {}, fontSans: light),
    dark: ThemeModeData(colors: const {}, fontSans: dark),
  );

  group('TweakcnThemeData.resolvedFontSans', () {
    test('uses the light stack when only light declares one', () {
      expect(
        themeWith(light: 'Inter, sans-serif').resolvedFontSans,
        'Inter, sans-serif',
      );
    });

    test('falls back to the dark stack when only dark declares one', () {
      expect(
        themeWith(dark: 'Inter, sans-serif').resolvedFontSans,
        'Inter, sans-serif',
      );
    });

    test('prefers light when both declare one', () {
      expect(
        themeWith(
          light: 'Inter, sans-serif',
          dark: 'Roboto, sans-serif',
        ).resolvedFontSans,
        'Inter, sans-serif',
      );
    });

    test('is null when neither declares one', () {
      expect(themeWith().resolvedFontSans, isNull);
    });

    test('treats a blank declaration as absent', () {
      // `--font-sans: ;` parses to an empty value; it declares nothing.
      expect(
        themeWith(light: '', dark: 'Inter, sans-serif').resolvedFontSans,
        'Inter, sans-serif',
      );
      expect(themeWith(light: '   ').resolvedFontSans, isNull);
    });
  });
}
