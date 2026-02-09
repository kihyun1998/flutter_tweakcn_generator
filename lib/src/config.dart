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

  const TweakcnConfig({
    required this.input,
    required this.output,
    this.classPrefix = 'Tweakcn',
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
    );
  }
}
