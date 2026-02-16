import 'dart:io';

import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:test/test.dart';

void main() {
  group('CssParser', () {
    test('parses hex CSS fixture', () {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final result = CssParser.parse(css);

      // Light mode
      expect(result.light.colors['background'], 0xFFFFFFFF);
      expect(result.light.colors['foreground'], 0xFF0A0A0A);
      expect(result.light.colors['primary'], 0xFF171717);
      expect(result.light.colors['primary-foreground'], 0xFFFAFAFA);
      expect(result.light.colors['destructive'], 0xFFEF4444);

      // Dark mode
      expect(result.dark.colors['background'], 0xFF0A0A0A);
      expect(result.dark.colors['foreground'], 0xFFFAFAFA);
      expect(result.dark.colors['primary'], 0xFFFAFAFA);
      expect(result.dark.colors['destructive'], 0xFF7F1D1D);

      // Radius (0.625rem = 10px)
      expect(result.light.radius, 10.0);

      // Shadows
      expect(result.light.shadows, isNotEmpty);
      expect(result.light.shadows['shadow-xs'], isNotNull);
      expect(result.light.shadows['shadow-sm'], isNotNull);
    });

    test('parses hsl CSS fixture', () {
      final css = File('test/fixtures/sample_hsl.css').readAsStringSync();
      final result = CssParser.parse(css);

      // hsl(0 0% 100%) = white
      expect(result.light.colors['background'], 0xFFFFFFFF);

      // hsl(0 0% 0%) would be black, hsl(0 0% 4%) ≈ #0A0A0A
      final fg = result.light.colors['foreground']!;
      expect((fg >> 16) & 0xFF, closeTo(10, 1));

      // Dark mode should also parse
      expect(result.dark.colors['background'], isNotNull);
      expect(result.dark.colors['primary'], isNotNull);

      // Radius (0.5rem = 8px)
      expect(result.light.radius, 8.0);
    });

    test('ignores @theme inline block', () {
      const css = '''
@theme inline {
  --color-background: var(--background);
}

:root {
  --background: #ffffff;
  --foreground: #000000;
}
''';
      final result = CssParser.parse(css);
      expect(result.light.colors['background'], 0xFFFFFFFF);
      expect(result.light.colors['foreground'], 0xFF000000);
    });

    test('parses all sidebar tokens', () {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final result = CssParser.parse(css);

      expect(result.light.colors['sidebar'], isNotNull);
      expect(result.light.colors['sidebar-foreground'], isNotNull);
      expect(result.light.colors['sidebar-primary'], isNotNull);
      expect(result.light.colors['sidebar-primary-foreground'], isNotNull);
      expect(result.light.colors['sidebar-accent'], isNotNull);
      expect(result.light.colors['sidebar-accent-foreground'], isNotNull);
      expect(result.light.colors['sidebar-border'], isNotNull);
      expect(result.light.colors['sidebar-ring'], isNotNull);
    });

    test('parses chart colors', () {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final result = CssParser.parse(css);

      expect(result.light.colors['chart-1'], isNotNull);
      expect(result.light.colors['chart-2'], isNotNull);
      expect(result.light.colors['chart-3'], isNotNull);
      expect(result.light.colors['chart-4'], isNotNull);
      expect(result.light.colors['chart-5'], isNotNull);
    });

    test('parses shadow tokens', () {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final result = CssParser.parse(css);

      expect(
          result.light.shadows.keys,
          containsAll([
            'shadow-2xs',
            'shadow-xs',
            'shadow-sm',
            'shadow',
            'shadow-md',
            'shadow-lg',
            'shadow-xl',
            'shadow-2xl',
          ]));

      // shadow-md has 2 shadows
      expect(result.light.shadows['shadow-md'], hasLength(2));

      // shadow-2xl has 1 shadow
      expect(result.light.shadows['shadow-2xl'], hasLength(1));
    });

    test('parses font-sans', () {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final result = CssParser.parse(css);

      expect(result.light.fontSans, "'Inter', sans-serif");
    });

    test('font-sans is null when not specified', () {
      const css = '''
:root {
  --background: #ffffff;
}
''';
      final result = CssParser.parse(css);
      expect(result.light.fontSans, isNull);
    });

    test('handles empty CSS', () {
      final result = CssParser.parse('');
      expect(result.light.colors, isEmpty);
      expect(result.dark.colors, isEmpty);
    });

    test('handles CSS with only :root', () {
      const css = '''
:root {
  --background: #ff0000;
}
''';
      final result = CssParser.parse(css);
      expect(result.light.colors['background'], 0xFFFF0000);
      expect(result.dark.colors, isEmpty);
    });
  });
}
