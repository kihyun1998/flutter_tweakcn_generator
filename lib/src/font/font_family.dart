import 'pubspec_font_declarations.dart';

/// A font family name, and the rules for recognizing it wherever it is
/// written.
///
/// A family is spelled one way in CSS and `pubspec.yaml` (`Noto Sans KR`) and
/// another in file names (`NotoSansKR-Bold.ttf`). Every part of the package
/// that downloads, scans, declares, or deletes a font has to agree on that
/// translation, so it lives here rather than in each of them.
class FontFamily {
  /// The family name as written in CSS and in `pubspec.yaml`.
  final String name;

  /// The family name as it appears at the start of a font file name: [name]
  /// with its spaces removed.
  final String fileNamePrefix;

  FontFamily(this.name) : fileNamePrefix = name.replaceAll(' ', '');

  /// The file extension this package downloads and declares.
  static const extension = '.ttf';

  /// Whether [fileName] is a font file this package manages, whatever family
  /// it belongs to.
  ///
  /// The extension is matched case-insensitively: a `.TTF` file is as much a
  /// font as a `.ttf` one.
  static bool isFontFile(String fileName) =>
      fileName.toLowerCase().endsWith(extension);

  /// Whether [fileName] could be a font file of this family.
  ///
  /// Case is ignored, so a hand-named `inter-bold.ttf` is recognized as
  /// `Inter`'s rather than treated as an unknown family's.
  ///
  /// This is a guess from the name, and a deliberately generous one: it claims
  /// `InterVariable.ttf` and `Inter24pt-Bold.ttf` for `Inter`, and it also
  /// claims `RobotoSlab-Bold.ttf` for `Roboto`, which is wrong. Nothing in a
  /// file name distinguishes those two cases. Where being wrong costs
  /// something — deciding what to delete — ask
  /// [PubspecFontDeclarations.familyOf] first and fall back to this only for
  /// files pubspec has never heard of.
  bool ownsFile(String fileName) =>
      isFontFile(fileName) &&
      fileName.toLowerCase().startsWith(fileNamePrefix.toLowerCase());

  /// The weight portion of [fileName], with the family prefix and any
  /// separator removed: `NotoSansKR-Bold.ttf` → `Bold`.
  ///
  /// Returns an empty string when the file names no weight, as in
  /// `Inter.ttf`.
  String weightSuffixOf(String fileName) {
    final stem =
        isFontFile(fileName)
            ? fileName.substring(0, fileName.length - extension.length)
            : fileName;
    if (stem.length <= fileNamePrefix.length) return '';

    final suffix = stem.substring(fileNamePrefix.length);
    return suffix.startsWith('-') || suffix.startsWith('_')
        ? suffix.substring(1)
        : suffix;
  }

  /// The file name this family's [weightName] weight is stored under.
  ///
  /// The result is always a file [ownsFile] claims back.
  String fileNameFor(String weightName) =>
      '$fileNamePrefix-$weightName$extension';

  /// Whether [declaredName] — a family name read from pubspec or from
  /// `--font-sans` — refers to this family.
  ///
  /// pubspec and CSS both spell the family the way [name] does, so this is an
  /// exact comparison: `Roboto` and `Roboto Slab` are different families.
  bool hasName(String declaredName) => declaredName == name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FontFamily && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'FontFamily($name)';
}
