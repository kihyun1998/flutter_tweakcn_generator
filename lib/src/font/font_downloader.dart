import 'dart:convert';
import 'dart:io';

import 'font_family.dart';

/// A downloaded font file with its metadata.
class DownloadedFont {
  /// Font family name (e.g. `'Inter'`).
  final String family;

  /// Relative path to the downloaded file (e.g. `'fonts/Inter-Regular.ttf'`).
  final String filePath;

  /// CSS font-weight value (100–900).
  final int weight;

  const DownloadedFont({
    required this.family,
    required this.filePath,
    required this.weight,
  });
}

/// A parsed `@font-face` entry from Google Fonts CSS.
class FontEntry {
  final int weight;
  final String url;
  const FontEntry({required this.weight, required this.url});
}

/// Something that could not be obtained, and why.
class FontDownloadFailure {
  /// What failed: a font file name, or the family name when the lookup that
  /// would have named the files is what went wrong.
  final String target;

  /// A human-readable reason, for the CLI to print.
  final String reason;

  const FontDownloadFailure({required this.target, required this.reason});

  @override
  String toString() => '$target: $reason';
}

/// What came of trying to obtain a font's files.
///
/// Only [fonts] may be declared in pubspec.yaml: a declaration pointing at a
/// file that was never written turns into an asset-not-found error on the next
/// Flutter build, with nothing to connect it back to the download.
class FontDownloadReport {
  /// The files that are on disk and safe to declare.
  final List<DownloadedFont> fonts;

  /// How many files this run fetched.
  final int downloaded;

  /// How many files were already on disk and left alone.
  final int skipped;

  /// What could not be obtained.
  final List<FontDownloadFailure> failures;

  const FontDownloadReport({
    required this.fonts,
    required this.downloaded,
    required this.skipped,
    required this.failures,
  });

  /// Nothing was asked for and nothing went wrong.
  static const empty = FontDownloadReport(
    fonts: [],
    downloaded: 0,
    skipped: 0,
    failures: [],
  );

  /// A report covering one failure and nothing else.
  factory FontDownloadReport.failure(String target, String reason) =>
      FontDownloadReport(
        fonts: const [],
        downloaded: 0,
        skipped: 0,
        failures: [FontDownloadFailure(target: target, reason: reason)],
      );

  bool get hasFailures => failures.isNotEmpty;

  /// One line naming what happened, for the CLI summary.
  String get summary =>
      '$downloaded downloaded, $skipped already present, '
      '${failures.length} failed';

  /// Combines the reports of several families into one.
  static FontDownloadReport merge(Iterable<FontDownloadReport> reports) =>
      FontDownloadReport(
        fonts: [for (final r in reports) ...r.fonts],
        downloaded: reports.fold(0, (sum, r) => sum + r.downloaded),
        skipped: reports.fold(0, (sum, r) => sum + r.skipped),
        failures: [for (final r in reports) ...r.failures],
      );
}

/// Downloads Google Font .ttf files via the Google Fonts CSS2 API.
class FontDownloader {
  FontDownloader._();

  /// Weight value → human-readable suffix for file naming.
  static const weightNames = {
    100: 'Thin',
    200: 'ExtraLight',
    300: 'Light',
    400: 'Regular',
    500: 'Medium',
    600: 'SemiBold',
    700: 'Bold',
    800: 'ExtraBold',
    900: 'Black',
  };

  /// Downloads all available weights for [fontName] into [fontsDir].
  ///
  /// [fontsDir] is the absolute path where files are saved.
  /// [relativeDir] is the relative path used in [DownloadedFont.filePath]
  /// (defaults to `'fonts'`).
  ///
  /// Files that already exist on disk are skipped but still reported as
  /// present. Files that could not be obtained are reported as failures and
  /// are left out of [FontDownloadReport.fonts], so nothing declares an asset
  /// that is not there.
  static Future<FontDownloadReport> download(
    String fontName,
    String fontsDir, {
    String relativeDir = 'fonts',
  }) async {
    final List<FontEntry> entries;
    try {
      entries = parseFontEntries(await _fetchCss(_buildCssUrl(fontName)));
    } catch (error) {
      // A family Google Fonts does not serve, or an unreachable API, is a
      // failed download like any other — not a reason to abandon the run
      // before the theme has been written or the other families tried.
      final reason = '$error';
      stderr.writeln('  Error: could not look up "$fontName" — $reason');
      return FontDownloadReport.failure(fontName, reason);
    }

    if (entries.isEmpty) {
      stderr.writeln('  Warning: No font files found for "$fontName"');
      return FontDownloadReport.empty;
    }

    return downloadEntries(
      entries,
      fontName,
      fontsDir,
      relativeDir: relativeDir,
    );
  }

  /// Fetches each of [entries] into [fontsDir] for the family [fontName].
  ///
  /// Split out from [download] so the file-writing half can be exercised
  /// against any server, without the Google Fonts CSS lookup in front of it.
  static Future<FontDownloadReport> downloadEntries(
    Iterable<FontEntry> entries,
    String fontName,
    String fontsDir, {
    String relativeDir = 'fonts',
  }) async {
    final dir = Directory(fontsDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final family = FontFamily(fontName);
    final fonts = <DownloadedFont>[];
    final failures = <FontDownloadFailure>[];
    var downloaded = 0;
    var skipped = 0;
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      for (final entry in entries) {
        final weightName = weightNames[entry.weight] ?? 'W${entry.weight}';
        final fileName = family.fileNameFor(weightName);
        final file = File('$fontsDir/$fileName');

        void recordDeclarable() => fonts.add(
          DownloadedFont(
            family: fontName,
            filePath: '$relativeDir/$fileName',
            weight: entry.weight,
          ),
        );

        if (file.existsSync()) {
          stdout.writeln('  Skipping $fileName (already exists)');
          skipped++;
          recordDeclarable();
          continue;
        }

        stdout.writeln('  Downloading $fileName ...');
        final reason = await _fetchTo(client, entry.url, file);
        if (reason != null) {
          stderr.writeln('  Error: could not download $fileName — $reason');
          failures.add(FontDownloadFailure(target: fileName, reason: reason));
          continue;
        }
        downloaded++;
        recordDeclarable();
      }
    } finally {
      client.close();
    }

    return FontDownloadReport(
      fonts: fonts,
      downloaded: downloaded,
      skipped: skipped,
      failures: failures,
    );
  }

  /// Fetches [url] into [file], returning a reason on failure and `null` on
  /// success.
  ///
  /// The body is written to a sibling part file and renamed only once it has
  /// arrived whole, so an interrupted transfer cannot leave behind something
  /// that a later run would mistake for a complete font.
  static Future<String?> _fetchTo(
    HttpClient client,
    String url,
    File file,
  ) async {
    final part = File('${file.path}.part');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) {
        return 'HTTP ${response.statusCode}';
      }

      final sink = part.openWrite();
      try {
        await response.pipe(sink).timeout(_timeout);
      } finally {
        // `pipe` closes the sink on success. When it fails, closing here
        // rethrows the same error, which would displace the original before
        // the catch below sees it — so that rethrow is discarded, not the
        // failure itself.
        await sink.close().catchError((_) {});
      }

      part.renameSync(file.path);
      return null;
    } catch (error) {
      return '$error';
    } finally {
      // Cleanup must not become the failure: on a read-only directory the
      // delete throws, and letting it out would abandon the whole run.
      try {
        if (part.existsSync()) part.deleteSync();
      } catch (_) {
        // The part file stays behind. It is never mistaken for a font, and
        // the next successful attempt overwrites it.
      }
    }
  }

  /// How long any one request may take before it counts as failed.
  ///
  /// Without this a server that accepts the connection and then stalls hangs
  /// the whole generator indefinitely.
  static const _timeout = Duration(seconds: 30);

  /// Builds a Google Fonts CSS2 API URL requesting all standard weights.
  static String _buildCssUrl(String fontName) {
    final encoded = Uri.encodeComponent(fontName);
    return 'https://fonts.googleapis.com/css2'
        '?family=$encoded:wght@100;200;300;400;500;600;700;800;900';
  }

  /// Fetches CSS from the Google Fonts API.
  ///
  /// The default Dart User-Agent causes Google Fonts to return TTF format URLs.
  static Future<String> _fetchCss(String url) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) {
        throw StateError(
          'Google Fonts API returned HTTP ${response.statusCode}',
        );
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  /// Parses `@font-face` rules from Google Fonts CSS, extracting weight and URL.
  static List<FontEntry> parseFontEntries(String css) {
    final results = <FontEntry>[];
    final facePattern = RegExp(r'@font-face\s*\{([^}]+)\}', multiLine: true);

    for (final match in facePattern.allMatches(css)) {
      final block = match.group(1)!;

      final weightMatch = RegExp(r'font-weight:\s*(\d+)').firstMatch(block);
      final urlMatch = RegExp(r"url\(([^)]+\.ttf)\)").firstMatch(block);

      if (weightMatch != null && urlMatch != null) {
        results.add(
          FontEntry(
            weight: int.parse(weightMatch.group(1)!),
            url: urlMatch.group(1)!,
          ),
        );
      }
    }

    return results;
  }
}
