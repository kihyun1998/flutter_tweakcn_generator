import 'dart:io';

import 'font_downloader.dart';

/// Adds `flutter > fonts` declarations to a pubspec.yaml file.
class PubspecFontAdder {
  PubspecFontAdder._();

  /// Adds font declarations for [fonts] to the pubspec.yaml at [pubspecPath].
  ///
  /// Groups fonts by family and writes proper `flutter > fonts` YAML.
  /// If the pubspec already declares the same family, it is skipped.
  static void addFonts(String pubspecPath, List<DownloadedFont> fonts) {
    if (fonts.isEmpty) return;

    final file = File(pubspecPath);
    if (!file.existsSync()) {
      throw StateError('pubspec.yaml not found at $pubspecPath');
    }

    var content = file.readAsStringSync();

    // Group by family
    final families = <String, List<DownloadedFont>>{};
    for (final f in fonts) {
      families.putIfAbsent(f.family, () => []).add(f);
    }

    // Build the fonts YAML block for each family
    final fontsYaml = StringBuffer();
    for (final entry in families.entries) {
      final family = entry.key;
      final familyFonts =
          entry.value..sort((a, b) => a.weight.compareTo(b.weight));

      // Skip if already declared
      if (content.contains('family: $family')) {
        continue;
      }

      fontsYaml.writeln('    - family: $family');
      fontsYaml.writeln('      fonts:');
      for (final f in familyFonts) {
        fontsYaml.writeln('        - asset: ${f.filePath}');
        fontsYaml.writeln('          weight: ${f.weight}');
      }
    }

    if (fontsYaml.isEmpty) return;

    // Insert into pubspec content
    content = _insertFontsSection(content, fontsYaml.toString());
    file.writeAsStringSync(content);
  }

  /// Inserts [fontsYaml] into the pubspec content at the right location.
  static String _insertFontsSection(String content, String fontsYaml) {
    // Case 1: flutter section with fonts already exists → append
    final fontsPattern = RegExp(r'^(  fonts:\s*\n)', multiLine: true);
    final fontsMatch = fontsPattern.firstMatch(content);
    if (fontsMatch != null) {
      // Find the end of existing fonts section and append
      final insertPos = fontsMatch.end;
      return content.substring(0, insertPos) +
          fontsYaml +
          content.substring(insertPos);
    }

    // Case 2: flutter section exists but no fonts → add fonts key
    final flutterPattern = RegExp(r'^flutter:\s*\n', multiLine: true);
    final flutterMatch = flutterPattern.firstMatch(content);
    if (flutterMatch != null) {
      final insertPos = flutterMatch.end;
      return '${content.substring(0, insertPos)}  fonts:\n$fontsYaml${content.substring(insertPos)}';
    }

    // Case 3: no flutter section → add it at end
    if (!content.endsWith('\n')) {
      content += '\n';
    }
    return '$content\nflutter:\n  fonts:\n$fontsYaml';
  }
}
