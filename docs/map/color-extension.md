# color-extension

## What it is
This territory emits the `<Prefix>Colors` `ThemeExtension`: one `Color` field
per roster token, the `light` and `dark` constants, the runtime factory
`fromMap`, and `copyWith`, `lerp` and value equality.

## Governing decisions
**None.**

## Design model
From reading the source.
- **The extension carries every token**, including the ones `ColorScheme` also
  maps (the comment on `_extensionColorTokens`).
- **A token the CSS does not define is `Color(0x00000000)`.** It is fully
  transparent, so a widget that reads it shows nothing rather than a color that
  looks deliberate. The constants and `fromMap` share the same placeholder
  (`DartThemeGenerator._missingColorArgb`).
- **`fromMap` takes `Map<String, int>`**, not a type from this package
  ([generated-file](generated-file.md)). It is written from the same
  `_extensionColorTokens` loop as every other member, so it fills a newly added
  token automatically.

## Code
- `lib/src/generator/dart_theme_generator.dart`: `_extensionColorTokens`, `_writeColorsExtension`, `_writeColorsInstance`, `_writeColorsFromMap`, `_missingColorArgb`, `_colorLiteral`, `_argbLiteral`, `_toCamelCase`
- tests: `test/generator/dart_theme_generator_test.dart`; `example/test/tweakcn_theme_test.dart` group `TweakcnColors.fromMap`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [token-roster](token-roster.md)
- [constant-equals-factory](constant-equals-factory.md)

## Blast radius
- [colorscheme-resolution](colorscheme-resolution.md): for a missing token this extension shows transparent, while `ColorScheme` shows a derived fallback. The two differ by design, and the difference is the subject of #22.
- [public-api](public-api.md): `fromMap` is half of the runtime-consumer seam. `ThemeModeData.colors` is the key and value shape it reads.
- [generated-file](generated-file.md): field names come from `_toCamelCase`, and `ThemeData` registers the `light`/`dark` constants.

## Known holes / open
**None.**
