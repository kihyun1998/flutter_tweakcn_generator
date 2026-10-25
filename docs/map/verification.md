# verification

## What it is
This territory is how the repo proves a change. It covers:
- `dart test` on a plain Dart SDK;
- the compile check `tool/verify_generated_output.dart`, which runs inside
  `example/` where `package:flutter` resolves;
- `example/`'s `flutter test`;
- the two CI jobs that run them.

## Governing decisions
**None** as a record. `CLAUDE.md` → "Verifying a change to the generator" is the
recipe.

## Design model
From `CLAUDE.md`, `.github/workflows/ci.yml`, `dart_test.yaml` and the verifier's dartdoc.
- **`dart test` compares text to text.** A file that does not compile, such as a
  `ColorScheme` missing a newly required parameter or a misspelled
  `GoogleFonts` method, passes it. The builder produced no output at all while
  the suite stayed green (#20).
- **Compiling is not running.** Only `example/`'s `flutter test` shows that the
  factories rebuild the constants (#19 `4eb5415`), and only it type-checks
  [shadow-layer-record](shadow-layer-record.md).
- **The verifier generates six shapes** (`verificationCases`: complete, minimal,
  color-free, dark-only, google-font fallback, local font), analyzes them in
  `example/tweakcn_verify/`, deletes them, and fails if the committed example
  theme is stale (`staleExampleTheme`).
  - The directory is not dot-prefixed, because the analyzer skips hidden
    directories.
- **Two CI jobs in two worlds.**
  - `test` runs on a plain Dart SDK, with `pub get --no-example`, analyze,
    format of `lib test tool bin`, and `dart test`.
  - `generated-output` runs on unpinned stable Flutter, with the verifier and
    then `flutter test`.
  - `example/` is excluded from analysis and formatting on purpose, because its
    options need Flutter (`analysis_options.yaml`, `ci.yml`).
- **`-P fast` skips the `slow` tag and is never a gate.** The slow tests let the
  downloader's real 30 s deadline expire (`dart_test.yaml`).
- **Use `dart pub get` in `example/`.** `flutter pub get` rewrites the
  checked-in plugin registrants (`ci.yml`).

## Code
- `tool/verify_generated_output.dart`: `VerificationCase`, `verificationCases`, `generateCase`, `staleExampleTheme`, `writeGeneratedCases`, `generatedCaseDirName`, `main`
- `example/test/tweakcn_theme_test.dart`, `example/test/app_test.dart`, `example/lib/theme/tweakcn_theme.g.dart`, `example/tweakcn.css`
- `.github/workflows/ci.yml`: jobs `test`, `generated-output`
- `dart_test.yaml`, `analysis_options.yaml`
- tests: `test/tool/verify_generated_output_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [shadow-layer-record](shadow-layer-record.md)
- [constant-equals-factory](constant-equals-factory.md)

## Blast radius
- [generated-file](generated-file.md), [colorscheme-resolution](colorscheme-resolution.md), [google-fonts-mode](google-fonts-mode.md): each new shape of emitted code needs a verification case, or nothing compiles it.
- [output-formatting](output-formatting.md): the stale-example check compares formatted bytes, so it fails on any formatter or language-version drift.

## Known holes / open
- **A fixture simpler than the real service can be simpler in exactly the place
  the bug lives.** The test server's bodiless 404/500 could not catch #23
  (lessons.md, `9dd3b11`, 2026-08-02).
- **A test pinned at the default input** cannot tell two formulas apart
  ([radius-steps](radius-steps.md), #31).
- **No test checks the [token-roster](token-roster.md)** parser list against the
  generator list.
