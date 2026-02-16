import 'dart:io';

import 'package:flutter_tweakcn_generator/src/config.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final projectDir = Directory.current.path;

  // Read config
  final config = TweakcnConfig.fromPubspec(projectDir);

  // Read CSS
  final cssFile = File(p.join(projectDir, config.input));
  if (!cssFile.existsSync()) {
    stderr.writeln('Error: CSS file not found: ${config.input}');
    stderr
        .writeln('Create ${config.input} or update the path in pubspec.yaml:');
    stderr.writeln('');
    stderr.writeln('flutter_tweakcn_generator:');
    stderr.writeln('  input: your-theme.css');
    exit(1);
  }

  final css = cssFile.readAsStringSync();

  // Parse
  final themeData = CssParser.parse(css);

  // Generate
  final generator = DartThemeGenerator(
    themeData,
    classPrefix: config.classPrefix,
  );
  final dartCode = generator.generate();

  // Write output
  final outputFile = File(p.join(projectDir, config.output));
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(dartCode);

  // Auto-add google_fonts dependency if needed
  if (dartCode.contains("package:google_fonts/google_fonts.dart")) {
    final pubspecFile = File(p.join(projectDir, 'pubspec.yaml'));
    final pubspecContent = pubspecFile.readAsStringSync();
    if (!pubspecContent.contains('google_fonts:')) {
      stdout.writeln('Adding google_fonts dependency...');
      final result = Process.runSync(
        'dart',
        ['pub', 'add', 'google_fonts'],
        workingDirectory: projectDir,
      );
      if (result.exitCode == 0) {
        stdout.writeln('  Added google_fonts to pubspec.yaml');
      } else {
        stderr.writeln(
          '  Failed to add google_fonts. Run manually: dart pub add google_fonts',
        );
      }
    }
  }

  stdout.writeln('Generated: ${config.output}');
  stdout.writeln(
    '  Colors: ${themeData.light.colors.length} light, '
    '${themeData.dark.colors.length} dark',
  );
  stdout.writeln(
    '  Shadows: ${themeData.light.shadows.length} light, '
    '${themeData.dark.shadows.length} dark',
  );
  stdout.writeln(
    '  Radius: ${themeData.light.radius ?? themeData.dark.radius ?? "default"}',
  );
}
