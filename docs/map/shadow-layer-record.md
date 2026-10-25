# shadow-layer-record

## The fact
One shadow layer crosses from the package into generated code as a record
`({double offsetX, double offsetY, double blurRadius, double spreadRadius, int color})`.
It is declared twice: as `ShadowLayer` in `lib/src/parser/shadow_parser.dart`,
and as `<Prefix>ShadowLayer` in the generated file, written by
`DartThemeGenerator._writeShadowLayerTypedef`. Record types are structural, so
the two are the same type exactly when their field names and types match.

## Why it is cross-cutting
The generated file must not import this package
([generated-file](generated-file.md)), so neither declaration can refer to the
other. `ThemeModeData.shadowLayers` produces the first one, and the generated
`fromShadowMap` takes the second.

## Territories it holds in
- [shadows](shadows.md): `ShadowLayer`, `ShadowData.toLayer`, `_writeShadowLayerTypedef`, `_writeShadowsFromMap`
- [public-api](public-api.md): `ThemeModeData.shadowLayers` is what a runtime consumer passes in
- [verification](verification.md): `cd example && flutter test` is the one compilation holding both declarations

## What a violation looks like
Add or rename a field on one side only, and a runtime consumer's
`TweakcnShadows.fromShadowMap(theme.light.shadowLayers)` stops compiling.
`dart test` stays green, because it compares text.

## Discovery history
- The record shape was chosen for #15 (`2b5ce8b`). Its dartdoc says the example's
  tests are the only place both declarations are compiled together.
- `CLAUDE.md` names this as the one seam that only `cd example && flutter test`
  type-checks. Confirmed by `example/test/tweakcn_theme_test.dart`,
  `takes shadow data naming no type from this package`.

## Where it will recur
Any change to a field of `ShadowData` / `ShadowLayer`, or to what the generated
typedef declares. The same applies to any future factory that takes a record
rather than a primitive map.
