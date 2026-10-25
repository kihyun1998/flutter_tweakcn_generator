# font-cleanup

## What it is
With `font_exclusive: true` in local or custom mode, this territory deletes font
files and `flutter > fonts` declarations that belong to no family the current
`--font-sans` names. It removes `font_dir` once it is empty.

## Governing decisions
**None.**

## Design model
From the source (`FontCleanup.cleanFontsDirectory`, the `font_exclusive` branch of `_run`).
- **Files go first, then declarations.** The declarations are read *before*
  `removeUndefinedFonts` rewrites pubspec, because they say which file belongs
  to which family.
- **Pubspec's record decides ownership. The name guess applies only to
  undeclared files, and leans toward keeping**
  ([pubspec-record-wins](pubspec-record-wins.md)).
- **An empty family list is a no-op unless `allowEmpty`**
  ([empty-means-unknown](empty-means-unknown.md)). The CLI sets `allowEmpty`
  when the CSS declares any stack, a pure system stack included, or when
  `font_exclusive_allow_empty` is set. Otherwise it skips with a warning.
- **Only font files** (`.ttf`, case-insensitive) are candidates
  (`FontFamily.isFontFile`).
- **It runs before the exit-code readiness check**, because removing a
  declaration can itself leave the theme naming a missing font
  ([cli-run](cli-run.md)).

## Code
- `lib/src/font/font_cleanup.dart`: `FontCleanup.cleanFontsDirectory`
- `lib/src/font/pubspec_font_adder.dart`: `PubspecFontAdder.removeUndefinedFonts`
- `bin/flutter_tweakcn_generator.dart`: the `font_exclusive` block in `_run`
- `lib/src/config.dart`: `TweakcnConfig.fontExclusive`, `fontExclusiveAllowEmpty`
- tests: `test/font/font_cleanup_test.dart`, `test/cli/font_exclusive_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [pubspec-record-wins](pubspec-record-wins.md)
- [empty-means-unknown](empty-means-unknown.md)

## Blast radius
- [pubspec-fonts](pubspec-fonts.md): the declaration half runs through the line-matching remover, with its line-ending hazards (#16).
- [custom-font-scan](custom-font-scan.md): in custom mode the files deleted here are the user's own and cannot be recovered.
- [cli-run](cli-run.md): exit `2` can be caused by this step.

## Known holes / open
- **The docs say "local mode only"; the code runs in both modes.** `README.md`
  (the `font_exclusive` line under Configuration) and the
  `TweakcnConfig.fontExclusive` dartdoc both say local only, but `_run` runs
  cleanup for `local` *or* `custom`. Checked at 2980252.
- Like [pubspec-fonts](pubspec-fonts.md), this deletes on the consumer's disk.
  Give any change here a full completeness pass, however small the diff.
