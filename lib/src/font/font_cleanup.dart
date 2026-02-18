import 'dart:io';

/// Cleans up font files that are not in the defined font families list.
class FontCleanup {
  FontCleanup._();

  /// Removes .ttf files from [fontsDir] whose names don't start with any of
  /// the sanitized [definedFamilies] names.
  ///
  /// A family name is sanitized by removing spaces (e.g. `'Noto Sans KR'` →
  /// `'NotoSansKR'`). A file is kept if its basename starts with any sanitized
  /// family name.
  ///
  /// If the directory becomes empty after cleanup, it is deleted as well.
  static void cleanFontsDirectory(
    String fontsDir,
    List<String> definedFamilies,
  ) {
    final dir = Directory(fontsDir);
    if (!dir.existsSync()) return;

    final sanitized =
        definedFamilies.map((f) => f.replaceAll(' ', '')).toList();

    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.ttf')) continue;

      final keep = sanitized.any((prefix) => name.startsWith(prefix));
      if (!keep) {
        entity.deleteSync();
        stdout.writeln('  Removed unused font: $name');
      }
    }

    // Remove directory if empty
    if (dir.existsSync() && dir.listSync().isEmpty) {
      dir.deleteSync();
      stdout.writeln('  Removed empty fonts directory');
    }
  }
}
