import 'dart:io';

import 'package:yaml/yaml.dart';

import 'font_downloader.dart';
import 'font_family.dart';

/// Adds `flutter > fonts` declarations to a pubspec.yaml file.
class PubspecFontAdder {
  PubspecFontAdder._();

  /// Matches a YAML scalar wrapped in a matching pair of quotes.
  static final _quotedPattern = RegExp(r'''^(["'])(.*)\1$''');

  /// Strips the quotes YAML allows around a scalar, so that a name read from
  /// raw text means the same as one read by the parser.
  static String _unquote(String value) =>
      _quotedPattern.firstMatch(value)?.group(2) ?? value;

  /// The font family names declared under `flutter > fonts` in
  /// [pubspecContent].
  ///
  /// Read with a YAML parser rather than by matching text, so that quoting,
  /// comments, line endings and nesting are the parser's problem and a
  /// `family:` key somewhere else in the file is not mistaken for a font
  /// declaration. Names are whole: `Roboto Slab` does not declare `Roboto`.
  ///
  /// Returns nothing for a pubspec that does not parse; the caller's own
  /// config load would already have failed on that.
  static List<String> _declaredFamilies(String pubspecContent) {
    Object? document;
    try {
      document = loadYaml(pubspecContent);
    } catch (_) {
      return const [];
    }

    if (document is! Map) return const [];
    final flutter = document['flutter'];
    if (flutter is! Map) return const [];
    final fonts = flutter['fonts'];
    if (fonts is! List) return const [];

    return [
      for (final entry in fonts)
        if (entry is Map && entry['family'] != null) '${entry['family']}',
    ];
  }

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
    final declared = _declaredFamilies(content);

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
      if (declared.any(FontFamily(family).hasName)) {
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

  /// Removes font family blocks from pubspec.yaml that are not in
  /// [definedFamilies].
  ///
  /// If all families are removed, the `fonts:` key is also removed.
  ///
  /// An empty [definedFamilies] would strip every font declaration. That is a
  /// detection failure far more often than it is an instruction, so it is
  /// treated as a no-op unless the caller sets [allowEmpty] to say it knows
  /// the theme really does define no fonts.
  static void removeUndefinedFonts(
    String pubspecPath,
    List<String> definedFamilies, {
    bool allowEmpty = false,
  }) {
    if (definedFamilies.isEmpty && !allowEmpty) return;

    final file = File(pubspecPath);
    if (!file.existsSync()) return;

    final lines = file.readAsStringSync().split('\n');
    final result = <String>[];

    final families = definedFamilies.map(FontFamily.new).toList();
    bool isDefined(String? family) =>
        family != null && families.any((f) => f.hasName(family));

    // Find the `  fonts:` line inside the flutter section
    var inFlutter = false;
    var inFonts = false;
    var currentBlock = <String>[];
    String? currentFamily;
    var fontsLineIndex = -1;
    var keptFamilies = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Detect top-level flutter: section
      if (RegExp(r'^flutter:\s*$').hasMatch(line)) {
        inFlutter = true;
        result.add(line);
        continue;
      }

      // Detect leaving flutter section (another top-level key)
      if (inFlutter && RegExp(r'^\S').hasMatch(line) && line.isNotEmpty) {
        // Flush any pending block before leaving
        if (inFonts && currentBlock.isNotEmpty) {
          if (isDefined(currentFamily)) {
            result.addAll(currentBlock);
            keptFamilies++;
          }
          currentBlock = [];
          currentFamily = null;
        }
        inFlutter = false;
        inFonts = false;
      }

      if (!inFlutter) {
        result.add(line);
        continue;
      }

      // Detect `  fonts:` inside flutter
      if (RegExp(r'^  fonts:\s*$').hasMatch(line)) {
        inFonts = true;
        fontsLineIndex = result.length;
        result.add(line);
        continue;
      }

      if (!inFonts) {
        result.add(line);
        continue;
      }

      // Detect end of fonts section (another flutter sub-key at indent 2)
      if (RegExp(r'^  \S').hasMatch(line) &&
          !line.trimLeft().startsWith('-') &&
          !line.trimLeft().startsWith('fonts:')) {
        // Flush pending block
        if (currentBlock.isNotEmpty) {
          if (isDefined(currentFamily)) {
            result.addAll(currentBlock);
            keptFamilies++;
          }
          currentBlock = [];
          currentFamily = null;
        }
        inFonts = false;
        result.add(line);
        continue;
      }

      // Detect `    - family: XXX`. The line is matched rather than parsed
      // because its indentation also delimits the block being rewritten, but
      // the name it yields must mean the same thing as the one
      // [_declaredFamilies] reads.
      final familyMatch = RegExp(r'^    - family:\s*(.+)$').firstMatch(line);
      if (familyMatch != null) {
        // Flush previous block
        if (currentBlock.isNotEmpty) {
          if (isDefined(currentFamily)) {
            result.addAll(currentBlock);
            keptFamilies++;
          }
        }
        currentBlock = [line];
        currentFamily = _unquote(familyMatch.group(1)!.trim());
        continue;
      }

      // Accumulate lines into the current family block
      if (currentFamily != null) {
        currentBlock.add(line);
      } else {
        result.add(line);
      }
    }

    // Flush any remaining block
    if (currentBlock.isNotEmpty) {
      if (isDefined(currentFamily)) {
        result.addAll(currentBlock);
        keptFamilies++;
      }
    }

    // Remove the `  fonts:` line if no families remain
    if (keptFamilies == 0 && fontsLineIndex >= 0) {
      result.removeAt(fontsLineIndex);
    }

    file.writeAsStringSync(result.join('\n'));
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
