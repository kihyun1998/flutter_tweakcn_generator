import 'package:flutter_tweakcn_generator/src/generator/color_scheme_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('ColorSchemeResolver', () {
    test('uses the theme token when it is defined', () {
      final resolved = ColorSchemeResolver.resolve({
        'background': 0xFFF9F9F9,
        'foreground': 0xFF3A3A3A,
        'primary': 0xFF606060,
        'primary-foreground': 0xFFF0F0F0,
        'secondary': 0xFFDEDEDE,
        'secondary-foreground': 0xFF3A3A3A,
        'destructive': 0xFFC87A7A,
        'destructive-foreground': 0xFFFFFFFF,
      }, isDark: false);

      expect(resolved.colors['surface'], 0xFFF9F9F9);
      expect(resolved.colors['onSurface'], 0xFF3A3A3A);
      expect(resolved.colors['primary'], 0xFF606060);
      expect(resolved.colors['onPrimary'], 0xFFF0F0F0);
      expect(resolved.colors['secondary'], 0xFFDEDEDE);
      expect(resolved.colors['onSecondary'], 0xFF3A3A3A);
      expect(resolved.colors['error'], 0xFFC87A7A);
      expect(resolved.colors['onError'], 0xFFFFFFFF);
      expect(resolved.substitutedTokens, isEmpty);
    });

    test('resolves every required property from an empty theme', () {
      final resolved = ColorSchemeResolver.resolve({}, isDark: false);

      expect(
        resolved.colors.keys,
        containsAll(ColorSchemeResolver.requiredTokens.keys),
      );
      for (final entry in resolved.colors.entries) {
        expect(entry.value, isNotNull, reason: '${entry.key} must resolve');
        // Nothing may be transparent — a transparent scheme color is a
        // silently broken theme rather than a visible fallback.
        expect(
          (entry.value >> 24) & 0xFF,
          0xFF,
          reason: '${entry.key} must be opaque',
        );
      }
    });

    test('reports every token it had to substitute', () {
      final resolved = ColorSchemeResolver.resolve({
        'background': 0xFFFFFFFF,
        'primary': 0xFF0000FF,
      }, isDark: false);

      expect(
        resolved.substitutedTokens,
        containsAll([
          'foreground',
          'primary-foreground',
          'secondary',
          'secondary-foreground',
          'destructive',
          'destructive-foreground',
        ]),
      );
      expect(resolved.substitutedTokens, isNot(contains('background')));
      expect(resolved.substitutedTokens, isNot(contains('primary')));
    });

    test('derives a missing on-color that contrasts with its base', () {
      final onDark = ColorSchemeResolver.resolve({
        'primary': 0xFF101010,
      }, isDark: false);
      expect(onDark.colors['onPrimary'], 0xFFFFFFFF);

      final onLight = ColorSchemeResolver.resolve({
        'primary': 0xFFF0F0F0,
      }, isDark: false);
      expect(onLight.colors['onPrimary'], 0xFF000000);
    });

    test('falls back to the primary color for a missing secondary', () {
      final resolved = ColorSchemeResolver.resolve({
        'primary': 0xFF606060,
      }, isDark: false);

      expect(resolved.colors['secondary'], 0xFF606060);
    });

    test('uses brightness-appropriate defaults for a missing surface', () {
      expect(
        ColorSchemeResolver.resolve({}, isDark: false).colors['surface'],
        0xFFFFFFFF,
      );
      expect(
        ColorSchemeResolver.resolve({}, isDark: true).colors['surface'],
        0xFF121212,
      );
    });

    test('derives onSurface from the resolved surface', () {
      expect(
        ColorSchemeResolver.resolve({}, isDark: false).colors['onSurface'],
        0xFF000000,
      );
      expect(
        ColorSchemeResolver.resolve({}, isDark: true).colors['onSurface'],
        0xFFFFFFFF,
      );
    });

    test('keeps a defined color even when it is transparent', () {
      final resolved = ColorSchemeResolver.resolve({
        'primary': 0x00FF0000,
      }, isDark: false);

      expect(resolved.colors['primary'], 0x00FF0000);
      expect(resolved.substitutedTokens, isNot(contains('primary')));
    });
  });
}
