import 'dart:convert';
import 'dart:io';

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
  /// Returns a list of [DownloadedFont] describing each downloaded file.
  /// Files that already exist on disk are skipped but still included in the
  /// result list.
  static Future<List<DownloadedFont>> download(
    String fontName,
    String fontsDir, {
    String relativeDir = 'fonts',
  }) async {
    final cssUrl = _buildCssUrl(fontName);
    final css = await _fetchCss(cssUrl);
    final entries = parseFontEntries(css);

    if (entries.isEmpty) {
      stderr.writeln('  Warning: No font files found for "$fontName"');
      return [];
    }

    final dir = Directory(fontsDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final results = <DownloadedFont>[];
    final client = HttpClient();

    try {
      for (final entry in entries) {
        final weightName = weightNames[entry.weight] ?? 'W${entry.weight}';
        final sanitized = fontName.replaceAll(' ', '');
        final fileName = '$sanitized-$weightName.ttf';
        final absolutePath = '$fontsDir/$fileName';

        results.add(
          DownloadedFont(
            family: fontName,
            filePath: '$relativeDir/$fileName',
            weight: entry.weight,
          ),
        );

        final file = File(absolutePath);
        if (file.existsSync()) {
          stdout.writeln('  Skipping $fileName (already exists)');
          continue;
        }

        stdout.writeln('  Downloading $fileName ...');
        final request = await client.getUrl(Uri.parse(entry.url));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
          }
          file.writeAsBytesSync(bytes);
        } else {
          stderr.writeln(
            '  Warning: Failed to download $fileName '
            '(HTTP ${response.statusCode})',
          );
        }
      }
    } finally {
      client.close();
    }

    return results;
  }

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
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
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
