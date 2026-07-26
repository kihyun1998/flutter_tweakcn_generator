import 'dart:io';

import 'package:test/test.dart';

import 'cli_harness.dart';

/// End-to-end tests for the `font_exclusive` cleanup step in the CLI.
///
/// These run the real entrypoint in a throwaway project directory, because the
/// decision of *whether* to clean lives in the CLI wiring rather than in the
/// cleanup primitives.
void main() {
  late Directory projectDir;

  setUp(() {
    projectDir = Directory.systemTemp.createTempSync('font_exclusive_cli_');
  });

  tearDown(() {
    projectDir.deleteSync(recursive: true);
  });

  void writeProject({
    required String fontMode,
    required String css,
    bool allowEmpty = false,
  }) {
    File('${projectDir.path}/pubspec.yaml').writeAsStringSync('''
name: demo_app
version: 1.0.0

environment:
  sdk: ^3.0.0

flutter_tweakcn_generator:
  input: theme.css
  output: lib/theme/tweakcn_theme.g.dart
  font_mode: $fontMode
  font_exclusive: true
  font_exclusive_allow_empty: $allowEmpty
  font_dir: fonts

flutter:
  uses-material-design: true
  fonts:
    - family: MyFont
      fonts:
        - asset: fonts/MyFont-Regular.ttf
          weight: 400
''');
    File('${projectDir.path}/theme.css').writeAsStringSync(css);
    Directory('${projectDir.path}/fonts').createSync();
    File(
      '${projectDir.path}/fonts/MyFont-Regular.ttf',
    ).writeAsBytesSync([0, 1, 2]);
  }

  String readPubspec() =>
      File('${projectDir.path}/pubspec.yaml').readAsStringSync();

  bool fontExists() =>
      File('${projectDir.path}/fonts/MyFont-Regular.ttf').existsSync();

  // No `--font-sans` anywhere, so the CLI detects no font families at all.
  const cssNoFontSans = '''
:root {
  --background: #ffffff;
  --primary: #ff0000;
}

.dark {
  --background: #000000;
  --primary: #00ff00;
}
''';

  // `--font-sans` is declared only in `.dark`. It is still the theme's font,
  // so detection finds it and cleanup runs normally.
  const cssFontOnlyInDark = '''
:root {
  --background: #ffffff;
  --primary: #ff0000;
}

.dark {
  --background: #000000;
  --primary: #00ff00;
  --font-sans: Inter, sans-serif;
}
''';

  // A deliberate switch to a pure system font stack: no Google font families,
  // but the user did say what they want. Cleanup should still run.
  const cssSystemFontStack = '''
:root {
  --background: #ffffff;
  --primary: #ff0000;
  --font-sans: ui-sans-serif, system-ui, sans-serif;
}
''';

  // `--font-sans` is present but empty. It parses to a blank string, which is
  // "declared" only in the most literal sense — treat it as undetected.
  const cssBlankFontSans = '''
:root {
  --primary: #ff0000;
  --font-sans: ;
}
''';

  group('font_exclusive cleanup', () {
    for (final fontMode in ['local', 'custom']) {
      group('font_mode: $fontMode', () {
        test('keeps fonts when no font stack was detected', () {
          writeProject(fontMode: fontMode, css: cssNoFontSans);
          final before = readPubspec();

          final result = runGeneratorIn(projectDir);

          expect(result.exitCode, 0);
          expect(fontExists(), isTrue, reason: 'user font files must survive');
          expect(readPubspec(), equals(before));
          expect(result.stderr.toString(), contains('--font-sans'));
        });

        test('keeps fonts when --font-sans is declared but blank', () {
          writeProject(fontMode: fontMode, css: cssBlankFontSans);
          final before = readPubspec();

          final result = runGeneratorIn(projectDir);

          expect(result.exitCode, 0);
          expect(fontExists(), isTrue, reason: 'user font files must survive');
          expect(readPubspec(), equals(before));
          expect(result.stderr.toString(), contains('--font-sans'));
        });

        test('still cleans up when the CSS declares a system font stack', () {
          writeProject(fontMode: fontMode, css: cssSystemFontStack);

          final result = runGeneratorIn(projectDir);

          expect(result.exitCode, 0);
          expect(fontExists(), isFalse);
          expect(readPubspec(), isNot(contains('family: MyFont')));
        });

        test('cleans up with no font stack when allow_empty opts in', () {
          writeProject(
            fontMode: fontMode,
            css: cssNoFontSans,
            allowEmpty: true,
          );

          final result = runGeneratorIn(projectDir);

          expect(result.exitCode, 0);
          expect(fontExists(), isFalse);
          expect(readPubspec(), isNot(contains('family: MyFont')));
        });
      });
    }

    // Only `custom` mode here: `local` would try to download Inter, and these
    // tests must not depend on the network.
    test('cleans up using a font stack declared only in .dark', () {
      writeProject(fontMode: 'custom', css: cssFontOnlyInDark);

      final result = runGeneratorIn(projectDir);

      // Inter is the theme's font; MyFont is not, so it goes.
      expect(result.exitCode, 0);
      expect(fontExists(), isFalse);
      expect(readPubspec(), isNot(contains('family: MyFont')));
    });

    test('cleans up for a system font stack declared only in .dark', () {
      // The riskiest case the dark fallback enables: no Google families
      // resolve, so cleanup deletes everything it manages. A declaration in
      // .dark is still a declaration, so this is intended — but it is
      // unrecoverable under `custom`, and worth pinning.
      writeProject(
        fontMode: 'custom',
        css: '''
:root { --primary: #ff0000; }
.dark { --font-sans: ui-sans-serif, system-ui, sans-serif; }
''',
      );

      final result = runGeneratorIn(projectDir);

      expect(result.exitCode, 0);
      expect(fontExists(), isFalse);
      expect(readPubspec(), isNot(contains('family: MyFont')));
    });

    test('cleans up when light is blank and dark declares a stack', () {
      writeProject(
        fontMode: 'custom',
        css: '''
:root { --font-sans: ; }
.dark { --font-sans: ui-sans-serif, system-ui, sans-serif; }
''',
      );

      final result = runGeneratorIn(projectDir);

      // A blank light declaration names nothing, so dark is the theme's word.
      expect(result.exitCode, 0);
      expect(fontExists(), isFalse);
    });
  });
}
