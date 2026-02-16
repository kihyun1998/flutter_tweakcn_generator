import 'color_parser.dart';

/// A single parsed CSS `box-shadow` layer.
///
/// Maps to Flutter's `BoxShadow` in the generated code.
class ShadowData {
  /// Horizontal offset in logical pixels.
  final double offsetX;

  /// Vertical offset in logical pixels.
  final double offsetY;

  /// Blur radius in logical pixels.
  final double blurRadius;

  /// Spread radius in logical pixels (can be negative).
  final double spreadRadius;

  /// Shadow color as a 32-bit ARGB integer.
  final int color;

  const ShadowData({
    required this.offsetX,
    required this.offsetY,
    required this.blurRadius,
    required this.spreadRadius,
    required this.color,
  });

  @override
  String toString() =>
      'ShadowData($offsetX, $offsetY, $blurRadius, $spreadRadius, '
      '0x${color.toRadixString(16).padLeft(8, '0')})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowData &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          blurRadius == other.blurRadius &&
          spreadRadius == other.spreadRadius &&
          color == other.color;

  @override
  int get hashCode =>
      Object.hash(offsetX, offsetY, blurRadius, spreadRadius, color);
}

/// Parses CSS box-shadow values into [ShadowData] lists.
class ShadowParser {
  /// Parses a full box-shadow value which may contain multiple shadows
  /// separated by commas.
  ///
  /// Returns an empty list for `none` or unparseable values.
  static List<ShadowData> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'none') return [];

    final shadows = _splitShadows(trimmed);
    final result = <ShadowData>[];
    for (final shadow in shadows) {
      final parsed = _parseSingle(shadow.trim());
      if (parsed != null) result.add(parsed);
    }
    return result;
  }

  /// Splits multiple shadows by commas, but respects parentheses
  /// (e.g. inside `rgb()` or `hsl()`).
  static List<String> _splitShadows(String value) {
    final result = <String>[];
    var depth = 0;
    var start = 0;

    for (var i = 0; i < value.length; i++) {
      final ch = value[i];
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
      } else if (ch == ',' && depth == 0) {
        result.add(value.substring(start, i));
        start = i + 1;
      }
    }
    result.add(value.substring(start));
    return result;
  }

  /// Parses a single box-shadow value.
  /// Format: `[inset] <offset-x> <offset-y> [blur] [spread] [color]`
  static ShadowData? _parseSingle(String value) {
    var remaining = value.trim();

    // Skip `inset` keyword (we don't map it to BoxShadow)
    if (remaining.startsWith('inset')) {
      remaining = remaining.substring(5).trim();
    }

    // Extract color from the end or beginning
    int? color;
    String numericPart;

    // Try to find color function at the end: rgb(...), hsl(...), oklch(...)
    final colorFuncMatch = RegExp(
      r'((?:rgb|rgba|hsl|hsla|oklch)\([^)]+\))\s*$',
    ).firstMatch(remaining);

    if (colorFuncMatch != null) {
      color = ColorParser.parse(colorFuncMatch.group(1)!);
      numericPart = remaining.substring(0, colorFuncMatch.start).trim();
    } else {
      // Try hex color at the end
      final hexMatch = RegExp(r'(#[0-9a-fA-F]{3,8})\s*$').firstMatch(remaining);
      if (hexMatch != null) {
        color = ColorParser.parse(hexMatch.group(1)!);
        numericPart = remaining.substring(0, hexMatch.start).trim();
      } else {
        numericPart = remaining;
      }
    }

    // Parse numeric values (offset-x, offset-y, blur, spread)
    final nums = _parseNumericValues(numericPart);
    if (nums.length < 2) return null;

    return ShadowData(
      offsetX: nums[0],
      offsetY: nums[1],
      blurRadius: nums.length > 2 ? nums[2] : 0,
      spreadRadius: nums.length > 3 ? nums[3] : 0,
      color: color ?? 0xFF000000,
    );
  }

  static List<double> _parseNumericValues(String s) {
    final matches = RegExp(r'-?[\d.]+(?:px|rem|em)?').allMatches(s);
    return matches.map((m) {
      var val = m.group(0)!;
      // Strip units
      val = val.replaceAll(RegExp(r'px|rem|em'), '');
      return double.tryParse(val) ?? 0;
    }).toList();
  }
}
