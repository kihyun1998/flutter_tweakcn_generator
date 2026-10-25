# empty-means-unknown

## The fact
An empty list of defined font families means "detection failed", not "delete
everything". Both destructive font steps do nothing on an empty list unless the
caller passes `allowEmpty: true`.

## Why it is cross-cutting
Two sites apply the guard independently:
- `FontCleanup.cleanFontsDirectory` deletes files.
- `PubspecFontAdder.removeUndefinedFonts` deletes declarations.

The CLI computes `allowEmpty` once (`_run`: `fontStackDeclared ||
config.fontExclusiveAllowEmpty`) and passes it to both. If one guard changed and
the other did not, files would be removed while their declarations stayed (the
next Flutter build fails on the missing asset), or declarations would be removed
while their files stayed.

## Territories it holds in
- [font-cleanup](font-cleanup.md): `FontCleanup.cleanFontsDirectory`, and the CLI's skip warning in `_run`
- [pubspec-fonts](pubspec-fonts.md): `PubspecFontAdder.removeUndefinedFonts`
- [cli-run](cli-run.md): `_run` computes the one `allowEmpty` both sites receive

## What a violation looks like
A `--font-sans` that fails to parse (a typo, a format the parser does not read)
empties `fonts/` and the `flutter > fonts` block. Under `custom` mode, the files
are lost for good.

## Discovery history
The guard and `font_exclusive_allow_empty` are documented in `README.md`
(Configuration) and in `TweakcnConfig.fontExclusiveAllowEmpty`. A pure system
stack counts as declared (`TweakcnThemeData.resolvedFontSans` is non-null), so it
still cleans up.

## Where it will recur
Any new step that removes something "not in the defined list". Give it the same
`allowEmpty` parameter, and have the CLI pass the same value it passes the other
two.
