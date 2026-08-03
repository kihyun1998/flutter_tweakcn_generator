import 'dart:io';

import 'package:test/test.dart';

import 'cli_harness.dart';

/// End-to-end tests for the warning the CLI prints when light and dark name
/// different font stacks, only one of which can reach the generated theme.
void main() {
  late Directory projectDir;

  setUp(() {
    projectDir = Directory.systemTemp.createTempSync('font_sans_conflict_');
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
  font_mode: custom
''');
    File('${projectDir.path}/theme.css').writeAsStringSync(css);
  }

  test('names both stacks and which one is used', () {
    writeProject('''
:root { --font-sans: Inter, sans-serif; }
.dark { --font-sans: Roboto, sans-serif; }
''');

    final result = runGeneratorIn(projectDir);
    final stderrText = result.stderr.toString();

    // `2`, not `0`: this project provides no Inter, so the theme names a
    // family nothing declares. That is #28's report, and this assertion used
    // to freeze the behavior it was about — the exit code is incidental here,
    // the warning below is what this test is for.
    expect(result.exitCode, 2);
    expect(stderrText, contains('different --font-sans'));
    expect(stderrText, contains('Inter, sans-serif'));
    expect(stderrText, contains('Roboto, sans-serif'));
  });

  test('stays quiet when the two modes agree', () {
    writeProject('''
:root { --font-sans: Inter, sans-serif; }
.dark { --font-sans: Inter, sans-serif; }
''');

    expect(
      runGeneratorIn(projectDir).stderr.toString(),
      isNot(contains('different --font-sans')),
    );
  });

  test('stays quiet when the two stacks name the same family', () {
    // Different CSS text, same font: nothing is actually dropped.
    writeProject('''
:root { --font-sans: 'Inter', sans-serif; }
.dark { --font-sans: Inter,sans-serif; }
''');

    expect(
      runGeneratorIn(projectDir).stderr.toString(),
      isNot(contains('different --font-sans')),
    );
  });

  test('stays quiet when only one mode declares a stack', () {
    writeProject('''
:root { --primary: #ff0000; }
.dark { --font-sans: Inter, sans-serif; }
''');

    expect(
      runGeneratorIn(projectDir).stderr.toString(),
      isNot(contains('different --font-sans')),
    );
  });
}
