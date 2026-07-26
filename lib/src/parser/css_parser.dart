import '../models/tweakcn_theme_data.dart';
import 'color_parser.dart';
import 'css_length.dart';
import 'shadow_parser.dart';

/// One `selector { ... }` rule, and whether it only applies in some
/// conditions.
typedef _Rule = ({String prelude, String body, bool conditional});

/// Parses tweakcn CSS into [TweakcnThemeData].
///
/// Extracts design tokens from `:root { }` (light) and `.dark { }` (dark)
/// blocks. Automatically strips `@theme inline { }` blocks added by
/// Tailwind CSS v4.
///
/// Recognized tokens:
/// - **Colors**: 32 named color variables (e.g. `--primary`, `--background`)
/// - **Shadows**: 8 shadow levels (`--shadow-2xs` through `--shadow-2xl`)
/// - **Radius**: `--radius` (CSS length → logical pixels)
/// - **Spacing**: `--spacing` (CSS length → logical pixels)
/// - **Font**: `--font-sans` (raw CSS font stack)
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

  /// Parses a full CSS string copied from [tweakcn.com](https://tweakcn.com).
  static TweakcnThemeData parse(String css) {
    // Comments go first: a brace or a declaration inside one would otherwise
    // be read as real syntax.
    final cleaned = _removeAtThemeBlocks(_removeComments(css));

    final rootVars = _extractBlock(cleaned, ':root');
    final darkVars = _extractBlock(cleaned, '.dark');

    return TweakcnThemeData(
      light: _parseMode(rootVars),
      dark: _parseMode(darkVars),
    );
  }

  /// Matches a CSS comment. Comments do not nest, so `/*` runs to the *next*
  /// `*/` however many `/*` lie between — the same rule a CSS tokenizer uses.
  static final _commentPattern = RegExp(r'/\*.*?\*/', dotAll: true);

  /// Matches one `--variable: value` declaration.
  ///
  /// CSS lets the *last* declaration in a block drop its semicolon, so the
  /// terminator is either a `;` or the end of the subject string. This pattern
  /// is applied to one block's contents at a time and is deliberately not
  /// `multiLine`, so `$` means the closing brace of that block rather than the
  /// end of any line.
  static final _declarationPattern = RegExp(
    r'--([a-zA-Z0-9_-]+)\s*:\s*([^;]+?)\s*(?:;|$)',
  );

  /// Removes `/* ... */` comments from CSS.
  ///
  /// A `/*` with no `*/` after it anywhere is left alone. A CSS tokenizer would
  /// treat it as running to the end of the file; keeping the text instead means
  /// a truncated paste still yields a theme rather than silently losing every
  /// declaration after the stray marker.
  static String _removeComments(String css) =>
      css.replaceAll(_commentPattern, '');

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

      i = _matchingBrace(css, braceStart) + 1;
    }

    return buffer.toString();
  }

  /// At-rules whose contents apply only sometimes. A theme generator renders
  /// one stylesheet, so what these hold must not override what always applies.
  static const _conditionalAtRules = {'@media', '@supports', '@container'};

  /// Extracts CSS variables from every block [selector] owns.
  ///
  /// A selector may appear more than once — a bare `:root` alongside another
  /// inside `@layer base`, say. Those blocks are merged in source order so a
  /// later declaration overrides an earlier one, as a browser resolves them.
  ///
  /// Blocks inside a conditional at-rule are used only when the selector has
  /// no unconditional block at all. Otherwise a `@media print` override would
  /// become the theme, which is not what any screen would render.
  static Map<String, String> _extractBlock(String css, String selector) {
    final matching =
        _rulesIn(
          css,
          0,
          css.length,
          conditional: false,
        ).where((rule) => _appliesTo(rule.prelude, selector)).toList();

    final unconditional = matching.where((r) => !r.conditional).toList();
    final chosen = unconditional.isNotEmpty ? unconditional : matching;

    final vars = <String, String>{};
    for (final rule in chosen) {
      for (final match in _declarationPattern.allMatches(rule.body)) {
        vars[match.group(1)!] = match.group(2)!.trim();
      }
    }
    return vars;
  }

  /// Whether a rule written as [prelude] styles [selector].
  ///
  /// A prelude may list several selectors, and each may be qualified —
  /// `html.dark` and `.card.dark` are both the dark theme. A descendant
  /// combinator is not: `.dark .card` styles something inside the dark theme,
  /// not the theme itself, so its declarations are not the theme's.
  static bool _appliesTo(String prelude, String selector) => prelude
      .split(',')
      .map((part) => part.trim())
      .any((part) => part.endsWith(selector));

  /// Collects the style rules between [start] and [end], descending through
  /// at-rules and remembering whether their contents are conditional.
  static List<_Rule> _rulesIn(
    String css,
    int start,
    int end, {
    required bool conditional,
  }) {
    final rules = <_Rule>[];
    var preludeStart = start;
    var i = start;

    while (i < end) {
      final char = css[i];

      // A prelude runs from the end of the previous statement or block.
      if (char == ';' || char == '}') {
        preludeStart = ++i;
        continue;
      }
      if (char != '{') {
        i++;
        continue;
      }

      final prelude = css.substring(preludeStart, i).trim();
      final close = _matchingBrace(css, i);
      final bodyEnd = close < end ? close : end;

      if (prelude.startsWith('@')) {
        rules.addAll(
          _rulesIn(
            css,
            i + 1,
            bodyEnd,
            conditional: conditional || _isConditionalAtRule(prelude),
          ),
        );
      } else {
        rules.add((
          prelude: prelude,
          body: css.substring(i + 1, bodyEnd),
          conditional: conditional,
        ));
      }

      i = bodyEnd + 1;
      preludeStart = i;
    }

    return rules;
  }

  /// Whether [prelude] opens an at-rule whose contents apply only sometimes.
  static bool _isConditionalAtRule(String prelude) {
    final name = prelude.split(RegExp(r'[\s(]')).first.toLowerCase();
    return _conditionalAtRules.contains(name);
  }

  /// The index of the `}` closing the block opened at [braceStart], or the end
  /// of [css] when the block is never closed.
  static int _matchingBrace(String css, int braceStart) {
    var depth = 0;
    for (var i = braceStart; i < css.length; i++) {
      if (css[i] == '{') depth++;
      if (css[i] == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return css.length;
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
        radius = CssLength.toPixels(value);
      } else if (name == 'spacing') {
        spacing = CssLength.toPixels(value);
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
}
