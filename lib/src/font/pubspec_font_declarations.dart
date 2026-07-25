import 'dart:io';

import 'package:yaml/yaml.dart';

/// What a `pubspec.yaml` currently declares under `flutter > fonts`.
///
/// This is the only record of which file belongs to which family. A file name
/// cannot answer that on its own: `RobotoSlab-Bold.ttf` and `InterVariable.ttf`
/// have the same shape — a family name followed by more text — yet the first
/// belongs to a family that merely shares a prefix with `Roboto` and the second
/// is `Inter`'s own. Guessing from the name alone either keeps stale files or
/// deletes real ones.
class PubspecFontDeclarations {
  /// Every family declared, in declaration order.
  final List<String> families;

  /// The families each declared asset belongs to, keyed by the asset's file
  /// name in lower case.
  ///
  /// A file may be declared more than once — pubspec is free to list the same
  /// asset under two family spellings — so this maps to a set rather than to
  /// one name. Collapsing it would let one declaration silently overwrite
  /// another and put a file that a defined family declares at risk.
  final Map<String, Set<String>> familiesByFileName;

  const PubspecFontDeclarations({
    required this.families,
    required this.familiesByFileName,
  });

  /// Declares nothing — the answer for a pubspec with no `flutter > fonts`
  /// section, and for callers that have no pubspec to consult.
  static const empty = PubspecFontDeclarations(
    families: [],
    familiesByFileName: {},
  );

  /// Reads the declarations out of the pubspec.yaml at [path].
  ///
  /// A pubspec that is missing declares nothing, matching how the rest of the
  /// font handling treats an absent file.
  factory PubspecFontDeclarations.read(String path) {
    final file = File(path);
    if (!file.existsSync()) return empty;
    return PubspecFontDeclarations.parse(file.readAsStringSync());
  }

  /// Reads the declarations out of [pubspecContent].
  ///
  /// Uses a YAML parser rather than matching text, so quoting, comments, line
  /// endings and nesting are the parser's problem. Returns [empty] for content
  /// that does not parse; the caller's own config load would already have
  /// failed on that.
  factory PubspecFontDeclarations.parse(String pubspecContent) {
    Object? document;
    try {
      document = loadYaml(pubspecContent);
    } catch (_) {
      return empty;
    }

    if (document is! Map) return empty;
    final flutter = document['flutter'];
    if (flutter is! Map) return empty;
    final fonts = flutter['fonts'];
    if (fonts is! List) return empty;

    final families = <String>[];
    final familiesByFileName = <String, Set<String>>{};

    for (final entry in fonts) {
      if (entry is! Map) continue;
      final family = entry['family'];
      if (family == null) continue;
      final familyName = '$family';
      families.add(familyName);

      final assets = entry['fonts'];
      if (assets is! List) continue;
      for (final asset in assets) {
        if (asset is! Map) continue;
        final path = asset['asset'];
        if (path == null) continue;
        // pubspec asset paths always use forward slashes.
        final fileName = '$path'.split('/').last.toLowerCase();
        familiesByFileName.putIfAbsent(fileName, () => {}).add(familyName);
      }
    }

    return PubspecFontDeclarations(
      families: families,
      familiesByFileName: familiesByFileName,
    );
  }

  /// The families [fileName] is declared under, empty when pubspec does not
  /// mention the file at all.
  ///
  /// An empty answer means the file was never managed by this package, not
  /// that it belongs to nobody. Matching ignores case, so a pubspec written
  /// with different capitalization than the file on disk still recognizes it.
  Set<String> familiesOf(String fileName) =>
      familiesByFileName[fileName.toLowerCase()] ?? const {};
}
