import 'dart:async';

import 'package:build/build.dart';

import '../generator/dart_theme_generator.dart';
import '../generator/language_version.dart';
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

    // The consumer's own pubspec, read as an asset: `dart format` run in their
    // project uses the language version it declares, and output formatted at
    // any other one fails their format check.
    final pubspec = AssetId(inputId.package, 'pubspec.yaml');
    final languageVersion =
        await buildStep.canRead(pubspec)
            ? languageVersionFromPubspec(await buildStep.readAsString(pubspec))
            : null;

    final themeData = CssParser.parse(css);
    final generator = DartThemeGenerator(
      themeData,
      classPrefix: classPrefix,
      fontMode: fontMode,
      languageVersion: languageVersion,
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
