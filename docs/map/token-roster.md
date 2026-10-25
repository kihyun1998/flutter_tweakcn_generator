# token-roster

## The fact
The 32 color tokens and the 8 shadow levels are listed twice, in the same order:
once for reading (`CssParser._colorVariables`, `CssParser._shadowVariables`) and
once for emitting (`DartThemeGenerator._extensionColorTokens`,
`DartThemeGenerator._shadowTokens`). The two color lists must name the same
tokens, and so must the two shadow lists.

Checked at 2980252 by extracting the quoted names from each pair and diffing
them: identical.

## Why it is cross-cutting
The parser decides which `--variables` reach `ThemeModeData`; the generator
decides which fields the extensions carry and which keys the runtime factories
read. Neither list is derived from the other, and the parser and generator share
no constant for it. The parser does not know what is emitted, and the generator
does not know what was parsed. The generator just reads `colors[token]` and
writes the placeholder when the key is absent.

## Territories it holds in
- [css-reading](css-reading.md): `CssParser._colorVariables`, `_shadowVariables`, read in `_parseMode`
- [color-extension](color-extension.md): `DartThemeGenerator._extensionColorTokens`, used for fields, constants, `fromMap`, `copyWith`, `lerp`, equality
- [shadows](shadows.md): `DartThemeGenerator._shadowTokens`, used for fields, constants and `fromShadowMap`
- [colorscheme-resolution](colorscheme-resolution.md): `ColorSchemeResolver.tokenMapping` names 13 of the 32, and has to stay a subset

## What a violation looks like
- **A token added to the generator only.** The field exists but is always
  `Color(0x00000000)`, because the parser never stores it. It compiles and passes
  every generator test. In an app, the widget that reads it is invisible.
- **A token added to the parser only.** It is parsed and counted in the CLI
  summary (`Colors: N light`), but nothing ever emits it.

## Discovery history
Found by reading during the map's first init (2026-10-25). No issue records a
divergence yet.

## Where it will recur
Any change that adds, renames or removes a tweakcn token. Read the token list in
tweakcn's `types/theme.ts` ([references](../agents/thegraph.md)) and edit both
lists in the same commit. `test/parser/css_parser_test.dart` and
`test/generator/dart_theme_generator_test.dart` each check their own side, and no
test compares the two lists with each other.
