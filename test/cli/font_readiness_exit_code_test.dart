import 'dart:io';

import 'package:test/test.dart';

import 'cli_harness.dart';

/// What the exit code says about whether the theme's fonts are actually there.
///
/// #24 set the rule — **`0` means the theme is usable as generated** — and #28
/// found it broken on *both* sides of one axis: a run whose fonts were entirely
/// in place reported `2` because a lookup failed, and a run whose theme named a
/// family with nothing behind it reported `0`.
///
/// The fix is one gate rather than two patches: the exit code is decided by
/// whether the theme ends up short of a font, not by whether an incident
/// happened on the way. These tests are that gate's contract.
///
/// The lookup is failed by pointing `https_proxy` at a port nothing listens on.
/// `HttpClient` honours it, so this is a real failed lookup and needs no
/// network — and it is the *transient* shape (a reachable family, an
/// unreachable network), which is the one a re-run actually hits.
void main() {
  late Directory projectDir;

  /// A proxy nothing listens on, so the CSS lookup fails without a network.
  final offline = {
    ...Platform.environment,
    'https_proxy': 'http://127.0.0.1:1',
    'http_proxy': 'http://127.0.0.1:1',
  };

  setUp(() {
    projectDir = Directory.systemTemp.createTempSync('font_ready_cli_');
  });

  tearDown(() => projectDir.deleteSync(recursive: true));

  void writeProject(
    String fontMode, {
    String fontSans = '"Inter"',
    String pubspecFonts = '',
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
  font_dir: fonts
$pubspecFonts''');
    File('${projectDir.path}/theme.css').writeAsStringSync('''
:root {
  --primary: #ff0000;
  --font-sans: $fontSans;
}
''');
  }

  /// Puts [fileName] in the project's fonts directory.
  ///
  /// Contents are never parsed on this path — only the file's existence and
  /// what pubspec says it belongs to decide whether a family is ready.
  void placeFont(String fileName) {
    Directory('${projectDir.path}/fonts').createSync(recursive: true);
    File(
      '${projectDir.path}/fonts/$fileName',
    ).writeAsBytesSync(List.filled(2048, 7));
  }

  String declares(String family, String fileName) => '''
flutter:
  fonts:
    - family: $family
      fonts:
        - asset: fonts/$fileName
          weight: 400
''';

  File generated() => File('${projectDir.path}/lib/theme/tweakcn_theme.g.dart');

  group('a font that is already in place', () {
    // #28's first half. The theme is complete before the run even starts; a
    // failed lookup changes nothing about whether it can be used.
    test('exits 0 when the lookup fails but the font is declared and on '
        'disk', () {
      writeProject(
        'local',
        pubspecFonts: declares('Inter', 'Inter-Regular.ttf'),
      );
      placeFont('Inter-Regular.ttf');

      final result = runGeneratorIn(projectDir, environment: offline);

      expect(
        result.exitCode,
        0,
        reason: 'nothing the theme needs is missing, so the run is not partial',
      );
      expect(generated().existsSync(), isTrue);
      // Side condition: the lookup really did fail, so a green here cannot
      // come from the request having quietly succeeded.
      expect(result.stderr, contains('could not look up'));
    });

    test('still says on stderr that the lookup failed', () {
      writeProject(
        'local',
        pubspecFonts: declares('Inter', 'Inter-Regular.ttf'),
      );
      placeFont('Inter-Regular.ttf');

      final result = runGeneratorIn(projectDir, environment: offline);

      expect(
        result.stderr,
        contains('Inter'),
        reason: 'the exit code stops reporting it; the diagnostics must not',
      );
    });
  });

  group('a font that is not in place', () {
    // #28's second half, custom mode: the scanner already warns, but the exit
    // code used to say the run was clean.
    test('exits 2 when custom mode finds no file for the family', () {
      writeProject('custom');

      final result = runGeneratorIn(projectDir);

      expect(
        result.exitCode,
        2,
        reason: 'the theme names Inter and nothing in the project provides it',
      );
      expect(generated().existsSync(), isTrue);
      expect(
        File('${projectDir.path}/pubspec.yaml').readAsStringSync(),
        isNot(contains('family: Inter')),
      );
    });

    test('exits 2 when the lookup fails and nothing is on disk', () {
      writeProject('local');

      final result = runGeneratorIn(projectDir, environment: offline);

      expect(result.exitCode, 2);
      expect(generated().existsSync(), isTrue);
    });

    // A file on disk that pubspec never declares does not load at runtime:
    // Flutter resolves fonts through the manifest, not the directory. In local
    // mode a failed lookup means nothing declares it either, so the file being
    // there must not be mistaken for the family being ready.
    test('exits 2 when the file is on disk but nothing declares it', () {
      writeProject('local');
      placeFont('Inter-Regular.ttf');

      final result = runGeneratorIn(projectDir, environment: offline);

      expect(
        result.exitCode,
        2,
        reason: 'an undeclared file is not a loadable font',
      );
      expect(
        File('${projectDir.path}/pubspec.yaml').readAsStringSync(),
        isNot(contains('family: Inter')),
      );
    });
  });

  group('the families are checked one by one', () {
    // The case neither #28 nor its measurement covered: a stack where one
    // family is ready and one is not. Merging the reports hides it; checking
    // each family does not.
    test('exits 2 when one family of a stack is missing', () {
      writeProject(
        'custom',
        fontSans: '"Inter", "Roboto Slab"',
        pubspecFonts: declares('Inter', 'Inter-Regular.ttf'),
      );
      placeFont('Inter-Regular.ttf');

      final result = runGeneratorIn(projectDir);

      expect(
        result.exitCode,
        2,
        reason: 'Roboto Slab is named by the theme and provided by nothing',
      );
    });

    test('exits 0 when every family of a stack is ready', () {
      writeProject(
        'custom',
        fontSans: '"Inter", "Roboto Slab"',
        pubspecFonts: '''
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
    - family: Roboto Slab
      fonts:
        - asset: fonts/RobotoSlab-Regular.ttf
          weight: 400
''',
      );
      placeFont('Inter-Regular.ttf');
      placeFont('RobotoSlab-Regular.ttf');

      final result = runGeneratorIn(projectDir);

      expect(result.exitCode, 0);
    });
  });

  group('modes the gate must not touch', () {
    test('a system font stack needs no font at all and exits 0', () {
      writeProject('local', fontSans: 'ui-sans-serif, system-ui, sans-serif');

      final result = runGeneratorIn(projectDir, environment: offline);

      expect(
        result.exitCode,
        0,
        reason: 'no family is named, so nothing can be missing',
      );
    });

    test('google_fonts mode needs no declared asset', () {
      writeProject('google_fonts');

      final result = runGeneratorIn(projectDir);

      expect(
        result.exitCode,
        anyOf(0, 2),
        reason:
            'whatever this is, it must not be decided by the asset gate — '
            'google_fonts themes carry no font files, and the only thing that '
            'may set 2 here is the pub add path',
      );
      // The gate must not be what fails it: no asset-missing message.
      expect(result.stderr, isNot(contains('no font file')));
    });
  });
}
