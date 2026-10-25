# css-lengths

## What it is
Turns a CSS length into the logical pixels Flutter lays out in. Radius, spacing
and shadow offsets all go through it.

## Governing decisions
**None.**

## Design model
From reading the source (`CssLength` dartdoc).
- **One conversion for every caller**, so a `rem` means the same thing in a
  radius as in a shadow. #8 (`eb23785`) fixed shadows reading `0.25rem` as
  0.25px, a 16× error.
- **`rem` and `em` are both × 16**, the browser default that tweakcn's values
  are written against. A theme file has no element whose font size an `em`
  could inherit.
- **Units match case-insensitively. A bare number is pixels.** Malformed values
  such as `1px2` are rejected (`_wholeLength`).
- **Reading a whole value and finding lengths inside a value** are built from
  the same regex pieces (`_number`, `_unit`), so the two cannot disagree on what
  a length is.

## Code
- `lib/src/parser/css_length.dart`: `CssLength.toPixels`, `CssLength.findAll`, `_rootFontSizePx`, `_number`, `_unit`, `_wholeLength`, `_embeddedLength`
- tests: `test/parser/css_length_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [radius-steps](radius-steps.md): `--radius` is converted here, and every step is derived from it.
- [shadows](shadows.md): `ShadowParser._parseNumericValues` is `CssLength.findAll`. The offsets, blur and spread are read here.

## Known holes / open
- `calc()`, `var()`, `%` and viewport units are not lengths here. A `--radius`
  written that way becomes `null`, which then falls back to the 8px default
  ([radius-steps](radius-steps.md)).
