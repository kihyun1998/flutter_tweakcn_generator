import 'dart:io';

import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';

/// Example: programmatic usage of flutter_tweakcn_generator.
///
/// For typical usage, run:
/// ```
/// dart run flutter_tweakcn_generator
/// ```
void main() {
  // Read CSS file
  final css = File('tweakcn.css').readAsStringSync();

  // Parse CSS
  final themeData = CssParser.parse(css);

  // Generate Dart code
  final generator = DartThemeGenerator(themeData, classPrefix: 'Tweakcn');
  final dartCode = generator.generate();

  // Write output
  File('lib/theme/tweakcn_theme.g.dart')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(dartCode);

  print('Generated theme file!');
  print('Light colors: ${themeData.light.colors.length}');
  print('Dark colors: ${themeData.dark.colors.length}');
}
