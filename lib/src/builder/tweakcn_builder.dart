import 'dart:async';

import 'package:build/build.dart';

import '../generator/dart_theme_generator.dart';
import '../parser/css_parser.dart';

/// A [Builder] that converts `.tweakcn.css` files to `.tweakcn.dart` files.
class TweakcnBuilder implements Builder {
  final String classPrefix;
  final String fontMode;

  TweakcnBuilder({
    this.classPrefix = 'Tweakcn',
    this.fontMode = 'google_fonts',
  });

  @override
  Map<String, List<String>> get buildExtensions => {
    '.tweakcn.css': ['.tweakcn.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final css = await buildStep.readAsString(inputId);

    final themeData = CssParser.parse(css);
    final generator = DartThemeGenerator(
      themeData,
      classPrefix: classPrefix,
      fontMode: fontMode,
    );
    final dartCode = generator.generate();

    // `.dart`, not `.tweakcn.dart`: [buildExtensions] names the whole suffix
    // that replaces `.tweakcn.css`, while `changeExtension` replaces only the
    // last one. Handing it the whole suffix leaves `.tweakcn` in twice, and
    // build_runner refuses an output the builder never declared — so the
    // build failed outright rather than writing a misnamed file.
    final outputId = inputId.changeExtension('.dart');
    await buildStep.writeAsString(outputId, dartCode);
  }
}
