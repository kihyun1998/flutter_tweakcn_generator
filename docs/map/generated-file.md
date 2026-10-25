# generated-file

## What it is
This territory covers the shape of the one Dart file every run produces: the
header, the imports, section order, the `<Prefix>Theme` class with its `light`
and `dark` `ThemeData` getters, the `<Prefix>BuildContext` extension, and value
equality on all three extensions. The per-extension content belongs to
[color-extension](color-extension.md), [radius-steps](radius-steps.md) and
[shadows](shadows.md).

## Governing decisions
**None** as a record. `CLAUDE.md` → "Boundary" states the rule this territory
keeps.

## Design model
- **The generated file imports Flutter and nothing else.** It imports
  `foundation.dart` and `material.dart`, plus `google_fonts` only in
  google_fonts mode (`DartThemeGenerator.generate`). `foundation.dart` is
  imported directly because `material.dart` does not re-export `listEquals`.
  Every factory signature therefore takes primitives or a structural record
  (`README.md` → "Building a theme at runtime"; `CLAUDE.md` → "Boundary").
- **Section order is fixed:** ColorScheme, Colors, Radius, Shadows, Theme,
  BuildContext (`generate`).
- **Value equality on every extension.** `ThemeData` compares extensions by
  value, so without `==` a theme rebuilt from unchanged tokens would rebuild
  every `Theme.of` dependant. The hash is `Object.hashAll` because the colors
  extension has more than 20 fields (#17 `34005bf`, `_writeValueEquality`).
- **Both `ThemeData` getters register all three extensions.** Both use
  `<Prefix>Radius.standard`, and the font lines come from
  [font-stack](font-stack.md) by mode (`_writeThemeClass`).
- **`class_prefix` renames every class and accessor**, for example
  `context.<prefix>Colors` (`_lowerFirst`).
- The output always passes through [output-formatting](output-formatting.md).

## Code
- `lib/src/generator/dart_theme_generator.dart`: `DartThemeGenerator` (`generate`, `classPrefix`, `fontMode`), `_writeValueEquality`, `_writeThemeClass`, `_writeBuildContextExtension`, `_lowerFirst`
- `example/lib/theme/tweakcn_theme.g.dart`: the committed output, regenerated and never hand-edited (`CLAUDE.md`)
- tests: `test/generator/dart_theme_generator_test.dart`; `example/test/tweakcn_theme_test.dart` group `value equality`; `example/test/app_test.dart`

## Reference behaviour
- Flutter `theme_data.dart` and `text_theme.dart`: the shape `ThemeData(...)`
  and `textTheme.apply(...)` must have to compile. The Flutter SDK reference is
  binding ([references](../agents/thegraph.md)).

## Cross-cutting invariants
- [constant-equals-factory](constant-equals-factory.md): equality is what lets the factory and constant be compared.

## Blast radius
- [verification](verification.md): `dart test` compares this text to text. Only `tool/verify_generated_output.dart` and `example/`'s `flutter test` show that it compiles and runs.
- [shipping](shipping.md): any change to the emitted text shows up as a diff in every consumer's committed theme, even a change to dartdoc only (`CHANGELOG.md` 0.5.1).
- [cli-run](cli-run.md): the CLI greps this text, for the `google_fonts` import and for the `GoogleFonts.(\w+)TextTheme` summary line.
- [public-api](public-api.md): a type from this package appearing here would make a build-time consumer depend on the package at runtime.

## Known holes / open
**None.**
