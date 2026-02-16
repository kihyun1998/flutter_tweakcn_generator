import 'dart:math' as math;

/// Parses CSS color strings into 32-bit ARGB integer values.
///
/// Supported formats:
/// - **Hex**: `#rgb`, `#rrggbb`, `#rrggbbaa`
/// - **RGB**: `rgb(255, 0, 0)`, `rgb(255 0 0 / 0.5)`
/// - **HSL**: `hsl(0 100% 50%)`, `hsl(0, 100%, 50%, 0.5)`
/// - **OKLCH**: `oklch(0.5 0.2 240)`, `oklch(0.5 0.2 240 / 0.8)`
class ColorParser {
  static const int _fullAlpha = 0xFF000000;

  /// Parses a CSS color string and returns a 32-bit ARGB integer.
  /// Returns `null` if the format is not recognized.
  static int? parse(String raw) {
    final value = raw.trim();
    if (value.startsWith('#')) return _parseHex(value);
    if (value.startsWith('rgb')) return _parseRgb(value);
    if (value.startsWith('hsl')) return _parseHsl(value);
    if (value.startsWith('oklch')) return _parseOklch(value);
    return null;
  }

  // -- Hex ----------------------------------------------------------------

  static int? _parseHex(String value) {
    var hex = value.substring(1);
    switch (hex.length) {
      case 3: // #RGB → #RRGGBB
        hex = hex.split('').map((c) => '$c$c').join();
      case 4: // #RGBA → #RRGGBBAA
        hex = hex.split('').map((c) => '$c$c').join();
      case 6: // #RRGGBB
        break;
      case 8: // #RRGGBBAA
        break;
      default:
        return null;
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;

    if (hex.length == 8) {
      // RRGGBBAA → AARRGGBB
      final r = (parsed >> 24) & 0xFF;
      final g = (parsed >> 16) & 0xFF;
      final b = (parsed >> 8) & 0xFF;
      final a = parsed & 0xFF;
      return (a << 24) | (r << 16) | (g << 8) | b;
    }
    return _fullAlpha | parsed;
  }

  // -- RGB ----------------------------------------------------------------

  static int? _parseRgb(String value) {
    // rgb(255, 255, 255) or rgb(255 255 255) or rgba(255, 255, 255, 0.5)
    // Also supports rgb(255 255 255 / 0.5)
    final inner = _extractParens(value);
    if (inner == null) return null;

    final parts = _splitColorArgs(inner);
    if (parts.length < 3) return null;

    final r = _parseColorComponent(parts[0], 255);
    final g = _parseColorComponent(parts[1], 255);
    final b = _parseColorComponent(parts[2], 255);
    final a = parts.length >= 4 ? _parseAlpha(parts[3]) : 1.0;

    if (r == null || g == null || b == null) return null;

    return _argb(a, r.round(), g.round(), b.round());
  }

  // -- HSL ----------------------------------------------------------------

  static int? _parseHsl(String value) {
    // hsl(0 0% 100%) or hsl(0, 0%, 100%) or hsl(0 0% 100% / 0.5)
    final inner = _extractParens(value);
    if (inner == null) return null;

    final parts = _splitColorArgs(inner);
    if (parts.length < 3) return null;

    final h = _parseNumber(parts[0]); // degrees
    final s = _parsePercentage(parts[1]); // 0-1
    final l = _parsePercentage(parts[2]); // 0-1
    final a = parts.length >= 4 ? _parseAlpha(parts[3]) : 1.0;

    if (h == null || s == null || l == null) return null;

    return _hslToArgb(h, s, l, a);
  }

  static int _hslToArgb(double h, double s, double l, double a) {
    // Normalize hue to 0-360
    final hue = ((h % 360) + 360) % 360;

    final c = (1 - (2 * l - 1).abs()) * s;
    final x = c * (1 - ((hue / 60) % 2 - 1).abs());
    final m = l - c / 2;

    double r, g, b;
    if (hue < 60) {
      (r, g, b) = (c, x, 0.0);
    } else if (hue < 120) {
      (r, g, b) = (x, c, 0.0);
    } else if (hue < 180) {
      (r, g, b) = (0.0, c, x);
    } else if (hue < 240) {
      (r, g, b) = (0.0, x, c);
    } else if (hue < 300) {
      (r, g, b) = (x, 0.0, c);
    } else {
      (r, g, b) = (c, 0.0, x);
    }

    return _argb(
      a,
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
    );
  }

  // -- OKLCH ----------------------------------------------------------------

  static int? _parseOklch(String value) {
    // oklch(0.5 0.2 240) or oklch(0.5 0.2 240 / 0.8)
    // L: 0-1, C: 0-0.4, H: 0-360
    final inner = _extractParens(value);
    if (inner == null) return null;

    final parts = _splitColorArgs(inner);
    if (parts.length < 3) return null;

    final lRaw = parts[0].trim();
    final cRaw = parts[1].trim();
    final hRaw = parts[2].trim();

    final L = lRaw.endsWith('%') ? _parsePercentage(lRaw) : _parseNumber(lRaw);
    final C = cRaw.endsWith('%')
        ? (_parsePercentage(cRaw) != null
            ? _parsePercentage(cRaw)! * 0.4
            : null)
        : _parseNumber(cRaw);
    final h = _parseNumber(hRaw); // degrees

    final a = parts.length >= 4 ? _parseAlpha(parts[3]) : 1.0;

    if (L == null || C == null || h == null) return null;

    return _oklchToArgb(L, C, h, a);
  }

  static int _oklchToArgb(double L, double C, double h, double a) {
    // OKLCH → OKLab
    final hRad = h * math.pi / 180;
    final labA = C * math.cos(hRad);
    final labB = C * math.sin(hRad);

    // OKLab → linear sRGB
    final l_ = L + 0.3963377774 * labA + 0.2158037573 * labB;
    final m_ = L - 0.1055613458 * labA - 0.0638541728 * labB;
    final s_ = L - 0.0894841775 * labA - 1.2914855480 * labB;

    final l3 = l_ * l_ * l_;
    final m3 = m_ * m_ * m_;
    final s3 = s_ * s_ * s_;

    final r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
    final g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
    final b = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

    return _argb(
      a,
      _linearToSrgb(r),
      _linearToSrgb(g),
      _linearToSrgb(b),
    );
  }

  static int _linearToSrgb(double c) {
    final clamped = c.clamp(0.0, 1.0);
    final srgb = clamped <= 0.0031308
        ? 12.92 * clamped
        : 1.055 * math.pow(clamped, 1.0 / 2.4) - 0.055;
    return (srgb * 255).round().clamp(0, 255);
  }

  // -- Helpers --------------------------------------------------------------

  static String? _extractParens(String value) {
    final start = value.indexOf('(');
    final end = value.lastIndexOf(')');
    if (start < 0 || end < 0 || end <= start) return null;
    return value.substring(start + 1, end);
  }

  /// Splits color arguments, handling both comma-separated and
  /// space-separated (with optional `/` for alpha) formats.
  static List<String> _splitColorArgs(String inner) {
    // Check for `/` separator (modern syntax alpha)
    String mainPart;
    String? alphaPart;
    final slashIndex = inner.indexOf('/');
    if (slashIndex >= 0) {
      mainPart = inner.substring(0, slashIndex).trim();
      alphaPart = inner.substring(slashIndex + 1).trim();
    } else {
      mainPart = inner;
    }

    List<String> parts;
    if (mainPart.contains(',')) {
      parts = mainPart.split(',').map((s) => s.trim()).toList();
      // Legacy rgba(r, g, b, a) - alpha may be in the 4th comma-separated arg
      if (parts.length == 4 && alphaPart == null) {
        alphaPart = parts.removeLast();
      }
    } else {
      parts =
          mainPart.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    }

    if (alphaPart != null) {
      parts.add(alphaPart);
    }
    return parts;
  }

  static double? _parseNumber(String s) {
    return double.tryParse(s.trim());
  }

  /// Parses a percentage string like "50%" and returns 0.0-1.0.
  static double? _parsePercentage(String s) {
    final trimmed = s.trim();
    if (!trimmed.endsWith('%')) return null;
    final num = double.tryParse(trimmed.substring(0, trimmed.length - 1));
    if (num == null) return null;
    return num / 100;
  }

  /// Parses a color component that can be either a number or percentage.
  static double? _parseColorComponent(String s, double maxVal) {
    final trimmed = s.trim();
    if (trimmed.endsWith('%')) {
      final pct = _parsePercentage(trimmed);
      return pct != null ? pct * maxVal : null;
    }
    return _parseNumber(trimmed);
  }

  /// Parses alpha value (number 0-1, or percentage).
  static double _parseAlpha(String s) {
    final trimmed = s.trim();
    if (trimmed.endsWith('%')) {
      return _parsePercentage(trimmed) ?? 1.0;
    }
    return double.tryParse(trimmed) ?? 1.0;
  }

  static int _argb(double a, int r, int g, int b) {
    final alpha = (a.clamp(0.0, 1.0) * 255).round();
    return (alpha << 24) |
        (r.clamp(0, 255) << 16) |
        (g.clamp(0, 255) << 8) |
        b.clamp(0, 255);
  }
}
