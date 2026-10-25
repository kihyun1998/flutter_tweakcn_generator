# color-values

## What it is
Turns one CSS color value into a 32-bit ARGB integer. The supported forms are
hex (`#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`), `rgb()`, `hsl()` and `oklch()`, each with
an optional alpha.

## Governing decisions
**None.**

## Design model
From reading the source.
- **The prefix picks the parser**, and anything else returns `null`
  (`ColorParser.parse`). [css-reading](css-reading.md) then drops the token.
- **oklch:** converted to OKLab, then to linear sRGB, then gamma-encoded
  (`_oklchToArgb`, `_linearToSrgb`). A percentage chroma is scaled by 0.4
  (`_parseOklch`).
- **Hex alpha comes last** (`#rrggbbaa`) and is moved to the front for ARGB
  (`_parseHex`).
- **Alpha** is accepted as a number or a percentage, and defaults to 1
  (`_parseAlpha`).

## Code
- `lib/src/parser/color_parser.dart`: `ColorParser.parse`, `_parseHex`, `_parseRgb`, `_parseHsl`, `_hslToArgb`, `_parseOklch`, `_oklchToArgb`, `_linearToSrgb`, `_splitColorArgs`, `_parseAlpha`, `_argb`
- tests: `test/parser/color_parser_test.dart`

## Reference behaviour
**None.** This was never compared against a browser's or tweakcn's own
conversion.

## Cross-cutting invariants
**None.**

## Blast radius
- [shadows](shadows.md): `ShadowParser` parses each layer's color through `ColorParser`, so a change here changes every shadow color.
- [color-extension](color-extension.md), [colorscheme-resolution](colorscheme-resolution.md): every emitted color passes through here. `contrastingColor` reads the luminance of these values.

## Known holes / open
- Gamut handling for out-of-range oklch values (clip or map) was not checked
  against a reference.
- Named colors (`red`), `color()` and `lab()` are not parsed. A token using one
  is dropped.
