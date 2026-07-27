import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:flutter_tweakcn_generator/builder.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:test/test.dart';

const _css = '''
:root {
  --background: #ffffff;
  --foreground: #0a0a0a;
  --primary: #171717;
  --font-sans: 'Inter', sans-serif;
  --radius: 0.625rem;
}
''';

void main() {
  /// Runs the builder over one CSS asset and asserts on what it wrote.
  ///
  /// Goes through [tweakcnBuilder] rather than constructing the builder
  /// directly, so the options `build.yaml` carries are part of what is under
  /// test. `outputs` also fails on an output the builder did not declare,
  /// which is the shape of failure this whole file exists for.
  Future<void> expectBuilds(
    Object expected, {
    Map<String, dynamic> options = const {},
  }) => testBuilder(
    tweakcnBuilder(BuilderOptions(options)),
    const {'a|lib/app.tweakcn.css': _css},
    outputs: {'a|lib/app.tweakcn.dart': expected},
  );

  group('TweakcnBuilder', () {
    test('writes the theme beside the CSS, named as it declares it will', () {
      // `build_extensions` says `.tweakcn.css` becomes `.tweakcn.dart`, and
      // build_runner rejects an output a builder did not declare — so a
      // wrongly named output is not a misnamed file, it is no file at all.
      return expectBuilds(decodedMatches(contains('class TweakcnColors')));
    });

    test('writes what the generator writes for the same CSS', () {
      return expectBuilds(DartThemeGenerator(CssParser.parse(_css)).generate());
    });

    test('carries class_prefix from build.yaml into the output', () {
      return expectBuilds(
        decodedMatches(contains('class MyColors')),
        options: {'class_prefix': 'My'},
      );
    });

    test('carries font_mode from build.yaml into the output', () {
      // `local` is the mode that stops the theme importing google_fonts, so
      // it is the one whose arrival is visible in the output.
      return expectBuilds(
        decodedMatches(
          allOf(
            isNot(contains('google_fonts')),
            contains("fontFamily: 'Inter'"),
          ),
        ),
        options: {'font_mode': 'local'},
      );
    });
  });
}
