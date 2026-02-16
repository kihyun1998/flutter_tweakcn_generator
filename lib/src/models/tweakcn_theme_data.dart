import '../parser/shadow_parser.dart';

/// Parsed theme data from a tweakcn CSS file, containing both light and dark
/// mode tokens.
///
/// Produced by [CssParser.parse] and consumed by [DartThemeGenerator].
class TweakcnThemeData {
  /// Light mode tokens (from `:root` block).
  final ThemeModeData light;

  /// Dark mode tokens (from `.dark` block).
  final ThemeModeData dark;

  const TweakcnThemeData({required this.light, required this.dark});
}

/// Parsed design tokens for a single theme mode (light or dark).
class ThemeModeData {
  /// Color tokens keyed by CSS variable name (without `--`).
  ///
  /// Values are 32-bit ARGB integers (e.g. `0xFFFFFFFF` for white).
  final Map<String, int> colors;

  /// Base border radius in logical pixels (converted from CSS `rem`).
  final double? radius;

  /// Base spacing in logical pixels (converted from CSS `rem`).
  final double? spacing;

  /// Shadow tokens keyed by CSS variable name (e.g. `shadow-md`).
  ///
  /// Each value is a list of [ShadowData] since CSS shadows can be
  /// comma-separated (multiple layers).
  final Map<String, List<ShadowData>> shadows;

  /// Raw CSS `--font-sans` value (e.g. `'Inter', sans-serif`).
  ///
  /// Used to detect Google Font names for `textTheme` generation.
  /// `null` if `--font-sans` is not present in the CSS.
  final String? fontSans;

  const ThemeModeData({
    required this.colors,
    this.radius,
    this.spacing,
    this.shadows = const {},
    this.fontSans,
  });
}
