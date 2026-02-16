import '../models/tweakcn_theme_data.dart';
import 'color_parser.dart';
import 'shadow_parser.dart';

/// Parses tweakcn CSS into [TweakcnThemeData].
///
/// Recognizes `:root { }` (light) and `.dark { }` (dark) blocks.
/// Ignores `@theme inline { }` blocks (Tailwind-specific).
class CssParser {
  /// CSS variable names that represent colors.
  static const _colorVariables = {
    'background',
    'foreground',
    'card',
    'card-foreground',
    'popover',
    'popover-foreground',
    'primary',
    'primary-foreground',
    'secondary',
    'secondary-foreground',
    'muted',
    'muted-foreground',
    'accent',
    'accent-foreground',
    'destructive',
    'destructive-foreground',
    'border',
    'input',
    'ring',
    'chart-1',
    'chart-2',
    'chart-3',
    'chart-4',
    'chart-5',
    'sidebar',
    'sidebar-foreground',
    'sidebar-primary',
    'sidebar-primary-foreground',
    'sidebar-accent',
    'sidebar-accent-foreground',
    'sidebar-border',
    'sidebar-ring',
  };

  /// Shadow variable name prefixes.
  static const _shadowVariables = {
    'shadow-2xs',
    'shadow-xs',
    'shadow-sm',
    'shadow',
    'shadow-md',
    'shadow-lg',
    'shadow-xl',
    'shadow-2xl',
  };

  /// Parses a full CSS string from tweakcn.
  static TweakcnThemeData parse(String css) {
    // Remove @theme inline { ... } blocks
    final cleaned = _removeAtThemeBlocks(css);

    final rootVars = _extractBlock(cleaned, ':root');
    final darkVars = _extractBlock(cleaned, '.dark');

    return TweakcnThemeData(
      light: _parseMode(rootVars),
      dark: _parseMode(darkVars),
    );
  }

  /// Removes `@theme inline { ... }` blocks from CSS.
  static String _removeAtThemeBlocks(String css) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < css.length) {
      final atThemeIndex = css.indexOf('@theme', i);
      if (atThemeIndex < 0) {
        buffer.write(css.substring(i));
        break;
      }

      buffer.write(css.substring(i, atThemeIndex));

      // Find the opening brace
      final braceStart = css.indexOf('{', atThemeIndex);
      if (braceStart < 0) {
        buffer.write(css.substring(atThemeIndex));
        break;
      }

      // Find matching closing brace
      var depth = 0;
      var j = braceStart;
      for (; j < css.length; j++) {
        if (css[j] == '{') depth++;
        if (css[j] == '}') {
          depth--;
          if (depth == 0) break;
        }
      }
      i = j + 1;
    }

    return buffer.toString();
  }

  /// Extracts CSS variables from a block identified by [selector].
  static Map<String, String> _extractBlock(String css, String selector) {
    final vars = <String, String>{};

    // Find the selector
    var searchFrom = 0;
    while (true) {
      final selectorIndex = css.indexOf(selector, searchFrom);
      if (selectorIndex < 0) break;

      // Check it's not part of a larger word
      final afterSelector = selectorIndex + selector.length;
      if (afterSelector < css.length) {
        final nextChar = css[afterSelector];
        if (nextChar != ' ' &&
            nextChar != '{' &&
            nextChar != '\n' &&
            nextChar != '\r' &&
            nextChar != '\t') {
          searchFrom = afterSelector;
          continue;
        }
      }

      // Find the opening brace
      final braceStart = css.indexOf('{', selectorIndex);
      if (braceStart < 0) break;

      // Find matching closing brace
      var depth = 0;
      var braceEnd = braceStart;
      for (; braceEnd < css.length; braceEnd++) {
        if (css[braceEnd] == '{') depth++;
        if (css[braceEnd] == '}') {
          depth--;
          if (depth == 0) break;
        }
      }

      final blockContent = css.substring(braceStart + 1, braceEnd);

      // Extract --variable: value; pairs
      final varPattern = RegExp(r'--([a-zA-Z0-9_-]+)\s*:\s*([^;]+);');
      for (final match in varPattern.allMatches(blockContent)) {
        vars[match.group(1)!] = match.group(2)!.trim();
      }

      break; // Only take the first match
    }

    return vars;
  }

  /// Converts raw CSS variable map into [ThemeModeData].
  static ThemeModeData _parseMode(Map<String, String> vars) {
    final colors = <String, int>{};
    final shadows = <String, List<ShadowData>>{};
    double? radius;
    double? spacing;
    String? fontSans;

    for (final entry in vars.entries) {
      final name = entry.key;
      final value = entry.value;

      if (_colorVariables.contains(name)) {
        final color = ColorParser.parse(value);
        if (color != null) colors[name] = color;
      } else if (_shadowVariables.contains(name)) {
        final parsed = ShadowParser.parse(value);
        if (parsed.isNotEmpty) shadows[name] = parsed;
      } else if (name == 'radius') {
        radius = _parseRemToPixels(value);
      } else if (name == 'spacing') {
        spacing = _parseRemToPixels(value);
      } else if (name == 'font-sans') {
        fontSans = value;
      }
    }

    return ThemeModeData(
      colors: colors,
      radius: radius,
      spacing: spacing,
      shadows: shadows,
      fontSans: fontSans,
    );
  }

  /// Converts rem value to pixels (1rem = 16px).
  static double? _parseRemToPixels(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('rem')) {
      final num = double.tryParse(
        trimmed.substring(0, trimmed.length - 3).trim(),
      );
      return num != null ? num * 16 : null;
    }
    // Try plain number (assume px)
    return double.tryParse(trimmed.replaceAll('px', ''));
  }
}
