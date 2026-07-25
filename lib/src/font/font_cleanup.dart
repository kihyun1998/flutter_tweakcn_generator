import 'dart:io';

import 'font_family.dart';

/// Cleans up font files that are not in the defined font families list.
class FontCleanup {
  FontCleanup._();

  /// Removes font files from [fontsDir] that belong to none of
  /// [definedFamilies].
  ///
  /// Which files a family owns is [FontFamily.ownsFile]'s decision. Files that
  /// are not font files are left alone.
  ///
  /// If the directory becomes empty after cleanup, it is deleted as well.
  ///
  /// An empty [definedFamilies] would delete every font file. That is a
  /// detection failure far more often than it is an instruction, so it is
  /// treated as a no-op unless the caller sets [allowEmpty] to say it knows
  /// the theme really does define no fonts.
  static void cleanFontsDirectory(
    String fontsDir,
    List<String> definedFamilies, {
    bool allowEmpty = false,
  }) {
    if (definedFamilies.isEmpty && !allowEmpty) return;

    final dir = Directory(fontsDir);
    if (!dir.existsSync()) return;

    final families = definedFamilies.map(FontFamily.new).toList();

    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!FontFamily.isFontFile(name)) continue;

      final keep = families.any((family) => family.ownsFile(name));
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
