import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration for flutter_tweakcn_generator, read from pubspec.yaml.
class TweakcnConfig {
  /// Path to the input CSS file.
  final String input;

  /// Path to the output Dart file.
  final String output;

  /// Class name prefix for generated classes.
  final String classPrefix;

  /// Font mode:
  /// - `'google_fonts'` uses the google_fonts package at runtime.
  /// - `'local'` downloads .ttf files from Google Fonts and uses `fontFamily`.
  /// - `'custom'` uses user-provided .ttf files from [fontDir] without
  ///   downloading from Google Fonts.
  final String fontMode;

  /// When `true` and [fontMode] is `'local'`, removes font files and
  /// pubspec.yaml font declarations that are not defined in `--font-sans`.
  final bool fontExclusive;

  /// When `true`, [fontExclusive] cleanup also runs when the CSS declares no
  /// `--font-sans` at all, deleting every font file and declaration.
  ///
  /// Off by default: a missing `--font-sans` is usually a parsing miss rather
  /// than a request to delete everything, and under `fontMode` `'custom'` the
  /// deleted files are user-provided and cannot be recovered. A CSS file that
  /// declares a system font stack (`ui-sans-serif, system-ui, ...`) is already
  /// cleaned up without this flag — that is a stated intent, not a blank.
  final bool fontExclusiveAllowEmpty;

  /// Directory where local font .ttf files are stored (relative to project root).
  final String fontDir;

  const TweakcnConfig({
    required this.input,
    required this.output,
    this.classPrefix = 'Tweakcn',
    this.fontMode = 'google_fonts',
    this.fontExclusive = false,
    this.fontExclusiveAllowEmpty = false,
    this.fontDir = 'fonts',
  });

  /// Reads configuration from pubspec.yaml in the given [projectDir].
  ///
  /// Looks for a `flutter_tweakcn_generator` key:
  /// ```yaml
  /// flutter_tweakcn_generator:
  ///   input: tweakcn.css
  ///   output: lib/theme/tweakcn_theme.g.dart
  ///   class_prefix: Tweakcn
  /// ```
  static TweakcnConfig fromPubspec(String projectDir) {
    final pubspecFile = File('$projectDir/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      throw StateError('pubspec.yaml not found in $projectDir');
    }

    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;
    if (yaml == null) {
      throw StateError('Invalid pubspec.yaml');
    }

    final config = yaml['flutter_tweakcn_generator'] as YamlMap?;

    return TweakcnConfig(
      input: config?['input'] as String? ?? 'tweakcn.css',
      output: config?['output'] as String? ?? 'lib/theme/tweakcn_theme.g.dart',
      classPrefix: config?['class_prefix'] as String? ?? 'Tweakcn',
      fontMode: config?['font_mode'] as String? ?? 'google_fonts',
      fontExclusive: config?['font_exclusive'] as bool? ?? false,
      fontExclusiveAllowEmpty:
          config?['font_exclusive_allow_empty'] as bool? ?? false,
      fontDir: config?['font_dir'] as String? ?? 'fonts',
    );
  }
}
