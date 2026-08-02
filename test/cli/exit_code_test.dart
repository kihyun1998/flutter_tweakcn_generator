import 'dart:io';

import 'package:test/test.dart';

import 'cli_harness.dart';

/// End-to-end tests for what the CLI's exit code promises.
///
/// The rule, from #24: **`0` means the theme is usable as generated.** A run
/// that wrote nothing exits `1`; a run that wrote a theme but could not put
/// something it needs in place exits `2`. Without the middle value a caller
/// reading only the exit code cannot tell "nothing was produced" from "the
/// theme is there and one font is missing", and the downstream builder that
/// reported this had reordered its whole pipeline around the ambiguity.
void main() {
  late Directory projectDir;

  setUp(() {
    projectDir = Directory.systemTemp.createTempSync('exit_code_cli_');
  });

  tearDown(() {
    // The `pub add` case leaves pubspec.yaml read-only, and a read-only file
    // in a writable directory still deletes — but restore it anyway so a
    // failure part-way through cannot leave the temp tree undeletable.
    final pubspec = File('${projectDir.path}/pubspec.yaml');
    if (pubspec.existsSync()) Process.runSync('chmod', ['644', pubspec.path]);
    projectDir.deleteSync(recursive: true);
  });

  void writeProject(String css, {String extraConfig = ''}) {
    File('${projectDir.path}/pubspec.yaml').writeAsStringSync('''
name: demo_app
version: 1.0.0

environment:
  sdk: ^3.0.0

flutter_tweakcn_generator:
  input: theme.css
  output: lib/theme/tweakcn_theme.g.dart
$extraConfig
''');
    File('${projectDir.path}/theme.css').writeAsStringSync(css);
  }

  File generated() => File('${projectDir.path}/lib/theme/tweakcn_theme.g.dart');

  test('exits 0 when the theme is usable as generated', () {
    // A system font stack resolves to no font family, so nothing has to be
    // fetched or declared and the theme stands on its own.
    writeProject('''
:root {
  --background: #ffffff;
  --foreground: #000000;
  --primary: #ff0000;
  --primary-foreground: #ffffff;
  --secondary: #00ff00;
  --secondary-foreground: #000000;
  --destructive: #ff0000;
  --destructive-foreground: #ffffff;
  --font-sans: ui-sans-serif, system-ui, sans-serif;
}
''');

    final result = runGeneratorIn(projectDir);

    expect(result.exitCode, 0);
    expect(generated().existsSync(), isTrue);
  });

  test('exits 1 when it wrote nothing at all', () {
    writeProject('');
    File('${projectDir.path}/theme.css').deleteSync();

    final result = runGeneratorIn(projectDir);

    expect(result.exitCode, 1);
    expect(
      generated().existsSync(),
      isFalse,
      reason: '1 is the value that says nothing was produced',
    );
  });

  test('exits 2 when the theme is written but a font could not be fetched', () {
    // `Segoe UI` is not a Google Font — the API answers 400. With no network
    // the lookup fails differently and the exit code is the same, which is why
    // this asserts the code rather than the message.
    writeProject('''
:root {
  --primary: #ff0000;
  --font-sans: "Segoe UI", sans-serif;
}
''', extraConfig: '  font_mode: local');

    final result = runGeneratorIn(projectDir);

    expect(result.exitCode, 2);
    expect(
      generated().existsSync(),
      isTrue,
      reason: 'the distinction 2 exists to draw: the theme is there',
    );
  });

  // Everything below is a path that reaches its outcome by *throwing*. Without
  // a top-level catch those leave the VM's uncaught-exception code (255),
  // which is not one of the three values this CLI documents — and they land on
  // both sides of the distinction it draws, so the contract cannot be stated
  // truthfully until they are classified like everything else.

  test('exits 1 when the config itself cannot be read', () {
    // `yes` is a YAML string, not a bool. One word in a hand-edited pubspec
    // reaches this, which is why it cannot stay a crash.
    writeProject('''
:root {
  --primary: #ff0000;
}
''', extraConfig: '  font_exclusive: yes');

    final result = runGeneratorIn(projectDir);

    expect(result.exitCode, 1);
    expect(generated().existsSync(), isFalse);
  });

  test(
    'exits 2 when the theme was written but pubspec could not be updated',
    () {
      writeProject('''
:root {
  --primary: #ff0000;
  --font-sans: "Inter", sans-serif;
}
''', extraConfig: '  font_mode: local');
      Process.runSync('chmod', ['444', '${projectDir.path}/pubspec.yaml']);

      final result = runGeneratorIn(projectDir);

      expect(
        result.exitCode,
        2,
        reason:
            'the pubspec write happens after the theme file exists, so this '
            'is the partial case and not the total one',
      );
      expect(generated().existsSync(), isTrue);
    },
    testOn: '!windows',
  );

  test(
    'does not read a commented-out google_fonts line as a declaration',
    () {
      // The guard was a substring test over the whole pubspec text, so a
      // commented-out line suppressed the add entirely and the run came back
      // `0` holding exactly the defect this contract exists to report.
      File('${projectDir.path}/pubspec.yaml').writeAsStringSync('''
name: demo_app
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  # google_fonts: ^8.0.0

flutter_tweakcn_generator:
  input: theme.css
  output: lib/theme/tweakcn_theme.g.dart
''');
      File('${projectDir.path}/theme.css').writeAsStringSync('''
:root {
  --primary: #ff0000;
  --font-sans: "Inter", sans-serif;
}
''');
      // Read-only, so the add is attempted and fails locally rather than
      // reaching the network. Before the fix nothing was attempted at all.
      Process.runSync('chmod', ['444', '${projectDir.path}/pubspec.yaml']);

      final result = runGeneratorIn(projectDir);

      expect(result.exitCode, 2);
    },
    testOn: '!windows',
  );

  test(
    'exits 2 when the google_fonts dependency could not be added',
    () {
      writeProject('''
:root {
  --primary: #ff0000;
  --font-sans: "Inter", sans-serif;
}
''');
      // `dart pub add` cannot even read a pubspec it has no permission to open,
      // so this fails in about a second and never reaches the network.
      Process.runSync('chmod', ['444', '${projectDir.path}/pubspec.yaml']);

      final result = runGeneratorIn(projectDir);

      expect(
        result.exitCode,
        2,
        reason:
            'the generated theme imports package:google_fonts, which is now not '
            'declared — the project cannot resolve, and 0 would call that a '
            'success',
      );
      expect(generated().existsSync(), isTrue);
      expect(
        generated().readAsStringSync(),
        contains('package:google_fonts/google_fonts.dart'),
        reason: 'this is what makes the run partial rather than complete',
      );
    },
    testOn: '!windows',
  );
}
