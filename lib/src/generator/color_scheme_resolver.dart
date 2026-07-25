import 'dart:math' as math;

/// The result of resolving the colors a Flutter `ColorScheme` requires.
class ResolvedColorScheme {
  /// `ColorScheme` property name → 32-bit ARGB value.
  ///
  /// Contains an entry for every property in
  /// [ColorSchemeResolver.requiredProperties], whether or not the theme
  /// defined the token behind it.
  final Map<String, int> colors;

  /// CSS token names the theme did not define, in the order they were
  /// resolved.
  ///
  /// A fallback was substituted for each. Empty when the theme defines every
  /// required token.
  final List<String> substitutedTokens;

  const ResolvedColorScheme({
    required this.colors,
    required this.substitutedTokens,
  });
}

/// Resolves the colors a Flutter `ColorScheme` requires from the tokens a
/// tweakcn theme actually defines.
///
/// None of `ColorScheme`'s required parameters can be omitted, so a generated
/// file that leaves one out does not compile. Every property here therefore
/// always resolves: to the theme's own token when it exists, and otherwise to
/// a fallback derived from the theme where possible and from Material's
/// baseline where not.
class ColorSchemeResolver {
  ColorSchemeResolver._();

  /// CSS token → `ColorScheme` property, in the order the generator emits
  /// them.
  ///
  /// The properties in [requiredProperties] come first; the rest are optional
  /// and are emitted only when the theme defines them.
  static const tokenMapping = <String, String>{
    'background': 'surface',
    'foreground': 'onSurface',
    'primary': 'primary',
    'primary-foreground': 'onPrimary',
    'secondary': 'secondary',
    'secondary-foreground': 'onSecondary',
    'destructive': 'error',
    'destructive-foreground': 'onError',
    'border': 'outline',
    'input': 'outlineVariant',
    'card': 'surfaceContainerLowest',
    'muted': 'surfaceContainerHighest',
    'muted-foreground': 'onSurfaceVariant',
  };

  /// The `ColorScheme` parameters marked `required` that carry a color.
  ///
  /// `brightness` is required too, but the generator writes it directly from
  /// the mode rather than resolving it from a token.
  static const requiredProperties = <String>{
    'surface',
    'onSurface',
    'primary',
    'onPrimary',
    'secondary',
    'onSecondary',
    'error',
    'onError',
  };

  /// `ColorScheme` property → the CSS token that supplies it, for the required
  /// properties only. Derived from [tokenMapping] so the two cannot diverge.
  static final requiredTokens = <String, String>{
    for (final entry in tokenMapping.entries)
      if (requiredProperties.contains(entry.value)) entry.value: entry.key,
  };

  static const _white = 0xFFFFFFFF;
  static const _black = 0xFF000000;

  // Material's own baseline, used only when the theme offers nothing to
  // derive from. Matches ColorScheme.light() / ColorScheme.dark().
  static const _baselineLightPrimary = 0xFF6200EE;
  static const _baselineDarkPrimary = 0xFFBB86FC;
  static const _baselineLightError = 0xFFB00020;
  static const _baselineDarkError = 0xFFCF6679;
  static const _baselineDarkSurface = 0xFF121212;

  /// Resolves every required color from [tokens], a CSS-token-name → ARGB map
  /// for a single theme mode.
  static ResolvedColorScheme resolve(
    Map<String, int> tokens, {
    required bool isDark,
  }) {
    final substituted = <String>[];

    int resolveProperty(String property, int Function() fallback) {
      final defined = tokens[requiredTokens[property]!];
      if (defined != null) return defined;
      substituted.add(requiredTokens[property]!);
      return fallback();
    }

    // Each `on` color is resolved from the local holding its base color, so
    // the dependency between the two is enforced by the compiler.
    final surface = resolveProperty(
      'surface',
      () => isDark ? _baselineDarkSurface : _white,
    );
    final onSurface = resolveProperty(
      'onSurface',
      () => contrastingColor(surface),
    );
    final primary = resolveProperty(
      'primary',
      () => isDark ? _baselineDarkPrimary : _baselineLightPrimary,
    );
    final onPrimary = resolveProperty(
      'onPrimary',
      () => contrastingColor(primary),
    );
    // A theme that names no secondary color is better served by reusing its
    // primary than by Material's unrelated baseline teal.
    final secondary = resolveProperty('secondary', () => primary);
    final onSecondary = resolveProperty(
      'onSecondary',
      () => contrastingColor(secondary),
    );
    final error = resolveProperty(
      'error',
      () => isDark ? _baselineDarkError : _baselineLightError,
    );
    final onError = resolveProperty('onError', () => contrastingColor(error));

    return ResolvedColorScheme(
      colors: {
        'surface': surface,
        'onSurface': onSurface,
        'primary': primary,
        'onPrimary': onPrimary,
        'secondary': secondary,
        'onSecondary': onSecondary,
        'error': error,
        'onError': onError,
      },
      substitutedTokens: substituted,
    );
  }

  /// Returns opaque black or white, whichever reads better on [background].
  ///
  /// Uses the WCAG relative luminance crossover, the point at which black and
  /// white have equal contrast against the background.
  static int contrastingColor(int background) =>
      relativeLuminance(background) > 0.179 ? _black : _white;

  /// WCAG 2.x relative luminance of an ARGB color, ignoring its alpha.
  static double relativeLuminance(int argb) {
    double linearize(int channel) {
      final s = channel / 255;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * linearize((argb >> 16) & 0xFF) +
        0.7152 * linearize((argb >> 8) & 0xFF) +
        0.0722 * linearize(argb & 0xFF);
  }
}
