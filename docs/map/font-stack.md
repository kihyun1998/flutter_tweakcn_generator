# font-stack

## What it is
This territory turns the resolved `--font-sans` stack into the ordered list of
font families the theme names, and decides how the theme class names them in
each mode. Every font step downstream receives this list.

## Governing decisions
**None.**

## Design model
From the source (`DartThemeGenerator.extractGoogleFontNames`, `_writeThemeClass`).
- **Families are read until the first generic keyword.** Anything from
  `ui-sans-serif`, `system-ui`, `sans-serif` and the rest of
  `_genericFontKeywords` onward is ignored. User-chosen fonts come first in a CSS
  stack. A pure system stack gives `[]`.
- **The first family is primary; the rest are fallbacks.** In local and custom
  mode the theme writes `fontFamily: 'X'` and `fontFamilyFallback: [...]`. In
  google_fonts mode, see [google-fonts-mode](google-fonts-mode.md).
- **Light's stack wins** (`TweakcnThemeData.resolvedFontSans`). The CLI warns
  when dark's stack resolves to different families (`_run`).
- **The family name is used as written in the CSS**, with quotes stripped. The
  same string becomes the `fontFamily` literal, the pubspec `family:` and the
  readiness check's key, and nothing normalizes it in between.

## Code
- `lib/src/generator/dart_theme_generator.dart`: `extractGoogleFontNames`, `_genericFontKeywords`, `_writeThemeClass`
- `bin/flutter_tweakcn_generator.dart`: `googleFonts` in `_run`, the light/dark warning
- tests: `test/cli/font_sans_conflict_test.dart`, `test/generator/dart_theme_generator_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [google-fonts-mode](google-fonts-mode.md), [font-download](font-download.md), [custom-font-scan](custom-font-scan.md): each gets this exact list, and a family split or merged differently here becomes a different download, a different scan or a different method name.
- [font-cleanup](font-cleanup.md): an empty list from a parsing miss would condemn everything. See [empty-means-unknown](empty-means-unknown.md).
- [cli-run](cli-run.md): the exit-code readiness check compares these strings exactly against pubspec's families.

## Known holes / open
- The name `extractGoogleFontNames` is misleading: it returns every non-generic
  family, whether or not Google Fonts serves it.
- `Segoe UI`, `Arial` and `SF Pro Display` sit early in stacks tweakcn commonly
  emits and are not Google Fonts. In local mode they reach the downloader and get
  a 400 ([font-download](font-download.md); lessons.md, `9dd3b11`, 2026-08-02).
