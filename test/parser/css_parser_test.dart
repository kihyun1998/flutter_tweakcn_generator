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
        ]),
      );

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

  group('CssParser without a trailing semicolon', () {
    test('parses a color that is last in the block', () {
      final result = CssParser.parse('''
:root {
  --background: #ffffff;
  --primary: #ff0000
}
''');

      expect(result.light.colors['primary'], 0xFFFF0000);
      expect(result.light.colors['background'], 0xFFFFFFFF);
    });

    test('parses a radius that is last in the block', () {
      final result = CssParser.parse('''
:root {
  --background: #ffffff;
  --radius: 0.5rem
}
''');

      expect(result.light.radius, 8.0);
    });

    test('parses a font stack that is last in the block', () {
      final result = CssParser.parse('''
:root {
  --background: #ffffff;
  --font-sans: Inter, sans-serif
}
''');

      expect(result.light.fontSans, 'Inter, sans-serif');
    });

    test('parses a shadow that is last in the block', () {
      final result = CssParser.parse('''
:root {
  --shadow-sm: 0 1px 3px 0px hsl(0 0% 0% / 0.10)
}
''');

      expect(result.light.shadows['shadow-sm'], hasLength(1));
    });

    test('parses the last declaration on a single-line block', () {
      final result = CssParser.parse(
        ':root { --background: #ffffff; --radius: 0.5rem }',
      );

      expect(result.light.colors['background'], 0xFFFFFFFF);
      expect(result.light.radius, 8.0);
    });

    test('parses the last declaration of a .dark block', () {
      final result = CssParser.parse('''
:root { --primary: #ff0000; }
.dark {
  --primary: #00ff00
}
''');

      expect(result.dark.colors['primary'], 0xFF00FF00);
    });

    test('leaves semicolon-terminated declarations unchanged', () {
      final result = CssParser.parse('''
:root {
  --background: #ffffff;
  --primary: #ff0000;
  --radius: 0.5rem;
}
''');

      expect(result.light.colors['background'], 0xFFFFFFFF);
      expect(result.light.colors['primary'], 0xFFFF0000);
      expect(result.light.radius, 8.0);
    });
  });

  group('CssParser with comments', () {
    test('ignores a trailing comment after the last declaration', () {
      final result = CssParser.parse('''
:root {
  --background: #ffffff;
  --radius: 0.5rem /* the shadcn default */
}
''');

      expect(result.light.radius, 8.0);
    });

    test('ignores a comment between declarations', () {
      final result = CssParser.parse('''
:root {
  /* base colors */
  --background: #ffffff;
  --primary: #ff0000;
}
''');

      expect(result.light.colors['background'], 0xFFFFFFFF);
      expect(result.light.colors['primary'], 0xFFFF0000);
    });

    test('does not parse a commented-out declaration', () {
      final result = CssParser.parse('''
:root {
  --background: #ffffff;
  /* --primary: #ff0000; */
}
''');

      expect(result.light.colors.containsKey('primary'), isFalse);
    });

    test('is not confused by a brace inside a comment', () {
      final result = CssParser.parse('''
:root {
  /* a stray } brace */
  --primary: #ff0000;
}
''');

      expect(result.light.colors['primary'], 0xFFFF0000);
    });

    test('does not read the slash in oklch(... / a) as a comment opener', () {
      final result = CssParser.parse('''
:root {
  --primary: oklch(0.5 0.2 240 / 0.8)
}
''');

      // 0.8 alpha survives, so the value reached the colour parser intact.
      expect((result.light.colors['primary']! >> 24) & 0xFF, 204);
    });

    test(
      'runs an unterminated comment to the next close marker, as CSS does',
      () {
        // CSS comments do not nest: the first `/*` runs to the next `*/`, which
        // here is inside .dark — taking the `}` that closed :root with it. A
        // browser resolves this malformed CSS the same way.
        final result = CssParser.parse('''
:root {
  /* unterminated
  --primary: #ff0000;
}
.dark {
  /* real */
  --primary: #00ff00;
}
''');

        expect(result.light.colors['primary'], 0xFF00FF00);
        expect(result.dark.colors, isEmpty);
      },
    );

    test('leaves a comment marker with no close marker alone', () {
      // Nothing pairs with it, so the declarations after it still parse
      // rather than the rest of the file being silently dropped.
      final result = CssParser.parse('''
:root {
  --primary: #ff0000;
  /* truncated paste
}
''');

      expect(result.light.colors['primary'], 0xFFFF0000);
    });
  });

  group('CssParser length tokens', () {
    double? radiusOf(String value) =>
        CssParser.parse(':root { --radius: $value; }').light.radius;

    test('converts rem and em alike', () {
      expect(radiusOf('0.5rem'), 8.0);
      expect(radiusOf('0.5em'), 8.0);
    });

    test('keeps px and unitless values', () {
      expect(radiusOf('12px'), 12.0);
      expect(radiusOf('12'), 12.0);
    });

    test('accepts signs and exponents CSS numbers allow', () {
      expect(radiusOf('+1rem'), 16.0);
      expect(radiusOf('-4px'), -4.0);
      expect(radiusOf('1e3'), 1000.0);
    });

    test('rejects a value that is not a length', () {
      expect(radiusOf('1px2'), isNull);
      expect(radiusOf('50%'), isNull);
      expect(radiusOf('auto'), isNull);
    });
  });
}
