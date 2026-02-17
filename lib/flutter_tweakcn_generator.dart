/// A code generator that converts [tweakcn](https://tweakcn.com) CSS themes
/// into Flutter `ThemeData`, `ColorScheme`, and `ThemeExtension` classes.
///
/// ## Usage
///
/// 1. Parse CSS with [CssParser.parse] to get [TweakcnThemeData].
/// 2. Generate Dart code with [DartThemeGenerator.generate].
///
/// Or use the CLI: `dart run flutter_tweakcn_generator`
library;

export 'src/config.dart';
export 'src/font/font_downloader.dart';
export 'src/font/pubspec_font_adder.dart';
export 'src/generator/dart_theme_generator.dart';
export 'src/models/tweakcn_theme_data.dart';
export 'src/parser/color_parser.dart';
export 'src/parser/css_parser.dart';
export 'src/parser/shadow_parser.dart';
