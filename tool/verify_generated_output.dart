/// Checks that the code this package generates actually compiles.
///
/// The package generates Flutter source but does not depend on Flutter, so
/// nothing in `dart test` can tell whether its output builds. This script
/// closes that gap: it generates a file for each of the theme shapes that
/// stress the generator differently, drops them into the example app — the one
/// place in the repo where `package:flutter` resolves — and analyzes them
/// there.
///
/// Run it from the package root:
///
/// ```
/// dart run tool/verify_generated_output.dart
/// ```
///
/// It exits non-zero and prints the analyzer's own output when any case fails,
/// and removes everything it wrote either way.
///
/// The analyzer is invoked as `dart analyze` from inside the example app
/// rather than as `flutter analyze`. Both run the same engine against the same
/// resolved packages, but `flutter analyze` also regenerates the platform
/// plugin registrants, which are checked in — it would leave the example app
/// dirty on every run. It does need the example app's packages to be resolved
/// already; the script says so rather than resolving them itself.
///
/// It runs whichever `dart` is on the PATH. On a machine where that is a
/// standalone SDK rather than the one bundled with Flutter, the two can differ
/// by a language version — worth knowing if a result here disagrees with the
/// IDE.
library;

import 'dart:io';

import 'package:flutter_tweakcn_generator/src/config.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:path/path.dart' as p;

/// One CSS input whose generated output must compile.
class VerificationCase {
  /// `snake_case` name, used as the generated file's base name.
  final String name;

  /// Why this shape is worth compiling — what it breaks if the generator gets
  /// it wrong.
  final String rationale;

  /// The tweakcn CSS to generate from.
  final String css;

  /// The font mode to generate under: `'google_fonts'`, `'local'`, or
  /// `'custom'`.
  ///
  /// The mode decides how the theme class names its font, and each way it can
  /// name one is a separate thing that has to compile.
  final String fontMode;

  const VerificationCase({
    required this.name,
    required this.rationale,
    required this.css,
    this.fontMode = 'google_fonts',
  });
}

/// The Dart source [verificationCase] must compile to.
String generateCase(VerificationCase verificationCase) =>
    DartThemeGenerator(
      CssParser.parse(verificationCase.css),
      fontMode: verificationCase.fontMode,
    ).generate();

/// The directory, relative to the example app, that generated cases are
/// written to.
///
/// Deliberately not dot-prefixed: the Dart analyzer skips hidden directories,
/// so a hidden scratch directory would make this check pass without having
/// analyzed anything.
const generatedCaseDirName = 'tweakcn_verify';

/// The example app, relative to the package root. The only package in the repo
/// where `package:flutter` and `package:google_fonts` resolve.
const exampleDirName = 'example';

/// The theme shapes the generated output must compile for, in increasing order
/// of degeneracy.
///
/// [repoRoot] is the package root, which holds the complete-theme fixture.
List<VerificationCase> verificationCases(Directory repoRoot) => [
  VerificationCase(
    name: 'complete_theme',
    rationale: 'every mapped token defined, in both modes',
    // The same fixture the unit tests assert their goldens against, so the
    // code those goldens describe is the code that gets compiled.
    css:
        File(
          p.join(repoRoot.path, 'test', 'fixtures', 'sample_hex.css'),
        ).readAsStringSync(),
  ),
  const VerificationCase(
    name: 'minimal_theme',
    rationale: 'most required ColorScheme tokens substituted, not defined',
    css: '''
:root {
  --background: #ffffff;
  --primary: #ff0000;
}
''',
  ),
  const VerificationCase(
    name: 'color_free_theme',
    rationale: 'every ColorScheme parameter substituted; no color at all',
    css: '''
:root {
  --radius: 0.5rem;
}
''',
  ),
  const VerificationCase(
    name: 'dark_only_theme',
    rationale: 'light mode entirely absent, including its font stack',
    css: '''
.dark {
  --background: #0a0a0a;
  --foreground: #fafafa;
  --primary: #fafafa;
  --font-sans: 'Inter', sans-serif;
  --radius: 0.625rem;
}
''',
  ),
  // The cases above all name at most one font under the default mode, which
  // leaves most of the font emission uncompiled. The unit tests do reach those
  // branches, but they compare the emitted text against text — they cannot
  // tell a balanced `.apply(...)` from an unbalanced one, or a real
  // `GoogleFonts` method from a plausible-looking name.
  const VerificationCase(
    name: 'google_font_fallback_theme',
    rationale: 'two Google Fonts: the generated .apply() fallback chain',
    css: '''
:root {
  --background: #ffffff;
  --primary: #171717;
  --font-sans: 'Architects Daughter', 'Noto Sans KR', sans-serif;
}
''',
  ),
  const VerificationCase(
    name: 'local_font_theme',
    rationale: 'two local fonts: fontFamily and fontFamilyFallback, no import',
    fontMode: 'local',
    css: '''
:root {
  --background: #ffffff;
  --primary: #171717;
  --font-sans: 'Architects Daughter', 'Noto Sans KR', sans-serif;
}
''',
  ),
];

/// Why the example's committed theme no longer matches what the generator
/// writes for it, or null when it still does.
///
/// The example is meant to show what a consumer's output looks like, so it is
/// committed exactly as generated. Nothing else notices when a change to the
/// emitted code leaves it behind — it compiles either way, and the difference
/// only turns up as an unexplained diff in someone's working tree.
String? staleExampleTheme(Directory exampleDir) {
  final config = TweakcnConfig.fromPubspec(exampleDir.path);
  final css = File(p.join(exampleDir.path, config.input));
  final committed = File(p.join(exampleDir.path, config.output));
  // Reported rather than skipped: a check that quietly passes when it cannot
  // find what it compares is worse than no check.
  if (!css.existsSync()) return 'No ${config.input} in $exampleDirName/.';
  if (!committed.existsSync()) {
    return 'No ${config.output} in $exampleDirName/ to compare against.';
  }

  final expected =
      DartThemeGenerator(
        CssParser.parse(css.readAsStringSync()),
        classPrefix: config.classPrefix,
        fontMode: config.fontMode,
      ).generate();

  if (committed.readAsStringSync().replaceAll('\r\n', '\n') ==
      expected.replaceAll('\r\n', '\n')) {
    return null;
  }
  return 'The example theme at ${config.output} is not what the generator '
      'now writes for ${config.input}.\n'
      'Regenerate it: cd $exampleDirName && dart run flutter_tweakcn_generator';
}

/// Generates [cases] into [target], one file each, and returns what it wrote.
///
/// [target] is emptied first, so a run never analyzes a file left behind by an
/// earlier one.
List<File> writeGeneratedCases(Directory target, List<VerificationCase> cases) {
  if (target.existsSync()) target.deleteSync(recursive: true);
  target.createSync(recursive: true);

  return [
    for (final verificationCase in cases)
      File(p.join(target.path, '${verificationCase.name}.g.dart'))
        ..writeAsStringSync(generateCase(verificationCase)),
  ];
}

int _run(Directory repoRoot) {
  final exampleDir = Directory(p.join(repoRoot.path, exampleDirName));
  if (!exampleDir.existsSync()) {
    stderr.writeln(
      'No $exampleDirName/ directory. Run this from the package root.',
    );
    return 1;
  }
  if (!File(
    p.join(exampleDir.path, '.dart_tool', 'package_config.json'),
  ).existsSync()) {
    stderr.writeln(
      "The example app's packages are not resolved, so package:flutter would "
      'not resolve and every case would fail for the wrong reason.\n'
      'Run `flutter pub get` in $exampleDirName/ first.',
    );
    return 1;
  }

  final stale = staleExampleTheme(exampleDir);
  if (stale != null) {
    stderr.writeln(stale);
    return 1;
  }

  final cases = verificationCases(repoRoot);
  final target = Directory(p.join(exampleDir.path, generatedCaseDirName));

  try {
    final written = writeGeneratedCases(target, cases);
    for (final verificationCase in cases) {
      stdout.writeln(
        '  ${verificationCase.name}  — ${verificationCase.rationale}',
      );
    }
    stdout.writeln(
      '\nAnalyzing ${written.length} generated files against Flutter...\n',
    );

    // `--fatal-infos` because a lint the generator emits reaches every
    // consumer's project, where they cannot fix it by hand.
    final ProcessResult result;
    try {
      result = Process.runSync(
        'dart',
        ['analyze', '--fatal-infos', generatedCaseDirName],
        workingDirectory: exampleDir.path,
        runInShell: Platform.isWindows,
      );
    } on ProcessException catch (e) {
      // Every other precondition failure here prints a sentence; a missing
      // `dart` should not be the one that prints a stack trace.
      stderr.writeln('Could not run the analyzer: ${e.message}');
      return 1;
    }

    if (result.exitCode == 0) {
      stdout.writeln('All ${written.length} generated files compile.');
      return 0;
    }

    // The analyzer's own message is the useful part — reprint it verbatim
    // rather than summarizing it away.
    stderr.writeln('Generated output does not compile:\n');
    stderr.write(result.stdout);
    stderr.write(result.stderr);
    return result.exitCode;
  } finally {
    if (target.existsSync()) target.deleteSync(recursive: true);
  }
}

void main() {
  exitCode = _run(Directory.current);
}
