# css-reading

## What it is
This territory decides which declarations in the pasted CSS become the theme.
It strips comments and `@theme` blocks, finds every rule styling `:root` (light)
and `.dark` (dark), merges them, and sorts each `--variable` into a color,
shadow, radius, spacing or font slot of `ThemeModeData`.

## Governing decisions
**None.** No decision record exists ([domain.md](../agents/domain.md)). tweakcn's
emitter is the binding reference for what arrives here
([references](../agents/thegraph.md)).

## Design model
From reading the source; no record states these rules.
- **Every block counts, in source order.** A selector can own several blocks
  (a bare `:root` beside one inside `@layer base`). A later declaration wins,
  as in a browser (`CssParser._extractBlock`, #9 `19a8a23`).
- **Conditional at-rules apply only as a fallback.** Blocks inside `@media`,
  `@supports` or `@container` are used only when the selector has no
  unconditional block (`_conditionalAtRules`, `_extractBlock`).
- **A qualified selector counts; a descendant selector does not.** `html.dark`
  is the dark theme, but `.dark .card` is not (`_appliesTo`).
- **Comments go first.** A `/*` that is never closed is left as text, so a
  truncated paste still yields a theme (`_removeComments`).
- **The last declaration in a block may omit its `;`** (`_declarationPattern`,
  #3 `16b3e31`).
- **A value that fails to parse is dropped.** A color or shadow that does not
  parse is left out of the map, not stored as an error (`_parseMode`).
- **Font stack, light first.** `TweakcnThemeData.resolvedFontSans` is light's
  stack, falling back to dark's, and a blank value counts as undeclared
  (#10 `03ed103`). How the stack becomes families is
  [font-stack](font-stack.md).
- **Input bound:** none. `CssParser.parse` takes the whole string, and the CLI
  reads the whole file (`_run`).

## Code
- `lib/src/parser/css_parser.dart`: `CssParser.parse`, `_removeComments`, `_removeAtThemeBlocks`, `_extractBlock`, `_appliesTo`, `_rulesIn`, `_isConditionalAtRule`, `_matchingBrace`, `_parseMode`, `_colorVariables`, `_shadowVariables`
- `lib/src/models/tweakcn_theme_data.dart`: `TweakcnThemeData` (`resolvedFontSans`, `lightFontSans`, `darkFontSans`, `_declared`), `ThemeModeData`
- tests: `test/parser/css_parser_test.dart`, `test/models/tweakcn_theme_data_test.dart`, `test/fixtures/`

## Reference behaviour
- tweakcn `utils/theme-style-generator.ts` produces the CSS read here. It emits
  `--shadow-2xs` … `--shadow-2xl` and the `.dark` block (lessons.md, `f8516cb`, 2026-08-02).
- tweakcn `types/theme.ts` lists every token (lessons.md, `f8516cb`, 2026-08-02).

## Cross-cutting invariants
- [token-roster](token-roster.md)

## Blast radius
- [color-values](color-values.md), [css-lengths](css-lengths.md), [shadows](shadows.md): each receives a raw value this territory chose. A value shape it starts passing through (a new unit, `var()`) arrives there unparsed.
- [color-extension](color-extension.md), [colorscheme-resolution](colorscheme-resolution.md): a token this territory stops storing becomes the transparent placeholder there, or a substituted fallback.
- [font-stack](font-stack.md): the light-first rule decides which stack every font step uses.
- [cli-run](cli-run.md): the summary counts parsed colors and shadows, and the font warning compares light's stack with dark's.

## Known holes / open
- `--spacing` is parsed into `ThemeModeData.spacing` and never emitted or used.
  The maintainer has not decided what it is for (maintainer, 2026-10-25).
- Only the tokens in `_colorVariables` are read. Any other `--variable` tweakcn
  emits is dropped silently.
