# cli-run

## What it is
`dart run flutter_tweakcn_generator`, the path most consumers use. It reads
config from `pubspec.yaml`, parses the CSS, generates and writes the theme, runs
the font step for the mode, optionally cleans up, and exits with a code that
says whether the theme is usable as generated.

## Governing decisions
**None** as a record. The exit-code contract is stated in `README.md` → "Exit
codes" and in the dartdoc of `_exitPartial`.

## Design model
From the source (`bin/flutter_tweakcn_generator.dart`).
- **Three exit codes, and only three.**
  - `0`: the theme is usable as generated.
  - `1`: nothing was generated (`_exitNothingGenerated`).
  - `2`: a theme was written but something it needs is missing (`_exitPartial`).
  - `2` is not worse than `1`; they are categories (#24, `8d350e2`).
  - Anything unexpected is caught in `main` and mapped to `1` or `2` by
    `_themeWritten`, so the process never exits `255`.
- **The status comes from the result, not from what happened during the run.**
  At the end, in local and custom mode, a theme naming a family pubspec does not
  declare exits `2` (`_familiesTheProjectCannotLoad`). A failed *lookup* alone is
  not `2`; a failed *file* download is (#28 `2d1579d`).
- **Readiness means "declared in pubspec", not "present on disk".** A
  declaration whose file is missing fails the next Flutter build loudly anyway.
  This holds only while every declaration comes from `PubspecFontAdder`, which
  declares only files it just wrote (`_familiesTheProjectCannotLoad` dartdoc).
- **Order:** config → CSS → generate → write (`_themeWritten = true`) → font step
  by mode → `font_exclusive` cleanup → readiness check → summary.
- **Config** comes from the `flutter_tweakcn_generator:` key, with defaults
  (`TweakcnConfig.fromPubspec`). A value of the wrong YAML type throws, which is
  caught as above.
- **Testing this territory:**
  - **Two old tests had frozen the bug.** Two tests asserted `exitCode, 0` while
    testing something else, and both named a font that was never provided. They
    broke when #28 corrected the rule. An assertion nobody thought of as a contract
    is still one (lessons.md, `2d1579d`, 2026-08-03).
  - **A trick for testing the lookup offline.** Pointing `http_proxy`/`https_proxy`
    at a dead port fails the lookup deterministically with no network (lessons.md,
    `2d1579d`).

## Code
- `bin/flutter_tweakcn_generator.dart`: `main`, `_run`, `_exitNothingGenerated`, `_exitPartial`, `_themeWritten`, `_familiesTheProjectCannotLoad`, `_declaresGoogleFonts`
- `lib/src/config.dart`: `TweakcnConfig`, `TweakcnConfig.fromPubspec`
- tests: `test/cli/cli_harness.dart`, `exit_code_test.dart`, `font_readiness_exit_code_test.dart`, `font_exclusive_test.dart`, `font_sans_conflict_test.dart`, `color_scheme_warning_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [empty-means-unknown](empty-means-unknown.md): computes `allowEmpty` once for both destructive steps.

## Blast radius
- [google-fonts-mode](google-fonts-mode.md), [font-download](font-download.md), [custom-font-scan](custom-font-scan.md), [font-cleanup](font-cleanup.md): this territory orders them, and the exit code depends on the report conventions each one returns.
- [pubspec-fonts](pubspec-fonts.md): the readiness check reads its record.
- [generated-file](generated-file.md): `_run` greps the generated text for the `google_fonts` import and the summary's `TextTheme` names.
- [build-runner-builder](build-runner-builder.md): none of this territory's font handling or exit codes exist on the builder path.
- [shipping](shipping.md): `README.md` → "Exit codes" and `CHANGELOG.md` 0.5.0 restate the contract, and scripts that drive the CLI depend on it.

## Known holes / open
**None.**
