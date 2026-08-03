import 'dart:io';

import 'package:flutter_tweakcn_generator/src/config.dart';
import 'package:flutter_tweakcn_generator/src/font/font_cleanup.dart';
import 'package:flutter_tweakcn_generator/src/font/custom_font_scanner.dart';
import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_adder.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_declarations.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/generator/language_version.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The run wrote nothing: there is no theme to use.
///
/// See [_exitPartial] for the rule that separates the two failure values.
const _exitNothingGenerated = 1;

/// The theme was written, but something it needs is not in place.
///
/// **`0` means the theme is usable as generated.** That is the whole rule; the
/// two non-zero values only say which side of it a run fell on. A caller that
/// reads nothing but the exit code can then tell "no theme was produced" from
/// "the theme is there and one font is missing" — a distinction the single `1`
/// this CLI used to return could not carry, and one that costs real work
/// downstream: a builder driving this CLI as a pipeline step had moved the
/// step to the end of its pipeline, because a single font failure looked
/// exactly like total failure and skipped everything after it.
///
/// The value is `2` rather than something from `sysexits` (64–78, mirrored by
/// `package:io`'s `ExitCode`) because none of those categories means "partial
/// success", and this CLI already answers `1`. Nothing standard is at stake:
/// the shell reserves `126`, `127` and `128+N`, and `1`–`63` are unassigned.
///
/// Note that `2` is *not* "worse than [_exitNothingGenerated]" — exit codes
/// are categories, not a scale. Keeping the hard failure on `1` is deliberate:
/// a caller already branching on `1` keeps catching the case it cared about.
const _exitPartial = 2;

/// Set once the theme file is on disk, so a failure after that point can be
/// reported as partial rather than total.
var _themeWritten = false;

/// Which of [families] the generated theme names but the project cannot load.
///
/// Readiness is **what `pubspec.yaml` declares**, not what sits in the fonts
/// directory: Flutter resolves a family through the asset manifest, so a file
/// nothing declares is not a font, and a family nothing declares falls back to
/// the default at runtime without an error anywhere. That silence is the whole
/// reason the exit code has to say it.
///
/// Deliberately *not* checked: whether each declared asset is still on disk.
/// A declaration pointing at a missing file fails the next Flutter build
/// loudly, naming the file — so the exit code adds nothing there, while
/// checking it would mean reconstructing asset paths that
/// [PubspecFontDeclarations] does not keep (it holds file names, not
/// directories) and would answer a false "missing" for any declaration
/// pointing outside `font_dir`. **This holds as long as declarations keep
/// coming from `PubspecFontAdder`, which declares only files it just wrote.**
///
/// Family names are matched exactly. Flutter's own manifest lookup is exact,
/// so treating `inter` and `Inter` as the same family would report a font as
/// ready that will not load.
List<String> _familiesTheProjectCannotLoad(
  List<String> families,
  String projectDir,
) {
  final declared =
      PubspecFontDeclarations.read(
        p.join(projectDir, 'pubspec.yaml'),
      ).families.toSet();
  return [
    for (final family in families)
      if (!declared.contains(family)) family,
  ];
}

/// Whether [pubspecContent] already declares `google_fonts` as a dependency.
///
/// Parsed rather than searched for as text. A substring test over the whole
/// file answered yes to a *commented-out* `# google_fonts:` line — and to one
/// under any other key — which suppressed the add entirely and left the run
/// reporting success while the generated theme imported a package the project
/// did not declare. That is the exact defect the exit codes above exist to
/// report, arriving through the one door that skipped them.
///
/// `dependency_overrides` and `dev_dependencies` count: `dart pub add` refuses
/// a package already named in any of them, so trying anyway would turn a
/// resolvable project into a reported failure.
bool _declaresGoogleFonts(String pubspecContent) {
  final doc = loadYaml(pubspecContent);
  if (doc is! YamlMap) return false;
  for (final section in const [
    'dependencies',
    'dev_dependencies',
    'dependency_overrides',
  ]) {
    final deps = doc[section];
    if (deps is YamlMap && deps.containsKey('google_fonts')) return true;
  }
  return false;
}

Future<void> main(List<String> args) async {
  try {
    await _run();
  } catch (error, stackTrace) {
    // Whatever reaches here is unplanned, and most of it is not exotic: a
    // config value of the wrong YAML type (`font_exclusive: yes` is a
    // *string*), an output path that cannot be created, a pubspec this
    // process may not rewrite, no `dart` on PATH. Left uncaught, every one of
    // them exits 255 — a fourth value the two constants above, the README and
    // the changelog all say does not exist. Worse, they land on *both* sides
    // of the line those values draw: some throw before the theme is written
    // and some after, so the one distinction this CLI promises to make would
    // be the one thing it stopped making.
    //
    // The stack trace goes out too. These are unexpected by construction, so
    // the trace is the useful half of the report.
    stderr.writeln('Error: $error');
    stderr.writeln(stackTrace);
    exit(_themeWritten ? _exitPartial : _exitNothingGenerated);
  }
}

Future<void> _run() async {
  final projectDir = Directory.current.path;

  // Read config
  final config = TweakcnConfig.fromPubspec(projectDir);

  // Read CSS
  final cssFile = File(p.join(projectDir, config.input));
  if (!cssFile.existsSync()) {
    stderr.writeln('Error: CSS file not found: ${config.input}');
    stderr.writeln(
      'Create ${config.input} or update the path in pubspec.yaml:',
    );
    stderr.writeln('');
    stderr.writeln('flutter_tweakcn_generator:');
    stderr.writeln('  input: your-theme.css');
    exit(_exitNothingGenerated);
  }

  final css = cssFile.readAsStringSync();

  // Parse
  final themeData = CssParser.parse(css);

  // Generate
  final generator = DartThemeGenerator(
    themeData,
    classPrefix: config.classPrefix,
    fontMode: config.fontMode,
    // Formatted at this project's own language version, since `dart format`
    // run here would use that one and the generated file has to survive it.
    languageVersion: languageVersionOfProject(projectDir),
  );
  final String dartCode;
  try {
    dartCode = generator.generate();
  } on StateError catch (e) {
    // Only a generator bug reaches here, but it should still arrive looking
    // like every other failure this CLI reports rather than as a stack trace.
    stderr.writeln('Error: ${e.message}');
    exit(_exitNothingGenerated);
  }

  // ColorScheme requires these, so a fallback was generated rather than an
  // uncompilable file. Say so — a substituted color is almost never what the
  // user wants, and the generated file gives no clue on its own.
  final substituted = generator.substitutedColorSchemeTokens;
  for (final entry in substituted.entries) {
    stderr.writeln(
      'Warning: ${entry.key} theme does not define '
      '${entry.value.map((t) => '--$t').join(', ')}. '
      'A fallback color was substituted in ColorScheme.',
    );
  }

  // Write output
  final outputFile = File(p.join(projectDir, config.output));
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(dartCode);
  _themeWritten = true;

  // Font handling based on fontMode
  final googleFonts = DartThemeGenerator.extractGoogleFontNames(
    themeData.resolvedFontSans,
  );

  if (themeData.lightFontSans != null && themeData.darkFontSans != null) {
    // ThemeData carries one font family across both brightnesses, so only the
    // light stack survives. Two stacks that resolve to the same families lose
    // nothing, so compare the families rather than the CSS text. Font names
    // cannot contain a comma, so joining them is an unambiguous comparison.
    final darkFonts = DartThemeGenerator.extractGoogleFontNames(
      themeData.darkFontSans,
    );
    if (googleFonts.join(',') != darkFonts.join(',')) {
      stderr.writeln(
        'Warning: light and dark declare different --font-sans. '
        'Using the light stack (${themeData.lightFontSans}); '
        'the dark stack (${themeData.darkFontSans}) is ignored.',
      );
    }
  }

  if (config.fontMode == 'custom' && googleFonts.isNotEmpty) {
    // Custom mode: scan local .ttf files provided by the user
    final fontsDir = p.join(projectDir, config.fontDir);
    final allFound = <DownloadedFont>[];
    // Read before addFonts writes to it, so the scanner sees what pubspec
    // said before this run started.
    final declarations = PubspecFontDeclarations.read(
      p.join(projectDir, 'pubspec.yaml'),
    );

    for (final fontName in googleFonts) {
      stdout.writeln('Scanning for custom font: $fontName');
      final found = CustomFontScanner.scan(
        fontName,
        fontsDir,
        relativeDir: config.fontDir,
        declarations: declarations,
      );
      allFound.addAll(found);
    }

    if (allFound.isNotEmpty) {
      final pubspecPath = p.join(projectDir, 'pubspec.yaml');
      PubspecFontAdder.addFonts(pubspecPath, allFound);
      stdout.writeln('Updated pubspec.yaml with custom font declarations');
    }
  } else if (config.fontMode == 'local' && googleFonts.isNotEmpty) {
    // Local mode: download .ttf files and update pubspec.yaml
    final fontsDir = p.join(projectDir, config.fontDir);
    final reports = <FontDownloadReport>[];

    // Families whose *lookup* failed, as opposed to families that lost an
    // individual file. `FontDownloadReport.failure` names the family as the
    // target in the first case and a file name in the second.
    final lookupFailed = <String>{};

    for (final fontName in googleFonts) {
      stdout.writeln('Downloading font: $fontName');
      final fontReport = await FontDownloader.download(
        fontName,
        fontsDir,
        relativeDir: config.fontDir,
      );
      if (fontReport.failures.any((f) => f.target == fontName)) {
        lookupFailed.add(fontName);
      }
      reports.add(fontReport);
    }

    final report = FontDownloadReport.merge(reports);
    stdout.writeln('  Fonts: ${report.summary}');

    if (report.hasFailures) {
      // Only what is on disk gets declared, so the build will not fail on a
      // missing asset — but the theme is short of what failed.
      stderr.writeln(
        'Error: ${report.failures.length} font file(s) could not be '
        'downloaded and were left out of pubspec.yaml:',
      );
      for (final failure in report.failures) {
        stderr.writeln('  $failure');
      }
      // A file that failed to download is a weight the theme asked for and did
      // not get, so the run is partial — that is #24's rule unchanged. A
      // failed *lookup* is not evidence of anything missing on its own: the
      // files it would have named may already be on disk and declared from an
      // earlier run, which is what a re-run on a dropped network looks like.
      // Whether anything is actually missing is settled below, by asking what
      // the project declares rather than what went wrong getting there (#28).
      if (report.failures.any((f) => !lookupFailed.contains(f.target))) {
        exitCode = _exitPartial;
      }
    }

    if (report.fonts.isNotEmpty) {
      final pubspecPath = p.join(projectDir, 'pubspec.yaml');
      PubspecFontAdder.addFonts(pubspecPath, report.fonts);
      stdout.writeln('Updated pubspec.yaml with font declarations');
    }
  } else if (dartCode.contains("package:google_fonts/google_fonts.dart")) {
    // Google Fonts mode: auto-add dependency
    final pubspecFile = File(p.join(projectDir, 'pubspec.yaml'));
    final pubspecContent = pubspecFile.readAsStringSync();
    if (!_declaresGoogleFonts(pubspecContent)) {
      stdout.writeln('Adding google_fonts dependency...');
      final result = Process.runSync('dart', [
        'pub',
        'add',
        'google_fonts',
      ], workingDirectory: projectDir);
      if (result.exitCode == 0) {
        stdout.writeln('  Added google_fonts to pubspec.yaml');
      } else {
        // The generated theme imports package:google_fonts. Without the
        // dependency the project does not resolve at all, so reporting this
        // on stderr alone let a caller reading the exit code call it a
        // success and move on to a build that could not work.
        stderr.writeln(
          '  Failed to add google_fonts. Run manually: dart pub add google_fonts',
        );
        stderr.writeln(
          '  Until then ${config.output} imports a package this project does '
          'not declare.',
        );
        exitCode = _exitPartial;
      }
    }
  }

  // font_exclusive: remove fonts not defined in --font-sans
  if ((config.fontMode == 'local' || config.fontMode == 'custom') &&
      config.fontExclusive) {
    // An empty font list has two very different causes. A theme that declares
    // a system font stack (`ui-sans-serif, system-ui, ...`) legitimately
    // resolves to no font families, and the fonts left over from a previous
    // run should go. A theme where `--font-sans` was never found — in either
    // mode — or was found blank is a detection failure, and deleting the
    // user's font files on that basis is unrecoverable in `custom` mode.
    final fontStackDeclared = themeData.resolvedFontSans != null;
    final allowEmpty = fontStackDeclared || config.fontExclusiveAllowEmpty;

    if (googleFonts.isEmpty && !allowEmpty) {
      stderr.writeln(
        'Warning: skipping font_exclusive cleanup — no --font-sans was found '
        'in ${config.input}.',
      );
      stderr.writeln(
        '  Cleaning up now would delete every font file in ${config.fontDir}/ '
        'and every font declaration in pubspec.yaml.',
      );
      stderr.writeln(
        '  Declare --font-sans, set font_exclusive: false if you '
        'manage fonts yourself, or set font_exclusive_allow_empty: true to '
        'clean up anyway.',
      );
    } else {
      final fontsDir = p.join(projectDir, config.fontDir);
      final pubspecPath = p.join(projectDir, 'pubspec.yaml');
      stdout.writeln('Font exclusive mode: cleaning up unused fonts...');
      // Read before removeUndefinedFonts rewrites it: the declarations are
      // what say which family each file on disk belongs to.
      FontCleanup.cleanFontsDirectory(
        fontsDir,
        googleFonts,
        allowEmpty: allowEmpty,
        declarations: PubspecFontDeclarations.read(pubspecPath),
      );
      PubspecFontAdder.removeUndefinedFonts(
        pubspecPath,
        googleFonts,
        allowEmpty: allowEmpty,
      );
      stdout.writeln('Font cleanup complete');
    }
  }

  // Whether the theme can load the fonts it names is what decides the exit
  // code — not whether anything went wrong on the way to putting them there.
  //
  // #24 set the rule (`0` means the theme is usable as generated) and #28
  // found it broken on *both* sides of one axis: a run whose fonts were
  // entirely in place answered `2` because a lookup failed, and a run whose
  // theme named a family with nothing behind it answered `0`. One check fixes
  // both, because both are the same question asked at the end instead of
  // inferred from an incident in the middle.
  //
  // Runs last, after `font_exclusive` cleanup, since removing a declaration is
  // itself a way for the theme to end up naming a font the project cannot
  // load.
  if ((config.fontMode == 'local' || config.fontMode == 'custom') &&
      googleFonts.isNotEmpty) {
    final missing = _familiesTheProjectCannotLoad(googleFonts, projectDir);
    if (missing.isNotEmpty) {
      stderr.writeln(
        'Error: the generated theme names ${missing.length} font '
        'family(ies) that pubspec.yaml does not declare, so Flutter falls '
        'back to the default font at runtime:',
      );
      for (final family in missing) {
        stderr.writeln('  $family');
      }
      exitCode = _exitPartial;
    }
  }

  // Summary
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

  if ((config.fontMode == 'local' || config.fontMode == 'custom') &&
      googleFonts.isNotEmpty) {
    final primary = googleFonts.first;
    final modeLabel = config.fontMode;
    if (googleFonts.length > 1) {
      stdout.writeln(
        '  Font: $primary ($modeLabel) → fallback: ${googleFonts.skip(1).join(', ')}',
      );
    } else {
      stdout.writeln('  Font: $primary ($modeLabel)');
    }
  } else {
    final fontMatch = RegExp(
      r'GoogleFonts\.(\w+)TextTheme',
    ).firstMatch(dartCode);
    if (fontMatch != null) {
      final fallbackMatches = RegExp(
        r'GoogleFonts\.(\w+)\(\)\.fontFamily',
      ).allMatches(dartCode);
      final fallbacks = fallbackMatches.map((m) => m.group(1)).toSet().toList();
      if (fallbacks.isNotEmpty) {
        stdout.writeln(
          '  Font: ${fontMatch.group(1)} (google_fonts) → fallback: ${fallbacks.join(', ')}',
        );
      } else {
        stdout.writeln('  Font: ${fontMatch.group(1)} (google_fonts)');
      }
    } else if (themeData.resolvedFontSans != null) {
      stdout.writeln('  Font: system default');
    }
  }

  stdout.writeln('  Font mode: ${config.fontMode}');
}
