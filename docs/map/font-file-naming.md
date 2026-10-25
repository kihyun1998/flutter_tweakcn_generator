# font-file-naming

## What it is
This territory is the translation between how a font family is named and how
its files are named. CSS and `pubspec.yaml` write the family as `Noto Sans KR`;
on disk the files are `NotoSansKR-Bold.ttf`. Every step that downloads, scans,
declares or deletes a font asks this one class.

## Governing decisions
**None.** `FontFamily` was extracted for #4 (`afc4a66`) so that one class owns
the translation.

## Design model
From the source (`FontFamily` dartdoc).
- **File-name prefix is the family name with its spaces removed**
  (`fileNamePrefix`). A file is written as `<prefix>-<WeightName>.ttf`
  (`fileNameFor`), and `ownsFile` always claims back what `fileNameFor` writes.
- **`ownsFile` is a guess, generous on purpose.** It is a case-insensitive
  prefix match, so it claims `InterVariable.ttf` and `Inter24pt-Bold.ttf` for
  `Inter`. It also claims `RobotoSlab-Bold.ttf` for `Roboto`, which is wrong.
  Where a wrong guess costs a file, the pubspec record is asked first
  ([pubspec-record-wins](pubspec-record-wins.md)).
- **`hasName` is exact.** `Roboto` and `Roboto Slab` are different families
  (#5 `dee7419`).
- **Only `.ttf` counts as a font file**, matched case-insensitively
  (`isFontFile`).
- **The weight is the part after the prefix**, with one `-` or `_` separator
  removed (`weightSuffixOf`). Turning it into a number is
  [weight-names](weight-names.md)' business.

## Code
- `lib/src/font/font_family.dart`: `FontFamily` (`name`, `fileNamePrefix`, `extension`, `isFontFile`, `ownsFile`, `weightSuffixOf`, `fileNameFor`, `hasName`)
- users: `FontDownloader.downloadEntries`, `CustomFontScanner.scan`, `FontCleanup.cleanFontsDirectory`, `PubspecFontAdder.addFonts`, `PubspecFontAdder.removeUndefinedFonts`
- tests: `test/font/font_family_test.dart`

## Reference behaviour
- Real releases name files `InterVariable.ttf`, `Inter24pt-Bold.ttf` and
  `Roboto[wdth,wght].ttf`, so a prefix rule has to tolerate more than
  `<Family>-<Weight>` (lessons.md, `108fc90`, 2026-07-25).

## Cross-cutting invariants
- [pubspec-record-wins](pubspec-record-wins.md): this guess is the fallback that rule falls back to.
- [weight-names](weight-names.md)

## Blast radius
- [font-download](font-download.md): the file names it writes come from `fileNameFor`. A change to the prefix strands every file downloaded before it as undeclared, guessed-at leftovers.
- [custom-font-scan](custom-font-scan.md), [font-cleanup](font-cleanup.md): both pick candidates with `ownsFile`. Making it stricter deletes or skips user files whose names do not follow the pattern (#6).
- [pubspec-fonts](pubspec-fonts.md): `hasName` decides whether a declared family counts as defined, for both adding and removing.

## Known holes / open
**None.**
