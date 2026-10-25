# Territory map

<!-- grill-map build stamp: 18c00d1 -->
<!-- grill-map synced at: 2980252 (2026-10-25) -->

The territory map. A comment's why, trap and measured value go to a note here.
Notes are added as they come up, or all at once with `grill-map`, which also
reads hand-written notes as leads and keeps their paths.

## The two questions

- **If I touch this, what else moves?** Find the territory, then read its
  `## Blast radius` and `## Cross-cutting invariants`, and follow the links.
- **What decision is this shape derived from?** Read `## Governing decisions`
  and `## Design model`. Every claim there carries its evidence: a symbol, a
  commit or an issue. Or it carries its source and date: `(maintainer, …)` or
  `(lessons.md, <commit>, …)` for a fact carried from the old evidence log.

## How to read it

- `## Blast radius` is a checklist. An item with nothing to do is a correct
  outcome.
- **None.** is itself an answer. No decision record exists yet
  ([domain.md](../agents/domain.md)), so every `## Governing decisions` reads
  **None.** and the rules come from reading the source.
- Notes name symbols, never line numbers. Links are plain relative markdown. A
  fact another artifact owns is linked, not restated.
- Source files and issues are text inside notes, not nodes. The map cannot
  answer "who calls X". Grep for that.

## Territories

What the system does, from the pasted CSS to the consumer's app:

- [css-reading](css-reading.md): which declarations become the theme
- [color-values](color-values.md): CSS color syntax → ARGB
- [css-lengths](css-lengths.md): CSS length → logical pixels
- [colorscheme-resolution](colorscheme-resolution.md): the required `ColorScheme` and its fallbacks
- [color-extension](color-extension.md): `<Prefix>Colors`, its constants and `fromMap`
- [radius-steps](radius-steps.md): tweakcn's four radius steps and `fromRadius`
- [shadows](shadows.md): shadow levels, parsed and emitted, with `fromShadowMap`
- [generated-file](generated-file.md): the output's shape, imports, `ThemeData`, equality
- [output-formatting](output-formatting.md): `dart format` at the consumer's language version
- [font-stack](font-stack.md): `--font-sans` → the families the theme names
- [google-fonts-mode](google-fonts-mode.md): `GoogleFonts.*TextTheme` and the dependency add
- [font-download](font-download.md): local mode, fetching `.ttf` from Google Fonts
- [custom-font-scan](custom-font-scan.md): custom mode, the user's own `.ttf`
- [pubspec-fonts](pubspec-fonts.md): reading and rewriting `flutter > fonts`
- [font-cleanup](font-cleanup.md): `font_exclusive` deletion
- [cli-run](cli-run.md): the CLI, its order and its exit codes
- [build-runner-builder](build-runner-builder.md): `.tweakcn.css` → `.tweakcn.dart`
- [public-api](public-api.md): the exports and the runtime-consumer seam
- [verification](verification.md): `dart test`, the compile check, `example/`, CI
- [shipping](shipping.md): releases, ranges, published docs

## Cross-cutting invariants

- [token-roster](token-roster.md): the parser's token list and the generator's agree
- [shadow-layer-record](shadow-layer-record.md): two declarations of one record type
- [constant-equals-factory](constant-equals-factory.md): a factory fed a theme's own tokens reproduces its constant
- [pubspec-record-wins](pubspec-record-wins.md): pubspec, not the file name, says who owns a font file
- [empty-means-unknown](empty-means-unknown.md): an empty family list deletes nothing

## Scope

The package's source under `lib/` and `bin/`, `tool/`, the tests, `example/`, CI,
and what ships to pub.dev. Out of scope:
- `docs/agents/` and `CLAUDE.md`, which are agent guidance, not system
  behaviour;
- `example/`'s platform folders, which are Flutter scaffolding;
- the `doc/` guide except as a shipped surface.

A territory appears when something in the repo commits to it: code, a decision
record, or an open issue with a design. A missing note means nothing does yet.

## What the reading found

The repo is one Dart package that turns tweakcn CSS text into Flutter Dart text
without depending on Flutter, which makes it blind to whether its own output
compiles. Most hard-won rules sit in two places:
- **The font pipeline:** this is the only code that writes and deletes files in
  a project it does not own.
- **The seam to runtime consumers:** generated factories have to reproduce what
  the generator baked in.

The largest gap is the `ColorScheme` half of that seam (#22). No decision record
exists yet, so the "why" lives in dartdoc, `README.md`, `CHANGELOG.md` and
commit messages. These notes point there.
