import 'dart:io';

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

    test('generates TweakcnRadius extension', () {
      expect(
        generatedCode,
        contains('class TweakcnRadius extends ThemeExtension<TweakcnRadius>'),
      );
      expect(generatedCode, contains('static const standard = TweakcnRadius('));
      expect(generatedCode, contains('TweakcnRadius copyWith('));
      expect(generatedCode, contains('TweakcnRadius lerp('));
    });

    test('generates TweakcnShadows extension', () {
      expect(
        generatedCode,
        contains('class TweakcnShadows extends ThemeExtension<TweakcnShadows>'),
      );
      expect(generatedCode, contains('static const light = TweakcnShadows('));
      expect(generatedCode, contains('static const dark = TweakcnShadows('));
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
}
