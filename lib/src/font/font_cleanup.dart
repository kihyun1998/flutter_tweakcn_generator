import 'dart:io';

import 'font_family.dart';
import 'pubspec_font_declarations.dart';

/// Cleans up font files that are not in the defined font families list.
class FontCleanup {
  FontCleanup._();

  /// Removes font files from [fontsDir] that belong to none of
  /// [definedFamilies].
  ///
  /// A file's family is taken from [declarations] when pubspec declares it,
  /// because that is a record rather than a guess: it is what lets a leftover
  /// `RobotoSlab-Bold.ttf` be removed when only `Roboto` is defined, without
  /// also removing an `InterVariable.ttf` that `Inter` really does own.
  ///
  /// A file pubspec has never heard of was never managed here, so its family
  /// is guessed with [FontFamily.ownsFile] — which errs toward keeping.
  /// Files that are not font files are left alone.
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
    PubspecFontDeclarations declarations = PubspecFontDeclarations.empty,
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

      final declaredFamilies = declarations.familiesOf(name);
      final keep =
          declaredFamilies.isNotEmpty
              // Any one defined declaration is enough to keep the file: a
              // second declaration under some other spelling must not be able
              // to condemn it.
              ? declaredFamilies.any(
                (declared) => families.any((f) => f.hasName(declared)),
              )
              : families.any((family) => family.ownsFile(name));
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
