# flutter_tweakcn_generator

A Dart build_runner package that generates Flutter theme code from tweakcn theme definitions.

## Verifying a change to the generator

`dart test` only checks the text the generator emits — the package has no Flutter dependency, so the suite cannot tell whether that text compiles. (`dart test -P fast` skips the `slow`-tagged tests, which wait out the font downloader's real 30-second deadline. That is for the edit loop; a gate runs the bare command.) After changing what the generator writes, also run:

```bash
dart run tool/verify_generated_output.dart
cd example && flutter test
```

The first compiles the generated output for six theme shapes against the real SDK inside `example/`, which must have its packages resolved (`flutter pub get`). It also fails when the theme committed under `example/` is no longer what the generator writes — regenerate it with `cd example && dart run flutter_tweakcn_generator`, since the example is committed exactly as generated.

The second runs the generated code. It is also the only thing that type-checks the seam between the package and its output: `ThemeModeData.shadowLayers` produces the record type the generated `fromShadowMap` takes, and nothing else in the repo puts those two declarations in the same compilation. Adding a field to one and not the other fails only here.

See the Development section of `README.md`.

## Boundary

The core turns CSS text into Dart text; the consumer decides what to do with
the result. Nothing here may know what an app looks like.

- Core: CSS parsing, token → `ColorScheme` resolution and its fallbacks, code
  emission, formatting at the consumer's language version, font resolution and
  download.
- Consumer: which theme and when, `ThemeMode`, runtime `ThemeData` composition,
  widget styling, the CSS itself, and all of `pubspec.yaml` outside the fonts
  block this package writes.
- Two seams. A build-time consumer meets only the generated file. A runtime
  consumer (`CssParser.parse` on pasted CSS) meets the public API, so whatever
  the generated code does that a live preview must reproduce has to be
  reachable from it (#22).
- A consumer's report: ask whose invariant broke first. A missing export is not
  a wrong fallback.

## Shipping

- Does it change what a consumer gets? Yes → branch, PR (`Closes #N`), squash
  merge. No (`.github/`, docs, `test/` or `tool/` only, release commits) →
  straight to `main`.
- Release: `chore: release X.Y.Z` bumps the version and adds the `CHANGELOG.md`
  section; `dart pub publish --dry-run` is clean. A published CHANGELOG entry is
  never rewritten. The maintainer runs `dart pub publish`; the agent never does.
- After a release, check each consumer (siblings under `/Volumes/T7/GitHub`;
  derive the list then). One may depend on this package as both a
  `dev_dependency` and a `dependency`.

## Comments

A comment says what the code is. Why it is this way, what it deliberately
leaves out, the trap and the measured value go to the territory note under
`docs/map/`. Where none seems to hold it, search the folder and the code
symbol first; only then start a new note, named for what the system does
there, not for the file. History goes to the commit message. Comments
written before this rule still carry the rest: never delete one whose
content the map does not yet hold — move it first (`decant`).

## Agent skills

### Working discipline

Any substantive change runs through `thegraph`; its build is
`docs/agents/thegraph.md`.

### Territory map

The map's hub is [`docs/map/README.md`](docs/map/README.md). Read it before
designing a change: open the territories the change touches and follow their
blast radius and invariants. After the change lands, update the notes it
falsified. When a fix reveals a fact, ask whether it holds at every site that
shares the same assumption. If yes, the fix lands with an invariant note.

### Issue tracker

Issues live as GitHub issues in `kihyun1998/flutter_tweakcn_generator`, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, using their default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
