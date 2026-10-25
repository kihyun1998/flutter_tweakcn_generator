# pubspec-record-wins

## The fact
Which family owns a font file is what `pubspec.yaml` declares under
`flutter > fonts`. A guess from the file name applies only to files pubspec has
never declared, and that guess leans toward *keeping* the file.

## Why it is cross-cutting
Two sites decide ownership, and each applies the precedence rule itself. They
share the data (`PubspecFontDeclarations.familiesOf`, `FontFamily.ownsFile`) but
not the rule:
- `FontCleanup.cleanFontsDirectory` keeps a declared file when any one of its
  declarations names a defined family. It falls back to `ownsFile` only when the
  file is undeclared.
- `CustomFontScanner.scan` skips a name-matched file whose declarations name
  another family, so that the guess is not written back into pubspec as fact.

A name cannot tell the two cases apart. `RobotoSlab-Bold.ttf` looks like one of
`Roboto`'s files, just as `InterVariable.ttf` looks like one of `Inter`'s
(`FontFamily.ownsFile` dartdoc).

## Territories it holds in
- [font-cleanup](font-cleanup.md): `FontCleanup.cleanFontsDirectory`
- [custom-font-scan](custom-font-scan.md): `CustomFontScanner.scan`
- [pubspec-fonts](pubspec-fonts.md): `PubspecFontDeclarations.familiesByFileName`, the record both read
- [font-file-naming](font-file-naming.md): `FontFamily.ownsFile`, the guess the record overrules

## What a violation looks like
- **In cleanup:** a file that belongs to a defined family is deleted. Under
  `font_mode: custom` the user supplied it, so it cannot be recovered.
- **In the scanner:** a leftover file is re-declared under the wrong family, and
  cleanup can never remove it.

## Discovery history
- #4 (`afc4a66`): `FontFamily` was extracted so that one class owns the
  family-name translation.
- #5 (`dee7419`): declarations are matched exactly instead of by substring.
- #6 (`108fc90`): ownership is now read from pubspec. While reviewing #6, the
  scanner was caught feeding its own guess back into pubspec
  (lessons.md, `108fc90`, 2026-07-25).
- The helper from #4 did not prevent #5 or #6. It only made each one cheap to
  fix. What lasts is the rule, not the function (lessons.md, `f8516cb`, 2026-08-02).

## Where it will recur
Any new code that decides, from a file name, whether a font file belongs to a
family. Ask `PubspecFontDeclarations.familiesOf` first.
