import 'dart:io';

import 'package:test/test.dart';

import 'cli_harness.dart';

/// End-to-end tests for the warning the CLI prints when it has to substitute
/// a color that `ColorScheme` requires but the theme does not define.
void main() {
  late Directory projectDir;

  setUp(() {
    projectDir = Directory.systemTemp.createTempSync('color_scheme_cli_');
  });

  tearDown(() {
    projectDir.deleteSync(recursive: true);
  });

  void writeProject(String css) {
    // `google_fonts` is declared so the CLI does not try to add it. These
    // tests are about the ColorScheme warning, and one of the fixtures below
    // names a Google font — which sends the run through `dart pub add`, a step
    // that cannot succeed here at all: `google_fonts` depends on `flutter`,
    // and the job that runs this suite deliberately has only a plain Dart SDK.
    // That failure used to be silent, so this file passed without anyone
    // noticing it was exercising the font path; it is an exit code now.
    File('${projectDir.path}/pubspec.yaml').writeAsStringSync('''
name: demo_app
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  google_fonts: ^8.0.0

flutter_tweakcn_generator:
  input: theme.css
  output: lib/theme/tweakcn_theme.g.dart
''');
    File('${projectDir.path}/theme.css').writeAsStringSync(css);
  }

  test('names the missing tokens and the mode they belong to', () {
    writeProject('''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --primary: #ff0000;
}
''');

    final result = runGeneratorIn(projectDir);
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
    writeProject(File('test/fixtures/sample_hex.css').readAsStringSync());

    final result = runGeneratorIn(projectDir);

    expect(result.exitCode, 0);
    expect(result.stderr.toString(), isNot(contains('ColorScheme')));
  });
}
