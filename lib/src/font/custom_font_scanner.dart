import 'dart:io';

import 'font_downloader.dart';
import 'font_family.dart';

/// Scans a local directory for user-provided .ttf files matching font families.
///
/// Unlike [FontDownloader], this does not fetch anything from the network.
/// It expects the user to have already placed .ttf files in the target
/// directory.
class CustomFontScanner {
  CustomFontScanner._();

  /// Well-known weight suffixes used for inferring font-weight from file names.
  static const _weightSuffixes = {
    'Thin': 100,
    'ExtraLight': 200,
    'UltraLight': 200,
    'Light': 300,
    'Regular': 400,
    'Medium': 500,
    'SemiBold': 600,
    'DemiBold': 600,
    'Bold': 700,
    'ExtraBold': 800,
    'UltraBold': 800,
    'Black': 900,
    'Heavy': 900,
  };

  /// Scans [fontsDir] for the font files belonging to [fontName], as decided
  /// by [FontFamily.ownsFile].
  ///
  /// [relativeDir] is the relative path used in [DownloadedFont.filePath]
  /// (defaults to `'fonts'`).
  ///
  /// Returns a list of [DownloadedFont] for each matched file.
  /// If no files are found, prints a warning and returns an empty list.
  static List<DownloadedFont> scan(
    String fontName,
    String fontsDir, {
    String relativeDir = 'fonts',
  }) {
    final dir = Directory(fontsDir);
    if (!dir.existsSync()) {
      stderr.writeln('  Warning: Font directory not found: $fontsDir');
      stderr.writeln(
        '  Please create the directory and place .ttf files for "$fontName".',
      );
      return [];
    }

    final family = FontFamily(fontName);
    final results = <DownloadedFont>[];

    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final fileName = entity.uri.pathSegments.last;
      if (!family.ownsFile(fileName)) continue;

      final weight = _weightFor(family.weightSuffixOf(fileName));
      results.add(
        DownloadedFont(
          family: fontName,
          filePath: '$relativeDir/$fileName',
          weight: weight,
        ),
      );
      stdout.writeln('  Found: $fileName (weight: $weight)');
    }

    if (results.isEmpty) {
      stderr.writeln(
        '  Warning: No .ttf files found for "$fontName" in $fontsDir',
      );
      stderr.writeln(
        '  Expected files like: ${family.fileNameFor('Regular')}, '
        '${family.fileNameFor('Bold')}, etc.',
      );
    }

    // Sort by weight for consistent ordering.
    results.sort((a, b) => a.weight.compareTo(b.weight));
    return results;
  }

  /// Maps a file name's weight suffix to a CSS font-weight.
  ///
  /// e.g. `Bold` → 700, `Light` → 300. Falls back to 400 (Regular) for an
  /// empty or unrecognized suffix.
  static int _weightFor(String suffix) {
    if (suffix.isEmpty) return 400;

    for (final entry in _weightSuffixes.entries) {
      if (suffix.toLowerCase() == entry.key.toLowerCase()) {
        return entry.value;
      }
    }

    return 400;
  }
}
