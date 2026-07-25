import 'dart:io';

import 'package:flutter_tweakcn_generator/src/config.dart';
import 'package:flutter_tweakcn_generator/src/font/font_cleanup.dart';
import 'package:flutter_tweakcn_generator/src/font/custom_font_scanner.dart';
import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_adder.dart';
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

  // Write output
  final outputFile = File(p.join(projectDir, config.output));
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(dartCode);

  // Font handling based on fontMode
  final googleFonts = DartThemeGenerator.extractGoogleFontNames(
    themeData.light.fontSans,
  );

  if (config.fontMode == 'custom' && googleFonts.isNotEmpty) {
    // Custom mode: scan local .ttf files provided by the user
    final fontsDir = p.join(projectDir, config.fontDir);
    final allFound = <DownloadedFont>[];

    for (final fontName in googleFonts) {
      stdout.writeln('Scanning for custom font: $fontName');
      final found = CustomFontScanner.scan(
        fontName,
        fontsDir,
        relativeDir: config.fontDir,
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
    final allDownloaded = <DownloadedFont>[];

    for (final fontName in googleFonts) {
      stdout.writeln('Downloading font: $fontName');
      final downloaded = await FontDownloader.download(
        fontName,
        fontsDir,
        relativeDir: config.fontDir,
      );
      allDownloaded.addAll(downloaded);
    }

    if (allDownloaded.isNotEmpty) {
      final pubspecPath = p.join(projectDir, 'pubspec.yaml');
      PubspecFontAdder.addFonts(pubspecPath, allDownloaded);
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
    // run should go. A theme where `--font-sans` was never found — or was
    // found blank — is a detection failure, and deleting the user's font files
    // on that basis is unrecoverable in `custom` mode.
    final fontStackDeclared =
        themeData.light.fontSans?.trim().isNotEmpty ?? false;
    final allowEmpty = fontStackDeclared || config.fontExclusiveAllowEmpty;

    if (googleFonts.isEmpty && !allowEmpty) {
      stderr.writeln(
        'Warning: skipping font_exclusive cleanup — no --font-sans was found '
        'in the :root block of ${config.input}.',
      );
      stderr.writeln(
        '  Cleaning up now would delete every font file in ${config.fontDir}/ '
        'and every font declaration in pubspec.yaml.',
      );
      stderr.writeln(
        '  Declare --font-sans in :root, set font_exclusive: false if you '
        'manage fonts yourself, or set font_exclusive_allow_empty: true to '
        'clean up anyway.',
      );
    } else {
      final fontsDir = p.join(projectDir, config.fontDir);
      final pubspecPath = p.join(projectDir, 'pubspec.yaml');
      stdout.writeln('Font exclusive mode: cleaning up unused fonts...');
      FontCleanup.cleanFontsDirectory(
        fontsDir,
        googleFonts,
        allowEmpty: allowEmpty,
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
    } else if (themeData.light.fontSans != null) {
      stdout.writeln('  Font: system default');
    }
  }

  stdout.writeln('  Font mode: ${config.fontMode}');
}
