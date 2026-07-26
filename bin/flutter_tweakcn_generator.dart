import 'dart:io';

import 'package:flutter_tweakcn_generator/src/config.dart';
import 'package:flutter_tweakcn_generator/src/font/font_cleanup.dart';
import 'package:flutter_tweakcn_generator/src/font/custom_font_scanner.dart';
import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_adder.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_declarations.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
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
    exit(1);
  }

  final css = cssFile.readAsStringSync();

  // Parse
  final themeData = CssParser.parse(css);

  // Generate
  final generator = DartThemeGenerator(
    themeData,
    classPrefix: config.classPrefix,
    fontMode: config.fontMode,
  );
  final dartCode = generator.generate();

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

    for (final fontName in googleFonts) {
      stdout.writeln('Downloading font: $fontName');
      reports.add(
        await FontDownloader.download(
          fontName,
          fontsDir,
          relativeDir: config.fontDir,
        ),
      );
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
      exitCode = 1;
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
    if (!pubspecContent.contains('google_fonts:')) {
      stdout.writeln('Adding google_fonts dependency...');
      final result = Process.runSync('dart', [
        'pub',
        'add',
        'google_fonts',
      ], workingDirectory: projectDir);
      if (result.exitCode == 0) {
        stdout.writeln('  Added google_fonts to pubspec.yaml');
      } else {
        stderr.writeln(
          '  Failed to add google_fonts. Run manually: dart pub add google_fonts',
        );
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
