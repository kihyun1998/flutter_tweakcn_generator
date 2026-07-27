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

  /// The `--font-sans` stack the generated theme uses.
  ///
  /// Distinct from [ThemeModeData.fontSans], which is one mode's raw value.
  ///
  /// A `ThemeData` carries one font family across both brightnesses, so light
  /// wins and dark is the fallback: a theme that names its font only in the
  /// dark block still gets that font rather than none.
  ///
  /// A declaration with no value declares nothing — see [_declared].
  String? get resolvedFontSans => lightFontSans ?? darkFontSans;

  /// The stack the light mode declares, or `null` if it declares none.
  String? get lightFontSans => _declared(light.fontSans);

  /// The stack the dark mode declares, or `null` if it declares none.
  String? get darkFontSans => _declared(dark.fontSans);

  /// Treats a missing or blank value alike: `--font-sans: ;` parses to an
  /// empty string, which names no font.
  static String? _declared(String? value) =>
      (value != null && value.trim().isNotEmpty) ? value : null;
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

  /// [shadows] in the primitive shape generated code takes, keyed the same
  /// way and with each level's layers left in order.
  ///
  /// Exists so that turning a parsed theme into a runtime theme does not mean
  /// reimplementing the parser's own output: a consumer hands this straight to
  /// the generated shadows factory.
  Map<String, List<ShadowLayer>> get shadowLayers => {
    for (final level in shadows.entries)
      level.key: [for (final layer in level.value) layer.toLayer()],
  };
}
