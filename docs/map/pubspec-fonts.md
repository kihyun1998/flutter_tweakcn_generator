# pubspec-fonts

## What it is
This territory reads and rewrites the `flutter > fonts` block of the consumer's
`pubspec.yaml`. It covers what is declared, adding families, and removing
undefined ones. This is the only code in the package that writes a file the
package does not own.

## Governing decisions
**None** as a record. `CLAUDE.md` → "Boundary" gives the consumer everything in
`pubspec.yaml` outside the fonts block this package writes.

## Design model
From the source (`PubspecFontAdder`, `PubspecFontDeclarations`).
- **Reading uses the YAML parser** (`PubspecFontDeclarations.parse`), so quoting,
  comments, line endings and nesting are the parser's problem. A file declared
  under several families maps to a *set* of families. Overwrite on the last
  declaration instead, and a defined family's file loses its keeper (#6).
- **Removing matches lines, because indentation delimits the block being
  rewritten** (`removeUndefinedFonts`, `_familyPattern`). The family name it
  extracts must mean what the parser's would. That is why `_unquote` exists: the
  adder once skipped a quoted declaration that cleanup did not recognize, which
  left the family undeclared (#5).
- **Line endings are the consumer's.**
  - `\r` is a regex line terminator, so `(.+)$` stops before it while `\s`
    matches it. A rewriter that splits on `\n` therefore half-works.
  - Patterns run on the line without its `\r` (`_withoutCarriageReturn`), and
    the original line is written back.
  - Inserted text takes the file's own ending (`_insertFontsSection`).
  - (#16 `e2e124a`, `4f6110f`)
- **A run with nothing to remove leaves the file byte-identical.**
- **Adding skips a family already declared**, matched exactly (`addFonts`,
  `FontFamily.hasName`).
- **Family names are matched exactly**, as Flutter's manifest lookup does
  (`_familiesTheProjectCannotLoad` dartdoc).

## Code
- `lib/src/font/pubspec_font_declarations.dart`: `PubspecFontDeclarations.read`, `parse`, `families`, `familiesByFileName`, `familiesOf`, `empty`
- `lib/src/font/pubspec_font_adder.dart`: `PubspecFontAdder.addFonts`, `removeUndefinedFonts`, `_insertFontsSection`, `_withoutCarriageReturn`, `_unquote`, `_familyPattern`, `_flutterKeyPattern`, `_fontsKeyPattern`
- tests: `test/font/pubspec_font_adder_test.dart`, `test/font/pubspec_font_declarations_test.dart`, `test/cli/font_exclusive_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [pubspec-record-wins](pubspec-record-wins.md): `familiesByFileName` is the record.
- [empty-means-unknown](empty-means-unknown.md): `removeUndefinedFonts`.

## Blast radius
- [cli-run](cli-run.md): the readiness check that decides exit code `2` reads these declarations. A family written in a form the reader parses differently reports a ready font as missing, or the reverse.
- [font-cleanup](font-cleanup.md), [custom-font-scan](custom-font-scan.md): both decide ownership from this record.
- [font-download](font-download.md): every declaration written here points at a path the downloader or scanner reported. A path that is not on disk fails the consumer's next Flutter build.

## Known holes / open
- **The adder and the remover read the same block two different ways** (YAML
  versus line patterns). Indentation other than two and four spaces, or flow
  style (`fonts: [...]`), is not handled by the remover.
- **Destructive, and silent when it goes wrong.** #16 rewrote a CRLF pubspec into
  invalid YAML on a run with nothing to clean, printed success and exited 0. The
  damage is on the consumer's disk before anyone reads a diff (lessons.md,
  `e2e124a`, 2026-07-27). Treat any change here as needing a full pass over line
  endings, quoting and indentation, whatever the size of the diff.
