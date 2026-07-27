import 'dart:io';

import 'package:flutter_tweakcn_generator/src/generator/color_scheme_resolver.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:test/test.dart';

void main() {
  group('DartThemeGenerator', () {
    late String generatedCode;

    setUpAll(() {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData);
      generatedCode = generator.generate();
    });

    test('generates valid Dart with required imports', () {
      expect(
        generatedCode,
        contains("import 'package:flutter/material.dart';"),
      );
    });

    test('generates header comment', () {
      expect(generatedCode, contains('GENERATED CODE - DO NOT MODIFY BY HAND'));
    });

    test('generates light ColorScheme', () {
      expect(generatedCode, contains('_lightColorScheme'));
      expect(generatedCode, contains('Brightness.light'));
    });

    test('leaves a complete theme untouched by fallback resolution', () {
      // Golden: a CSS file defining every mapped token must generate exactly
      // what it did before ColorScheme fallbacks existed.
      expect(
        generatedCode,
        contains('''
const _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF0A0A0A),
  primary: Color(0xFF171717),
  onPrimary: Color(0xFFFAFAFA),
  secondary: Color(0xFFF5F5F5),
  onSecondary: Color(0xFF171717),
  error: Color(0xFFEF4444),
  onError: Color(0xFFFAFAFA),
  outline: Color(0xFFE5E5E5),
  outlineVariant: Color(0xFFE5E5E5),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerHighest: Color(0xFFF5F5F5),
  onSurfaceVariant: Color(0xFF737373),
);'''),
      );
    });

    test('generates dark ColorScheme', () {
      expect(generatedCode, contains('_darkColorScheme'));
      expect(generatedCode, contains('Brightness.dark'));
    });

    test('generates TweakcnColors extension', () {
      expect(
        generatedCode,
        contains('class TweakcnColors extends ThemeExtension<TweakcnColors>'),
      );
      expect(generatedCode, contains('static const light = TweakcnColors('));
      expect(generatedCode, contains('static const dark = TweakcnColors('));
      expect(generatedCode, contains('TweakcnColors copyWith('));
      expect(generatedCode, contains('TweakcnColors lerp('));
    });

    test('generates a runtime factory over the parsed color map', () {
      // The signature stays in primitives on purpose: the generated file
      // imports Flutter and nothing else, so a consumer building a theme at
      // runtime does not have to depend on this package to do it.
      expect(
        generatedCode,
        contains('factory TweakcnColors.fromMap(Map<String, int> colors)'),
      );
    });

    test('the factory reads every token the constants declare', () {
      final factory = _sliceBetween(
        generatedCode,
        'factory TweakcnColors.fromMap',
        '  );',
      );
      final light = _sliceBetween(
        generatedCode,
        'static const light = TweakcnColors(',
        '  );',
      );

      final declared =
          RegExp(
            r'^    (\w+): ',
            multiLine: true,
          ).allMatches(light).map((m) => m.group(1)).toList();

      expect(declared, isNotEmpty);
      for (final field in declared) {
        expect(
          factory,
          contains('$field: Color(colors['),
          reason: '$field is a constant field the factory never fills',
        );
      }
    });

    test('the factory falls back to the placeholder the constants use', () {
      // A theme that omits a token generates `Color(0x00000000)` for it. The
      // factory has to agree, or building from a theme's own tokens would not
      // reproduce that theme's constant.
      final code =
          DartThemeGenerator(
            CssParser.parse(':root { --background: #ffffff; }'),
          ).generate();
      final factory = _sliceBetween(
        code,
        'factory TweakcnColors.fromMap',
        '  );',
      );

      expect(code, contains('foreground: Color(0x00000000),'));
      expect(
        factory,
        contains("foreground: Color(colors['foreground'] ?? 0x00000000)"),
      );
    });

    test('the factory follows the class prefix', () {
      final code =
          DartThemeGenerator(
            CssParser.parse(':root { --background: #ffffff; }'),
            classPrefix: 'My',
          ).generate();

      expect(
        code,
        contains('factory MyColors.fromMap(Map<String, int> colors)'),
      );
    });

    test('gives every extension value equality over all of its fields', () {
      // Derived from each class's own constant rather than listed here: a
      // field the generator adds and equality forgets is exactly the drift
      // this catches, and a list written out here would forget it too.
      for (final (cls, constant, compare) in [
        ('TweakcnColors', 'light', (String f) => '$f == other.$f'),
        ('TweakcnRadius', 'standard', (String f) => '$f == other.$f'),
        ('TweakcnShadows', 'light', (String f) => 'listEquals($f, other.$f)'),
      ]) {
        final body = _sliceBetween(generatedCode, 'class $cls extends', '\n}');
        final instance = _sliceBetween(
          generatedCode,
          'static const $constant = $cls(',
          '\n  );',
        );
        final fields =
            RegExp(
              r'^    (\w+):',
              multiLine: true,
            ).allMatches(instance).map((m) => m.group(1)!).toList();

        expect(fields, isNotEmpty, reason: 'found no fields on $cls');
        for (final field in fields) {
          expect(
            body,
            contains(compare(field)),
            reason: '$cls.$field is a field equality never looks at',
          );
          expect(
            body,
            contains('int get hashCode => Object.hashAll(['),
            reason: '$cls does not hash by value',
          );
        }
      }
    });

    test('hashes the colors extension past what Object.hash takes', () {
      // Object.hash tops out at 20 arguments and this extension carries more
      // tokens than that, so the generated code cannot use it.
      final hash = _sliceBetween(
        generatedCode,
        'class TweakcnColors extends',
        '\n}',
      );

      expect(hash, contains('int get hashCode => Object.hashAll(['));
    });

    test('generates TweakcnRadius extension', () {
      expect(
        generatedCode,
        contains('class TweakcnRadius extends ThemeExtension<TweakcnRadius>'),
      );
      expect(generatedCode, contains('static const standard = TweakcnRadius('));
      expect(generatedCode, contains('TweakcnRadius copyWith('));
      expect(generatedCode, contains('TweakcnRadius lerp('));
    });

    test('generates a runtime factory over the parsed radius', () {
      // Nullable because the CSS need not define a radius, and the caller
      // should not have to know what the generator falls back to when it
      // does not — that is the arithmetic this factory exists to own.
      expect(
        generatedCode,
        contains('factory TweakcnRadius.fromRadius(double? radius)'),
      );
    });

    test('the radius factory falls back to the constant\'s own default', () {
      final code =
          DartThemeGenerator(
            CssParser.parse(':root { --background: #ffffff; }'),
          ).generate();
      final standard = _sliceBetween(
        code,
        'static const standard = TweakcnRadius(',
        '  );',
      );
      final factory = _sliceBetween(
        code,
        'factory TweakcnRadius.fromRadius',
        '  }',
      );

      // A theme that declares no radius still generates a constant, from a
      // default. Absent radius has to reach the same one.
      expect(standard, contains('lg: 8.0,'));
      expect(factory, contains('radius ?? 8.0'));
    });

    test('the radius factory applies the constant\'s own step offsets', () {
      final factory = _sliceBetween(
        generatedCode,
        'factory TweakcnRadius.fromRadius',
        '  }',
      );

      // The two steps below the base are held at zero; the base and the step
      // above it are left alone, because a radius that is itself negative is
      // the theme's own doing.
      expect(factory, contains('sm: atLeastZero(base - 4),'));
      expect(factory, contains('md: atLeastZero(base - 2),'));
      expect(factory, contains('lg: base,'));
      expect(factory, contains('xl: base + 4,'));
    });

    test('a radius smaller than its steps generates no negative one', () {
      // 0.125rem is 2px, so sm and md would both come out below zero.
      final code =
          DartThemeGenerator(
            CssParser.parse(':root { --radius: 0.125rem; }'),
          ).generate();
      final standard = _sliceBetween(
        code,
        'static const standard = TweakcnRadius(',
        '  );',
      );

      expect(standard, contains('sm: 0.0,'));
      expect(standard, contains('md: 0.0,'));
      expect(standard, contains('lg: 2.0,'));
      expect(standard, contains('xl: 6.0,'));
    });

    test('the radius factory follows the class prefix', () {
      final code =
          DartThemeGenerator(
            CssParser.parse(':root { --radius: 0.5rem; }'),
            classPrefix: 'My',
          ).generate();

      expect(code, contains('factory MyRadius.fromRadius(double? radius)'));
    });

    test('compares the shadows extension by layer, not by list identity', () {
      // Two lists holding equal BoxShadows are not `==`, so comparing the
      // fields directly would leave every instance unequal to every other —
      // which is the state this replaces.
      final body = _sliceBetween(
        generatedCode,
        'class TweakcnShadows extends',
        '\n}',
      );

      expect(body, isNot(contains('shadow2xs == other.shadow2xs')));
      expect(body, contains('Object.hashAll(shadow2xs)'));
    });

    test('generates TweakcnShadows extension', () {
      expect(
        generatedCode,
        contains('class TweakcnShadows extends ThemeExtension<TweakcnShadows>'),
      );
      expect(generatedCode, contains('static const light = TweakcnShadows('));
      expect(generatedCode, contains('static const dark = TweakcnShadows('));
    });

    test('generates the primitive shape a shadow layer crosses in', () {
      // A record, so the generated file names no type from this package and
      // a consumer still gets their field names checked.
      expect(
        generatedCode,
        contains('''
typedef TweakcnShadowLayer = ({
  double offsetX,
  double offsetY,
  double blurRadius,
  double spreadRadius,
  int color,
});'''),
      );
    });

    test('generates a runtime factory over the parsed shadows', () {
      expect(
        generatedCode,
        contains(
          'factory TweakcnShadows.fromShadowMap(\n'
          '    Map<String, List<TweakcnShadowLayer>> shadows,\n'
          '  )',
        ),
      );
    });

    test('the shadows factory fills every level the constants declare', () {
      final factory = _sliceBetween(
        generatedCode,
        'factory TweakcnShadows.fromShadowMap',
        '  }',
      );
      final light = _sliceBetween(
        generatedCode,
        'static const light = TweakcnShadows(',
        '\n  );',
      );

      final declared =
          RegExp(
            r'^    (\w+):',
            multiLine: true,
          ).allMatches(light).map((m) => m.group(1)).toSet();

      expect(declared, hasLength(8));
      for (final field in declared) {
        expect(
          factory,
          contains('$field: level('),
          reason: '$field is a constant field the factory never fills',
        );
      }
    });

    test('the shadows factory keys levels by their CSS token', () {
      final factory = _sliceBetween(
        generatedCode,
        'factory TweakcnShadows.fromShadowMap',
        '  }',
      );

      expect(factory, contains("shadow2xs: level('shadow-2xs')"));
      expect(factory, contains("shadow: level('shadow')"));
      expect(factory, contains("shadow2xl: level('shadow-2xl')"));
    });

    test('an undeclared shadow level comes out as the constants do', () {
      final code =
          DartThemeGenerator(
            CssParser.parse(':root { --shadow-md: 0 1px 2px 0 #00000010; }'),
          ).generate();

      // Levels the CSS does not define are baked in as empty lists, so the
      // factory has to reach the same thing when the map has no entry.
      expect(code, contains('shadow2xs: [],'));
      expect(code, contains("shadows[token] ?? const <TweakcnShadowLayer>[]"));
    });

    test('the shadows factory follows the class prefix', () {
      final code =
          DartThemeGenerator(
            CssParser.parse(':root { --shadow-md: 0 1px 2px 0 #00000010; }'),
            classPrefix: 'My',
          ).generate();

      expect(code, contains('typedef MyShadowLayer = ({'));
      expect(code, contains('Map<String, List<MyShadowLayer>> shadows'));
    });

    test('generates TweakcnTheme class', () {
      expect(generatedCode, contains('class TweakcnTheme'));
      expect(generatedCode, contains('static ThemeData get light'));
      expect(generatedCode, contains('static ThemeData get dark'));
    });

    test('generates BuildContext extension', () {
      expect(
        generatedCode,
        contains('extension TweakcnBuildContext on BuildContext'),
      );
      expect(generatedCode, contains('tweakcnColors'));
      expect(generatedCode, contains('tweakcnRadius'));
      expect(generatedCode, contains('tweakcnShadows'));
    });

    test('generates color fields in TweakcnColors', () {
      // Check camelCase conversion of CSS variables
      expect(generatedCode, contains('final Color background;'));
      expect(generatedCode, contains('final Color foreground;'));
      expect(generatedCode, contains('final Color cardForeground;'));
      expect(generatedCode, contains('final Color popoverForeground;'));
      expect(generatedCode, contains('final Color primaryForeground;'));
      expect(generatedCode, contains('final Color sidebarPrimary;'));
      expect(generatedCode, contains('final Color sidebarPrimaryForeground;'));
      expect(generatedCode, contains('final Color chart1;'));
    });

    test('generates shadow fields in TweakcnShadows', () {
      expect(generatedCode, contains('final List<BoxShadow> shadow2xs;'));
      expect(generatedCode, contains('final List<BoxShadow> shadowXs;'));
      expect(generatedCode, contains('final List<BoxShadow> shadowSm;'));
      expect(generatedCode, contains('final List<BoxShadow> shadow;'));
      expect(generatedCode, contains('final List<BoxShadow> shadowMd;'));
      expect(generatedCode, contains('final List<BoxShadow> shadowLg;'));
      expect(generatedCode, contains('final List<BoxShadow> shadowXl;'));
      expect(generatedCode, contains('final List<BoxShadow> shadow2xl;'));
    });

    test('generates radius values from CSS (0.625rem = 10px)', () {
      // lg = radius = 10, md = 8, sm = 6, xl = 14
      expect(generatedCode, contains('sm: 6.0'));
      expect(generatedCode, contains('md: 8.0'));
      expect(generatedCode, contains('lg: 10.0'));
      expect(generatedCode, contains('xl: 14.0'));
    });

    test('generates Color literals with hex values', () {
      // background: #ffffff → Color(0xFFFFFFFF)
      expect(generatedCode, contains('Color(0xFFFFFFFF)'));
      // foreground: #0a0a0a → Color(0xFF0A0A0A)
      expect(generatedCode, contains('Color(0xFF0A0A0A)'));
    });

    test('generates BoxShadow with correct values', () {
      expect(generatedCode, contains('BoxShadow('));
      expect(generatedCode, contains('Offset('));
      expect(generatedCode, contains('blurRadius:'));
      expect(generatedCode, contains('spreadRadius:'));
    });

    test('generates google_fonts import when font-sans has Google Font', () {
      expect(
        generatedCode,
        contains("import 'package:google_fonts/google_fonts.dart';"),
      );
    });

    test('generates textTheme with GoogleFonts in ThemeData', () {
      expect(
        generatedCode,
        contains('textTheme: GoogleFonts.interTextTheme()'),
      );
    });

    test('does not generate google_fonts import for system font stack', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: ui-sans-serif, system-ui, sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData);
      final code = generator.generate();

      expect(code, isNot(contains('google_fonts')));
      expect(code, isNot(contains('textTheme:')));
    });

    test('generates correct method name for multi-word Google Font', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Noto Sans KR', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData);
      final code = generator.generate();

      expect(code, contains('GoogleFonts.notoSansKrTextTheme()'));
    });

    test('extracts Google Font from full tweakcn font stack', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Inter', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData);
      final code = generator.generate();

      expect(code, contains('GoogleFonts.interTextTheme()'));
    });

    test('skips Google Fonts for default tweakcn system font stack', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData);
      final code = generator.generate();

      expect(code, isNot(contains('google_fonts')));
      expect(code, isNot(contains('textTheme:')));
    });

    test('generates fontFamilyFallback for multiple Google Fonts', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Architects Daughter', 'Noto Sans KR', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData);
      final code = generator.generate();

      expect(
        code,
        contains("import 'package:google_fonts/google_fonts.dart';"),
      );
      expect(
        code,
        contains('GoogleFonts.architectsDaughterTextTheme().apply('),
      );
      expect(
        code,
        contains('fontFamilyFallback: [GoogleFonts.notoSansKr().fontFamily!]'),
      );
    });

    test('generates fontFamilyFallback with multiple fallback fonts', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Inter', 'Noto Sans KR', 'Noto Sans JP', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData);
      final code = generator.generate();

      expect(code, contains('GoogleFonts.interTextTheme().apply('));
      expect(code, contains('GoogleFonts.notoSansKr().fontFamily!'));
      expect(code, contains('GoogleFonts.notoSansJp().fontFamily!'));
    });

    test('generates code with custom class prefix', () {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, classPrefix: 'My');
      final code = generator.generate();

      expect(code, contains('class MyColors extends ThemeExtension<MyColors>'));
      expect(code, contains('class MyRadius extends ThemeExtension<MyRadius>'));
      expect(
        code,
        contains('class MyShadows extends ThemeExtension<MyShadows>'),
      );
      expect(code, contains('class MyTheme'));
      expect(code, contains('extension MyBuildContext on BuildContext'));
      expect(code, contains('myColors'));
      expect(code, contains('myRadius'));
      expect(code, contains('myShadows'));
    });

    test('ColorScheme maps CSS variables correctly', () {
      // primary → primary
      expect(generatedCode, contains('primary: Color(0xFF171717)'));
      // primary-foreground → onPrimary
      expect(generatedCode, contains('onPrimary: Color(0xFFFAFAFA)'));
      // background → surface
      expect(generatedCode, contains('surface: Color(0xFFFFFFFF)'));
      // foreground → onSurface
      expect(generatedCode, contains('onSurface: Color(0xFF0A0A0A)'));
    });
  });

  group('DartThemeGenerator (fontMode: local)', () {
    test('does not generate google_fonts import in local mode', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Inter', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'local');
      final code = generator.generate();

      expect(code, isNot(contains('google_fonts')));
      expect(code, isNot(contains('GoogleFonts')));
      expect(code, isNot(contains('textTheme:')));
    });

    test('generates fontFamily for single font in local mode', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Inter', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'local');
      final code = generator.generate();

      expect(code, contains("fontFamily: 'Inter'"));
      expect(code, isNot(contains('fontFamilyFallback')));
    });

    test(
      'generates fontFamily and fontFamilyFallback for multiple fonts in local mode',
      () {
        final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Architects Daughter', 'Noto Sans KR', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
        final themeData = CssParser.parse(css);
        final generator = DartThemeGenerator(themeData, fontMode: 'local');
        final code = generator.generate();

        expect(code, contains("fontFamily: 'Architects Daughter'"));
        expect(code, contains("fontFamilyFallback: ['Noto Sans KR']"));
        expect(code, isNot(contains('google_fonts')));
      },
    );

    test('generates multiple fallback fonts in local mode', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Inter', 'Noto Sans KR', 'Noto Sans JP', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'local');
      final code = generator.generate();

      expect(code, contains("fontFamily: 'Inter'"));
      expect(
        code,
        contains("fontFamilyFallback: ['Noto Sans KR', 'Noto Sans JP']"),
      );
    });

    test('does not generate font code for system fonts in local mode', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: ui-sans-serif, system-ui, sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'local');
      final code = generator.generate();

      expect(code, isNot(contains('fontFamily')));
      expect(code, isNot(contains('google_fonts')));
    });

    test('fontFamily appears in both light and dark ThemeData', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'Inter', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'local');
      final code = generator.generate();

      // fontFamily should appear twice (once in light, once in dark)
      final matches = "fontFamily: 'Inter'".allMatches(code).length;
      expect(matches, equals(2));
    });
  });

  group('DartThemeGenerator (fontMode: custom)', () {
    test('does not generate google_fonts import in custom mode', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'My Custom Font', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'custom');
      final code = generator.generate();

      expect(code, isNot(contains('google_fonts')));
      expect(code, isNot(contains('GoogleFonts')));
      expect(code, isNot(contains('textTheme:')));
    });

    test('generates fontFamily for single font in custom mode', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'My Custom Font', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'custom');
      final code = generator.generate();

      expect(code, contains("fontFamily: 'My Custom Font'"));
      expect(code, isNot(contains('fontFamilyFallback')));
    });

    test('generates fontFamily and fontFamilyFallback for multiple fonts', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'My Custom Font', 'Noto Sans KR', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'custom');
      final code = generator.generate();

      expect(code, contains("fontFamily: 'My Custom Font'"));
      expect(code, contains("fontFamilyFallback: ['Noto Sans KR']"));
      expect(code, isNot(contains('google_fonts')));
    });

    test('fontFamily appears in both light and dark ThemeData', () {
      final css = '''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --font-sans: 'My Custom Font', sans-serif;
}
.dark {
  --background: #000000;
  --foreground: #ffffff;
}
''';
      final themeData = CssParser.parse(css);
      final generator = DartThemeGenerator(themeData, fontMode: 'custom');
      final code = generator.generate();

      final matches = "fontFamily: 'My Custom Font'".allMatches(code).length;
      expect(matches, equals(2));
    });
  });

  group('DartThemeGenerator font stack source', () {
    String generateFrom(String css, {String fontMode = 'google_fonts'}) =>
        DartThemeGenerator(CssParser.parse(css), fontMode: fontMode).generate();

    test('uses a font stack declared only in the dark block', () {
      final code = generateFrom('''
:root { --background: #ffffff; }
.dark {
  --background: #000000;
  --font-sans: Inter, sans-serif;
}
''');

      expect(code, contains('GoogleFonts.interTextTheme()'));
    });

    test('prefers the light stack when both declare one', () {
      final code = generateFrom('''
:root { --font-sans: Inter, sans-serif; }
.dark { --font-sans: Roboto, sans-serif; }
''');

      expect(code, contains('GoogleFonts.interTextTheme()'));
      expect(code, isNot(contains('roboto')));
    });

    test('uses a dark-only stack for fontFamily in custom mode', () {
      final code = generateFrom('''
:root { --background: #ffffff; }
.dark { --font-sans: 'My Custom Font', sans-serif; }
''', fontMode: 'custom');

      expect(code, contains("fontFamily: 'My Custom Font'"));
    });

    test('generates no text theme when neither block declares one', () {
      final code = generateFrom(':root { --background: #ffffff; }');

      expect(code, isNot(contains('google_fonts')));
      expect(code, isNot(contains('textTheme:')));
    });
  });

  group('DartThemeGenerator ColorScheme completeness', () {
    // Every parameter Flutter's ColorScheme constructor marks `required`,
    // taken from the resolver rather than hand-copied so the two cannot
    // disagree about what the generator owes. `brightness` is required too but
    // is written straight from the mode, so the resolver does not carry it.
    //
    // No list inside this suite can know that a future Flutter release added a
    // required parameter — the package does not depend on Flutter. That is
    // what `dart run tool/verify_generated_output.dart` is for: it compiles
    // the generated output against the real SDK.
    const requiredParameters = [
      'brightness',
      ...ColorSchemeResolver.requiredProperties,
    ];

    String generateFrom(String css) =>
        DartThemeGenerator(CssParser.parse(css)).generate();

    test('emits every required parameter for a minimal theme', () {
      final code = generateFrom('''
:root {
  --background: #ffffff;
  --primary: #ff0000;
}
''');

      final light = code.substring(
        code.indexOf('const _lightColorScheme'),
        code.indexOf('const _darkColorScheme'),
      );
      for (final parameter in requiredParameters) {
        expect(
          light,
          contains('  $parameter: '),
          reason: '$parameter is required and must always be emitted',
        );
      }
    });

    test('emits every required parameter for a theme with no colors', () {
      final code = generateFrom(':root { --radius: 0.5rem; }');

      for (final scheme in ['_lightColorScheme', '_darkColorScheme']) {
        final start = code.indexOf('const $scheme');
        final block = code.substring(start, code.indexOf(');', start));
        for (final parameter in requiredParameters) {
          expect(
            block,
            contains('  $parameter: '),
            reason: '$parameter missing from $scheme',
          );
        }
      }
    });

    test('reports the tokens it substituted, per mode', () {
      final generator = DartThemeGenerator(
        CssParser.parse('''
:root {
  --background: #ffffff;
  --primary: #ff0000;
}
'''),
      );

      final substituted = generator.substitutedColorSchemeTokens;
      expect(substituted.keys, containsAll(['light', 'dark']));
      expect(substituted['light'], contains('destructive'));
      expect(substituted['light'], isNot(contains('primary')));
      // The dark block is absent entirely, so every token is substituted.
      expect(substituted['dark'], contains('background'));
    });

    test('reports nothing for a theme that defines every token', () {
      final css = File('test/fixtures/sample_hex.css').readAsStringSync();
      final generator = DartThemeGenerator(CssParser.parse(css));

      expect(generator.substitutedColorSchemeTokens, isEmpty);
    });
  });
}

/// The slice of [code] from [start] up to the next [end] after it.
///
/// Lets a test assert about one member of a generated class without matching
/// text that a neighbouring member happens to share.
String _sliceBetween(String code, String start, String end) {
  final from = code.indexOf(start);
  expect(from, isNonNegative, reason: 'generated code has no "$start"');
  final to = code.indexOf(end, from);
  expect(to, isNonNegative, reason: 'no "$end" after "$start"');
  return code.substring(from, to);
}
