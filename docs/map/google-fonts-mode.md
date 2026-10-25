# google-fonts-mode

## What it is
This territory covers the default `font_mode: google_fonts`. The theme loads its
fonts at runtime through the `google_fonts` package: it emits
`GoogleFonts.<method>TextTheme()`, with `fontFamilyFallback` for the rest of the
stack. The CLI adds the `google_fonts` dependency when the project lacks it.

## Governing decisions
**None.**

## Design model
From the source.
- **Method name from family name:** the first word is lower-cased; each later
  word has its first letter upper-cased and the rest lower-cased. `Noto Sans KR`
  becomes `notoSansKr` (`DartThemeGenerator._toGoogleFontsMethodName`).
- **One family:** `textTheme: GoogleFonts.<m>TextTheme()`. **Several:**
  `.apply(fontFamilyFallback: [GoogleFonts.<f>().fontFamily!, ...])`
  (`_writeThemeClass`).
- **The import is emitted only in this mode, and only when there is a family**
  (`generate`).
- **The CLI decides whether to add the dependency by searching the generated
  text** for the `google_fonts` import (`_run`). It decides whether the
  dependency is already present by *parsing* pubspec. A commented-out line does
  not count; `dev_dependencies` and `dependency_overrides` do, because
  `dart pub add` refuses a package named there (`_declaresGoogleFonts`).
- **A failed `dart pub add` exits 2.** The theme imports a package the project
  does not declare ([cli-run](cli-run.md)).

## Code
- `lib/src/generator/dart_theme_generator.dart`: `_toGoogleFontsMethodName`, `_writeThemeClass`, the conditional import in `generate`
- `bin/flutter_tweakcn_generator.dart`: `_declaresGoogleFonts`, the `dart pub add google_fonts` branch and the summary regexes in `_run`
- tests: `test/generator/dart_theme_generator_test.dart`, `test/cli/exit_code_test.dart`

## Reference behaviour
- The `google_fonts` package's generated source is the binding reference for
  method spelling ([references](../agents/thegraph.md)). `README.md` →
  "Development" names this as a failure mode: a method name derived from a
  family the package does not spell that way. The rule above was never checked
  against that source, so `KR` → `Kr` and similar holds only as far as the
  `google_font_fallback_theme` verification case exercises it.

## Cross-cutting invariants
**None.**

## Blast radius
- [verification](verification.md): only the compile check catches a misspelled method, because `dart test` compares text.
- [generated-file](generated-file.md): this is the one mode in which the generated file imports something other than Flutter.
- [cli-run](cli-run.md): the CLI greps this territory's output text, so a change in how the import or `TextTheme` call is written breaks the dependency add and the summary.

## Known holes / open
- Font names whose Google Fonts method does not follow the rule above (digits,
  hyphens, all-caps words) are not enumerated anywhere.
- The `build_runner` path never adds the dependency
  ([build-runner-builder](build-runner-builder.md)).
