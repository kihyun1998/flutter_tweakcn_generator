# public-api

## What it is
This territory is what a consumer can import from
`package:flutter_tweakcn_generator`, and the second consumer mode it serves.
A **build-time** consumer only runs the CLI or builder and ships the generated
file. A **runtime** consumer parses CSS that end users paste (`CssParser.parse`)
and feeds the tokens to the generated factories, so for them this package's
public API is the seam.

## Governing decisions
**None** as a record. `CLAUDE.md` → "Boundary" names the two seams.

## Design model
- **Exported** (`lib/flutter_tweakcn_generator.dart`): `config`,
  `font_downloader`, `pubspec_font_adder`, `dart_theme_generator`,
  `tweakcn_theme_data`, `color_parser`, `css_parser`, `shadow_parser`. The
  builder entry point is `lib/builder.dart`.
- **Not exported:** `ColorSchemeResolver`, `CssLength`, `FontFamily`,
  `PubspecFontDeclarations`, `FontCleanup`, `CustomFontScanner`, the formatter
  and the language-version helpers.
- **Anything a live preview must reproduce has to be reachable from here**
  (`CLAUDE.md` → "Boundary"). The three extension factories meet this
  ([constant-equals-factory](constant-equals-factory.md)); the `ColorScheme` half
  does not (#22).
- **Runtime use moves the package from `dev_dependencies` to `dependencies`.**
  Only `CssParser` needs it. The factories name no package type (`README.md` →
  "Building a theme at runtime").
- **A consumer's report: first ask whose invariant broke.** For a missing token,
  a transparent color from `fromMap` is the contract. A consumer who wants
  `ColorScheme`'s fallback there has found a missing export, not a wrong fallback
  (`CLAUDE.md` → "Boundary"; #22).

## Code
- `lib/flutter_tweakcn_generator.dart`: the export list
- `lib/src/models/tweakcn_theme_data.dart`: `TweakcnThemeData`, `ThemeModeData` (`colors`, `radius`, `shadowLayers`)
- tests: `test/flutter_tweakcn_generator_test.dart`

## Reference behaviour
- The consumer `kihyun1998/mobile_init_project` uses both modes (#22). It was
  **not read** for this map: adding it to the session was refused. The call site
  and its pinned version are unknown here.

## Cross-cutting invariants
- [shadow-layer-record](shadow-layer-record.md)
- [constant-equals-factory](constant-equals-factory.md)

## Blast radius
- [colorscheme-resolution](colorscheme-resolution.md): exporting it (#22) makes its fallbacks public contract.
- [shipping](shipping.md): pub.dev publishes every exported symbol's dartdoc as the API reference, and removing an export breaks consumers it cannot see.
- `doc/riverpod.md` and `README.md` → "Building a theme at runtime" describe this surface.

## Known holes / open
- `ColorSchemeResolver` is not exported, so a runtime preview hand-copies its
  fallbacks and they already drift. Tracked: #22.
- The consumer side of the seam was not read (see `## Reference behaviour`).
