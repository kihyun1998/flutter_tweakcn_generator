# radius-steps

## What it is
This territory emits the `<Prefix>Radius` `ThemeExtension`. The four steps come
from `--radius`: `sm = r − 4`, `md = r − 2`, `lg = r`, `xl = r + 4`. `sm` and
`md` are held at zero. The territory also emits the `standard` constant and the
runtime factory `fromRadius`.

## Governing decisions
**None** as a record. The derivation is tweakcn's, and tweakcn is binding
([references](../agents/thegraph.md)). shadcn/ui is listed there as an example
only.

## Design model
From the source and its cited upstream (the dartdoc of
`DartThemeGenerator._writeRadiusExtension`).
- **The offsets are tweakcn's.** `utils/theme-style-generator.ts` writes
  `calc(var(--radius) - 4px)`, `- 2px`, `var(--radius)` and `+ 4px` into both of
  tweakcn's outputs. That block ships inside the globals.css the user copies, so
  the generated values match what their own web app computes.
- **Clamp at zero, below the base only.** CSS Values 4 §calc-range clamps a
  negative `calc()` result instead of dropping the declaration. A negative
  `--radius` has no single browser behaviour to reproduce, so `lg` and `xl` are
  left alone (`_atLeastZero` dartdoc).
- **One radius per `ThemeData`.** The radius is light's, falling back to dark's,
  then to `_defaultRadius` (8.0). The constant and `fromRadius(null)` reach the
  same steps.
- **Testing this territory:**
  - **A test at the default input proves nothing about the formula.**
    `generates radius values from CSS (0.625rem = 10px)` passes under both
    formulas. Only the 2px and zero-radius tests tell them apart (#31, measured in
    lessons.md, `94847d8`, 2026-08-04).

## Code
- `lib/src/generator/dart_theme_generator.dart`: `_defaultRadius`, `_atLeastZero`, `_writeRadiusExtension`, `_writeRadiusFromRadius`
- tests: `test/generator/dart_theme_generator_test.dart`; `example/test/tweakcn_theme_test.dart` group `TweakcnRadius.fromRadius`

## Reference behaviour
- tweakcn `utils/theme-style-generator.ts` `:174-177` (Tailwind v4 `@theme inline`)
  and `:256-259` (v3 config). These lines settle the offsets, as cited in the
  generator's dartdoc. Re-check them the day tweakcn's emitter moves.
- tweakcn `config/theme.ts:53` sets the default radius to `0.625rem` = 10px.
- shadcn/ui v4 `apps/v4/app/globals.css:50-53` scales instead (`* 0.6`, `* 0.8`,
  `* 1.4`). The two formulas agree only at r = 10, because all three step
  equations have that one root (#31, `94847d8`).

## Cross-cutting invariants
- [constant-equals-factory](constant-equals-factory.md): the offsets and the clamp appear once as Dart arithmetic and once as emitted text.

## Blast radius
- [css-lengths](css-lengths.md): `--radius` arrives already converted. A unit misread there scales every step.
- [public-api](public-api.md): `fromRadius` is part of the runtime seam. `README.md` → "Building a theme at runtime" restates the derivation.
- [shipping](shipping.md): `CHANGELOG.md` 0.5.1 and the generated dartdoc both cite the derivation. A change here is a consumer-visible diff in the committed theme.

## Known holes / open
- The 8px default for a theme with no `--radius` has no recorded source.
