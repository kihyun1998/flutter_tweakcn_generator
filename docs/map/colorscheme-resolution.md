# colorscheme-resolution

## What it is
This territory maps tweakcn color tokens onto Flutter's `ColorScheme`, and
always resolves the eight color parameters `ColorScheme` marks `required`, even
when the CSS does not define them. It also reports which tokens were
substituted, so the CLI can warn.

## Governing decisions
**None.** The required parameter set is Flutter's, from
`packages/flutter/lib/src/material/color_scheme.dart`. That reference is binding
([references](../agents/thegraph.md)).

## Design model
From reading the source (`ColorSchemeResolver` dartdoc).
- **Every required property is always emitted.** Leaving one out produces a
  file that does not compile (#2 `17bfc18`). Optional properties are emitted only
  when defined (`DartThemeGenerator._writeColorScheme`).
- **Fallbacks, in order of preference:**
  - an `on*` color is black or white, whichever contrasts better with its base
    (`contrastingColor`, WCAG crossover at luminance 0.179);
  - a missing `secondary` reuses `primary`;
  - anything else falls back to Material's baseline (`_baselineLightPrimary` and
    friends).
- **An `on*` color is computed from its base's local variable**, so the compiler
  enforces the dependency (`resolve`).
- **`tokenMapping` defines `requiredTokens`**, so the two cannot diverge.
- **The generator resolves each mode once.** The emitted code and
  `substitutedColorSchemeTokens` share that result
  (`DartThemeGenerator._resolvedColorSchemes`).

## Code
- `lib/src/generator/color_scheme_resolver.dart`: `ColorSchemeResolver.tokenMapping`, `requiredProperties`, `requiredTokens`, `resolve`, `contrastingColor`, `relativeLuminance`; `ResolvedColorScheme`
- `lib/src/generator/dart_theme_generator.dart`: `_resolvedColorSchemes`, `_writeColorSchemes`, `_writeColorScheme`, `substitutedColorSchemeTokens`
- `bin/flutter_tweakcn_generator.dart`: the substitution warning in `_run`
- tests: `test/generator/color_scheme_resolver_test.dart`, `test/cli/color_scheme_warning_test.dart`

## Reference behaviour
- Flutter `color_scheme.dart`: which parameters are `required`. A new one in a
  Flutter release breaks the generated file. CI's `generated-output` job is
  deliberately not pinned to a Flutter version, so it catches this (`ci.yml`).
- The baseline values match `ColorScheme.light()` / `.dark()` (code comment
  above `_baselineLightPrimary`; not re-checked against the SDK).

## Cross-cutting invariants
- [token-roster](token-roster.md): `tokenMapping` must stay a subset of the roster.

## Blast radius
- [public-api](public-api.md): this resolver is not exported, so a runtime consumer cannot reproduce the generated `ColorScheme` (#22).
- [cli-run](cli-run.md): the warning text is built from `substitutedColorSchemeTokens`.
- [verification](verification.md): the color-free and minimal cases in `tool/verify_generated_output.dart` exist to compile every fallback path.
- `README.md` → "ColorScheme Mapping" restates `tokenMapping` and the fallback rules, so it drifts when they change.

## Known holes / open
- There is no runtime factory for `ColorScheme`, unlike the three extensions.
  A live preview has to hand-copy these fallbacks. Tracked: #22.
