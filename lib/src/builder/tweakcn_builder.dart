import 'dart:async';

import 'package:build/build.dart';

import '../generator/dart_theme_generator.dart';
import '../parser/css_parser.dart';

/// A [Builder] that converts `.tweakcn.css` files to `.tweakcn.dart` files.
class TweakcnBuilder implements Builder {
  final String classPrefix;

  TweakcnBuilder({this.classPrefix = 'Tweakcn'});

  @override
  Map<String, List<String>> get buildExtensions => {
        '.tweakcn.css': ['.tweakcn.dart'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final css = await buildStep.readAsString(inputId);

    final themeData = CssParser.parse(css);
    final generator = DartThemeGenerator(themeData, classPrefix: classPrefix);
    final dartCode = generator.generate();

    final outputId = inputId.changeExtension('.tweakcn.dart');
    await buildStep.writeAsString(outputId, dartCode);
  }
}
