# custom-font-scan

## What it is
In `font_mode: custom`, this territory finds the user's own `.ttf` files for
each family in `font_dir`, infers each file's weight from its name, and hands
them on to be declared. It never touches the network.

## Governing decisions
**None.**

## Design model
From the source (`CustomFontScanner.scan`).
- **Candidates are guessed by name.** `FontFamily.ownsFile` matches the prefix
  case-insensitively and is generous on purpose.
- **A file pubspec declares under another family is skipped**
  ([pubspec-record-wins](pubspec-record-wins.md)). The CLI reads the
  declarations once, before any of this run's writes.
- **Weight from the suffix:** `Bold` → 700 and so on, including the aliases
  `UltraLight`, `DemiBold`, `UltraBold` and `Heavy`. An empty or unknown suffix
  is 400 (`_weightSuffixes`, `_weightFor`).
- **A missing directory or no matches is a warning on stderr, not an error.**
  The exit code still catches the undeclared family at the end
  ([cli-run](cli-run.md), #28).

## Code
- `lib/src/font/custom_font_scanner.dart`: `CustomFontScanner.scan`, `_weightSuffixes`, `_weightFor`
- `lib/src/font/font_family.dart`: `FontFamily.ownsFile`, `weightSuffixOf`, `fileNameFor`
- tests: `test/font/custom_font_scanner_test.dart`, `test/font/font_family_test.dart`

## Reference behaviour
- Real font releases name files in ways a prefix rule has to tolerate:
  `InterVariable.ttf`, `Inter24pt-Bold.ttf` and `Roboto[wdth,wght].ttf`
  (lessons.md, `108fc90`, 2026-07-25).

## Cross-cutting invariants
- [pubspec-record-wins](pubspec-record-wins.md)
- [weight-names](weight-names.md): `_weightSuffixes` reads back what the downloader names

## Blast radius
- [pubspec-fonts](pubspec-fonts.md): what this territory returns is written into pubspec as fact.
- [font-cleanup](font-cleanup.md): the cleanup step guesses ownership with the same name rule.
- [font-file-naming](font-file-naming.md): candidates are picked by `ownsFile`, a guess from the name.

## Known holes / open
- A variable font file (`Roboto[wdth,wght].ttf`) has no weight suffix, so it is
  declared at 400 only.
