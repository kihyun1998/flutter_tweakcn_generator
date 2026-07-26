/// Converts a CSS length to the logical pixels Flutter lays out in.
///
/// Radii, spacing and shadow offsets all arrive as lengths and all have to
/// agree on what a unit means, so both the conversion and the recognition of
/// what counts as a length live here: a `rem` that becomes 16px in a radius
/// cannot become 1px in a shadow.
class CssLength {
  CssLength._();

  /// The font size a `rem` is measured against.
  ///
  /// 16 logical pixels is the browser default that tweakcn's own values are
  /// authored against.
  static const _rootFontSizePx = 16.0;

  /// A CSS number: optional sign, digits either side of the point, optional
  /// exponent. `+1`, `-.5` and `1e-2` are all legal.
  static const _number = r'[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?';

  /// The length units this package understands.
  static const _unit = r'(?:px|rem|em)';

  /// Matches a whole string that is one length.
  static final _wholeLength = RegExp(
    '^($_number)($_unit)?\$',
    caseSensitive: false,
  );

  /// Finds lengths embedded in a longer value, such as a `box-shadow`.
  ///
  /// Built from the same pieces as [_wholeLength] so the two cannot come to
  /// disagree about what a length is.
  static final _embeddedLength = RegExp(
    '$_number$_unit?',
    caseSensitive: false,
  );

  /// Converts [value] to logical pixels, or returns `null` when it is not a
  /// length this package understands.
  ///
  /// `em` is treated the same as `rem`. A theme file has no element to inherit
  /// a font size from, so the root size is the only sensible reading. Units
  /// are matched case-insensitively, as CSS matches them.
  static double? toPixels(String value) {
    final match = _wholeLength.firstMatch(value.trim());
    if (match == null) return null;

    final number = double.tryParse(match.group(1)!);
    if (number == null) return null;

    return switch (match.group(2)?.toLowerCase()) {
      'rem' || 'em' => number * _rootFontSizePx,
      _ => number,
    };
  }

  /// Converts every length found in [value], in the order they appear.
  ///
  /// For values that hold several lengths at once, such as the offsets, blur
  /// and spread of a `box-shadow`.
  static List<double> findAll(String value) {
    final lengths = <double>[];
    for (final match in _embeddedLength.allMatches(value)) {
      // Recognition and conversion share a grammar, so anything found here
      // converts. Skipping rather than substituting keeps a hypothetical
      // failure from turning into a plausible-looking zero.
      final pixels = toPixels(match.group(0)!);
      if (pixels != null) lengths.add(pixels);
    }
    return lengths;
  }
}
