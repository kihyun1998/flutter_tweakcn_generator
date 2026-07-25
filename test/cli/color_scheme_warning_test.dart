import 'dart:io';

import 'package:test/test.dart';

/// End-to-end tests for the warning the CLI prints when it has to substitute
/// a color that `ColorScheme` requires but the theme does not define.
void main() {
  final repoRoot = Directory.current.path;
  final packageConfig = '$repoRoot/.dart_tool/package_config.json';

  late Directory projectDir;

  setUp(() {
    projectDir = Directory.systemTemp.createTempSync('color_scheme_cli_');
  });

  tearDown(() {
    projectDir.deleteSync(recursive: true);
  });

  void writeProject(String css) {
    File('${projectDir.path}/pubspec.yaml').writeAsStringSync('''
name: demo_app
version: 1.0.0

environment:
  sdk: ^3.0.0

flutter_tweakcn_generator:
  input: theme.css
  output: lib/theme/tweakcn_theme.g.dart
''');
    File('${projectDir.path}/theme.css').writeAsStringSync(css);
  }

  ProcessResult runGenerator() {
    return Process.runSync('dart', [
      'run',
      '--packages=$packageConfig',
      '$repoRoot/bin/flutter_tweakcn_generator.dart',
    ], workingDirectory: projectDir.path);
  }

  test('names the missing tokens and the mode they belong to', () {
    writeProject('''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --primary: #ff0000;
}
''');

    final result = runGenerator();
    final lines = result.stderr.toString().split('\n');

    expect(result.exitCode, 0);

    final light = lines.firstWhere((l) => l.contains('light theme'));
    expect(light, contains('--destructive'));
    expect(light, contains('--secondary'));
    // The light block defines these, so they must not be reported.
    expect(light, isNot(contains('--primary,')));
    expect(light, isNot(contains('--background')));

    // The CSS has no .dark block at all, so every token is reported there.
    final dark = lines.firstWhere((l) => l.contains('dark theme'));
    expect(dark, contains('--background'));
    expect(dark, contains('--primary,'));
  });

  test('stays quiet for a theme that defines every required token', () {
    writeProject(
      File('$repoRoot/test/fixtures/sample_hex.css').readAsStringSync(),
    );

    final result = runGenerator();

    expect(result.exitCode, 0);
    expect(result.stderr.toString(), isNot(contains('ColorScheme')));
  });
}
