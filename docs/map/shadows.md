# shadows

## What it is
This territory parses each `--shadow-*` level into a list of layers, and emits
the `<Prefix>Shadows` `ThemeExtension`. That covers eight `List<BoxShadow>`
fields, the `light`/`dark` constants, the `<Prefix>ShadowLayer` record typedef,
and the runtime factory `fromShadowMap`.

## Governing decisions
**None.**

## Design model
From reading the source.
- **A level is a comma-separated list of layers**, and commas inside parentheses
  are not separators (`ShadowParser._splitShadows`). Layers keep the order the
  CSS lists them in, in the constants and in the factory alike.
- **`none`, an empty value or an unparseable layer yields nothing.** A level
  missing from the CSS comes out as `[]` (`_writeShadowInstance`,
  `_writeShadowsFromMap`).
- **Numbers go through [css-lengths](css-lengths.md)** and the color through
  [color-values](color-values.md).
- **Equality is element-wise**, because a `List` is equal only to itself
  (`_writeValueEquality(fieldsAreLists: true)`).
- **The layer type is a structural record**, so the generated file never names a
  type from this package ([shadow-layer-record](shadow-layer-record.md)).

## Code
- `lib/src/parser/shadow_parser.dart`: `ShadowLayer`, `ShadowData` (`toLayer`), `ShadowParser.parse`, `_splitShadows`, `_parseSingle`, `_parseNumericValues`
- `lib/src/models/tweakcn_theme_data.dart`: `ThemeModeData.shadows`, `ThemeModeData.shadowLayers`
- `lib/src/generator/dart_theme_generator.dart`: `_shadowTokens`, `_writeShadowsExtension`, `_writeShadowLayerTypedef`, `_writeShadowsFromMap`, `_writeShadowInstance`, `_shadowCamelCase`
- tests: `test/parser/shadow_parser_test.dart`, `test/models/shadow_layers_test.dart`; `example/test/tweakcn_theme_test.dart` group `TweakcnShadows.fromShadowMap`

## Reference behaviour
- tweakcn stores a shadow as *components* (`shadow-color`, `opacity`, `blur`,
  `spread`, `offset-x`, `offset-y` in `types/theme.ts`) and derives the eight
  levels in `utils/theme-style-generator.ts:62-69`. This package parses those
  derived levels, so a question about what a shadow means is answered one step
  upstream of the CSS it reads (lessons.md, `f8516cb`, 2026-08-02).

## Cross-cutting invariants
- [token-roster](token-roster.md)
- [shadow-layer-record](shadow-layer-record.md)
- [constant-equals-factory](constant-equals-factory.md)

## Blast radius
- [public-api](public-api.md): `ThemeModeData.shadowLayers` and `fromShadowMap` form the runtime seam.
- [verification](verification.md): only `example/`'s `flutter test` compiles the two record declarations together.

## Known holes / open
- **An `inset` layer becomes an outer shadow.** `_parseSingle` strips the
  keyword and keeps the layer, because `BoxShadow` has no inset form. The theme
  then draws an outer shadow where the CSS asked for an inner one, and nothing
  warns.
