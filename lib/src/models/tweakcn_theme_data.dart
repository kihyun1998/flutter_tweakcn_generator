import '../parser/shadow_parser.dart';

/// Holds parsed theme data for both light and dark modes.
class TweakcnThemeData {
  final ThemeModeData light;
  final ThemeModeData dark;

  const TweakcnThemeData({required this.light, required this.dark});
}

/// Holds parsed data for a single theme mode (light or dark).
class ThemeModeData {
  /// CSS variable name (without `--`) → ARGB color int.
  final Map<String, int> colors;

  /// Radius base value in logical pixels (converted from rem).
  final double? radius;

  /// Spacing base value in logical pixels (converted from rem).
  final double? spacing;

  /// Shadow name → list of shadow data.
  final Map<String, List<ShadowData>> shadows;

  /// Raw CSS font-sans value (e.g. `'Inter', sans-serif`).
  final String? fontSans;

  const ThemeModeData({
    required this.colors,
    this.radius,
    this.spacing,
    this.shadows = const {},
    this.fontSans,
  });
}
